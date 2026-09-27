import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/diennuoc_model.dart';
import '../utils/constants.dart';
import 'api_client.dart';

class DienNuocService {
  final ApiClient _apiClient = ApiClient();

  Future<List<DienNuoc>> getDanhSach({int page = 1, int pageSize = 20, int? thang, int? nam, int? idHoGiaDinh, String? keyword}) async {
    try {
      final Map<String, dynamic> query = {'page': page, 'pageSize': pageSize};
      if (thang != null) query['thang'] = thang;
      if (nam != null) query['nam'] = nam;
      if (idHoGiaDinh != null) query['idHoGiaDinh'] = idHoGiaDinh;
      
      if (keyword != null && keyword.isNotEmpty) query['keyword'] = keyword;

      final response = await _apiClient.dio.get('${AppConstants.baseUrl}/DienNuoc', queryParameters: query);
      
      if (response.data['data'] != null) {
        List data = response.data['data'];
        return data.map((e) => DienNuoc.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ LỖI GET ĐIỆN NƯỚC: $e');
      return [];
    }
}

  Future<String?> createDienNuoc(DienNuoc dto) async {
    try {
      final response = await _apiClient.dio.post('${AppConstants.baseUrl}/DienNuoc', data: dto.toJson());
      if (response.statusCode == 200 || response.statusCode == 201) return null; // Thành công
      return 'Lỗi không xác định';
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        return e.response?.data['message'] ?? 'Thêm mới thất bại';
      }
      return 'Lỗi kết nối máy chủ';
    }
  }

  Future<bool> updateDienNuoc(int id, DienNuoc dto) async {
    try {
      final response = await _apiClient.dio.put('${AppConstants.baseUrl}/DienNuoc/$id', data: dto.toJson());
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteDienNuoc(int id) async {
    try {
      final response = await _apiClient.dio.delete('${AppConstants.baseUrl}/DienNuoc/$id');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('❌ LỖI API XÓA: $e');
      return false;
    }
  }

  Future<Map<String, int>> getLatestChiSo(int idHoGiaDinh) async {
    try {
      final response = await _apiClient.dio.get('${AppConstants.baseUrl}/DienNuoc/latest/$idHoGiaDinh');
      if (response.data != null && response.data['data'] != null) {
        return {
          'dien': response.data['data']['latestDien'] ?? 0,
          'nuoc': response.data['data']['latestNuoc'] ?? 0,
        };
      }
    } catch (e) {
      debugPrint('Lỗi lấy chỉ số cũ: $e');
    }
    return {'dien': 0, 'nuoc': 0};
  }
  Future<List<Map<String, dynamic>>> getDanhMucHoGiaDinh() async {
    try {
      final response = await _apiClient.dio.get('${AppConstants.baseUrl}/DienNuoc/danhmuc');
      if (response.data != null && response.data['data'] != null) {
        List data = response.data['data'];
        return data.map((e) => {
          'id': e['id'],
          'name': 'Phòng ${e['sophong']} - ${e['hogiadinh']}',
          'khuvuc': e['khuvuc']
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ LỖI GET DANH MỤC: $e');
      return [];
    }
  }
  
}