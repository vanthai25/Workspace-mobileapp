import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../../../models/dao_tao_bao_cao_models.dart';
import '../../../../../../providers/dao_tao_v2_provider.dart';
import 'dao_tao_design.dart';
import 'excel_download.dart';

class DaoTaoBaoCaoTongHopDialog extends StatefulWidget {
  const DaoTaoBaoCaoTongHopDialog({super.key});

  @override
  State<DaoTaoBaoCaoTongHopDialog> createState() =>
      _DaoTaoBaoCaoTongHopDialogState();
}

class _DaoTaoBaoCaoTongHopDialogState extends State<DaoTaoBaoCaoTongHopDialog> {
  final _searchController = TextEditingController();
  late DateTime _tuNgay;
  late DateTime _denNgay;
  DaoTaoBaoCaoDanhMucModel? _danhMuc;
  DaoTaoBaoCaoTongHopModel? _report;
  final Set<int> _lopIds = {};
  final Set<String> _diaDiems = {};
  final Set<int> _loaiNhanViens = {};
  bool _loadingDanhMuc = false;
  bool _loadingReport = false;
  bool _exporting = false;
  bool _isComparison = false;
  String? _error;
  String _personKeyword = '';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _tuNgay = DateTime(now.year, now.month, 1);
    _denNgay = DateTime(now.year, now.month + 1, 0);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDanhMuc());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDanhMuc() async {
    setState(() {
      _loadingDanhMuc = true;
      _error = null;
      _report = null;
    });
    try {
      final result = await context
          .read<DaoTaoV2Provider>()
          .service
          .getBaoCaoTongHopDanhMuc(tuNgay: _tuNgay, denNgay: _denNgay);
      if (!mounted) return;
      setState(() {
        _danhMuc = result;
        _lopIds
          ..clear()
          ..addAll(const <int>[]);
        _diaDiems.clear();
        _loaiNhanViens.clear();
      });
    } catch (e) {
      if (mounted) setState(() => _error = _message(e));
    } finally {
      if (mounted) setState(() => _loadingDanhMuc = false);
    }
  }

  Map<String, dynamic> get _request => {
    'tuNgay': DateFormat('yyyy-MM-dd').format(_tuNgay),
    'denNgay': DateFormat('yyyy-MM-dd').format(_denNgay),
    'idLopDaoTaos': _isComparison ? _effectiveLopIds.toList() : <int>[],
    'diaDiems': _diaDiems.toList(),
    'loaiNhanViens': _loaiNhanViens.toList(),
  };

  Future<void> _preview() async {
    if (_isComparison && _effectiveLopIds.length < 2) {
      setState(() => _error = 'Vui lòng chọn ít nhất hai lớp để so sánh.');
      return;
    }
    setState(() {
      _loadingReport = true;
      _error = null;
    });
    try {
      final report = await context
          .read<DaoTaoV2Provider>()
          .service
          .getBaoCaoTongHop(_request);
      if (mounted) setState(() => _report = report);
    } catch (e) {
      if (mounted) setState(() => _error = _message(e));
    } finally {
      if (mounted) setState(() => _loadingReport = false);
    }
  }

  Future<void> _export() async {
    if (_isComparison && _effectiveLopIds.length < 2) {
      setState(() => _error = 'Vui lòng chọn ít nhất hai lớp để so sánh.');
      return;
    }
    setState(() {
      _exporting = true;
      _error = null;
    });
    try {
      final bytes = await context
          .read<DaoTaoV2Provider>()
          .service
          .exportBaoCaoTongHopExcel(_request);
      await downloadExcelFile(
        bytes: bytes,
        fileName:
            '${_isComparison ? 'SoSanhLopDaoTao' : 'BaoCaoDaoTao'}_${DateFormat('yyyyMMdd').format(_tuNgay)}_${DateFormat('yyyyMMdd').format(_denNgay)}.xlsx',
      );
    } catch (e) {
      if (mounted) setState(() => _error = _message(e));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _tuNgay : _denNgay,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _tuNgay = picked;
        if (_denNgay.isBefore(_tuNgay)) _denNgay = picked;
      } else {
        _denNgay = picked;
        if (_tuNgay.isAfter(_denNgay)) _tuNgay = picked;
      }
    });
    await _loadDanhMuc();
  }

  Future<void> _preset(String value) async {
    final now = DateTime.now();
    setState(() {
      if (value == 'week') {
        _tuNgay = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: now.weekday - 1));
        _denNgay = _tuNgay.add(const Duration(days: 6));
      } else if (value == 'lastMonth') {
        _tuNgay = DateTime(now.year, now.month - 1, 1);
        _denNgay = DateTime(now.year, now.month, 0);
      } else {
        _tuNgay = DateTime(now.year, now.month, 1);
        _denNgay = DateTime(now.year, now.month + 1, 0);
      }
    });
    await _loadDanhMuc();
  }

  @override
  Widget build(BuildContext context) {
    return DaoTaoDialogShell(
      title: 'Báo cáo đào tạo',
      subtitle: _isComparison
          ? 'So sánh kết quả giữa các lớp được chọn'
          : 'Thống kê toàn bộ lớp trong khoảng thời gian',
      icon: Icons.analytics_rounded,
      maxWidth: 1380,
      maxHeight: 900,
      footer: Row(
        children: [
          Text(
            _isComparison
                ? '${_effectiveLopIds.length} lớp dùng để so sánh'
                : '${_visibleClasses.length} lớp trong phạm vi báo cáo',
            style: const TextStyle(
              color: DaoTaoColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: _loadingReport ? null : _preview,
            icon: _loadingReport
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.visibility_rounded),
            label: const Text('Xem báo cáo'),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: _exporting ? null : _export,
            icon: _exporting
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.download_rounded),
            label: const Text('Xuất Excel'),
          ),
        ],
      ),
      child: _loadingDanhMuc
          ? const Center(child: CircularProgressIndicator())
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: 390, child: _buildFilters()),
                const VerticalDivider(width: 1),
                Expanded(child: _buildResult()),
              ],
            ),
    );
  }

  Widget _buildFilters() {
    final data = _danhMuc;
    return Material(
      color: Colors.white,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const _SectionTitle(
            icon: Icons.date_range_rounded,
            title: 'Khoảng thời gian',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            children: [
              ActionChip(
                label: const Text('Tuần này'),
                onPressed: () => _preset('week'),
              ),
              ActionChip(
                label: const Text('Tháng này'),
                onPressed: () => _preset('month'),
              ),
              ActionChip(
                label: const Text('Tháng trước'),
                onPressed: () => _preset('lastMonth'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _dateButton('Từ ngày', _tuNgay, true)),
              const SizedBox(width: 8),
              Expanded(child: _dateButton('Đến ngày', _denNgay, false)),
            ],
          ),
          const SizedBox(height: 22),
          const _SectionTitle(icon: Icons.place_rounded, title: 'Địa điểm'),
          const SizedBox(height: 8),
          if (data?.diaDiems.isEmpty ?? true)
            const Text(
              'Chưa có địa điểm trong kỳ.',
              style: TextStyle(color: DaoTaoColors.muted),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: data!.diaDiems.map((item) {
                return FilterChip(
                  label: Text(item),
                  selected: _diaDiems.contains(item),
                  onSelected: (selected) => setState(() {
                    selected ? _diaDiems.add(item) : _diaDiems.remove(item);
                    _report = null;
                  }),
                );
              }).toList(),
            ),
          const SizedBox(height: 22),
          const _SectionTitle(
            icon: Icons.groups_rounded,
            title: 'Nhóm nhân viên',
          ),
          const SizedBox(height: 8),
          Text(
            _loaiNhanViens.isEmpty
                ? 'Đang lấy tất cả nhóm'
                : 'Đã chọn ${_loaiNhanViens.length} nhóm',
            style: const TextStyle(fontSize: 12, color: DaoTaoColors.muted),
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: (data?.loaiNhanViens ?? const []).map((item) {
              return FilterChip(
                label: Text(item.tenLoaiNhanVien),
                selected: _loaiNhanViens.contains(item.loaiNhanVien),
                onSelected: (selected) => setState(() {
                  selected
                      ? _loaiNhanViens.add(item.loaiNhanVien)
                      : _loaiNhanViens.remove(item.loaiNhanVien);
                  _report = null;
                }),
              );
            }).toList(),
          ),
          const SizedBox(height: 22),
          const _SectionTitle(
            icon: Icons.compare_arrows_rounded,
            title: 'Hình thức báo cáo',
          ),
          const SizedBox(height: 9),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                icon: Icon(Icons.summarize_rounded),
                label: Text('Tổng hợp'),
              ),
              ButtonSegment(
                value: true,
                icon: Icon(Icons.compare_rounded),
                label: Text('So sánh lớp'),
              ),
            ],
            selected: {_isComparison},
            onSelectionChanged: (values) => setState(() {
              _isComparison = values.first;
              _lopIds.clear();
              _report = null;
              _error = null;
            }),
          ),
          const SizedBox(height: 8),
          Text(
            _isComparison
                ? 'Chọn từ 2 lớp trở lên để đối chiếu kết quả từng người.'
                : 'Báo cáo tự lấy tất cả lớp phù hợp với thời gian và bộ lọc.',
            style: const TextStyle(fontSize: 12, color: DaoTaoColors.muted),
          ),
          if (_isComparison) ...[
            const SizedBox(height: 20),
            const _SectionTitle(
              icon: Icons.school_rounded,
              title: 'Chọn lớp cần so sánh',
            ),
            const SizedBox(height: 8),
            if (_visibleClasses.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  'Không có lớp phù hợp.',
                  style: TextStyle(color: DaoTaoColors.muted),
                ),
              )
            else
              ..._visibleClasses.map(_classCheckbox),
          ],
        ],
      ),
    );
  }

  List<DaoTaoBaoCaoLopOptionModel> get _visibleClasses {
    final classes =
        _danhMuc?.lopDaoTaos ?? const <DaoTaoBaoCaoLopOptionModel>[];
    if (_diaDiems.isEmpty) return classes;
    return classes
        .where((e) => e.diaDiem != null && _diaDiems.contains(e.diaDiem))
        .toList();
  }

  Set<int> get _effectiveLopIds {
    final visibleIds = _visibleClasses.map((e) => e.idLopDaoTao).toSet();
    return _lopIds.where(visibleIds.contains).toSet();
  }

  Widget _classCheckbox(DaoTaoBaoCaoLopOptionModel item) {
    final selected = _lopIds.contains(item.idLopDaoTao);
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFEFF8FD) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? const Color(0xFFAED9EF) : DaoTaoColors.border,
        ),
      ),
      child: CheckboxListTile(
        dense: true,
        controlAffinity: ListTileControlAffinity.leading,
        value: selected,
        onChanged: (value) => setState(() {
          value == true
              ? _lopIds.add(item.idLopDaoTao)
              : _lopIds.remove(item.idLopDaoTao);
          _report = null;
        }),
        title: Text(
          item.tenLopDaoTao,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        subtitle: Text(
          '${_formatDate(item.ngayBatDau)} • ${_text(item.diaDiem, 'Chưa nhập địa điểm')}\n'
          '${_text(item.tenPhamViDaoTao, 'Chưa xác định phạm vi')} • '
          '${_text(item.khoaPhongThamGia, 'Chưa chọn khoa/phòng')}',
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11.5, height: 1.4),
        ),
      ),
    );
  }

  Widget _dateButton(String label, DateTime value, bool isStart) {
    return InkWell(
      onTap: () => _pickDate(isStart),
      borderRadius: BorderRadius.circular(11),
      child: InputDecorator(
        decoration: daoTaoInputDecoration(
          label: label,
          icon: Icons.calendar_today_rounded,
        ),
        child: Text(
          DateFormat('dd/MM/yyyy').format(value),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildResult() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: DaoTaoColors.danger,
              ),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _preview,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }
    final report = _report;
    if (report == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.query_stats_rounded, size: 58, color: Color(0xFF91A8B9)),
            SizedBox(height: 12),
            Text(
              'Chọn bộ lọc và bấm “Xem báo cáo”',
              style: TextStyle(color: DaoTaoColors.muted, fontSize: 15),
            ),
          ],
        ),
      );
    }
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
            child: Row(
              children: [
                _metric(
                  'Lớp đã chọn',
                  report.soLopDaChon,
                  Icons.school_rounded,
                  DaoTaoColors.primary,
                ),
                const SizedBox(width: 9),
                _metric(
                  'Nhân sự',
                  report.tongNhanSu,
                  Icons.groups_rounded,
                  const Color(0xFF6B5BC4),
                ),
                const SizedBox(width: 9),
                _metric(
                  'Đạt ít nhất 1 buổi',
                  report.soNguoiHopLe,
                  Icons.verified_rounded,
                  DaoTaoColors.success,
                ),
                const SizedBox(width: 9),
                _metric(
                  'Không tham gia',
                  report.soNguoiKhongThamGia,
                  Icons.person_off_rounded,
                  DaoTaoColors.warning,
                ),
              ],
            ),
          ),
          TabBar(
            tabs: [
              const Tab(text: 'Thống kê từng lớp'),
              Tab(
                text: _isComparison
                    ? 'So sánh theo nhân viên'
                    : 'Thống kê theo nhân viên',
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildClassResults(report),
                _buildPeopleResults(report),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, int value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: DaoTaoColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: .1),
              foregroundColor: color,
              child: Icon(icon, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$value',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: DaoTaoColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassResults(DaoTaoBaoCaoTongHopModel report) {
    return ListView.separated(
      padding: const EdgeInsets.all(18),
      itemCount: report.lopDaoTaos.length,
      separatorBuilder: (_, _) => const SizedBox(height: 9),
      itemBuilder: (_, index) {
        final item = report.lopDaoTaos[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                CircleAvatar(child: Text('${index + 1}')),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.tenLopDaoTao,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${_formatDate(item.ngayBatDau)} • ${_text(item.diaDiem, 'Chưa nhập địa điểm')} • '
                        '${_text(item.tpThamDu, 'Chưa nhập đối tượng')}\n'
                        '${_text(item.tenPhamViDaoTao, 'Chưa xác định phạm vi')} • '
                        '${_text(item.khoaPhongThamGia, 'Chưa chọn khoa/phòng')}',
                        style: const TextStyle(
                          color: DaoTaoColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _count('Đăng ký', item.soDangKy, DaoTaoColors.primary),
                _count('Hợp lệ', item.soHopLe, DaoTaoColors.success),
                _count('Không hợp lệ', item.soKhongHopLe, DaoTaoColors.danger),
                _count(
                  'Chờ xác nhận',
                  item.soChuaXacNhan,
                  DaoTaoColors.warning,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _count(String label, int value, Color color) => Container(
    width: 92,
    margin: const EdgeInsets.only(left: 7),
    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 7),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: color,
            fontSize: 17,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10.5, color: DaoTaoColors.muted),
        ),
      ],
    ),
  );

  Widget _buildPeopleResults(DaoTaoBaoCaoTongHopModel report) {
    final keyword = _personKeyword.trim().toLowerCase();
    final people = report.caNhans
        .where(
          (e) =>
              keyword.isEmpty ||
              e.hoVaTen.toLowerCase().contains(keyword) ||
              e.maSo.toLowerCase().contains(keyword) ||
              (e.tenKhoaPhong ?? '').toLowerCase().contains(keyword),
        )
        .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _personKeyword = value),
            decoration: daoTaoInputDecoration(
              hint: 'Tìm mã số, họ tên hoặc khoa/phòng...',
              icon: Icons.search_rounded,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(18),
            itemCount: people.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, index) {
              final item = people[index];
              final resultText = item.daHopLeBatKy
                  ? 'Đạt'
                  : item.soLopDaDangKy == 0
                  ? 'Không tham gia'
                  : 'Chưa đạt';
              final color = item.daHopLeBatKy
                  ? DaoTaoColors.success
                  : item.soLopDaDangKy == 0
                  ? DaoTaoColors.warning
                  : DaoTaoColors.danger;
              final subtitle =
                  '${_text(item.tenKhoaPhong, 'Chưa có khoa/phòng')} • '
                  '${_text(item.tenLoaiNhanVien, 'Chưa phân nhóm')}\n'
                  'Toàn viện: ${item.soLopToanVien} • '
                  'Khoa/phòng: ${item.soLopKhoaPhong} • '
                  'Tổng hợp lệ: ${item.soLopHopLe}';
              if (!_isComparison) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: DaoTaoColors.border),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        item.hoVaTen.isEmpty
                            ? '?'
                            : item.hoVaTen.characters.first.toUpperCase(),
                      ),
                    ),
                    title: Text(
                      '${item.hoVaTen} (${item.maSo})',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(subtitle),
                    trailing: Chip(
                      label: Text(resultText),
                      labelStyle: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                      backgroundColor: color.withValues(alpha: .1),
                      side: BorderSide.none,
                    ),
                  ),
                );
              }
              return ExpansionTile(
                backgroundColor: Colors.white,
                collapsedBackgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: DaoTaoColors.border),
                ),
                collapsedShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: DaoTaoColors.border),
                ),
                leading: CircleAvatar(
                  child: Text(
                    item.hoVaTen.isEmpty
                        ? '?'
                        : item.hoVaTen.characters.first.toUpperCase(),
                  ),
                ),
                title: Text(
                  '${item.hoVaTen} (${item.maSo})',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(subtitle),
                trailing: Chip(
                  label: Text(resultText),
                  labelStyle: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                  backgroundColor: color.withValues(alpha: .1),
                  side: BorderSide.none,
                ),
                children: item.ketQuaTheoLops.map((entry) {
                  final entryColor = entry.isHopLe
                      ? DaoTaoColors.success
                      : entry.daDangKy
                      ? DaoTaoColors.danger
                      : DaoTaoColors.muted;
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      entry.isHopLe
                          ? Icons.check_circle_rounded
                          : entry.daDangKy
                          ? Icons.cancel_rounded
                          : Icons.remove_circle_outline_rounded,
                      color: entryColor,
                      size: 20,
                    ),
                    title: Text(entry.tenLopDaoTao),
                    trailing: Text(
                      entry.trangThai,
                      style: TextStyle(
                        color: entryColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? value) => value == null
      ? 'Chưa có ngày'
      : DateFormat('dd/MM/yyyy HH:mm').format(value);
  String _text(String? value, String fallback) =>
      value?.trim().isNotEmpty == true ? value!.trim() : fallback;

  String _message(Object error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.connectionError) {
        return 'Không thể kết nối tới máy chủ. Vui lòng kiểm tra API hoặc đường truyền.';
      }
      if (error.type == DioExceptionType.receiveTimeout) {
        return 'Máy chủ xử lý báo cáo quá lâu. Vui lòng thu hẹp khoảng thời gian rồi thử lại.';
      }
      final data = error.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      return error.message ?? 'Không thể tải báo cáo.';
    }
    return error.toString().replaceFirst('Exception: ', '');
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 19, color: DaoTaoColors.primary),
      const SizedBox(width: 7),
      Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: DaoTaoColors.text,
        ),
      ),
    ],
  );
}
