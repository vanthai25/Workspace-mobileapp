import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/nhan_vien_mobile_v2_models.dart';
import '../utils/constants.dart';

// ============================================================
// JOB LOAD AVATAR
//
// Avatar không tải ồ ạt cùng lúc.
// Mỗi job sẽ được đưa vào Queue.
// ============================================================

class _AvatarLoadJob {
  final String maSo;
  final int size;

  final Completer<Uint8List?> completer;

  _AvatarLoadJob({
    required this.maSo,
    required this.size,
    required this.completer,
  });
}

class NhanVienMobileV2Service {
  final Dio dio;

  NhanVienMobileV2Service(
    this.dio,
  );

  String get _basePath =>
      '${AppConstants.baseUrl}/v2/NhanVien/mobile';

  // ==========================================================
  // CACHE AVATAR
  //
  // Key:
  //
  // 00001:160
  // 00001:480
  //
  // Vì màn danh sách và màn detail dùng size khác nhau.
  // ==========================================================

  final Map<String, Uint8List> _avatarCache = {};

  // ==========================================================
  // REQUEST ĐANG CHẠY / ĐANG CHỜ
  //
  // Tránh cùng 1 avatar bị request nhiều lần.
  // ==========================================================

  final Map<String, Future<Uint8List?>>
      _avatarRequests = {};

  // ==========================================================
  // NHỮNG NHÂN VIÊN API ĐÃ XÁC NHẬN 404
  //
  // Chỉ cache null khi backend trả đúng 404.
  //
  // Timeout / 500 / mất mạng:
  // KHÔNG cache null.
  // ==========================================================

  final Set<String> _noAvatarCache =
      <String>{};

  // ==========================================================
  // QUEUE AVATAR
  // ==========================================================

  final Queue<_AvatarLoadJob>
      _avatarQueue =
      Queue<_AvatarLoadJob>();

  int _activeAvatarLoads = 0;

  // Chỉ cho tối đa 3 avatar tải cùng lúc.
  static const int _maxConcurrentAvatarLoads =
      3;

  // ==========================================================
  // DANH BẠ
  // ==========================================================

  Future<
      List<
          NhanVienMobileKhoaPhongV2Model>>
      getDanhBa({
    String? keyword,
    int? idKhoaPhong,
  }) async {
    final queryParameters =
        <String, dynamic>{};

    final normalizedKeyword =
        keyword?.trim();

    if (normalizedKeyword != null &&
        normalizedKeyword.isNotEmpty) {
      queryParameters['keyword'] =
          normalizedKeyword;
    }

    if (idKhoaPhong != null) {
      queryParameters['idKhoaPhong'] =
          idKhoaPhong;
    }

    final response =
        await dio.get(
      '$_basePath/danh-ba',
      queryParameters:
          queryParameters,
    );

    final data =
        _extractData(
      response.data,
    );

    if (data is! List) {
      return <
          NhanVienMobileKhoaPhongV2Model>[];
    }

    return data
        .whereType<Map>()
        .map(
          (e) =>
              NhanVienMobileKhoaPhongV2Model
                  .fromJson(
            Map<String, dynamic>.from(
              e,
            ),
          ),
        )
        .toList();
  }

  // ==========================================================
  // DETAIL
  // ==========================================================

  Future<NhanVienMobileDetailV2Model>
      getChiTiet(
    String maSo,
  ) async {
    final normalizedMaSo =
        maSo.trim();

    if (normalizedMaSo.isEmpty) {
      throw Exception(
        'Mã nhân viên không hợp lệ.',
      );
    }

    final response =
        await dio.get(
      '$_basePath/'
      '${Uri.encodeComponent(normalizedMaSo)}',
    );

    final data =
        _extractData(
      response.data,
    );

    if (data is! Map) {
      throw Exception(
        'API không trả về thông tin nhân viên.',
      );
    }

    return NhanVienMobileDetailV2Model
        .fromJson(
      Map<String, dynamic>.from(
        data,
      ),
    );
  }

  // ==========================================================
  // GET AVATAR
  //
  // Danh sách:
  //
  // getAvatar(
  //   '00001',
  //   size: 160,
  // )
  //
  // Detail:
  //
  // getAvatar(
  //   '00001',
  //   size: 480,
  // )
  // ==========================================================

  Future<Uint8List?> getAvatar(
    String maSo, {
    int size = 160,
    bool forceRefresh = false,
  }) async {
    final key =
        maSo.trim();

    if (key.isEmpty) {
      return null;
    }

    // Backend hiện cho 96 -> 600.
    final int normalizedSize;

    if (size < 96) {
      normalizedSize = 96;
    } else if (size > 600) {
      normalizedSize = 600;
    } else {
      normalizedSize = size;
    }

    final cacheKey =
        '$key:$normalizedSize';

    // ========================================================
    // FORCE REFRESH
    // ========================================================

    if (forceRefresh) {
      _avatarCache.remove(
        cacheKey,
      );

      _avatarRequests.remove(
        cacheKey,
      );

      _noAvatarCache.remove(
        key,
      );
    }

    // ========================================================
    // API ĐÃ XÁC NHẬN KHÔNG CÓ AVATAR
    // ========================================================

    if (_noAvatarCache.contains(
      key,
    )) {
      return null;
    }

    // ========================================================
    // CACHE
    // ========================================================

    final cached =
        _avatarCache[
            cacheKey];

    if (cached != null &&
        cached.isNotEmpty) {
      return cached;
    }

    // ========================================================
    // REQUEST ĐANG CHẠY
    //
    // Nếu 2 widget cùng cần avatar này,
    // dùng chung Future.
    // ========================================================

    final existing =
        _avatarRequests[
            cacheKey];

    if (existing != null) {
      return existing;
    }

    // ========================================================
    // ĐƯA VÀO QUEUE
    // ========================================================

    final request =
        _enqueueAvatar(
      key,
      normalizedSize,
    );

    _avatarRequests[
        cacheKey] =
        request;

    try {
      final result =
          await request;

      // ======================================================
      // CHỈ CACHE KHI THỰC SỰ CÓ ẢNH
      //
      // Tuyệt đối không:
      //
      // _avatarCache[key] = null;
      //
      // Vì lỗi mạng tạm thời không được coi là không có ảnh.
      // ======================================================

      if (result != null &&
          result.isNotEmpty) {
        _avatarCache[
            cacheKey] =
            result;
      }

      return result;
    } finally {
      _avatarRequests.remove(
        cacheKey,
      );
    }
  }

  // ==========================================================
  // QUEUE
  // ==========================================================

  Future<Uint8List?> _enqueueAvatar(
    String maSo,
    int size,
  ) {
    final completer =
        Completer<Uint8List?>();

    _avatarQueue.add(
      _AvatarLoadJob(
        maSo: maSo,
        size: size,
        completer:
            completer,
      ),
    );

    _drainAvatarQueue();

    return completer.future;
  }

  // ==========================================================
  // CHẠY QUEUE
  //
  // Ví dụ:
  //
  // 20 avatar đang chờ
  //
  // chỉ:
  //
  // avatar 1
  // avatar 2
  // avatar 3
  //
  // cùng tải.
  //
  // Một cái xong thì lấy job tiếp theo.
  // ==========================================================

  void _drainAvatarQueue() {
    while (
        _activeAvatarLoads <
                _maxConcurrentAvatarLoads &&
            _avatarQueue.isNotEmpty) {
      final job =
          _avatarQueue.removeFirst();

      _activeAvatarLoads++;

      _runAvatarJob(
        job,
      );
    }
  }

  Future<void> _runAvatarJob(
    _AvatarLoadJob job,
  ) async {
    try {
      final result =
          await _loadAvatar(
        job.maSo,
        size: job.size,
      );

      if (!job
          .completer
          .isCompleted) {
        job.completer.complete(
          result,
        );
      }
    } catch (e, stackTrace) {
      debugPrint(
        '[AVATAR-QUEUE] '
        '${job.maSo}: $e\n'
        '$stackTrace',
      );

      if (!job
          .completer
          .isCompleted) {
        job.completer.complete(
          null,
        );
      }
    } finally {
      _activeAvatarLoads--;

      // Có slot trống -> chạy tiếp job sau.
      _drainAvatarQueue();
    }
  }
    Future<
    List<NhanVienMobileKhoaPhongV2Model>>
    getKhoaPhongs() async {
  final response =
      await dio.get(
    '$_basePath/khoa-phong',
  );

  final data =
      _extractData(
    response.data,
  );

  if (data is! List) {
    return <
        NhanVienMobileKhoaPhongV2Model>[];
  }

  return data
      .whereType<Map>()
      .map(
        (e) =>
            NhanVienMobileKhoaPhongV2Model
                .fromJson(
          Map<String, dynamic>.from(
            e,
          ),
        ),
      )
      .toList();
}

  Future<NhanVienMobileTongQuanV2Model>
    getTongQuan() async {
  final response =
      await dio.get(
    '$_basePath/tong-quan',
  );

  final data =
      _extractData(
    response.data,
  );

  if (data is! Map) {
    throw Exception(
      'API không trả về tổng quan nhân sự.',
    );
  }

  return NhanVienMobileTongQuanV2Model
      .fromJson(
    Map<String, dynamic>.from(
      data,
    ),
  );
}
  Future<Uint8List?> _loadAvatar(
    String maSo, {
    required int size,
  }) async {
    const int maxAttempts =
        2;

    for (
      int attempt = 1;
      attempt <= maxAttempts;
      attempt++
    ) {
      try {
        final response =
            await dio.get<dynamic>(
          '$_basePath/'
          '${Uri.encodeComponent(maSo)}'
          '/avatar',

          // Backend sẽ resize thumbnail.
          queryParameters: {
            'size': size,
          },

          options: Options(
            responseType:
                ResponseType.bytes,

            receiveTimeout:
                const Duration(
              seconds: 30,
            ),
          ),
        );

        final data =
            response.data;

        final bytes =
            _toBytes(
          data,
        );

        if (bytes == null ||
            bytes.isEmpty) {
          debugPrint(
            '[AVATAR] '
            '$maSo '
            'size=$size '
            'API trả dữ liệu rỗng.',
          );

          return null;
        }

        debugPrint(
          '[AVATAR] '
          '$maSo '
          'size=$size '
          'OK '
          '${bytes.length} bytes',
        );

        return bytes;
      } on DioException catch (e) {
        final status =
            e.response
                ?.statusCode;

        if (status == 404) {
          _noAvatarCache.add(
            maSo,
          );

          return null;
        }

        debugPrint(
          '[AVATAR] '
          '$maSo '
          'size=$size '
          'attempt=$attempt '
          'status=$status '
          'type=${e.type} '
          'message=${e.message}',
        );

        // Retry nếu chưa hết lượt.
        if (attempt <
            maxAttempts) {
          await Future.delayed(
            const Duration(
              milliseconds: 450,
            ),
          );

          continue;
        }

        return null;
      } catch (e, stackTrace) {
        debugPrint(
          '[AVATAR] '
          '$maSo '
          'size=$size '
          'attempt=$attempt '
          'error=$e\n'
          '$stackTrace',
        );

        if (attempt <
            maxAttempts) {
          await Future.delayed(
            const Duration(
              milliseconds: 450,
            ),
          );

          continue;
        }

        return null;
      }
    }

    return null;
  }

  // ==========================================================
  // CONVERT RESPONSE -> Uint8List
  // ==========================================================

  Uint8List? _toBytes(
    dynamic data,
  ) {
    if (data == null) {
      return null;
    }

    if (data is Uint8List) {
      return data;
    }

    if (data is List<int>) {
      return Uint8List.fromList(
        data,
      );
    }

    if (data is List) {
      final values =
          <int>[];

      for (final item in data) {
        if (item is num) {
          values.add(
            item.toInt(),
          );
        }
      }

      if (values.isEmpty) {
        return null;
      }

      return Uint8List.fromList(
        values,
      );
    }

    return null;
  }

  // ==========================================================
  // XÓA CACHE AVATAR
  //
  // Có thể dùng sau này nếu ảnh nhân viên vừa được sửa.
  // ==========================================================

  void clearAvatarCache({
    String? maSo,
  }) {
    if (maSo == null ||
        maSo.trim().isEmpty) {
      _avatarCache.clear();

      _avatarRequests.clear();

      _noAvatarCache.clear();

      return;
    }

    final key =
        maSo.trim();

    _avatarCache.removeWhere(
      (
        cacheKey,
        _,
      ) =>
          cacheKey.startsWith(
        '$key:',
      ),
    );

    _avatarRequests.removeWhere(
      (
        cacheKey,
        _,
      ) =>
          cacheKey.startsWith(
        '$key:',
      ),
    );

    _noAvatarCache.remove(
      key,
    );
  }

  // ==========================================================
  // API WRAPPER
  // ==========================================================

  dynamic _extractData(
    dynamic responseData,
  ) {
    if (responseData is Map) {
      if (responseData.containsKey(
        'data',
      )) {
        return responseData[
            'data'];
      }

      if (responseData.containsKey(
        'Data',
      )) {
        return responseData[
            'Data'];
      }
    }

    return responseData;
  }
}