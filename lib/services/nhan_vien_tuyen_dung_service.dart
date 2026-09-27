import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import '../models/nhan_vien_tuyen_dung_v2_models.dart';
import '../utils/constants.dart';

class NhanVienTuyenDungService {
  final Dio dio;

  NhanVienTuyenDungService(this.dio);

  String get _basePath => '${AppConstants.baseUrl}/v2/NhanVien/tuyen-dung';

  // ==========================================================
  // DANH SÁCH ỨNG VIÊN
  // ==========================================================

  Future<List<NhanVienTuyenDungItemV2Model>> getDanhSach({
    String? keyword,
  }) async {
    final response = await dio.get(
      _basePath,
      queryParameters: {
        if (keyword != null && keyword.trim().isNotEmpty)
          'keyword': keyword.trim(),
      },
    );

    final data = _extractData(response.data);

    if (data is! List) {
      return [];
    }

    return data
        .whereType<Map>()
        .map(
          (item) => NhanVienTuyenDungItemV2Model.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  Future<String> importNhanVien(NhanVienTuyenDungPreviewV2Model preview) async {
    final formData = FormData();

    // ==========================================================
    // PAYLOAD JSON
    // ==========================================================

    formData.fields.add(
      MapEntry('payload', jsonEncode(preview.toImportJson())),
    );

    // ==========================================================
    // ẢNH ĐẠI DIỆN MỚI
    // ==========================================================

    final avatarBytes = preview.nhanVien.replacementAvatarBytes;

    final avatarName = preview.nhanVien.replacementAvatarFileName;

    if (avatarBytes != null &&
        avatarBytes.isNotEmpty &&
        avatarName != null &&
        avatarName.trim().isNotEmpty) {
      formData.files.add(
        MapEntry(
          'anhDaiDien',
          MultipartFile.fromBytes(avatarBytes, filename: avatarName.trim()),
        ),
      );
    }

    // ==========================================================
    // FILE BẰNG CẤP MỚI
    // ==========================================================

    for (final item in preview.bangCaps) {
      final bytes = item.replacementFileBytes;

      final fileName = item.replacementFileName;

      if (bytes == null ||
          bytes.isEmpty ||
          fileName == null ||
          fileName.trim().isEmpty) {
        continue;
      }

      formData.files.add(
        MapEntry(
          'bangCap_${item.idBangCapTuyenDung}',
          MultipartFile.fromBytes(bytes, filename: fileName.trim()),
        ),
      );
    }

    // ==========================================================
    // FILE CHỨNG CHỈ MỚI
    // ==========================================================

    for (final item in preview.chungChis) {
      final bytes = item.replacementFileBytes;

      final fileName = item.replacementFileName;

      if (bytes == null ||
          bytes.isEmpty ||
          fileName == null ||
          fileName.trim().isEmpty) {
        continue;
      }

      formData.files.add(
        MapEntry(
          'chungChi_${item.idChungChiTuyenDung}',
          MultipartFile.fromBytes(bytes, filename: fileName.trim()),
        ),
      );
    }

    // ==========================================================
    // POST
    // ==========================================================

    late final Response<dynamic> response;

    try {
      response = await dio.post(
        '$_basePath/${preview.idTuyenDung}/import',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
    } on DioException catch (error) {
      throw Exception(
        _dioErrorMessage(error, 'Không thể tạo nhân viên từ tuyển dụng.'),
      );
    }

    final data = _extractData(response.data);

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);

      final maSo = map['maSo']?.toString();

      if (maSo != null && maSo.trim().isNotEmpty) {
        return maSo.trim();
      }
    }

    throw Exception('API đã tạo nhân viên nhưng không trả về mã nhân viên.');
  }

  Future<Uint8List?> getAnhDaiDienPreview(int idTuyenDung) async {
    try {
      final response = await dio.get<List<int>>(
        '$_basePath/$idTuyenDung/anh-dai-dien',
        options: Options(responseType: ResponseType.bytes),
      );

      final data = response.data;

      if (data == null || data.isEmpty) {
        return null;
      }

      return Uint8List.fromList(data);
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List?> getBangCapFilePreview({
    required int idTuyenDung,
    required int idBangCapTuyenDung,
  }) async {
    try {
      final response = await dio.get<List<int>>(
        '$_basePath/$idTuyenDung/'
        'bang-cap/$idBangCapTuyenDung/file',
        options: Options(responseType: ResponseType.bytes),
      );

      final data = response.data;

      if (data == null || data.isEmpty) {
        return null;
      }

      return Uint8List.fromList(data);
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List?> getChungChiFilePreview({
    required int idTuyenDung,
    required int idChungChiTuyenDung,
  }) async {
    try {
      final response = await dio.get<List<int>>(
        '$_basePath/$idTuyenDung/'
        'chung-chi/$idChungChiTuyenDung/file',
        options: Options(responseType: ResponseType.bytes),
      );

      final data = response.data;

      if (data == null || data.isEmpty) {
        return null;
      }

      return Uint8List.fromList(data);
    } catch (_) {
      return null;
    }
  }

  Future<NhanVienTuyenDungPreviewV2Model> getPreview(int idTuyenDung) async {
    final response = await dio.get('$_basePath/$idTuyenDung/preview');

    final data = _extractData(response.data);

    if (data is! Map) {
      throw Exception('Dữ liệu xem trước hồ sơ tuyển dụng không hợp lệ.');
    }

    return NhanVienTuyenDungPreviewV2Model.fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  // ==========================================================
  // API RESPONSE
  // ==========================================================

  dynamic _extractData(dynamic responseData) {
    if (responseData is Map) {
      if (responseData.containsKey('data')) {
        return responseData['data'];
      }

      if (responseData.containsKey('Data')) {
        return responseData['Data'];
      }
    }

    return responseData;
  }

  String _dioErrorMessage(DioException error, String fallback) {
    final responseData = error.response?.data;

    if (responseData is Map) {
      final message = responseData['message'] ?? responseData['Message'];

      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString().trim();
      }
    }

    return fallback;
  }
}
