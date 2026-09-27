import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/cme_model.dart';
import '../../models/dao_tao_dashboard_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cme_provider.dart';
import '../../providers/dao_tao_dashboard_provider.dart';

class DaoTaoDashboardScreen extends StatefulWidget {
  final VoidCallback onOpenClasses;
  final VoidCallback onOpenInternalPractice;
  final VoidCallback onOpenExternalPractice;
  final VoidCallback onOpenCme;

  const DaoTaoDashboardScreen({
    super.key,
    required this.onOpenClasses,
    required this.onOpenInternalPractice,
    required this.onOpenExternalPractice,
    required this.onOpenCme,
  });

  @override
  State<DaoTaoDashboardScreen> createState() => _DaoTaoDashboardScreenState();
}

class _DaoTaoDashboardScreenState extends State<DaoTaoDashboardScreen> {
  static const _blue = Color(0xFF087DBA);
  static const _navy = Color(0xFF123D58);
  static const _orange = Color(0xFFF39A35);
  static const _green = Color(0xFF26A27B);

  bool get _canApproveCme =>
      context.read<AuthProvider>().currentRoleIds.contains(36);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _canApproveCme) {
        context.read<CmeProvider>().loadDashboard(
          canApprove: true,
          soNgaySapHetHan: 60,
          gioiHan: 6,
        );
      }
    });
  }

  Future<void> _refresh() async {
    final tasks = <Future<void>>[
      context.read<DaoTaoDashboardProvider>().load(),
    ];
    if (_canApproveCme) {
      tasks.add(
        context.read<CmeProvider>().loadDashboard(
          canApprove: true,
          soNgaySapHetHan: 60,
          gioiHan: 6,
        ),
      );
    }
    await Future.wait(tasks);
  }

  Future<void> _export() async {
    final provider = context.read<DaoTaoDashboardProvider>();
    final file = await provider.exportExcel();
    if (!mounted) return;
    if (file == null) {
      _snack(provider.error ?? 'Không thể xuất báo cáo Excel.', error: true);
      return;
    }
    await FilePicker.platform.saveFile(
      dialogTitle: 'Lưu báo cáo đào tạo',
      fileName: file.fileName,
      type: FileType.custom,
      allowedExtensions: const ['xlsx'],
      bytes: file.bytes,
    );
    if (mounted) _snack('Đã tạo báo cáo Excel nhiều sheet.');
  }

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? const Color(0xFFD45151) : _green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DaoTaoDashboardProvider>();
    final cme = context.watch<CmeProvider>();
    final data = provider.dashboard;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FA),
      body: Column(
        children: [
          _header(provider, data),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 36),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1600),
                    child: data == null
                        ? _initialState(provider)
                        : _dashboard(data, cme),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(DaoTaoDashboardProvider provider, DaoTaoDashboardModel? data) {
    final timestamp = data?.thoiDiemThongKe;
    final canExport = context.read<AuthProvider>().currentRoleIds.any(
      const <int>{47, 48, 49, 50}.contains,
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF063B5A), Color(0xFF087DBA)],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x26063B5A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.space_dashboard_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dashboard Đào tạo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  timestamp == null
                      ? 'Tổng hợp lớp đào tạo và hoạt động thực hành'
                      : 'Số liệu cập nhật ${DateFormat('HH:mm, dd/MM/yyyy').format(timestamp.toLocal())}',
                  style: const TextStyle(
                    color: Color(0xFFD5ECF8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (canExport) ...[
            OutlinedButton.icon(
              onPressed: provider.exporting ? null : _export,
              icon: provider.exporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.file_download_outlined),
              label: const Text('Xuất Excel chi tiết'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0x99FFFFFF)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          IconButton.filledTonal(
            onPressed: provider.loading ? null : _refresh,
            tooltip: 'Làm mới',
            icon: provider.loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }

  Widget _initialState(DaoTaoDashboardProvider provider) {
    if (provider.loading) {
      return const SizedBox(
        height: 420,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return _panel(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 48,
                color: Colors.grey,
              ),
              const SizedBox(height: 12),
              Text(provider.error ?? 'Chưa có dữ liệu dashboard.'),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: provider.load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tải lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dashboard(DaoTaoDashboardModel data, CmeProvider cme) {
    final urgent =
        data.thucHanhNoiBo.ketThucNgayMai +
        data.thucHanhNgoaiVien.ketThucNgayMai;
    final active =
        data.thucHanhNoiBo.dangThucHanh + data.thucHanhNgoaiVien.dangThucHanh;
    final people =
        data.thucHanhNoiBo.tongHoSo + data.thucHanhNgoaiVien.tongNguoiThucHanh;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (_, constraints) {
            final width = constraints.maxWidth >= 1100
                ? (constraints.maxWidth - 48) / 4
                : constraints.maxWidth >= 650
                ? (constraints.maxWidth - 16) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _kpi(
                  'Tổng người theo dõi',
                  people,
                  Icons.groups_2_outlined,
                  _blue,
                  width,
                ),
                _kpi(
                  'Đang thực hành',
                  active,
                  Icons.play_circle_outline_rounded,
                  _green,
                  width,
                ),
                _kpi(
                  'Kết thúc ngày mai',
                  urgent,
                  Icons.notification_important_outlined,
                  const Color(0xFFD9534F),
                  width,
                ),
                _kpi(
                  'CME cần xử lý',
                  _canApproveCme
                      ? cme.dashboardSummary.pendingCount +
                            cme.dashboardSummary.expiringCount
                      : 0,
                  Icons.workspace_premium_outlined,
                  _orange,
                  width,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        if (data.coQuyenLopDaoTao) ...[
          _classSection(data.lopDaoTao),
          const SizedBox(height: 20),
        ],
        if (_canApproveCme) ...[_cmeSection(cme), const SizedBox(height: 20)],
        if (data.coQuyenThucHanhNoiBo) ...[
          _internalSection(data.thucHanhNoiBo),
          const SizedBox(height: 20),
        ],
        if (data.coQuyenThucHanhNgoaiVien)
          _externalSection(data.thucHanhNgoaiVien),
      ],
    );
  }

  Widget _kpi(
    String label,
    int value,
    IconData icon,
    Color color,
    double width,
  ) {
    return SizedBox(
      width: width,
      child: _panel(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .11),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$value',
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        color: _navy,
                      ),
                    ),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF607889),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _classSection(DaoTaoLopDashboardModel value) {
    return _section(
      icon: Icons.class_outlined,
      title: 'Lớp đào tạo',
      subtitle: 'Tiến độ mở lớp và lượt đăng ký',
      color: _blue,
      onOpen: widget.onOpenClasses,
      child: _metricWrap([
        ('Tổng số lớp', value.tongSoLop, _blue),
        ('Đang mở đăng ký', value.dangMoDangKy, _green),
        ('Đang diễn ra', value.dangDienRa, const Color(0xFF6A5ACD)),
        ('Sắp diễn ra', value.sapDienRa, _orange),
        ('Đã kết thúc', value.daKetThuc, const Color(0xFF667783)),
        ('Tổng lượt đăng ký', value.tongLuotDangKy, const Color(0xFFB34C88)),
      ]),
    );
  }

  Widget _cmeSection(CmeProvider provider) {
    final value = provider.dashboardSummary;
    return _section(
      icon: Icons.workspace_premium_outlined,
      title: 'CME cần chú ý',
      subtitle: 'Yêu cầu chờ duyệt và chứng chỉ sắp hết hạn',
      color: _orange,
      onOpen: widget.onOpenCme,
      child: provider.isLoadingDashboard && !value.hasNotifications
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          : Column(
              children: [
                _metricWrap([
                  (
                    'Yêu cầu chờ duyệt',
                    value.pendingCount,
                    const Color(0xFFD87520),
                  ),
                  (
                    'Chứng chỉ sắp hết hạn',
                    value.expiringCount,
                    const Color(0xFFD34D4D),
                  ),
                ]),
                if (value.yeuCauChoDuyet.isNotEmpty ||
                    value.chungChiSapHetHan.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  ...value.yeuCauChoDuyet.take(3).map(_cmeRequestRow),
                  ...value.chungChiSapHetHan.take(3).map(_cmeExpiryRow),
                ],
              ],
            ),
    );
  }

  Widget _cmeRequestRow(CmeRequestModel item) => _noticeRow(
    icon: Icons.pending_actions_outlined,
    color: _orange,
    title: item.tenNguoiGui?.trim().isNotEmpty == true
        ? item.tenNguoiGui!.trim()
        : item.maSoNguoiGui,
    detail: '${item.tenChungChi} • chờ duyệt',
    trailing: DateFormat('dd/MM').format(item.ngayGui),
    onTap: widget.onOpenCme,
  );

  Widget _cmeExpiryRow(CmeExpiringCertificate item) => _noticeRow(
    icon: Icons.event_busy_outlined,
    color: const Color(0xFFD34D4D),
    title: item.employeeName.isEmpty ? item.maSo : item.employeeName,
    detail: '${item.tenChungChi} • ${item.departmentName}',
    trailing: item.soNgayConLai == null ? '--' : '${item.soNgayConLai} ngày',
    onTap: widget.onOpenCme,
  );

  Widget _internalSection(DaoTaoCapCchnDashboardModel value) {
    final maxProfiles = value.theoLoaiNhanVien.fold<int>(
      0,
      (maximum, item) => item.tongHoSo > maximum ? item.tongHoSo : maximum,
    );
    return _section(
      icon: Icons.medical_information_outlined,
      title: 'Quản lý thực hành nội bộ',
      subtitle: 'Ghép Mã số với Nhân viên và phân tích theo Loại nhân viên',
      color: const Color(0xFF3973C6),
      onOpen: widget.onOpenInternalPractice,
      child: Column(
        children: [
          _metricWrap([
            ('Tổng hồ sơ', value.tongHoSo, _blue),
            (
              'Tổng đợt hướng dẫn',
              value.tongDotHuongDan,
              const Color(0xFF4D69A7),
            ),
            ('Đang thực hành', value.dangThucHanh, _green),
            ('Sắp kết thúc 7 ngày', value.sapKetThuc7Ngay, _orange),
            (
              'Kết thúc ngày mai',
              value.ketThucNgayMai,
              const Color(0xFFD34D4D),
            ),
            (
              'Đợt đã hoàn thành',
              value.dotDaHoanThanh,
              const Color(0xFF607889),
            ),
            ('Chưa phân công', value.chuaPhanCong, const Color(0xFF7A67B7)),
            ('Hồ sơ chưa đủ', value.hoSoChuaDayDu, const Color(0xFFB06D3E)),
          ]),
          if (value.theoLoaiNhanVien.isNotEmpty) ...[
            const SizedBox(height: 18),
            _subheading('Cơ cấu theo loại nhân viên'),
            const SizedBox(height: 10),
            ...value.theoLoaiNhanVien.map(
              (item) => _professionBar(item, maxProfiles),
            ),
          ],
          if (value.canhBaoSapKetThuc.isNotEmpty) ...[
            const SizedBox(height: 18),
            _subheading('Các đợt sắp kết thúc'),
            const SizedBox(height: 8),
            ...value.canhBaoSapKetThuc.map(
              (item) => _practiceAlert(item, widget.onOpenInternalPractice),
            ),
          ],
        ],
      ),
    );
  }

  Widget _externalSection(DaoTaoNgoaiVienDashboardModel value) {
    return _section(
      icon: Icons.badge_outlined,
      title: 'Quản lý sinh viên',
      subtitle: 'Đăng ký, phân công và tiến độ thực hành',
      color: const Color(0xFF9C5CBB),
      onOpen: widget.onOpenExternalPractice,
      child: Column(
        children: [
          _metricWrap([
            ('Tổng số người', value.tongNguoiThucHanh, const Color(0xFF9C5CBB)),
            (
              'Tổng đợt thực hành',
              value.tongDotThucHanh,
              const Color(0xFF7657A6),
            ),
            ('Đợt đang mở', value.dotDangMoDangKy, _green),
            ('Tổng đăng ký', value.tongDangKy, const Color(0xFF4D69A7)),
            ('Chưa phân công', value.dangKyChuaPhanCong, _orange),
            ('Đang thực hành', value.dangThucHanh, _blue),
            (
              'Sắp kết thúc 7 ngày',
              value.sapKetThuc7Ngay,
              const Color(0xFFD87520),
            ),
            (
              'Kết thúc ngày mai',
              value.ketThucNgayMai,
              const Color(0xFFD34D4D),
            ),
            ('Đã hoàn thành', value.daHoanThanh, const Color(0xFF607889)),
          ]),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _sourceTile(
                  'Đăng ký ngoài',
                  value.dangKyTuBenNgoai,
                  Icons.public_rounded,
                  _blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _sourceTile(
                  'Nhập thủ công',
                  value.dangKyNhapThuCong,
                  Icons.edit_note_rounded,
                  const Color(0xFF7A67B7),
                ),
              ),
            ],
          ),
          if (value.canhBaoSapKetThuc.isNotEmpty) ...[
            const SizedBox(height: 18),
            _subheading('Người sắp kết thúc thực hành'),
            const SizedBox(height: 8),
            ...value.canhBaoSapKetThuc.map(
              (item) => _practiceAlert(item, widget.onOpenExternalPractice),
            ),
          ],
        ],
      ),
    );
  }

  Widget _section({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Widget child,
    required VoidCallback onOpen,
  }) {
    return _panel(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 17, 12, 13),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .11),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _navy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF718593),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Mở quản lý'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(18), child: child),
        ],
      ),
    );
  }

  Widget _metricWrap(List<(String, int, Color)> metrics) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final count = constraints.maxWidth >= 1050
            ? 6
            : constraints.maxWidth >= 700
            ? 3
            : 2;
        final width = (constraints.maxWidth - (count - 1) * 10) / count;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: metrics
              .map(
                (metric) => SizedBox(
                  width: width,
                  child: Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: metric.$3.withValues(alpha: .065),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: metric.$3.withValues(alpha: .14),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${metric.$2}',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            color: metric.$3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          metric.$1,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF526B7A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _professionBar(DaoTaoLoaiNhanVienDashboardModel item, int maximum) {
    final progress = maximum == 0 ? 0.0 : item.tongHoSo / maximum;
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(
              item.tenLoaiNhanVien.isEmpty
                  ? 'Chưa xác định'
                  : item.tenLoaiNhanVien,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, color: _navy),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 9,
                backgroundColor: const Color(0xFFE9F0F4),
                color: _blue,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 170,
            child: Text(
              '${item.tongHoSo} hồ sơ  •  ${item.dangThucHanh} đang học',
              style: const TextStyle(fontSize: 12, color: Color(0xFF607889)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _practiceAlert(DaoTaoCanhBaoDashboardModel item, VoidCallback onTap) {
    final urgent = item.soNgayConLai <= 1;
    return _noticeRow(
      icon: urgent
          ? Icons.notification_important_outlined
          : Icons.schedule_rounded,
      color: urgent ? const Color(0xFFD34D4D) : _orange,
      title: item.hoVaTen,
      detail: [
        item.loaiNhanVien,
        item.khoaPhong,
        item.nguoiHuongDan,
        item.tenDot,
      ].where((e) => e.isNotEmpty).join(' • '),
      trailing: item.soNgayConLai <= 0
          ? 'Hôm nay'
          : item.soNgayConLai == 1
          ? 'Ngày mai'
          : '${item.soNgayConLai} ngày',
      onTap: onTap,
    );
  }

  Widget _noticeRow({
    required IconData icon,
    required Color color,
    required String title,
    required String detail,
    required String trailing,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.isEmpty ? 'Chưa có tên' : title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _navy,
                        ),
                      ),
                      if (detail.isNotEmpty)
                        Text(
                          detail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF6D808D),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    trailing,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sourceTile(String label, int value, IconData icon, Color color) =>
      Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAFC),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: _navy,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$value',
              style: TextStyle(
                color: color,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );

  Widget _subheading(String title) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: _navy,
      ),
    ),
  );

  Widget _panel({required Widget child}) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0xFFE2EBF0)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0B16384E),
          blurRadius: 18,
          offset: Offset(0, 7),
        ),
      ],
    ),
    child: child,
  );
}
