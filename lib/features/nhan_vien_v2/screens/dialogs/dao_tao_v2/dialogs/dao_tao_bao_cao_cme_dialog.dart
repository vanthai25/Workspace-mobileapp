import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../../../models/dao_tao_bao_cao_models.dart';
import '../../../../../../providers/dao_tao_v2_provider.dart';
import 'dao_tao_design.dart';
import 'excel_download.dart';

class DaoTaoBaoCaoCmeDialog extends StatefulWidget {
  const DaoTaoBaoCaoCmeDialog({super.key});

  @override
  State<DaoTaoBaoCaoCmeDialog> createState() => _DaoTaoBaoCaoCmeDialogState();
}

class _DaoTaoBaoCaoCmeDialogState extends State<DaoTaoBaoCaoCmeDialog> {
  final _searchController = TextEditingController();
  late DateTime _tuNgay;
  late DateTime _denNgay;
  DaoTaoBaoCaoCmeDanhMucModel? _danhMuc;
  DaoTaoBaoCaoCmeModel? _report;
  final Set<int> _loaiNhanViens = {};
  bool _loadingDanhMuc = false;
  bool _loadingReport = false;
  bool _exporting = false;
  String _keyword = '';
  String? _error;

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

  Map<String, dynamic> get _request => {
    'tuNgay': DateFormat('yyyy-MM-dd').format(_tuNgay),
    'denNgay': DateFormat('yyyy-MM-dd').format(_denNgay),
    'loaiNhanViens': _loaiNhanViens.toList(),
  };

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
          .getBaoCaoCmeDanhMuc();
      if (!mounted) return;
      setState(() {
        _danhMuc = result;
        _loaiNhanViens.clear();
      });
    } catch (error) {
      if (mounted) setState(() => _error = _errorMessage(error));
    } finally {
      if (mounted) setState(() => _loadingDanhMuc = false);
    }
  }

  Future<void> _preview() async {
    setState(() {
      _loadingReport = true;
      _error = null;
    });
    try {
      final result = await context
          .read<DaoTaoV2Provider>()
          .service
          .getBaoCaoCme(_request);
      if (mounted) setState(() => _report = result);
    } catch (error) {
      if (mounted) setState(() => _error = _errorMessage(error));
    } finally {
      if (mounted) setState(() => _loadingReport = false);
    }
  }

  Future<void> _export() async {
    setState(() {
      _exporting = true;
      _error = null;
    });
    try {
      final bytes = await context
          .read<DaoTaoV2Provider>()
          .service
          .exportBaoCaoCmeExcel(_request);
      await downloadExcelFile(
        bytes: bytes,
        fileName:
            'BaoCaoCME_${DateFormat('yyyyMMdd').format(_tuNgay)}_${DateFormat('yyyyMMdd').format(_denNgay)}.xlsx',
      );
    } catch (error) {
      if (mounted) setState(() => _error = _errorMessage(error));
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
      _report = null;
    });
  }

  void _preset(String value) {
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
      _report = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DaoTaoDialogShell(
      title: 'Báo cáo chứng chỉ / CME',
      subtitle: 'Thống kê giờ tín chỉ theo nhân viên và loại nhân viên',
      icon: Icons.workspace_premium_rounded,
      maxWidth: 1380,
      maxHeight: 900,
      footer: Row(
        children: [
          Text(
            _loaiNhanViens.isEmpty
                ? 'Tất cả loại nhân viên'
                : '${_loaiNhanViens.length} loại nhân viên đã chọn',
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
                SizedBox(width: 350, child: _buildFilters()),
                const VerticalDivider(width: 1),
                Expanded(child: _buildResult()),
              ],
            ),
    );
  }

  Widget _buildFilters() {
    return Material(
      color: Colors.white,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const _CmeSectionTitle(
            icon: Icons.date_range_rounded,
            title: 'Khoảng thời gian',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
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
          const SizedBox(height: 24),
          const _CmeSectionTitle(
            icon: Icons.groups_rounded,
            title: 'Loại nhân viên',
          ),
          const SizedBox(height: 8),
          const Text(
            'Không chọn nghĩa là lấy tất cả loại nhân viên.',
            style: TextStyle(fontSize: 12, color: DaoTaoColors.muted),
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: (_danhMuc?.loaiNhanViens ?? const []).map((item) {
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
        ],
      ),
    );
  }

  Widget _dateButton(String label, DateTime value, bool isStart) => InkWell(
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
            Icon(
              Icons.workspace_premium_outlined,
              size: 58,
              color: Color(0xFF91A8B9),
            ),
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
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
            child: Row(
              children: [
                _metric(
                  'Nhân viên',
                  '${report.tongNhanSu}',
                  Icons.groups_rounded,
                  const Color(0xFF6B5BC4),
                ),
                const SizedBox(width: 9),
                _metric(
                  'Chứng chỉ / CME',
                  '${report.tongChungChiCme}',
                  Icons.workspace_premium_rounded,
                  DaoTaoColors.primary,
                ),
                const SizedBox(width: 9),
                _metric(
                  'Tổng giờ tín chỉ',
                  _number(report.tongGioTinChi),
                  Icons.schedule_rounded,
                  DaoTaoColors.success,
                ),
              ],
            ),
          ),
          SizedBox(
            height: 92,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
              scrollDirection: Axis.horizontal,
              itemCount: report.theoLoaiNhanViens.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final item = report.theoLoaiNhanViens[index];
                return Container(
                  width: 230,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: DaoTaoColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.tenLoaiNhanVien,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${item.soCme} CME • ${item.soChungChi} chứng chỉ • ${_number(item.tongGioTinChi)} giờ',
                        style: const TextStyle(
                          color: DaoTaoColors.muted,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const TabBar(
            tabs: [
              Tab(text: 'Theo nhân viên'),
              Tab(text: 'Chi tiết chứng chỉ / CME'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [_buildPeople(report), _buildDetails(report)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value, IconData icon, Color color) =>
      Expanded(
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
                      value,
                      style: TextStyle(
                        color: color,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
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

  Widget _buildPeople(DaoTaoBaoCaoCmeModel report) {
    final keyword = _keyword.trim().toLowerCase();
    final people = report.caNhans
        .where(
          (item) =>
              keyword.isEmpty ||
              item.maSo.toLowerCase().contains(keyword) ||
              item.hoVaTen.toLowerCase().contains(keyword) ||
              (item.tenKhoaPhong ?? '').toLowerCase().contains(keyword),
        )
        .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _keyword = value),
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
              final hasCredit = item.tongChungChiCme > 0;
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
                  subtitle: Text(
                    '${_text(item.tenKhoaPhong, 'Chưa có khoa/phòng')} • '
                    '${_text(item.tenLoaiNhanVien, 'Chưa phân nhóm')}\n'
                    '${item.soCme} CME • ${item.soChungChi} chứng chỉ',
                  ),
                  trailing: Chip(
                    avatar: Icon(
                      Icons.schedule_rounded,
                      size: 17,
                      color: hasCredit
                          ? DaoTaoColors.success
                          : DaoTaoColors.muted,
                    ),
                    label: Text('${_number(item.tongGioTinChi)} giờ tín chỉ'),
                    labelStyle: TextStyle(
                      color: hasCredit
                          ? DaoTaoColors.success
                          : DaoTaoColors.muted,
                      fontWeight: FontWeight.w800,
                    ),
                    side: BorderSide.none,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetails(DaoTaoBaoCaoCmeModel report) {
    if (report.chiTiets.isEmpty) {
      return const Center(
        child: Text(
          'Không có chứng chỉ/CME trong khoảng thời gian đã chọn.',
          style: TextStyle(color: DaoTaoColors.muted),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(18),
      itemCount: report.chiTiets.length,
      itemBuilder: (_, index) {
        final item = report.chiTiets[index];
        final color = item.isCme
            ? DaoTaoColors.primary
            : const Color(0xFF6B5BC4);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
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
                child: Icon(
                  item.isCme
                      ? Icons.military_tech_rounded
                      : Icons.card_membership_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.tenChungChi,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.hoVaTen} (${item.maSo}) • '
                      '${_text(item.tenKhoaPhong, 'Chưa có khoa/phòng')}',
                      style: const TextStyle(
                        color: DaoTaoColors.muted,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '${_text(item.tenLoaiNhanVien, 'Chưa phân nhóm')}\n'
                  '${_text(item.donViDaoTao, 'Chưa có đơn vị đào tạo')}',
                  style: const TextStyle(fontSize: 11.5, height: 1.45),
                ),
              ),
              SizedBox(
                width: 110,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_number(item.gioTinChi)} giờ',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      item.ngayGhiNhan == null
                          ? 'Chưa có ngày'
                          : DateFormat('dd/MM/yyyy').format(item.ngayGhiNhan!),
                      style: const TextStyle(
                        color: DaoTaoColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text(item.isCme ? 'CME' : 'Chứng chỉ'),
                labelStyle: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
                backgroundColor: color.withValues(alpha: .08),
                side: BorderSide.none,
              ),
            ],
          ),
        );
      },
    );
  }

  String _number(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);

  String _text(String? value, String fallback) =>
      value?.trim().isNotEmpty == true ? value!.trim() : fallback;

  String _errorMessage(Object error) {
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
      return error.message ?? 'Không thể tải báo cáo CME.';
    }
    return error.toString().replaceFirst('Exception: ', '');
  }
}

class _CmeSectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _CmeSectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 19, color: DaoTaoColors.primary),
      const SizedBox(width: 7),
      Text(
        title,
        style: const TextStyle(
          color: DaoTaoColors.text,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}
