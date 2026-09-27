import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/cap_cchn_models.dart';

class CapCchnDetailDialog extends StatefulWidget {
  final CapCchnModel item;
  final Future<void> Function(String type, CapCchnFileModel file) onDownload;

  const CapCchnDetailDialog({
    super.key,
    required this.item,
    required this.onDownload,
  });

  @override
  State<CapCchnDetailDialog> createState() => _CapCchnDetailDialogState();
}

class _CapCchnDetailDialogState extends State<CapCchnDetailDialog> {
  static const Color _navy = Color(0xFF173B52);
  static const Color _primary = Color(0xFF087DBA);
  String? _downloadingType;

  CapCchnModel get item => widget.item;

  Future<void> _download(String type, CapCchnFileModel file) async {
    if (_downloadingType != null) return;
    setState(() => _downloadingType = type);
    try {
      await widget.onDownload(type, file);
    } finally {
      if (mounted) setState(() => _downloadingType = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final bool compact = size.width < 700;
    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 32,
        vertical: compact ? 12 : 28,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 920, maxHeight: size.height * .9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _header(compact),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(compact ? 16 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _overview(compact),
                    const SizedBox(height: 20),
                    _sectionTitle(
                      Icons.person_outline,
                      'Thông tin người thực hành',
                    ),
                    const SizedBox(height: 10),
                    _personalInfo(),
                    const SizedBox(height: 20),
                    _sectionTitle(Icons.route_outlined, 'Các đợt hướng dẫn'),
                    const SizedBox(height: 10),
                    _periods(),
                    const SizedBox(height: 20),
                    _sectionTitle(Icons.fact_check_outlined, 'Hồ sơ cần có'),
                    const SizedBox(height: 10),
                    _documents(),
                    const SizedBox(height: 20),
                    _sectionTitle(Icons.attach_file_rounded, 'File đính kèm'),
                    const SizedBox(height: 10),
                    _attachments(),
                  ],
                ),
              ),
            ),
            _actions(),
          ],
        ),
      ),
    );
  }

  Widget _header(bool compact) {
    final _StatusVisual status = _statusOf(item);
    final String name = item.hoVaTen?.trim().isNotEmpty == true
        ? item.hoVaTen!.trim()
        : 'Chưa có tên';
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(compact ? 16 : 24, 20, 12, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[Color(0xFF0A6DA2), Color(0xFF174A68)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: compact ? 25 : 30,
            backgroundColor: Colors.white.withValues(alpha: .18),
            child: Text(
              name.substring(0, 1).toUpperCase(),
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 20 : 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 18 : 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.maSo.trim().isEmpty
                      ? 'Chưa được cấp mã số nhân viên'
                      : '${item.maSo}  •  Tình trạng: ${item.idTinhTrang ?? '-'}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .82),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 9),
                _statusPill(status, onDark: true),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            tooltip: 'Đóng',
          ),
        ],
      ),
    );
  }

  Widget _overview(bool compact) {
    final List<Widget> stats = <Widget>[
      _metric(
        Icons.play_circle_outline_rounded,
        '${item.soDotDangThucHanh}',
        'Đang thực hành',
        const Color(0xFF16845E),
      ),
      _metric(
        Icons.history_toggle_off_rounded,
        '${item.soDotSapKetThuc}',
        'Sắp kết thúc',
        const Color(0xFFE07920),
      ),
      _metric(
        Icons.task_alt_rounded,
        '${item.soDotDaHoanThanh}',
        'Đã hoàn thành',
        const Color(0xFF7357B5),
      ),
      _metric(
        Icons.event_available_outlined,
        '${item.soDotSapBatDau}',
        'Sắp bắt đầu',
        _primary,
      ),
    ];
    return Column(
      children: <Widget>[
        GridView.count(
          crossAxisCount: compact ? 2 : 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: compact ? 1.55 : 1.45,
          children: stats,
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F8FA),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E9EE)),
          ),
          child: Wrap(
            spacing: 24,
            runSpacing: 12,
            children: <Widget>[
              _info('Tổ/đội', item.tenToDoi),
              _info('Chức danh', item.tenChucDanh),
              _info('Chức vụ', item.tenChucVu),
              _info(
                'Cập nhật gần nhất',
                item.ngayUD == null
                    ? null
                    : DateFormat('dd/MM/yyyy HH:mm').format(item.ngayUD!),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _periods() {
    if (item.nguoiHuongDans.isEmpty) {
      return _emptyBlock(
        Icons.person_add_alt_1_outlined,
        'Chưa phân công đợt hướng dẫn nào.',
      );
    }
    final List<CapCchnMentorModel> periods =
        <CapCchnMentorModel>[...item.nguoiHuongDans]
          ..sort((CapCchnMentorModel a, CapCchnMentorModel b) {
            final int aPriority = _periodStatus(a).priority;
            final int bPriority = _periodStatus(b).priority;
            if (aPriority != bPriority) return aPriority.compareTo(bPriority);
            return (b.ngayKetThuc ?? DateTime(1900)).compareTo(
              a.ngayKetThuc ?? DateTime(1900),
            );
          });
    return Column(
      children: periods
          .map((CapCchnMentorModel period) => _periodCard(period))
          .toList(),
    );
  }

  Widget _personalInfo() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF7FAFC),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE0E8EE)),
    ),
    child: Wrap(
      spacing: 24,
      runSpacing: 14,
      children: <Widget>[
        _info('Ngày sinh', _date(item.ngaySinh)),
        _info(
          'Giới tính',
          item.gioiTinh == null
              ? null
              : item.gioiTinh!
              ? 'Nam'
              : 'Nữ',
        ),
        _info('Số CCCD', item.soCCCD),
        _info('Ngày cấp CCCD', _date(item.ngayCapCCCD)),
        _info('Số điện thoại', item.soDienThoai),
        _info('Loại nhân viên', item.tenLoaiNhanVien),
        _info('Trình độ chuyên môn', item.trinhDoChuyenMon),
        _info('Trường/đơn vị', item.truongDonVi),
        _info(
          'Thời gian thực hành',
          item.ngayBatDauThucHanh == null
              ? null
              : '${_date(item.ngayBatDauThucHanh)} – ${_date(item.ngayKetThucThucHanh)}',
        ),
        _info(
          'Học phí',
          item.hocPhi == null
              ? null
              : NumberFormat('#,##0').format(item.hocPhi),
        ),
        _info('Hộ khẩu thường trú', item.diaChiThuongTru),
        _info('Ghi chú', item.ghiChu),
      ],
    ),
  );

  Widget _periodCard(CapCchnMentorModel period) {
    final _PeriodVisual status = _periodStatus(period);
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: .055),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: status.color.withValues(alpha: .28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(status.icon, color: status.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        period.hoVaTen?.trim().isNotEmpty == true
                            ? period.hoVaTen!.trim()
                            : period.maSo,
                        style: const TextStyle(
                          color: _navy,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _smallPill(status.label, status.color),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  period.tenKhoaPhong?.trim().isNotEmpty == true
                      ? period.tenKhoaPhong!.trim()
                      : 'Chưa có khoa/phòng thực hành',
                  style: const TextStyle(
                    color: Color(0xFF607584),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.date_range_outlined,
                      size: 15,
                      color: Color(0xFF7C8F9B),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        '${_date(period.ngayBatDau)}  →  ${_date(period.ngayKetThuc)}',
                        style: const TextStyle(
                          color: Color(0xFF526B7A),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _documents() {
    final List<(String, bool)> documents = <(String, bool)>[
      ('Đề nghị thực hành', item.isDeNghiTH),
      ('Sơ yếu lý lịch', item.isSoYeuLL),
      ('CCCD', item.isCCCD),
      ('Văn bằng chuyên môn', item.isVanBangCM),
      ('Ảnh 3x4', item.isAnh34),
      ('Nhật ký thực hành', item.isNhatKyTH),
      ('Báo cáo thực hành', item.isBaoCaoTH),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: documents.map(((String, bool) entry) {
        final bool done = entry.$2;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            color: done ? const Color(0xFFEAF7F1) : const Color(0xFFF3F5F6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: done ? const Color(0xFFBDE4D3) : const Color(0xFFE0E5E8),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                done ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 17,
                color: done ? const Color(0xFF16845E) : const Color(0xFF98A5AD),
              ),
              const SizedBox(width: 6),
              Text(
                entry.$1,
                style: TextStyle(
                  color: done
                      ? const Color(0xFF17674E)
                      : const Color(0xFF697B86),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _attachments() {
    final List<(String, String, CapCchnFileModel?)> files =
        <(String, String, CapCchnFileModel?)>[
          ('Ảnh đại diện', 'anh-dai-dien', item.anhDaiDien),
          ('Học phí', 'hoc-phi', item.fileHocPhi),
          ('Hợp đồng', 'hop-dong', item.fileHopDong),
          ('Quyết định', 'quyet-dinh', item.fileQuyetDinh),
          ('Xác nhận thực hành', 'xac-nhan-th', item.fileXacNhanTH),
          (
            'Thông báo tiếp nhận',
            'thong-bao-tiep-nhan',
            item.fileThongBaoTiepNhan,
          ),
        ];
    final List<(String, String, CapCchnFileModel?)> available = files
        .where(((String, String, CapCchnFileModel?) row) => row.$3 != null)
        .toList();
    if (available.isEmpty) {
      return _emptyBlock(Icons.file_present_outlined, 'Chưa có file đính kèm.');
    }
    return Wrap(
      spacing: 9,
      runSpacing: 9,
      children: available.map(((String, String, CapCchnFileModel?) row) {
        final bool loading = _downloadingType == row.$2;
        return ActionChip(
          onPressed: loading ? null : () => _download(row.$2, row.$3!),
          avatar: loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download_rounded, size: 18, color: _primary),
          label: Text(row.$1),
          tooltip: row.$3!.fileName,
          side: const BorderSide(color: Color(0xFFCFE2ED)),
          backgroundColor: const Color(0xFFF1F8FC),
        );
      }).toList(),
    );
  }

  Widget _actions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E9EE))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, 'edit'),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Chỉnh sửa'),
            style: FilledButton.styleFrom(backgroundColor: _primary),
          ),
        ],
      ),
    );
  }

  Widget _metric(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: .18)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(color: Color(0xFF617684), fontSize: 10.5),
          ),
        ],
      ),
    );
  }

  Widget _info(String label, String? value) {
    return SizedBox(
      width: 175,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(color: Color(0xFF82939F), fontSize: 10.5),
          ),
          const SizedBox(height: 2),
          Text(
            value?.trim().isNotEmpty == true ? value!.trim() : '—',
            style: const TextStyle(
              color: _navy,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String title) {
    return Row(
      children: <Widget>[
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFE7F4FA),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _primary, size: 19),
        ),
        const SizedBox(width: 9),
        Text(
          title,
          style: const TextStyle(
            color: _navy,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _emptyBlock(IconData icon, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, color: const Color(0xFF91A1AB), size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFF71838E), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPill(_StatusVisual status, {bool onDark = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: onDark
            ? Colors.white.withValues(alpha: .15)
            : status.color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
        border: onDark
            ? Border.all(color: Colors.white.withValues(alpha: .2))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            status.icon,
            size: 15,
            color: onDark ? Colors.white : status.color,
          ),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              color: onDark ? Colors.white : status.color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  String _date(DateTime? value) {
    return value == null
        ? 'Chưa xác định'
        : DateFormat('dd/MM/yyyy').format(value);
  }
}

_StatusVisual _statusOf(CapCchnModel item) {
  if (item.soDotSapKetThuc > 0) {
    final int? days = item.daysUntilNearestEnd;
    final String label = days == 0
        ? 'Kết thúc hôm nay'
        : days == 1
        ? 'Kết thúc ngày mai'
        : 'Sắp kết thúc';
    return _StatusVisual(
      label,
      Icons.notification_important_outlined,
      const Color(0xFFE07920),
    );
  }
  if (item.soDotDangThucHanh > 0) {
    return const _StatusVisual(
      'Đang thực hành',
      Icons.play_circle_outline_rounded,
      Color(0xFF16845E),
    );
  }
  if (item.soDotSapBatDau > 0) {
    return const _StatusVisual(
      'Sắp bắt đầu',
      Icons.event_available_outlined,
      Color(0xFF087DBA),
    );
  }
  if (item.soDotDaHoanThanh > 0) {
    return const _StatusVisual(
      'Đã hoàn thành',
      Icons.task_alt_rounded,
      Color(0xFF7357B5),
    );
  }
  return const _StatusVisual(
    'Chưa phân công',
    Icons.hourglass_empty_rounded,
    Color(0xFF7B8B95),
  );
}

_PeriodVisual _periodStatus(CapCchnMentorModel period) {
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime? start = period.ngayBatDau == null
      ? null
      : DateTime(
          period.ngayBatDau!.year,
          period.ngayBatDau!.month,
          period.ngayBatDau!.day,
        );
  final DateTime? end = period.ngayKetThuc == null
      ? null
      : DateTime(
          period.ngayKetThuc!.year,
          period.ngayKetThuc!.month,
          period.ngayKetThuc!.day,
        );
  if (start != null &&
      end != null &&
      !start.isAfter(today) &&
      !end.isBefore(today)) {
    final int days = end.difference(today).inDays;
    if (days <= 7) {
      return _PeriodVisual(
        days == 0
            ? 'Kết thúc hôm nay'
            : days == 1
            ? 'Còn 1 ngày'
            : 'Còn $days ngày',
        Icons.notification_important_outlined,
        const Color(0xFFE07920),
        0,
      );
    }
    return const _PeriodVisual(
      'Đang thực hành',
      Icons.play_circle_outline_rounded,
      Color(0xFF16845E),
      1,
    );
  }
  if (start != null && start.isAfter(today)) {
    return const _PeriodVisual(
      'Sắp bắt đầu',
      Icons.event_available_outlined,
      Color(0xFF087DBA),
      2,
    );
  }
  if (end != null && end.isBefore(today)) {
    return const _PeriodVisual(
      'Đã hoàn thành',
      Icons.task_alt_rounded,
      Color(0xFF7357B5),
      3,
    );
  }
  return const _PeriodVisual(
    'Chưa đủ ngày',
    Icons.help_outline_rounded,
    Color(0xFF7B8B95),
    4,
  );
}

class _StatusVisual {
  final String label;
  final IconData icon;
  final Color color;

  const _StatusVisual(this.label, this.icon, this.color);
}

class _PeriodVisual {
  final String label;
  final IconData icon;
  final Color color;
  final int priority;

  const _PeriodVisual(this.label, this.icon, this.color, this.priority);
}
