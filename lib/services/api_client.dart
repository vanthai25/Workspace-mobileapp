import 'package:dio/dio.dart';

import 'auth_interceptor.dart';

class ApiClient {
  static final ApiClient _instance =
      ApiClient._internal();

  factory ApiClient() => _instance;

  late final Dio dio;

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        connectTimeout:
            const Duration(seconds: 30),
        receiveTimeout:
            const Duration(seconds: 30),
        sendTimeout:
            const Duration(seconds: 30),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      AuthInterceptor(dio),
    );

    /*
     * Có thể mở khi cần debug request API.
     */
    // dio.interceptors.add(
    //   LogInterceptor(
    //     requestBody: true,
    //     responseBody: true,
    //     requestHeader: false,
    //     responseHeader: false,
    //   ),
    // );
  }

  String translateError(String? rawError) {
    if (rawError == null ||
        rawError.trim().isEmpty) {
      return 'Đã có lỗi xảy ra. '
          'Vui lòng thử lại.';
    }

    final String error = rawError.trim();
    final String lower =
        error.toLowerCase();

    if (lower.contains('user_locked') ||
        lower.contains(
          'user account is locked',
        ) ||
        lower.contains(
          'tài khoản đã bị khóa',
        )) {
      return 'Tài khoản của bạn đã bị khóa. '
          'Vui lòng liên hệ Admin.';
    }

    if (lower.contains(
          'password_expired',
        ) ||
        lower.contains(
          'password_hethan',
        ) ||
        lower.contains(
          'password expries',
        ) ||
        lower.contains(
          'password expires',
        ) ||
        lower.contains('pass hết hạn') ||
        lower.contains(
          'mật khẩu đã hết hạn',
        )) {
      return 'Mật khẩu của bạn đã hết hạn. '
          'Vui lòng đổi mật khẩu mới.';
    }

    if (lower.contains(
          'invalid_password',
        ) ||
        lower.contains(
          'invalid password',
        ) ||
        lower.contains(
          'invalid credentials',
        ) ||
        lower.contains('sai mật khẩu')) {
      return 'Tài khoản hoặc mật khẩu '
          'không chính xác.';
    }

    if (lower.contains(
          'old_password_invalid',
        ) ||
        lower.contains(
          'old password is incorrect',
        ) ||
        lower.contains(
          'mật khẩu cũ sai',
        )) {
      return 'Mật khẩu hiện tại '
          'không chính xác.';
    }

    if (lower.contains(
      'new_password_same_as_old',
    )) {
      return 'Mật khẩu mới không được trùng '
          'với mật khẩu hiện tại.';
    }

    if (lower.contains(
          'user_not_found',
        ) ||
        lower.contains(
          'user not found',
        )) {
      return 'Tài khoản không tồn tại.';
    }

    if (lower.contains(
          'session_expired',
        ) ||
        lower.contains(
          'invalid or expired refresh token',
        )) {
      return 'Phiên đăng nhập đã hết hạn. '
          'Vui lòng đăng nhập lại.';
    }

    if (lower.contains(
      'token_reused',
    )) {
      return 'Phiên đăng nhập không an toàn. '
          'Vui lòng đăng nhập lại.';
    }

    if (lower.contains(
      'network error',
    )) {
      return 'Không thể kết nối máy chủ. '
          'Vui lòng kiểm tra mạng.';
    }

    return error;
  }
}

/// Giữ tương thích với file cũ nào đang gọi
/// translateError(...) trực tiếp.
String translateError(String? rawError) {
  return ApiClient().translateError(
    rawError,
  );
}