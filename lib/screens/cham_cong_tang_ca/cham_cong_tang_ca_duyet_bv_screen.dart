import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/cham_cong_tang_ca_model.dart';
import '../../providers/cham_cong_tang_ca_provider.dart';
import '../../utils/helpers.dart';

class ChamCongTangCaDuyetBVScreen extends StatefulWidget {
  const ChamCongTangCaDuyetBVScreen({Key? key}) : super(key: key);

  @override
  State<ChamCongTangCaDuyetBVScreen> createState() =>
      _ChamCongTangCaDuyetBVScreenState();
}

class _ChamCongTangCaDuyetBVScreenState
    extends State<ChamCongTangCaDuyetBVScreen> {
  DateTime _selectedMonth = DateTime.now();

  /// null: Tất cả
  /// 1: Chờ BV duyệt
  /// 2: BV đã duyệt
  /// 3: Từ chối
  int? _selectedStatus = 1;

  /// Chuỗi rỗng: Tất cả khoa
  String _selectedMaKhoa = '';

  /// Danh sách ID đang được tích chọn
  final Set<int> _selectedIds = <int>{};

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChamCongTangCaProvider>().fetchDanhSach();
    });
  }

  // =========================================================
  // XỬ LÝ THÁNG
  // =========================================================

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month - 1,
        1,
      );

      _selectedIds.clear();
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
        1,
      );

      _selectedIds.clear();
    });
  }

  // =========================================================
  // KIỂM TRA TRẠNG THÁI
  // =========================================================

  bool _isBVRejected(ChamCongTangCaModel phieu) {
    return phieu.trangThaiDuyet == 3 &&
        phieu.ldBVDuyet != null &&
        phieu.ldBVDuyet!.trim().isNotEmpty;
  }

  bool _isKhoaRejected(ChamCongTangCaModel phieu) {
    return phieu.trangThaiDuyet == 3 &&
        (phieu.ldBVDuyet == null || phieu.ldBVDuyet!.trim().isEmpty);
  }

  bool _canSelect(ChamCongTangCaModel phieu) {
    return phieu.trangThaiDuyet == 1;
  }

  // =========================================================
  // DANH SÁCH KHOA
  // =========================================================

  Map<String, String> _getDanhSachKhoa(
    List<ChamCongTangCaModel> danhSach,
  ) {
    final Map<String, String> result = <String, String>{};

    for (final phieu in danhSach) {
      final String maKhoa = phieu.maKhoa.trim();
      final String tenKhoa = phieu.tenKhoa.trim();

      if (maKhoa.isEmpty) {
        continue;
      }

      result[maKhoa] = tenKhoa.isNotEmpty ? tenKhoa : maKhoa;
    }

    final List<MapEntry<String, String>> entries = result.entries.toList()
      ..sort(
        (a, b) => a.value.toLowerCase().compareTo(
              b.value.toLowerCase(),
            ),
      );

    return Map<String, String>.fromEntries(entries);
  }

  Future<void> _showChonKhoaBottomSheet(
    Map<String, String> danhSachKhoa,
  ) async {
    final String? selectedMaKhoa = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return _KhoaPickerBottomSheet(
          danhSachKhoa: danhSachKhoa,
          selectedMaKhoa: _selectedMaKhoa,
        );
      },
    );

    if (!mounted || selectedMaKhoa == null) {
      return;
    }

    setState(() {
      _selectedMaKhoa = selectedMaKhoa;
      _selectedIds.clear();
    });
  }

  Widget _buildKhoaFilter(
    Map<String, String> danhSachKhoa,
  ) {
    final String selectedTenKhoa = _selectedMaKhoa.isEmpty
        ? 'Tất cả Khoa'
        : danhSachKhoa[_selectedMaKhoa] ?? 'Tất cả Khoa';

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            _showChonKhoaBottomSheet(danhSachKhoa);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.apartment,
                    color: Colors.green,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedTenKhoa,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // LỌC DANH SÁCH
  // =========================================================

  List<ChamCongTangCaModel> _filterDanhSach(
    List<ChamCongTangCaModel> danhSach,
  ) {
    final List<ChamCongTangCaModel> result = danhSach.where((phieu) {
      // Phiếu trạng thái 0 chưa qua Khoa nên BV không được xử lý.
      if (phieu.trangThaiDuyet == 0) {
        return false;
      }

      if (_selectedStatus != null &&
          phieu.trangThaiDuyet != _selectedStatus) {
        return false;
      }

      if (phieu.batDau.year != _selectedMonth.year ||
          phieu.batDau.month != _selectedMonth.month) {
        return false;
      }

      if (_selectedMaKhoa.isNotEmpty &&
          phieu.maKhoa.trim() != _selectedMaKhoa.trim()) {
        return false;
      }

      return true;
    }).toList();

    result.sort((a, b) => b.ngayLap.compareTo(a.ngayLap));

    return result;
  }

  // =========================================================
  // HIỂN THỊ TRẠNG THÁI
  // =========================================================

  String _getTrangThaiText(ChamCongTangCaModel phieu) {
    switch (phieu.trangThaiDuyet) {
      case 1:
        return 'Chờ BV duyệt';

      case 2:
        return 'BV đã duyệt';

      case 3:
        if (_isBVRejected(phieu)) {
          return 'BV từ chối';
        }

        if (_isKhoaRejected(phieu)) {
          return 'Khoa từ chối';
        }

        return 'Đã từ chối';

      default:
        return 'Không xác định';
    }
  }

  Color _getTrangThaiColor(ChamCongTangCaModel phieu) {
    switch (phieu.trangThaiDuyet) {
      case 1:
        return Colors.orange;

      case 2:
        return Colors.green;

      case 3:
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  Widget _buildTrangThaiBadge(
    ChamCongTangCaModel phieu,
  ) {
    final Color color = _getTrangThaiColor(phieu);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.5),
        ),
      ),
      child: Text(
        _getTrangThaiText(phieu),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    int? statusValue,
  ) {
    final bool isSelected = _selectedStatus == statusValue;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: Colors.green.withOpacity(0.18),
        backgroundColor: Colors.grey.shade100,
        side: BorderSide(
          color: isSelected ? Colors.green : Colors.transparent,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        onSelected: (_) {
          setState(() {
            _selectedStatus = statusValue;
            _selectedIds.clear();
          });
        },
      ),
    );
  }

  // =========================================================
  // HIỂN THỊ NGƯỜI DUYỆT
  // =========================================================

  Widget _buildThongTinDuyet(
    ChamCongTangCaModel phieu,
  ) {
    final DateFormat dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    final String? tenLDKhoa = phieu.tenLDKhoaDuyet?.trim();
    final String? tenLDBV = phieu.tenLDBVDuyet?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tenLDKhoa != null && tenLDKhoa.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.person_outline,
                color: Colors.blueGrey,
                size: 19,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'LĐ Khoa: $tenLDKhoa',
                  style: const TextStyle(
                    color: Colors.blueGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (phieu.ngayLDKhoaDuyet != null)
            Padding(
              padding: const EdgeInsets.only(
                left: 25,
                top: 2,
              ),
              child: Text(
                'Xử lý lúc: ${dateFormat.format(phieu.ngayLDKhoaDuyet!)}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ),
        ],
        if (tenLDBV != null && tenLDBV.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.verified_user_outlined,
                color: Colors.green,
                size: 19,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'LĐ Bệnh viện: $tenLDBV',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (phieu.ngayLDBVDuyet != null)
            Padding(
              padding: const EdgeInsets.only(
                left: 25,
                top: 2,
              ),
              child: Text(
                'Xử lý lúc: ${dateFormat.format(phieu.ngayLDBVDuyet!)}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ),
        ],
        if (phieu.trangThaiDuyet == 3) ...[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.cancel_outlined,
                color: Colors.red,
                size: 19,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Lý do từ chối: '
                  '${phieu.lyDoTuChoi?.trim().isNotEmpty == true ? phieu.lyDoTuChoi!.trim() : "Không có lý do"}',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // =========================================================
  // DIALOG
  // =========================================================

  Future<bool> _showConfirmDialog({
    required String title,
    required String content,
    Color confirmColor = Colors.green,
  }) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Đóng'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: Text(
                'Xác nhận',
                style: TextStyle(
                  color: confirmColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<String?> _showRejectDialog({
    required String title,
    required String hintText,
  }) async {
    final TextEditingController controller = TextEditingController();

    final String? result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: hintText,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Đóng'),
            ),
            TextButton(
              onPressed: () {
                final String lyDo = controller.text.trim();

                if (lyDo.isEmpty) {
                  AppHelpers.showSnackBar(
                    'Vui lòng nhập lý do từ chối',
                    isError: true,
                  );
                  return;
                }

                Navigator.pop(dialogContext, lyDo);
              },
              child: const Text(
                'Xác nhận',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    controller.dispose();

    return result;
  }

  // =========================================================
  // XỬ LÝ MỘT PHIẾU
  // =========================================================

  Future<void> _xuLyPhieu(
    int id,
    int newStatus,
    String tenHanhDong,
  ) async {
    if (_isProcessing) {
      return;
    }

    String lyDoTuChoi = '';

    if (newStatus == 3) {
      final String? lyDo = await _showRejectDialog(
        title: 'Bệnh viện từ chối phiếu',
        hintText: 'Nhập lý do từ chối...',
      );

      if (lyDo == null) {
        return;
      }

      lyDoTuChoi = lyDo;
    } else {
      final bool confirmed = await _showConfirmDialog(
        title: 'Xác nhận $tenHanhDong',
        content: 'Bạn có chắc chắn muốn $tenHanhDong phiếu này?',
        confirmColor: newStatus == 1 ? Colors.orange : Colors.green,
      );

      if (!confirmed) {
        return;
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    final bool success = await context
        .read<ChamCongTangCaProvider>()
        .duyetPhieu(
          id,
          newStatus,
          capDuyet: 'BV',
          lyDoTuChoi: lyDoTuChoi,
        );

    if (!mounted) {
      return;
    }

    setState(() {
      _isProcessing = false;
      _selectedIds.remove(id);
    });

    if (success) {
      AppHelpers.showSnackBar(
        '$tenHanhDong thành công',
      );
    }
  }

  // =========================================================
  // XỬ LÝ NHIỀU PHIẾU
  // =========================================================

  Future<void> _duyetNhieu() async {
    if (_selectedIds.isEmpty || _isProcessing) {
      return;
    }

    final bool confirmed = await _showConfirmDialog(
      title: 'BV duyệt nhiều phiếu',
      content:
          'Bạn có chắc chắn muốn duyệt ${_selectedIds.length} phiếu đã chọn?',
      confirmColor: Colors.green,
    );

    if (!confirmed || !mounted) {
      return;
    }

    final Set<int> idsCanXuLy = Set<int>.from(_selectedIds);

    setState(() {
      _isProcessing = true;
    });

    final bool success = await context
        .read<ChamCongTangCaProvider>()
        .duyetNhieu(
          ids: idsCanXuLy,
          newStatus: 2,
          capDuyet: 'BV',
        );

    if (!mounted) {
      return;
    }

    setState(() {
      _isProcessing = false;

      if (success) {
        _selectedIds.clear();
      }
    });

    if (success) {
      AppHelpers.showSnackBar(
        'Bệnh viện đã duyệt ${idsCanXuLy.length} phiếu',
      );
    }
  }

  Future<void> _tuChoiNhieu() async {
    if (_selectedIds.isEmpty || _isProcessing) {
      return;
    }

    final String? lyDo = await _showRejectDialog(
      title: 'BV từ chối nhiều phiếu',
      hintText: 'Nhập lý do từ chối chung cho các phiếu...',
    );

    if (lyDo == null || !mounted) {
      return;
    }

    final Set<int> idsCanXuLy = Set<int>.from(_selectedIds);

    setState(() {
      _isProcessing = true;
    });

    final bool success = await context
        .read<ChamCongTangCaProvider>()
        .duyetNhieu(
          ids: idsCanXuLy,
          newStatus: 3,
          capDuyet: 'BV',
          lyDoTuChoi: lyDo,
        );

    if (!mounted) {
      return;
    }

    setState(() {
      _isProcessing = false;

      if (success) {
        _selectedIds.clear();
      }
    });

    if (success) {
      AppHelpers.showSnackBar(
        'Bệnh viện đã từ chối ${idsCanXuLy.length} phiếu',
      );
    }
  }

  bool? _getSelectAllValue(
    Set<int> selectableIds,
  ) {
    if (selectableIds.isEmpty) {
      return false;
    }

    final int selectedCount =
        selectableIds.where(_selectedIds.contains).length;

    if (selectedCount == 0) {
      return false;
    }

    if (selectedCount == selectableIds.length) {
      return true;
    }

    return null;
  }

  // =========================================================
  // CARD PHIẾU
  // =========================================================

  Widget _buildPhieuCard(
    ChamCongTangCaModel phieu,
  ) {
    final bool canSelect = _canSelect(phieu);
    final bool isSelected = _selectedIds.contains(phieu.id);

    final DateFormat dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
    final DateFormat timeFormat = DateFormat('HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Colors.green : Colors.grey.shade200,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (canSelect)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Checkbox(
                      value: isSelected,
                      activeColor: Colors.green,
                      onChanged: _isProcessing
                          ? null
                          : (checked) {
                              setState(() {
                                if (checked == true) {
                                  _selectedIds.add(phieu.id);
                                } else {
                                  _selectedIds.remove(phieu.id);
                                }
                              });
                            },
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: canSelect ? 10 : 0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          phieu.tenNV,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          phieu.tenKhoa,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildTrangThaiBadge(phieu),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.event_note_outlined,
                  size: 19,
                  color: Colors.blueGrey,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Ngày lập: ${dateTimeFormat.format(phieu.ngayLap)}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.schedule,
                  size: 19,
                  color: Colors.blueGrey,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${dateTimeFormat.format(phieu.batDau)}'
                    ' - ${timeFormat.format(phieu.ketThuc)}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.timelapse,
                  size: 19,
                  color: Colors.blueGrey,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Tổng thời gian: ${phieu.soPhut} phút',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.description_outlined,
                  size: 19,
                  color: Colors.blueGrey,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Lý do tăng ca: ${phieu.lyDoTangCa}',
                  ),
                ),
              ],
            ),
            _buildThongTinDuyet(phieu),

            // Chờ Bệnh viện duyệt
            if (phieu.trangThaiDuyet == 1) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: _isProcessing
                        ? null
                        : () {
                            _xuLyPhieu(
                              phieu.id,
                              3,
                              'Từ chối',
                            );
                          },
                    icon: const Icon(
                      Icons.close,
                      size: 18,
                    ),
                    label: const Text('Từ chối'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(
                        color: Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isProcessing
                        ? null
                        : () {
                            _xuLyPhieu(
                              phieu.id,
                              2,
                              'BV duyệt',
                            );
                          },
                    icon: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      'Duyệt phiếu',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ],
              ),
            ],

            // Bệnh viện đã duyệt
            if (phieu.trangThaiDuyet == 2) ...[
              const Divider(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _isProcessing
                      ? null
                      : () {
                          _xuLyPhieu(
                            phieu.id,
                            1,
                            'Hủy duyệt',
                          );
                        },
                  icon: const Icon(
                    Icons.undo,
                    color: Colors.orange,
                  ),
                  label: const Text(
                    'Hủy duyệt',
                    style: TextStyle(
                      color: Colors.orange,
                    ),
                  ),
                ),
              ),
            ],

            // Bệnh viện đã từ chối, cho phép duyệt lại
            if (_isBVRejected(phieu)) ...[
              const Divider(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing
                      ? null
                      : () {
                          _xuLyPhieu(
                            phieu.id,
                            2,
                            'BV duyệt lại',
                          );
                        },
                  icon: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: 19,
                  ),
                  label: const Text(
                    'Duyệt lại',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ),
            ],

            // Khoa từ chối thì BV chỉ được xem
            if (_isKhoaRejected(phieu)) ...[
              const Divider(height: 24),
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.red,
                    size: 19,
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Phiếu đã bị Khoa từ chối và chưa được '
                      'chuyển lên Lãnh đạo Bệnh viện.',
                      style: TextStyle(
                        color: Colors.red,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final ChamCongTangCaProvider provider =
        context.watch<ChamCongTangCaProvider>();

    final Map<String, String> danhSachKhoa =
        _getDanhSachKhoa(provider.danhSachPhieu);

    final List<ChamCongTangCaModel> filteredList =
        _filterDanhSach(provider.danhSachPhieu);

    final Set<int> selectableIds = filteredList
        .where(_canSelect)
        .map((phieu) => phieu.id)
        .toSet();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('BV Duyệt Tăng Ca'),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Bộ lọc tháng
          Container(
            margin: const EdgeInsets.fromLTRB(
              16,
              12,
              16,
              8,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month,
                  color: Colors.blueGrey,
                ),
                const SizedBox(width: 12),
                Text(
                  'Tháng ${_selectedMonth.month}/${_selectedMonth.year}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Tháng trước',
                  onPressed: _previousMonth,
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    size: 16,
                    color: Colors.green,
                  ),
                ),
                IconButton(
                  tooltip: 'Tháng sau',
                  onPressed: _nextMonth,
                  icon: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),

          // Lọc khoa dạng Bottom Sheet
          _buildKhoaFilter(danhSachKhoa),

          // Lọc trạng thái
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
            child: Row(
              children: [
                _buildFilterChip('Tất cả', null),
                _buildFilterChip('Chờ BV duyệt', 1),
                _buildFilterChip('BV đã duyệt', 2),
                _buildFilterChip('Từ chối', 3),
              ],
            ),
          ),

          // Chọn tất cả
          if (selectableIds.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(
                12,
                2,
                12,
                0,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade200,
                ),
              ),
              child: CheckboxListTile(
                dense: true,
                tristate: true,
                activeColor: Colors.green,
                controlAffinity: ListTileControlAffinity.leading,
                value: _getSelectAllValue(selectableIds),
                title: Text(
                  'Chọn tất cả phiếu chờ BV duyệt '
                  '(${selectableIds.length})',
                ),
                onChanged: _isProcessing
                    ? null
                    : (checked) {
                        setState(() {
                          if (checked == true) {
                            _selectedIds.addAll(selectableIds);
                          } else {
                            _selectedIds.removeAll(selectableIds);
                          }
                        });
                      },
              ),
            ),

          Expanded(
            child: Builder(
              builder: (context) {
                if (provider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (provider.errorMessage.isNotEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 42,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            provider.errorMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              context
                                  .read<ChamCongTangCaProvider>()
                                  .fetchDanhSach();
                            },
                            icon: const Icon(
                              Icons.refresh,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Tải lại',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (filteredList.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      _selectedIds.clear();

                      await context
                          .read<ChamCongTangCaProvider>()
                          .fetchDanhSach();
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 160),
                        Icon(
                          Icons.inbox_outlined,
                          size: 52,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 12),
                        Center(
                          child: Text(
                            'Không có phiếu nào.',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _selectedIds.clear();
                    });

                    await context
                        .read<ChamCongTangCaProvider>()
                        .fetchDanhSach();
                  },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      return _buildPhieuCard(
                        filteredList[index],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // Thanh xử lý nhiều phiếu
      bottomNavigationBar: _selectedIds.isEmpty
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey.shade200,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isProcessing ? null : _tuChoiNhieu,
                        icon: const Icon(Icons.close),
                        label: Text(
                          'Từ chối (${_selectedIds.length})',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(
                            color: Colors.red,
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _duyetNhieu,
                        icon: _isProcessing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.check,
                                color: Colors.white,
                              ),
                        label: Text(
                          'Duyệt (${_selectedIds.length})',
                          style: const TextStyle(
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// ===========================================================
// BOTTOM SHEET CHỌN KHOA
// ===========================================================

class _KhoaPickerBottomSheet extends StatefulWidget {
  final Map<String, String> danhSachKhoa;
  final String selectedMaKhoa;

  const _KhoaPickerBottomSheet({
    required this.danhSachKhoa,
    required this.selectedMaKhoa,
  });

  @override
  State<_KhoaPickerBottomSheet> createState() =>
      _KhoaPickerBottomSheetState();
}

class _KhoaPickerBottomSheetState
    extends State<_KhoaPickerBottomSheet> {
  final TextEditingController _searchController =
      TextEditingController();

  String _keyword = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _normalizeText(String value) {
    return value.trim().toLowerCase();
  }

  List<MapEntry<String, String>> get _filteredDanhSach {
    final String keyword = _normalizeText(_keyword);

    final List<MapEntry<String, String>> entries =
        widget.danhSachKhoa.entries.where((entry) {
      if (keyword.isEmpty) {
        return true;
      }

      final String maKhoa = _normalizeText(entry.key);
      final String tenKhoa = _normalizeText(entry.value);

      return maKhoa.contains(keyword) || tenKhoa.contains(keyword);
    }).toList();

    entries.sort(
      (a, b) => a.value.toLowerCase().compareTo(
            b.value.toLowerCase(),
          ),
    );

    return entries;
  }

  String _getFirstLetter(String value) {
    final String text = value.trim();

    if (text.isEmpty) {
      return 'K';
    }

    return text.substring(0, 1).toUpperCase();
  }

  Widget _buildLeadingAvatar({
    required String text,
    bool isAll = false,
  }) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isAll ? Colors.grey.shade200 : Colors.blue.shade50,
        shape: BoxShape.circle,
      ),
      child: isAll
          ? Icon(
              Icons.apartment,
              color: Colors.grey.shade600,
              size: 21,
            )
          : Text(
              _getFirstLetter(text),
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }

  Widget _buildSelectedIcon(bool isSelected) {
    if (!isSelected) {
      return const SizedBox(
        width: 24,
        height: 24,
      );
    }

    return const Icon(
      Icons.check_circle,
      color: Colors.blue,
      size: 22,
    );
  }

  Widget _buildAllKhoaItem() {
    final bool isSelected = widget.selectedMaKhoa.isEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context, '');
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.blue.withOpacity(0.04)
                : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.shade300,
              ),
            ),
          ),
          child: Row(
            children: [
              _buildLeadingAvatar(
                text: 'Tất cả Khoa',
                isAll: true,
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Tất cả Khoa',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _buildSelectedIcon(isSelected),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKhoaItem(
    MapEntry<String, String> entry,
  ) {
    final bool isSelected =
        widget.selectedMaKhoa.trim() == entry.key.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context, entry.key);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.blue.withOpacity(0.04)
                : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.shade300,
              ),
            ),
          ),
          child: Row(
            children: [
              _buildLeadingAvatar(
                text: entry.value,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  entry.value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ),
              _buildSelectedIcon(isSelected),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<MapEntry<String, String>> filteredDanhSach =
        _filteredDanhSach;

    final double keyboardHeight =
        MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        bottom: keyboardHeight,
      ),
      child: FractionallySizedBox(
        heightFactor: 0.82,
        alignment: Alignment.bottomCenter,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(22),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),

              // Thanh kéo
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),

              const SizedBox(height: 14),

              const Text(
                'Chọn Khoa',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 14),

              // Ô tìm kiếm
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _keyword = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm khoa...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Colors.grey,
                    ),
                    suffixIcon: _keyword.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();

                              setState(() {
                                _keyword = '';
                              });
                            },
                            icon: const Icon(
                              Icons.close,
                              size: 19,
                            ),
                          ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Expanded(
                child: filteredDanhSach.isEmpty &&
                        _keyword.trim().isNotEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 42,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Không tìm thấy khoa phù hợp',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView(
                        padding: EdgeInsets.zero,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        children: [
                          if (_keyword.trim().isEmpty)
                            _buildAllKhoaItem(),
                          ...filteredDanhSach.map(
                            _buildKhoaItem,
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}