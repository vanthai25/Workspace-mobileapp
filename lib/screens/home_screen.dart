import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:mobileapp_bvhv/screens/diennuoc_list_screen.dart';
import 'package:mobileapp_bvhv/screens/dutru_detail_screen.dart';
import 'package:mobileapp_bvhv/screens/nuocthai_list_screen.dart';
import 'package:mobileapp_bvhv/screens/repair_detail_screen.dart';
import 'package:mobileapp_bvhv/screens/xn_trasau_list_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
// import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import '../features/khth/khth_popup_dialog.dart';
import '../features/khth/khth_service.dart';
import '../main.dart';
import '../models/baocom_menu.dart';
import '../models/baocom_model.dart';
import '../models/su_kien_v2_models.dart';
import '../providers/dao_tao_v2_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_client.dart';
import '../services/bao_com_lech_service.dart';
import '../services/taptin_service.dart';
import '../services/baocom_service.dart';
import '../models/taptin_model.dart';
import '../utils/constants.dart';
// import '../utils/notification_router.dart';
import '../widgets/home_event_effect_layer.dart';
import '../widgets/quick_baocom_widget.dart';
import '../widgets/birthday_banner.dart';
import '../widgets/su_kien_home_carousel.dart';
import '../widgets/quick_dao_tao_widget.dart';
import 'cme/dao_tao_cme_hub_screen.dart';
import 'bao_com_hub_screen.dart';
import 'bao_com_lech/bao_com_lech_screen.dart';
import 'cham_cong_bo_sung/chamcong_bosung_hub_screen.dart';
import 'cham_truc/cham_truc_screen.dart';
import 'danhbatruc_screen.dart';
import 'cham_cong_phep/quan_ly_nghi_phep_screen.dart';
import 'luong/luong_screen.dart';
import 'taisan_hub_screen.dart';
import 'dutru_list_screen.dart';
// import 'login_screen.dart';
import 'profile_screen.dart';
import 'menu_screen.dart';
import 'notification_screen.dart';

class _WebQuickActionData {
  const _WebQuickActionData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.builder,
    this.onTap,
  }) : assert(builder != null || onTap != null);

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final WidgetBuilder? builder;
  final VoidCallback? onTap;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onOpenTraining});

  final VoidCallback? onOpenTraining;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  static const double _desktopWebBreakpoint = 900;
  SuKienV2Model? _homeEffectEvent;
  bool _eventMotionPaused = false;
  final TaptinService _tapTinService = TaptinService();
  final KhthService _khthService = KhthService(
    ApiClient().dio,
    AppConstants.baseUrl,
  );

  final Color primaryColor = const Color(0xFF1274BC);
  final Color secondaryColor = const Color(0xFF0A4E80);
  final Color bgColor = const Color(0xFFF5F7FA);

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<TapTin> _recentNews = [];
  BaoCom? _todayMeal;
  BaoComMenu? _todayMenu;

  bool _isLoadingNews = true;
  bool _isRefreshingWeb = false;
  bool _isLoggingOutWeb = false;
  bool _isOpeningKhth = false;
  int _eventCarouselRevision = 0;
  int _unreadCount = 0;
  int _baoComLechCount = 0;
  void _handleNotificationClick(Map<String, dynamic> data) {
    if (!mounted) return;

    String type = data['type']?.toString() ?? '';
    String id = data['id']?.toString() ?? '';

    if (type.contains('|')) {
      var parts = type.split('|');
      type = parts[0];
      if (parts.length > 1) {
        id = parts[1];
      }
    }

    debugPrint("🔥 CLICK THÔNG BÁO -> TYPE: $type | ID: $id");

    if (type == 'DU_TRU') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => DuTruDetailScreen(maPhieu: id)),
      );
    } else if (type == 'SUA_CHUA') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RepairDetailScreen(repairId: int.parse(id)),
        ),
      );
    } else if (type == 'NUOC_THAI') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => NuocThaiListScreen()),
      );
    } else if (type == 'NGHI_PHEP') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const QuanLyNghiPhepScreen()),
      );
    } else if (type == 'XNTRASAU') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const XNTraSauListScreen()),
      );
    } else {
      debugPrint("❌ CHƯA CÓ MÀN HÌNH XỬ LÝ CHO TYPE NÀY: $type");
    }
  }

  void _onHomeEventChanged(SuKienV2Model? event) {
    final oldId = _homeEffectEvent?.idSuKien;

    final oldConfig = _homeEffectEvent?.effectConfig;

    if (oldId == event?.idSuKien &&
        oldConfig == event?.effectConfig &&
        _homeEffectEvent?.effectType == event?.effectType &&
        _homeEffectEvent?.denNgay == event?.denNgay) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _homeEffectEvent = event;
    });
  }

  @override
  void initState() {
    super.initState();

    // ========================================================
    // ANIMATION
    // ========================================================
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _animationController.forward();

    // ========================================================
    // LOAD DỮ LIỆU HOME
    // ========================================================
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      // Tin tức
      _loadCachedNews();
      _fetchRecentNews();

      // Báo cơm
      _fetchTodayData();
      _fetchBaoComLechCount();

      // Thông báo
      _fetchUnreadCount();

      // ======================================================
      // XỬ LÝ THÔNG BÁO KHI APP ĐƯỢC MỞ
      // ======================================================
      if (pendingNotificationPayload != null) {
        _handleNotificationClick(pendingNotificationPayload!);

        pendingNotificationPayload = null;
      }
    });

    // ========================================================
    // THÔNG BÁO KHI APP ĐANG MỞ
    // ========================================================
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (!mounted) {
        return;
      }

      _fetchUnreadCount();
    });

    // ========================================================
    // CLICK THÔNG BÁO
    // ========================================================
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (!mounted) {
        return;
      }

      _handleNotificationClick(message.data);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Điều hướng whitelist cho actionType=screen của banner sự kiện.
  void _openEventScreen(String route) {
    switch (route.trim().toLowerCase()) {
      case 'dao-tao':
        if (kIsWeb &&
            MediaQuery.sizeOf(context).width >= _desktopWebBreakpoint) {
          if (widget.onOpenTraining != null) {
            widget.onOpenTraining!();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Màn Đào tạo chưa được cấu hình.')),
            );
          }
        } else {
          _openMobileDaoTao();
        }
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chưa hỗ trợ màn hình "$route" từ banner.')),
        );
    }
  }

  Future<void> _openKhth() async {
    if (_isOpeningKhth) {
      return;
    }

    setState(() => _isOpeningKhth = true);

    try {
      final String url = await _khthService.getOpenUrl();
      if (!mounted) {
        return;
      }

      if (kIsWeb) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => KhthPopupDialog(url: url),
        );
      } else {
        final bool launched = await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
        if (!launched) {
          throw Exception('Không thể mở Kế hoạch tổng hợp.');
        }
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      final String message = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFD54F4F),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isOpeningKhth = false);
      }
    }
  }

  // --- API CALLS ---
  Future<void> _fetchTodayData() async {
    final auth = context.read<AuthProvider>();
    final manv = auth.currentManv ?? '';

    await Future.wait([_fetchTodayMeal(manv), _fetchTodayMenu()]);
  }

  Future<void> _fetchBaoComLechCount() async {
    try {
      final int count = await BaoComLechService().getCurrentMonthCount();

      if (!mounted) {
        return;
      }

      setState(() {
        _baoComLechCount = count;
      });
    } catch (e) {
      debugPrint(
        'Home: lỗi lấy count '
        'lệch cơm: $e',
      );
    }
  }

  Future<void> _fetchTodayMeal(String maNV) async {
    if (maNV.isEmpty) return;
    try {
      String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final list = await BaoComService().getBaoCom(
        nguoibao: maNV,
        fromDate: todayStr,
        toDate: todayStr,
      );
      final myMeals = list.where((m) => m.manv == maNV).toList();
      if (mounted && (kIsWeb || myMeals.isNotEmpty)) {
        setState(() {
          _todayMeal = myMeals.isNotEmpty ? myMeals.first : null;
        });
      }
    } catch (e) {
      debugPrint("Home: Lỗi tải phiếu cơm: $e");
    }
  }

  Future<void> _fetchTodayMenu() async {
    try {
      final dio = ApiClient().dio;
      final response = await dio.get(
        '${AppConstants.baseUrl}/BaoComMenu/today',
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        if (mounted) {
          setState(
            () => _todayMenu = BaoComMenu.fromJson(response.data['data']),
          );
        }
      }
    } catch (e) {
      debugPrint("Home: Hôm nay chưa có thực đơn hoặc lỗi: $e");
    }
  }

  Future<void> _updateAppBadge(int count) async {
    if (kIsWeb) {
      return;
    }

    try {
      final bool isSupported = await FlutterAppBadger.isAppBadgeSupported();

      if (!isSupported) {
        return;
      }

      if (count > 0) {
        FlutterAppBadger.updateBadgeCount(count);
      } else {
        FlutterAppBadger.removeBadge();
      }
    } catch (e) {
      debugPrint('Home: Không thể cập nhật app badge: $e');
    }
  }

  Future<void> _fetchUnreadCount() async {
    final String? manv = context.read<AuthProvider>().currentManv;

    if (manv == null || manv.trim().isEmpty) {
      return;
    }

    try {
      final dio = ApiClient().dio;

      final response = await dio.get(
        '${AppConstants.baseUrl}'
        '/AppNotification/unread-count',
        queryParameters: {'maNv': manv.trim()},
      );

      if (response.statusCode != 200) {
        return;
      }

      final dynamic rawCount = response.data['count'];

      final int count = rawCount is int
          ? rawCount
          : int.tryParse(rawCount?.toString() ?? '') ?? 0;

      if (!mounted) {
        return;
      }

      setState(() {
        _unreadCount = count;
      });

      await _updateAppBadge(count);
    } catch (e) {
      debugPrint('Lỗi đếm thông báo: $e');
    }
  }

  Future<void> _loadCachedNews() async {
    final prefs = await SharedPreferences.getInstance();
    String? cachedData = prefs.getString('cached_recent_news');

    if (cachedData != null && mounted) {
      List data = jsonDecode(cachedData);
      setState(() {
        _recentNews = data.map((json) => TapTin.fromJson(json)).toList();
        _isLoadingNews = false;
      });
    }
  }

  Future<void> _fetchRecentNews() async {
    try {
      final dio = ApiClient().dio;
      final response = await dio.get('${AppConstants.baseUrl}/Taptin/latest');

      if (response.statusCode == 200 && response.data['success'] == true) {
        List data = response.data['data'] ?? [];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_recent_news', jsonEncode(data));

        if (mounted) {
          setState(() {
            _recentNews = data.map((json) => TapTin.fromJson(json)).toList();
            _isLoadingNews = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Lỗi tải tin tức: $e");
      if (mounted && kIsWeb) {
        setState(() => _isLoadingNews = false);
      }
    }
  }

  Future<void> _refreshWebDashboard() async {
    if (_isRefreshingWeb) {
      return;
    }

    setState(() => _isRefreshingWeb = true);

    try {
      final List<Future<void>> refreshTasks = <Future<void>>[
        _fetchTodayData(),
        _fetchBaoComLechCount(),
        _fetchUnreadCount(),
        _fetchRecentNews(),
        context.read<DaoTaoV2Provider>().loadDanhSach(),
      ];

      await Future.wait<void>(refreshTasks);
      if (mounted) setState(() => _eventCarouselRevision++);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Chưa thể làm mới toàn bộ dữ liệu. Vui lòng thử lại.',
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshingWeb = false);
      }
    }
  }

  void _openMobileDaoTao() {
    final provider = context.read<DaoTaoV2Provider>();

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider<DaoTaoV2Provider>.value(
          value: provider,
          child: const DaoTaoCmeHubScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool useDesktopWeb =
        kIsWeb && MediaQuery.sizeOf(context).width >= _desktopWebBreakpoint;

    if (useDesktopWeb) {
      return _buildWebHome(context);
    }

    return Scaffold(
      backgroundColor: bgColor,

      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 90),

            child: Stack(
              children: [
                _buildBackgroundHeader(),

                SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      const SizedBox(height: 10),
                      _buildHeaderContent(context),
                      const SizedBox(height: 50),

                      SuKienHomeCarousel(
                        key: const ValueKey('event-mobile'),
                        refreshRevision: _eventCarouselRevision,
                        motionPaused: _eventMotionPaused,
                        onMotionPausedChanged: (value) =>
                            setState(() => _eventMotionPaused = value),

                        onOpenScreen: _openEventScreen,

                        onActiveEventChanged: _onHomeEventChanged,
                      ),

                      // 1. THẺ BÁO CƠM
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            Padding(
                              // QuickBaoComWidget dùng Card có margin mặc định 4px.
                              // 20 + 4 = 24px, đồng bộ với các card Home bên dưới.
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: QuickBaoComWidget(
                                preloadedMeal: _todayMeal,
                                preloadedMenu: _todayMenu,
                                onRefreshNeeded: _fetchTodayData,
                                baoComLechCount: _baoComLechCount,
                                onBaoComLechTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const BaoComLechScreen(),
                                    ),
                                  ).then((_) {
                                    _fetchBaoComLechCount();
                                  });
                                },
                              ),
                            ),

                            QuickDaoTaoWidget(onTap: _openMobileDaoTao),
                          ],
                        ),
                      ),

                      FadeTransition(
                        opacity: _fadeAnimation,
                        child:
                            const BirthdayBanner(), // Chỉ tự hiện khi có người sinh nhật
                      ),

                      const SizedBox(height: 16),

                      // 3. MENU GRID VÀ CÁC THÀNH PHẦN KHÁC
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.only(
                                  top: 24,
                                  bottom: 8,
                                  left: 12,
                                  right: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: _buildGridMenu(),
                              ),
                              const SizedBox(height: 35),
                              Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: primaryColor,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Văn bản nội bộ',
                                    style: TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildNewsSlider(),

                              // 🔥 GỌI KHỐI SỐ TRỰC TOÀN HỆ THỐNG Ở ĐÂY (NGAY SAU VĂN BẢN NỘI BỘ)
                              const SizedBox(height: 4),
                              _buildHotlineCard(context),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Positioned.fill(
            child: HomeEventEffectLayer(
              event: _homeEffectEvent,
              enabled: !_eventMotionPaused,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebHome(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();
    final DaoTaoV2Provider trainingProvider = context.watch<DaoTaoV2Provider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: Stack(
        children: [
          Column(
            children: [
              _buildWebTopBar(auth),

              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final bool useTwoColumns = constraints.maxWidth >= 960;
                    final double horizontalPadding =
                        constraints.maxWidth >= 1280
                        ? 20
                        : constraints.maxWidth >= 720
                        ? 16
                        : 12;

                    return SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        20,
                        horizontalPadding,
                        28,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1800),
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildWebWelcomeBanner(auth),
                                SuKienHomeCarousel(
                                  key: const ValueKey('event-web'),
                                  refreshRevision: _eventCarouselRevision,
                                  motionPaused: _eventMotionPaused,
                                  onMotionPausedChanged: (value) => setState(
                                    () => _eventMotionPaused = value,
                                  ),

                                  desktop: true,

                                  onOpenScreen: _openEventScreen,

                                  onActiveEventChanged: _onHomeEventChanged,
                                ),
                                const BirthdayBanner(),
                                const SizedBox(height: 18),
                                _buildWebStats(trainingProvider),
                                const SizedBox(height: 18),
                                _buildWebDashboardContent(
                                  trainingProvider: trainingProvider,
                                  useTwoColumns: useTwoColumns,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          Positioned.fill(
            child: HomeEventEffectLayer(
              event: _homeEffectEvent,
              enabled: !_eventMotionPaused,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebTopBar(AuthProvider auth) {
    final String manv = auth.currentManv ?? '';
    final String employeeName = auth.currentTenNV ?? 'Nhân viên';

    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5EAF1))),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool compact = constraints.maxWidth < 720;
          final bool veryCompact = constraints.maxWidth < 520;

          return Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!compact)
                      const Text(
                        'TRANG CHỦ  /  TỔNG QUAN',
                        style: TextStyle(
                          color: Color(0xFF8A9AA8),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                    if (!compact) const SizedBox(height: 4),
                    const Text(
                      'Tổng quan hệ thống',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFF172B3A),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              if (!compact) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F9FC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5EAF1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 15,
                        color: Color(0xFF647789),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _webDateLabel(),
                        style: const TextStyle(
                          color: Color(0xFF506577),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],
              if (!veryCompact) ...[
                Tooltip(
                  message: 'Làm mới dữ liệu',
                  child: IconButton(
                    onPressed: _isRefreshingWeb ? null : _refreshWebDashboard,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF4F8FB),
                      foregroundColor: primaryColor,
                      fixedSize: const Size(42, 42),
                    ),
                    icon: _isRefreshingWeb
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded, size: 21),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Badge(
                isLabelVisible: _unreadCount > 0,
                label: Text(
                  _unreadCount > 99 ? '99+' : '$_unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                backgroundColor: const Color(0xFFEF5350),
                offset: const Offset(-2, 1),
                child: Tooltip(
                  message: 'Thông báo',
                  child: IconButton(
                    onPressed: manv.isEmpty
                        ? null
                        : () => _openWebNotifications(manv),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF4F8FB),
                      foregroundColor: const Color(0xFF3E5668),
                      fixedSize: const Size(42, 42),
                    ),
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      size: 21,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              if (!compact)
                Container(width: 1, height: 34, color: const Color(0xFFE2E8EE)),
              if (!compact) const SizedBox(width: 14),
              PopupMenuButton<String>(
                enabled: manv.isNotEmpty && !_isLoggingOutWeb,
                tooltip: 'Tài khoản',
                position: PopupMenuPosition.under,
                offset: const Offset(0, 8),
                color: Colors.white,
                surfaceTintColor: Colors.white,
                elevation: 12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE3E9EF)),
                ),
                onSelected: (action) async {
                  await _handleWebAccountAction(action, auth);
                },
                itemBuilder: (popupContext) => [
                  PopupMenuItem<String>(
                    enabled: false,
                    height: 62,
                    child: SizedBox(
                      width: 230,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            employeeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF213949),
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Mã nhân viên: $manv',
                            style: const TextStyle(
                              color: Color(0xFF8495A3),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const PopupMenuDivider(height: 1),
                  const PopupMenuItem<String>(
                    value: 'change_password',
                    height: 52,
                    child: Row(
                      children: [
                        Icon(
                          Icons.lock_reset_rounded,
                          color: Color(0xFF526B7C),
                          size: 21,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Đổi mật khẩu',
                          style: TextStyle(
                            color: Color(0xFF304A5B),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(height: 1),
                  const PopupMenuItem<String>(
                    value: 'logout',
                    height: 52,
                    child: Row(
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          color: Color(0xFFD54F4F),
                          size: 21,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Đăng xuất',
                          style: TextStyle(
                            color: Color(0xFFD54F4F),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 5,
                    ),
                    child: Row(
                      children: [
                        if (_isLoggingOutWeb)
                          const SizedBox(
                            width: 38,
                            height: 38,
                            child: Padding(
                              padding: EdgeInsets.all(9),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        else
                          _buildWebAvatar(
                            auth.currentAvatar,
                            employeeName,
                            radius: 19,
                          ),
                        if (!compact) ...[
                          const SizedBox(width: 10),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 150),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  employeeName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF213949),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  manv,
                                  style: const TextStyle(
                                    color: Color(0xFF8A9AA8),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Color(0xFF8A9AA8),
                            size: 18,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleWebAccountAction(String action, AuthProvider auth) async {
    if (action == 'change_password') {
      await Navigator.pushNamed(
        context,
        '/change-password',
        arguments: <String, dynamic>{
          'isForced': false,
          'manv': auth.currentManv,
        },
      );
      return;
    }

    if (action != 'logout' || _isLoggingOutWeb) {
      return;
    }

    setState(() => _isLoggingOutWeb = true);

    try {
      await auth.logout();

      if (!mounted) {
        return;
      }

      setState(() => _isLoggingOutWeb = false);
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => _isLoggingOutWeb = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa thể đăng xuất. Vui lòng thử lại.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFFD54F4F),
        ),
      );
    }
  }

  Widget _buildWebWelcomeBanner(AuthProvider auth) {
    final String employeeName = auth.currentTenNV ?? 'Nhân viên';
    final String manv = auth.currentManv ?? '';
    final String department = auth.currentMaKhoa ?? '';

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact = constraints.maxWidth < 720;

        final Widget profileButton = OutlinedButton.icon(
          onPressed: manv.isEmpty
              ? null
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileScreen(manv: manv),
                    ),
                  );
                },
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(color: Colors.white.withValues(alpha: 0.42)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
          icon: const Icon(Icons.person_outline_rounded, size: 18),
          label: const Text(
            'Xem hồ sơ',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        );

        return Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1683CF), Color(0xFF0F69AA), Color(0xFF0A4E80)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F69AA).withValues(alpha: 0.18),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -105,
                right: -55,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.09),
                      width: 36,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -100,
                right: 180,
                child: Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 22 : 30,
                  vertical: compact ? 24 : 28,
                ),
                child: compact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWebWelcomeText(employeeName, manv, department),
                          const SizedBox(height: 20),
                          profileButton,
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: _buildWebWelcomeText(
                              employeeName,
                              manv,
                              department,
                            ),
                          ),
                          const SizedBox(width: 24),
                          profileButton,
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWebWelcomeText(
    String employeeName,
    String manv,
    String department,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            _webGreeting().toUpperCase(),
            style: const TextStyle(
              color: Color(0xFFD7EEFC),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.05,
            ),
          ),
        ),
        const SizedBox(height: 13),
        Text(
          'Xin chào, $employeeName',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            height: 1.18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.45,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          department.isEmpty
              ? 'Mã nhân viên: $manv'
              : 'Mã nhân viên: $manv  •  Khoa/Phòng: $department',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.76),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Theo dõi công việc và truy cập nhanh các tiện ích nội bộ của bạn.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildWebStats(DaoTaoV2Provider trainingProvider) {
    final int selectedMeals =
        (_todayMeal?.ansang == true ? 1 : 0) +
        (_todayMeal?.anchieu == true ? 1 : 0);
    final List<Widget> cards = [
      _buildWebStatCard(
        icon: Icons.notifications_none_rounded,
        color: const Color(0xFF1274BC),
        value: '$_unreadCount',
        title: 'Thông báo chưa đọc',
        note: _unreadCount > 0 ? 'Đang chờ bạn xem' : 'Đã cập nhật đầy đủ',
        onTap: () {
          final String manv = context.read<AuthProvider>().currentManv ?? '';
          if (manv.isNotEmpty) {
            _openWebNotifications(manv);
          }
        },
      ),
      _buildWebStatCard(
        icon: Icons.restaurant_menu_rounded,
        color: const Color(0xFF0E9F7B),
        value: '$selectedMeals/2',
        title: 'Bữa ăn đã đăng ký',
        note: 'Bữa trưa và bữa tối hôm nay',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BaoComHubScreen()),
        ),
      ),
      _buildWebStatCard(
        icon: Icons.school_outlined,
        color: const Color(0xFFF39C4A),
        value: '${trainingProvider.danhSach.length}',
        title: 'Lớp đào tạo đang mở',
        note: 'Còn thời hạn đăng ký',
        onTap: widget.onOpenTraining,
      ),
      _buildWebStatCard(
        icon: Icons.description_outlined,
        color: const Color(0xFF7656C8),
        value: '${_recentNews.length}',
        title: 'Văn bản gần đây',
        note: _isLoadingNews
            ? 'Đang đồng bộ dữ liệu'
            : 'Thông tin nội bộ mới nhất',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final int columnCount = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 560
            ? 2
            : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 116,
          ),
          itemBuilder: (context, index) => cards[index],
        );
      },
    );
  }

  Widget _buildWebStatCard({
    required IconData icon,
    required Color color,
    required String value,
    required String title,
    required String note,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
        side: const BorderSide(color: Color(0xFFE5EAF1)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        hoverColor: color.withValues(alpha: 0.035),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 23),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        color: Color(0xFF172B3A),
                        fontSize: 26,
                        height: 1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF425A6B),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF91A0AC),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFFC4CED6),
                  size: 12,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebDashboardContent({
    required DaoTaoV2Provider trainingProvider,
    required bool useTwoColumns,
  }) {
    if (!useTwoColumns) {
      return Column(
        children: [
          _buildWebMealCard(),
          const SizedBox(height: 18),
          _buildWebTrainingCard(trainingProvider),
          const SizedBox(height: 18),
          _buildWebDocumentsCard(),
          const SizedBox(height: 18),
          _buildWebSupportCard(),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Column(children: [_buildWebDocumentsCard()])),
        const SizedBox(width: 18),
        SizedBox(
          width: 410,
          child: Column(
            children: [
              _buildWebMealCard(),
              const SizedBox(height: 18),
              _buildWebTrainingCard(trainingProvider),
              const SizedBox(height: 18),
              _buildWebSupportCard(),
            ],
          ),
        ),
      ],
    );
  }

  List<_WebQuickActionData> _webQuickActions(AuthProvider auth) {
    final List<_WebQuickActionData> actions = [
      _WebQuickActionData(
        icon: Icons.fingerprint_rounded,
        title: 'Chấm công',
        subtitle: 'Bổ sung & theo dõi công',
        color: const Color(0xFF0E9F7B),
        builder: (_) => const ChamCongBoSungHubScreen(),
      ),
      _WebQuickActionData(
        icon: Icons.account_balance_wallet_outlined,
        title: 'Bảng lương',
        subtitle: 'Tra cứu thu nhập',
        color: const Color(0xFF365FD9),
        builder: (_) => const LuongScreen(),
      ),
      _WebQuickActionData(
        icon: Icons.calendar_month_outlined,
        title: 'Lịch trực',
        subtitle: 'Theo dõi lịch cá nhân',
        color: const Color(0xFFE95C5C),
        builder: (_) => const ChamTrucScreen(),
      ),
      _WebQuickActionData(
        icon: Icons.school_outlined,
        title: 'Đào tạo',
        subtitle: 'Lớp học & đăng ký',
        color: const Color(0xFFB88714),
        onTap: widget.onOpenTraining,
      ),
      // _WebQuickActionData(
      //   icon: Icons.menu_book_rounded,
      //   title: 'Thực đơn',
      //   subtitle: 'Món ăn hôm nay',
      //   color: const Color(0xFF7A63C5),
      //   onTap: _showWebMealMenuDialog,
      // ),
      _WebQuickActionData(
        icon: Icons.inventory_2_outlined,
        title: 'Tài sản',
        subtitle: 'Quản lý và sửa chữa',
        color: const Color(0xFF168C8C),
        builder: (_) => const TaiSanHubScreen(),
      ),
      _WebQuickActionData(
        icon: Icons.request_page_outlined,
        title: 'Dự trù',
        subtitle: 'Phiếu đề nghị dự trù',
        color: const Color(0xFFF08B3E),
        builder: (_) => const DuTruListScreen(),
      ),
    ];

    if (auth.currentRoleIds.contains(4)) {
      actions.add(
        _WebQuickActionData(
          icon: Icons.water_drop_outlined,
          title: 'Nước thải',
          subtitle: 'Theo dõi vận hành',
          color: const Color(0xFF2C8ED6),
          builder: (_) => const NuocThaiListScreen(),
        ),
      );
    }
    if (auth.currentRoleIds.contains(5)) {
      actions.add(
        _WebQuickActionData(
          icon: Icons.electric_meter_outlined,
          title: 'Điện nước',
          subtitle: 'Quản lý chỉ số',
          color: const Color(0xFFA28C22),
          builder: (_) => const DienNuocListScreen(),
        ),
      );
    }
    if (auth.currentRoleIds.contains(8)) {
      actions.add(
        _WebQuickActionData(
          icon: Icons.science_outlined,
          title: 'XN trả sau',
          subtitle: 'Quản lý xét nghiệm',
          color: const Color(0xFF7A63C5),
          builder: (_) => const XNTraSauListScreen(),
        ),
      );
    }

    return actions;
  }

  // Kept for potential reuse by smaller layouts; desktop shortcuts now live in
  // MainRootScreen's sidebar.
  // ignore: unused_element
  Widget _buildWebQuickActions(AuthProvider auth) {
    final List<_WebQuickActionData> actions = _webQuickActions(auth);

    return _buildWebPanel(
      title: 'Truy cập nhanh',
      subtitle: 'Các tiện ích được cấp quyền cho tài khoản của bạn',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F6FA),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          '${actions.length} tiện ích',
          style: const TextStyle(
            color: Color(0xFF567083),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final int columnCount = constraints.maxWidth >= 1050
              ? 4
              : constraints.maxWidth >= 720
              ? 3
              : constraints.maxWidth >= 400
              ? 2
              : 1;

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: actions.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columnCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 88,
            ),
            itemBuilder: (context, index) {
              final _WebQuickActionData action = actions[index];
              return _buildWebQuickActionCard(action);
            },
          );
        },
      ),
    );
  }

  Widget _buildWebQuickActionCard(_WebQuickActionData action) {
    return Material(
      color: const Color(0xFFF8FAFC),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE5EAF1)),
      ),
      child: InkWell(
        onTap:
            action.onTap ??
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: action.builder!),
              );
            },
        borderRadius: BorderRadius.circular(14),
        hoverColor: action.color.withValues(alpha: 0.045),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(action.icon, color: action.color, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF263F50),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      action.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF8A9AA8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Color(0xFFC3CDD5),
                size: 11,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showWebMealMenuDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final double dialogHeight =
            MediaQuery.sizeOf(dialogContext).height * 0.84;

        return Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: SizedBox(
            width: 620,
            height: dialogHeight,
            child: Material(
              color: Colors.white,
              clipBehavior: Clip.antiAlias,
              borderRadius: BorderRadius.circular(22),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1274BC), Color(0xFF0A4E80)],
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.menu_book_rounded,
                            color: Colors.white,
                            size: 25,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Thực đơn hôm nay',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _webDateLabel(),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.78),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.12,
                            ),
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.close_rounded),
                          tooltip: 'Đóng',
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          _buildWebMealMenuDialogSection(
                            icon: Icons.wb_sunny_outlined,
                            color: const Color(0xFFE89A32),
                            title: 'Thực đơn trưa',
                            menu: _todayMenu?.menuTrua,
                          ),
                          const SizedBox(height: 14),
                          _buildWebMealMenuDialogSection(
                            icon: Icons.nightlight_outlined,
                            color: const Color(0xFF7656C8),
                            title: 'Thực đơn tối',
                            menu: _todayMenu?.menuToi,
                          ),
                          const SizedBox(height: 18),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: Color(0xFF91A0AC),
                                size: 16,
                              ),
                              SizedBox(width: 7),
                              Flexible(
                                child: Text(
                                  'Thực đơn có thể được cập nhật theo tình hình thực tế.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF7C8E9B),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWebMealMenuDialogSection({
    required IconData icon,
    required Color color,
    required String title,
    required String? menu,
  }) {
    final String content = menu?.trim().isNotEmpty == true
        ? menu!.trim()
        : 'Chưa cập nhật thực đơn.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  content,
                  style: const TextStyle(
                    color: Color(0xFF2E485A),
                    fontSize: 15,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebMealCard() {
    final bool hasLunch = _todayMeal?.ansang == true;
    final bool hasDinner = _todayMeal?.anchieu == true;
    final bool isLocked = DateTime.now().hour >= 8;

    return _buildWebPanel(
      title: 'Báo cơm hôm nay',
      subtitle: DateFormat('dd/MM/yyyy').format(DateTime.now()),
      trailing: _baoComLechCount > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0EE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$_baoComLechCount lệch suất',
                style: const TextStyle(
                  color: Color(0xFFD8574F),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          : null,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildWebMealStatus(
                  title: 'Bữa trưa',
                  isSelected: hasLunch,
                  icon: Icons.wb_sunny_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildWebMealStatus(
                  title: 'Bữa tối',
                  isSelected: hasDinner,
                  icon: Icons.nightlight_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: const Color(0xFFE7EDF2)),
            ),
            child: Column(
              children: [
                _buildWebMenuLine('Thực đơn trưa', _todayMenu?.menuTrua),
                const Divider(color: Color(0xFFE5EAF1), height: 18),
                _buildWebMenuLine('Thực đơn tối', _todayMenu?.menuToi),
              ],
            ),
          ),
          if (isLocked) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8EB),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.lock_clock_outlined,
                    color: Color(0xFFD88924),
                    size: 16,
                  ),
                  SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'Đã qua 08:00, thông tin suất ăn đã được khóa.',
                      style: TextStyle(
                        color: Color(0xFF9A681F),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BaoComLechScreen()),
                ).then((_) => _fetchBaoComLechCount());
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD84F4F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.warning_amber_rounded, size: 19),
              label: const Text(
                'Xem lệch cơm',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebMealStatus({
    required String title,
    required bool isSelected,
    required IconData icon,
  }) {
    final Color color = isSelected
        ? const Color(0xFF0E9F7B)
        : const Color(0xFF8293A0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFEDF9F5) : const Color(0xFFF7F9FB),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: isSelected ? const Color(0xFFBDE8DA) : const Color(0xFFE4EAF0),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF344D5E),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isSelected ? 'Đã đăng ký' : 'Chưa đăng ký',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            isSelected
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: color,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildWebMenuLine(String label, String? menu) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.restaurant_menu_rounded,
            color: primaryColor,
            size: 14,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF7A8C99),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                menu?.trim().isNotEmpty == true
                    ? menu!.trim()
                    : 'Chưa cập nhật',
                style: const TextStyle(
                  color: Color(0xFF344D5E),
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWebTrainingCard(DaoTaoV2Provider provider) {
    return _buildWebPanel(
      title: 'Lớp đào tạo đang mở',
      subtitle: 'Các lớp còn thời hạn đăng ký',
      trailing: TextButton(
        onPressed: widget.onOpenTraining,
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          minimumSize: Size.zero,
        ),
        child: const Text(
          'Xem tất cả',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ),
      child: _buildWebTrainingContent(provider),
    );
  }

  Widget _buildWebTrainingContent(DaoTaoV2Provider provider) {
    if (provider.isLoading && provider.danhSach.isEmpty) {
      return const SizedBox(
        height: 92,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (provider.danhSach.isEmpty) {
      return _buildWebEmptyState(
        icon: Icons.school_outlined,
        message: provider.errorMessage?.trim().isNotEmpty == true
            ? provider.errorMessage!
            : 'Hiện chưa có lớp đào tạo mở đăng ký.',
      );
    }

    final classes = provider.danhSach.take(3).toList();
    return Column(
      children: [
        for (int index = 0; index < classes.length; index++) ...[
          Material(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: widget.onOpenTraining,
              borderRadius: BorderRadius.circular(12),
              hoverColor: primaryColor.withValues(alpha: 0.04),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 37,
                      height: 37,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E6),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.school_outlined,
                        color: Color(0xFFF08A36),
                        size: 19,
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
                              color: Color(0xFF344D5E),
                              fontSize: 13,
                              height: 1.3,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (classes[index].ketThucDangKy != null) ...[
                            const SizedBox(height: 5),
                            Text(
                              'Đăng ký đến ${DateFormat('dd/MM/yyyy HH:mm').format(classes[index].ketThucDangKy!)}',
                              style: const TextStyle(
                                color: Color(0xFF8899A6),
                                fontSize: 11,
                              ),
                            ),
                          ],
                          if (classes[index].donViDaoTao?.trim().isNotEmpty ==
                              true) ...[
                            const SizedBox(height: 4),
                            Text(
                              classes[index].donViDaoTao!.trim(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF9AA8B3),
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (classes[index].isDaDangKy)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF7F2),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: const Text(
                          'Đã đăng ký',
                          style: TextStyle(
                            color: Color(0xFF168B6B),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (index != classes.length - 1) const SizedBox(height: 9),
        ],
      ],
    );
  }

  Widget _buildWebDocumentsCard() {
    return _buildWebPanel(
      title: 'Văn bản nội bộ',
      subtitle: 'Thông báo và tài liệu được cập nhật gần đây',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F0FC),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          '${_recentNews.length} văn bản',
          style: const TextStyle(
            color: Color(0xFF7656C8),
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      child: _buildWebDocumentsContent(),
    );
  }

  Widget _buildWebDocumentsContent() {
    if (_isLoadingNews) {
      return const SizedBox(
        height: 150,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_recentNews.isEmpty) {
      return _buildWebEmptyState(
        icon: Icons.inbox_outlined,
        message: 'Chưa có văn bản nội bộ mới.',
      );
    }

    final List<TapTin> documents = _recentNews.take(6).toList();
    return Column(
      children: [
        for (int index = 0; index < documents.length; index++) ...[
          _buildWebDocumentRow(documents[index]),
          if (index != documents.length - 1)
            const Divider(color: Color(0xFFE9EEF2), height: 1),
        ],
      ],
    );
  }

  Widget _buildWebDocumentRow(TapTin document) {
    final bool isPdf = (document.duongDan ?? '').toLowerCase().endsWith('.pdf');
    final String displayDate = _formatNewsDate(document.ngayUp);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _viewFile(document),
        hoverColor: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(11),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isPdf
                      ? const Color(0xFFFFEEEE)
                      : const Color(0xFFEDF6FC),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  isPdf
                      ? Icons.picture_as_pdf_outlined
                      : Icons.article_outlined,
                  color: isPdf
                      ? const Color(0xFFD95656)
                      : const Color(0xFF1274BC),
                  size: 20,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.tenTapTin ?? 'Thông báo nội bộ',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF314A5B),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            document.tenLoai ?? 'Văn bản nội bộ',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF8999A6),
                              fontSize: 11,
                            ),
                          ),
                        ),
                        if (displayDate.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 7),
                            child: Text(
                              '•',
                              style: TextStyle(
                                color: Color(0xFFBCC5CC),
                                fontSize: 11,
                              ),
                            ),
                          ),
                          Text(
                            displayDate,
                            style: const TextStyle(
                              color: Color(0xFF8999A6),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F8FB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      isPdf ? 'Mở PDF' : 'Chi tiết',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: primaryColor,
                      size: 12,
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

  Widget _buildWebSupportCard() {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
        side: const BorderSide(color: Color(0xFFDCE8F0)),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DanhBaTrucScreen()),
        ),
        borderRadius: BorderRadius.circular(17),
        hoverColor: const Color(0xFFF2F8FC),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF5FC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.support_agent_rounded,
                  color: primaryColor,
                  size: 23,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Số trực toàn hệ thống',
                      style: TextStyle(
                        color: Color(0xFF2D4758),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tra cứu liên hệ trực theo khoa/phòng',
                      style: TextStyle(color: Color(0xFF8798A5), fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Chi tiết',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebPanel({
    required String title,
    required String subtitle,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EAF1)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A3950).withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF243D4E),
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF8A9AA8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 12), trailing],
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildWebEmptyState({
    required IconData icon,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFB0BDC7), size: 28),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF8798A5),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebAvatar(
    String? base64String,
    String employeeName, {
    double radius = 20,
  }) {
    if (base64String != null && base64String.isNotEmpty) {
      try {
        final String cleanBase64 = base64String.contains(',')
            ? base64String.split(',').last
            : base64String;
        return CircleAvatar(
          radius: radius,
          backgroundColor: const Color(0xFFE7F2F9),
          backgroundImage: MemoryImage(base64Decode(cleanBase64)),
        );
      } catch (_) {}
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFE6F2FA),
      child: Text(
        employeeName.isNotEmpty ? employeeName[0].toUpperCase() : '?',
        style: TextStyle(
          color: primaryColor,
          fontSize: radius * 0.72,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  void _openWebNotifications(String manv) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NotificationScreen(maNv: manv)),
    ).then((_) => _fetchUnreadCount());
  }

  String _webGreeting() {
    final int hour = DateTime.now().hour;
    if (hour < 11) {
      return 'Chào buổi sáng';
    }
    if (hour < 18) {
      return 'Chào buổi chiều';
    }
    return 'Chào buổi tối';
  }

  String _webDateLabel() {
    final DateTime now = DateTime.now();
    const List<String> weekdays = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật',
    ];
    return '${weekdays[now.weekday - 1]}, ${DateFormat('dd/MM/yyyy').format(now)}';
  }

  String _formatNewsDate(String? rawDate) {
    if (rawDate == null || rawDate.trim().isEmpty) {
      return '';
    }
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(rawDate));
    } catch (_) {
      return '';
    }
  }

  // --- CÁC WIDGET THÀNH PHẦN KHÁC GIỮ NGUYÊN ---
  Widget _buildBackgroundHeader() {
    return Stack(
      children: [
        Container(
          height: 140,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [const Color(0xFF4FA5E5), primaryColor, secondaryColor],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
        ),
        Positioned(
          top: -50,
          right: -50,
          child: CircleAvatar(
            radius: 100,
            backgroundColor: Colors.white.withOpacity(0.05),
          ),
        ),
        Positioned(
          top: 60,
          left: -30,
          child: CircleAvatar(
            radius: 60,
            backgroundColor: Colors.white.withOpacity(0.08),
          ),
        ),
      ],
    );
  }

  // --- KHỐI SỐ TRỰC TOÀN HỆ THỐNG ---
  Widget _buildHotlineCard(BuildContext context) {
    const Color primaryColor = Color(0xFF1274BC); // Màu xanh chủ đạo

    return Container(
      width: double.infinity,
      height: 65,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(50),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DanhBaTrucScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Icon bên trái
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.phone_in_talk_rounded,
                    color: primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // Text ở giữa
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Liên hệ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Số trực toàn hệ thống',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ],
                  ),
                ),

                // Nút Gọi điện
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Chi tiết',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'My HungVuong',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          Row(
            children: [
              Badge(
                isLabelVisible: _unreadCount > 0,
                label: Text(
                  '$_unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: Colors.redAccent,
                offset: const Offset(-4, 4),
                child: IconButton(
                  icon: const Icon(
                    Icons.notifications_active_rounded,
                    color: Colors.white,
                  ),
                  tooltip: 'Thông báo',
                  onPressed: () {
                    final manv = context.read<AuthProvider>().currentManv;
                    if (manv != null && manv.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotificationScreen(maNv: manv),
                        ),
                      ).then((_) => _fetchUnreadCount());
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderContent(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final manv = auth.currentManv ?? '';
    final tenNhanVien = auth.currentTenNV ?? 'Nhân viên';
    final anhNhanVien = auth.currentAvatar;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              if (manv.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(manv: manv),
                  ),
                );
              }
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: _buildMiniAvatar(anhNhanVien, tenNhanVien),
                ),
                Positioned(
                  bottom: -1,
                  right: -1,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.menu_rounded,
                      size: 12,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Xin chào, $manv',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        tenNhanVien,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                ),
              ],
            ),
          ),

          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MenuScreen()),
                  );
                },
                child: Container(
                  width: 35,
                  height: 35,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.settings_outlined,
                    color: Colors.black87,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              Badge(
                isLabelVisible: _unreadCount > 0,
                label: Text(
                  '$_unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: Colors.redAccent,
                offset: const Offset(-2, -2),
                child: GestureDetector(
                  onTap: () {
                    if (manv.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotificationScreen(maNv: manv),
                        ),
                      ).then((_) => _fetchUnreadCount());
                    }
                  },
                  child: Container(
                    width: 35,
                    height: 35,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      color: Colors.black87,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridMenu() {
    final auth = Provider.of<AuthProvider>(context);
    bool hasRole4 = auth.currentRoleIds.contains(4);
    bool hasRole5 = auth.currentRoleIds.contains(5);
    bool hasRole8 = auth.currentRoleIds.contains(8);
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: 12,
      mainAxisSpacing: 16,
      childAspectRatio: 0.75,
      children: [
        _buildMiniMenuCard(
          Icons.school_rounded,
          'Đào tạo',
          const Color(0xFF087DBA),
          ChangeNotifierProvider<DaoTaoV2Provider>.value(
            value: context.read<DaoTaoV2Provider>(),
            child: const DaoTaoCmeHubScreen(),
          ),
        ),
        _buildMiniMenuCard(
          Icons.fingerprint_rounded,
          'Công',
          Colors.teal,
          const ChamCongBoSungHubScreen(),
        ),
        _buildMiniMenuCard(
          Icons.payments_rounded,
          'Lương',
          const Color.fromARGB(255, 0, 38, 255),
          const LuongScreen(),
        ),
        _buildMiniMenuCard(
          Icons.calendar_month_rounded,
          'Lịch trực',
          const Color.fromARGB(255, 255, 1, 1),
          const ChamTrucScreen(),
        ),
        _buildMiniMenuCard(
          Icons.restaurant_rounded,
          'Cơm/Sự kiện',
          const Color.fromARGB(255, 170, 131, 2),
          const BaoComHubScreen(),
        ),
        _buildMiniMenuCard(
          Icons.analytics_outlined,
          'Kế hoạch tổng hợp',
          const Color(0xFF3768C5),
          null,
          onTap: _openKhth,
        ),
        _buildMiniMenuCard(
          Icons.inventory_2_rounded,
          'Tài sản',
          Colors.teal,
          const TaiSanHubScreen(),
        ),
        _buildMiniMenuCard(
          Icons.request_page_rounded,
          'Dự trù',
          Colors.orange,
          const DuTruListScreen(),
        ),
        if (hasRole4)
          _buildMiniMenuCard(
            Icons.water_drop_rounded,
            'Nước thải',
            Colors.blue,
            const NuocThaiListScreen(),
          ),
        if (hasRole5)
          _buildMiniMenuCard(
            Icons.electric_meter_rounded,
            'Điện nước',
            const Color.fromARGB(255, 172, 163, 45),
            const DienNuocListScreen(),
          ),
        if (hasRole8)
          _buildMiniMenuCard(
            Icons.science_outlined,
            'XN Trả sau',
            const Color.fromARGB(255, 172, 163, 45),
            const XNTraSauListScreen(),
          ),
      ],
    );
  }

  Widget _buildNewsSlider() {
    if (_isLoadingNews)
      return const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator()),
      );

    if (_recentNews.isEmpty) {
      return Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text(
              "Chưa có thông báo nào",
              style: TextStyle(
                color: Colors.grey.shade500,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: _recentNews.length,
        itemBuilder: (context, index) {
          final news = _recentNews[index];
          String displayDate = '';
          if (news.ngayUp != null && news.ngayUp!.isNotEmpty) {
            try {
              displayDate = DateFormat(
                'dd/MM/yyyy',
              ).format(DateTime.parse(news.ngayUp!));
            } catch (_) {}
          }
          bool isPdf = (news.duongDan ?? '').toLowerCase().endsWith('.pdf');

          return GestureDetector(
            onTap: () => _viewFile(news),
            child: Container(
              width: 270,
              margin: const EdgeInsets.only(right: 16, bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1274BC).withOpacity(0.06),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade100, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isPdf
                              ? const Color(0xFFFFF0F0)
                              : const Color(0xFFF0F8FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isPdf
                              ? Icons.picture_as_pdf_rounded
                              : Icons.article_rounded,
                          color: isPdf
                              ? const Color(0xFFE53935)
                              : const Color(0xFF1274BC),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          news.tenTapTin ?? 'Thông báo',
                          style: const TextStyle(
                            color: Color(0xFF2C3E50),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            height: 1.3,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            displayDate,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const Row(
                        children: [
                          Text(
                            "Xem ngay",
                            style: TextStyle(
                              color: Color(0xFF1274BC),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: Color(0xFF1274BC),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _viewFile(TapTin file) async {
    if (file.id == null) return;

    bool isPdf = (file.duongDan ?? '').toLowerCase().endsWith('.pdf');
    if (!isPdf) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Chỉ hỗ trợ xem trực tiếp văn bản định dạng PDF. Hãy tải file về máy để xem!',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _tapTinService.recordViewDoc(file.id!);

    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');

    final url = '${AppConstants.baseUrl}/Taptin/download/${file.id}';

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            elevation: 0.5,
            backgroundColor: Colors.white,
            centerTitle: true,
            title: Text(
              file.tenTapTin ?? 'Chi tiết văn bản',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.black87,
                size: 20,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: SafeArea(
            child: SfPdfViewer.network(
              url,
              headers: {'Authorization': 'Bearer $token'},
              canShowScrollHead: false,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniAvatar(String? base64String, String tenNhanVien) {
    if (base64String != null && base64String.isNotEmpty) {
      try {
        String cleanBase64 = base64String.contains(',')
            ? base64String.split(',').last
            : base64String;
        return CircleAvatar(
          radius: 22,
          backgroundColor: Colors.white,
          backgroundImage: MemoryImage(base64Decode(cleanBase64)),
        );
      } catch (_) {}
    }
    return CircleAvatar(
      radius: 22,
      backgroundColor: Colors.white24,
      child: Text(
        tenNhanVien.isNotEmpty ? tenNhanVien[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildMiniMenuCard(
    IconData icon,
    String title,
    Color color,
    Widget? destinationPage, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap();
          return;
        }
        if (destinationPage != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => destinationPage),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tính năng "$title" đang được phát triển!')),
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A5568),
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
