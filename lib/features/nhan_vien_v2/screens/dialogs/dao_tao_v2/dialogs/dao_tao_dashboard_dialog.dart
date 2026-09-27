import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../models/dao_tao_v2_models.dart';
import '../../../../../../providers/dao_tao_v2_provider.dart';
import 'dao_tao_design.dart';

class DaoTaoDashboardDialog extends StatefulWidget {
  final int idLopDaoTao;
  final String tenLopDaoTao;

  const DaoTaoDashboardDialog({
    super.key,
    required this.idLopDaoTao,
    required this.tenLopDaoTao,
  });

  @override
  State<DaoTaoDashboardDialog> createState() => _DaoTaoDashboardDialogState();
}

class _DaoTaoDashboardDialogState extends State<DaoTaoDashboardDialog> {
  String _keyword = '';

  bool _chiKhoaChuaDangKy = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<DaoTaoV2Provider>().loadDashboard(widget.idLopDaoTao);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DaoTaoV2Provider>();

    final dashboard = provider.dashboard;

    return Theme(
      data: daoTaoTheme(context),
      child: DaoTaoDialogShell(
        title: 'Dashboard đăng ký đào tạo',
        subtitle: widget.tenLopDaoTao,
        icon: Icons.analytics_outlined,
        maxWidth: 1180,
        maxHeight: 800,
        headerActions: [
          IconButton.filledTonal(
            tooltip: 'Làm mới dữ liệu',
            onPressed: provider.isLoadingDashboard
                ? null
                : () => provider.loadDashboard(widget.idLopDaoTao),
            icon: provider.isLoadingDashboard
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 6),
        ],
        child: _buildBody(provider, dashboard),
      ),
    );
  }

  Widget _buildBody(
    DaoTaoV2Provider provider,
    DaoTaoDashboardV2Model? dashboard,
  ) {
    if (provider.isLoadingDashboard && dashboard == null) {
      return const Center(
        child: CircularProgressIndicator(color: DaoTaoColors.primary),
      );
    }

    if (dashboard == null) {
      return DaoTaoEmptyState(
        icon: Icons.cloud_off_rounded,
        title: 'Không tải được dashboard',
        message: provider.errorMessage,
        action: FilledButton.icon(
          onPressed: () => provider.loadDashboard(widget.idLopDaoTao),
          icon: const Icon(Icons.refresh),
          label: const Text('Thử lại'),
        ),
      );
    }

    final filtered = dashboard.khoaPhongs.where((e) {
      if (_chiKhoaChuaDangKy && e.daCoDangKy) {
        return false;
      }

      if (_keyword.trim().isEmpty) {
        return true;
      }

      return e.tenKhoaPhong.toLowerCase().contains(
        _keyword.trim().toLowerCase(),
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // =================================================
          // SUMMARY
          // =================================================
          Row(
            children: [
              Expanded(
                child: _summaryCard(
                  icon: Icons.how_to_reg,
                  title: 'Đã đăng ký',
                  value: '${dashboard.tongNguoiDangKy}',
                  subtitle: 'Tổng lượt đăng ký',
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _summaryCard(
                  icon: Icons.groups_2_outlined,
                  title: 'Nhân sự',
                  value: '${dashboard.tongNhanSu}',
                  subtitle: 'Nhân sự hiện tại',
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _summaryCard(
                  icon: Icons.percent,
                  title: 'Tỷ lệ tham gia',
                  value: '${_percent(dashboard.tyLeThamGia)}%',
                  subtitle:
                      '${dashboard.tongDangKyTheoKhoa}/${dashboard.tongNhanSu} người',
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _summaryCard(
                  icon: Icons.domain_outlined,
                  title: 'Khoa đã tham gia',
                  value: '${dashboard.soKhoaCoDangKy}',
                  subtitle: '${dashboard.soKhoaChuaDangKy} khoa chưa đăng ký',
                ),
              ),
            ],
          ),

          if (dashboard.soDangKyKhongXacDinhKhoa > 0) ...[
            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E8),
                border: Border.all(color: const Color(0xFFF6DCA6)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: DaoTaoColors.warning),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      '${dashboard.soDangKyKhongXacDinhKhoa} người đã đăng ký nhưng hiện không xác định được khoa/phòng theo vị trí công tác hiện tại.',
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 18),

          // =================================================
          // FILTER
          // =================================================
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: daoTaoInputDecoration(
                    icon: Icons.search,
                    hint: 'Tìm nhanh khoa/phòng...',
                  ),
                  onChanged: (value) {
                    setState(() {
                      _keyword = value;
                    });
                  },
                ),
              ),

              const SizedBox(width: 12),

              FilterChip(
                selected: _chiKhoaChuaDangKy,
                avatar: const Icon(
                  Icons.notification_important_outlined,
                  size: 18,
                ),
                label: const Text('Chỉ khoa chưa đăng ký'),
                onSelected: (value) {
                  setState(() {
                    _chiKhoaChuaDangKy = value;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          // =================================================
          // TABLE HEADER
          // =================================================
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xFFE9F3F9),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: const Color(0xFFD4E6F1)),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    'Khoa / Phòng',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

                SizedBox(
                  width: 110,
                  child: Text(
                    'Nhân sự',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

                SizedBox(
                  width: 110,
                  child: Text(
                    'Đăng ký',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

                Expanded(
                  flex: 3,
                  child: Text(
                    'Tỷ lệ tham gia',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

                SizedBox(
                  width: 145,
                  child: Text(
                    'Trạng thái',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // =================================================
          // TABLE BODY
          // =================================================
          Expanded(
            child: filtered.isEmpty
                ? const DaoTaoEmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'Không có dữ liệu phù hợp',
                    message: 'Thử thay đổi từ khóa hoặc điều kiện lọc.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 6),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      return _khoaRow(filtered[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF5FC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: DaoTaoColors.primary),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: DaoTaoColors.muted,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 23,
                      color: DaoTaoColors.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  Text(
                    subtitle,
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

  Widget _khoaRow(DaoTaoKhoaPhongDashboardV2Model item) {
    final ratio = (item.tyLeThamGia / 100).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: DaoTaoColors.surface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: DaoTaoColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              item.tenKhoaPhong,
              style: TextStyle(
                fontWeight: item.daCoDangKy ? FontWeight.w500 : FontWeight.bold,
              ),
            ),
          ),

          SizedBox(
            width: 110,
            child: Text('${item.tongNhanSu}', textAlign: TextAlign.center),
          ),

          SizedBox(
            width: 110,
            child: Text(
              '${item.soNguoiDangKy}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),

          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Text('${_percent(item.tyLeThamGia)}%'),
                  ),

                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(
            width: 145,
            child: Align(
              alignment: Alignment.center,
              child: item.daCoDangKy
                  ? const DaoTaoStatusPill(
                      label: 'Đã đăng ký',
                      icon: Icons.check_circle_outline,
                      color: DaoTaoColors.success,
                    )
                  : const DaoTaoStatusPill(
                      label: 'Chưa đăng ký',
                      icon: Icons.warning_amber_rounded,
                      color: DaoTaoColors.warning,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _percent(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value
        .toStringAsFixed(2)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }
}
