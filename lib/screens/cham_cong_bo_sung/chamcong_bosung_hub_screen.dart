import 'package:flutter/material.dart';
import 'package:mobileapp_bvhv/screens/cham_cong_phep/quan_ly_nghi_phep_screen.dart';
import 'package:mobileapp_bvhv/screens/cham_cong_tang_ca/cham_cong_tang_ca_duyet_bv_screen.dart';
import 'package:mobileapp_bvhv/screens/cham_cong_tang_ca/cham_cong_tang_ca_duyet_khoa_screen.dart';
import 'package:mobileapp_bvhv/screens/cham_cong_tang_ca/cham_cong_tang_ca_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'bao_cao_lech_screen.dart';
import 'cham_cong_bo_sung_web_design.dart';
import 'chamcong_bosung_list_screen.dart';
import 'duyet_bosung_screen.dart';

class ChamCongBoSungHubScreen extends StatelessWidget {
  const ChamCongBoSungHubScreen({super.key});

  final Color primaryColor = const Color(0xFF1274BC);

  @override
  Widget build(BuildContext context) {
    // 🔥 Lấy quyền từ Provider
    final authProvider = context.read<AuthProvider>();
    bool hasRole6 = authProvider.currentRoleIds.contains(6); // Quyền Lãnh đạo
    bool hasRole7 = authProvider.currentRoleIds.contains(7); // Quyền Kế toán
    bool hasRole34 = authProvider.currentRoleIds.contains(34);
    bool hasRole35 = authProvider.currentRoleIds.contains(35);

    if (useChamCongDesktopWeb(context)) {
      return _buildWeb(
        context,
        hasRole6: hasRole6,
        hasRole7: hasRole7,
        hasRole34: hasRole34,
        hasRole35: hasRole35,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text(
          'Quản lý Chấm công',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // const Padding(
            //   padding: EdgeInsets.only(left: 8, bottom: 16, top: 8),
            //   child: Text(
            //     'Nghiệp vụ cá nhân',
            //     style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
            //   ),
            // ),
            _buildActionCard(
              context: context,
              title: 'Đối chiếu chấm công',
              subtitle: 'Đối chiều dữ liệu chấm công và tạo phiếu bổ sung.',
              icon: Icons.fingerprint_rounded,
              color: Colors.teal,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BaoCaoLechScreen()),
              ),
            ),
            _buildActionCard(
              context: context,
              title: 'Đăng ký nghỉ phép',
              subtitle: 'Tạo phiếu đăng ký nghỉ phép (phép năm; phép tháng).',
              icon: Icons.calendar_month_outlined,
              color: const Color.fromARGB(255, 250, 40, 40),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QuanLyNghiPhepScreen()),
              ),
            ),
            _buildActionCard(
              context: context,
              title: 'Danh sách phiếu tăng ca',
              subtitle: 'Theo dõi tiến độ duyệt, sửa hoặc xóa phiếu.',
              icon: Icons.receipt_long_rounded,
              color: const Color.fromARGB(255, 14, 180, 36),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChamCongTangCaScreen()),
              ),
            ),
            _buildActionCard(
              context: context,
              title: 'Danh sách phiếu bổ sung công',
              subtitle: 'Theo dõi tiến độ duyệt, sửa hoặc xóa phiếu.',
              icon: Icons.history_rounded,
              color: Colors.indigo,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ChamCongBoSungListScreen(),
                ),
              ),
            ),

            if (hasRole6 || hasRole7) ...[
              const Padding(
                padding: EdgeInsets.only(left: 8, bottom: 16, top: 24),
                child: Text(
                  'Nghiệp vụ quản lý',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ),
            ],

            if (hasRole6) ...[
              _buildActionCard(
                context: context,
                title: 'LĐ đơn vị duyệt bổ sung',
                subtitle:
                    'Duyệt phiếu xin bổ sung công của nhân viên trong khoa.',
                icon: Icons.fact_check_rounded,
                color: Colors.orange.shade700,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const DuyetBoSungScreen(isRole6: true, isRole7: false),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (hasRole7) ...[
              _buildActionCard(
                context: context,
                title: 'Kế toán duyệt bổ sung',
                subtitle: 'Nghiệm thu phiếu bổ sung công toàn bệnh viện.',
                icon: Icons.verified_user_rounded,
                color: Colors.green.shade600,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const DuyetBoSungScreen(isRole6: false, isRole7: true),
                  ),
                ),
              ),
            ],
            if (hasRole34) ...[
              _buildActionCard(
                context: context,
                title: 'LĐ đơn vị duyệt phiếu tăng ca',
                subtitle: 'Duyệt phiếu tăng ca của nhân viên trong khoa.',
                icon: Icons.fact_check_rounded,
                color: Colors.green.shade600,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChamCongTangCaDuyetKhoaScreen(),
                  ),
                ),
              ),
            ],

            if (hasRole35) ...[
              _buildActionCard(
                context: context,
                title: 'LĐ BV duyệt phiếu tăng ca',
                subtitle: 'Nghiệm thu phiếu tăng ca toàn bệnh viện.',
                icon: Icons.local_hospital_rounded,
                color: Colors.green.shade600,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChamCongTangCaDuyetBVScreen(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeb(
    BuildContext context, {
    required bool hasRole6,
    required bool hasRole7,
    required bool hasRole34,
    required bool hasRole35,
  }) {
    final personalActions = <Widget>[
      _buildWebActionCard(
        context: context,
        title: 'Đối chiếu chấm công',
        subtitle: 'Kiểm tra ngày thiếu công và tạo phiếu bổ sung trực tiếp.',
        icon: Icons.fingerprint_rounded,
        color: const Color(0xFF16837A),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BaoCaoLechScreen()),
        ),
      ),
      _buildWebActionCard(
        context: context,
        title: 'Đăng ký nghỉ phép',
        subtitle: 'Tạo và theo dõi các phiếu phép năm, phép tháng.',
        icon: Icons.calendar_month_rounded,
        color: const Color(0xFFDA5A54),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const QuanLyNghiPhepScreen()),
        ),
      ),
      _buildWebActionCard(
        context: context,
        title: 'Danh sách phiếu tăng ca',
        subtitle: 'Theo dõi tiến độ duyệt, cập nhật hoặc hủy phiếu tăng ca.',
        icon: Icons.more_time_rounded,
        color: const Color(0xFF2A8C63),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChamCongTangCaScreen()),
        ),
      ),
      _buildWebActionCard(
        context: context,
        title: 'Phiếu bổ sung công',
        subtitle: 'Tra cứu trạng thái và lịch sử các phiếu đã gửi.',
        icon: Icons.history_rounded,
        color: const Color(0xFF5667B0),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChamCongBoSungListScreen()),
        ),
      ),
    ];

    final managementActions = <Widget>[
      if (hasRole6)
        _buildWebActionCard(
          context: context,
          title: 'LĐ đơn vị duyệt bổ sung',
          subtitle: 'Duyệt phiếu bổ sung công của nhân viên trong đơn vị.',
          icon: Icons.fact_check_rounded,
          color: ChamCongWebColors.warning,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const DuyetBoSungScreen(isRole6: true, isRole7: false),
            ),
          ),
        ),
      if (hasRole7)
        _buildWebActionCard(
          context: context,
          title: 'Kế toán duyệt bổ sung',
          subtitle: 'Nghiệm thu phiếu bổ sung công trên toàn bệnh viện.',
          icon: Icons.verified_user_rounded,
          color: ChamCongWebColors.success,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const DuyetBoSungScreen(isRole6: false, isRole7: true),
            ),
          ),
        ),
      if (hasRole34)
        _buildWebActionCard(
          context: context,
          title: 'LĐ đơn vị duyệt tăng ca',
          subtitle: 'Kiểm tra và duyệt phiếu tăng ca trong đơn vị.',
          icon: Icons.approval_rounded,
          color: const Color(0xFF397CB5),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ChamCongTangCaDuyetKhoaScreen(),
            ),
          ),
        ),
      if (hasRole35)
        _buildWebActionCard(
          context: context,
          title: 'LĐ bệnh viện duyệt tăng ca',
          subtitle: 'Nghiệm thu phiếu tăng ca trên toàn bệnh viện.',
          icon: Icons.local_hospital_rounded,
          color: const Color(0xFF8A5BA6),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ChamCongTangCaDuyetBVScreen(),
            ),
          ),
        ),
    ];

    return ChamCongWebPage(
      title: 'Quản lý chấm công',
      subtitle: 'Đối chiếu dữ liệu, bổ sung công, nghỉ phép và tăng ca',
      icon: Icons.schedule_rounded,
      showBack: false,
      maxWidth: 1360,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 1180 ? 3 : 2;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ChamCongWebCard(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF5FC),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Icons.tips_and_updates_outlined,
                          color: ChamCongWebColors.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Chọn nghiệp vụ cần xử lý',
                              style: TextStyle(
                                color: ChamCongWebColors.text,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Các chức năng quản lý chỉ xuất hiện theo quyền được cấp.',
                              style: TextStyle(color: ChamCongWebColors.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const ChamCongWebSectionTitle(
                  title: 'Nghiệp vụ cá nhân',
                  subtitle: 'Các tác vụ chấm công thường xuyên của bạn',
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: columns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: columns == 3 ? 2.35 : 2.65,
                  children: personalActions,
                ),
                if (managementActions.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const ChamCongWebSectionTitle(
                    title: 'Nghiệp vụ quản lý',
                    subtitle: 'Phê duyệt và nghiệm thu theo phạm vi phụ trách',
                    icon: Icons.admin_panel_settings_outlined,
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: columns,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: columns == 3 ? 2.35 : 2.65,
                    children: managementActions,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWebActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: ChamCongWebColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: ChamCongWebColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        hoverColor: color.withValues(alpha: .045),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ChamCongWebColors.text,
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ChamCongWebColors.muted,
                        height: 1.35,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade400,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
