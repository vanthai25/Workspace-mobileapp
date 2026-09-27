import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import '../models/baocom_menu.dart';
import '../models/baocom_model.dart';
import '../utils/constants.dart';
import 'api_client.dart';

class BaoComService {
  final Dio _dio = ApiClient().dio;

  Future<List<BaoCom>> getAllBaoCom() async {
    try {
      final response = await _dio.get('${AppConstants.baseUrl}/BaoCom');
      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => BaoCom.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Lỗi lấy danh sách báo cơm: $e');
    }
  }

  Future<bool> createBaoCom(BaoCom data) async {
    try {
      final response = await _dio.post('${AppConstants.baseUrl}/BaoCom', data: data.toJson());
      return response.data['success'] == true;
    } on DioException catch (e) {
      throw Exception('Lỗi mạng khi tạo báo cơm: ${e.message}');
    }
  }

  // 3. Cập nhật báo cơm (PUT)
  Future<bool> updateBaoCom(BaoCom data) async {
    try {
      final response = await _dio.put(
        '${AppConstants.baseUrl}/BaoCom/${data.id}',
        data: data.toJson(),
      );
      return response.data['success'] == true;
    } on DioException catch (e) {
      throw Exception('Lỗi mạng khi cập nhật báo cơm: ${e.message}');
    }
  }

  // 4. Xóa báo cơm (DELETE)
  Future<bool> deleteBaoCom(int id) async {
    try {
      final response = await _dio.delete('${AppConstants.baseUrl}/BaoCom/$id');
      return response.data['success'] == true;
    } on DioException catch (e) {
      throw Exception('Lỗi xóa báo cơm: ${e.message}');
    }
  }
  Future<List<Map<String, dynamic>>> getAllKhoa() async {
    try {
      final response = await _dio.get(
        '${AppConstants.baseUrl}/Khoa',
        queryParameters: {
          'PageSize': 200,
        }
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      throw Exception('Lỗi lấy danh sách khoa: $e');
    }
  }
  Future<List<BaoCom>> getBaoCom({
    String? nguoibao,
    String? fromDate,
    String? toDate,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      Map<String, dynamic> queryParams = {
        'SortBy': 'ngaybaocom',
        'SortOrder': 'desc',    
        'Page': page,
        'PageSize': pageSize,
      };

      // Gắn thêm tham số nếu có
      if (nguoibao != null && nguoibao.isNotEmpty) queryParams['Nguoibao'] = nguoibao;
      if (fromDate != null && fromDate.isNotEmpty) queryParams['FromDate'] = fromDate;
      if (toDate != null && toDate.isNotEmpty) queryParams['ToDate'] = toDate;

      final response = await _dio.get('${AppConstants.baseUrl}/BaoCom', queryParameters: queryParams);
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => BaoCom.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Lỗi lấy danh sách báo cơm: $e');
    }
  }
  Future<List<BaoComMenu>> getBaoComMenu() async {
    try {
      final response = await _dio.get('${AppConstants.baseUrl}/BaoComMenu');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((item) => BaoComMenu.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Lỗi lấy thực đơn: $e');
      return [];
    }
  }
}