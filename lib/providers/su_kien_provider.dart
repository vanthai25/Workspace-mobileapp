import 'package:flutter/material.dart';

import '../models/su_kien_model.dart';
import '../services/su_kien_service.dart';

class SuKienProvider
    with ChangeNotifier {
  final SuKienService _service =
      SuKienService();

  bool _isLoading = false;
  bool _isLoadingDangMo = false;
  bool _daLoadDangMo = false;

  List<SuKienModel>
      _suKienDangMo = [];

  List<SuKienDangKyModel>
      _dangKyCuaToi = [];

  bool get isLoading =>
      _isLoading;

  bool get isLoadingDangMo =>
      _isLoadingDangMo;

  bool get daLoadDangMo =>
      _daLoadDangMo;

  List<SuKienModel>
      get suKienDangMo =>
          _suKienDangMo;

  List<SuKienDangKyModel>
      get dangKyCuaToi =>
          _dangKyCuaToi;

  List<SuKienModel>
      get suKienCoTheDangKy =>
          _suKienDangMo
              .where(
                (x) =>
                    !x.daDangKy,
              )
              .toList();

  // =========================================================
  // SỰ KIỆN ĐANG MỞ
  // =========================================================

  Future<void>
      fetchSuKienDangMo() async {
    if (_isLoadingDangMo) {
      return;
    }

    _isLoadingDangMo = true;
    notifyListeners();

    try {
      _suKienDangMo =
          await _service
              .getSuKienDangMo();

      _daLoadDangMo = true;
    } finally {
      _isLoadingDangMo = false;
      notifyListeners();
    }
  }

  // =========================================================
  // ĐĂNG KÝ CỦA TÔI
  // =========================================================

  Future<void>
      fetchDangKyCuaToi() async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _dangKyCuaToi =
          await _service
              .getDangKyCuaToi();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // =========================================================
  // REFRESH NỘI BỘ
  //
  // Không notify giữa chừng.
  // Sau create/update/delete chỉ rebuild 1 lần.
  // =========================================================

  Future<void>
      _reloadAfterChange() async {
    final List<SuKienModel>
        suKien =
        await _service
            .getSuKienDangMo();

    final List<SuKienDangKyModel>
        dangKy =
        await _service
            .getDangKyCuaToi();

    _suKienDangMo =
        suKien;

    _dangKyCuaToi =
        dangKy;

    _daLoadDangMo =
        true;
  }

  // =========================================================
// ĐĂNG KÝ
// =========================================================

Future<bool> dangKy({
  required int masukien,
  bool? coAn,
  int? soLuong,
  String? ghiChu,
}) async {
  if (_isLoading) {
    return false;
  }

  _isLoading = true;
  _isLoadingDangMo = true;

  try {
    final bool success =
        await _service.dangKy(
      masukien: masukien,
      coAn: coAn,
      soLuong: soLuong,
      ghiChu: ghiChu,
    );

    if (!success) {
      return false;
    }

    await _reloadAfterChange();

    return true;
  } finally {
    _isLoading = false;
    _isLoadingDangMo = false;

    // Chỉ rebuild 1 lần cuối.
    notifyListeners();
  }
}


// =========================================================
// SỬA
// =========================================================

Future<bool> updateDangKy(
  int id, {
  bool? coAn,
  int? soLuong,
  String? ghiChu,
}) async {
  if (_isLoading) {
    return false;
  }

  _isLoading = true;
  _isLoadingDangMo = true;

  try {
    final bool success =
        await _service.updateDangKy(
      id,
      coAn: coAn,
      soLuong: soLuong,
      ghiChu: ghiChu,
    );

    if (!success) {
      return false;
    }

    await _reloadAfterChange();

    return true;
  } finally {
    _isLoading = false;
    _isLoadingDangMo = false;

    notifyListeners();
  }
}


// =========================================================
// HỦY
// =========================================================

Future<bool> huyDangKy(
  int id,
) async {
  if (_isLoading) {
    return false;
  }

  _isLoading = true;
  _isLoadingDangMo = true;

  try {
    final bool success =
        await _service.huyDangKy(
      id,
    );

    if (!success) {
      return false;
    }

    await _reloadAfterChange();

    return true;
  } finally {
    _isLoading = false;
    _isLoadingDangMo = false;

    notifyListeners();
  }
}
}