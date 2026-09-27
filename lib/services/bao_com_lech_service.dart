import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/bao_com_lech_model.dart';
import '../utils/constants.dart';
import 'api_client.dart';

class BaoComLechApiException
    implements Exception {
  final String message;

  final int? statusCode;

  const BaoComLechApiException({
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => message;
}

class BaoComLechService {
  final Dio _dio =
      ApiClient().dio;

  String get _baseUrl =>
      '${AppConstants.baseUrl}'
      '/v2/BaoComLech';

  // =========================================================
  // DANH SÁCH
  // =========================================================

  Future<List<BaoComLechModel>>
      getDanhSach({
    required int thang,
    required int nam,
  }) async {
    try {
      final Response<dynamic> response =
          await _dio.get(
        _baseUrl,
        queryParameters: {
          'thang': thang,
          'nam': nam,
        },
      );

      final Map<String, dynamic> body =
          _toMap(
        response.data,
      );

      final dynamic rawData =
          body['data'] ??
              body['Data'];

      if (response.statusCode == 200 &&
          rawData is List) {
        return rawData
            .whereType<Map>()
            .map(
              (dynamic item) =>
                  BaoComLechModel
                      .fromJson(
                Map<String, dynamic>.from(
                  item as Map,
                ),
              ),
            )
            .toList();
      }

      throw BaoComLechApiException(
        statusCode:
            response.statusCode,
        message: _readMessage(
          body,
          'Không thể lấy dữ liệu lệch cơm.',
        ),
      );
    } on DioException catch (e) {
      throw _convertDioError(e);
    }
  }

  // =========================================================
  // TẠO / SỬA PHẢN HỒI
  // =========================================================

  Future<void> phanHoi({
    required int id,
    required String noiDung,
    String? hinhAnhPath,
    bool xoaHinhAnh = false,
  }) async {
    try {
      final Map<String, dynamic>
          formMap = {
        'PhanHoi': noiDung.trim(),
        'XoaHinhAnh':
            xoaHinhAnh,
      };

      if (hinhAnhPath != null &&
          hinhAnhPath.isNotEmpty) {
        final String fileName =
            hinhAnhPath
                .split('/')
                .last;

        formMap['HinhAnh'] =
            await MultipartFile
                .fromFile(
          hinhAnhPath,
          filename: fileName,
        );
      }

      final FormData formData =
          FormData.fromMap(
        formMap,
      );

      final Response<dynamic> response =
          await _dio.put(
        '$_baseUrl/$id/phan-hoi',
        data: formData,
      );

      if (response.statusCode == 200) {
        return;
      }

      final Map<String, dynamic> body =
          _toMap(
        response.data,
      );

      throw BaoComLechApiException(
        statusCode:
            response.statusCode,
        message: _readMessage(
          body,
          'Không thể gửi phản hồi.',
        ),
      );
    } on DioException catch (e) {
      throw _convertDioError(e);
    }
  }

  // =========================================================
  // XÓA PHẢN HỒI
  // =========================================================

  Future<void> xoaPhanHoi(
    int id,
  ) async {
    try {
      final Response<dynamic> response =
          await _dio.delete(
        '$_baseUrl/$id/phan-hoi',
      );

      if (response.statusCode == 200) {
        return;
      }

      final Map<String, dynamic> body =
          _toMap(
        response.data,
      );

      throw BaoComLechApiException(
        statusCode:
            response.statusCode,
        message: _readMessage(
          body,
          'Không thể xóa phản hồi.',
        ),
      );
    } on DioException catch (e) {
      throw _convertDioError(e);
    }
  }

  // =========================================================
  // LẤY ẢNH
  // =========================================================

  Future<Uint8List?>
      getHinhAnh(
    int id,
  ) async {
    try {
      final Response<List<int>>
          response =
          await _dio.get<List<int>>(
        '$_baseUrl/$id/hinh-anh',
        options: Options(
          responseType:
              ResponseType.bytes,
        ),
      );

      final List<int>? bytes =
          response.data;

      if (response.statusCode == 200 &&
          bytes != null &&
          bytes.isNotEmpty) {
        return Uint8List.fromList(
          bytes,
        );
      }

      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode ==
          404) {
        return null;
      }

      rethrow;
    }
  }

  // =========================================================
  // HELPERS
  // =========================================================

  BaoComLechApiException
      _convertDioError(
    DioException e,
  ) {
    final Map<String, dynamic> body =
        _toMap(
      e.response?.data,
    );

    return BaoComLechApiException(
      statusCode:
          e.response?.statusCode,
      message: _readMessage(
        body,
        'Không thể kết nối máy chủ.',
      ),
    );
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

    return {};
  }

  String _readMessage(
    Map<String, dynamic> body,
    String fallback,
  ) {
    final String message = (
      body['message'] ??
          body['Message'] ??
          ''
    ).toString().trim();

    return message.isEmpty
        ? fallback
        : message;
  }
  Future<int> getCurrentMonthCount() async {
  try {
    final response =
        await _dio.get(
      '${AppConstants.baseUrl}'
      '/v2/BaoComLech/count-current-month',
    );

    if (response.statusCode != 200) {
      return 0;
    }

    final dynamic body =
        response.data;

    if (body is! Map) {
      return 0;
    }

    final dynamic data =
        body['data'] ??
            body['Data'];

    if (data is! Map) {
      return 0;
    }

    final dynamic rawCount =
        data['soLuong'] ??
            data['SoLuong'];

    if (rawCount is int) {
      return rawCount;
    }

    return int.tryParse(
          rawCount?.toString() ?? '',
        ) ??
        0;
  } catch (e) {
    debugPrint(
      '[BAO COM LECH COUNT] $e',
    );

    return 0;
  }
}
}