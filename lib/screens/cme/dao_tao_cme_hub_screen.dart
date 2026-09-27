import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../features/nhan_vien_v2/screens/dialogs/dao_tao_v2/dialogs/dao_tao_v2_mobile_screen.dart';
import '../../models/dao_tao_v2_models.dart';
import '../../providers/dao_tao_v2_provider.dart';
import 'cme_screen.dart';

class DaoTaoCmeHubScreen extends StatelessWidget {
  const DaoTaoCmeHubScreen({super.key});

  static const Color _primary = Color(0xFF087DBA);
  static const Color _navy = Color(0xFF15354C);
  static const Color _background = Color(0xFFF3F7FA);

  void _openTraining(BuildContext context) {
    final provider = context.read<DaoTaoV2Provider>();
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider<DaoTaoV2Provider>.value(
          value: provider,
          child: const DaoTaoV2MobileScreen(),
        ),
      ),
    );
  }

  void _openCme(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const CmeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DaoTaoV2Provider>();
    final classes = provider.danhSach.take(2).toList();

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: _navy,
        title: const Text(
          'Đào tạo & CME',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Làm mới lớp đào tạo',
            onPressed: provider.isLoading ? null : provider.loadDanhSach,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: provider.loadDanhSach,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(15, 16, 15, 32),
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 18),
            _buildSectionTitle(
              icon: Icons.school_rounded,
              title: 'Lớp đào tạo',
              subtitle: 'Các lớp đang còn thời hạn đăng ký',
              count: provider.danhSach.length,
            ),
            const SizedBox(height: 10),
            _buildTrainingCard(context, provider, classes),
            const SizedBox(height: 22),
            _buildSectionTitle(
              icon: Icons.workspace_premium_rounded,
              title: 'Cập nhật CME',
              subtitle: 'Gửi và theo dõi chứng nhận CME của bạn',
            ),
            const SizedBox(height: 10),
            _buildCmeCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A73AC), Color(0xFF25A2CE)],
        ),
        borderRadius: BorderRadius.circular(21),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: .2),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.auto_stories_rounded, color: Colors.white, size: 38),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Phát triển chuyên môn',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Đăng ký lớp học và cập nhật CME tại một nơi.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
    required String subtitle,
    int? count,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFE4F3FA),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: _primary, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF718496),
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
        if (count != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFE4F3FA),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count lớp',
              style: const TextStyle(
                color: _primary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTrainingCard(
    BuildContext context,
    DaoTaoV2Provider provider,
    List<LopDaoTaoV2Model> classes,
  ) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openTraining(context),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFDDE8EF)),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              if (provider.isLoading && provider.danhSach.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(30),
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              else if (classes.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(22),
                  child: Row(
                    children: [
                      Icon(Icons.event_busy_outlined, color: Color(0xFF9AADB9)),
                      SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          'Hiện chưa có lớp đào tạo đang mở đăng ký.',
                          style: TextStyle(color: Color(0xFF718496)),
                        ),
                      ),
                    ],
                  ),
                )
              else
                for (int index = 0; index < classes.length; index++) ...[
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5FB),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.school_outlined,
                            color: _primary,
                            size: 21,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                classes[index].tenLopDaoTao,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _navy,
                                  fontSize: 13.5,
                                  height: 1.3,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (classes[index].ketThucDangKy != null) ...[
                                const SizedBox(height: 5),
                                Text(
                                  'Đăng ký đến ${DateFormat('dd/MM/yyyy HH:mm').format(classes[index].ketThucDangKy!)}',
                                  style: const TextStyle(
                                    color: Color(0xFF718496),
                                    fontSize: 10.5,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (classes[index].isDaDangKy)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF16845E),
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                  if (index != classes.length - 1)
                    const Divider(height: 1, indent: 14, endIndent: 14),
                ],
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFF7FAFC),
                  border: Border(top: BorderSide(color: Color(0xFFE5EDF2))),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Xem tất cả lớp',
                      style: TextStyle(
                        color: _primary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: _primary,
                      size: 18,
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

  Widget _buildCmeCard(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openCme(context),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFDDE8EF)),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEDE9FB), Color(0xFFE4F0FB)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Color(0xFF7057B7),
                  size: 27,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cập nhật CME',
                      style: TextStyle(
                        color: _navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Gửi minh chứng và theo dõi trạng thái phê duyệt CME.',
                      style: TextStyle(
                        color: Color(0xFF718496),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF8799A7)),
            ],
          ),
        ),
      ),
    );
  }
}
