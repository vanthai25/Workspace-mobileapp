import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/tai_san_model.dart'; 
import '../utils/constants.dart';
import 'api_client.dart';

class TaiSanService {
  final Dio _dio = ApiClient().dio;

  Future<List<TaiSan>> getDanhSachTaiSan({
    String? tentaisan,
    String? maTaiSan,
    String? makhoa,
    String? vitrisudung,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      Map<String, dynamic> params = {
        'Page': page,
        'PageSize': pageSize,
      };

      if (tentaisan != null && tentaisan.isNotEmpty) params['Tentaisan'] = tentaisan;
      if (maTaiSan != null && maTaiSan.isNotEmpty) params['MaTaiSan'] = maTaiSan;
      if (makhoa != null && makhoa.isNotEmpty) params['Makhoa'] = makhoa;
      if (vitrisudung != null && vitrisudung.isNotEmpty) params['Vitrisudung'] = vitrisudung;

      final response = await _dio.get(
        '${AppConstants.baseUrl}/TaiSan', 
        queryParameters: params
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => TaiSan.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Lỗi lấy danh sách tài sản: $e');
      return [];
    }
  }

  Future<TaiSan?> getTaiSanById(String maTaiSan) async {
    try {
      final response = await _dio.get('${AppConstants.baseUrl}/TaiSan/$maTaiSan');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        var data = response.data['data'];
        if (data != null && data is Map<String, dynamic>) {
          return TaiSan.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Lỗi lấy chi tiết tài sản $maTaiSan: $e');
      return null;
    }
  }
}