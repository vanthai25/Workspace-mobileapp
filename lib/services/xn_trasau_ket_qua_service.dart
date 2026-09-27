import 'package:dio/dio.dart';
import '../models/xn_trasau_ket_qua.dart';
import '../utils/constants.dart';
import 'api_client.dart';

abstract class XnResultGateway {
  Future<XnRow> configuration(int id, CancelToken token);
  Future<XnRow> result(
    int id,
    XnResultKind kind,
    String template,
    int? form,
    CancelToken token,
  );
  Future<XnRow> signature(int id, CancelToken token);
}

class XnResultService implements XnResultGateway {
  XnResultService({Dio? dio}) : _dio = dio ?? ApiClient().dio;
  final Dio _dio;

  @override
  Future<XnRow> configuration(int id, CancelToken token) =>
      _get('/$id/cau-hinh-ket-qua', token);

  @override
  Future<XnRow> result(
    int id,
    XnResultKind kind,
    String template,
    int? form,
    CancelToken token,
  ) => _get('/$id/ket-qua/${kind.route}', token, {
    'idMauIn': template,
    if (kind == XnResultKind.pathology && form != null) 'idMauKqKhac': form,
  });

  @override
  Future<XnRow> signature(int id, CancelToken token) =>
      _get('/$id/chu-ky', token, {'kemAnh': true});

  Future<XnRow> _get(
    String path,
    CancelToken token, [
    Map<String, dynamic>? query,
  ]) async {
    try {
      final response = await _dio.get<dynamic>(
        '${AppConstants.baseUrl}/XNTraSau$path',
        queryParameters: query,
        cancelToken: token,
        options: Options(receiveTimeout: const Duration(seconds: 180)),
      );
      final body = response.data;
      if (body is! Map || body['success'] != true || body['data'] is! Map) {
        throw const XnResultException(
          'Máy chủ trả dữ liệu kết quả không hợp lệ.',
        );
      }
      return Map<String, dynamic>.from(body['data'] as Map);
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) rethrow;
      final body = error.response?.data;
      if (body is Map) {
        final message = xnText(body['message']);
        if (message.isNotEmpty) {
          throw XnResultException(message, code: xnText(body['code']));
        }
      }
      if (error.response?.statusCode == 401) {
        throw const XnResultException(
          'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
        );
      }
      if (error.response?.statusCode == 403) {
        throw const XnResultException('Bạn không có quyền xem kết quả này.');
      }
      throw const XnResultException(
        'Không tải được kết quả. Kiểm tra kết nối và thử lại.',
      );
    }
  }
}
