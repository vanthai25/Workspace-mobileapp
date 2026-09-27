import 'package:flutter/material.dart';
import 'taisan_screen.dart';
import 'repair_list_screen.dart';

class TaiSanHubScreen extends StatelessWidget {
  const TaiSanHubScreen({super.key});

  final Color primaryColor = const Color(0xFF1274BC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text('Quản lý Tài sản', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 8, bottom: 16, top: 8),
              child: Text(
                'Vui lòng chọn phân hệ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
              ),
            ),
            _buildActionCard(
              context: context,
              title: 'Danh sách Tài sản',
              subtitle: 'Tra cứu thông tin, vị trí và lịch sử của tài sản, thiết bị.',
              icon: Icons.inventory_rounded,
              color: Colors.teal,
              destination: const TaiSanScreen(),
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              context: context,
              title: 'Phiếu sửa chữa',
              subtitle: 'Tạo mới, tiếp nhận và theo dõi tiến độ sửa chữa tài sản.',
              icon: Icons.engineering_rounded,
              color: Colors.orange.shade700,
              destination: const RepairListScreen(),
            ),
          ],
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
    required Widget destination,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
        },
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                    const SizedBox(height: 6),
                    Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 30),
            ],
          ),
        ),
      ),
    );
  }
}