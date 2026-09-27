import 'package:flutter/material.dart';

import 'baocom_screen.dart';
import 'su_kien/su_kien_screen.dart';

class BaoComHubScreen extends StatelessWidget {
  const BaoComHubScreen({
    super.key,
  });

  static const Color primaryColor =
      Color(0xFF1274BC);

  static const Color bgColor =
      Color(0xFFF4F7FB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,

      appBar: AppBar(
        title: const Text(
          'Báo cơm & Sự kiện',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            16,
            20,
            16,
            30,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // =================================================
              // TIÊU ĐỀ
              // =================================================

              const Text(
                'Tiện ích',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(
                    0xFF25313C,
                  ),
                ),
              ),

              const SizedBox(
                height: 5,
              ),

              Text(
                'Chọn chức năng bạn muốn sử dụng',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              // =================================================
              // BÁO CƠM
              // =================================================

              _buildMenuCard(
                context: context,
                icon:
                    Icons.restaurant_rounded,
                title:
                    'Báo cơm',
                description:
                    'Đăng ký và quản lý bữa ăn hằng ngày',
                color:
                    Colors.redAccent,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const BaoComScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(
                height: 14,
              ),

              // =================================================
              // SỰ KIỆN
              // =================================================

              _buildMenuCard(
                context: context,
                icon:
                    Icons.celebration_rounded,
                title:
                    'Sự kiện',
                description:
                    'Đăng ký và quản lý các sự kiện của bạn',
                color:
                    primaryColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const SuKienScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================
  // MENU CARD
  // ===========================================================

  Widget _buildMenuCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          20,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              0.055,
            ),
            blurRadius: 14,
            offset: const Offset(
              0,
              6,
            ),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(
          20,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            20,
          ),
          child: Padding(
            padding: const EdgeInsets.all(
              16,
            ),
            child: Row(
              children: [
                // =============================================
                // ICON
                // =============================================

                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: color.withOpacity(
                      0.10,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      17,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 29,
                  ),
                ),

                const SizedBox(
                  width: 14,
                ),

                // =============================================
                // TEXT
                // =============================================

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.w900,
                          color: Color(
                            0xFF25313C,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 5,
                      ),

                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          color:
                              Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  width: 8,
                ),

                // =============================================
                // ARROW
                // =============================================

                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withOpacity(
                      0.08,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons
                        .arrow_forward_ios_rounded,
                    size: 15,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}