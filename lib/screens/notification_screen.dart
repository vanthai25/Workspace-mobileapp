import 'package:flutter/material.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:mobileapp_bvhv/screens/dutru_detail_screen.dart';
import 'package:mobileapp_bvhv/screens/repair_detail_screen.dart';
import 'package:mobileapp_bvhv/screens/xn_trasau_list_screen.dart';
import '../models/notification_model.dart';
import '../utils/constants.dart'; 
import '../services/api_client.dart';
import 'cham_cong_phep/quan_ly_nghi_phep_screen.dart';
import 'nuocthai_list_screen.dart'; 

class NotificationScreen extends StatefulWidget {
  final String maNv;

  const NotificationScreen({super.key, required this.maNv});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<AppNotification> _notifications = [];
  bool _isLoading = true;

  // 🔥 ĐÃ THÊM: State lưu bộ lọc hiện tại
  String _selectedFilter = 'ALL';

  // 🔥 ĐÃ THÊM: Danh sách các bộ lọc
  final List<Map<String, String>> _filters = [
    {'id': 'ALL', 'name': 'Tất cả'},
    {'id': 'DU_TRU', 'name': 'Dự trù'},
    {'id': 'SUA_CHUA', 'name': 'Sửa chữa'},
    {'id': 'NUOC_THAI', 'name': 'Nước thải'},
    {'id': 'NGHI_PHEP', 'name': 'Nghỉ phép'},
    {'id': 'XNTRASAU', 'name': 'XN Trả sau'},
    {'id': 'OTHER', 'name': 'Khác'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final dio = ApiClient().dio;
      final response = await dio.get(
        '${AppConstants.baseUrl}/AppNotification/my-notifications',
        queryParameters: {'maNv': widget.maNv},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        if (mounted) {
          setState(() {
            _notifications = data.map((json) => AppNotification.fromJson(json)).toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('Lỗi tải thông báo: $e');
    }
  }
  Future<void> _updateAppBadge() async {
    if (await FlutterAppBadger.isAppBadgeSupported()) {
      final unreadCount = _notifications.where((n) => !n.isRead).length;
      if (unreadCount > 0) {
        FlutterAppBadger.updateBadgeCount(unreadCount);
      } else {
        FlutterAppBadger.removeBadge();
      }
    }
  }
  Future<void> _markAsRead(AppNotification notif) async {
    if (notif.isRead) return;

    setState(() => notif.isRead = true);
    
    _updateAppBadge();
    
    try {
      final dio = ApiClient().dio;
      await dio.put('${AppConstants.baseUrl}/AppNotification/mark-as-read/${notif.id}');
    } catch (e) {
      debugPrint('Lỗi đánh dấu đọc: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      for (var notif in _notifications) {
        notif.isRead = true;
      }
    });
    
    FlutterAppBadger.removeBadge();

    try {
      final dio = ApiClient().dio;
      await dio.put(
        '${AppConstants.baseUrl}/AppNotification/mark-all-read',
        queryParameters: {'maNv': widget.maNv},
      );
    } catch (e) {
      debugPrint('Lỗi đánh dấu tất cả: $e');
    }
  }

  // 🔥 ĐÃ THÊM: Hàm lọc danh sách hiển thị
  List<AppNotification> get _filteredNotifications {
    if (_selectedFilter == 'ALL') return _notifications;

    if (_selectedFilter == 'OTHER') {
      return _notifications.where((n) {
        final type = n.notificationType ?? '';
        return !type.startsWith('DU_TRU') &&
               !type.startsWith('SUA_CHUA') &&
               !type.startsWith('NUOC_THAI') &&
               !type.startsWith('NGHI_PHEP') &&
               !type.startsWith('XNTRASAU');
      }).toList();
    }

    return _notifications.where((n) {
      return (n.notificationType ?? '').startsWith(_selectedFilter);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Vẫn đếm tổng số thông báo chưa đọc của TOÀN BỘ (không phụ thuộc bộ lọc)
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    // Danh sách đã được lọc để vẽ UI
    final displayList = _filteredNotifications;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Nền màu xám xanh nhạt sang trọng
      appBar: AppBar(
        title: const Text('Thông báo', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: const Color(0xFF1274BC),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          if (unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton.icon(
                onPressed: _markAllAsRead,
                icon: const Icon(Icons.done_all_rounded, color: Colors.white, size: 18),
                label: const Text('Đã đọc', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // 🔥 ĐÃ THÊM: Thanh cuộn Filter (Chỉ hiện khi đã load xong dữ liệu)
          if (!_isLoading)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: _filters.map((filter) {
                    bool isSelected = _selectedFilter == filter['id'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          filter['name']!,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey.shade700,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: const Color(0xFF1274BC),
                        checkmarkColor: Colors.white,
                        backgroundColor: Colors.grey.shade100,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        onSelected: (bool selected) {
                          setState(() {
                            _selectedFilter = filter['id']!;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

          // DANH SÁCH THÔNG BÁO
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1274BC)))
                : displayList.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        color: const Color(0xFF1274BC),
                        onRefresh: _fetchNotifications,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: 12, bottom: 40),
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: displayList.length,
                          itemBuilder: (context, index) {
                            return _buildNotificationItem(displayList[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // --- GIAO DIỆN KHI KHÔNG CÓ THÔNG BÁO ---
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Icon(Icons.notifications_off_rounded, size: 60, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 24),
          Text(
            _selectedFilter == 'ALL' ? 'Không có thông báo nào' : 'Không có thông báo loại này',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter == 'ALL' ? 'Khi có thông báo mới, chúng sẽ xuất hiện ở đây.' : 'Hãy chọn tất cả để xem các thông báo khác.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // --- GIAO DIỆN TỪNG THẺ THÔNG BÁO ---
  Widget _buildNotificationItem(AppNotification notif) {
    bool isRead = notif.isRead;
    bool isSystem = notif.notificationType?.startsWith('HE_THONG') == true;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : const Color(0xFFF0F8FF), 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRead ? Colors.grey.shade200 : const Color(0xFF1274BC).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          if (!isRead)
            BoxShadow(
              color: const Color(0xFF1274BC).withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _markAsRead(notif);

            if (notif.notificationType != null && notif.notificationType!.contains('|')) {
              final parts = notif.notificationType!.split('|');
              final type = parts[0];
              final id = parts[1];

              if (type == 'DU_TRU') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => DuTruDetailScreen(maPhieu: id)));
              } 
              else if (type == 'SUA_CHUA') {
                final repairId = int.tryParse(id) ?? 0; 
                if (repairId > 0) {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => RepairDetailScreen(repairId: repairId)));
                }
              }
              else if (type == 'NUOC_THAI') {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => NuocThaiListScreen())
                );
              }
              else if (type == 'NGHI_PHEP') {
                Navigator.push(
                  context, 
                  MaterialPageRoute(
                    builder: (context) => const QuanLyNghiPhepScreen(initialTabIndex: 1)
                  )
                );
              }
              else if (type == 'XNTRASAU') {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => const XNTraSauListScreen())
                );
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon bên trái
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isRead ? Colors.grey.shade100 : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      if (!isRead)
                        BoxShadow(
                          color: const Color(0xFF1274BC).withOpacity(0.15),
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                    ]
                  ),
                  child: Icon(
                    isSystem ? Icons.info_rounded : Icons.notifications_active_rounded,
                    color: isRead ? Colors.grey.shade400 : const Color(0xFF1274BC),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Nội dung chữ
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notif.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                                color: isRead ? Colors.grey.shade700 : const Color(0xFF2C3E50),
                              ),
                            ),
                          ),
                          // Chấm đỏ góc phải nếu chưa đọc
                          if (!isRead)
                            Container(
                              width: 8, height: 8,
                              margin: const EdgeInsets.only(left: 8),
                              decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                            )
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notif.body,
                        style: TextStyle(
                          fontSize: 13,
                          color: isRead ? Colors.grey.shade500 : Colors.black87,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Thời gian
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text(
                            '${notif.createdAt.day.toString().padLeft(2, '0')}/${notif.createdAt.month.toString().padLeft(2, '0')}/${notif.createdAt.year} lúc ${notif.createdAt.hour.toString().padLeft(2, '0')}:${notif.createdAt.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
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