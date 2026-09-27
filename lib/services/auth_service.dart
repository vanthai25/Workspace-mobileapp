import 'package:dio/dio.dart';

import '../models/user_model.dart';
import '../utils/constants.dart';
import 'api_client.dart';
import 'auth_api_exception.dart';

class AuthService {
  final ApiClient _apiClient =
      ApiClient();

  Dio get _dio => _apiClient.dio;

  // =========================================================
  // LOGIN V2
  // =========================================================

  Future<AuthData> login(
    String manv,
    String passwordHash,
  ) async {
    try {
      final Response<dynamic> response =
          await _dio.post(
        '${AppConstants.authV2Url}/login',
        data: {
          'manv': manv.trim(),
          'passwordHash': passwordHash,
        },
      );

      final Map<String, dynamic> body =
          _toMap(response.data);

      if (body['success'] == true) {
        final Map<String, dynamic>? data =
            _toNullableMap(body['data']);

        if (data == null) {
          throw const AuthApiException(
            code: 'LOGIN_DATA_MISSING',
            message:
                'Máy chủ không trả về '
                'dữ liệu đăng nhập.',
          );
        }

        return AuthData.fromJson(data);
      }

      throw AuthApiException(
        code: _readCode(
          body,
          'LOGIN_FAILED',
        ),
        message: _readMessage(
          body,
          'Đăng nhập không thành công.',
        ),
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      _throwDioException(
        e,
        'Không thể kết nối máy chủ '
        'để đăng nhập.',
      );
    }
  }

  // =========================================================
  // REFRESH TOKEN V2
  // =========================================================

  Future<AuthData> refreshAccessToken(
    String refreshToken,
  ) async {
    try {
      final Response<dynamic> response =
          await _dio.post(
        '${AppConstants.authV2Url}/refresh-token',
        data: {
          'refreshToken': refreshToken,
        },
      );

      final Map<String, dynamic> body =
          _toMap(response.data);

      if (body['success'] == true) {
        final Map<String, dynamic>? data =
            _toNullableMap(body['data']);

        if (data == null) {
          throw const AuthApiException(
            code:
                'REFRESH_DATA_MISSING',
            message:
                'Máy chủ không trả về '
                'token mới.',
          );
        }

        return AuthData.fromJson(data);
      }

      throw AuthApiException(
        code: _readCode(
          body,
          'SESSION_EXPIRED',
        ),
        message: _readMessage(
          body,
          'Phiên đăng nhập đã hết hạn.',
        ),
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      _throwDioException(
        e,
        'Không thể làm mới '
        'phiên đăng nhập.',
      );
    }
  }

  // =========================================================
  // CHANGE PASSWORD V2
  // =========================================================

  Future<bool> changePassword(
    String manv,
    String oldPassword,
    String newPassword,
  ) async {
    try {
      final Response<dynamic> response =
          await _dio.post(
        '${AppConstants.authV2Url}'
        '/change-password',
        data: {
          'manv': manv.trim(),
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        },
      );

      final Map<String, dynamic> body =
          _toMap(response.data);

      if (body['success'] == true) {
        return true;
      }

      throw AuthApiException(
        code: _readCode(
          body,
          'CHANGE_PASSWORD_FAILED',
        ),
        message: _readMessage(
          body,
          'Đổi mật khẩu không thành công.',
        ),
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      _throwDioException(
        e,
        'Không thể kết nối máy chủ '
        'để đổi mật khẩu.',
      );
    }
  }

  // =========================================================
  // REGISTER V1
  // =========================================================

  Future<bool> register(
    String manv,
    String password,
    String email,
    String role,
  ) async {
    try {
      final Response<dynamic> response =
          await _dio.post(
        '${AppConstants.baseUrl}'
        '/Auth/register',
        data: {
          'manv': manv.trim(),
          'passwordHash': password,
          'email': email.trim(),
          'role': role,
        },
      );

      final Map<String, dynamic> body =
          _toMap(response.data);

      if (body['success'] == true) {
        return true;
      }

      throw AuthApiException(
        code: 'REGISTER_FAILED',
        message:
            _apiClient.translateError(
          body['message']?.toString(),
        ),
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      _throwDioException(
        e,
        'Không thể kết nối máy chủ '
        'để đăng ký.',
      );
    }
  }

  // =========================================================
  // FORGOT PASSWORD V1
  // =========================================================

  Future<bool> forgotPassword(
    String manv,
    String email,
  ) async {
    try {
      final Response<dynamic> response =
          await _dio.post(
        '${AppConstants.baseUrl}'
        '/User/forgot-password',
        data: {
          'manv': manv.trim(),
          'email': email.trim(),
        },
      );

      final Map<String, dynamic> body =
          _toMap(response.data);

      if (body['success'] == true) {
        return true;
      }

      throw AuthApiException(
        code:
            'FORGOT_PASSWORD_FAILED',
        message:
            _apiClient.translateError(
          body['message']?.toString(),
        ),
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      _throwDioException(
        e,
        'Không thể gửi yêu cầu '
        'quên mật khẩu.',
      );
    }
  }

  // =========================================================
  // RESET PASSWORD V1
  // =========================================================

  Future<bool> resetPassword(
    String email,
    String otpToken,
    String newPassword,
  ) async {
    try {
      final Response<dynamic> response =
          await _dio.post(
        '${AppConstants.baseUrl}'
        '/User/reset-password',
        data: {
          'email': email.trim(),
          'token': otpToken.trim(),
          'newPassword': newPassword,
        },
      );

      final Map<String, dynamic> body =
          _toMap(response.data);

      if (body['success'] == true) {
        return true;
      }

      throw AuthApiException(
        code:
            'RESET_PASSWORD_FAILED',
        message:
            _apiClient.translateError(
          body['message']?.toString(),
        ),
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      _throwDioException(
        e,
        'Không thể kết nối máy chủ '
        'để khôi phục mật khẩu.',
      );
    }
  }

  // =========================================================
  // LOGOUT V1
  // =========================================================

  Future<void> logoutApi(
    int userId, {
    String? fcmToken,
  }) async {
    try {
      await _dio.post(
        '${AppConstants.baseUrl}'
        '/Auth/logout/$userId',
        queryParameters: {
          if (fcmToken != null &&
              fcmToken.trim().isNotEmpty)
            'fcmToken': fcmToken.trim(),
        },
      );
    } catch (_) {
      /*
       * Không chặn logout local khi API
       * logout đang lỗi hoặc mất mạng.
       */
    }
  }

  Map<String, dynamic> _toMap(
    dynamic value,
  ) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(
        value,
      );
    }

    return <String, dynamic>{};
  }

  Map<String, dynamic>? _toNullableMap(
    dynamic value,
  ) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(
        value,
      );
    }

    return null;
  }

  String _readCode(
    Map<String, dynamic> body,
    String fallback,
  ) {
    final String value =
        (body['code'] ?? body['Code'])
                ?.toString()
                .trim()
                .toUpperCase() ??
            '';

    return value.isEmpty
        ? fallback
        : value;
  }

  String _readMessage(
    Map<String, dynamic> body,
    String fallback,
  ) {
    final String value =
        (body['message'] ??
                    body['Message'])
                ?.toString()
                .trim() ??
            '';

    return value.isEmpty
        ? fallback
        : value;
  }

  Never _throwDioException(
    DioException exception,
    String fallbackMessage,
  ) {
    final Map<String, dynamic> body =
        _toMap(exception.response?.data);

    final String code = _readCode(
      body,
      'API_ERROR',
    );

    final String rawMessage =
        _readMessage(
      body,
      fallbackMessage,
    );

    final String message =
        code == 'API_ERROR'
            ? _apiClient.translateError(
                rawMessage,
              )
            : rawMessage;

    throw AuthApiException(
      code: code,
      message: message,
      statusCode:
          exception.response?.statusCode,
    );
  }
}