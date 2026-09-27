import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart' as fp;

import '../models/cap_cchn_models.dart';
import '../utils/constants.dart';

class CapCchnService {
  final Dio dio;

  CapCchnService(this.dio);

  String get _basePath => '${AppConstants.baseUrl}/v2/DaoTao/cap-cchn';

  Future<CapCchnPageResult> getDanhSach({
    String? keyword,
    String? status,
    int page = 1,
    int pageSize = 12,
  }) async {
    try {
      final Response<dynamic> response = await dio.get<dynamic>(
        _basePath,
        queryParameters: <String, dynamic>{
          if (keyword != null && keyword.trim().isNotEmpty)
            'keyword': keyword.trim(),
          if (status != null && status.trim().isNotEmpty)
            'trangThai': status.trim(),
          'page': page,
          'pageSize': pageSize,
        },
      );
      final Map<String, dynamic> body = _asMap(response.data);
      final dynamic rawData = body['data'];
      final List<CapCchnModel> items = rawData is List
          ? rawData
                .whereType<Map>()
                .map(
                  (Map value) =>
                      CapCchnModel.fromJson(Map<String, dynamic>.from(value)),
                )
                .toList()
          : <CapCchnModel>[];
      final Map<String, dynamic> metadata = _asMap(body['metadata']);
      final int resultPageSize = _toInt(metadata['pageSize']) ?? pageSize;
      final int totalCount = _toInt(metadata['totalCount']) ?? items.length;

      return CapCchnPageResult(
        items: items,
        currentPage: _toInt(metadata['currentPage']) ?? page,
        pageSize: resultPageSize,
        totalCount: totalCount,
        totalPages:
            _toInt(metadata['totalPages']) ??
            (totalCount == 0 ? 0 : (totalCount / resultPageSize).ceil()),
      );
    } on DioException catch (error) {
      throw Exception(_dioMessage(error, 'Không thể tải danh sách hồ sơ.'));
    }
  }

  Future<CapCchnModel> getById(int id) async {
    try {
      final Response<dynamic> response = await dio.get<dynamic>(
        '$_basePath/$id',
      );
      return CapCchnModel.fromJson(_asMap(_asMap(response.data)['data']));
    } on DioException catch (error) {
      throw Exception(_dioMessage(error, 'Không thể tải chi tiết hồ sơ.'));
    }
  }

  Future<CapCchnCatalog> getCatalog() async {
    try {
      final Response<dynamic> response = await dio.get<dynamic>(
        '$_basePath/danh-muc',
      );
      return CapCchnCatalog.fromJson(_asMap(_asMap(response.data)['data']));
    } on DioException catch (error) {
      throw Exception(_dioMessage(error, 'Không thể tải danh mục thực hành.'));
    }
  }

  Future<List<CapCchnMentorOption>> getMentorOptions({
    required int idKhoaPhong,
    required int loaiNhanVien,
    required DateTime ngayBatDau,
    required DateTime ngayKetThuc,
    int? excludeCapCchnId,
    String? keyword,
  }) async {
    try {
      final Response<dynamic> response = await dio.get<dynamic>(
        '$_basePath/nguoi-huong-dan',
        queryParameters: <String, dynamic>{
          'idKhoaPhong': idKhoaPhong,
          'loaiNhanVien': loaiNhanVien,
          'ngayBatDau': _apiDate(ngayBatDau),
          'ngayKetThuc': _apiDate(ngayKetThuc),
          'excludeCapCchnId': ?excludeCapCchnId,
          if (keyword != null && keyword.trim().isNotEmpty)
            'keyword': keyword.trim(),
        },
      );
      final dynamic raw = _asMap(response.data)['data'];
      return raw is List
          ? raw
                .whereType<Map>()
                .map(
                  (Map item) => CapCchnMentorOption.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : <CapCchnMentorOption>[];
    } on DioException catch (error) {
      throw Exception(
        _dioMessage(error, 'Không thể tải người hướng dẫn phù hợp.'),
      );
    }
  }

  Future<CapCchnModel> create(
    Map<String, dynamic> payload, {
    fp.PlatformFile? fileHopDong,
    fp.PlatformFile? fileQuyetDinh,
    fp.PlatformFile? fileXacNhanTH,
    fp.PlatformFile? fileThongBaoTiepNhan,
    fp.PlatformFile? anhDaiDien,
    fp.PlatformFile? fileHocPhi,
  }) {
    return _save(
      payload,
      fileHopDong: fileHopDong,
      fileQuyetDinh: fileQuyetDinh,
      fileXacNhanTH: fileXacNhanTH,
      fileThongBaoTiepNhan: fileThongBaoTiepNhan,
      anhDaiDien: anhDaiDien,
      fileHocPhi: fileHocPhi,
    );
  }

  Future<CapCchnModel> update(
    int id,
    Map<String, dynamic> payload, {
    fp.PlatformFile? fileHopDong,
    fp.PlatformFile? fileQuyetDinh,
    fp.PlatformFile? fileXacNhanTH,
    fp.PlatformFile? fileThongBaoTiepNhan,
    fp.PlatformFile? anhDaiDien,
    fp.PlatformFile? fileHocPhi,
  }) {
    return _save(
      payload,
      id: id,
      fileHopDong: fileHopDong,
      fileQuyetDinh: fileQuyetDinh,
      fileXacNhanTH: fileXacNhanTH,
      fileThongBaoTiepNhan: fileThongBaoTiepNhan,
      anhDaiDien: anhDaiDien,
      fileHocPhi: fileHocPhi,
    );
  }

  Future<CapCchnModel> _save(
    Map<String, dynamic> payload, {
    int? id,
    fp.PlatformFile? fileHopDong,
    fp.PlatformFile? fileQuyetDinh,
    fp.PlatformFile? fileXacNhanTH,
    fp.PlatformFile? fileThongBaoTiepNhan,
    fp.PlatformFile? anhDaiDien,
    fp.PlatformFile? fileHocPhi,
  }) async {
    try {
      final FormData formData = FormData();
      formData.fields.add(
        MapEntry<String, String>('payload', jsonEncode(payload)),
      );
      _addFile(formData, 'fileHopDong', fileHopDong);
      _addFile(formData, 'fileQuyetDinh', fileQuyetDinh);
      _addFile(formData, 'fileXacNhanTH', fileXacNhanTH);
      _addFile(formData, 'fileThongBaoTiepNhan', fileThongBaoTiepNhan);
      _addFile(formData, 'anhDaiDien', anhDaiDien);
      _addFile(formData, 'fileHocPhi', fileHocPhi);

      final Response<dynamic> response = id == null
          ? await dio.post<dynamic>(_basePath, data: formData)
          : await dio.put<dynamic>('$_basePath/$id', data: formData);
      return CapCchnModel.fromJson(_asMap(_asMap(response.data)['data']));
    } on DioException catch (error) {
      throw Exception(_dioMessage(error, 'Không thể lưu hồ sơ.'));
    }
  }

  Future<void> delete(int id) async {
    try {
      await dio.delete<dynamic>('$_basePath/$id');
    } on DioException catch (error) {
      throw Exception(_dioMessage(error, 'Không thể xóa hồ sơ.'));
    }
  }

  Future<Uint8List> downloadFile(int id, String loaiFile) async {
    try {
      final Response<List<int>> response = await dio.get<List<int>>(
        '$_basePath/$id/files/$loaiFile',
        options: Options(responseType: ResponseType.bytes),
      );
      final List<int> bytes = response.data ?? <int>[];
      if (bytes.isEmpty) throw Exception('File tải về không có dữ liệu.');
      return Uint8List.fromList(bytes);
    } on DioException catch (error) {
      throw Exception(_dioMessage(error, 'Không thể tải file đính kèm.'));
    }
  }

  void _addFile(FormData data, String field, fp.PlatformFile? file) {
    if (file == null) return;
    final Uint8List? bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw Exception('Không đọc được file "${file.name}".');
    }
    data.files.add(
      MapEntry<String, MultipartFile>(
        field,
        MultipartFile.fromBytes(bytes, filename: file.name),
      ),
    );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String && value.trim().isNotEmpty) {
      final dynamic decoded = jsonDecode(value);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    return <String, dynamic>{};
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  String _apiDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  String _dioMessage(DioException error, String fallback) {
    final Map<String, dynamic> body = _asMap(error.response?.data);
    final String message = body['message']?.toString().trim() ?? '';
    if (message.isNotEmpty) return message;
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Không thể kết nối máy chủ. Vui lòng kiểm tra mạng.';
    }
    return fallback;
  }
}
