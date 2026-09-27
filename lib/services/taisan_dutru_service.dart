import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/taisan_dutru_model.dart';
import '../utils/constants.dart';
import 'api_client.dart';

class TaisanDutruService {
  final Dio _dio = ApiClient().dio;

  Future<List<TaiSanDuTru>> getTaiSanDuTrus({
    String? maPhieuDuTru,
    String? ghiChuDuTru,
    String? fromDate,
    String? toDate,
    String? maKhoaDeNghi,
    int? trangThaiPhieu,
    int? mucUuTien,
    int page = 1,
    int pageSize = 20,
    String? maHDTVPhuTrach, 
  }) async {
    try {
      Map<String, dynamic> params = {
        'Page': page,
        'PageSize': pageSize,
      };
      if (maPhieuDuTru != null && maPhieuDuTru.isNotEmpty) params['MaPhieuDuTru'] = maPhieuDuTru;
      if (ghiChuDuTru != null && ghiChuDuTru.isNotEmpty) params['GhiChuDuTru'] = ghiChuDuTru;
      if (fromDate != null) params['FromDate'] = fromDate;
      if (toDate != null) params['ToDate'] = toDate;
      if (maKhoaDeNghi != null && maKhoaDeNghi.isNotEmpty) params['MaKhoaDeNghi'] = maKhoaDeNghi;
      if (trangThaiPhieu != null) params['TrangThaiPhieu'] = trangThaiPhieu;
      
      if (maHDTVPhuTrach != null && maHDTVPhuTrach.isNotEmpty) params['MaHDTVPhuTrach'] = maHDTVPhuTrach;
      if (mucUuTien != null) params['MucUuTien'] = mucUuTien;
      debugPrint('🔥 THÔNG SỐ GỬI LÊN SERVER: $params');
      final response = await _dio.get('${AppConstants.baseUrl}/TaiSanDuTru', queryParameters: params);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => TaiSanDuTru.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Lỗi tải danh sách dự trù: $e');
      return [];
    }
  }

  Future<TaiSanDuTru?> getTaiSanDuTruDetail(String maPhieu) async {
  try {
    final response = await _dio.get('${AppConstants.baseUrl}/TaiSanDuTru/$maPhieu');

    if (response.statusCode == 200 && response.data['success'] == true) {
      var data = response.data['data'];
      
      if (data is List) {
        if (data.isNotEmpty) {
          return TaiSanDuTru.fromJson(data.first as Map<String, dynamic>);
        }
      } 
      else if (data is Map<String, dynamic>) {
        return TaiSanDuTru.fromJson(data);
      }
    }
    return null;
  } catch (e) {
    debugPrint('Lỗi tải chi tiết dự trù: $e');
    return null;
  }
}

  Future<bool> updateTrangThaiDuTru(String maPhieu, String actionEndpoint, {Map<String, dynamic>? queryParams}) async {
    try {
      final url = '${AppConstants.baseUrl}/TaiSanDuTru/$actionEndpoint/$maPhieu';
      final response = await _dio.put(
        url,
        queryParameters: queryParams,
        options: Options(headers: {'Content-Type': 'application/x-www-form-urlencoded'}),
        data: {'maphieudutru': maPhieu}, 
      );
      
      return response.statusCode == 200 && (response.data['success'] == true);
    } on DioException catch (e) { 
      if (e.response != null && e.response?.data != null) {
        String errorMsg = e.response?.data['message'] ?? 'Lỗi thao tác!';
        debugPrint('Backend từ chối: $errorMsg');
        
        // (Tùy chọn) Bạn có thể dùng AppHelpers.showSnackBar ở đây để báo trực tiếp lên UI
        // AppHelpers.showSnackBar(errorMsg, isError: true);
      }
      return false;
    } catch (e) {
      debugPrint('Lỗi hệ thống: $e');
      return false;
    }
  }
  
}