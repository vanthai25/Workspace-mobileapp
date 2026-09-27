import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../models/cham_truc_model.dart';
import '../utils/constants.dart';
import 'api_client.dart';

class ChamTrucApiException
    implements Exception {
  final String message;
  final int? statusCode;

  const ChamTrucApiException({
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => message;
}

class ChamTrucService {
  final Dio _dio =
      ApiClient().dio;

  String get _baseUrl =>
      '${AppConstants.baseUrl}'
      '/v2/ChamTruc';

  Future<List<ChamTrucModel>>
      getDanhSach({
    required DateTime ngay,
    String? coSo,
    String? maKhoa,
  }) async {
    try {
      final Map<String, dynamic>
          params = {
        'ngay': DateFormat(
          'yyyy-MM-dd',
        ).format(ngay),
      };

      if (coSo != null &&
          coSo.trim().isNotEmpty) {
        params['coSo'] =
            coSo.trim();
      }

      if (maKhoa != null &&
          maKhoa.trim().isNotEmpty) {
        params['maKhoa'] =
            maKhoa.trim();
      }

      final Response<dynamic> response =
          await _dio.get(
        _baseUrl,
        queryParameters: params,
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
              (item) =>
                  ChamTrucModel.fromJson(
                Map<String, dynamic>.from(
                  item,
                ),
              ),
            )
            .toList();
      }

      throw ChamTrucApiException(
        statusCode:
            response.statusCode,
        message: _readMessage(
          body,
          'Không thể tải danh sách trực.',
        ),
      );
    } on DioException catch (e) {
      final Map<String, dynamic> body =
          _toMap(
        e.response?.data,
      );

      throw ChamTrucApiException(
        statusCode:
            e.response?.statusCode,
        message: _readMessage(
          body,
          'Không thể kết nối máy chủ.',
        ),
      );
    }
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
    final String text = (
      body['message'] ??
          body['Message'] ??
          ''
    ).toString().trim();

    return text.isEmpty
        ? fallback
        : text;
  }
}