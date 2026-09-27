import 'package:flutter/material.dart';

import '../models/cham_cong_phep_model.dart';
import '../services/cham_cong_phep_service.dart';

class ChamCongPhepProvider
    with ChangeNotifier {
  final ChamCongPhepService _service =
      ChamCongPhepService();

  bool _isLoading = false;
  bool _isLoadingQuyen = true;
  bool _isManager = false;
  bool _hasCheckedQuyen = false;

  bool get isLoading =>
      _isLoading;

  bool get isLoadingQuyen =>
      _isLoadingQuyen;

  bool get isManager =>
      _isManager;

  List<ChamCongPhepPhieuNghiResponseDto>
      _lichSuList = [];

  List<ChamCongPhepPhieuNghiResponseDto>
      get lichSuList =>
          _lichSuList;

  List<ChamCongPhepKyHieuResponseDto>
      _listKyHieu = [];

  List<ChamCongPhepKyHieuResponseDto>
      get listKyHieu =>
          _listKyHieu;

  List<ChamCongPhepNguoiDuyetResponseDto>
      _listNguoiDuyet = [];

  List<ChamCongPhepNguoiDuyetResponseDto>
      get listNguoiDuyet =>
          _listNguoiDuyet;

  List<ChamCongPhepPhieuNghiResponseDto>
      _choDuyetList = [];

  List<ChamCongPhepPhieuNghiResponseDto>
      get choDuyetList =>
          _choDuyetList;

  // =========================================================
  // LOADING
  // =========================================================

  void setLoading(
    bool value,
  ) {
    if (_isLoading == value) {
      return;
    }

    _isLoading =
        value;

    notifyListeners();
  }

  // =========================================================
  // DANH MỤC
  //
  // Ký hiệu + người duyệt
  // =========================================================

  Future<void> fetchDanhMuc() async {
    setLoading(true);

    try {
      final listKyHieu =
          await _service
              .getDanhSachKyHieu();

      final listNguoiDuyet =
          await _service
              .getDanhSachNguoiDuyet();

      _listKyHieu =
          listKyHieu;

      _listNguoiDuyet =
          listNguoiDuyet;
    } catch (e) {
      debugPrint(
        '❌ Lỗi tải danh mục: $e',
      );
    } finally {
      setLoading(false);
    }
  }

  // =========================================================
  // CHECK QUYỀN DUYỆT
  // =========================================================

  Future<void> checkManagerRole()
      async {
    if (_hasCheckedQuyen) {
      return;
    }

    _isLoadingQuyen =
        true;

    try {
      _isManager =
          await _service
              .checkQuyenDuyet();

      _hasCheckedQuyen =
          true;
    } catch (e) {
      debugPrint(
        '❌ Lỗi khi check quyền: $e',
      );

      _isManager =
          false;
    } finally {
      _isLoadingQuyen =
          false;

      notifyListeners();
    }
  }

  // =========================================================
  // LỊCH SỬ
  // =========================================================

  Future<void> fetchLichSu({
    String? fromDate,
    String? toDate,
  }) async {
    setLoading(true);

    try {
      _lichSuList =
          await _service
              .getLichSuXinNghi(
        fromDate:
            fromDate,
        toDate:
            toDate,
      );
    } catch (e) {
      debugPrint(
        '❌ Lỗi tải lịch sử: $e',
      );
    } finally {
      setLoading(false);
    }
  }

  // =========================================================
  // GỬI ĐƠN CŨ
  //
  // GIỮ CHO CODE CŨ NẾU CÒN CHỖ NÀO DÙNG.
  // =========================================================

  Future<String?> submitDonXinPhep(
    ChamCongPhepCreateRequestDto request,
  ) async {
    setLoading(true);

    try {
      final String? errorMessage =
          await _service
              .taoDonXinPhep(
        request,
      );

      if (errorMessage == null) {
        _lichSuList =
            await _service
                .getLichSuXinNghi();
      }

      return errorMessage;
    } finally {
      setLoading(false);
    }
  }

  // =========================================================
  // GỬI ĐƠN V2
  //
  // MÀN TẠO ĐƠN MỚI SẼ GỌI HÀM NÀY.
  // =========================================================

  Future<String?>
      submitDonXinPhepV2(
    ChamCongPhepCreateRequestDto request,
  ) async {
    setLoading(true);

    try {
      final String? errorMessage =
          await _service
              .taoDonXinPhepV2(
        request,
      );

      if (errorMessage == null) {
        // Reload lịch sử nhưng không gọi fetchLichSu()
        // để tránh loading lồng nhau.
        _lichSuList =
            await _service
                .getLichSuXinNghi();
      }

      return errorMessage;
    } catch (e) {
      debugPrint(
        '❌ Lỗi gửi đơn V2: $e',
      );

      return 'Có lỗi xảy ra khi gửi đơn.';
    } finally {
      setLoading(false);
    }
  }

  // =========================================================
  // SỬA ĐƠN V2
  // =========================================================

  Future<String?>
      updateDonXinPhepV2(
    String ngayLap,
    ChamCongPhepCreateRequestDto request,
  ) async {
    setLoading(true);

    try {
      final String? errorMessage =
          await _service
              .suaDonXinPhepV2(
        ngayLap,
        request,
      );

      if (errorMessage == null) {
        _lichSuList =
            await _service
                .getLichSuXinNghi();
      }

      return errorMessage;
    } catch (e) {
      debugPrint(
        '❌ Lỗi cập nhật đơn V2: $e',
      );

      return 'Có lỗi xảy ra khi cập nhật đơn.';
    } finally {
      setLoading(false);
    }
  }

  // =========================================================
  // XÓA
  // =========================================================

  Future<bool> xoaDon(
    String ngayLap,
  ) async {
    setLoading(true);

    try {
      final bool success =
          await _service
              .xoaDonXinPhep(
        ngayLap,
      );

      if (success) {
        _lichSuList.removeWhere(
          (e) =>
              e.ngayLap
                  .toIso8601String() ==
              ngayLap,
        );
      }

      return success;
    } finally {
      setLoading(false);
    }
  }

  // =========================================================
  // DANH SÁCH CHỜ DUYỆT
  // =========================================================

  Future<void>
      fetchDanhSachChoDuyet({
    String? fromDate,
    String? toDate,
    int? trangThai,
    String? searchKeyword,
  }) async {
    setLoading(true);

    try {
      _choDuyetList =
          await _service
              .getDanhSachChoDuyet(
        fromDate:
            fromDate,
        toDate:
            toDate,
        trangThai:
            trangThai,
        searchKeyword:
            searchKeyword,
      );
    } catch (e) {
      debugPrint(
        '❌ Lỗi tải danh sách chờ duyệt: $e',
      );
    } finally {
      setLoading(false);
    }
  }

  // =========================================================
  // DUYỆT / TỪ CHỐI
  // =========================================================

  Future<bool> xuLyDuyetDon(
    String ngayLap,
    String manvXin,
    int trangThai,
    String? noiDung,
  ) async {
    setLoading(true);

    try {
      final requestDto =
          ChamCongPhepRequestDto(
        ngayLap:
            DateTime.parse(
          ngayLap,
        ),
        manvXin:
            manvXin,
        trangThai:
            trangThai,
        noiDungDuyet:
            noiDung,
      );

      final String? error =
          await _service
              .xuLyDon(
        requestDto,
      );

      if (error == null) {
        _choDuyetList =
            await _service
                .getDanhSachChoDuyet();

        return true;
      }

      return false;
    } catch (e) {
      debugPrint(
        '❌ Lỗi xử lý duyệt đơn: $e',
      );

      return false;
    } finally {
      setLoading(false);
    }
  }

  // =========================================================
  // HỦY DUYỆT
  // =========================================================

  Future<bool> huyDuyetDon(
    String ngayLap,
    String manvXin,
  ) async {
    try {
      final errorMsg =
          await _service
              .huyDuyetDon(
        ngayLap,
        manvXin,
      );

      if (errorMsg == null) {
        return true;
      }

      debugPrint(
        'Lỗi server trả về: $errorMsg',
      );

      return false;
    } catch (e) {
      debugPrint(
        '❌ Lỗi provider Hủy duyệt: $e',
      );

      return false;
    }
  }
}