import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../models/su_kien_v2_models.dart';
import '../utils/constants.dart';

/// Dữ liệu sự kiện cho Home. Dùng Dio chung của ApiClient để gửi JWT.
class SuKienHomeService {
  SuKienHomeService(this.dio);

  final Dio dio;

  String get _base => '${AppConstants.baseUrl}/v2/SuKien';

  Future<List<SuKienV2Model>> getCurrent() async {
    final response = await dio.get<dynamic>('$_base/current');
    final raw = response.data;
    if (raw is! Map) {
      throw const FormatException('Phản hồi sự kiện không hợp lệ.');
    }

    final body = Map<String, dynamic>.from(raw);
    if (body['success'] == false) {
      throw Exception(body['message']?.toString() ?? 'Không thể tải sự kiện.');
    }

    final data = body['data'];
    if (data is! List) return <SuKienV2Model>[];

    return data
        .whereType<Map>()
        .map((item) =>
            SuKienV2Model.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<Uint8List> getBannerImage(int idBanner) async {
    final response = await dio.get<List<int>>(
      '$_base/banners/$idBanner/image',
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = response.data ?? <int>[];
    if (bytes.isEmpty) {
      throw Exception('Ảnh banner #$idBanner không có dữ liệu.');
    }
    return Uint8List.fromList(bytes);
  }
}
