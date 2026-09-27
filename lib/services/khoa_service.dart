import 'package:dio/dio.dart';
import '../models/khoa_model.dart';
import '../utils/constants.dart';
import 'api_client.dart'; 

class KhoaService {
  final Dio _dio = ApiClient().dio;

  // 1. Lấy danh sách Khoa (Đã áp dụng Model mới)
  Future<List<Khoa>> getAllKhoa() async {
    try {
      final response = await _dio.get(
        '${AppConstants.baseUrl}/Khoa',
        queryParameters: {
          'PageSize': 200,
        }
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => Khoa.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Lỗi lấy danh sách khoa: $e');
    }
  }

  // 2. Lấy tên Khoa theo mã
  Future<String> getTenKhoa(String maKhoa) async {
    try {
      final response = await _dio.get('${AppConstants.baseUrl}/Khoa/$maKhoa');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data']['tenkhoa']?.toString() ?? maKhoa;
      }
      return maKhoa;
    } catch (e) {
      return maKhoa;
    }
  }

  // 3. Lấy danh sách Chức vụ
  Future<List<dynamic>> getAllChucVu() async {
    try {
      final response = await _dio.get(
        '${AppConstants.baseUrl}/ChucVu',
        queryParameters: {
          'PageSize': 200, 
        }
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] ?? [];
      }
      return [];
    } catch (e) {
      return []; 
    }
  }

  // 4. Lấy danh sách Chức danh
  Future<List<dynamic>> getAllChucDanh() async {
    try {
      final response = await _dio.get(
        '${AppConstants.baseUrl}/ChucDanh',
        queryParameters: {
          'PageSize': 200,
        }
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}