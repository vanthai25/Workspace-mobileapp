import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/chamcong_bosung_model.dart';
import '../../services/chamcong_bosung_service.dart';
import '../../utils/helpers.dart';
import 'cham_cong_bo_sung_web_design.dart';
import 'tao_phieu_bosung_screen.dart';

class BaoCaoLechScreen extends StatefulWidget {
  const BaoCaoLechScreen({super.key});

  @override
  State<BaoCaoLechScreen> createState() => _BaoCaoLechScreenState();
}

class _BaoCaoLechScreenState extends State<BaoCaoLechScreen> {
  final ChamCongBoSungService _apiService = ChamCongBoSungService();

  final Color primaryColor = const Color(0xFF1274BC);

  bool _isLoading = true;
  bool _isWeekView = true;

  late DateTime _focusedMonth;
  late DateTime _selectedDate;

  /// Dữ liệu bảng công V2 theo ngày.
  Map<DateTime, BaoCaoChamCongLechV2> _mapData = {};

  /// Phiếu bổ sung cá nhân theo ngày và đúng cơ sở.
  Map<DateTime, ChamCongBoSung> _mapPhieu = {};

  List<ChamCongCoSoOption> _danhSachCoSo = [];

  /// Mã cơ sở ngắn dùng để gọi API:
  /// BVHV, PKCM, PKKX, PKSD, PKTB.
  String? _selectedCoSo;

  /// Giá trị thực tế lưu trong CHAMCONG_BOSUNG.Coso.
  String? _coSoLuuBoSung;

  final List<String> _weekDays = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];

  @override
  void initState() {
    super.initState();

    final DateTime now = DateTime.now();

    _focusedMonth = DateTime(now.year, now.month, 1);

    _selectedDate = DateTime(now.year, now.month, now.day);

    _fetchDataForMonth();
  }

  DateTime? _parseApiDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final String raw = value.trim();

    final DateTime? isoDate = DateTime.tryParse(raw);

    if (isoDate != null) {
      return isoDate;
    }

    try {
      return DateFormat('dd/MM/yyyy').parseStrict(raw);
    } catch (_) {
      return null;
    }
  }

  DateTime _cleanDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  Future<void> _fetchDataForMonth() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    final DateTime firstDay = DateTime(
      _focusedMonth.year,
      _focusedMonth.month,
      1,
    );

    final DateTime lastDay = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    );

    final String tuNgay = DateFormat('yyyy-MM-dd').format(firstDay);

    final String denNgay = DateFormat('yyyy-MM-dd').format(lastDay);

    final BaoCaoChamCongLechV2Result? report = await _apiService
        .getBaoCaoLechV2(tuNgay: tuNgay, denNgay: denNgay, coSo: _selectedCoSo);

    if (!mounted) {
      return;
    }

    if (report == null) {
      setState(() {
        _mapData.clear();
        _mapPhieu.clear();
        _isLoading = false;
      });

      return;
    }

    /*
     * Stored V2 chỉ trả thông tin tổng hợp công.
     * Lấy thêm lịch sử phiếu để hiển thị:
     * - trạng thái chờ duyệt;
     * - nội dung, lý do;
     * - sửa, xóa phiếu.
     */
    final List<ChamCongBoSung> danhSachPhieu = await _apiService
        .getDanhSachPhieuCaNhan(
          month: _focusedMonth.month,
          year: _focusedMonth.year,
        );

    if (!mounted) {
      return;
    }

    final Map<DateTime, BaoCaoChamCongLechV2> newMapData = {};

    for (final BaoCaoChamCongLechV2 item in report.data) {
      final DateTime? ngay = item.ngay;

      if (ngay == null) {
        continue;
      }

      newMapData[_cleanDate(ngay)] = item;
    }

    final String currentCosoDatabase =
        report.cosoLuuBoSung?.trim().toUpperCase() ?? '';

    final Map<DateTime, ChamCongBoSung> newMapPhieu = {};

    for (final ChamCongBoSung phieu in danhSachPhieu) {
      final String phieuCoso = phieu.coso?.trim().toUpperCase() ?? '';

      /*
       * Chỉ ghép phiếu thuộc đúng cơ sở
       * đang mở trên màn hình.
       */
      if (phieuCoso != currentCosoDatabase) {
        continue;
      }

      final DateTime? ngayPhieu = _parseApiDate(phieu.ngaythieu);

      if (ngayPhieu == null) {
        continue;
      }

      final DateTime key = _cleanDate(ngayPhieu);

      /*
       * API lịch sử đang sắp xếp mới nhất trước.
       * Mỗi ngày chỉ hiển thị phiếu mới nhất.
       */
      newMapPhieu.putIfAbsent(key, () => phieu);
    }

    setState(() {
      _mapData = newMapData;
      _mapPhieu = newMapPhieu;

      _selectedCoSo = report.coSoDangXem ?? report.coSoMacDinh ?? 'BVHV';

      _coSoLuuBoSung = report.cosoLuuBoSung;

      _danhSachCoSo = report.danhSachCoSo;

      _isLoading = false;
    });
  }

  void _changeMonth(int offset) {
    setState(() {
      _focusedMonth = DateTime(
        _focusedMonth.year,
        _focusedMonth.month + offset,
        1,
      );

      _selectedDate = _focusedMonth;
    });

    _fetchDataForMonth();
  }

  void _changeCoSo(String maCoSo) {
    if (_selectedCoSo == maCoSo || _isLoading) {
      return;
    }

    setState(() {
      _selectedCoSo = maCoSo;
      _mapData.clear();
      _mapPhieu.clear();
    });

    _fetchDataForMonth();
  }

  Color _getTicketColor(
    int? status, {
    bool isBg = false,
    bool isBorder = false,
  }) {
    switch (status) {
      case 1:
      case 2:
        if (isBg) {
          return Colors.blue.shade50;
        }

        if (isBorder) {
          return Colors.blue.shade200;
        }

        return Colors.blue.shade700;

      case 3:
      case 5:
        if (isBg) {
          return Colors.red.shade50;
        }

        if (isBorder) {
          return Colors.red.shade200;
        }

        return Colors.red.shade700;

      case 4:
        if (isBg) {
          return Colors.green.shade50;
        }

        if (isBorder) {
          return Colors.green.shade200;
        }

        return Colors.green.shade700;

      default:
        if (isBg) {
          return Colors.grey.shade50;
        }

        if (isBorder) {
          return Colors.grey.shade200;
        }

        return Colors.grey.shade700;
    }
  }

  IconData _getTicketIcon(int? status) {
    switch (status) {
      case 1:
      case 2:
        return Icons.pending_actions_rounded;

      case 3:
      case 5:
        return Icons.cancel_presentation_rounded;

      case 4:
        return Icons.task_alt_rounded;

      default:
        return Icons.info_outline_rounded;
    }
  }

  String _getTicketStatusText(int? status) {
    switch (status) {
      case 1:
        return 'Chờ LĐ Đơn vị duyệt';

      case 2:
        return 'Chờ Kế toán duyệt';

      case 3:
        return 'LĐ Đơn vị từ chối';

      case 4:
        return 'Đã duyệt bổ sung';

      case 5:
        return 'Kế toán từ chối';

      default:
        return 'Trạng thái không xác định';
    }
  }

  String _getCurrentCoSoName() {
    for (final ChamCongCoSoOption coSo in _danhSachCoSo) {
      if (coSo.ma == _selectedCoSo) {
        return coSo.ten;
      }
    }

    return _selectedCoSo ?? '';
  }

  @override
  Widget build(BuildContext context) {
    if (useChamCongDesktopWeb(context)) {
      return _buildWeb(context);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text(
          'Đối chiếu công',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: primaryColor,
        onRefresh: _fetchDataForMonth,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildCoSoSelector(),

              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildCalendarHeader(),

                    const SizedBox(height: 16),

                    _buildDaysOfWeek(),

                    const SizedBox(height: 8),

                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: _isLoading
                          ? SizedBox(
                              height: 120,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: primaryColor,
                                ),
                              ),
                            )
                          : _buildCalendarGrid(),
                    ),

                    GestureDetector(
                      onTap: _isLoading
                          ? null
                          : () {
                              setState(() {
                                _isWeekView = !_isWeekView;
                              });
                            },
                      child: Container(
                        width: 40,
                        height: 24,
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _isWeekView
                              ? Icons.keyboard_arrow_down_rounded
                              : Icons.keyboard_arrow_up_rounded,
                          color: Colors.grey.shade600,
                          size: 20,
                        ),
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFF0F0F0),
                      ),
                    ),

                    _buildLegend(),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 40),
                child: _isLoading
                    ? const SizedBox.shrink()
                    : _buildSelectedDayDetail(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeb(BuildContext context) {
    return ChamCongWebPage(
      title: 'Đối chiếu chấm công',
      subtitle: 'Kiểm tra dữ liệu theo ngày và tạo phiếu bổ sung khi cần',
      icon: Icons.fingerprint_rounded,
      maxWidth: 1420,
      actions: [
        OutlinedButton.icon(
          onPressed: _isLoading
              ? null
              : () => setState(() => _isWeekView = !_isWeekView),
          icon: Icon(
            _isWeekView ? Icons.calendar_view_month : Icons.view_week_rounded,
          ),
          label: Text(_isWeekView ? 'Xem cả tháng' : 'Xem theo tuần'),
        ),
        const SizedBox(width: 10),
        IconButton.filledTonal(
          tooltip: 'Làm mới dữ liệu',
          onPressed: _isLoading ? null : _fetchDataForMonth,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      child: Column(
        children: [
          _buildWebCoSoSelector(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final calendar = _buildWebCalendarPanel();
                final detail = _isLoading
                    ? const SizedBox.shrink()
                    : _buildSelectedDayDetail();

                if (constraints.maxWidth < 1050) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                    child: Column(
                      children: [calendar, const SizedBox(height: 14), detail],
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 590,
                        child: SingleChildScrollView(child: calendar),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: detail,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebCoSoSelector() {
    if (_danhSachCoSo.isEmpty) {
      return const SizedBox(height: 18);
    }

    return ChamCongWebCard(
      margin: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Expanded(
            child: ChamCongWebSectionTitle(
              title: 'Cơ sở chấm công',
              subtitle: 'Chọn địa điểm cần đối chiếu dữ liệu',
              icon: Icons.location_on_outlined,
            ),
          ),
          const SizedBox(width: 18),
          ..._danhSachCoSo.map((coSo) {
            final selected = _selectedCoSo == coSo.ma;

            return Padding(
              padding: const EdgeInsets.only(left: 7),
              child: ChoiceChip(
                selected: selected,
                showCheckmark: false,
                selectedColor: ChamCongWebColors.primary,
                backgroundColor: const Color(0xFFF8FAFC),
                side: BorderSide(
                  color: selected
                      ? ChamCongWebColors.primary
                      : ChamCongWebColors.border,
                ),
                label: Text(
                  coSo.ma,
                  style: TextStyle(
                    color: selected ? Colors.white : ChamCongWebColors.muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                onSelected: _isLoading ? null : (_) => _changeCoSo(coSo.ma),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWebCalendarPanel() {
    return ChamCongWebCard(
      child: Column(
        children: [
          _buildCalendarHeader(),
          const SizedBox(height: 16),
          _buildDaysOfWeek(),
          const SizedBox(height: 8),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _isLoading
                ? const SizedBox(
                    height: 180,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: ChamCongWebColors.primary,
                      ),
                    ),
                  )
                : _buildCalendarGrid(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isLoading
                  ? null
                  : () {
                      setState(() {
                        _isWeekView = !_isWeekView;
                      });
                    },
              icon: Icon(
                _isWeekView
                    ? Icons.keyboard_arrow_down_rounded
                    : Icons.keyboard_arrow_up_rounded,
              ),
              label: Text(
                _isWeekView ? 'Xem lịch cả tháng' : 'Thu gọn theo tuần',
              ),
            ),
          ),
          const SizedBox(height: 13),
          const Divider(height: 1),
          const SizedBox(height: 13),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildCoSoSelector() {
    if (_danhSachCoSo.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(Icons.location_on_rounded, color: primaryColor, size: 19),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    _getCurrentCoSoName().isEmpty
                        ? 'Cơ sở chấm công'
                        : _getCurrentCoSoName(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ),
                if (_coSoLuuBoSung != null)
                  Text(
                    _selectedCoSo ?? '',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: _danhSachCoSo.map((coSo) {
                final bool isSelected = _selectedCoSo == coSo.ma;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      coSo.ma,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: primaryColor,
                    backgroundColor: Colors.grey.shade50,
                    side: BorderSide(
                      color: isSelected ? primaryColor : Colors.grey.shade300,
                    ),
                    showCheckmark: false,
                    onSelected: (_) {
                      _changeCoSo(coSo.ma);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(
              Icons.calendar_month_rounded,
              color: Color(0xFF2C3E50),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Tháng ${_focusedMonth.month}/${_focusedMonth.year}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.chevron_left_rounded, color: primaryColor),
              onPressed: _isLoading ? null : () => _changeMonth(-1),
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(4),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: Icon(Icons.chevron_right_rounded, color: primaryColor),
              onPressed: _isLoading ? null : () => _changeMonth(1),
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(4),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDaysOfWeek() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: _weekDays.map((day) {
        return SizedBox(
          width: 30,
          child: Text(
            day,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalendarGrid() {
    if (_isWeekView) {
      final int offsetToSunday = _selectedDate.weekday == 7
          ? 0
          : _selectedDate.weekday;

      final DateTime startOfWeek = _selectedDate.subtract(
        Duration(days: offsetToSunday),
      );

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 7,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisSpacing: 8,
          crossAxisSpacing: 4,
          childAspectRatio: 0.85,
        ),
        itemBuilder: (context, index) {
          final DateTime cellDate = _cleanDate(
            startOfWeek.add(Duration(days: index)),
          );

          final bool inCurrentMonth =
              cellDate.month == _focusedMonth.month &&
              cellDate.year == _focusedMonth.year;

          return _buildCalendarCell(cellDate, inCurrentMonth: inCurrentMonth);
        },
      );
    }

    final int daysInMonth = DateUtils.getDaysInMonth(
      _focusedMonth.year,
      _focusedMonth.month,
    );

    final int firstWeekday = DateTime(
      _focusedMonth.year,
      _focusedMonth.month,
      1,
    ).weekday;

    final int emptySlots = firstWeekday % 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: emptySlots + daysInMonth,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 4,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) {
        if (index < emptySlots) {
          return const SizedBox.shrink();
        }

        final int day = index - emptySlots + 1;

        final DateTime cellDate = DateTime(
          _focusedMonth.year,
          _focusedMonth.month,
          day,
        );

        return _buildCalendarCell(cellDate, inCurrentMonth: true);
      },
    );
  }

  Widget _buildCalendarCell(DateTime cellDate, {required bool inCurrentMonth}) {
    final bool isSelected = cellDate == _selectedDate;

    final DateTime now = DateTime.now();

    final bool isToday = cellDate == DateTime(now.year, now.month, now.day);

    final BaoCaoChamCongLechV2? data = _mapData[cellDate];

    final bool hasData = data != null;

    final String kyHieu = data?.kh?.trim().toUpperCase() ?? '';

    final String trangThai = data?.trangThai.trim().toLowerCase() ?? '';

    final bool isNghi = hasData && trangThai.startsWith('nghỉ');

    final bool isThieu = hasData && trangThai.startsWith('thiếu');

    final bool isOk = hasData && trangThai.startsWith('đủ');

    Color backgroundColor = Colors.transparent;

    if (isSelected) {
      backgroundColor = primaryColor;
    } else if (isNghi) {
      // Ngày nghỉ để nền trắng.
      backgroundColor = Colors.white;
    } else if (isThieu) {
      backgroundColor = Colors.red.shade100;
    } else if (isOk) {
      backgroundColor = Colors.green.shade100;
    }

    Color textColor = Colors.black87;

    if (isSelected) {
      textColor = Colors.white;
    } else if (!inCurrentMonth) {
      textColor = Colors.grey.shade400;
    } else if (isNghi) {
      textColor = Colors.grey.shade700;
    } else if (isThieu) {
      textColor = Colors.red.shade800;
    } else if (isOk) {
      textColor = Colors.green.shade800;
    } else if (isToday) {
      textColor = primaryColor;
    }

    return GestureDetector(
      onTap: () {
        final bool changeMonth = !inCurrentMonth;

        setState(() {
          _selectedDate = cellDate;

          if (changeMonth) {
            _focusedMonth = DateTime(cellDate.year, cellDate.month, 1);
          }
        });

        if (changeMonth) {
          _fetchDataForMonth();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: isToday && !isSelected
              ? Border.all(color: primaryColor.withOpacity(0.5), width: 1.5)
              : null,
        ),
        child: Center(
          child: Text(
            cellDate.day.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected || isToday || hasData
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _legendItem(Colors.green.shade100, Colors.green.shade800, 'Đủ công'),
        _legendItem(Colors.red.shade100, Colors.red.shade800, 'Thiếu công'),
      ],
    );
  }

  Widget _legendItem(Color backgroundColor, Color textColor, String label) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: textColor.withOpacity(0.3), width: 1),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedDayDetail() {
    final BaoCaoChamCongLechV2? item = _mapData[_selectedDate];

    final ChamCongBoSung? phieu = _mapPhieu[_selectedDate];

    if (item == null) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 20),
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              Icons.event_available_rounded,
              size: 50,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            const Text(
              'Chưa có dữ liệu chấm công cho ngày này',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final String trangThai = item.trangThai.trim();

    final bool isThieu = trangThai.toLowerCase().startsWith('thiếu');

    final bool isDaBoSung = item.isBoSung == 1;

    final String kyHieu = item.kh?.trim().isNotEmpty == true
        ? item.kh!.toUpperCase()
        : 'N/A';

    final DateTime now = DateTime.now();

    final DateTime today = DateTime(now.year, now.month, now.day);

    final DateTime selectedDay = _cleanDate(_selectedDate);

    final bool isOver7Days = today.difference(selectedDay).inDays > 7;

    final bool canCreatePhieu =
        isThieu &&
        (phieu == null ||
            phieu.trangthaiduyet == 3 ||
            phieu.trangthaiduyet == 5);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: isThieu ? Colors.red : Colors.green,
              width: 6,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.ngay == null
                          ? 'Ngày: N/A'
                          : 'Ngày: ${DateFormat('dd/MM/yyyy').format(item.ngay!)} - ${item.thu}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ),

                  if (isDaBoSung)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Text(
                        'ĐÃ BỔ SUNG',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  const Icon(
                    Icons.bookmark_added_rounded,
                    size: 17,
                    color: Colors.blueGrey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ký hiệu: $kyHieu',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildMetricBox(
                      label: 'Tổng giờ',
                      value: '${item.gio.toStringAsFixed(2)} giờ',
                      icon: Icons.schedule_rounded,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricBox(
                      label: 'Công',
                      value: item.cong.toStringAsFixed(
                        item.cong % 1 == 0 ? 0 : 1,
                      ),
                      icon: Icons.fact_check_rounded,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1),
              ),

              Row(
                children: [
                  Expanded(child: _buildTimeSlot('Vào 1', item.vao1)),
                  Expanded(child: _buildTimeSlot('Ra 1', item.ra1)),
                  Expanded(child: _buildTimeSlot('Vào 2', item.vao2)),
                  Expanded(child: _buildTimeSlot('Ra 2', item.ra2)),
                ],
              ),

              // const SizedBox(height: 16),

              // Row(
              //   children: [
              //     Expanded(
              //       child: _buildDelayItem(
              //         title: 'Đi trễ',
              //         value: item.tre,
              //         icon:
              //             Icons.login_rounded,
              //       ),
              //     ),
              //     const SizedBox(width: 10),
              //     Expanded(
              //       child: _buildDelayItem(
              //         title: 'Về sớm',
              //         value: item.som,
              //         icon:
              //             Icons.logout_rounded,
              //       ),
              //     ),
              //   ],
              // ),
              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isThieu ? Colors.red : Colors.green).withOpacity(
                    0.05,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (isThieu ? Colors.red : Colors.green).withOpacity(
                      0.18,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isThieu
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_outline,
                      size: 20,
                      color: isThieu ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        trangThai,
                        style: TextStyle(
                          color: isThieu
                              ? Colors.red.shade700
                              : Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (phieu != null) ...[
                const SizedBox(height: 16),
                _buildPhieuBoSungCard(
                  item: item,
                  phieu: phieu,
                  isOver7Days: isOver7Days,
                ),
              ],

              if (canCreatePhieu) ...[
                const SizedBox(height: 16),

                if (isOver7Days)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_clock_rounded,
                          color: Colors.red.shade700,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Đã quá 7 ngày, không thể tạo phiếu!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _openCreateScreen(item);
                      },
                      icon: const Icon(
                        Icons.add_task_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'TẠO PHIẾU BỔ SUNG CÔNG',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhieuBoSungCard({
    required BaoCaoChamCongLechV2 item,
    required ChamCongBoSung phieu,
    required bool isOver7Days,
  }) {
    final int? status = phieu.trangthaiduyet;

    final Color statusColor = _getTicketColor(status);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _getTicketColor(status, isBg: true),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getTicketColor(status, isBorder: true)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(_getTicketIcon(status), color: statusColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getTicketStatusText(status),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (phieu.tongcong != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+ ${phieu.tongcong} công',
                      style: TextStyle(
                        color: Colors.amber.shade900,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPhieuInfoRow(
                  icon: Icons.assignment_rounded,
                  label: 'Nội dung',
                  value: phieu.noidung,
                ),

                const SizedBox(height: 8),

                _buildPhieuInfoRow(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Lý do',
                  value: phieu.lydo,
                ),

                if (phieu.ghichu != null &&
                    phieu.ghichu!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildPhieuInfoRow(
                    icon: Icons.info_outline_rounded,
                    label: 'Ghi chú',
                    value: phieu.ghichu,
                    valueColor: Colors.red.shade700,
                  ),
                ],
              ],
            ),
          ),

          if (status == 1 && !isOver7Days) ...[
            const Divider(height: 1, thickness: 1),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      _deletePhieu(phieu);
                    },
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 17,
                    ),
                    label: const Text(
                      'Xóa phiếu',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),

                Container(height: 20, width: 1, color: Colors.grey.shade300),

                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      _openEditScreen(item, phieu);
                    },
                    icon: Icon(
                      Icons.edit_document,
                      color: Colors.blue.shade700,
                      size: 17,
                    ),
                    label: Text(
                      'Sửa phiếu',
                      style: TextStyle(color: Colors.blue.shade700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhieuInfoRow({
    required IconData icon,
    required String label,
    required String? value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.blueGrey.shade400),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label: ${value?.trim().isNotEmpty == true ? value : ''}',
            style: TextStyle(
              fontSize: 13,
              color: valueColor ?? Colors.black87,
              fontWeight: label == 'Nội dung'
                  ? FontWeight.w500
                  : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricBox({
    required String label,
    required String value,
    required IconData icon,
    required MaterialColor color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.shade100),
      ),
      child: Row(
        children: [
          Icon(icon, color: color.shade700, size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: color.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDelayItem({
    required String title,
    required int value,
    required IconData icon,
  }) {
    final bool hasDelay = value > 0;

    final Color color = hasDelay ? Colors.red : Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              '$title: $value phút',
              style: TextStyle(
                color: hasDelay ? Colors.red.shade700 : Colors.green.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlot(String label, String? time) {
    final bool isMissing =
        time == null || time.trim().isEmpty || time == '-' || time == 'N/A';

    final String displayTime = isMissing ? '--:--' : time;

    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 6),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
          decoration: BoxDecoration(
            color: isMissing
                ? Colors.red.withOpacity(0.05)
                : const Color(0xFFF4F7FB),
            borderRadius: BorderRadius.circular(8),
            border: isMissing
                ? Border.all(color: Colors.red.withOpacity(0.2))
                : null,
          ),
          child: Text(
            displayTime,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isMissing ? Colors.red.shade400 : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openCreateScreen(BaoCaoChamCongLechV2 item) async {
    final DateTime? ngay = item.ngay;

    if (ngay == null) {
      AppHelpers.showSnackBar(
        'Không xác định được ngày thiếu công.',
        isError: true,
      );
      return;
    }

    final bool? result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TaoPhieuBoSungScreen(
          ngayThieu: DateFormat('dd/MM/yyyy').format(ngay),
          coSo: _selectedCoSo ?? 'BVHV',
        ),
      ),
    );

    if (result == true) {
      await _fetchDataForMonth();
    }
  }

  Future<void> _openEditScreen(
    BaoCaoChamCongLechV2 item,
    ChamCongBoSung phieu,
  ) async {
    final DateTime? ngay = item.ngay;

    if (ngay == null || phieu.id == null) {
      AppHelpers.showSnackBar(
        'Không xác định được thông tin phiếu.',
        isError: true,
      );
      return;
    }

    final bool? result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TaoPhieuBoSungScreen(
          ngayThieu: DateFormat('dd/MM/yyyy').format(ngay),
          coSo: _selectedCoSo ?? 'BVHV',
          editId: phieu.id,
          oldNoiDung: phieu.noidung,
          oldLyDo: phieu.lydo,
          oldTongCong: phieu.tongcong,
        ),
      ),
    );

    if (result == true) {
      await _fetchDataForMonth();
    }
  }

  Future<void> _deletePhieu(ChamCongBoSung phieu) async {
    if (phieu.id == null) {
      return;
    }

    final bool confirm =
        await showDialog<bool>(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              title: const Text('Xóa phiếu'),
              content: const Text(
                'Bạn có chắc chắn muốn xóa phiếu bổ sung này?',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx, false);
                  },
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    Navigator.pop(ctx, true);
                  },
                  child: const Text(
                    'Xóa',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirm) {
      return;
    }

    final bool success = await _apiService.deletePhieu(phieu.id!);

    if (!success) {
      AppHelpers.showSnackBar('Xóa phiếu thất bại.', isError: true);
      return;
    }

    AppHelpers.showSnackBar('Đã xóa phiếu thành công.', isError: false);

    await _fetchDataForMonth();
  }
}
