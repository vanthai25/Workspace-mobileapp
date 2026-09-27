import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cham_cong_phep_provider.dart';
import 'lich_su_nghi_screen.dart';
import 'duyet_don_screen.dart';

class QuanLyNghiPhepScreen extends StatefulWidget {
  final int initialTabIndex;
  const QuanLyNghiPhepScreen({Key? key, this.initialTabIndex = 0}) : super(key: key);

  @override
  State<QuanLyNghiPhepScreen> createState() => _QuanLyNghiPhepScreenState();

}

class _QuanLyNghiPhepScreenState extends State<QuanLyNghiPhepScreen> {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChamCongPhepProvider>().checkManagerRole();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChamCongPhepProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingQuyen) {
          return const Scaffold(
            backgroundColor: Color(0xFFF5F7FA),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!provider.isManager) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5F7FA),
            appBar: AppBar(
              title: const Text('Nghỉ phép của tôi', style: TextStyle(fontWeight: FontWeight.bold)),
              centerTitle: true,
              elevation: 0,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
            body: const LichSuNghiScreen(),
          );
        }
        return DefaultTabController(
          length: 2,
          initialIndex: widget.initialTabIndex, 
          child: Scaffold(
            backgroundColor: const Color(0xFFF5F7FA),
            appBar: AppBar(
              title: const Text('Quản lý nghỉ phép', style: TextStyle(fontWeight: FontWeight.bold)),
              centerTitle: true,
              elevation: 0,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
            body: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                  child: TabBar(
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(25.0),
                      color: const Color(0xFF1274BC),
                      boxShadow: [
                        BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                      ]
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey.shade600,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    tabs: const [
                      Tab(text: 'Đơn của tôi'),
                      Tab(text: 'Duyệt đơn'),
                    ],
                  ),
                ),
                
                const Expanded(
                  child: TabBarView(
                    physics: BouncingScrollPhysics(),
                    children: [
                      LichSuNghiScreen(),
                      DuyetDonScreen(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}