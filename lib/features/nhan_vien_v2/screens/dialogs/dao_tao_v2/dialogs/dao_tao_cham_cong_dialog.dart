import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../models/dao_tao_v2_models.dart';
import '../../../../../../providers/dao_tao_v2_provider.dart';
import 'dao_tao_design.dart';
import 'excel_download.dart';

class DaoTaoChamCongDialog extends StatefulWidget {
  final LopDaoTaoV2Model item;

  const DaoTaoChamCongDialog({super.key, required this.item});

  @override
  State<DaoTaoChamCongDialog> createState() => _DaoTaoChamCongDialogState();
}

class _DaoTaoChamCongDialogState extends State<DaoTaoChamCongDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  String _keyword = '';

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 4, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<DaoTaoV2Provider>().loadBaoCaoChamCong(
        widget.item.idLopDaoTao,
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DaoTaoV2Provider>();

    final report = provider.baoCaoChamCong;

    return Theme(
      data: daoTaoTheme(context),
      child: Dialog(
        insetPadding: const EdgeInsets.all(22),
        clipBehavior: Clip.antiAlias,
        backgroundColor: DaoTaoColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),

        child: SizedBox(
          width: 1350,
          height: 820,

          child: Column(
            children: [
              // ===============================================
              // HEADER
              // ===============================================
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                decoration: const BoxDecoration(
                  color: DaoTaoColors.surface,
                  border: Border(
                    bottom: BorderSide(color: DaoTaoColors.border),
                  ),
                ),

                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2999D7), DaoTaoColors.primaryDark],
                        ),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.fingerprint_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          const Text(
                            'Chấm công đào tạo',
                            style: TextStyle(
                              color: DaoTaoColors.text,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),

                          Text(
                            widget.item.tenLopDaoTao,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: DaoTaoColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    FilledButton.icon(
                      onPressed: provider.isExportingExcel
                          ? null
                          : () => _exportExcel(provider),
                      icon: provider.isExportingExcel
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download_rounded),
                      label: const Text('Xuất Excel'),
                    ),

                    const SizedBox(width: 6),

                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),

              if (report != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      _summary(
                        'Tổng đăng ký',
                        report.tongDangKy,
                        Icons.groups_rounded,
                        DaoTaoColors.primary,
                      ),
                      const SizedBox(width: 10),
                      _summary(
                        'Đăng ký đủ',
                        report.soDangKyDu,
                        Icons.task_alt_rounded,
                        DaoTaoColors.success,
                      ),
                      const SizedBox(width: 10),
                      _summary(
                        'Đăng ký thiếu',
                        report.soDangKyThieu,
                        Icons.pending_actions_rounded,
                        DaoTaoColors.warning,
                      ),
                      const SizedBox(width: 10),
                      _summary(
                        'Không ĐK có chấm',
                        report.soKhongDangKyCoCham,
                        Icons.person_search_rounded,
                        DaoTaoColors.danger,
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  decoration: daoTaoInputDecoration(
                    hint: 'Tìm mã số, họ tên hoặc khoa/phòng...',
                    icon: Icons.search_rounded,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _keyword = value;
                    });
                  },
                ),
              ),

              const SizedBox(height: 10),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: DaoTaoColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DaoTaoColors.border),
                ),
                child: TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(text: 'Đăng ký đủ (${report?.soDangKyDu ?? 0})'),
                    Tab(text: 'Đăng ký thiếu (${report?.soDangKyThieu ?? 0})'),
                    Tab(
                      text:
                          'Không ĐK có chấm (${report?.soKhongDangKyCoCham ?? 0})',
                    ),
                    Tab(
                      text:
                          'Tất cả giờ chấm (${report?.tatCaGioCham.length ?? 0})',
                    ),
                  ],
                ),
              ),

              Expanded(child: _body(provider, report)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(DaoTaoV2Provider provider, DaoTaoChamCongBaoCaoV2Model? report) {
    if (provider.isLoadingChamCong && report == null) {
      return const Center(
        child: CircularProgressIndicator(color: DaoTaoColors.primary),
      );
    }

    if (report == null) {
      return DaoTaoEmptyState(
        icon: Icons.cloud_off_rounded,
        title: 'Không tải được dữ liệu chấm công',
        message: provider.errorMessage,
      );
    }

    return TabBarView(
      controller: _tabController,

      children: [
        _nguoiTable(report.dangKyDu),

        _nguoiTable(report.dangKyThieu),

        _nguoiTable(report.khongDangKyCoCham),

        _gioChamTable(report.tatCaGioCham),
      ],
    );
  }

  Widget _nguoiTable(List<DaoTaoChamCongNguoiV2Model> source) {
    final key = _keyword.trim().toLowerCase();

    final items = source.where((e) {
      if (key.isEmpty) {
        return true;
      }

      return e.maSo.toLowerCase().contains(key) ||
          (e.hoVaTen ?? '').toLowerCase().contains(key) ||
          (e.tenKhoaPhong ?? '').toLowerCase().contains(key);
    }).toList();

    if (items.isEmpty) {
      return const DaoTaoEmptyState(
        icon: Icons.search_off_rounded,
        title: 'Không có dữ liệu phù hợp',
        message: 'Thử thay đổi từ khóa tìm kiếm.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),

      itemCount: items.length,

      separatorBuilder: (_, _) => const SizedBox(height: 8),

      itemBuilder: (_, index) {
        final item = items[index];

        return Container(
          decoration: BoxDecoration(
            color: DaoTaoColors.surface,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: DaoTaoColors.border),
          ),
          child: ExpansionTile(
            shape: const Border(),
            collapsedShape: const Border(),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFEAF5FC),
              foregroundColor: DaoTaoColors.primary,
              child: Text('${index + 1}'),
            ),

            title: Text(
              '${item.maSo} - ${item.hoVaTen ?? ''}',
              style: const TextStyle(
                color: DaoTaoColors.text,
                fontWeight: FontWeight.w700,
              ),
            ),

            subtitle: Text(item.tenKhoaPhong ?? 'Chưa xác định khoa/phòng'),

            trailing: DaoTaoStatusPill(
              label: item.duChamCong ? 'Đủ chấm công' : 'Thiếu chấm công',
              icon: item.duChamCong
                  ? Icons.check_circle_outline
                  : Icons.warning_amber_rounded,
              color: item.duChamCong
                  ? DaoTaoColors.success
                  : DaoTaoColors.warning,
            ),

            children: item.chiTietNgay.map(_dayRow).toList(),
          ),
        );
      },
    );
  }

  Widget _dayRow(DaoTaoChamCongNgayV2Model day) {
    return ListTile(
      dense: true,

      title: Text(_date(day.ngay)),

      subtitle: Text(
        'Tất cả giờ chấm: '
        '${day.tatCaGioCham.map(_time).join(', ')}',
      ),

      trailing: Text(
        'Vào: ${_time(day.gioVaoHopLe)}   '
        'Ra: ${_time(day.gioRaHopLe)}',
      ),
    );
  }

  Widget _gioChamTable(List<DaoTaoGioChamV2Model> source) {
    final key = _keyword.trim().toLowerCase();

    final items = source.where((e) {
      if (key.isEmpty) {
        return true;
      }

      return e.maSo.toLowerCase().contains(key) ||
          e.badgeNumber.toLowerCase().contains(key) ||
          (e.hoVaTen ?? '').toLowerCase().contains(key) ||
          (e.tenKhoaPhong ?? '').toLowerCase().contains(key);
    }).toList();

    return ListView.separated(
      padding: const EdgeInsets.all(16),

      itemCount: items.length,

      separatorBuilder: (_, _) => const SizedBox(height: 7),

      itemBuilder: (_, index) {
        final item = items[index];

        return Container(
          decoration: BoxDecoration(
            color: DaoTaoColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: DaoTaoColors.border),
          ),
          child: ListTile(
            leading: Text('${index + 1}'),

            title: Text('${item.maSo} - ${item.hoVaTen ?? ''}'),

            subtitle: Text(
              '${item.tenKhoaPhong ?? ''} • '
              'Máy ${item.machineNumber ?? ''}',
            ),

            trailing: SizedBox(
              width: 300,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,

                children: [
                  Text(_dateTime(item.checkTime)),

                  const SizedBox(width: 12),

                  DaoTaoStatusPill(
                    label: item.phanLoai,
                    icon: Icons.fingerprint_rounded,
                    color: DaoTaoColors.primary,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _summary(String title, int value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),

          child: Row(
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$value',
                      style: const TextStyle(
                        color: DaoTaoColors.text,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      title,
                      style: const TextStyle(
                        color: DaoTaoColors.muted,
                        fontSize: 11.5,
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

  Future<void> _exportExcel(DaoTaoV2Provider provider) async {
    final bytes = await provider.exportChamCongExcel(widget.item.idLopDaoTao);

    if (!mounted || bytes == null) {
      if (provider.errorMessage != null) {
        _message(provider.errorMessage!);
      }

      return;
    }

    final now = DateTime.now();

    await downloadExcelFile(
      bytes: bytes,
      fileName:
          'ChamCongLop_${widget.item.idLopDaoTao}_'
          '${now.year}${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}.xlsx',
    );
  }

  String _date(DateTime? value) {
    if (value == null) {
      return '';
    }

    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  String _time(DateTime? value) {
    if (value == null) {
      return '--:--';
    }

    return '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}:'
        '${value.second.toString().padLeft(2, '0')}';
  }

  String _dateTime(DateTime? value) {
    if (value == null) {
      return '';
    }

    return '${_date(value)} ${_time(value)}';
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}
