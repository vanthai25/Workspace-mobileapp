import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/taisan_repair_model.dart';
import '../utils/constants.dart';
import 'api_client.dart';

class TaiSanRepairService {
  final Dio _dio = ApiClient().dio;

  Future<bool> createTaiSanRepair(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post('${AppConstants.baseUrl}/TaiSan_Repair/create', data: payload);
      return response.data['success'] == true;
    } catch (e) {
      debugPrint('Lỗi tạo phiếu sửa chữa: $e');
      return false;
    }
  }

  Future<List<int>> uploadFiles(List<String> filePaths) async {
    if (filePaths.isEmpty) return [];
    try {
      var formData = FormData();
      for (var path in filePaths) {
        formData.files.add(MapEntry('files', await MultipartFile.fromFile(path)));
      }

      final response = await _dio.post(
        '${AppConstants.baseUrl}/FileStorage/upload',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      if (response.statusCode == 200) {
        var fileIdsData = response.data['fileIds']; 
        if (fileIdsData is List) {
          return fileIdsData.map((e) => int.parse(e.toString())).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Lỗi upload file: $e');
      return [];
    }
  }
  Future<List<TaiSanRepair>> getTaiSanRepairs({
    String? fromDate,
    String? toDate,
    String? tentaisan,
    String? khoalap,
    String? khoanhan,
    String? nguoixutri,
    int? trangthaiphieu,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      Map<String, dynamic> params = {
        'Page': page,
        'PageSize': pageSize,
        'SortBy': 'ngaylap',
        'SortOrder': 'desc',
      };

      if (fromDate != null && fromDate.isNotEmpty) params['FromDate'] = fromDate;
      if (toDate != null && toDate.isNotEmpty) params['ToDate'] = toDate;
      if (tentaisan != null && tentaisan.isNotEmpty) params['Tentaisan'] = tentaisan;
      if (khoalap != null && khoalap.isNotEmpty) params['Khoalap'] = khoalap;
      if (khoanhan != null && khoanhan.isNotEmpty) params['Khoanhan'] = khoanhan;
      if (nguoixutri != null && nguoixutri.isNotEmpty) params['Nguoixutri'] = nguoixutri;
      if (trangthaiphieu != null) params['Trangthaiphieu'] = trangthaiphieu;
      final response = await _dio.get('${AppConstants.baseUrl}/TaiSan_Repair', queryParameters: params);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => TaiSanRepair.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Lỗi tải danh sách phiếu sửa chữa: $e');
      return [];
    }
  }
  Future<TaiSanRepair?> getTaiSanRepairById(int id) async {
    try {
      final response = await _dio.get('${AppConstants.baseUrl}/TaiSan_Repair/$id');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return TaiSanRepair.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      debugPrint('Lỗi tải chi tiết phiếu: $e');
      return null;
    }
  }
  Future<bool> updateRepairStatus(int id) async {
    try {
      final response = await _dio.put('${AppConstants.baseUrl}/TaiSan_Repair/updateStatus/$id');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Lỗi cập nhật trạng thái phiếu: $e');
      return false;
    }
  }
  Future<Map<String, String>> getEmployeeDictionary() async {
    try {
      final response = await _dio.get('${AppConstants.baseUrl}/NhanVien');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        Map<String, String> employeeDict = {};
        
        for (var item in data) {
          if (item['manv'] != null && item['tennv'] != null) {
            employeeDict[item['manv'].toString()] = item['tennv'].toString();
          }
        }
        return employeeDict;
      }
      return {};
    } catch (e) {
      debugPrint('Lỗi tải danh sách nhân viên: $e');
      return {};
    }
  }
  Future<bool> deleteTaiSanRepair(int id) async {
    try {
      final response = await _dio.delete('${AppConstants.baseUrl}/TaiSan_Repair/$id');
      
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        debugPrint('Lỗi xóa Backend: ${e.response?.data}');
      }
      return false;
    }
  }

  Future<bool> updateTaiSanRepair(int id, Map<String, dynamic> payload) async {
    try {
      var formData = FormData.fromMap({
        'Id': id,
        'Ngaylap': payload['ngaylap'] ?? '',
        'MaTaiSanId': payload['maTaiSanId'] ?? '',
        'Tentaisan': payload['tentaisan'] ?? '',
        'Vitrisudung': payload['vitrisudung'] ?? '',
        'Noidung': payload['noidung'] ?? '',
        'Nguoilap': payload['nguoilap'] ?? '',
        'Khoalap': payload['khoalap'] ?? '',
        'Khoanhan': payload['khoanhan'] ?? '',
        'Trangthaiphieu': 0, 
        'Mucuutien': payload['mucuutien'] ?? 1,
        'Ghichu': payload['ghichu'] ?? '',
      });

      if (payload['newFileIds'] != null && payload['newFileIds'] is List) {
        for (var fileId in payload['newFileIds']) {
          formData.fields.add(MapEntry('NewFileIds', fileId.toString()));
        }
      }

      if (payload['deletedFileIds'] != null && payload['deletedFileIds'] is List) {
        for (var fileId in payload['deletedFileIds']) {
          formData.fields.add(MapEntry('DeletedFileIds', fileId.toString()));
        }
      }

      final response = await _dio.put(
        '${AppConstants.baseUrl}/TaiSan_Repair/$id',
        data: formData,
        options: Options(contentType: 'multipart/form-data'), 
      );
      
      return response.statusCode == 200 || (response.data != null && response.data['success'] == true);
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        debugPrint('Lỗi chi tiết từ Backend khi sửa: ${e.response?.data}');
      } else {
        debugPrint('Lỗi kết nối khi cập nhật phiếu: $e');
      }
      return false;
    }
  }
  Future<bool> changeRepairStatus(int id, int newStatus, {String? nguoixutri, String? noidungxutri, String? noidungchuyendi}) async {
    try {
      Map<String, dynamic> data = {'newStatus': newStatus};
      if (nguoixutri != null) data['nguoixutri'] = nguoixutri;
      if (noidungxutri != null) data['noidungxutri'] = noidungxutri;
      if (noidungchuyendi != null) data['noidungchuyendi'] = noidungchuyendi;
      final response = await _dio.put(
        '${AppConstants.baseUrl}/TaiSan_Repair/change-status/$id',
        data: FormData.fromMap(data),
      );
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        if (response.data != null && response.data is Map) {
          return response.data['success'] == true;
        }
        return true; 
      }
      return false;
    } catch (e) {
      debugPrint('Lỗi chuyển trạng thái: $e');
      return false;
    }
  }

  // Future<bool> logRepairAction(int repairId, String manv, String noidung) async {
  //   try {
  //     final response = await _dio.post(
  //       '${AppConstants.baseUrl}/TaiSan_RepairCt',
  //       data: {
  //         "repairId": repairId,
  //         "manv": manv,
  //         "noidung": noidung
  //       },
  //     );
  //     return response.statusCode == 200 || response.data['success'] == true;
  //   } catch (e) {
  //     debugPrint('Lỗi lưu vết hành động: $e');
  //     return false;
  //   }
  // }

  // TIẾP NHẬN PHIẾU (0 -> 2)
  // Future<bool> tiepNhanRepair(int id, String nguoixutri) async {
  //   try {
  //     final response = await _dio.put(
  //       '${AppConstants.baseUrl}/TaiSan_Repair/tiepnhan/$id',
  //       data: {
  //         'id': id, 
  //         'nguoixutri': nguoixutri
  //       },
  //       options: Options(contentType: Headers.formUrlEncodedContentType),
  //     );
      
  //     // Chấp nhận cả mã 200 (OK) và 204 (No Content)
  //     if (response.statusCode == 200 || response.statusCode == 204) {
  //       if (response.data != null && response.data is Map) {
  //         return response.data['success'] == true;
  //       }
  //       return true; 
  //     }
  //     return false;
  //   } catch (e) {
  //     debugPrint('Lỗi tiếp nhận: $e');
  //     return false;
  //   }
  // }

  // ==========================================
  // CHUYỂN GỬI PHIẾU (2 -> 3)
  // ==========================================
  // Future<bool> chuyenGuiRepair(int id) async {
  //   try {
  //     final response = await _dio.put(
  //       '${AppConstants.baseUrl}/TaiSan_Repair/chuyengui/$id',
  //       data: {'id': id},
  //       options: Options(contentType: Headers.formUrlEncodedContentType),
  //     );

  //     if (response.statusCode == 200 || response.statusCode == 204) {
  //       if (response.data != null && response.data is Map) {
  //         return response.data['success'] == true;
  //       }
  //       return true; 
  //     }
  //     return false;
  //   } catch (e) {
  //     debugPrint('Lỗi chuyển gửi: $e');
  //     return false;
  //   }
  // }


  // HOÀN THÀNH PHIẾU (3 -> 9)

  // Future<bool> hoanThanhRepair(int id, String noidungxutri) async {
  //   try {
  //     final response = await _dio.put(
  //       '${AppConstants.baseUrl}/TaiSan_Repair/success/$id',
  //       data: {
  //         'id': id,
  //         'noidungxutri': noidungxutri
  //       },
  //       options: Options(contentType: Headers.formUrlEncodedContentType),
  //     );

  //     if (response.statusCode == 200 || response.statusCode == 204) {
  //       if (response.data != null && response.data is Map) {
  //         return response.data['success'] == true;
  //       }
  //       return true; 
  //     }
  //     return false;
  //   } catch (e) {
  //     debugPrint('Lỗi hoàn thành: $e');
  //     return false;
  //   }
  // }
}