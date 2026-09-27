import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/foundation.dart';

import '../models/nhan_vien_v2_models.dart';
import '../models/khen_thuong_ky_luat_models.dart';
import '../utils/constants.dart';

class NhanVienV2Service {
  final Dio dio;

  NhanVienV2Service(this.dio);

  String get _basePath => '${AppConstants.baseUrl}/v2/NhanVien';

  Future<NhanVienV2PageResult> getDanhSach({
    String? keyword,
    int? idKhoaPhong,
    bool includeNghiViec = false,
    int page = 1,
    int pageSize = 50,
    String sortBy = 'maSo',
    String sortOrder = 'asc',
  }) async {
    try {
      final url = _basePath;

      debugPrint('================ NHAN VIEN V2 ================');

      debugPrint('URL: $url');

      final response = await dio.get(
        url,
        queryParameters: {
          if (keyword != null && keyword.trim().isNotEmpty)
            'keyword': keyword.trim(),

          'idKhoaPhong': ?idKhoaPhong,

          'includeNghiViec': includeNghiViec,

          'page': page,

          'pageSize': pageSize,
          'sortBy': sortBy,
          'sortOrder': sortOrder,
        },
      );

      debugPrint('REAL URL: ${response.realUri}');

      debugPrint('STATUS: ${response.statusCode}');

      debugPrint('RESPONSE TYPE: ${response.data.runtimeType}');

      // =====================================================
      // CHUẨN HÓA RESPONSE
      // =====================================================

      final Map<String, dynamic> body = _parseResponseMap(response.data);

      debugPrint('success = ${body['success']}');

      debugPrint('message = ${body['message']}');

      final dynamic rawData = body['data'];

      debugPrint('data type = ${rawData.runtimeType}');

      if (rawData is! List) {
        throw Exception(
          'API không trả data dạng List. '
          'Kiểu nhận được: ${rawData.runtimeType}',
        );
      }

      // =====================================================
      // PARSE NHÂN VIÊN
      // =====================================================

      final List<NhanVienV2Model> items = [];

      for (final item in rawData) {
        if (item is Map) {
          items.add(NhanVienV2Model.fromJson(Map<String, dynamic>.from(item)));
        }
      }

      debugPrint('PARSED ITEMS = ${items.length}');

      if (items.isNotEmpty) {
        debugPrint(
          'FIRST = '
          '${items.first.maSo} - '
          '${items.first.hoVaTen}',
        );
      }

      // =====================================================
      // METADATA
      // =====================================================

      final dynamic rawMetadata = body['metadata'];

      Map<String, dynamic> metadata = {};

      if (rawMetadata is Map) {
        metadata = Map<String, dynamic>.from(rawMetadata);
      }

      debugPrint('METADATA = $metadata');

      final int currentPage = _parseInt(metadata['currentPage']) ?? page;

      final int resultPageSize = _parseInt(metadata['pageSize']) ?? pageSize;

      final int totalCount = _parseInt(metadata['totalCount']) ?? items.length;

      final int totalPages =
          _parseInt(metadata['totalPages']) ??
          (totalCount == 0 ? 0 : (totalCount / resultPageSize).ceil());

      debugPrint('TOTAL COUNT = $totalCount');

      debugPrint('TOTAL PAGES = $totalPages');

      debugPrint('==============================================');

      return NhanVienV2PageResult(
        items: items,

        currentPage: currentPage,

        pageSize: resultPageSize,

        totalCount: totalCount,

        totalPages: totalPages,
      );
    } on DioException catch (e) {
      debugPrint('NHAN VIEN V2 DIO ERROR');

      debugPrint('STATUS = ${e.response?.statusCode}');

      debugPrint('URL = ${e.requestOptions.uri}');

      debugPrint('DATA = ${e.response?.data}');

      rethrow;
    } catch (e, stackTrace) {
      debugPrint('NHAN VIEN V2 ERROR = $e');

      debugPrint(stackTrace.toString());

      rethrow;
    }
  }

  Map<String, dynamic> _parseResponseMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    if (value is String) {
      final decoded = jsonDecode(value);

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    }

    throw Exception(
      'Response API không hợp lệ. '
      'Kiểu: ${value.runtimeType}',
    );
  }

  int? _parseInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(value.toString());
  }

  Future<NhanVienTongQuanV2Model> getTongQuan() async {
    final response = await dio.get('$_basePath/tong-quan');

    return NhanVienTongQuanV2Model.fromJson(_extractDataMap(response.data));
  }

  Future<NhanVienDanhMucV2Model> getDanhMuc() async {
    final response = await dio.get('$_basePath/danh-muc');

    return NhanVienDanhMucV2Model.fromJson(_extractDataMap(response.data));
  }

  Future<Uint8List> exportBaoCaoNhanSuExcel(DateTime ngayBaoCao) async {
    try {
      final response = await dio.get<List<int>>(
        '$_basePath/bao-cao/tinh-hinh-nhan-su/excel',
        queryParameters: {'ngayBaoCao': _formatApiDate(ngayBaoCao)},
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = response.data ?? <int>[];

      if (bytes.isEmpty) {
        throw Exception('File báo cáo nhân sự trả về rỗng.');
      }

      return Uint8List.fromList(bytes);
    } on DioException catch (error) {
      throw Exception(
        _dioErrorMessage(error, 'Không thể xuất báo cáo nhân sự.'),
      );
    }
  }

  Future<UploadedFileV2Model> uploadFile({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    });

    final response = await dio.post('$_basePath/upload-file', data: formData);

    return UploadedFileV2Model.fromJson(_extractDataMap(response.data));
  }

  Future<Uint8List> downloadNhanVienFile({
    required String maSo,
    required int idFile,
  }) async {
    try {
      final response = await dio.get<List<int>>(
        '$_basePath/${maSo.trim()}/files/$idFile/download',
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = response.data ?? const <int>[];
      if (bytes.isEmpty) {
        throw Exception('File trả về không có dữ liệu.');
      }

      return Uint8List.fromList(bytes);
    } on DioException catch (error) {
      throw Exception(_dioErrorMessage(error, 'Không thể mở file đính kèm.'));
    }
  }

  String _khenThuongKyLuatPath(String maSo) =>
      '$_basePath/${maSo.trim()}/khen-thuong-ky-luat';

  Future<NhanVienKhenThuongKyLuatModel> getKhenThuongKyLuat(String maSo) async {
    try {
      final response = await dio.get(_khenThuongKyLuatPath(maSo));
      return NhanVienKhenThuongKyLuatModel.fromJson(
        _extractDataMap(response.data),
      );
    } on DioException catch (error) {
      throw Exception(
        _dioErrorMessage(error, 'Không thể tải khen thưởng, kỷ luật.'),
      );
    }
  }

  Future<void> saveKhenThuong({
    required String maSo,
    required Map<String, dynamic> payload,
    String? maKhenThuong,
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    final form = FormData.fromMap({
      'payload': jsonEncode(payload),
      if (fileBytes != null && fileName != null)
        'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
    });
    try {
      final path =
          '${_khenThuongKyLuatPath(maSo)}/khen-thuong'
          '${maKhenThuong == null ? '' : '/$maKhenThuong'}';
      if (maKhenThuong == null) {
        await dio.post(path, data: form);
      } else {
        await dio.put(path, data: form);
      }
    } on DioException catch (error) {
      throw Exception(_dioErrorMessage(error, 'Không thể lưu khen thưởng.'));
    }
  }

  Future<void> saveKyLuat({
    required String maSo,
    required Map<String, dynamic> payload,
    String? maKyLuat,
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    final form = FormData.fromMap({
      'payload': jsonEncode(payload),
      if (fileBytes != null && fileName != null)
        'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
    });
    try {
      final path =
          '${_khenThuongKyLuatPath(maSo)}/ky-luat'
          '${maKyLuat == null ? '' : '/$maKyLuat'}';
      if (maKyLuat == null) {
        await dio.post(path, data: form);
      } else {
        await dio.put(path, data: form);
      }
    } on DioException catch (error) {
      throw Exception(_dioErrorMessage(error, 'Không thể lưu kỷ luật.'));
    }
  }

  Future<void> deleteKhenThuong(String maSo, String maKhenThuong) async {
    try {
      await dio.delete(
        '${_khenThuongKyLuatPath(maSo)}/khen-thuong/$maKhenThuong',
      );
    } on DioException catch (error) {
      throw Exception(_dioErrorMessage(error, 'Không thể xóa khen thưởng.'));
    }
  }

  Future<void> deleteKyLuat(String maSo, String maKyLuat) async {
    try {
      await dio.delete('${_khenThuongKyLuatPath(maSo)}/ky-luat/$maKyLuat');
    } on DioException catch (error) {
      throw Exception(_dioErrorMessage(error, 'Không thể xóa kỷ luật.'));
    }
  }

  Future<Uint8List> downloadKhenThuongKyLuatFile({
    required String maSo,
    required String loai,
    required String ma,
  }) async {
    try {
      final response = await dio.get<List<int>>(
        '${_khenThuongKyLuatPath(maSo)}/$loai/$ma/file',
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data ?? const <int>[];
      if (bytes.isEmpty) throw Exception('File trả về không có dữ liệu.');
      return Uint8List.fromList(bytes);
    } on DioException catch (error) {
      throw Exception(_dioErrorMessage(error, 'Không thể mở file đính kèm.'));
    }
  }

  Future<NhanVienProfileV2Model> getHoSo(String maSo) async {
    final response = await dio.get('$_basePath/${maSo.trim()}/ho-so');

    return NhanVienProfileV2Model.fromJson(_extractDataMap(response.data));
  }

  Future<void> deleteDaoTaoNoiVien(String maSo, int idDangKyDaoTao) async {
    await dio.delete(
      '$_basePath/'
      '${maSo.trim()}/'
      'dao-tao-noi-vien/'
      '$idDangKyDaoTao',
    );
  }
  // ===========================================================
  // DANH BẠ CHI TIẾT
  // ===========================================================

  Future<NhanVienV2Model> getByMaSo(String maSo) async {
    final response = await dio.get('$_basePath/${maSo.trim()}');

    return NhanVienV2Model.fromJson(_extractDataMap(response.data));
  }

  // ===========================================================
  // KHOA PHÒNG
  // ===========================================================

  Future<List<KhoaPhongV2Model>> getKhoaPhong() async {
    final response = await dio.get('$_basePath/khoa-phong');

    final body = _asMap(response.data);

    final data = body['data'];

    if (data is! List) {
      return [];
    }

    return data
        .whereType<Map>()
        .map((e) => KhoaPhongV2Model.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<NhanVienProfileV2Model> getMe() async {
    final response = await dio.get('$_basePath/me');

    return NhanVienProfileV2Model.fromJson(_extractDataMap(response.data));
  }
  // ===========================================================
  // NHÂN VIÊN
  // ===========================================================

  Future<void> createNhanVien(Map<String, dynamic> data) async {
    try {
      await dio.post(_basePath, data: data);
    } on DioException catch (error) {
      throw Exception(_dioErrorMessage(error, 'Không thể tạo nhân viên.'));
    }
  }

  Future<void> updateNhanVien(String maSo, Map<String, dynamic> data) async {
    await dio.put('$_basePath/${maSo.trim()}', data: data);
  }

  Future<KhoaTaiKhoanNhanVienV2Model> lockNhanVienAccounts(String maSo) async {
    try {
      final response = await dio.put(
        '$_basePath/${maSo.trim()}/tai-khoan/khoa',
      );

      return KhoaTaiKhoanNhanVienV2Model.fromApiResponse(_asMap(response.data));
    } on DioException catch (error) {
      final body = _asMap(error.response?.data);

      // Backend trả 502 khi chỉ một phần hệ thống khóa thành công.
      // Vẫn đọc data để giao diện hiển thị kết quả NSTL/HIS/DOMAIN.
      if (body['data'] is Map) {
        return KhoaTaiKhoanNhanVienV2Model.fromApiResponse(body);
      }

      throw Exception(
        body['message']?.toString() ?? 'Không thể khóa tài khoản nhân viên.',
      );
    }
  }

  // ===========================================================
  // VỊ TRÍ CÔNG TÁC
  // ===========================================================

  Future<void> createViTriCongTac(
    String maSo,
    Map<String, dynamic> data,
  ) async {
    try {
      await dio.post('$_basePath/$maSo/vi-tri-cong-tac', data: data);
    } on DioException catch (error) {
      throw Exception(
        _dioErrorMessage(error, 'Không thể thêm vị trí công tác.'),
      );
    }
  }

  Future<void> updateViTriCongTac(
    String maSo,
    int id,
    Map<String, dynamic> data,
  ) async {
    await dio.put('$_basePath/$maSo/vi-tri-cong-tac/$id', data: data);
  }

  Future<void> deleteViTriCongTac(String maSo, int id) async {
    await dio.delete('$_basePath/$maSo/vi-tri-cong-tac/$id');
  }

  // ===========================================================
  // CHỨNG CHỈ
  // ===========================================================

  Future<void> createChungChi(String maSo, Map<String, dynamic> data) async {
    await dio.post('$_basePath/$maSo/chung-chi', data: data);
  }

  Future<void> updateChungChi(
    String maSo,
    int id,
    Map<String, dynamic> data,
  ) async {
    await dio.put('$_basePath/$maSo/chung-chi/$id', data: data);
  }

  Future<void> deleteChungChi(String maSo, int id) async {
    await dio.delete('$_basePath/$maSo/chung-chi/$id');
  }

  // ===========================================================
  // BẰNG CẤP
  // ===========================================================

  Future<void> createBangCap(String maSo, Map<String, dynamic> data) async {
    await dio.post('$_basePath/$maSo/bang-cap', data: data);
  }

  Future<void> updateBangCap(
    String maSo,
    int id,
    Map<String, dynamic> data,
  ) async {
    await dio.put('$_basePath/$maSo/bang-cap/$id', data: data);
  }

  Future<void> deleteBangCap(String maSo, int id) async {
    await dio.delete('$_basePath/$maSo/bang-cap/$id');
  }

  // ===========================================================
  // CCHN
  // ===========================================================

  Future<void> createCchn(String maSo, Map<String, dynamic> data) async {
    await dio.post('$_basePath/$maSo/cchn', data: data);
  }

  Future<void> updateCchn(
    String maSo,
    int id,
    Map<String, dynamic> data,
  ) async {
    await dio.put('$_basePath/$maSo/cchn/$id', data: data);
  }

  Future<void> deleteCchn(String maSo, int id) async {
    await dio.delete('$_basePath/$maSo/cchn/$id');
  }

  // ===========================================================
  // HỢP ĐỒNG
  // ===========================================================

  Future<void> createHopDong(String maSo, Map<String, dynamic> data) async {
    await dio.post('$_basePath/$maSo/hop-dong-lao-dong', data: data);
  }

  Future<void> updateHopDong(
    String maSo,
    int id,
    Map<String, dynamic> data,
  ) async {
    await dio.put('$_basePath/$maSo/hop-dong-lao-dong/$id', data: data);
  }

  Future<void> deleteHopDong(String maSo, int id) async {
    await dio.delete('$_basePath/$maSo/hop-dong-lao-dong/$id');
  }

  // ===========================================================
  // THÂN NHÂN
  // ===========================================================

  Future<void> createThanNhan(String maSo, Map<String, dynamic> data) async {
    await dio.post('$_basePath/$maSo/than-nhan', data: data);
  }

  Future<void> updateThanNhan(
    String maSo,
    int id,
    Map<String, dynamic> data,
  ) async {
    await dio.put('$_basePath/$maSo/than-nhan/$id', data: data);
  }

  Future<void> deleteThanNhan(String maSo, int id) async {
    await dio.delete('$_basePath/$maSo/than-nhan/$id');
  }

  Future<List<NhanVienTaiLieuKhacV2Model>> getTaiLieuKhac(String maSo) async {
    final response = await dio.get('$_basePath/$maSo/tai-lieu-khac');

    final body = response.data;

    dynamic data = body;

    if (body is Map && body.containsKey('data')) {
      data = body['data'];
    }

    if (data is! List) {
      return [];
    }

    return data
        .whereType<Map>()
        .map(
          (e) =>
              NhanVienTaiLieuKhacV2Model.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
  }

  Future<List<NhanVienTaiLieuKhacV2Model>> uploadTaiLieuKhac({
    required String maSo,
    required List<fp.PlatformFile> files,
    DateTime? ngayTaiLieu,
    String? ghiChu,
  }) async {
    final formData = FormData();

    if (ngayTaiLieu != null) {
      formData.fields.add(
        MapEntry(
          'ngayTaiLieu',
          '${ngayTaiLieu.year.toString().padLeft(4, '0')}-'
              '${ngayTaiLieu.month.toString().padLeft(2, '0')}-'
              '${ngayTaiLieu.day.toString().padLeft(2, '0')}',
        ),
      );
    }

    final note = ghiChu?.trim();

    if (note != null && note.isNotEmpty) {
      formData.fields.add(MapEntry('ghiChu', note));
    }

    for (final file in files) {
      final bytes = file.bytes;

      if (bytes == null || bytes.isEmpty) {
        throw Exception('Không đọc được file "${file.name}".');
      }

      formData.files.add(
        MapEntry('files', MultipartFile.fromBytes(bytes, filename: file.name)),
      );
    }

    final response = await dio.post(
      '$_basePath/$maSo/tai-lieu-khac',
      data: formData,
    );

    final body = response.data;

    dynamic data = body;

    if (body is Map && body.containsKey('data')) {
      data = body['data'];
    }

    if (data is! List) {
      return [];
    }

    return data
        .whereType<Map>()
        .map(
          (e) =>
              NhanVienTaiLieuKhacV2Model.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
  }

  Future<NhanVienTaiLieuKhacV2Model> updateTaiLieuKhac({
    required String maSo,
    required int idTaiLieu,
    String? tenTaiLieu,
    DateTime? ngayTaiLieu,
    String? ghiChu,
    int? stt,
  }) async {
    final response = await dio.put(
      '$_basePath/$maSo/tai-lieu-khac/$idTaiLieu',

      data: {
        'tenTaiLieu': tenTaiLieu?.trim().isEmpty == true
            ? null
            : tenTaiLieu?.trim(),

        'ngayTaiLieu': ngayTaiLieu?.toIso8601String(),

        'ghiChu': ghiChu?.trim().isEmpty == true ? null : ghiChu?.trim(),

        'stt': stt,
      },
    );

    final body = response.data;

    final data = body is Map && body['data'] is Map ? body['data'] : body;

    return NhanVienTaiLieuKhacV2Model.fromJson(
      Map<String, dynamic>.from(data as Map),
    );
  }

  Future<Uint8List> downloadTaiLieuKhac({
    required String maSo,
    required int idTaiLieu,
  }) async {
    final response = await dio.get<List<int>>(
      '$_basePath/$maSo/tai-lieu-khac/'
      '$idTaiLieu/download',

      options: Options(responseType: ResponseType.bytes),
    );

    final data = response.data ?? <int>[];

    if (data.isEmpty) {
      throw Exception('File tải về không có dữ liệu.');
    }

    return Uint8List.fromList(data);
  }

  Future<bool> deleteTaiLieuKhac({
    required String maSo,
    required int idTaiLieu,
  }) async {
    await dio.delete('$_basePath/$maSo/tai-lieu-khac/$idTaiLieu');

    return true;
  }
  // ===========================================================
  // HELPERS
  // ===========================================================

  Map<String, dynamic> _extractDataMap(dynamic responseData) {
    final body = _asMap(responseData);

    final data = body['data'];

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      body['message']?.toString() ?? 'API không trả về dữ liệu hợp lệ.',
    );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return {};
  }

  String _dioErrorMessage(DioException error, String fallback) {
    final body = _errorBody(error.response?.data);
    final message = body['message'] ?? body['Message'];

    if (message != null && message.toString().trim().isNotEmpty) {
      return message.toString().trim();
    }

    return fallback;
  }

  Map<String, dynamic> _errorBody(dynamic value) {
    final directBody = _asMap(value);

    if (directBody.isNotEmpty) {
      return directBody;
    }

    try {
      dynamic decoded;

      if (value is List<int>) {
        decoded = jsonDecode(utf8.decode(value));
      } else if (value is String && value.trim().isNotEmpty) {
        decoded = jsonDecode(value);
      }

      return _asMap(decoded);
    } catch (_) {
      return {};
    }
  }

  String _formatApiDate(DateTime value) {
    final date = value.toLocal();

    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
