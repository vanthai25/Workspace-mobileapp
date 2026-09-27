import 'package:dio/dio.dart';

class KhthService {
  final Dio dio;
  final String baseUrl;

  KhthService(
    this.dio,
    this.baseUrl,
  );
  String get logoutUrl {
    final uri =
        Uri.parse(baseUrl);

    return Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.hasPort
          ? uri.port
          : null,
      path: '/khth/logout',
    ).toString();
  }
  Future<String> getOpenUrl() async {
    final response = await dio.post(
      '$baseUrl/v2/KhthAccess/open-ticket',
    );

    final body = response.data;

    if (body is! Map) {
      throw Exception(
        'Phản hồi từ máy chủ không hợp lệ.',
      );
    }

    final success =
        body['success'] == true;

    if (!success) {
      throw Exception(
        body['message']?.toString() ??
            'Không thể mở Kế hoạch tổng hợp.',
      );
    }

    final data = body['data'];

    if (data is! Map) {
      throw Exception(
        'Máy chủ không trả về thông tin truy cập.',
      );
    }

    final url =
        data['url']?.toString().trim() ?? '';

    if (url.isEmpty) {
      throw Exception(
        'Máy chủ không trả về đường dẫn Kế hoạch tổng hợp.',
      );
    }

    return url;
  }
  
}