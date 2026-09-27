import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart' as fp;
import '../models/dao_tao_v2_models.dart';
import '../models/dao_tao_bao_cao_models.dart';
import '../utils/constants.dart';

class DaoTaoV2Service {
  final Dio dio;

  DaoTaoV2Service(this.dio);

  String get _basePath => '${AppConstants.baseUrl}/v2/DaoTao';

  Future<List<LopDaoTaoV2Model>> getDanhSach({
    String? keyword,
    bool? dangMoDangKy,
    DateTime? tuNgay,
    DateTime? denNgay,
  }) async {
    final query = <String, dynamic>{};

    final key = keyword?.trim();

    if (key != null && key.isNotEmpty) {
      query['keyword'] = key;
    }

    if (dangMoDangKy != null) {
      query['dangMoDangKy'] = dangMoDangKy;
    }
    if (tuNgay != null) {
      query['tuNgay'] = _apiDate(tuNgay);
    }

    if (denNgay != null) {
      query['denNgay'] = _apiDate(denNgay);
    }
    final response = await dio.get(
      '$_basePath/lop-dao-tao',
      queryParameters: query,
    );

    final data = _extractData(response.data);

    if (data is! List) {
      return [];
    }

    return data
        .whereType<Map>()
        .map((e) => LopDaoTaoV2Model.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  String _apiDate(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

  Future<LopDaoTaoV2Model> getById(int id) async {
    final response = await dio.get('$_basePath/lop-dao-tao/$id');

    final data = _extractDataMap(response.data);

    return LopDaoTaoV2Model.fromJson(data);
  }

  Future<List<LopDaoTaoV2Model>> getLopCuaToi() async {
    final response = await dio.get('$_basePath/lop-cua-toi');

    final data = _extractData(response.data);

    if (data is! List) {
      return [];
    }

    return data
        .whereType<Map>()
        .map((e) => LopDaoTaoV2Model.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<DaoTaoDanhMucV2Model> getDanhMuc() async {
    final response = await dio.get('$_basePath/danh-muc');

    return DaoTaoDanhMucV2Model.fromJson(_extractDataMap(response.data));
  }

  Future<DaoTaoBaoCaoDanhMucModel> getBaoCaoTongHopDanhMuc({
    required DateTime tuNgay,
    required DateTime denNgay,
  }) async {
    final response = await dio.get(
      '$_basePath/bao-cao-tong-hop/danh-muc',
      queryParameters: {
        'tuNgay': _apiDate(tuNgay),
        'denNgay': _apiDate(denNgay),
      },
    );
    return DaoTaoBaoCaoDanhMucModel.fromJson(_extractDataMap(response.data));
  }

  Future<DaoTaoBaoCaoTongHopModel> getBaoCaoTongHop(
    Map<String, dynamic> request,
  ) async {
    final response = await dio.post(
      '$_basePath/bao-cao-tong-hop',
      data: request,
    );
    return DaoTaoBaoCaoTongHopModel.fromJson(_extractDataMap(response.data));
  }

  Future<Uint8List> exportBaoCaoTongHopExcel(
    Map<String, dynamic> request,
  ) async {
    final response = await dio.post<List<int>>(
      '$_basePath/bao-cao-tong-hop/excel',
      data: request,
      options: Options(
        responseType: ResponseType.bytes,
        validateStatus: (status) => status != null && status < 500,
      ),
    );
    final bytes = response.data ?? const <int>[];
    if ((response.statusCode ?? 0) >= 200 &&
        (response.statusCode ?? 0) < 300 &&
        bytes.isNotEmpty) {
      return Uint8List.fromList(bytes);
    }
    var message = 'Không thể xuất báo cáo Excel.';
    if (bytes.isNotEmpty) {
      try {
        final decoded = jsonDecode(utf8.decode(bytes, allowMalformed: true));
        if (decoded is Map && decoded['message'] != null) {
          message = decoded['message'].toString();
        }
      } catch (_) {}
    }
    throw Exception(message);
  }

  Future<DaoTaoBaoCaoCmeDanhMucModel> getBaoCaoCmeDanhMuc() async {
    final response = await dio.get('$_basePath/bao-cao-cme/danh-muc');
    return DaoTaoBaoCaoCmeDanhMucModel.fromJson(_extractDataMap(response.data));
  }

  Future<DaoTaoBaoCaoCmeModel> getBaoCaoCme(
    Map<String, dynamic> request,
  ) async {
    final response = await dio.post('$_basePath/bao-cao-cme', data: request);
    return DaoTaoBaoCaoCmeModel.fromJson(_extractDataMap(response.data));
  }

  Future<Uint8List> exportBaoCaoCmeExcel(Map<String, dynamic> request) async {
    final response = await dio.post<List<int>>(
      '$_basePath/bao-cao-cme/excel',
      data: request,
      options: Options(
        responseType: ResponseType.bytes,
        validateStatus: (status) => status != null && status < 500,
      ),
    );
    final bytes = response.data ?? const <int>[];
    if ((response.statusCode ?? 0) >= 200 &&
        (response.statusCode ?? 0) < 300 &&
        bytes.isNotEmpty) {
      return Uint8List.fromList(bytes);
    }
    var message = 'Không thể xuất báo cáo CME.';
    if (bytes.isNotEmpty) {
      try {
        final decoded = jsonDecode(utf8.decode(bytes));
        if (decoded is Map && decoded['message'] != null) {
          message = decoded['message'].toString();
        }
      } catch (_) {}
    }
    throw Exception(message);
  }

  Future<bool> createLop(
    Map<String, dynamic> data, {
    required List<fp.PlatformFile> files,
  }) async {
    final formData = FormData();

    formData.fields.add(MapEntry('payload', jsonEncode(data)));

    for (final file in files) {
      final bytes = file.bytes;

      if (bytes == null || bytes.isEmpty) {
        throw Exception('Không đọc được file "${file.name}".');
      }

      formData.files.add(
        MapEntry('files', MultipartFile.fromBytes(bytes, filename: file.name)),
      );
    }

    await dio.post('$_basePath/lop-dao-tao', data: formData);

    return true;
  }

  Future<bool> updateLop(
    int id,
    Map<String, dynamic> data, {
    required List<fp.PlatformFile> files,
    required List<int> fileIdsToDelete,
  }) async {
    final formData = FormData();

    formData.fields.add(MapEntry('payload', jsonEncode(data)));

    for (final file in files) {
      final bytes = file.bytes;

      if (bytes == null || bytes.isEmpty) {
        throw Exception('Không đọc được file "${file.name}".');
      }

      formData.files.add(
        MapEntry('files', MultipartFile.fromBytes(bytes, filename: file.name)),
      );
    }

    for (final idFile in fileIdsToDelete) {
      formData.fields.add(MapEntry('fileIdsToDelete', idFile.toString()));
    }

    await dio.put('$_basePath/lop-dao-tao/$id', data: formData);

    return true;
  }

  Future<bool> deleteLop(int id) async {
    await dio.delete('$_basePath/lop-dao-tao/$id');

    return true;
  }

  Future<bool> dangKy(int id, {bool isDangKyOnline = false}) async {
    await dio.post(
      '$_basePath/lop-dao-tao/$id/dang-ky',

      queryParameters: {'isDangKyOnline': isDangKyOnline},
    );

    return true;
  }

  Future<bool> huyDangKy(int id) async {
    await dio.delete('$_basePath/lop-dao-tao/$id/dang-ky');

    return true;
  }

  Future<List<LopDaoTaoFileV2Model>> getTaiLieu(int idLopDaoTao) async {
    final response = await dio.get(
      '$_basePath/lop-dao-tao/'
      '$idLopDaoTao/tai-lieu',
    );

    final data = _extractData(response.data);

    if (data is! List) {
      return [];
    }

    return data
        .whereType<Map>()
        .map((e) => LopDaoTaoFileV2Model.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Uint8List> downloadTaiLieu({
    required int idLopDaoTao,
    required int idFile,
  }) async {
    final response = await dio.get<List<int>>(
      '$_basePath/lop-dao-tao/'
      '$idLopDaoTao/'
      'tai-lieu/'
      '$idFile/download',

      options: Options(responseType: ResponseType.bytes),
    );

    final bytes = response.data ?? <int>[];

    if (bytes.isEmpty) {
      throw Exception('File tải về không có dữ liệu.');
    }

    return Uint8List.fromList(bytes);
  }

  Future<DaoTaoUploadedFileV2Model> uploadFile({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    });

    final response = await dio.post(
      '${AppConstants.baseUrl}/v2/NhanVien/upload-file',
      data: formData,
    );

    return DaoTaoUploadedFileV2Model.fromJson(_extractDataMap(response.data));
  }

  // ==========================================================
  // RESPONSE HELPERS
  // ==========================================================

  dynamic _extractData(dynamic body) {
    if (body is Map) {
      if (body.containsKey('data')) {
        return body['data'];
      }

      if (body.containsKey('result')) {
        return body['result'];
      }
    }

    return body;
  }

  Map<String, dynamic> _extractDataMap(dynamic body) {
    final data = _extractData(body);

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return <String, dynamic>{};
  }

  Future<DaoTaoDashboardV2Model> getDashboard(int idLopDaoTao) async {
    final response = await dio.get(
      '$_basePath/lop-dao-tao/$idLopDaoTao/dashboard',
    );

    final data = _extractDataMap(response.data);

    return DaoTaoDashboardV2Model.fromJson(data);
  }

  Future<DaoTaoChamCongBaoCaoV2Model> getBaoCaoChamCong(int idLopDaoTao) async {
    final response = await dio.get(
      '$_basePath/lop-dao-tao/$idLopDaoTao/cham-cong',
    );

    return DaoTaoChamCongBaoCaoV2Model.fromJson(_extractDataMap(response.data));
  }

  Future<List<DaoTaoNguoiDangKyV2Model>> getNguoiDangKy(int idLopDaoTao) async {
    final response = await dio.get(
      '$_basePath/lop-dao-tao/$idLopDaoTao/nguoi-dang-ky',
    );

    final data = _extractData(response.data);

    if (data is! List) {
      return [];
    }

    return data
        .whereType<Map>()
        .map(
          (e) =>
              DaoTaoNguoiDangKyV2Model.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
  }

  Future<CapChungChiDaoTaoResultV2Model> capChungChi({
    required int idLopDaoTao,
    required List<String> maSos,
    required bool cme,
    DateTime? ngayHetHan,
    String? soChungChi,
  }) async {
    final response = await dio.post(
      '$_basePath/lop-dao-tao/$idLopDaoTao/cap-chung-chi',
      data: {
        'maSos': maSos,

        'cme': cme,

        'ngayHetHan': ngayHetHan?.toIso8601String(),

        'soChungChi': soChungChi?.trim().isEmpty == true
            ? null
            : soChungChi?.trim(),
      },
    );

    return CapChungChiDaoTaoResultV2Model.fromJson(
      _extractDataMap(response.data),
    );
  }

  Future<DaoTaoThongTinOnlineV2Model> getThongTinOnline(int idLopDaoTao) async {
    final response = await dio.get(
      '$_basePath/lop-dao-tao/'
      '$idLopDaoTao/thong-tin-online',
    );

    return DaoTaoThongTinOnlineV2Model.fromJson(_extractDataMap(response.data));
  }

  // ==========================================================
  // NHÂN VIÊN CHƯA ĐĂNG KÝ
  // ==========================================================

  Future<List<DaoTaoNhanVienChuaDangKyV2Model>> getNhanVienChuaDangKy(
    int idLopDaoTao, {
    String? keyword,
  }) async {
    final query = <String, dynamic>{};

    final key = keyword?.trim();

    if (key != null && key.isNotEmpty) {
      query['keyword'] = key;
    }

    final response = await dio.get(
      '$_basePath/lop-dao-tao/'
      '$idLopDaoTao/nhan-vien-chua-dang-ky',

      queryParameters: query,
    );

    final data = _extractData(response.data);

    if (data is! List) {
      return [];
    }

    return data
        .whereType<Map>()
        .map(
          (e) => DaoTaoNhanVienChuaDangKyV2Model.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList();
  }

  // ==========================================================
  // BỔ SUNG NGƯỜI ĐĂNG KÝ
  // ==========================================================

  Future<BoSungNguoiDangKyResultV2Model> boSungNguoiDangKy({
    required int idLopDaoTao,
    required Map<String, bool> nhanViens,
  }) async {
    final response = await dio.post(
      '$_basePath/lop-dao-tao/'
      '$idLopDaoTao/bo-sung-nguoi-dang-ky',

      data: {
        'nhanViens': nhanViens.entries
            .map((entry) => {'maSo': entry.key, 'isDangKyOnline': entry.value})
            .toList(),
      },
    );

    return BoSungNguoiDangKyResultV2Model.fromJson(
      _extractDataMap(response.data),
    );
  }

  // ==========================================================
  // DANH SÁCH XÁC NHẬN HỌC VIÊN
  //
  // TAB: ĐÃ ĐĂNG KÝ TRƯỚC
  // ==========================================================

  Future<List<DaoTaoXacNhanHocVienV2Model>> getXacNhanHocVien(
    int idLopDaoTao,
  ) async {
    final response = await dio.get(
      '$_basePath/lop-dao-tao/'
      '$idLopDaoTao/xac-nhan-hoc-vien',
    );

    final data = _extractData(response.data);

    if (data is! List) {
      return [];
    }

    return data
        .whereType<Map>()
        .map(
          (e) => DaoTaoXacNhanHocVienV2Model.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList();
  }

  // ==========================================================
  // LƯU XÁC NHẬN HỌC VIÊN HỢP LỆ
  // ==========================================================

  Future<bool> xacNhanHocVien({
    required int idLopDaoTao,
    required Map<String, bool> nhanViens,
  }) async {
    await dio.post(
      '$_basePath/lop-dao-tao/'
      '$idLopDaoTao/xac-nhan-hoc-vien',

      data: {
        'nhanViens': nhanViens.entries
            .map((entry) => {'maSo': entry.key, 'isHopLeDaoTao': entry.value})
            .toList(),
      },
    );

    return true;
  }

  Future<Uint8List> exportChamCongExcel(int idLopDaoTao) async {
    final response = await dio.get<List<int>>(
      '$_basePath/lop-dao-tao/$idLopDaoTao/cham-cong/excel',
      options: Options(
        responseType: ResponseType.bytes,
        validateStatus: (status) {
          return status != null && status < 500;
        },
      ),
    );

    final statusCode = response.statusCode ?? 0;

    final rawBytes = response.data ?? <int>[];

    // ========================================================
    // THÀNH CÔNG
    // ========================================================

    if (statusCode >= 200 && statusCode < 300) {
      if (rawBytes.isEmpty) {
        throw Exception('File Excel trả về rỗng.');
      }

      return Uint8List.fromList(rawBytes);
    }

    String message = 'Xuất Excel thất bại. HTTP $statusCode.';

    if (rawBytes.isNotEmpty) {
      try {
        final text = utf8.decode(rawBytes, allowMalformed: true);

        final decoded = jsonDecode(text);

        if (decoded is Map) {
          final backendMessage = decoded['message'] ?? decoded['Message'];

          if (backendMessage != null &&
              backendMessage.toString().trim().isNotEmpty) {
            message = backendMessage.toString();
          }
        } else if (text.trim().isNotEmpty) {
          message = text.trim();
        }
      } catch (_) {
        try {
          final text = utf8.decode(rawBytes, allowMalformed: true);

          if (text.trim().isNotEmpty) {
            message = text.trim();
          }
        } catch (_) {
          // Giữ message mặc định.
        }
      }
    }

    throw Exception(message);
  }

  Future<DaoTaoInDiemDanhV2Model> getDuLieuInDiemDanh({
    required int idLopDaoTao,
    required String loaiIn,
    required DateTime ngayInDiemDanh,
  }) async {
    final response = await dio.post(
      '$_basePath/lop-dao-tao/'
      '$idLopDaoTao/in-diem-danh',

      data: {
        'loaiIn': loaiIn,

        'ngayInDiemDanh': ngayInDiemDanh.toIso8601String(),
      },
    );

    return DaoTaoInDiemDanhV2Model.fromJson(_extractDataMap(response.data));
  }
}
