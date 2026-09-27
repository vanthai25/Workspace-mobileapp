import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/xn_trasau_model.dart';
import '../utils/constants.dart';
import 'api_client.dart';

class XNTraSauService {
  static const int maxKeywordLength = 100;
  final Dio _dio = ApiClient().dio;

  static String? _normalizeKeyword(String? value) {
    if (value == null) return null;
    final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) return null;
    return normalized.length <= maxKeywordLength
        ? normalized
        : normalized.substring(0, maxKeywordLength);
  }

  Future<List<XNTraSau>> getXNTraSauList({
    String? keyword,
    String? nguoicd,
    String? fromDate,
    String? toDate,
    int? state,
    int page = 1,
    int pageSize = 20,
    String? khoacd,
    String? phongcd,
    String? filterNguoicd,
  }) async {
    try {
      Map<String, dynamic> params = {'Page': page, 'PageSize': pageSize};
      final normalizedKeyword = _normalizeKeyword(keyword);
      if (normalizedKeyword != null) params['Keyword'] = normalizedKeyword;
      if (fromDate != null) params['FromDate'] = fromDate;
      if (toDate != null) params['ToDate'] = toDate;
      if (state != null) params['State'] = state;
      if (nguoicd != null && nguoicd.isNotEmpty) params['Nguoicd'] = nguoicd;
      if (khoacd != null) params['Khoacd'] = khoacd;
      if (phongcd != null) params['Phongcd'] = phongcd;
      if (filterNguoicd != null) params['FilterNguoicd'] = filterNguoicd;
      final response = await _dio.get(
        '${AppConstants.baseUrl}/XNTraSau',
        queryParameters: params,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => XNTraSau.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Lỗi tải danh sách XN Trả sau: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getFilterOptions() async {
    try {
      final res = await _dio.get('${AppConstants.baseUrl}/XNTraSau/filters');
      if (res.statusCode == 200 && res.data['success'] == true) {
        return res.data['data'];
      }
    } catch (e) {
      debugPrint('Lỗi filter: $e');
    }
    return {'khoas': [], 'phongs': [], 'nguoicds': []};
  }

  Future<bool> toggleState(int id) async {
    try {
      final response = await _dio.put(
        '${AppConstants.baseUrl}/XNTraSau/toggle-state/$id',
      );
      return response.statusCode == 200 && (response.data['success'] == true);
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Lỗi thao tác!');
      }
      throw Exception('Lỗi kết nối mạng!');
    } catch (e) {
      throw Exception('Lỗi hệ thống: $e');
    }
  }
}
