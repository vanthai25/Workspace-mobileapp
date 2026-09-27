import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/cham_cong_tang_ca_model.dart';
import '../../providers/cham_cong_tang_ca_provider.dart';
import '../../utils/helpers.dart';

class ChamCongTangCaDuyetKhoaScreen extends StatefulWidget {
  const ChamCongTangCaDuyetKhoaScreen({Key? key}) : super(key: key);

  @override
  State<ChamCongTangCaDuyetKhoaScreen> createState() =>
      _ChamCongTangCaDuyetKhoaScreenState();
}

class _ChamCongTangCaDuyetKhoaScreenState
    extends State<ChamCongTangCaDuyetKhoaScreen> {
  DateTime _selectedMonth = DateTime.now();

  // 0: Chờ Khoa duyệt
  // 1: Khoa đã duyệt
  // 3: Từ chối
  // null: Tất cả
  int? _selectedStatus = 0;

  final Set<int> _selectedIds = {};

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChamCongTangCaProvider>().fetchDanhSach();
    });
  }

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

  bool _isKhoaRejected(ChamCongTangCaModel phieu) {
    return phieu.trangThaiDuyet == 3 &&
        (phieu.ldBVDuyet == null ||
            phieu.ldBVDuyet!.trim().isEmpty);
  }

  bool _isBVRejected(ChamCongTangCaModel phieu) {
    return phieu.trangThaiDuyet == 3 &&
        phieu.ldBVDuyet != null &&
        phieu.ldBVDuyet!.trim().isNotEmpty;
  }

  bool _canSelect(ChamCongTangCaModel phieu) {
    return phieu.trangThaiDuyet == 0;
  }

  List<ChamCongTangCaModel> _filterDanhSach(
    List<ChamCongTangCaModel> danhSach,
  ) {
    return danhSach.where((phieu) {
      if (_selectedStatus != null &&
          phieu.trangThaiDuyet != _selectedStatus) {
        return false;
      }

      if (phieu.batDau.year != _selectedMonth.year ||
          phieu.batDau.month != _selectedMonth.month) {
        return false;
      }

      return true;
    }).toList();
  }

  String _getTrangThaiText(ChamCongTangCaModel phieu) {
    switch (phieu.trangThaiDuyet) {
      case 0:
        return 'Chờ Khoa duyệt';
      case 1:
        return 'Khoa đã duyệt';
      case 2:
        return 'Bệnh viện đã duyệt';
      case 3:
        if (_isKhoaRejected(phieu)) {
          return 'Khoa từ chối';
        }

        if (_isBVRejected(phieu)) {
          return 'Bệnh viện từ chối';
        }

        return 'Đã từ chối';
      default:
        return 'Không xác định';
    }
  }

  Color _getTrangThaiColor(ChamCongTangCaModel phieu) {
    switch (phieu.trangThaiDuyet) {
      case 0:
        return Colors.orange;
      case 1:
        return Colors.blue;
      case 2:
        return Colors.green;
      case 3:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildTrangThaiBadge(ChamCongTangCaModel phieu) {
    final color = _getTrangThaiColor(phieu);

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

  Widget _buildThongTinDuyet(ChamCongTangCaModel phieu) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    final tenLDKhoa = phieu.tenLDKhoaDuyet?.trim();
    final tenLDBV = phieu.tenLDBVDuyet?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tenLDKhoa != null && tenLDKhoa.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '👤 LĐ Khoa xử lý: $tenLDKhoa',
            style: const TextStyle(
              color: Colors.blueGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (phieu.ngayLDKhoaDuyet != null)
            Padding(
              padding: const EdgeInsets.only(
                left: 24,
                top: 2,
              ),
              child: Text(
                dateFormat.format(phieu.ngayLDKhoaDuyet!),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ),
        ],
        if (tenLDBV != null && tenLDBV.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '👤 LĐ Bệnh viện xử lý: $tenLDBV',
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (phieu.ngayLDBVDuyet != null)
            Padding(
              padding: const EdgeInsets.only(
                left: 24,
                top: 2,
              ),
              child: Text(
                dateFormat.format(phieu.ngayLDBVDuyet!),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ),
        ],
        if (phieu.trangThaiDuyet == 3) ...[
          const SizedBox(height: 8),
          Text(
            '❌ Lý do từ chối: '
            '${phieu.lyDoTuChoi?.trim().isNotEmpty == true ? phieu.lyDoTuChoi : "Không có lý do"}',
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFilterChip(
    String label,
    int? statusValue,
  ) {
    final isSelected = _selectedStatus == statusValue;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: Colors.blue.withOpacity(0.18),
        backgroundColor: Colors.grey.shade100,
        side: BorderSide(
          color: isSelected
              ? Colors.blue
              : Colors.transparent,
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

  Future<bool> _showConfirmDialog({
    required String title,
    required String content,
    Color confirmColor = Colors.blue,
  }) async {
    final result = await showDialog<bool>(
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
                style: TextStyle(color: confirmColor),
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
    final controller = TextEditingController();

    final result = await showDialog<String>(
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
                final lyDo = controller.text.trim();

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
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    controller.dispose();
    return result;
  }

  Future<void> _xuLyPhieu(
    int id,
    int newStatus,
    String tenHanhDong,
  ) async {
    if (_isProcessing) return;

    String lyDoTuChoi = '';

    if (newStatus == 3) {
      final lyDo = await _showRejectDialog(
        title: 'Từ chối phiếu',
        hintText: 'Nhập lý do từ chối...',
      );

      if (lyDo == null) return;

      lyDoTuChoi = lyDo;
    } else {
      final confirmed = await _showConfirmDialog(
        title: 'Xác nhận $tenHanhDong',
        content:
            'Bạn có chắc chắn muốn $tenHanhDong phiếu này?',
        confirmColor: newStatus == 0
            ? Colors.orange
            : Colors.green,
      );

      if (!confirmed) return;
    }

    if (!mounted) return;

    setState(() {
      _isProcessing = true;
    });

    final success = await context
        .read<ChamCongTangCaProvider>()
        .duyetPhieu(
          id,
          newStatus,
          capDuyet: 'KHOA',
          lyDoTuChoi: lyDoTuChoi,
        );

    if (!mounted) return;

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

  Future<void> _duyetNhieu() async {
    if (_selectedIds.isEmpty || _isProcessing) return;

    final confirmed = await _showConfirmDialog(
      title: 'Duyệt nhiều phiếu',
      content:
          'Bạn có chắc chắn muốn duyệt ${_selectedIds.length} phiếu đã chọn?',
      confirmColor: Colors.green,
    );

    if (!confirmed || !mounted) return;

    setState(() {
      _isProcessing = true;
    });

    final success = await context
        .read<ChamCongTangCaProvider>()
        .duyetNhieu(
          ids: Set<int>.from(_selectedIds),
          newStatus: 1,
          capDuyet: 'KHOA',
        );

    if (!mounted) return;

    setState(() {
      _isProcessing = false;

      if (success) {
        _selectedIds.clear();
      }
    });

    if (success) {
      AppHelpers.showSnackBar(
        'Đã duyệt các phiếu được chọn',
      );
    }
  }

  Future<void> _tuChoiNhieu() async {
    if (_selectedIds.isEmpty || _isProcessing) return;

    final lyDo = await _showRejectDialog(
      title: 'Từ chối nhiều phiếu',
      hintText:
          'Nhập lý do từ chối chung cho các phiếu...',
    );

    if (lyDo == null || !mounted) return;

    setState(() {
      _isProcessing = true;
    });

    final success = await context
        .read<ChamCongTangCaProvider>()
        .duyetNhieu(
          ids: Set<int>.from(_selectedIds),
          newStatus: 3,
          capDuyet: 'KHOA',
          lyDoTuChoi: lyDo,
        );

    if (!mounted) return;

    setState(() {
      _isProcessing = false;

      if (success) {
        _selectedIds.clear();
      }
    });

    if (success) {
      AppHelpers.showSnackBar(
        'Đã từ chối các phiếu được chọn',
      );
    }
  }

  bool? _getSelectAllValue(Set<int> selectableIds) {
    if (selectableIds.isEmpty) return false;

    final selectedCount = selectableIds
        .where(_selectedIds.contains)
        .length;

    if (selectedCount == 0) return false;

    if (selectedCount == selectableIds.length) {
      return true;
    }

    return null;
  }

  Widget _buildPhieuCard(
    ChamCongTangCaModel phieu,
  ) {
    final canSelect = _canSelect(phieu);
    final isSelected = _selectedIds.contains(phieu.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? Colors.blue
              : Colors.grey.shade200,
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
                    child: Text(
                      '${phieu.tenNV} - ${phieu.tenKhoa}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildTrangThaiBadge(phieu),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '📅 Ngày lập: '
              '${DateFormat('dd/MM/yyyy HH:mm').format(phieu.ngayLap)}',
            ),
            const SizedBox(height: 4),
            Text(
              '⏰ ${DateFormat('dd/MM/yyyy HH:mm').format(phieu.batDau)}'
              ' - ${DateFormat('dd/MM/yyyy HH:mm').format(phieu.ketThuc)}',
            ),
            const SizedBox(height: 4),
            Text('⌛ Tổng: ${phieu.soPhut} phút'),
            const SizedBox(height: 4),
            Text('📝 Lý do: ${phieu.lyDoTangCa}'),
            _buildThongTinDuyet(phieu),

            // Phiếu mới: Khoa duyệt hoặc từ chối
            if (phieu.trangThaiDuyet == 0) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isProcessing
                        ? null
                        : () => _xuLyPhieu(
                              phieu.id,
                              3,
                              'Từ chối',
                            ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(
                        color: Colors.red,
                      ),
                    ),
                    child: const Text('Từ chối'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isProcessing
                        ? null
                        : () => _xuLyPhieu(
                              phieu.id,
                              1,
                              'Duyệt',
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text(
                      'Duyệt phiếu',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],

            // Khoa đã duyệt nhưng BV chưa xử lý
            if (phieu.trangThaiDuyet == 1) ...[
              const Divider(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _isProcessing
                      ? null
                      : () => _xuLyPhieu(
                            phieu.id,
                            0,
                            'Hủy duyệt',
                          ),
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

            // Phiếu do Khoa từ chối được phép duyệt lại
            if (_isKhoaRejected(phieu)) ...[
              const Divider(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing
                      ? null
                      : () => _xuLyPhieu(
                            phieu.id,
                            1,
                            'Duyệt lại',
                          ),
                  icon: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Duyệt lại',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ),
            ],

            // BV đã từ chối thì Khoa chỉ được xem
            if (_isBVRejected(phieu)) ...[
              const Divider(height: 24),
              const Text(
                'Phiếu đã được Lãnh đạo Bệnh viện xử lý, '
                'Khoa không thể thay đổi.',
                style: TextStyle(
                  color: Colors.red,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider =
        context.watch<ChamCongTangCaProvider>();

    final filteredList =
        _filterDanhSach(provider.danhSachPhieu);

    final selectableIds = filteredList
        .where(_canSelect)
        .map((phieu) => phieu.id)
        .toSet();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Khoa Duyệt Tăng Ca'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(
              16,
              12,
              16,
              8,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
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
                  onPressed: _previousMonth,
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    size: 16,
                    color: Colors.blue,
                  ),
                ),
                IconButton(
                  onPressed: _nextMonth,
                  icon: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            child: Row(
              children: [
                _buildFilterChip('Tất cả', null),
                _buildFilterChip('Chờ duyệt', 0),
                _buildFilterChip('Đã duyệt', 1),
                _buildFilterChip('Từ chối', 3),
              ],
            ),
          ),
          if (selectableIds.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(
                12,
                4,
                12,
                0,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: CheckboxListTile(
                dense: true,
                tristate: true,
                controlAffinity:
                    ListTileControlAffinity.leading,
                value: _getSelectAllValue(selectableIds),
                title: Text(
                  'Chọn tất cả phiếu chờ duyệt '
                  '(${selectableIds.length})',
                ),
                onChanged: _isProcessing
                    ? null
                    : (checked) {
                        setState(() {
                          if (checked == true) {
                            _selectedIds.addAll(
                              selectableIds,
                            );
                          } else {
                            _selectedIds.removeAll(
                              selectableIds,
                            );
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
                      child: Text(
                        provider.errorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ),
                  );
                }

                if (filteredList.isEmpty) {
                  return const Center(
                    child: Text('Không có phiếu nào.'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    _selectedIds.clear();
                    await context
                        .read<ChamCongTangCaProvider>()
                        .fetchDanhSach();
                  },
                  child: ListView.builder(
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
      bottomNavigationBar: _selectedIds.isEmpty
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
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
                        onPressed: _isProcessing
                            ? null
                            : _tuChoiNhieu,
                        icon: const Icon(Icons.close),
                        label: Text(
                          'Từ chối (${_selectedIds.length})',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing
                            ? null
                            : _duyetNhieu,
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