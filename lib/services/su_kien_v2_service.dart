import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../models/su_kien_v2_models.dart';
import '../utils/constants.dart';


class SuKienV2Service {
  final Dio dio;

  SuKienV2Service(
    this.dio,
  );


  String get _base =>
      '${AppConstants.baseUrl}/v2/SuKien';


  // =========================================================
  // ADMIN LIST
  // =========================================================

  Future<List<SuKienV2Model>>
      getAdminList() async {
    final response =
        await _request(
      () => dio.get(
        '$_base/admin',
      ),
    );

    final data =
        _map(response.data)['data'];

    if (data is! List) {
      return [];
    }

    return data
        .whereType<Map>()
        .map(
          (e) =>
              SuKienV2Model.fromJson(
            Map<String, dynamic>.from(
              e,
            ),
          ),
        )
        .toList();
  }


  // =========================================================
  // GET DETAIL
  // =========================================================

  Future<SuKienV2Model>
      getById(
    int idSuKien,
  ) async {
    final response =
        await _request(
      () => dio.get(
        '$_base/admin/$idSuKien',
      ),
    );

    return SuKienV2Model.fromJson(
      _map(
        _map(response.data)['data'],
      ),
    );
  }


  // =========================================================
  // CREATE
  // =========================================================

  Future<SuKienV2Model> create(
    Map<String, dynamic> payload,
  ) async {
    final response =
        await _request(
      () => dio.post(
        '$_base/admin',
        data:
            payload,
      ),
    );

    return SuKienV2Model.fromJson(
      _map(
        _map(response.data)['data'],
      ),
    );
  }


  // =========================================================
  // UPDATE
  // =========================================================

  Future<SuKienV2Model> update(
    int idSuKien,
    Map<String, dynamic> payload,
  ) async {
    final response =
        await _request(
      () => dio.put(
        '$_base/admin/$idSuKien',
        data:
            payload,
      ),
    );

    return SuKienV2Model.fromJson(
      _map(
        _map(response.data)['data'],
      ),
    );
  }


  // =========================================================
  // DELETE
  // =========================================================

  Future<void> delete(
    int idSuKien,
  ) async {
    await _request(
      () => dio.delete(
        '$_base/admin/$idSuKien',
      ),
    );
  }


  // =========================================================
  // REQUEST
  // =========================================================

  Future<Response<dynamic>> _request(
    Future<Response<dynamic>>
        Function() call,
  ) async {
    try {
      final response =
          await call();

      final body =
          _map(response.data);

      if (body['success'] == false) {
        throw Exception(
          _errorMessage(body),
        );
      }

      return response;
    } on DioException catch (e) {
      final body =
          _map(e.response?.data);

      if (e.response?.statusCode ==
          403) {
        throw Exception(
          'Bạn không có quyền quản lý sự kiện.',
        );
      }

      throw Exception(
        body.isEmpty
            ? 'Không thể kết nối máy chủ.'
            : _errorMessage(body),
      );
    }
  }


  String _errorMessage(
    Map<String, dynamic> body,
  ) {
    final message =
        body['message']?.toString() ??
        'Yêu cầu không thành công.';

    final errors =
        body['errors'];

    if (errors is! Map) {
      return message;
    }

    final details =
        <String>[];

    for (final value
        in errors.values) {
      if (value is List) {
        details.addAll(
          value.map(
            (e) => e.toString(),
          ),
        );
      } else if (value != null) {
        details.add(
          value.toString(),
        );
      }
    }

    final unique =
        details
            .where(
              (e) =>
                  e.trim().isNotEmpty,
            )
            .toSet();

    return unique.isEmpty
        ? message
        : '$message ${unique.join(' ')}';
  }


  Map<String, dynamic> _map(
    dynamic value,
  ) {
    return value is Map
        ? Map<String, dynamic>.from(
            value,
          )
        : <String, dynamic>{};
  }

Future<SuKienBannerV2Model>
    uploadBanner({
  required int idSuKien,
  required PlatformFile file,
  String? tieuDe,
  String? moTa,
  String? actionType,
  String? actionValue,
  String? buttonText,
  int thuTu = 0,
  bool isActive = true,
}) async {
  if (file.bytes == null ||
      file.bytes!.isEmpty) {
    throw Exception(
      'Không đọc được file ${file.name}.',
    );
  }

  final form =
      FormData();

  form.files.add(
    MapEntry(
      'file',
      MultipartFile.fromBytes(
        file.bytes!,
        filename:
            file.name,
      ),
    ),
  );

  void addField(
    String key,
    dynamic value,
  ) {
    if (value == null) {
      return;
    }

    final text =
        value.toString();

    if (text.trim().isEmpty) {
      return;
    }

    form.fields.add(
      MapEntry(
        key,
        text,
      ),
    );
  }

  addField(
    'tieuDe',
    tieuDe,
  );

  addField(
    'moTa',
    moTa,
  );

  addField(
    'actionType',
    actionType,
  );

  addField(
    'actionValue',
    actionValue,
  );

  addField(
    'buttonText',
    buttonText,
  );

  addField(
    'thuTu',
    thuTu,
  );

  addField(
    'isActive',
    isActive,
  );

  final response =
      await _request(
    () => dio.post(
      '$_base/admin/$idSuKien/banners',
      data:
          form,
    ),
  );

  return SuKienBannerV2Model.fromJson(
    _map(
      _map(response.data)['data'],
    ),
  );
}


// =========================================================
// BANNER - UPDATE
// =========================================================

Future<SuKienBannerV2Model>
    updateBanner({
  required int idSuKien,
  required int idBanner,
  String? tieuDe,
  String? moTa,
  String? actionType,
  String? actionValue,
  String? buttonText,
  int thuTu = 0,
  bool isActive = true,
}) async {
  final response =
      await _request(
    () => dio.put(
      '$_base/admin/'
      '$idSuKien/banners/$idBanner',

      data: {
        'tieuDe':
            _emptyToNull(
          tieuDe,
        ),

        'moTa':
            _emptyToNull(
          moTa,
        ),

        'actionType':
            _emptyToNull(
          actionType,
        ),

        'actionValue':
            _emptyToNull(
          actionValue,
        ),

        'buttonText':
            _emptyToNull(
          buttonText,
        ),

        'thuTu':
            thuTu,

        'isActive':
            isActive,
      },
    ),
  );

  return SuKienBannerV2Model.fromJson(
    _map(
      _map(response.data)['data'],
    ),
  );
}


// =========================================================
// BANNER - DELETE
// =========================================================

Future<void> deleteBanner({
  required int idSuKien,
  required int idBanner,
}) async {
  await _request(
    () => dio.delete(
      '$_base/admin/'
      '$idSuKien/banners/$idBanner',
    ),
  );
}


Future<Uint8List> getBannerImage(
  int idBanner,
) async {
  try {
    final response =
        await dio.get<List<int>>(
      '$_base/banners/$idBanner/image',

      options:
          Options(
        responseType:
            ResponseType.bytes,
      ),
    );

    final bytes =
        response.data ??
        <int>[];

    if (bytes.isEmpty) {
      throw Exception(
        'Ảnh banner không có dữ liệu.',
      );
    }

    return Uint8List.fromList(
      bytes,
    );
  } on DioException catch (e) {
    final body =
        _map(
      e.response?.data,
    );

    throw Exception(
      body.isEmpty
          ? 'Không thể tải ảnh banner.'
          : _errorMessage(body),
    );
  }
}


String? _emptyToNull(
  String? value,
) {
  final text =
      value?.trim() ??
      '';

  return text.isEmpty
      ? null
      : text;
}
}
