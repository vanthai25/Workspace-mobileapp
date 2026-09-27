import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import '../models/thuc_hanh_models.dart';
import '../utils/constants.dart';

class ThucHanhService {
  final Dio dio;
  ThucHanhService(this.dio);
  String get _base => '${AppConstants.baseUrl}/v2/DaoTao/thuc-hanh';
  String get _public => '${AppConstants.baseUrl}/v2/public/dao-tao-thuc-hanh';

  Future<ThucHanhPage<NguoiThucHanhModel>> getPeople({
    String? keyword,
    int? batchId,
    int page = 1,
    int pageSize = 20,
  }) => _page(
    '$_base/nguoi-thuc-hanh',
    NguoiThucHanhModel.fromJson,
    query: {
      'keyword': keyword,
      'idDotThucHanh': batchId,
      'page': page,
      'pageSize': pageSize,
    },
  );
  Future<NguoiThucHanhModel> getPerson(int id) =>
      _one('$_base/nguoi-thuc-hanh/$id', NguoiThucHanhModel.fromJson);
  Future<void> savePerson({
    int? id,
    required Map<String, dynamic> payload,
    PlatformFile? avatar,
    List<PlatformFile> files = const [],
  }) => _multipart(
    id == null ? 'POST' : 'PUT',
    id == null ? '$_base/nguoi-thuc-hanh' : '$_base/nguoi-thuc-hanh/$id',
    payload,
    avatar: avatar,
    files: files,
  );
  Future<void> deletePerson(int id) => _delete('$_base/nguoi-thuc-hanh/$id');

  Future<ThucHanhPage<DotThucHanhModel>> getBatches({
    String? keyword,
    int? registrationState,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 1,
    int pageSize = 20,
  }) => _page(
    '$_base/dot',
    DotThucHanhModel.fromJson,
    query: {
      'keyword': keyword,
      'tinhTrangDangKy': registrationState,
      'tuNgay': fromDate?.toIso8601String(),
      'denNgay': toDate?.toIso8601String(),
      'page': page,
      'pageSize': pageSize,
    },
  );
  Future<DotThucHanhModel> getBatch(int id) =>
      _one('$_base/dot/$id', DotThucHanhModel.fromJson);
  Future<DotThucHanhModel> saveBatch({
    int? id,
    required Map<String, dynamic> payload,
    PlatformFile? decision,
  }) async {
    final form = _form(payload, decision: decision);
    final url = id == null ? '$_base/dot' : '$_base/dot/$id';
    final response = await _request(
      () => id == null ? dio.post(url, data: form) : dio.put(url, data: form),
    );
    return DotThucHanhModel.fromJson(_map(_map(response.data)['data']));
  }

  Future<void> deleteBatch(int id) => _delete('$_base/dot/$id');

  Future<Uint8List> downloadImportTemplate(int batchId) =>
      download('$_base/dot/$batchId/excel-mau');

  Future<Map<String, dynamic>> importPeople(
    int batchId,
    PlatformFile file,
  ) async {
    if (file.bytes == null) {
      throw Exception('Không đọc được file ${file.name}.');
    }
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(file.bytes!, filename: file.name),
    });
    final response = await _request(
      () => dio.post('$_base/dot/$batchId/import-excel', data: form),
    );
    return _map(_map(response.data)['data']);
  }

  Future<Uint8List> exportBatchReport(int batchId) =>
      download('$_base/dot/$batchId/bao-cao');

  Future<ThucHanhPage<DangKyThucHanhModel>> getRegistrations({
    String? keyword,
    int? batchId,
    int? practiceState,
    int? source,
    int page = 1,
    int pageSize = 20,
  }) => _page(
    '$_base/dang-ky',
    DangKyThucHanhModel.fromJson,
    query: {
      'keyword': keyword,
      'idDotThucHanh': batchId,
      'tinhTrangThucHanh': practiceState,
      'nguonDangKy': source,
      'page': page,
      'pageSize': pageSize,
    },
  );
  Future<DangKyThucHanhModel> getRegistration(int id) =>
      _one('$_base/dang-ky/$id', DangKyThucHanhModel.fromJson);
  Future<String> createRegistration(int personId, int batchId) async {
    final response = await _request(
      () => dio.post(
        '$_base/dang-ky',

        data: {'idNguoiThucHanh': personId, 'idDotThucHanh': batchId},
      ),
    );

    return _map(response.data)['message']?.toString() ??
        'Đã thêm người vào đợt.';
  }

  Future<void> deleteRegistration(int id) => _delete('$_base/dang-ky/$id');
  Future<void> saveAssignment(
    int registrationId,
    Map<String, dynamic> data, {
    int? id,
  }) async => _request(
    () => id == null
        ? dio.post('$_base/dang-ky/$registrationId/phan-cong', data: data)
        : dio.put('$_base/dang-ky/$registrationId/phan-cong/$id', data: data),
  );
  Future<void> deleteAssignment(int registrationId, int id) =>
      _delete('$_base/dang-ky/$registrationId/phan-cong/$id');

  Future<ThucHanhPage<DotThucHanhModel>> getPublicBatches({
    String? keyword,
    int page = 1,
    int pageSize = 12,
  }) => _page(
    '$_public/dot',
    DotThucHanhModel.fromJson,
    query: {'keyword': keyword, 'page': page, 'pageSize': pageSize},
  );

  Future<DotThucHanhModel> getPublicBatch(String token) =>
      _one('$_public/dot/$token', DotThucHanhModel.fromJson);
  Future<Map<String, dynamic>> publicRegister(
    String token,
    Map<String, dynamic> payload, {
    PlatformFile? avatar,
    List<PlatformFile> files = const [],
  }) async {
    final data = Map<String, dynamic>.from(payload);

    final form = _form(data, avatar: avatar, files: files);

    final r = await _request(
      () => dio.post('$_public/dot/$token/dang-ky', data: form),
    );

    return _map(_map(r.data)['data']);
  }

  Future<TraCuuThucHanhModel> lookupRegistration(String lookupCode) =>
      _one('$_public/tra-cuu/$lookupCode', TraCuuThucHanhModel.fromJson);

  Future<Uint8List> download(String url) async {
    final r = await dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(r.data ?? []);
  }

  String avatarUrl(int id) => '$_base/nguoi-thuc-hanh/$id/anh-dai-dien';
  String personFileUrl(int id, int fileId) =>
      '$_base/nguoi-thuc-hanh/$id/files/$fileId';
  String decisionUrl(int id) => '$_base/dot/$id/quyet-dinh';
  String publicDecisionUrl(String token) => '$_public/dot/$token/quyet-dinh';

  Future<ThucHanhPage<T>> _page<T>(
    String url,
    T Function(Map<String, dynamic>) parse, {
    Map<String, dynamic>? query,
  }) async {
    final r = await _get(url, query: query);
    final body = _map(r.data), meta = _map(body['metadata']);
    return ThucHanhPage(
      items: _dataList(r).map(parse).toList(),
      page: _i(meta['currentPage'], 1),
      totalPages: _i(meta['totalPages'], 0),
      totalCount: _i(meta['totalCount'], 0),
    );
  }

  Future<T> _one<T>(String url, T Function(Map<String, dynamic>) parse) async {
    final r = await _get(url);
    return parse(_map(_map(r.data)['data']));
  }

  Future<Response<dynamic>> _get(String url, {Map<String, dynamic>? query}) {
    Map<String, dynamic>? parameters;
    if (query != null) {
      parameters = Map<String, dynamic>.from(query);
      parameters.removeWhere(
        (_, dynamic value) => value == null || value == '',
      );
    }
    return _request(() => dio.get(url, queryParameters: parameters));
  }

  Future<void> _delete(String url) async => _request(() => dio.delete(url));
  Future<void> _multipart(
    String method,
    String url,
    Map<String, dynamic> payload, {
    PlatformFile? avatar,
    PlatformFile? decision,
    List<PlatformFile> files = const [],
  }) async {
    final form = _form(
      payload,
      avatar: avatar,
      decision: decision,
      files: files,
    );
    await _request(
      () => method == 'POST'
          ? dio.post(url, data: form)
          : dio.put(url, data: form),
    );
  }

  FormData _form(
    Map<String, dynamic> payload, {
    PlatformFile? avatar,
    PlatformFile? decision,
    List<PlatformFile> files = const [],
  }) {
    final form = FormData.fromMap({'payload': jsonEncode(payload)});
    void add(String key, PlatformFile? f) {
      if (f != null) {
        if (f.bytes == null) throw Exception('Không đọc được file ${f.name}.');
        form.files.add(
          MapEntry(key, MultipartFile.fromBytes(f.bytes!, filename: f.name)),
        );
      }
    }

    add('anhDaiDien', avatar);
    add('fileQuyetDinh', decision);
    for (final f in files) {
      add('files', f);
    }
    return form;
  }

  Future<Response<dynamic>> _request(
    Future<Response<dynamic>> Function() call,
  ) async {
    try {
      final r = await call();
      final b = _map(r.data);
      if (b['success'] == false) {
        throw Exception(_errorMessage(b));
      }
      return r;
    } on DioException catch (e) {
      final b = _map(e.response?.data);
      throw Exception(
        b.isEmpty ? 'Không thể kết nối máy chủ.' : _errorMessage(b),
      );
    }
  }

  String _errorMessage(Map<String, dynamic> body) {
    final message = body['message']?.toString() ?? 'Yêu cầu không thành công.';
    final errors = body['errors'];
    if (errors is! Map) return message;
    final details = <String>[];
    for (final entry in errors.entries) {
      final value = entry.value;
      if (value is List) {
        final messages = value
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .join(' ');
        if (messages.isNotEmpty) details.add('${entry.key}: $messages');
      } else if (value != null) {
        details.add('${entry.key}: $value');
      }
    }
    final unique = details.where((e) => e.trim().isNotEmpty).toSet();
    return unique.isEmpty ? message : '$message ${unique.join(' ')}';
  }

  List<Map<String, dynamic>> _dataList(Response<dynamic> r) {
    final d = _map(r.data)['data'];
    return d is List
        ? d.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : [];
  }

  Map<String, dynamic> _map(dynamic v) =>
      v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
  int _i(dynamic v, int fallback) =>
      v is int ? v : int.tryParse('$v') ?? fallback;
}
