import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/cham_cong_phep_model.dart';
import '../utils/constants.dart';
import 'api_client.dart';

class ChamCongPhepService {
  final ApiClient _apiClient = ApiClient();

  // =========================================================
  // DANH SÁCH NGƯỜI DUYỆT
  //
  // Dùng chung cho cả luồng cũ và V2.
  // Backend tự lấy theo MANV đang đăng nhập.
  // =========================================================

  Future<List<ChamCongPhepNguoiDuyetResponseDto>>
      getDanhSachNguoiDuyet() async {
    try {
      final response =
          await _apiClient.dio.get(
        '${AppConstants.baseUrl}/ChamCongPhep/danh-sach-nguoi-duyet',
      );

      debugPrint(
        '--- DEBUG API NGƯỜI DUYỆT ---',
      );
      debugPrint(
        response.data.toString(),
      );

      if (response.data['data'] != null) {
        final List data =
            response.data['data'];

        return data
            .map(
              (e) =>
                  ChamCongPhepNguoiDuyetResponseDto
                      .fromJson(e),
            )
            .toList();
      }

      return [];
    } catch (e) {
      debugPrint(
        '❌ LỖI GET NGƯỜI DUYỆT: $e',
      );

      return [];
    }
  }

  // =========================================================
  // KÝ HIỆU
  // =========================================================

  Future<List<ChamCongPhepKyHieuResponseDto>>
      getDanhSachKyHieu() async {
    try {
      final response =
          await _apiClient.dio.get(
        '${AppConstants.baseUrl}/ChamCongPhep/danh-sach-ky-hieu',
      );

      if (response.data['data'] != null) {
        final List data =
            response.data['data'];

        return data
            .map(
              (e) =>
                  ChamCongPhepKyHieuResponseDto
                      .fromJson(e),
            )
            .toList();
      }

      return [];
    } catch (e) {
      debugPrint(
        '❌ LỖI GET KÝ HIỆU: $e',
      );

      return [];
    }
  }

  // =========================================================
  // TẠO ĐƠN CŨ
  //
  // GIỮ NGUYÊN - KHÔNG XÓA.
  // =========================================================

  Future<String?> taoDonXinPhep(
    ChamCongPhepCreateRequestDto dto,
  ) async {
    try {
      final response =
          await _apiClient.dio.post(
        '${AppConstants.baseUrl}/ChamCongPhep/tao-don',
        data: dto.toJson(),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        return null;
      }

      return 'Lỗi không xác định';
    } on DioException catch (e) {
      return _getDioMessage(
        e,
        'Thêm mới đơn xin nghỉ thất bại',
      );
    }
  }

  // =========================================================
  // TẠO ĐƠN V2
  //
  // Flutter mới gọi hàm này.
  //
  // DTO phải có:
  // nguoiDuyet = MANV người dùng đã chọn.
  // =========================================================

  Future<String?> taoDonXinPhepV2(
    ChamCongPhepCreateRequestDto dto,
  ) async {
    try {
      debugPrint(
        '====== TẠO ĐƠN NGHỈ PHÉP V2 ======',
      );

      debugPrint(
        dto.toJson().toString(),
      );

      final response =
          await _apiClient.dio.post(
        '${AppConstants.baseUrl}/ChamCongPhep/tao-don-v2',
        data: dto.toJson(),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        return null;
      }

      return response.data?['message']
              ?.toString() ??
          'Tạo đơn xin nghỉ thất bại';
    } on DioException catch (e) {
      debugPrint(
        '❌ LỖI TẠO ĐƠN V2: ${e.response?.data}',
      );

      return _getDioMessage(
        e,
        'Tạo đơn xin nghỉ thất bại',
      );
    } catch (e) {
      debugPrint(
        '❌ LỖI TẠO ĐƠN V2: $e',
      );

      return 'Có lỗi xảy ra khi tạo đơn.';
    }
  }

  // =========================================================
  // SỬA ĐƠN CŨ
  //
  // GIỮ NGUYÊN.
  // =========================================================

  Future<String?> suaDonXinPhep(
    String ngayLap,
    ChamCongPhepCreateRequestDto dto,
  ) async {
    try {
      final response =
          await _apiClient.dio.put(
        '${AppConstants.baseUrl}/ChamCongPhep/sua-don',
        queryParameters: {
          'ngayLap': ngayLap,
        },
        data: dto.toJson(),
      );

      if (response.statusCode == 200) {
        return null;
      }

      return 'Lỗi không xác định';
    } on DioException catch (e) {
      return _getDioMessage(
        e,
        'Cập nhật đơn xin nghỉ thất bại',
      );
    }
  }

  // =========================================================
  // SỬA ĐƠN V2
  // =========================================================

  Future<String?> suaDonXinPhepV2(
    String ngayLap,
    ChamCongPhepCreateRequestDto dto,
  ) async {
    try {
      final response =
          await _apiClient.dio.put(
        '${AppConstants.baseUrl}/ChamCongPhep/sua-don-v2',
        queryParameters: {
          'ngayLap': ngayLap,
        },
        data: dto.toJson(),
      );

      if (response.statusCode == 200) {
        return null;
      }

      return response.data?['message']
              ?.toString() ??
          'Cập nhật đơn xin nghỉ thất bại';
    } on DioException catch (e) {
      return _getDioMessage(
        e,
        'Cập nhật đơn xin nghỉ thất bại',
      );
    }
  }

  // =========================================================
  // XÓA
  // =========================================================

  Future<bool> xoaDonXinPhep(
    String ngayLap,
  ) async {
    try {
      final response =
          await _apiClient.dio.delete(
        '${AppConstants.baseUrl}/ChamCongPhep/xoa-don',
        queryParameters: {
          'ngayLap': ngayLap,
        },
      );

      return response.statusCode == 200 ||
          response.statusCode == 204;
    } catch (e) {
      debugPrint(
        '❌ LỖI API XÓA ĐƠN NGHỈ PHÉP: $e',
      );

      return false;
    }
  }

  // =========================================================
  // LỊCH SỬ
  // =========================================================

  Future<List<ChamCongPhepPhieuNghiResponseDto>>
      getLichSuXinNghi({
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final Map<String, dynamic> query =
          {};

      if (fromDate != null) {
        query['fromDate'] =
            fromDate;
      }

      if (toDate != null) {
        query['toDate'] =
            toDate;
      }

      final response =
          await _apiClient.dio.get(
        '${AppConstants.baseUrl}/ChamCongPhep/lich-su-cua-toi',
        queryParameters: query,
      );

      if (response.data['data'] != null) {
        final List data =
            response.data['data'];

        return data
            .map(
              (e) =>
                  ChamCongPhepPhieuNghiResponseDto
                      .fromJson(e),
            )
            .toList();
      }

      return [];
    } catch (e) {
      debugPrint(
        '❌ LỖI GET LỊCH SỬ XIN NGHỈ: $e',
      );

      return [];
    }
  }

  // =========================================================
  // DÀNH CHO NGƯỜI DUYỆT
  // =========================================================

  Future<List<ChamCongPhepPhieuNghiResponseDto>>
      getDanhSachChoDuyet({
    String? fromDate,
    String? toDate,
    int? trangThai,
    String? searchKeyword,
  }) async {
    try {
      final response =
          await _apiClient.dio.get(
        '${AppConstants.baseUrl}/ChamCongPhep/danh-sach-cho-duyet',
        queryParameters: {
          if (fromDate != null)
            'fromDate': fromDate,
          if (toDate != null)
            'toDate': toDate,
          if (trangThai != null &&
              trangThai != -1)
            'trangThai': trangThai,
          if (searchKeyword != null &&
              searchKeyword.isNotEmpty)
            'searchKeyword':
                searchKeyword,
        },
      );

      if (response.data['success'] ==
          true) {
        final List data =
            response.data['data'] ?? [];

        return data
            .map(
              (json) =>
                  ChamCongPhepPhieuNghiResponseDto
                      .fromJson(json),
            )
            .toList();
      }

      return [];
    } catch (e) {
      debugPrint(
        '❌ LỖI GET DANH SÁCH CHỜ DUYỆT: $e',
      );

      rethrow;
    }
  }

  // =========================================================
  // XỬ LÝ ĐƠN
  // =========================================================

  Future<String?> xuLyDon(
    ChamCongPhepRequestDto dto,
  ) async {
    try {
      final response =
          await _apiClient.dio.put(
        '${AppConstants.baseUrl}/ChamCongPhep/xu-ly-don',
        data: dto.toJson(),
      );

      if (response.statusCode == 200) {
        return null;
      }

      return 'Lỗi không xác định';
    } on DioException catch (e) {
      return _getDioMessage(
        e,
        'Xử lý đơn thất bại',
      );
    }
  }

  // =========================================================
  // HỦY DUYỆT
  // =========================================================

  Future<String?> huyDuyetDon(
    String ngayLap,
    String manvXin,
  ) async {
    try {
      final response =
          await _apiClient.dio.put(
        '${AppConstants.baseUrl}/ChamCongPhep/huy-duyet',
        queryParameters: {
          'ngayLap': ngayLap,
          'manvXin': manvXin,
        },
      );

      if (response.statusCode == 200) {
        return null;
      }

      return 'Lỗi không xác định';
    } on DioException catch (e) {
      return _getDioMessage(
        e,
        'Hủy duyệt thất bại',
      );
    }
  }

  // =========================================================
  // CHECK QUYỀN
  // =========================================================

  Future<bool> checkQuyenDuyet() async {
    try {
      final response =
          await _apiClient.dio.get(
        '${AppConstants.baseUrl}/ChamCongPhep/kiem-tra-quyen',
      );

      if (response.data['success'] ==
          true) {
        return response.data['data'] ==
            true;
      }

      return false;
    } catch (e) {
      debugPrint(
        '❌ LỖI CHECK QUYỀN DUYỆT: $e',
      );

      return false;
    }
  }

  // =========================================================
  // HELPER LẤY MESSAGE TỪ DIO
  // =========================================================

  String _getDioMessage(
    DioException e,
    String defaultMessage,
  ) {
    try {
      final dynamic data =
          e.response?.data;

      if (data is Map &&
          data['message'] != null) {
        return data['message']
            .toString();
      }

      if (data is String &&
          data.trim().isNotEmpty) {
        return data;
      }
    } catch (_) {}

    if (e.response == null) {
      return 'Lỗi kết nối máy chủ';
    }

    return defaultMessage;
  }
}