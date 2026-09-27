import 'package:dio/dio.dart';
import 'package:mobileapp_bvhv/services/api_client.dart';
import '../models/nuocthai_model.dart';
import '../utils/constants.dart';

class NuocThaiService {
  final ApiClient _apiClient = ApiClient();
  final String _endpoint = '${AppConstants.baseUrl}/NuocThai';

  // Lấy danh sách kèm bộ lọc và phân trang
  Future<List<NuocThai>> getDanhSachNuocThai({
    int page = 1,
    int pageSize = 20,
    String? chiNhanh,
    String? fromDate,
    String? toDate,
    bool? batThuong,
  }) async {
    try {
      final Map<String, dynamic> queryParameters = {
        'page': page,
        'pageSize': pageSize,
        if (chiNhanh != null && chiNhanh.isNotEmpty) 'chiNhanh': chiNhanh,
        if (fromDate != null) 'fromDate': fromDate,
        if (toDate != null) 'toDate': toDate,
        if (batThuong != null) 'batThuong': batThuong,
      };

      final response = await _apiClient.dio.get(
        _endpoint,
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        final responseData = response.data['data'] ?? [];
        if (responseData is List) {
          return responseData.map((e) => NuocThai.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Lỗi tải danh sách nước thải: $e');
      throw Exception('Không thể tải dữ liệu nước thải');
    }
  }
  Future<double> getLatestChiSo(String chiNhanh) async {
    try {
      final response = await _apiClient.dio.get('$_endpoint/latest/$chiNhanh');
      if (response.statusCode == 200 && response.data['data'] != null) {
        return double.tryParse(response.data['data']['chiSoMoi'].toString()) ?? 0.0;
      }
      return 0.0;
    } catch (e) {
      print('Lỗi lấy chỉ số gần nhất: $e');
      return 0.0;
    }
  }

  // Cập nhật hàm createNuocThai để ném ra thông báo lỗi dạng String (để bắt lỗi trùng ngày)
  Future<String?> createNuocThaiWithMsg(NuocThai data) async {
    try {
      final response = await _apiClient.dio.post(_endpoint, data: data.toJson());
      if (response.statusCode == 201) return null; // Thành công
      return response.data['message'] ?? 'Lỗi không xác định';
    } catch (e) {
      if (e is DioException && e.response != null) {
        return e.response?.data['message'] ?? 'Lỗi hệ thống';
      }
      return 'Lỗi kết nối';
    }
  }
  // Thêm mới phiếu
  Future<bool> createNuocThai(NuocThai data) async {
    try {
      final response = await _apiClient.dio.post(_endpoint, data: data.toJson());
      return response.statusCode == 201;
    } catch (e) {
      print('Lỗi thêm nước thải: $e');
      return false;
    }
  }

  // Cập nhật phiếu
  Future<bool> updateNuocThai(int id, NuocThai data) async {
    try {
      final response = await _apiClient.dio.put('$_endpoint/$id', data: data.toJson());
      return response.statusCode == 200;
    } catch (e) {
      print('Lỗi cập nhật nước thải: $e');
      return false;
    }
  }

  Future<bool> checkExists(String chiNhanh, DateTime ngay) async {
    try {
      final response = await _apiClient.dio.get(
        '/NuocThai/check-exists',
        queryParameters: {'chiNhanh': chiNhanh, 'ngay': ngay.toIso8601String()},
      );
      return response.data['data'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteNuocThai(int id) async {
    try {
      final response = await _apiClient.dio.delete('${AppConstants.baseUrl}/NuocThai/$id');
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      return false;
    }
    
  }
}