import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/luong_model.dart';
import '../utils/constants.dart';
import 'api_client.dart';

class LuongApiException
    implements Exception {
  final String message;
  final int? statusCode;
  final String? code;

  const LuongApiException({
    required this.message,
    this.statusCode,
    this.code,
  });

  @override
  String toString() => message;
}

class LuongService {
  final ApiClient _apiClient =
      ApiClient();

  Dio get _dio =>
      _apiClient.dio;

  Future<LuongThangModel?>
      getLuongThang({
    required int thang,
    required int nam,
  }) async {
    try {
      final Response<dynamic> response =
          await _dio.get(
        '${AppConstants.baseUrl}'
        '/v2/Luong',
        queryParameters: {
          'thang': thang,
          'nam': nam,
        },
      );

      final Map<String, dynamic> body =
          _toMap(
        response.data,
      );

      final bool success =
          body['success'] == true ||
          body['Success'] == true;

      final Map<String, dynamic>?
          data =
          _toNullableMap(
        body['data'] ??
            body['Data'],
      );

      if (response.statusCode == 200 &&
          success &&
          data != null) {
        return LuongThangModel.fromJson(
          data,
        );
      }

      if (response.statusCode == 404) {
        return null;
      }

      throw LuongApiException(
        statusCode: response.statusCode,
        code: _readCode(body),
        message: _readMessage(
          body,
          'Không thể lấy dữ liệu lương.',
        ),
      );
    } on DioException catch (e) {
      /*
       * Không có dữ liệu lương tháng này
       * không xem là lỗi hệ thống.
       */
      if (e.response?.statusCode == 404) {
        return null;
      }

      final Map<String, dynamic> body =
          _toMap(
        e.response?.data,
      );

      throw LuongApiException(
        statusCode:
            e.response?.statusCode,
        code: _readCode(body),
        message: _readMessage(
          body,
          _getFallbackMessage(e),
        ),
      );
    }
  }
  Future<List<LuongThucLinhThangModel>>
    getThucLinhTheoNam({
    required int nam,
  }) async {
    final String url =
        '${AppConstants.baseUrl}'
        '/v2/Luong/thuc-linh-theo-nam';

    try {
      debugPrint(
        '[LUONG CHART] GET $url?nam=$nam',
      );

      final Response<dynamic> response =
          await _dio.get(
        url,
        queryParameters: {
          'nam': nam,
        },
      );

      debugPrint(
        '[LUONG CHART] STATUS: '
        '${response.statusCode}',
      );

      final dynamic responseData =
          response.data;

      if (response.statusCode == 200 &&
          responseData is Map) {
        final dynamic rawData =
            responseData['data'] ??
            responseData['Data'];

        if (rawData is List) {
          final List<
                  LuongThucLinhThangModel>
              result =
              rawData.map(
            (dynamic e) {
              return LuongThucLinhThangModel
                  .fromJson(
                Map<String, dynamic>.from(
                  e as Map,
                ),
              );
            },
          ).toList();

          result.sort(
            (
              LuongThucLinhThangModel a,
              LuongThucLinhThangModel b,
            ) =>
                a.thang.compareTo(
              b.thang,
            ),
          );

          return result;
        }
      }

      throw const LuongApiException(
        message:
            'Dữ liệu biểu đồ lương không hợp lệ.',
      );
  } on DioException catch (e) {
    debugPrint(
      '[LUONG CHART] ERROR STATUS: '
      '${e.response?.statusCode}',
    );

    debugPrint(
      '[LUONG CHART] ERROR BODY: '
      '${e.response?.data}',
    );

    final dynamic body =
        e.response?.data;

    String message =
        'Không thể tải biểu đồ lương.';

    if (body is Map) {
      message = (
        body['message'] ??
        body['Message'] ??
        message
      ).toString();
    }

    throw LuongApiException(
      message: message,
      statusCode:
          e.response?.statusCode,
    );
  }
}
  String _getFallbackMessage(
    DioException error,
  ) {
    switch (error.type) {
      case DioExceptionType
            .connectionTimeout:
      case DioExceptionType
            .sendTimeout:
      case DioExceptionType
            .receiveTimeout:
        return 'Kết nối máy chủ quá thời gian. '
            'Vui lòng thử lại.';

      case DioExceptionType
            .connectionError:
        return 'Không thể kết nối máy chủ. '
            'Vui lòng kiểm tra mạng.';

      default:
        return 'Không thể tải dữ liệu lương. '
            'Vui lòng thử lại.';
    }
  }

  String _readMessage(
    Map<String, dynamic> body,
    String fallback,
  ) {
    final String value = (
      body['message'] ??
      body['Message'] ??
      ''
    ).toString().trim();

    return value.isEmpty
        ? fallback
        : value;
  }

  String? _readCode(
    Map<String, dynamic> body,
  ) {
    final String value = (
      body['code'] ??
      body['Code'] ??
      ''
    ).toString().trim();

    return value.isEmpty
        ? null
        : value;
  }

  Map<String, dynamic> _toMap(
    dynamic value,
  ) {
    if (value
        is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(
        value,
      );
    }

    return <String, dynamic>{};
  }

  Map<String, dynamic>?
      _toNullableMap(
    dynamic value,
  ) {
    if (value
        is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(
        value,
      );
    }

    return null;
  }
}