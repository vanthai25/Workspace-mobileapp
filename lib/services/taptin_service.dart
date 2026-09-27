import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../models/taptin_model.dart';
import '../utils/constants.dart';
import 'api_client.dart';

class TaptinService {
  final Dio _dio = ApiClient().dio;

  Future<List<TapTin>> getAllTapTin() async {
    try {
      final response = await _dio.get('${AppConstants.baseUrl}/Taptin');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => TapTin.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Lỗi lấy danh sách tập tin: $e');
    }
  }

  
  Future<String?> downloadFile(int fileId, String fileName) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/$fileName';

      await _dio.download(
        '${AppConstants.baseUrl}/Taptin/download/$fileId',
        savePath,
      );
      
      return savePath;
    } catch (e) {
      return null;
    }
  }
  Future<List<TapTin>> searchTapTin({
    String? fromDate,
    String? toDate,
    String? keyword,
    int page = 1,
    int? loaiId,
    int pageSize = 10,
  }) async {
    try {
      Map<String, dynamic> params = {
        'Page': page,
        'loaiID': loaiId,
        'PageSize': pageSize,
        'SortBy': 'NgayUp',
        'SortOrder': 'desc', 
      };

      if (fromDate != null && fromDate.isNotEmpty) params['FromDate'] = fromDate;
      if (toDate != null && toDate.isNotEmpty) params['ToDate'] = toDate;
      if (keyword != null && keyword.trim().isNotEmpty) params['TenTapTin'] = keyword.trim();
      if (loaiId != null) params['LoaiId'] = loaiId;

      final response = await _dio.get('${AppConstants.baseUrl}/Taptin', queryParameters: params);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => TapTin.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Lỗi API TapTin: $e');
      return [];
    }
  }
  Future<void> recordViewDoc(int fileId) async {
    try {
      final response = await _dio.post('${AppConstants.baseUrl}/Taptin/record-view/$fileId');
      if (response.statusCode == 200) {
        debugPrint('✅ Đã ghi nhận lượt xem cho file: $fileId');
      }
    } catch (e) {
      debugPrint('❌ Lỗi ghi nhận lượt xem: $e');
    }
  }
}