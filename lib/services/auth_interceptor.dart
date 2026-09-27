import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../utils/constants.dart';

class AuthInterceptor extends QueuedInterceptor {
  final Dio dio;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _authRetriedKey = '_auth_request_retried';

  static const Set<String> _terminalRefreshCodes = {
    'SESSION_EXPIRED',
    'TOKEN_REUSED',
    'REFRESH_TOKEN_REQUIRED',
    'INVALID_REFRESH_TOKEN',
    'REFRESH_TOKEN_INVALID',
    'USER_NOT_FOUND',
    'INVALID_USER',
    'UNAUTHORIZED',
  };

  static String? _inMemoryToken;

  static bool _isNavigatingAuthError = false;

  static void Function(String code, String? manv)? authStateListener;

  static void Function(String accessToken, String refreshToken)?
  tokenRefreshedListener;

  AuthInterceptor(this.dio);

  void _cloneMultipartBodyForRetry(RequestOptions options) {
    final dynamic data = options.data;

    if (data is FormData) {
      options.data = data.clone();
    }
  }

  static void clearMemoryToken() {
    _inMemoryToken = null;
  }

  static void setMemoryToken(String? token) {
    final String normalizedToken = token?.trim() ?? '';

    _inMemoryToken = normalizedToken.isEmpty ? null : normalizedToken;
  }

  bool _isPublicEndpoint(String path) {
    final String lower = path.toLowerCase();

    return lower.contains('/auth/login') ||
        lower.contains('/public/dao-tao-thuc-hanh') ||
        lower.contains('/auth/register') ||
        lower.contains('/auth/refresh-token') ||
        lower.contains('/auth/change-password') ||
        lower.contains('/user/forgot-password') ||
        lower.contains('/user/reset-password');
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_isPublicEndpoint(options.path)) {
      options.headers.remove('Authorization');

      handler.next(options);
      return;
    }

    _inMemoryToken ??= await _secureStorage.read(key: 'access_token');

    final String token = _inMemoryToken?.trim() ?? '';

    if (token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    /*
     * Các API public tự xử lý lỗi trong
     * AuthService, không điều hướng ở đây.
     */
    if (_isPublicEndpoint(err.requestOptions.path)) {
      handler.next(err);
      return;
    }

    final String errorCode = _extractErrorCode(err.response?.data);

    /*
     * PASSWORD_EXPIRED và USER_LOCKED có thể
     * được backend trả bằng 403 hoặc 423,
     * không nhất thiết là 401.
     */
    if (errorCode == 'PASSWORD_EXPIRED') {
      await _handlePasswordExpired();

      handler.reject(err);
      return;
    }

    if (errorCode == 'USER_LOCKED') {
      await _clearSessionAndGoLogin(
        message:
            'Tài khoản của bạn đã bị khóa. '
            'Vui lòng liên hệ Admin.',
        code: 'USER_LOCKED',
      );

      handler.reject(err);
      return;
    }

    /*
     * Chỉ thực hiện refresh khi API nghiệp vụ
     * trả về 401.
     */
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    debugPrint(
      '[AUTH] Nhận 401: '
      '${err.requestOptions.method} '
      '${err.requestOptions.uri}',
    );

    debugPrint(
      '[AUTH] Nội dung 401: '
      '${err.response?.data}',
    );

    /*
     * Request đã được thử lại bằng token mới
     * nhưng vẫn trả 401.
     *
     * Không refresh lần thứ hai và cũng không
     * tự xóa phiên, vì có thể chính endpoint
     * nghiệp vụ đang trả 401.
     */
    if (err.requestOptions.extra[_authRetriedKey] == true) {
      debugPrint(
        '[AUTH] Request đã retry nhưng vẫn 401: '
        '${err.requestOptions.uri}',
      );

      handler.reject(err);
      return;
    }

    final String? requestToken = _extractBearerToken(
      err.requestOptions.headers['Authorization'],
    );

    final String currentToken =
        (await _secureStorage.read(key: 'access_token'))?.trim() ?? '';

    /*
     * Một request khác có thể đã refresh token
     * thành công trước đó.
     *
     * Khi đó chỉ cần gọi lại API bằng access
     * token mới đang nằm trong Secure Storage.
     */
    if (currentToken.isNotEmpty && requestToken != currentToken) {
      _inMemoryToken = currentToken;

      final RequestOptions retryOptions = err.requestOptions;

      retryOptions.extra[_authRetriedKey] = true;

      retryOptions.headers['Authorization'] = 'Bearer $currentToken';

      _cloneMultipartBodyForRetry(retryOptions);

      try {
        debugPrint(
          '[AUTH] Retry bằng token '
          'đã được request khác làm mới.',
        );

        final Response<dynamic> retryResponse = await dio.fetch(retryOptions);

        handler.resolve(retryResponse);
        return;
      } on DioException catch (retryError) {
        debugPrint(
          '[AUTH] Retry bằng token hiện tại lỗi: '
          '${retryError.response?.statusCode}',
        );

        handler.reject(retryError);
        return;
      } catch (e) {
        debugPrint('[AUTH] Lỗi retry không xác định: $e');

        handler.reject(err);
        return;
      }
    }

    final String refreshToken =
        (await _secureStorage.read(key: 'refresh_token'))?.trim() ?? '';

    if (refreshToken.isEmpty) {
      await _clearSessionAndGoLogin(
        message:
            'Phiên đăng nhập đã hết hạn. '
            'Vui lòng đăng nhập lại.',
        code: 'SESSION_EXPIRED',
      );

      handler.reject(err);
      return;
    }

    String newAccessToken = '';
    String newRefreshToken = '';

    /*
     * GIAI ĐOẠN 1:
     * Chỉ gọi API refresh và lưu cặp token mới.
     */
    try {
      final Dio refreshDio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      final String refreshUrl =
          '${AppConstants.authV2Url}'
          '/refresh-token';

      debugPrint('[AUTH] Gọi refresh: $refreshUrl');

      final Response<dynamic> response = await refreshDio.post(
        refreshUrl,
        data: {'refreshToken': refreshToken},
      );

      final Map<String, dynamic> responseData = _toMap(response.data);

      final bool isSuccess =
          responseData['success'] == true || responseData['Success'] == true;

      final Map<String, dynamic>? tokenData = _toNullableMap(
        responseData['data'] ?? responseData['Data'],
      );

      if (!isSuccess || tokenData == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Response refresh token không hợp lệ.',
          type: DioExceptionType.badResponse,
        );
      }

      newAccessToken =
          (tokenData['accessToken'] ?? tokenData['AccessToken'])
              ?.toString()
              .trim() ??
          '';

      newRefreshToken =
          (tokenData['refreshToken'] ?? tokenData['RefreshToken'])
              ?.toString()
              .trim() ??
          '';

      /*
       * Backend V2 sử dụng refresh token rotation.
       * Vì vậy phải nhận đủ cả token mới.
       */
      if (newAccessToken.isEmpty || newRefreshToken.isEmpty) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error:
              'Máy chủ không trả đủ '
              'access token và refresh token mới.',
          type: DioExceptionType.badResponse,
        );
      }

      _inMemoryToken = newAccessToken;

      await _secureStorage.write(key: 'access_token', value: newAccessToken);

      await _secureStorage.write(key: 'refresh_token', value: newRefreshToken);

      /*
       * Đồng bộ token mới với AuthProvider.
       */
      tokenRefreshedListener?.call(newAccessToken, newRefreshToken);

      debugPrint('[AUTH] Refresh token thành công.');
    } on DioException catch (refreshError) {
      final int? refreshStatus = refreshError.response?.statusCode;

      final String refreshErrorCode = _extractErrorCode(
        refreshError.response?.data,
      );

      debugPrint(
        '[AUTH] Refresh status: '
        '$refreshStatus',
      );

      debugPrint(
        '[AUTH] Refresh code: '
        '$refreshErrorCode',
      );

      debugPrint(
        '[AUTH] Refresh type: '
        '${refreshError.type}',
      );

      debugPrint(
        '[AUTH] Refresh data: '
        '${refreshError.response?.data}',
      );

      if (refreshErrorCode == 'PASSWORD_EXPIRED') {
        await _handlePasswordExpired();

        handler.reject(refreshError);
        return;
      }

      if (refreshErrorCode == 'USER_LOCKED') {
        await _clearSessionAndGoLogin(
          message:
              'Tài khoản của bạn đã bị khóa. '
              'Vui lòng liên hệ Admin.',
          code: 'USER_LOCKED',
        );

        handler.reject(refreshError);
        return;
      }

      /*
       * Refresh endpoint trả 401 đồng nghĩa
       * refresh token không còn sử dụng được.
       */
      final bool isTerminalSessionError =
          _terminalRefreshCodes.contains(refreshErrorCode) ||
          refreshStatus == 401;

      if (isTerminalSessionError) {
        await _clearSessionAndGoLogin(
          message:
              'Phiên đăng nhập đã hết hạn. '
              'Vui lòng đăng nhập lại.',
          code: 'SESSION_EXPIRED',
        );

        handler.reject(refreshError);
        return;
      }

      /*
       * Mất mạng, timeout hoặc backend lỗi 500:
       * giữ nguyên token, không chuyển về login.
       */
      if (refreshStatus == null || refreshStatus >= 500) {
        debugPrint(
          '[AUTH] Không xóa phiên vì lỗi mạng '
          'hoặc máy chủ tạm thời không hoạt động.',
        );

        handler.reject(refreshError);
        return;
      }

      /*
       * Các lỗi 4xx không xác định, ví dụ DTO
       * backend sai hoặc request validation lỗi:
       * không tự xóa phiên để tránh đăng xuất nhầm.
       */
      debugPrint(
        '[AUTH] Refresh bị từ chối nhưng không '
        'thuộc lỗi hết phiên. Giữ nguyên phiên.',
      );

      handler.reject(refreshError);
      return;
    } catch (e) {
      debugPrint('[AUTH] Lỗi refresh không xác định: $e');

      /*
       * Không xóa phiên với lỗi không xác định.
       */
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: e,
          type: DioExceptionType.unknown,
        ),
      );

      return;
    }

    /*
     * GIAI ĐOẠN 2:
     * Refresh đã thành công, gọi lại API ban đầu.
     *
     * Phải nằm ngoài try/catch refresh.
     */
    final RequestOptions retryOptions = err.requestOptions;

    retryOptions.extra[_authRetriedKey] = true;

    retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';

    _cloneMultipartBodyForRetry(retryOptions);

    try {
      debugPrint(
        '[AUTH] Gọi lại API sau refresh: '
        '${retryOptions.method} '
        '${retryOptions.uri}',
      );

      final Response<dynamic> retryResponse = await dio.fetch(retryOptions);

      handler.resolve(retryResponse);
      return;
    } on DioException catch (retryError) {
      debugPrint(
        '[AUTH] API vẫn lỗi sau refresh: '
        '${retryOptions.method} '
        '${retryOptions.uri}',
      );

      debugPrint(
        '[AUTH] Retry status: '
        '${retryError.response?.statusCode}',
      );

      debugPrint(
        '[AUTH] Retry data: '
        '${retryError.response?.data}',
      );

      /*
       * Không xóa phiên tại đây.
       * Cặp token mới vừa được cấp thành công.
       */
      handler.reject(retryError);
      return;
    } catch (e) {
      debugPrint('[AUTH] Lỗi gọi lại API: $e');

      handler.reject(
        DioException(
          requestOptions: retryOptions,
          error: e,
          type: DioExceptionType.unknown,
        ),
      );

      return;
    }
  }

  String? _extractBearerToken(dynamic authorizationHeader) {
    final String value = authorizationHeader?.toString().trim() ?? '';

    if (value.isEmpty) {
      return null;
    }

    if (value.toLowerCase().startsWith('bearer ')) {
      final String token = value.substring(7).trim();

      return token.isEmpty ? null : token;
    }

    return value;
  }

  String _extractErrorCode(dynamic data) {
    final Map<String, dynamic> map = _toMap(data);

    return (map['code'] ?? map['Code'])?.toString().trim().toUpperCase() ?? '';
  }

  Map<String, dynamic> _toMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return <String, dynamic>{};
  }

  Map<String, dynamic>? _toNullableMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return null;
  }

  String? _getManvFromToken(String? token) {
    if (token == null || token.trim().isEmpty) {
      return null;
    }

    try {
      final List<String> parts = token.split('.');

      if (parts.length != 3) {
        return null;
      }

      final String normalized = base64Url.normalize(parts[1]);

      final dynamic payload = jsonDecode(
        utf8.decode(base64Url.decode(normalized)),
      );

      if (payload is Map) {
        final String manv = payload['manv']?.toString().trim() ?? '';

        return manv.isEmpty ? null : manv;
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  Future<void> _handlePasswordExpired() async {
    if (_isNavigatingAuthError) {
      return;
    }

    _isNavigatingAuthError = true;

    final String? token =
        _inMemoryToken ?? await _secureStorage.read(key: 'access_token');

    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final String? manv = _getManvFromToken(token) ?? prefs.getString('manv');

    _inMemoryToken = null;

    await _secureStorage.delete(key: 'access_token');

    await _secureStorage.delete(key: 'refresh_token');

    await prefs.remove('tennv');
    await prefs.remove('avatar');
    await prefs.remove('makhoa');

    if (manv != null && manv.trim().isNotEmpty) {
      final String normalizedManv = manv.trim();

      await prefs.setString('manv', normalizedManv);

      await prefs.setString('pending_password_change_manv', normalizedManv);
    }

    authStateListener?.call('PASSWORD_EXPIRED', manv);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/change-password',
        (route) => false,
        arguments: {'isForced': true, 'manv': manv},
      );

      _isNavigatingAuthError = false;
    });
  }

  Future<void> _clearSessionAndGoLogin({
    required String message,
    required String code,
  }) async {
    if (_isNavigatingAuthError) {
      return;
    }

    _isNavigatingAuthError = true;
    _inMemoryToken = null;

    await _secureStorage.delete(key: 'access_token');

    await _secureStorage.delete(key: 'refresh_token');

    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.remove('manv');
    await prefs.remove('tennv');
    await prefs.remove('avatar');
    await prefs.remove('makhoa');

    await prefs.remove('pending_password_change_manv');

    authStateListener?.call(code, null);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );

      AppHelpersSafe.showError(message);

      _isNavigatingAuthError = false;
    });
  }
}

/// Tránh phụ thuộc trực tiếp vào AppHelpers
/// trong interceptor.
class AppHelpersSafe {
  static void showError(String message) {
    final BuildContext? context = navigatorKey.currentContext;

    if (context == null) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
  }
}
