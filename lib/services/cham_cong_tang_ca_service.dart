import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/cham_cong_tang_ca_model.dart'; // Import Model của bạn
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'api_client.dart';

class ChamCongTangCaService {
  final Dio _dio = ApiClient().dio;

  Future<List<ChamCongTangCaModel>> getDanhSachPhieu({
  int? trangThai,
  bool chiCaNhan = false,
}) async {
  try {
    final response = await _dio.get(
      '${AppConstants.baseUrl}/ChamCongTangCa',
      queryParameters: {
        if (trangThai != null) 'trangThai': trangThai,
        'chiCaNhan': chiCaNhan,
      },
    );

    if (response.statusCode == 200 &&
        response.data['success'] == true) {
      final List<dynamic> data =
          response.data['data'] ?? [];

      return data
          .map(
            (json) => ChamCongTangCaModel.fromJson(json),
          )
          .toList();
    }

    return [];
  } on DioException catch (e) {
    String message = 'Không thể tải danh sách tăng ca';

    if (e.response?.data is Map) {
      message = e.response?.data['message'] ?? message;
    }

    throw Exception(message);
  } catch (e) {
    throw Exception('Có lỗi khi tải danh sách: $e');
  }
}

  // 2. Tạo phiếu tăng ca mới
  Future<bool> createPhieu({
    required DateTime batDau,
    required DateTime ketThuc,
    required int soPhut,
    required String lyDoTangCa,
  }) async {
    try {
      final response = await _dio.post(
        '${AppConstants.baseUrl}/ChamCongTangCa',
        data: {
          "batDau": batDau.toIso8601String(),
          "ketThuc": ketThuc.toIso8601String(),
          "soPhut": soPhut,
          "lyDoTangCa": lyDoTangCa,
        },
      );
      
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      String errorMessage = 'Lỗi kết nối đến máy chủ';
      if (e.response != null && e.response?.data != null) {
        errorMessage = e.response?.data['message'] ?? e.response?.data.toString();
      }
      AppHelpers.showSnackBar(errorMessage, isError: true);
      return false;
    } catch (e) {
      AppHelpers.showSnackBar('Có lỗi xảy ra: $e', isError: true);
      return false;
    }
  }

  // 3. Sửa phiếu tăng ca (Chỉ khi trạng thái = 0)
  Future<bool> updatePhieu(
    int id, {
    required DateTime batDau,
    required DateTime ketThuc,
    required int soPhut,
    required String lyDoTangCa,
  }) async {
    try {
      final response = await _dio.put(
        '${AppConstants.baseUrl}/ChamCongTangCa/$id',
        data: {
          "batDau": batDau.toIso8601String(),
          "ketThuc": ketThuc.toIso8601String(),
          "soPhut": soPhut,
          "lyDoTangCa": lyDoTangCa,
        },
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } on DioException catch (e) {
      String errorMessage = 'Lỗi kết nối đến máy chủ';
      if (e.response != null && e.response?.data != null) {
        errorMessage = e.response?.data['message'] ?? e.response?.data.toString();
      }
      AppHelpers.showSnackBar(errorMessage, isError: true);
      return false;
    } catch (e) {
      AppHelpers.showSnackBar('Có lỗi xảy ra: $e', isError: true);
      return false;
    }
  }

  // 4. Xóa phiếu tăng ca (Chỉ khi trạng thái = 0)
  Future<bool> deletePhieu(int id) async {
    try {
      final response = await _dio.delete(
        '${AppConstants.baseUrl}/ChamCongTangCa/$id',
      );
      return (response.statusCode == 200 || response.statusCode == 204);
    } on DioException catch (e) {
      String errorMessage = 'Lỗi kết nối đến máy chủ';
      if (e.response != null && e.response?.data != null) {
        errorMessage = e.response?.data['message'] ?? e.response?.data.toString();
      }
      AppHelpers.showSnackBar(errorMessage, isError: true);
      return false;
    } catch (e) {
      debugPrint('Lỗi deletePhieuTangCa: $e');
      return false;
    }
  }

  Future<bool> duyetPhieu(
      int id,
      int newStatus, {
      required String capDuyet,
      String lyDoTuChoi = '',
    }) async {
    try {
      final response = await _dio.post(
        '${AppConstants.baseUrl}/ChamCongTangCa/DuyetPhieu',
        data: {
          'id': id,
          'newStatus': newStatus,
          'lyDoTuChoi': lyDoTuChoi,
          'capDuyet': capDuyet,
        },
      );

      return response.statusCode == 200 &&
          response.data['success'] == true;
    } on DioException catch (e) {
      String message = 'Lỗi kết nối xử lý duyệt';

      if (e.response?.data is Map) {
        message = e.response?.data['message'] ?? message;
      }

      AppHelpers.showSnackBar(message, isError: true);
      return false;
    }
  }
  Future<bool> duyetNhieu({
  required Set<int> ids,
  required int newStatus,
  required String capDuyet,
  String lyDoTuChoi = '',
}) async {
  if (ids.isEmpty) {
    AppHelpers.showSnackBar(
      'Vui lòng chọn ít nhất một phiếu',
      isError: true,
    );
    return false;
  }

  try {
    final response = await _dio.post(
      '${AppConstants.baseUrl}/ChamCongTangCa/DuyetNhieu',
      data: {
        'ids': ids.toList(),
        'newStatus': newStatus,
        'capDuyet': capDuyet,
        'lyDoTuChoi': lyDoTuChoi,
      },
    );

    return response.statusCode == 200 &&
        response.data['success'] == true;
  } on DioException catch (e) {
    String message = 'Không thể xử lý các phiếu đã chọn';

    if (e.response?.data is Map) {
      message = e.response?.data['message'] ?? message;
    }

    AppHelpers.showSnackBar(message, isError: true);
    return false;
  }
}
}