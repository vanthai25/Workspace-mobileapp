import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/chamcong_bosung_model.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'api_client.dart';

class ChamCongBoSungService {
  final Dio _dio = ApiClient().dio;

  // 1. Lấy danh sách phiếu bổ sung
  Future<List<ChamCongBoSung>> getDanhSachPhieu({int? trangThai}) async {
    try {
      String url = '${AppConstants.baseUrl}/ChamCongBoSung';
      if (trangThai != null) {
        url += '?trangThai=$trangThai';
      }
      
      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => ChamCongBoSung.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Lỗi getDanhSachPhieu: $e');
      return [];
    }
  }

  Future<bool> createPhieuV2({
  required String noiDung,
  required String lyDo,
  required String ngayThieu,
  required double tongCong,
  required String coSo,
}) async {
  try {
    final response = await _dio.post(
      '${AppConstants.baseUrl}/ChamCongBoSung/v2',
      data: {
        'noidung': noiDung,
        'lydo': lyDo,
        'ngaythieu': ngayThieu,
        'tongcong': tongCong,
        'coso': coSo,
      },
    );

    return response.statusCode == 200 ||
        response.statusCode == 201;
  } on DioException catch (e) {
    final dynamic responseData = e.response?.data;

    final String message =
        responseData is Map
            ? responseData['message']?.toString() ??
                'Tạo phiếu thất bại'
            : 'Lỗi kết nối đến máy chủ';

    AppHelpers.showSnackBar(
      message,
      isError: true,
    );

    return false;
  } catch (e) {
    AppHelpers.showSnackBar(
      'Có lỗi xảy ra: $e',
      isError: true,
    );

    return false;
  }
}
Future<bool> updatePhieuV2(
  int id, {
  required String noiDung,
  required String lyDo,
  required String ngayThieu,
  required double tongCong,
  required String coSo,
}) async {
  try {
    final response = await _dio.put(
      '${AppConstants.baseUrl}/ChamCongBoSung/v2/$id',
      data: {
        'noidung': noiDung,
        'lydo': lyDo,
        'ngaythieu': ngayThieu,
        'tongcong': tongCong,
        'coso': coSo,
      },
    );

    return response.statusCode == 200 &&
        response.data['success'] == true;
  } on DioException catch (e) {
    final dynamic responseData = e.response?.data;

    final String message =
        responseData is Map
            ? responseData['message']?.toString() ??
                'Cập nhật phiếu thất bại'
            : 'Lỗi kết nối đến máy chủ';

    AppHelpers.showSnackBar(
      message,
      isError: true,
    );

    return false;
  } catch (e) {
    AppHelpers.showSnackBar(
      'Có lỗi xảy ra: $e',
      isError: true,
    );

    return false;
  }
}
  // 3. Thay đổi trạng thái (Duyệt / Từ chối)
  Future<bool> changeStatus(int id, int status, {String ghiChuTuChoi = ""}) async {
    try {
      final response = await _dio.put(
        '${AppConstants.baseUrl}/ChamCongBoSung/change-status/$id',
        queryParameters: {
          'status': status,
          'ghiChuTuChoi': ghiChuTuChoi,
        },
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint('Lỗi changeStatus: $e');
      return false;
    }
  }

  Future<BaoCaoChamCongLechV2Result?>
    getBaoCaoLechV2({
  required String tuNgay,
  required String denNgay,
  String? coSo,
}) async {
  try {
    final response = await _dio.get(
      '${AppConstants.baseUrl}/ChamCongBoSung/v2/bao-cao-lech',
      queryParameters: {
        'tuNgay': tuNgay,
        'denNgay': denNgay,

        // Lần đầu không truyền để backend
        // tự chọn theo Makhoa.
        if (coSo != null && coSo.trim().isNotEmpty)
          'coSo': coSo.trim(),
      },
    );

    if (response.statusCode == 200 &&
        response.data is Map &&
        response.data['success'] == true) {
      return BaoCaoChamCongLechV2Result.fromResponse(
        Map<String, dynamic>.from(
          response.data as Map,
        ),
      );
    }

    return null;
  } on DioException catch (e) {
    final dynamic responseData = e.response?.data;

    final String message =
        responseData is Map
            ? responseData['message']?.toString() ??
                'Không lấy được bảng công'
            : 'Không lấy được bảng công';

    AppHelpers.showSnackBar(
      message,
      isError: true,
    );

    return null;
  } catch (e) {
    debugPrint('Lỗi getBaoCaoLechV2: $e');

    AppHelpers.showSnackBar(
      'Có lỗi xảy ra khi tải bảng công',
      isError: true,
    );

    return null;
  }
}

  Future<bool> deletePhieu(int id) async {
    try {
      final response = await _dio.delete(
        '${AppConstants.baseUrl}/ChamCongBoSung/$id',
      );
      return (response.statusCode == 200 || response.statusCode == 204);
    } catch (e) {
      debugPrint('Lỗi deletePhieu: $e');
      return false;
    }
  }
  Future<List<PhieuBoSungModel>> getDanhSachPheDuyet({int? trangThai}) async {
    try {
      String url = '${AppConstants.baseUrl}/ChamCongBoSung/DanhSachDuyet';
      if (trangThai != null) url += '?trangThai=$trangThai';

      final response = await _dio.get(url);
      if (response.statusCode == 200 && response.data['data'] != null) {
        return (response.data['data'] as List).map((x) => PhieuBoSungModel.fromJson(x)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Lỗi getDanhSachPheDuyet: $e');
      return [];
    }
  }

  Future<bool> duyetPhieu(int id, int newStatus, {String ghiChuTuChoi = ''}) async {
    try {
      final response = await _dio.post(
        '${AppConstants.baseUrl}/ChamCongBoSung/DuyetPhieu',
        data: {
          "id": id,
          "newStatus": newStatus,
          "ghiChuTuChoi": ghiChuTuChoi
        },
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      String errorMessage = 'Lỗi kết nối C#';
      if (e.response != null && e.response?.data != null) {
        errorMessage = e.response?.data['message'] ?? e.response?.data.toString();
      }
      AppHelpers.showSnackBar(errorMessage, isError: true);
      return false;
    } catch (e) {
      AppHelpers.showSnackBar('Lỗi: $e', isError: true);
      return false;
    }
  }
  Future<Map<String, dynamic>?> getDashboardDuyet({
    required int month, required int year, 
    required int tabIndex, String keyword = '',
    required bool isRole6, required bool isRole7,
    String makhoa = '',bool isRole34 = false,
    bool isRole35 = false,
  }) async {
    try {
      final response = await _dio.get(
        '${AppConstants.baseUrl}/ChamCongBoSung/DashboardDuyet',
        queryParameters: {
          'month': month, 'year': year, 
          'tabIndex': tabIndex, 'keyword': keyword,
          'isRole6': isRole6, 'isRole7': isRole7,
          'makhoa': makhoa,'isRole34': isRole34,
          'isRole35': isRole35,
        },
      );
      if (response.statusCode == 200 && response.data['data'] != null) {
        return response.data['data']; 
      }
      return null;
    } catch (e) {
      debugPrint('Lỗi getDashboardDuyet: $e');
      return null;
    }
  }
  Future<List<Map<String, String>>> getDanhSachKhoa() async {
    try {
      final response = await _dio.get('${AppConstants.baseUrl}/Khoa', queryParameters: {
         'Page': 1,
         'PageSize': 999 
      });

      if (response.statusCode == 200 && response.data['data'] != null) {
        final List<dynamic> rawList = response.data['data'];
        return rawList.map((item) => {
          'makhoa': item['makhoa']?.toString() ?? '',
          'tenkhoa': item['tenkhoa']?.toString() ?? ''
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Lỗi tải danh sách khoa từ KhoaController: $e');
      return [];
    }
  }
  Future<List<ChamCongBoSung>> getDanhSachPhieuCaNhan({int? trangThai, required int month, required int year}) async {
    try {
      final response = await _dio.get(
        '${AppConstants.baseUrl}/ChamCongBoSung/LichSuCaNhan', 
        queryParameters: {
          if (trangThai != null) 'trangThai': trangThai,
          'month': month, 
          'year': year,  
        },
      );
      
      if (response.statusCode == 200 && response.data['data'] != null) {
        final List<dynamic> rawList = response.data['data'];
        return rawList.map((x) => ChamCongBoSung.fromJson(x)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Lỗi tải danh sách lịch sử cá nhân: $e');
      return [];
    }
  }
}