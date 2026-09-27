import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/chamcong_bosung_model.dart';
import '../../services/chamcong_bosung_service.dart';
import '../../utils/helpers.dart';
import 'cham_cong_bo_sung_web_design.dart';
import 'tao_phieu_bosung_screen.dart';

class ChamCongBoSungListScreen extends StatefulWidget {
  const ChamCongBoSungListScreen({super.key});

  @override
  State<ChamCongBoSungListScreen> createState() =>
      _ChamCongBoSungListScreenState();
}

class _ChamCongBoSungListScreenState extends State<ChamCongBoSungListScreen> {
  final ChamCongBoSungService _apiService = ChamCongBoSungService();

  final Color primaryColor = const Color(0xFF1274BC);

  List<ChamCongBoSung> _listPhieu = [];

  bool _isLoading = true;
  bool _isProcessing = false;

  int? _selectedStatus;

  late DateTime _selectedMonth;

  final List<Map<String, dynamic>> _statusTabs = [
    {'id': null, 'name': 'Tất cả'},
    {'id': 1, 'name': 'Chờ LĐ duyệt'},
    {'id': 2, 'name': 'Chờ KT duyệt'},
    {'id': 4, 'name': 'Hoàn thành'},
    {'id': 3, 'name': 'LĐ từ chối'},
    {'id': 5, 'name': 'KT từ chối'},
  ];

  @override
  void initState() {
    super.initState();

    final DateTime now = DateTime.now();

    _selectedMonth = DateTime(now.year, now.month, 1);

    _fetchData();
  }

  Future<void> _fetchData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    final List<ChamCongBoSung> data = await _apiService.getDanhSachPhieuCaNhan(
      trangThai: _selectedStatus,
      month: _selectedMonth.month,
      year: _selectedMonth.year,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _listPhieu = data;
      _isLoading = false;
    });
  }

  void _changeMonth(int offset) {
    if (_isLoading || _isProcessing) {
      return;
    }

    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + offset,
        1,
      );
    });

    _fetchData();
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

  String _formatNgay(String? value) {
    final DateTime? parsedDate = _parseApiDate(value);

    if (parsedDate == null) {
      return value?.trim().isNotEmpty == true ? value! : 'N/A';
    }

    return DateFormat('dd/MM/yyyy').format(parsedDate);
  }

  String _normalizeCoSoApi(String? coso) {
    final String value = coso?.trim().toUpperCase() ?? '';

    switch (value) {
      case 'PKCM':
      case 'CHANMONG':
        return 'PKCM';

      case 'PKKX':
      case 'KIMXUYEN':
        return 'PKKX';

      case 'PKSD':
      case 'SONDUONG':
        return 'PKSD';

      case 'PKTB':
      case 'THANHBA':
        return 'PKTB';

      case 'BVHV':
      case 'BVHUNGVUONG':
      default:
        return 'BVHV';
    }
  }

  String _getCoSoName(String? coso) {
    final String maCoSo = _normalizeCoSoApi(coso);

    switch (maCoSo) {
      case 'PKCM':
        return 'PK Chấn Mộng';

      case 'PKKX':
        return 'PK Kim Xuyên';

      case 'PKSD':
        return 'PK Sơn Dương';

      case 'PKTB':
        return 'PK Thanh Ba';

      case 'BVHV':
      default:
        return 'BV Hùng Vương';
    }
  }

  Color _getCoSoColor(String? coso) {
    switch (_normalizeCoSoApi(coso)) {
      case 'PKCM':
        return Colors.purple;

      case 'PKKX':
        return Colors.teal;

      case 'PKSD':
        return Colors.indigo;

      case 'PKTB':
        return Colors.deepOrange;

      case 'BVHV':
      default:
        return primaryColor;
    }
  }

  Future<void> _deletePhieu(ChamCongBoSung phieu) async {
    final int? id = phieu.id;

    if (id == null) {
      AppHelpers.showSnackBar('Không xác định được mã phiếu.', isError: true);
      return;
    }

    final bool confirm =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text(
                'Xác nhận xóa',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: const Text(
                'Bạn có chắc chắn muốn xóa phiếu bổ sung này không? '
                'Hành động này không thể hoàn tác.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                  },
                  child: const Text(
                    'Hủy',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    Navigator.pop(dialogContext, true);
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

    if (!confirm || !mounted) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    final bool success = await _apiService.deletePhieu(id);

    if (!mounted) {
      return;
    }

    setState(() {
      _isProcessing = false;
    });

    if (!success) {
      AppHelpers.showSnackBar(
        'Lỗi khi xóa phiếu, vui lòng thử lại!',
        isError: true,
      );
      return;
    }

    AppHelpers.showSnackBar('Đã xóa phiếu thành công!', isError: false);

    await _fetchData();
  }

  Future<void> _editPhieu(ChamCongBoSung phieu) async {
    if (phieu.id == null) {
      AppHelpers.showSnackBar('Không xác định được mã phiếu.', isError: true);
      return;
    }

    final DateTime? ngayThieu = _parseApiDate(phieu.ngaythieu);

    if (ngayThieu == null) {
      AppHelpers.showSnackBar('Ngày thiếu công không hợp lệ.', isError: true);
      return;
    }

    final String coSoApi = _normalizeCoSoApi(phieu.coso);

    final bool? result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TaoPhieuBoSungScreen(
          ngayThieu: DateFormat('dd/MM/yyyy').format(ngayThieu),

          // Bắt buộc truyền cơ sở cho V2.
          coSo: coSoApi,

          editId: phieu.id,
          oldNoiDung: phieu.noidung,
          oldLyDo: phieu.lydo,
          oldTongCong: phieu.tongcong,
        ),
      ),
    );

    if (result == true) {
      await _fetchData();
    }
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 1:
        return Colors.blue;

      case 2:
        return Colors.orange;

      case 3:
        return Colors.red;

      case 4:
        return Colors.green;

      case 5:
        return Colors.red.shade900;

      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(int status) {
    switch (status) {
      case 1:
      case 2:
        return Icons.pending_actions_rounded;

      case 3:
      case 5:
        return Icons.cancel_outlined;

      case 4:
        return Icons.check_circle_outline_rounded;

      default:
        return Icons.info_outline_rounded;
    }
  }

  String _getStatusText(int status) {
    switch (status) {
      case 1:
        return 'Chờ LĐ duyệt';

      case 2:
        return 'Chờ Kế toán duyệt';

      case 3:
        return 'LĐ từ chối';

      case 4:
        return 'Hoàn thành';

      case 5:
        return 'Kế toán từ chối';

      default:
        return 'Không xác định';
    }
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        disabledBackgroundColor: Colors.grey.shade100,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      onPressed: _isProcessing ? null : onTap,
      icon: Icon(icon, size: 16),
      label: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month_rounded, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Tháng ${_selectedMonth.month} '
                'năm ${_selectedMonth.year}',
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
                onPressed: _isLoading || _isProcessing
                    ? null
                    : () => _changeMonth(-1),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                splashRadius: 24,
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: Icon(Icons.chevron_right_rounded, color: primaryColor),
                onPressed: _isLoading || _isProcessing
                    ? null
                    : () => _changeMonth(1),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                splashRadius: 24,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _statusTabs.length,
        itemBuilder: (BuildContext context, int index) {
          final Map<String, dynamic> tab = _statusTabs[index];

          final int? tabId = tab['id'] as int?;

          final String tabName = tab['name']?.toString() ?? '';

          final bool isSelected = _selectedStatus == tabId;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                tabName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              selected: isSelected,
              selectedColor: primaryColor,
              backgroundColor: Colors.white,
              showCheckmark: false,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? primaryColor : Colors.grey.shade300,
                ),
              ),
              onSelected: _isLoading || _isProcessing
                  ? null
                  : (_) {
                      setState(() {
                        _selectedStatus = tabId;
                      });

                      _fetchData();
                    },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 70),
      children: [
        Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(
          'Không có phiếu bổ sung trong tháng này',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Kéo xuống để tải lại dữ liệu',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        ),
      ],
    );
  }

  Widget _buildPhieuList() {
    if (_listPhieu.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 30),
      itemCount: _listPhieu.length,
      itemBuilder: (BuildContext context, int index) {
        final ChamCongBoSung phieu = _listPhieu[index];

        return _buildPhieuCard(phieu);
      },
    );
  }

  Widget _buildPhieuCard(ChamCongBoSung phieu) {
    final int status = phieu.trangthaiduyet ?? 0;

    final Color statusColor = _getStatusColor(status);

    final Color coSoColor = _getCoSoColor(phieu.coso);

    final String ngayThieuHienThi = _formatNgay(phieu.ngaythieu);

    final bool hasTenLdDuyet = phieu.tenLdDuyet?.trim().isNotEmpty == true;

    final bool hasTenKtDuyet = phieu.tenKtDuyet?.trim().isNotEmpty == true;

    final bool hasGhiChu = phieu.ghichu?.trim().isNotEmpty == true;

    final bool canEditAndDelete = status == 1 && phieu.id != null;

    return Card(
      elevation: useChamCongDesktopWeb(context) ? 0 : 2,
      margin: useChamCongDesktopWeb(context)
          ? EdgeInsets.zero
          : const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          useChamCongDesktopWeb(context) ? 16 : 12,
        ),
        side: useChamCongDesktopWeb(context)
            ? const BorderSide(color: ChamCongWebColors.border)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: statusColor,
              width: useChamCongDesktopWeb(context) ? 4 : 5,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.event_rounded, size: 18, color: primaryColor),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      ngayThieuHienThi,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    icon: Icons.location_on_rounded,
                    text: _getCoSoName(phieu.coso),
                    color: coSoColor,
                  ),
                  _buildInfoChip(
                    icon: Icons.work_outline,
                    text: '${phieu.tongcong?.toStringAsFixed(1) ?? '0.0'} công',
                    color: Colors.orange,
                  ),
                  _buildInfoChip(
                    icon: _getStatusIcon(status),
                    text: _getStatusText(status),
                    color: statusColor,
                  ),
                ],
              ),

              const Divider(height: 22),

              _buildTextInfoRow(
                icon: Icons.assignment_rounded,
                label: 'Nội dung',
                value: phieu.noidung,
                valueColor: Colors.black87,
              ),

              const SizedBox(height: 8),

              _buildTextInfoRow(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Lý do',
                value: phieu.lydo,
                valueColor: Colors.black54,
              ),

              if (hasTenLdDuyet || hasTenKtDuyet) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasTenLdDuyet)
                        _buildApproverRow(
                          icon: Icons.person,
                          label: 'LĐ duyệt',
                          value: phieu.tenLdDuyet!,
                          color: Colors.blueGrey,
                        ),

                      if (hasTenLdDuyet && hasTenKtDuyet)
                        const SizedBox(height: 6),

                      if (hasTenKtDuyet)
                        _buildApproverRow(
                          icon: Icons.manage_accounts,
                          label: 'KT duyệt',
                          value: phieu.tenKtDuyet!,
                          color: Colors.green,
                        ),
                    ],
                  ),
                ),
              ],

              if ((status == 3 || status == 5) && hasGhiChu) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 17,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Từ chối: ${phieu.ghichu}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.red,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (canEditAndDelete) ...[
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildActionButton(
                      title: 'Sửa',
                      icon: Icons.edit_outlined,
                      color: Colors.blue,
                      onTap: () {
                        _editPhieu(phieu);
                      },
                    ),
                    const SizedBox(width: 12),
                    _buildActionButton(
                      title: 'Xóa',
                      icon: Icons.delete_outline,
                      color: Colors.red,
                      onTap: () {
                        _deletePhieu(phieu);
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInfoRow({
    required IconData icon,
    required String label,
    required String? value,
    required Color valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label: ${value?.trim().isNotEmpty == true ? value : ''}',
            style: TextStyle(fontSize: 14, color: valueColor),
          ),
        ),
      ],
    );
  }

  Widget _buildApproverRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '$label: $value',
            style: TextStyle(fontSize: 12, color: color),
          ),
        ),
      ],
    );
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
          'Lịch sử bổ sung công',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildMonthSelector(),
              _buildStatusFilter(),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(color: primaryColor),
                      )
                    : RefreshIndicator(
                        color: primaryColor,
                        onRefresh: _fetchData,
                        child: _buildPhieuList(),
                      ),
              ),
            ],
          ),

          if (_isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.08),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: CircularProgressIndicator(color: primaryColor),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWeb(BuildContext context) {
    return ChamCongWebPage(
      title: 'Lịch sử bổ sung công',
      subtitle: 'Theo dõi trạng thái và xử lý các phiếu bổ sung đã gửi',
      icon: Icons.history_rounded,
      maxWidth: 1360,
      actions: [
        IconButton.filledTonal(
          tooltip: 'Làm mới dữ liệu',
          onPressed: _isLoading || _isProcessing ? null : _fetchData,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      child: Stack(
        children: [
          Column(
            children: [
              ChamCongWebCard(
                margin: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: ChamCongWebSectionTitle(
                            title: 'Bộ lọc danh sách',
                            subtitle: 'Chọn tháng và trạng thái cần theo dõi',
                            icon: Icons.filter_alt_outlined,
                          ),
                        ),
                        IconButton.outlined(
                          tooltip: 'Tháng trước',
                          onPressed: _isLoading || _isProcessing
                              ? null
                              : () => _changeMonth(-1),
                          icon: const Icon(Icons.chevron_left_rounded),
                        ),
                        Container(
                          constraints: const BoxConstraints(minWidth: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.center,
                          child: Text(
                            'Tháng ${_selectedMonth.month}/${_selectedMonth.year}',
                            style: const TextStyle(
                              color: ChamCongWebColors.text,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton.outlined(
                          tooltip: 'Tháng sau',
                          onPressed: _isLoading || _isProcessing
                              ? null
                              : () => _changeMonth(1),
                          icon: const Icon(Icons.chevron_right_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _statusTabs.map((tab) {
                        final tabId = tab['id'] as int?;
                        final selected = _selectedStatus == tabId;

                        return ChoiceChip(
                          selected: selected,
                          showCheckmark: false,
                          label: Text(tab['name']?.toString() ?? ''),
                          labelStyle: TextStyle(
                            color: selected
                                ? Colors.white
                                : ChamCongWebColors.muted,
                            fontWeight: FontWeight.w700,
                          ),
                          selectedColor: ChamCongWebColors.primary,
                          backgroundColor: const Color(0xFFF8FAFC),
                          side: BorderSide(
                            color: selected
                                ? ChamCongWebColors.primary
                                : ChamCongWebColors.border,
                          ),
                          onSelected: _isLoading || _isProcessing
                              ? null
                              : (_) {
                                  setState(() => _selectedStatus = tabId);
                                  _fetchData();
                                },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: ChamCongWebColors.primary,
                        ),
                      )
                    : _listPhieu.isEmpty
                    ? const ChamCongWebEmpty(
                        title: 'Chưa có phiếu bổ sung',
                        message:
                            'Không có dữ liệu phù hợp với bộ lọc hiện tại.',
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final cardWidth = constraints.maxWidth >= 1000
                              ? (constraints.maxWidth - 52) / 2
                              : constraints.maxWidth - 40;

                          return SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: _listPhieu
                                  .map(
                                    (item) => SizedBox(
                                      width: cardWidth,
                                      child: _buildPhieuCard(item),
                                    ),
                                  )
                                  .toList(),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          if (_isProcessing)
            Positioned.fill(
              child: ColoredBox(
                color: Color(0x140B426B),
                child: Center(
                  child: ChamCongWebCard(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Đang xử lý...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
