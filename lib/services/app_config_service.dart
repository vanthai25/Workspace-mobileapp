import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/app_config_model.dart';
import '../utils/constants.dart';
import 'api_client.dart'; 

class AppConfigService {
  final Dio _dio = ApiClient().dio;

  Future<AppConfig?> getSystemConfig() async {
    try {
      final response = await _dio.get('${AppConstants.baseUrl}/AppConfig/status');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return AppConfig.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      debugPrint('Lỗi tải cấu hình hệ thống: $e');
      return null;
    }
  }
}