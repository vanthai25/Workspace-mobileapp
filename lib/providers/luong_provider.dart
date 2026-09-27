import 'package:flutter/material.dart';

import '../models/luong_model.dart';
import '../services/luong_service.dart';

class LuongProvider with ChangeNotifier {
  final LuongService _service = LuongService();

  // =========================================================
  // DỮ LIỆU
  // =========================================================

  /// Bảng lương của tháng đang chọn.
  LuongThangModel? _data;

  /// Dữ liệu thực lĩnh 12 tháng của năm đang chọn.
  List<LuongThucLinhThangModel> _thongKeNam = [];

  // =========================================================
  // TRẠNG THÁI
  // =========================================================

  bool _isLoading = false;

  bool _isLoadingThongKe = false;

  String? _errorMessage;

  String? _thongKeErrorMessage;

  // =========================================================
  // THÁNG / NĂM ĐANG CHỌN
  // =========================================================

  int _selectedMonth = DateTime.now().month;

  int _selectedYear = DateTime.now().year;

  // =========================================================
  // CHỐNG REQUEST CŨ GHI ĐÈ REQUEST MỚI
  // =========================================================

  int _salaryRequestVersion = 0;

  int _chartRequestVersion = 0;

  // =========================================================
  // GETTERS
  // =========================================================

  LuongThangModel? get data => _data;

  List<LuongThucLinhThangModel>
      get thongKeNam => _thongKeNam;

  bool get isLoading => _isLoading;

  bool get isLoadingThongKe =>
      _isLoadingThongKe;

  String? get errorMessage =>
      _errorMessage;

  String? get thongKeErrorMessage =>
      _thongKeErrorMessage;

  int get selectedMonth =>
      _selectedMonth;

  int get selectedYear =>
      _selectedYear;

  DateTime get selectedDate =>
      DateTime(
        _selectedYear,
        _selectedMonth,
        1,
      );

  bool get hasData => _data != null;

  bool get hasThongKe =>
      _thongKeNam.isNotEmpty;

  /// Có cho phép chuyển sang tháng tiếp theo hay không.
  /// Không cho xem tháng tương lai.
  bool get canGoNext {
    final DateTime now =
        DateTime.now();

    final DateTime currentMonth =
        DateTime(
      now.year,
      now.month,
      1,
    );

    final DateTime selectedMonth =
        DateTime(
      _selectedYear,
      _selectedMonth,
      1,
    );

    return selectedMonth.isBefore(
      currentMonth,
    );
  }

  // =========================================================
  // LOAD TOÀN BỘ
  // =========================================================

  /// Dùng khi mở màn hình lương lần đầu.
  ///
  /// Load đồng thời:
  /// - Bảng lương tháng hiện tại.
  /// - Biểu đồ thực lĩnh 12 tháng.
  Future<void> fetchAll() async {
    await Future.wait([
      fetchLuong(),
      fetchThongKeNam(),
    ]);
  }

  // =========================================================
  // LOAD BẢNG LƯƠNG THÁNG
  // =========================================================

  Future<void> fetchLuong({
    bool showLoading = true,
  }) async {
    final int requestId =
        ++_salaryRequestVersion;

    if (showLoading) {
      _isLoading = true;
    }

    _errorMessage = null;

    notifyListeners();

    try {
      final LuongThangModel? result =
          await _service.getLuongThang(
        thang: _selectedMonth,
        nam: _selectedYear,
      );

      /*
       * Nếu trong lúc request đang chạy,
       * người dùng đã chọn tháng khác
       * thì bỏ kết quả request cũ.
       */
      if (requestId !=
          _salaryRequestVersion) {
        return;
      }

      /*
       * result == null:
       * tháng đó chưa có bảng lương.
       *
       * Đây KHÔNG phải lỗi.
       */
      _data = result;
    } on LuongApiException catch (e) {
      if (requestId !=
          _salaryRequestVersion) {
        return;
      }

      _data = null;
      _errorMessage = e.message;
    } catch (e) {
      if (requestId !=
          _salaryRequestVersion) {
        return;
      }

      _data = null;

      _errorMessage =
          'Không thể tải dữ liệu lương. '
          'Vui lòng thử lại.';
    } finally {
      if (requestId ==
          _salaryRequestVersion) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  // =========================================================
  // LOAD BIỂU ĐỒ 12 THÁNG
  // =========================================================

  Future<void> fetchThongKeNam({
    bool showLoading = true,
  }) async {
    final int requestId =
        ++_chartRequestVersion;

    /*
     * Giữ lại năm tại thời điểm bắt đầu request.
     * Nếu sau đó người dùng đổi sang năm khác
     * thì không dùng kết quả cũ.
     */
    final int requestYear =
        _selectedYear;

    if (showLoading) {
      _isLoadingThongKe = true;
    }

    _thongKeErrorMessage = null;

    notifyListeners();

    try {
      final List<
              LuongThucLinhThangModel>
          result =
          await _service
              .getThucLinhTheoNam(
        nam: requestYear,
      );

      if (requestId !=
          _chartRequestVersion) {
        return;
      }

      if (requestYear !=
          _selectedYear) {
        return;
      }

      /*
       * Sắp xếp T1 -> T12 cho chắc chắn.
       */
      result.sort(
        (
          LuongThucLinhThangModel a,
          LuongThucLinhThangModel b,
        ) =>
            a.thang.compareTo(
          b.thang,
        ),
      );

      _thongKeNam = result;
    } on LuongApiException catch (e) {
      if (requestId !=
          _chartRequestVersion) {
        return;
      }

      _thongKeNam = [];
      _thongKeErrorMessage =
          e.message;
    } catch (e) {
      if (requestId !=
          _chartRequestVersion) {
        return;
      }

      _thongKeNam = [];

      _thongKeErrorMessage =
          'Không thể tải thống kê '
          'lương năm $_selectedYear.';
    } finally {
      if (requestId ==
          _chartRequestVersion) {
        _isLoadingThongKe = false;
        notifyListeners();
      }
    }
  }

  // =========================================================
  // REFRESH
  // =========================================================

  /// Kéo xuống refresh:
  /// tải lại cả bảng lương tháng
  /// và biểu đồ năm.
  Future<void> refresh() async {
    await Future.wait([
      fetchLuong(
        showLoading: false,
      ),
      fetchThongKeNam(
        showLoading: false,
      ),
    ]);
  }

  // =========================================================
  // CHUYỂN THÁNG TRƯỚC / SAU
  // =========================================================

  Future<void> changeMonth(
    int offset,
  ) async {
    if (offset == 0) {
      return;
    }

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

    /*
     * Không cho chuyển sang tương lai.
     */
    if (target.isAfter(
      currentMonth,
    )) {
      return;
    }

    final int oldYear =
        _selectedYear;

    _selectedMonth =
        target.month;

    _selectedYear =
        target.year;

    /*
     * Xóa dữ liệu tháng cũ
     * để không hiển thị nhầm trong lúc tải.
     */
    _data = null;
    _errorMessage = null;

    /*
     * Nếu chuyển qua năm khác:
     * xóa biểu đồ năm cũ.
     */
    final bool yearChanged =
        oldYear != _selectedYear;

    if (yearChanged) {
      _thongKeNam = [];
      _thongKeErrorMessage = null;
    }

    notifyListeners();

    if (yearChanged) {
      /*
       * Ví dụ:
       * 01/2026 -> bấm trái -> 12/2025
       *
       * Khi đó cần load lại:
       * - Lương 12/2025
       * - Biểu đồ năm 2025
       */
      await Future.wait([
        fetchLuong(),
        fetchThongKeNam(),
      ]);
    } else {
      /*
       * Chỉ đổi tháng trong cùng năm
       * thì biểu đồ 12 tháng không cần gọi lại API.
       *
       * UI chỉ thay cột được highlight.
       */
      await fetchLuong();
    }
  }

  // =========================================================
  // CHỌN THÁNG / NĂM TỪ PICKER
  // =========================================================

  Future<void> selectMonthYear(
    DateTime date,
  ) async {
    final DateTime normalized =
        DateTime(
      date.year,
      date.month,
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

    /*
     * Không cho chọn tháng tương lai.
     */
    if (normalized.isAfter(
      currentMonth,
    )) {
      return;
    }

    /*
     * Chọn lại đúng tháng đang xem
     * thì không gọi API lại.
     */
    if (_selectedMonth ==
            normalized.month &&
        _selectedYear ==
            normalized.year) {
      return;
    }

    final int oldYear =
        _selectedYear;

    _selectedMonth =
        normalized.month;

    _selectedYear =
        normalized.year;

    _data = null;
    _errorMessage = null;

    final bool yearChanged =
        oldYear != _selectedYear;

    if (yearChanged) {
      _thongKeNam = [];
      _thongKeErrorMessage = null;
    }

    notifyListeners();

    if (yearChanged) {
      await Future.wait([
        fetchLuong(),
        fetchThongKeNam(),
      ]);
    } else {
      await fetchLuong();
    }
  }

  // =========================================================
  // CHỌN RIÊNG THÁNG
  // =========================================================

  Future<void> selectMonth(
    int month,
  ) async {
    if (month < 1 ||
        month > 12) {
      return;
    }

    await selectMonthYear(
      DateTime(
        _selectedYear,
        month,
        1,
      ),
    );
  }

  // =========================================================
  // CHỌN RIÊNG NĂM
  // =========================================================

  Future<void> selectYear(
    int year,
  ) async {
    final DateTime now =
        DateTime.now();

    if (year > now.year) {
      return;
    }

    int month =
        _selectedMonth;

    /*
     * Nếu chọn năm hiện tại nhưng tháng đang chọn
     * lớn hơn tháng hiện tại thì đưa về tháng hiện tại.
     *
     * Ví dụ đang xem:
     * 12/2025
     *
     * chọn 2026 trong khi hiện tại là 08/2026
     * → tự chuyển thành 08/2026.
     */
    if (year == now.year &&
        month > now.month) {
      month = now.month;
    }

    await selectMonthYear(
      DateTime(
        year,
        month,
        1,
      ),
    );
  }

  // =========================================================
  // LẤY THỰC LĨNH CỦA MỘT THÁNG TRONG BIỂU ĐỒ
  // =========================================================

  LuongThucLinhThangModel?
      getThongKeThang(
    int month,
  ) {
    for (final item
        in _thongKeNam) {
      if (item.thang == month) {
        return item;
      }
    }

    return null;
  }

  // =========================================================
  // RESET
  // =========================================================

  void clear() {
    /*
     * Hủy hiệu lực các request
     * đang chạy.
     */
    _salaryRequestVersion++;
    _chartRequestVersion++;

    _data = null;

    _thongKeNam = [];

    _errorMessage = null;

    _thongKeErrorMessage = null;

    _isLoading = false;

    _isLoadingThongKe = false;

    /*
     * Khi logout/login tài khoản khác,
     * đưa về tháng hiện tại.
     */
    final DateTime now =
        DateTime.now();

    _selectedMonth =
        now.month;

    _selectedYear =
        now.year;

    notifyListeners();
  }
}