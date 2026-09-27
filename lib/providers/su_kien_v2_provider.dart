import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../models/su_kien_v2_models.dart';
import '../services/su_kien_v2_service.dart';
import '../services/su_kien_changes.dart';


class SuKienV2Provider
    extends ChangeNotifier {
  final SuKienV2Service service;

  SuKienV2Provider(
    this.service,
  );


  List<SuKienV2Model> items =
      [];

  bool isLoading =
      false;

  bool isSaving =
      false;

  int? deletingId;

  String? errorMessage;

  bool isSavingBanner =
    false;

  int? deletingBannerId;

  String? bannerErrorMessage;

  final Map<int, Uint8List>
      _bannerImageCache = {};

  Future<void> load() async {
    if (isLoading) {
      return;
    }

    isLoading =
        true;

    errorMessage =
        null;

    notifyListeners();

    try {
      items =
          await service
              .getAdminList();
    } catch (e) {
      errorMessage =
          _error(e);
    } finally {
      isLoading =
          false;

      notifyListeners();
    }
  }


  // =========================================================
  // CREATE
  // =========================================================

  Future<bool> create(
    Map<String, dynamic> payload,
  ) async {
    if (isSaving) {
      return false;
    }

    isSaving =
        true;

    errorMessage =
        null;

    notifyListeners();

    try {
      final created =
          await service.create(
        payload,
      );

      SuKienChanges.notifyChanged();

      items.insert(
        0,
        created,
      );

      _sort();

      return true;
    } catch (e) {
      errorMessage =
          _error(e);

      return false;
    } finally {
      isSaving =
          false;

      notifyListeners();
    }
  }


  // =========================================================
  // UPDATE
  // =========================================================

  Future<bool> update(
    int idSuKien,
    Map<String, dynamic> payload,
  ) async {
    if (isSaving) {
      return false;
    }

    isSaving =
        true;

    errorMessage =
        null;

    notifyListeners();

    try {
      final updated =
          await service.update(
        idSuKien,
        payload,
      );

      SuKienChanges.notifyChanged();

      final index =
          items.indexWhere(
        (x) =>
            x.idSuKien ==
            idSuKien,
      );

      if (index >= 0) {
        items[index] =
            updated;
      }

      _sort();

      return true;
    } catch (e) {
      errorMessage =
          _error(e);

      return false;
    } finally {
      isSaving =
          false;

      notifyListeners();
    }
  }


  // =========================================================
  // DELETE
  // =========================================================

  Future<bool> delete(
    int idSuKien,
  ) async {
    if (deletingId != null) {
      return false;
    }

    deletingId =
        idSuKien;

    errorMessage =
        null;

    notifyListeners();

    try {
      await service.delete(
        idSuKien,
      );

      SuKienChanges.notifyChanged();

      items.removeWhere(
        (x) =>
            x.idSuKien ==
            idSuKien,
      );

      return true;
    } catch (e) {
      errorMessage =
          _error(e);

      return false;
    } finally {
      deletingId =
          null;

      notifyListeners();
    }
  }


  void _sort() {
    items.sort(
      (a, b) {
        final priority =
            b.mucUuTien.compareTo(
          a.mucUuTien,
        );

        if (priority != 0) {
          return priority;
        }

        return b.idSuKien.compareTo(
          a.idSuKien,
        );
      },
    );
  }
  Future<Uint8List?>
    loadBannerImage(
  int idBanner, {
  bool force = false,
}) async {
  if (!force &&
      _bannerImageCache
          .containsKey(
        idBanner,
      )) {
    return _bannerImageCache[
        idBanner];
  }

  try {
    final bytes =
        await service
            .getBannerImage(
      idBanner,
    );

    _bannerImageCache[
        idBanner] = bytes;

    return bytes;
  } catch (e) {
    bannerErrorMessage =
        _error(e);

    return null;
  }
}

Future<bool> uploadBanner({
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
  if (isSavingBanner) {
    return false;
  }

  isSavingBanner =
      true;

  bannerErrorMessage =
      null;

  notifyListeners();

  try {
    final created =
        await service
            .uploadBanner(
      idSuKien:
          idSuKien,

      file:
          file,

      tieuDe:
          tieuDe,

      moTa:
          moTa,

      actionType:
          actionType,

      actionValue:
          actionValue,

      buttonText:
          buttonText,

      thuTu:
          thuTu,

      isActive:
          isActive,
    );

    // Xóa cache nếu tình cờ trùng id.
    _bannerImageCache.remove(
      created.idBanner,
    );

    SuKienChanges.notifyChanged();
    await _refreshEvent(
      idSuKien,
    );

    return true;
  } catch (e) {
    bannerErrorMessage =
        _error(e);

    return false;
  } finally {
    isSavingBanner =
        false;

    notifyListeners();
  }
}


// =========================================================
// BANNER UPDATE
// =========================================================

Future<bool> updateBanner({
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
  if (isSavingBanner) {
    return false;
  }

  isSavingBanner =
      true;

  bannerErrorMessage =
      null;

  notifyListeners();

  try {
    await service
        .updateBanner(
      idSuKien:
          idSuKien,

      idBanner:
          idBanner,

      tieuDe:
          tieuDe,

      moTa:
          moTa,

      actionType:
          actionType,

      actionValue:
          actionValue,

      buttonText:
          buttonText,

      thuTu:
          thuTu,

      isActive:
          isActive,
    );

    SuKienChanges.notifyChanged();
    await _refreshEvent(
      idSuKien,
    );

    return true;
  } catch (e) {
    bannerErrorMessage =
        _error(e);

    return false;
  } finally {
    isSavingBanner =
        false;

    notifyListeners();
  }
}


// =========================================================
// BANNER DELETE
// =========================================================

Future<bool> deleteBanner({
  required int idSuKien,
  required int idBanner,
}) async {
  if (deletingBannerId !=
      null) {
    return false;
  }

  deletingBannerId =
      idBanner;

  bannerErrorMessage =
      null;

  notifyListeners();

  try {
    await service
        .deleteBanner(
      idSuKien:
          idSuKien,

      idBanner:
          idBanner,
    );

    _bannerImageCache.remove(
      idBanner,
    );

    SuKienChanges.notifyChanged();
    await _refreshEvent(
      idSuKien,
    );

    return true;
  } catch (e) {
    bannerErrorMessage =
        _error(e);

    return false;
  } finally {
    deletingBannerId =
        null;

    notifyListeners();
  }
}


// =========================================================
// REFRESH 1 EVENT
// =========================================================

Future<void> _refreshEvent(
  int idSuKien,
) async {
  final updated =
      await service.getById(
    idSuKien,
  );

  final index =
      items.indexWhere(
    (x) =>
        x.idSuKien ==
        idSuKien,
  );

  if (index >= 0) {
    items[index] =
        updated;
  } else {
    items.add(
      updated,
    );
  }

  _sort();
}

  String _error(
    Object error,
  ) {
    return error
        .toString()
        .replaceFirst(
          RegExp(
            r'^Exception:\s*',
          ),
          '',
        );
  }
}