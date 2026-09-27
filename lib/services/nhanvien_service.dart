import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/nhanvien_model.dart';
import '../utils/constants.dart';
import 'api_client.dart';

class NhanvienService {
  final Dio _dio = ApiClient().dio;

  Future<List<NhanVien>> getAllNhanVien({
    int page = 1, 
    int pagesize = 50,
    String? filterBy,
    String? filterQuery,
  }) async {
    try {
      Map<String, dynamic> queryParams = {
        'page': page,
        'pagesize': pagesize,
        'sortBy': 'manv',  
        'sortOrder': 'asc', 
      };

      if (filterQuery != null && filterQuery.isNotEmpty) {
        queryParams['filterBy'] = filterBy ?? 'tennv'; 
        queryParams['filterQuery'] = filterQuery;
      }

      final response = await _dio.get('${AppConstants.baseUrl}/NhanVien', queryParameters: queryParams);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => NhanVien.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Lỗi tải danh sách nhân viên: $e');
    }
  }


  Future<List<NhanVien>> searchNhanVien({
  int page = 1, 
  int pageSize = 100,
  String? keyword, 
  String? maKhoa,
}) async {
  try {
    Map<String, dynamic> queryParams = {
      'Page': page,
      'PageSize': pageSize,
      'SortBy': 'MaNV',  
      'SortOrder': 'asc',
    };

    if (keyword != null && keyword.trim().isNotEmpty) {
      if (double.tryParse(keyword.trim()) != null) {
        queryParams['Manv'] = keyword.trim();
      } else {
        queryParams['Tennv'] = keyword.trim();
      }
    }

    if (maKhoa != null && maKhoa.trim().isNotEmpty) {
      queryParams['MaKhoa'] = maKhoa.trim();
    }

    // CẬP NHẬT ĐƯỜNG DẪN MỚI Ở ĐÂY:
    // Vì AppConstants.baseUrl đã có sẵn '/api', nên ta chỉ cần thêm '/NhanVien'
    final response = await _dio.get(
      '${AppConstants.baseUrl}/NhanVien', 
      queryParameters: queryParams,
    );

    if (response.statusCode == 200 && response.data['success'] == true) {
      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((json) => NhanVien.fromJson(json)).toList();
    }
    return [];
  } catch (e) {
    debugPrint('Lỗi khi gọi API /NhanVien: $e');
    return []; 
  }
}

  Future<NhanVien?> getNhanVienById(String manv) async {
    try {
      // Cách 1: Gọi API trực tiếp
      final response = await _dio.get('${AppConstants.baseUrl}/NhanVien/$manv');
      
      if (response.data['success'] == true) {
        var data = response.data['data'];
        if (data != null) {
          if (data is Map<String, dynamic>) return NhanVien.fromJson(data);
          if (data is List && data.isNotEmpty) return NhanVien.fromJson(data.first);
        }
      }
      return null;
    } catch (e) {
      try {
        final fallbackResponse = await _dio.get('${AppConstants.baseUrl}/NhanVien', queryParameters: {
          'filterBy': 'manv',
          'filterQuery': manv,
          'page': 1,
          'pagesize': 1,
        });
        
        if (fallbackResponse.data['success'] == true) {
          var data = fallbackResponse.data['data'];
          if (data != null && data is List && data.isNotEmpty) {
            return NhanVien.fromJson(data.first);
          }
        }
        return null;
      } catch (e2) {
        return null; 
      }
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
  Future<List<NhanVien>> getNhanVienByKhoa(String maKhoa) async {
    try {
      final response = await _dio.get(
        '${AppConstants.baseUrl}/NhanVien', 
        queryParameters: {
          'Makhoa': maKhoa,
          'PageSize': 200, 
        }
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => NhanVien.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
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
  Future<List<NhanVien>> getEmployeesByKhoa(String maKhoa) async {
    try {
      final response = await _dio.get(
        '${AppConstants.baseUrl}/NhanVien/get-by-khoa/$maKhoa'
      );
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => NhanVien.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Lỗi tải danh sách theo khoa: $e');
      return [];
    }
  }
  Future<List<NhanVien>> getBirthdaysToday() async {
    try {
      final response = await _dio.get(
        '${AppConstants.baseUrl}/NhanVien/birthdays-today'
      );
      if (response.data['success'] == true) {
        List<dynamic> data = response.data['data'];
        return data.map((json) => NhanVien.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Lỗi tải danh sách sinh nhật: $e");
      return [];
    }
  }
  Future<List<NhanVien>> searchDanhBa({
    int page = 1,
    int pageSize = 100,
    String? keyword,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'page': page,
        'pageSize': pageSize,
      };

      if (keyword != null && keyword.trim().isNotEmpty) {
        queryParams['keyword'] = keyword.trim();
      }

      final response = await _dio.get(
        '${AppConstants.baseUrl}/NhanVien/danh-ba',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 &&
          response.data['success'] == true) {
        final List<dynamic> data =
            response.data['data'] ?? [];

        return data
            .map((json) => NhanVien.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      debugPrint('❌ Lỗi tìm kiếm danh bạ: $e');
      return [];
    }
  }

  Future<List<NhanVien>> getDanhBaByKhoa(
    String maKhoa,
  ) async {
    try {
      final response = await _dio.get(
        '${AppConstants.baseUrl}/NhanVien/danh-ba-theo-khoa/$maKhoa',
      );

      if (response.statusCode == 200 &&
          response.data['success'] == true) {
        final List<dynamic> data =
            response.data['data'] ?? [];

        return data
            .map((json) => NhanVien.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      debugPrint(
        '❌ Lỗi tải danh bạ theo khoa $maKhoa: $e',
      );

      return [];
    }
  }
}