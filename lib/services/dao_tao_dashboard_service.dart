import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../models/dao_tao_dashboard_models.dart';
import '../utils/constants.dart';

class DaoTaoDashboardDownload {
  final Uint8List bytes;
  final String fileName;

  const DaoTaoDashboardDownload({required this.bytes, required this.fileName});
}

class DaoTaoDashboardService {
  final Dio dio;
  static const String _base = '/v2/DaoTao/dashboard';

  DaoTaoDashboardService(this.dio);

  Future<DaoTaoDashboardModel> getDashboard() async {
    final response = await dio.get('${AppConstants.baseUrl}$_base');
    final body = _asMap(response.data);
    return DaoTaoDashboardModel.fromJson(_asMap(body['data']));
  }

  Future<DaoTaoDashboardDownload> exportExcel() async {
    final response = await dio.get<List<int>>(
      '${AppConstants.baseUrl}$_base/export-excel',
      options: Options(responseType: ResponseType.bytes),
    );
    return DaoTaoDashboardDownload(
      bytes: Uint8List.fromList(response.data ?? const <int>[]),
      fileName: _fileName(response.headers) ?? 'Bao_cao_tong_quan_dao_tao.xlsx',
    );
  }

  Map<String, dynamic> _asMap(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  String? _fileName(Headers headers) {
    final raw = headers.value('content-disposition');
    if (raw == null) return null;
    final encoded = RegExp(
      r"filename\*\s*=\s*(?:UTF-8'')?([^;]+)",
      caseSensitive: false,
    ).firstMatch(raw)?.group(1);
    final plain = RegExp(
      r'filename\s*=\s*"?([^";]+)',
      caseSensitive: false,
    ).firstMatch(raw)?.group(1);
    final value = (encoded ?? plain)?.replaceAll('"', '').trim();
    if (value == null || value.isEmpty) return null;
    try {
      return Uri.decodeComponent(value);
    } on FormatException {
      return value;
    }
  }
}
