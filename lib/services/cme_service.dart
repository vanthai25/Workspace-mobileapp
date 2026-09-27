import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../models/cme_model.dart';
import '../utils/constants.dart';
import 'api_client.dart';

class CmeService {
  static const Duration _longRequestTimeout = Duration(minutes: 2);

  final Dio _dio;

  CmeService({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  String get _baseUrl => '${AppConstants.baseUrl}/v2/CME';

  Future<List<CmeTrainingType>> getTrainingTypes() async {
    try {
      final Response<dynamic> response = await _dio.get(
        '$_baseUrl/hinh-thuc-dao-tao',
      );
      final dynamic data = _readSuccessData(
        response,
        fallback: 'Không thể tải danh mục hình thức đào tạo.',
      );

      if (data is! List) {
        throw _invalidResponse();
      }

      return List<CmeTrainingType>.unmodifiable(
        data.whereType<Map>().map(
          (Map<dynamic, dynamic> item) =>
              CmeTrainingType.fromJson(Map<String, dynamic>.from(item)),
        ),
      );
    } on DioException catch (error) {
      throw _convertDioError(error);
    } on CmeApiException {
      rethrow;
    } on FormatException {
      throw _invalidResponse();
    }
  }

  Future<List<CmeDepartment>> getDepartments() async {
    try {
      final Response<dynamic> response = await _dio.get('$_baseUrl/khoa');
      final dynamic data = _readSuccessData(
        response,
        fallback: 'Không thể tải danh mục khoa/phòng.',
      );

      if (data is! List) {
        throw _invalidResponse();
      }

      final List<CmeDepartment> departments = data
          .whereType<Map>()
          .map(
            (Map<dynamic, dynamic> item) =>
                CmeDepartment.fromJson(Map<String, dynamic>.from(item)),
          )
          .where((CmeDepartment item) => item.maKhoa.isNotEmpty)
          .toList(growable: false);

      return List<CmeDepartment>.unmodifiable(departments);
    } on DioException catch (error) {
      throw _convertDioError(error);
    } on CmeApiException {
      rethrow;
    } on FormatException {
      throw _invalidResponse();
    }
  }

  Future<CmePagedResult> getMyRequests([CmeQuery query = const CmeQuery()]) {
    return _getPaged('$_baseUrl/yeu-cau-cua-toi', query);
  }

  Future<CmePagedResult> getApprovalRequests([
    CmeQuery query = const CmeQuery(trangThai: CmeStatus.choDuyet),
  ]) {
    return _getPaged('$_baseUrl/yeu-cau', query);
  }

  Future<CmeDashboardSummary> getDashboard({
    int soNgaySapHetHan = 60,
    int gioiHan = 5,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get(
        '$_baseUrl/thong-bao',
        queryParameters: <String, dynamic>{
          'SoNgaySapHetHan': soNgaySapHetHan.clamp(1, 365),
          'GioiHan': gioiHan.clamp(1, 50),
        },
      );
      final dynamic data = _readSuccessData(
        response,
        fallback: 'Không thể tải thông báo CME.',
      );

      if (data is! Map) {
        throw _invalidResponse();
      }

      return CmeDashboardSummary.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (error) {
      throw _convertDioError(error);
    } on CmeApiException {
      rethrow;
    } on FormatException {
      throw _invalidResponse();
    }
  }

  Future<CmeRequestModel> getById(int id) async {
    try {
      final Response<dynamic> response = await _dio.get(
        '$_baseUrl/yeu-cau/$id',
      );
      return _readRequestModel(
        response,
        fallback: 'Không thể tải chi tiết yêu cầu CME.',
      );
    } on DioException catch (error) {
      throw _convertDioError(error);
    } on CmeApiException {
      rethrow;
    } on FormatException {
      throw _invalidResponse();
    }
  }

  Future<CmeRequestModel> create(CmeCreateInput input) async {
    final String safeFileName = _safeFileName(input.fileName);
    final Map<String, dynamic> fields = <String, dynamic>{
      'TenChungChi': input.tenChungChi.trim(),
      if (_hasText(input.soChungChi)) 'SoChungChi': input.soChungChi!.trim(),
      if (_hasText(input.donViDaoTao)) 'DonViDaoTao': input.donViDaoTao!.trim(),
      if (input.idHinhThucDaoTao != null)
        'IdHinhThucDaoTao': input.idHinhThucDaoTao.toString(),
      if (input.ngayBatDau != null)
        'NgayBatDau': input.ngayBatDau!.toIso8601String(),
      if (input.ngayKetThuc != null)
        'NgayKetThuc': input.ngayKetThuc!.toIso8601String(),
      if (input.soTiet != null) 'SoTiet': input.soTiet.toString(),
      if (input.ngayCap != null) 'NgayCap': input.ngayCap!.toIso8601String(),
      if (input.chuKy != null) 'ChuKy': input.chuKy.toString(),
      if (input.ngayHetHan != null)
        'NgayHetHan': input.ngayHetHan!.toIso8601String(),
      'File': MultipartFile.fromBytes(input.fileBytes, filename: safeFileName),
    };

    try {
      final Response<dynamic> response = await _dio.post(
        '$_baseUrl/yeu-cau',
        data: FormData.fromMap(fields),
        options: Options(
          contentType: Headers.multipartFormDataContentType,
          sendTimeout: _longRequestTimeout,
          receiveTimeout: _longRequestTimeout,
        ),
      );

      return _readRequestModel(
        response,
        fallback: 'Không thể gửi yêu cầu CME.',
      );
    } on DioException catch (error) {
      throw _convertDioError(error);
    } on CmeApiException {
      rethrow;
    } on FormatException {
      throw _invalidResponse();
    }
  }

  Future<void> deleteRequest(int id) async {
    try {
      final Response<dynamic> response = await _dio.delete(
        '$_baseUrl/yeu-cau/$id',
      );
      _readSuccessData(response, fallback: 'Không thể xóa yêu cầu CME.');
    } on DioException catch (error) {
      throw _convertDioError(error);
    } on CmeApiException {
      rethrow;
    } on FormatException {
      throw _invalidResponse();
    }
  }

  Future<CmeAttachment> downloadAttachment(int id) async {
    try {
      final Response<List<int>> response = await _dio.get<List<int>>(
        '$_baseUrl/yeu-cau/$id/file',
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: _longRequestTimeout,
        ),
      );
      final List<int>? data = response.data;

      if (!_isSuccessStatus(response.statusCode) ||
          data == null ||
          data.isEmpty) {
        throw const CmeApiException(
          message: 'Không thể tải file đính kèm CME.',
        );
      }

      final String contentType =
          response.headers.value(Headers.contentTypeHeader)?.split(';').first ??
          'application/octet-stream';
      final String fileName =
          _fileNameFromHeaders(response.headers) ??
          _fallbackFileName(id, contentType);

      return CmeAttachment(
        bytes: Uint8List.fromList(data),
        fileName: fileName,
        contentType: contentType.trim().toLowerCase(),
      );
    } on DioException catch (error) {
      throw _convertDioError(error);
    } on CmeApiException {
      rethrow;
    }
  }

  Future<CmeRequestModel> approve(int id) async {
    try {
      final Response<dynamic> response = await _dio.post(
        '$_baseUrl/yeu-cau/$id/duyet',
      );
      return _readRequestModel(
        response,
        fallback: 'Không thể duyệt yêu cầu CME.',
      );
    } on DioException catch (error) {
      throw _convertDioError(error);
    } on CmeApiException {
      rethrow;
    } on FormatException {
      throw _invalidResponse();
    }
  }

  Future<CmeRequestModel> cancelApproval(int id) async {
    try {
      final Response<dynamic> response = await _dio.post(
        '$_baseUrl/yeu-cau/$id/huy-duyet',
      );
      return _readRequestModel(
        response,
        fallback: 'Không thể hủy duyệt yêu cầu CME.',
      );
    } on DioException catch (error) {
      throw _convertDioError(error);
    } on CmeApiException {
      rethrow;
    } on FormatException {
      throw _invalidResponse();
    }
  }

  Future<CmeRequestModel> reject(int id, String reason) async {
    try {
      final Response<dynamic> response = await _dio.post(
        '$_baseUrl/yeu-cau/$id/tu-choi',
        data: <String, dynamic>{'LyDoTuChoi': reason.trim()},
      );
      return _readRequestModel(
        response,
        fallback: 'Không thể từ chối yêu cầu CME.',
      );
    } on DioException catch (error) {
      throw _convertDioError(error);
    } on CmeApiException {
      rethrow;
    } on FormatException {
      throw _invalidResponse();
    }
  }

  Future<CmePagedResult> _getPaged(String url, CmeQuery query) async {
    try {
      final Response<dynamic> response = await _dio.get(
        url,
        queryParameters: query.toQueryParameters(),
      );
      final dynamic data = _readSuccessData(
        response,
        fallback: 'Không thể tải danh sách yêu cầu CME.',
      );

      if (data is! Map) {
        throw _invalidResponse();
      }

      return CmePagedResult.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (error) {
      throw _convertDioError(error);
    } on CmeApiException {
      rethrow;
    } on FormatException {
      throw _invalidResponse();
    }
  }

  CmeRequestModel _readRequestModel(
    Response<dynamic> response, {
    required String fallback,
  }) {
    final dynamic data = _readSuccessData(response, fallback: fallback);
    if (data is! Map) {
      throw _invalidResponse();
    }

    return CmeRequestModel.fromJson(Map<String, dynamic>.from(data));
  }

  dynamic _readSuccessData(
    Response<dynamic> response, {
    required String fallback,
  }) {
    final Map<String, dynamic> body = _toMap(response.data);
    final bool success = _asBool(body['success'] ?? body['Success']) ?? false;

    if (!_isSuccessStatus(response.statusCode) || !success) {
      throw _exceptionFromBody(
        body,
        statusCode: response.statusCode,
        fallback: fallback,
      );
    }

    return body['data'] ?? body['Data'];
  }

  CmeApiException _convertDioError(DioException error) {
    final int? statusCode = error.response?.statusCode;
    final Map<String, dynamic> body = _toMap(error.response?.data);
    final String fallback;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        fallback = 'Kết nối máy chủ quá thời gian. Vui lòng thử lại.';
      case DioExceptionType.connectionError:
        fallback = 'Không thể kết nối máy chủ. Vui lòng kiểm tra mạng.';
      case DioExceptionType.cancel:
        fallback = 'Yêu cầu đã bị hủy.';
      default:
        fallback = 'Có lỗi khi kết nối máy chủ.';
    }

    if (body.isNotEmpty) {
      return _exceptionFromBody(
        body,
        statusCode: statusCode,
        fallback: fallback,
      );
    }

    final String? rawMessage = _readPlainMessage(error.response?.data);
    return CmeApiException(
      message: rawMessage ?? fallback,
      statusCode: statusCode,
    );
  }

  CmeApiException _exceptionFromBody(
    Map<String, dynamic> body, {
    required int? statusCode,
    required String fallback,
  }) {
    final String? message = _asNonEmptyString(
      body['message'] ?? body['Message'],
    );
    final String? code = _asNonEmptyString(body['code'] ?? body['Code']);
    final List<String> validationMessages = _readValidationMessages(
      body['data'] ?? body['Data'],
    );
    final String resolvedMessage = validationMessages.isEmpty
        ? message ?? fallback
        : <String>{?message, ...validationMessages}.join('\n');

    return CmeApiException(
      message: resolvedMessage,
      statusCode: statusCode,
      code: code,
    );
  }

  Map<String, dynamic> _toMap(dynamic value) {
    final dynamic decoded = _decodePayload(value);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }

    return const <String, dynamic>{};
  }

  dynamic _decodePayload(dynamic value) {
    if (value is Map) {
      return value;
    }

    String? text;
    if (value is Uint8List) {
      text = utf8.decode(value, allowMalformed: true).trim();
    } else if (value is List<int>) {
      text = utf8.decode(value, allowMalformed: true).trim();
    } else if (value is List && value.every((dynamic item) => item is int)) {
      text = utf8.decode(value.cast<int>(), allowMalformed: true).trim();
    } else if (value is String) {
      text = value.trim();
    }

    if (text == null || text.isEmpty) {
      return value;
    }

    try {
      return jsonDecode(text);
    } on FormatException {
      return text;
    }
  }

  String? _readPlainMessage(dynamic value) {
    final dynamic decoded = _decodePayload(value);
    if (decoded is! String || decoded.isEmpty || decoded.length > 1000) {
      return null;
    }

    return decoded;
  }

  List<String> _readValidationMessages(dynamic value) {
    if (value is! Map) {
      return const <String>[];
    }

    final List<String> messages = <String>[];
    for (final dynamic rawValue in value.values) {
      if (rawValue is List) {
        messages.addAll(rawValue.map(_asNonEmptyString).whereType<String>());
      } else {
        final String? message = _asNonEmptyString(rawValue);
        if (message != null) {
          messages.add(message);
        }
      }
    }

    return messages.toSet().toList(growable: false);
  }

  String? _fileNameFromHeaders(Headers headers) {
    final String? contentDisposition = headers.value('content-disposition');
    if (contentDisposition == null || contentDisposition.isEmpty) {
      return null;
    }

    final RegExpMatch? encodedMatch = RegExp(
      r"filename\*\s*=\s*(?:UTF-8'')?([^;]+)",
      caseSensitive: false,
    ).firstMatch(contentDisposition);
    String? fileName = encodedMatch?.group(1)?.trim();

    if (fileName != null) {
      fileName = fileName.replaceAll('"', '');
      try {
        fileName = Uri.decodeComponent(fileName);
      } on FormatException {
        // Giữ tên gốc khi header không encode URI hợp lệ.
      }
    } else {
      final RegExpMatch? plainMatch = RegExp(
        r'filename\s*=\s*"?([^";]+)"?',
        caseSensitive: false,
      ).firstMatch(contentDisposition);
      fileName = plainMatch?.group(1)?.trim();
    }

    return _hasText(fileName) ? _safeFileName(fileName!) : null;
  }

  String _fallbackFileName(int id, String contentType) {
    final String extension = switch (contentType.toLowerCase()) {
      'application/pdf' => 'pdf',
      'image/jpeg' => 'jpg',
      'image/png' => 'png',
      'image/webp' => 'webp',
      'image/heic' => 'heic',
      'image/heif' => 'heif',
      _ => 'bin',
    };
    return 'cme-$id.$extension';
  }

  String _safeFileName(String value) {
    final String normalized = value
        .replaceAll('\\', '/')
        .split('/')
        .last
        .trim();
    return normalized.isEmpty ? 'cme-file' : normalized;
  }

  bool _isSuccessStatus(int? statusCode) =>
      statusCode != null && statusCode >= 200 && statusCode < 300;

  CmeApiException _invalidResponse() => const CmeApiException(
    message: 'Dữ liệu phản hồi từ máy chủ không hợp lệ.',
    code: 'INVALID_RESPONSE',
  );
}

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

String? _asNonEmptyString(dynamic value) {
  if (value == null) {
    return null;
  }

  final String text = value.toString().trim();
  return text.isEmpty ? null : text;
}

bool? _asBool(dynamic value) {
  if (value is bool) {
    return value;
  }

  if (value == null) {
    return null;
  }

  return switch (value.toString().trim().toLowerCase()) {
    'true' || '1' => true,
    'false' || '0' => false,
    _ => null,
  };
}
