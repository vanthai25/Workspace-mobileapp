import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/su_kien_model.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'api_client.dart';

class SuKienService {
  final Dio _dio =
      ApiClient().dio;

  // =========================================================
  // SỰ KIỆN CÒN HẠN
  // =========================================================

  Future<List<SuKienModel>>
      getSuKienDangMo() async {
    try {
      final response =
          await _dio.get(
        '${AppConstants.baseUrl}'
        '/SuKien/dang-mo',
      );

      if (response.statusCode == 200 &&
          response.data is Map &&
          response.data['success'] ==
              true) {
        final List<dynamic> raw =
            response.data['data'] ??
                [];

        return raw
            .map(
              (x) =>
                  SuKienModel.fromJson(
                Map<String, dynamic>.from(
                  x,
                ),
              ),
            )
            .toList();
      }

      return [];
    } catch (e) {
      debugPrint(
        'Lỗi getSuKienDangMo: $e',
      );

      return [];
    }
  }

  // =========================================================
  // ĐĂNG KÝ CỦA TÔI
  // =========================================================

  Future<List<SuKienDangKyModel>>
      getDangKyCuaToi() async {
    try {
      final response =
          await _dio.get(
        '${AppConstants.baseUrl}'
        '/SuKien/dang-ky-cua-toi',
      );

      if (response.statusCode == 200 &&
          response.data is Map &&
          response.data['success'] ==
              true) {
        final List<dynamic> raw =
            response.data['data'] ??
                [];

        return raw
            .map(
              (x) =>
                  SuKienDangKyModel
                      .fromJson(
                Map<String, dynamic>.from(
                  x,
                ),
              ),
            )
            .toList();
      }

      return [];
    } catch (e) {
      debugPrint(
        'Lỗi getDangKyCuaToi: $e',
      );

      return [];
    }
  }

  // =========================================================
  // TẠO ĐĂNG KÝ
  // =========================================================

  Future<bool> dangKy({
  required int masukien,
  bool? coAn,
  int? soLuong,
  String? ghiChu,
}) async {
  try {
    final response =
        await _dio.post(
      '${AppConstants.baseUrl}/SuKien/dang-ky',
      data: {
        'masukien': masukien,
        'coAn': coAn,
        'soLuong': soLuong,
        'ghichu': ghiChu,
      },
    );

    final data =
        response.data;

    return data is Map &&
        (
          data['success'] == true ||
          data['Success'] == true
        );
  } on DioException catch (e) {
    final message =
        e.response?.data?['message'] ??
        e.response?.data?['Message'] ??
        'Không thể đăng ký sự kiện.';

    AppHelpers.showSnackBar(
      message.toString(),
      isError: true,
    );

    return false;
  } catch (e) {
    AppHelpers.showSnackBar(
      'Có lỗi khi đăng ký sự kiện.',
      isError: true,
    );

    return false;
  }
}
  Future<bool> updateDangKy(
  int id, {
  bool? coAn,
  int? soLuong,
  String? ghiChu,
}) async {
  try {
    final response =
        await _dio.put(
      '${AppConstants.baseUrl}/SuKien/dang-ky/$id',
      data: {
        'coAn': coAn,
        'soLuong': soLuong,
        'ghichu': ghiChu,
      },
    );

    final data =
        response.data;

    return data is Map &&
        (
          data['success'] == true ||
          data['Success'] == true
        );
  } on DioException catch (e) {
    final message =
        e.response?.data?['message'] ??
        e.response?.data?['Message'] ??
        'Không thể cập nhật đăng ký.';

    AppHelpers.showSnackBar(
      message.toString(),
      isError: true,
    );

    return false;
  } catch (e) {
    return false;
  }
}
  // =========================================================
  // HỦY = DELETE
  // =========================================================

  Future<bool> huyDangKy(
    int id,
  ) async {
    try {
      final response =
          await _dio.delete(
        '${AppConstants.baseUrl}'
        '/SuKien/dang-ky/$id',
      );

      final dynamic data =
          response.data;

      if (response.statusCode ==
              200 &&
          data is Map &&
          data['success'] == true) {
        return true;
      }

      _showApiError(
        data,
        'Hủy đăng ký thất bại.',
      );

      return false;
    } on DioException catch (e) {
      _showApiError(
        e.response?.data,
        'Không thể hủy đăng ký.',
      );

      return false;
    }
  }

  void _showApiError(
    dynamic raw,
    String fallback,
  ) {
    String message =
        fallback;

    if (raw is Map) {
      message = (
        raw['message'] ??
            raw['Message'] ??
            fallback
      ).toString();
    }

    AppHelpers.showSnackBar(
      message,
      isError: true,
    );
  }
}