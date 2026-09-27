import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/bao_com_lech_model.dart';
import '../services/bao_com_lech_service.dart';

class BaoComLechProvider
    with ChangeNotifier {
  final BaoComLechService _service =
      BaoComLechService();

  List<BaoComLechModel> _items = [];

  bool _isLoading = false;

  bool _isProcessing = false;

  String? _errorMessage;

  int _selectedMonth =
      DateTime.now().month;

  int _selectedYear =
      DateTime.now().year;

  int _requestVersion = 0;

  // =========================================================
  // GETTERS
  // =========================================================

  List<BaoComLechModel>
      get items =>
          List.unmodifiable(
            _items,
          );

  bool get isLoading =>
      _isLoading;

  bool get isProcessing =>
      _isProcessing;

  String? get errorMessage =>
      _errorMessage;

  int get selectedMonth =>
      _selectedMonth;

  int get selectedYear =>
      _selectedYear;

  bool get canGoNext {
    final DateTime now =
        DateTime.now();

    final DateTime selected =
        DateTime(
      _selectedYear,
      _selectedMonth,
      1,
    );

    final DateTime current =
        DateTime(
      now.year,
      now.month,
      1,
    );

    return selected.isBefore(
      current,
    );
  }

  // =========================================================
  // LOAD
  // =========================================================

  Future<void> fetchData({
    bool showLoading = true,
  }) async {
    final int requestId =
        ++_requestVersion;

    if (showLoading) {
      _isLoading = true;
    }

    _errorMessage = null;

    notifyListeners();

    try {
      final List<BaoComLechModel>
          result =
          await _service.getDanhSach(
        thang: _selectedMonth,
        nam: _selectedYear,
      );

      if (requestId !=
          _requestVersion) {
        return;
      }

      _items = result;
    } on BaoComLechApiException
        catch (e) {
      if (requestId !=
          _requestVersion) {
        return;
      }

      _items = [];
      _errorMessage = e.message;
    } catch (_) {
      if (requestId !=
          _requestVersion) {
        return;
      }

      _items = [];

      _errorMessage =
          'Không thể tải dữ liệu lệch cơm.';
    } finally {
      if (requestId ==
          _requestVersion) {
        _isLoading = false;

        notifyListeners();
      }
    }
  }

  Future<void> refresh() async {
    await fetchData(
      showLoading: false,
    );
  }

  // =========================================================
  // ĐỔI THÁNG
  // =========================================================

  Future<void> changeMonth(
    int offset,
  ) async {
    final DateTime target =
        DateTime(
      _selectedYear,
      _selectedMonth + offset,
      1,
    );

    final DateTime now =
        DateTime.now();

    final DateTime currentMonth =
        DateTime(
      now.year,
      now.month,
      1,
    );

    if (target.isAfter(
      currentMonth,
    )) {
      return;
    }

    _selectedMonth =
        target.month;

    _selectedYear =
        target.year;

    _items = [];
    _errorMessage = null;

    notifyListeners();

    await fetchData();
  }

  Future<void> selectMonthYear(
    DateTime date,
  ) async {
    final DateTime target =
        DateTime(
      date.year,
      date.month,
      1,
    );

    final DateTime now =
        DateTime.now();

    final DateTime current =
        DateTime(
      now.year,
      now.month,
      1,
    );

    if (target.isAfter(
      current,
    )) {
      return;
    }

    if (target.month ==
            _selectedMonth &&
        target.year ==
            _selectedYear) {
      return;
    }

    _selectedMonth =
        target.month;

    _selectedYear =
        target.year;

    _items = [];
    _errorMessage = null;

    notifyListeners();

    await fetchData();
  }

  // =========================================================
  // PHẢN HỒI / SỬA
  // =========================================================

  Future<bool> savePhanHoi({
    required int id,
    required String noiDung,
    String? hinhAnhPath,
    bool xoaHinhAnh = false,
  }) async {
    _isProcessing = true;
    _errorMessage = null;

    notifyListeners();

    try {
      await _service.phanHoi(
        id: id,
        noiDung: noiDung,
        hinhAnhPath:
            hinhAnhPath,
        xoaHinhAnh:
            xoaHinhAnh,
      );

      await fetchData(
        showLoading: false,
      );

      return true;
    } on BaoComLechApiException
        catch (e) {
      _errorMessage =
          e.message;

      return false;
    } catch (_) {
      _errorMessage =
          'Không thể gửi phản hồi.';

      return false;
    } finally {
      _isProcessing = false;

      notifyListeners();
    }
  }

  // =========================================================
  // XÓA
  // =========================================================

  Future<bool> deletePhanHoi(
    int id,
  ) async {
    _isProcessing = true;
    _errorMessage = null;

    notifyListeners();

    try {
      await _service
          .xoaPhanHoi(
        id,
      );

      await fetchData(
        showLoading: false,
      );

      return true;
    } on BaoComLechApiException
        catch (e) {
      _errorMessage =
          e.message;

      return false;
    } catch (_) {
      _errorMessage =
          'Không thể xóa phản hồi.';

      return false;
    } finally {
      _isProcessing = false;

      notifyListeners();
    }
  }

  // =========================================================
  // ẢNH
  // =========================================================

  Future<Uint8List?>
      getHinhAnh(
    int id,
  ) {
    return _service
        .getHinhAnh(
      id,
    );
  }

  void clear() {
    _requestVersion++;

    _items = [];
    _errorMessage = null;
    _isLoading = false;
    _isProcessing = false;

    final DateTime now =
        DateTime.now();

    _selectedMonth =
        now.month;

    _selectedYear =
        now.year;

    notifyListeners();
  }
}