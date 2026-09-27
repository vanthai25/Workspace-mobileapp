import 'package:flutter/material.dart';

import '../models/cham_truc_model.dart';
import '../services/cham_truc_service.dart';

class ChamTrucProvider
    with ChangeNotifier {
  final ChamTrucService _service =
      ChamTrucService();

  List<ChamTrucModel> _items = [];

  DateTime _selectedDate =
      DateTime.now();

  String? _selectedCoSo;

  String _searchText = '';

  bool _isLoading = false;

  String? _errorMessage;
  String? _selectedMaKhoa;

  String? get selectedMaKhoa =>
      _selectedMaKhoa;
  int _requestVersion = 0;

  // =========================================================
  // GETTERS
  // =========================================================

  List<ChamTrucModel>
      get items =>
          List.unmodifiable(
            _items,
          );

  DateTime get selectedDate =>
      _selectedDate;

  String? get selectedCoSo =>
      _selectedCoSo;

  bool get isLoading =>
      _isLoading;

  String? get errorMessage =>
      _errorMessage;

  String get searchText =>
      _searchText;

  // =========================================================
  // FILTER SEARCH
  // =========================================================

  List<ChamTrucModel> get filteredItems {
    final String keyword =
        _searchText.trim().toLowerCase();

    return _items.where((item) {
      // ==========================
      // 1. FILTER KHOA
      // ==========================
      if (_selectedMaKhoa != null &&
          _selectedMaKhoa!
              .trim()
              .isNotEmpty) {
        final String maKhoaItem =
            item.makhoa
                    ?.trim()
                    .toLowerCase() ??
                '';

        final String maKhoaSelected =
            _selectedMaKhoa!
                .trim()
                .toLowerCase();

        if (maKhoaItem !=
            maKhoaSelected) {
          return false;
        }
      }

      // ==========================
      // 2. TÌM MÃ NV / TÊN NV
      // ==========================
      if (keyword.isNotEmpty) {
        final String manv =
            item.manv
                .trim()
                .toLowerCase();

        final String tennv =
            item.tennv
                    ?.trim()
                    .toLowerCase() ??
                '';

        if (!manv.contains(keyword) &&
            !tennv.contains(keyword)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // =========================================================
  // FETCH
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
      final result =
          await _service.getDanhSach(
        ngay: _selectedDate,
        coSo: _selectedCoSo,
      );

      if (requestId !=
          _requestVersion) {
        return;
      }

      _items = result;
    } on ChamTrucApiException
        catch (e) {
      if (requestId !=
          _requestVersion) {
        return;
      }

      _items = [];

      _errorMessage =
          e.message;
    } catch (e) {
      if (requestId !=
          _requestVersion) {
        return;
      }

      _items = [];

      _errorMessage =
          'Không thể tải danh sách trực.';
    } finally {
      if (requestId ==
          _requestVersion) {
        _isLoading = false;

        notifyListeners();
      }
    }
  }

  Future<void> refresh() {
    return fetchData(
      showLoading: false,
    );
  }

  // =========================================================
  // DATE
  // =========================================================

  Future<void> changeDate(
    int offset,
  ) async {
    _selectedDate =
        DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day + offset,
    );

    await fetchData();
  }

  Future<void> selectDate(
    DateTime date,
  ) async {
    final DateTime target =
        DateTime(
      date.year,
      date.month,
      date.day,
    );

    if (target.year ==
            _selectedDate.year &&
        target.month ==
            _selectedDate.month &&
        target.day ==
            _selectedDate.day) {
      return;
    }

    _selectedDate = target;

    await fetchData();
  }
  List<Map<String, String>> get danhSachKhoa {
    final Map<String, String> map = {};

    for (final item in _items) {
      final String ma =
          item.makhoa?.trim() ?? '';

      final String ten =
          item.tenkhoa?.trim() ?? '';

      if (ma.isNotEmpty) {
        map[ma] = ten.isEmpty
            ? ma
            : ten;
      }
    }

    final result = map.entries.map((e) {
      return {
        'makhoa': e.key,
        'tenkhoa': e.value,
      };
    }).toList();

    result.sort(
      (a, b) =>
          (a['tenkhoa'] ?? '')
              .compareTo(
        b['tenkhoa'] ?? '',
      ),
    );

    return result;
  }
  // =========================================================
  // CƠ SỞ
  // =========================================================

  Future<void> selectCoSo(
    String? value,
  ) async {
    if (_selectedCoSo == value) {
      return;
    }

    _selectedCoSo = value;

    // Đổi cơ sở thì bỏ lựa chọn khoa cũ.
    _selectedMaKhoa = null;

    await fetchData();
  }

  // =========================================================
  // SEARCH
  // =========================================================

  void setSearchText(
    String value,
  ) {
    _searchText = value;

    notifyListeners();
  }
  void selectKhoa(String? maKhoa) {
    _selectedMaKhoa = maKhoa;
    notifyListeners();
  }
}