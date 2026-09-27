import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../features/khth/khth_logout.dart';
import '../features/khth/khth_popup_dialog.dart';
import '../features/khth/khth_service.dart';
import '../features/nhan_vien_v2/screens/dialogs/dao_tao_v2/dialogs/dao_tao_v2_web_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/cap_cchn_provider.dart';
import '../providers/cme_provider.dart';
import '../providers/dao_tao_dashboard_provider.dart';
import '../providers/dao_tao_v2_provider.dart';
import '../providers/nhan_vien_v2_provider.dart';
import '../providers/su_kien_v2_provider.dart';
import '../providers/thuc_hanh_provider.dart';

import '../services/api_client.dart';
import '../services/cap_cchn_service.dart';
import '../services/dao_tao_dashboard_service.dart';
import '../services/dao_tao_v2_service.dart';
import '../services/nhan_vien_v2_service.dart';
import '../services/su_kien_v2_service.dart';
import '../services/taisan_service.dart';
import '../services/thuc_hanh_service.dart';

import '../utils/constants.dart';
import '../utils/helpers.dart';

import 'all_files_screen.dart';
import 'bao_com_hub_screen.dart';
import 'cap_cchn/cap_cchn_screen.dart';
import 'cham_cong_bo_sung/chamcong_bosung_hub_screen.dart';
import 'cham_truc/cham_truc_screen.dart';
import 'cme/cme_screen.dart';
import 'cme/dao_tao_dashboard_screen.dart';
import 'create_repair_ticket_screen.dart';
import 'diennuoc_list_screen.dart';
import 'dutru_list_screen.dart';
import 'employee_list_screen.dart';
import 'home_screen.dart';
import 'luong/luong_screen.dart';
import 'menu_screen.dart';
import 'nhan_vien/nhan_vien_v2_web_screen.dart';
import 'nuocthai_list_screen.dart';
import 'scanner_screen.dart';
import 'su_kien_v2/su_kien_admin_web_screen.dart';
import 'taisan_hub_screen.dart';
import 'thuc_hanh/thuc_hanh_admin_screen.dart';
import 'xn_trasau_list_screen.dart';

class MainRootScreen extends StatefulWidget {
  const MainRootScreen({super.key});

  @override
  State<MainRootScreen> createState() => _MainRootScreenState();
}

class _MainRootScreenState extends State<MainRootScreen> {
  static const double _desktopWebBreakpoint = 900;

  int _currentIndex = 0;
  bool? _wasUsingDesktopWeb;

  int _cmePageRevision = 0;
  bool _isLoggingOutWeb = false;
  bool _isTrainingMenuExpanded = true;

  late final List<Widget> _mobilePages;
  late final List<Widget> _webPages;
  late final KhthService _khthService;

  bool _isOpeningKhth = false;
  Future<void> _logoutWeb() async {
    if (_isLoggingOutWeb) {
      return;
    }

    setState(() {
      _isLoggingOutWeb = true;
    });

    try {
      try {
        await logoutKhthBrowser(url: _khthService.logoutUrl);
      } catch (e) {
        debugPrint('KHTH logout warning: $e');
      }

      if (!mounted) {
        return;
      }

      await context.read<AuthProvider>().logout();

      if (!mounted) {
        return;
      }

      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoggingOutWeb = false;
      });

      debugPrint('Logout Web error: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa thể đăng xuất. Vui lòng thử lại.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFFD54F4F),
        ),
      );
    }
  }

  final TaiSanService _taiSanService = TaiSanService();

  late final NhanVienV2Service _nhanVienV2Service;

  late final DaoTaoV2Service _daoTaoV2Service;
  late final DaoTaoDashboardService _daoTaoDashboardService;
  late final CapCchnService _capCchnService;
  late final ThucHanhService _thucHanhService;
  late final SuKienV2Service _suKienV2Service;

  bool _usesDesktopWeb(BuildContext context) {
    return kIsWeb && MediaQuery.sizeOf(context).width >= _desktopWebBreakpoint;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final bool useDesktopWeb = _usesDesktopWeb(context);
    if (_wasUsingDesktopWeb != null && _wasUsingDesktopWeb != useDesktopWeb) {
      final bool invalidForDesktop = useDesktopWeb && _currentIndex == 3;
      final bool invalidForMobile = !useDesktopWeb && _currentIndex > 3;

      if (invalidForDesktop || invalidForMobile) {
        _currentIndex = 0;
      }
    }
    _wasUsingDesktopWeb = useDesktopWeb;
  }

  @override
  void initState() {
    super.initState();

    _nhanVienV2Service = NhanVienV2Service(ApiClient().dio);

    _daoTaoV2Service = DaoTaoV2Service(ApiClient().dio);
    _daoTaoDashboardService = DaoTaoDashboardService(ApiClient().dio);
    _capCchnService = CapCchnService(ApiClient().dio);
    _thucHanhService = ThucHanhService(ApiClient().dio);
    _khthService = KhthService(ApiClient().dio, AppConstants.baseUrl);
    _suKienV2Service = SuKienV2Service(ApiClient().dio,);

    _mobilePages = [
      ChangeNotifierProvider<DaoTaoV2Provider>(
        create: (_) {
          final provider = DaoTaoV2Provider(service: _daoTaoV2Service);
          provider.dangMoDangKy = true;
          provider.initialize();
          return provider;
        },
        child: const HomeScreen(),
      ),
      const EmployeeListScreen(),
      const AllFilesScreen(),
      const MenuScreen(),
    ];

    _webPages = [
      _buildWebHomePage(),
      _buildWebNhanVienPage(),
      const AllFilesScreen(),
      const SizedBox.shrink(),
      const CmeScreen(),
      _buildDaoTaoPage(),
      const ChamCongBoSungHubScreen(),
      const LuongScreen(),
      const ChamTrucScreen(),
      const TaiSanHubScreen(),
      const DuTruListScreen(),
      const NuocThaiListScreen(),
      const DienNuocListScreen(),
      const XNTraSauListScreen(),
      const BaoComHubScreen(),
      _buildCapCchnPage(),
      _buildThucHanhPage(),
      _buildDaoTaoDashboardPage(),
      _buildSuKienPage(),
    ];
  }

  Widget _buildWebNhanVienPage() {
    return ChangeNotifierProvider<NhanVienV2Provider>(
      create: (_) =>
          NhanVienV2Provider(service: _nhanVienV2Service)..initialize(),

      child: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          return NhanVienV2WebScreen(
            roleIds: Set<int>.from(auth.currentRoleIds),
          );
        },
      ),
    );
  }

  Widget _buildWebHomePage() {
    return ChangeNotifierProvider<DaoTaoV2Provider>(
      create: (_) {
        final provider = DaoTaoV2Provider(service: _daoTaoV2Service);
        provider.dangMoDangKy = true;
        provider.initialize();
        return provider;
      },
      child: HomeScreen(onOpenTraining: _openTraining),
    );
  }

  Widget _buildDaoTaoPage() {
    return ChangeNotifierProvider<DaoTaoV2Provider>(
      create: (_) => DaoTaoV2Provider(service: _daoTaoV2Service)..initialize(),

      child: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          return DaoTaoV2WebScreen(roleIds: Set<int>.from(auth.currentRoleIds));
        },
      ),
    );
  }

  Widget _buildCapCchnPage() {
    return ChangeNotifierProvider<CapCchnProvider>(
      create: (_) => CapCchnProvider(service: _capCchnService)..initialize(),
      child: CapCchnScreen(nhanVienService: _nhanVienV2Service),
    );
  }

  Widget _buildThucHanhPage() {
    return ChangeNotifierProvider<ThucHanhProvider>(
      create: (_) => ThucHanhProvider(_thucHanhService)..initialize(),
      child: ThucHanhAdminScreen(nhanVienService: _nhanVienV2Service),
    );
  }
  Widget _buildSuKienPage() {
    return ChangeNotifierProvider<
        SuKienV2Provider>(
      create: (_) =>
          SuKienV2Provider(
        _suKienV2Service,
      ),

      child:
          const SuKienAdminWebScreen(),
    );
  }
  Widget _buildDaoTaoDashboardPage() {
    return ChangeNotifierProvider<DaoTaoDashboardProvider>(
      create: (_) => DaoTaoDashboardProvider(_daoTaoDashboardService)..load(),
      child: DaoTaoDashboardScreen(
        onOpenClasses: () => setState(() => _currentIndex = 5),
        onOpenInternalPractice: () => setState(() => _currentIndex = 15),
        onOpenExternalPractice: () => setState(() => _currentIndex = 16),
        onOpenCme: _openCmeApproval,
      ),
    );
  }

  void _openCmeApproval() {
    if (!kIsWeb || !mounted || _webPages.length <= 4) {
      return;
    }

    setState(() {
      _cmePageRevision++;

      _webPages[4] = CmeScreen(
        key: ValueKey<String>('cme-approval-$_cmePageRevision'),
        initialTab: 1,
      );

      // CME LUÔN GIỮ INDEX 4
      _currentIndex = 4;
    });
  }

  void _openTraining() {
    if (!kIsWeb || !mounted || _webPages.length <= 5) {
      return;
    }

    final roles = context.read<AuthProvider>().currentRoleIds;
    final canViewDashboard = roles.any(
      const <int>{36, 47, 48, 49, 50}.contains,
    );
    setState(() => _currentIndex = canViewDashboard ? 17 : 5);
  }

  Future<void> _openKhth() async {
    if (_isOpeningKhth) {
      return;
    }

    setState(() {
      _isOpeningKhth = true;
    });

    try {
      final String url = await _khthService.getOpenUrl();

      if (!mounted) {
        return;
      }

      setState(() {
        _isOpeningKhth = false;
      });

      if (kIsWeb) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) {
            return KhthPopupDialog(url: url);
          },
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

      setState(() {
        _isOpeningKhth = false;
      });

      final String message = e.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFD54F4F),
        ),
      );
    }
  }
  // ==========================================================
  // SCAN QR MOBILE
  // ==========================================================

  Future<void> _scanQRCodeAndNavigate() async {
    final String? maTaiSan = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );

    if (maTaiSan == null || maTaiSan.isEmpty) {
      return;
    }

    if (mounted) {
      AppHelpers.showSnackBar(
        'Đang tra cứu tài sản: $maTaiSan...',
        isError: false,
      );
    }

    try {
      final results = await _taiSanService.getDanhSachTaiSan(
        maTaiSan: maTaiSan,
        pageSize: 1,
      );

      if (!mounted) {
        return;
      }

      if (results.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                CreateRepairTicketScreen(initialTaiSan: results.first),
          ),
        );
      } else {
        AppHelpers.showSnackBar(
          '❌ Không tìm thấy tài sản nào khớp với mã QR này!',
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      AppHelpers.showSnackBar('Lỗi tra cứu tài sản: $e', isError: true);
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final bool useDesktopWeb = _usesDesktopWeb(context);

    // ========================================================
    // WEB
    // ========================================================

    if (useDesktopWeb) {
      final permissions = context
          .select<
            AuthProvider,
            ({
              bool cme,
              bool trainingDashboard,
              bool capCchn,
              bool thucHanhNgoai,
              bool nuocThai,
              bool dienNuoc,
              bool xnTraSau,
              bool suKien,
            })
          >(
            (AuthProvider auth) => (
              cme: auth.currentRoleIds.contains(36),
              trainingDashboard: auth.currentRoleIds.any(
                const <int>{36, 47, 48, 49, 50}.contains,
              ),
              capCchn: auth.currentRoleIds.contains(49),
              thucHanhNgoai: auth.currentRoleIds.contains(50),
              nuocThai: auth.currentRoleIds.contains(4),
              dienNuoc: auth.currentRoleIds.contains(5),
              xnTraSau: auth.currentRoleIds.contains(8),
              suKien: auth.currentRoleIds.contains(52),
            ),
          );

      final int pendingCmeCount = context.select<CmeProvider, int>(
        (CmeProvider provider) => provider.dashboardSummary.pendingCount,
      );
      if (!permissions.suKien &&
          _currentIndex == 18) {
        WidgetsBinding.instance
            .addPostFrameCallback(
          (_) {
            if (!mounted) {
              return;
            }

            setState(() {
              _currentIndex = 0;
            });
          },
        );
      }

      return _buildWebRoot(
        context,
        canApproveCme: permissions.cme,
        canViewTrainingDashboard: permissions.trainingDashboard,
        canManageCapCchn: permissions.capCchn,
        canManageExternalPractice: permissions.thucHanhNgoai,
        canViewNuocThai: permissions.nuocThai,
        canViewDienNuoc: permissions.dienNuoc,
        canViewXnTraSau: permissions.xnTraSau,
        pendingCmeCount: pendingCmeCount,
        canManageSuKien: permissions.suKien,
      );
    }

    // ========================================================
    // MOBILE
    // ========================================================

    final bool isKeyboardVisible =
        MediaQuery.of(context).viewInsets.bottom != 0;
    final int mobileIndex = _currentIndex.clamp(0, _mobilePages.length - 1);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),

      child: Scaffold(
        resizeToAvoidBottomInset: false,

        extendBody: true,

        body: IndexedStack(index: mobileIndex, children: [
          TickerMode(enabled: mobileIndex == 0, child: _mobilePages.first),
          ..._mobilePages.skip(1),
        ]),

        // ====================================================
        // QR BUTTON
        // ====================================================
        floatingActionButton: isKeyboardVisible
            ? null
            : Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF4FA5E5), Color(0xFF1274BC)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1274BC).withValues(alpha: 0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: FloatingActionButton(
                  onPressed: _scanQRCodeAndNavigate,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  highlightElevation: 0,
                  shape: const CircleBorder(),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),

        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

        // ====================================================
        // MOBILE BOTTOM NAVIGATION
        // ====================================================
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),

          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),

            child: BottomAppBar(
              color: Colors.white,
              surfaceTintColor: Colors.white,
              shape: const CircularNotchedRectangle(),
              notchMargin: 10.0,
              elevation: 0,
              padding: EdgeInsets.zero,
              height: 75,

              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [
                    // ========================================
                    // LEFT
                    // ========================================
                    Row(
                      children: [
                        _buildAnimatedTab(
                          Icons.home_outlined,
                          Icons.home_rounded,
                          'Home',
                          0,
                        ),

                        const SizedBox(width: 16),

                        _buildAnimatedTab(
                          Icons.people_outline_rounded,
                          Icons.people_rounded,
                          'Nhân sự',
                          1,
                        ),
                      ],
                    ),

                    // ========================================
                    // RIGHT
                    // ========================================
                    Row(
                      children: [
                        _buildAnimatedTab(
                          Icons.folder_copy_outlined,
                          Icons.folder_rounded,
                          'Văn bản',
                          2,
                        ),

                        const SizedBox(width: 16),

                        _buildAnimatedTab(
                          Icons.menu_rounded,
                          Icons.menu_open_rounded,
                          'Menu',
                          3,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // WEB ROOT
  // ==========================================================

  Widget _buildWebRoot(
    BuildContext context, {
    required bool canApproveCme,
    required bool canViewTrainingDashboard,
    required bool canManageCapCchn,
    required bool canManageExternalPractice,
    required bool canViewNuocThai,
    required bool canViewDienNuoc,
    required bool canViewXnTraSau,
    required int pendingCmeCount,
    required bool canManageSuKien,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isExpanded = constraints.maxWidth >= 1280;

        return Scaffold(
          backgroundColor: const Color(0xFFF4F7FB),

          body: Row(
            children: [
              // ==============================================
              // SIDEBAR
              // ==============================================
              _buildWebSidebar(
                isExpanded: isExpanded,
                canApproveCme: canApproveCme,
                canViewTrainingDashboard: canViewTrainingDashboard,
                canManageCapCchn: canManageCapCchn,
                canManageExternalPractice: canManageExternalPractice,
                canViewNuocThai: canViewNuocThai,
                canViewDienNuoc: canViewDienNuoc,
                canViewXnTraSau: canViewXnTraSau,
                pendingCmeCount: pendingCmeCount,
                canManageSuKien: canManageSuKien,
              ),

              // ==============================================
              // PAGE
              // ==============================================
              Expanded(
                child: IndexedStack(index: _currentIndex, children: [
                  TickerMode(enabled: _currentIndex == 0, child: _webPages.first),
                  ..._webPages.skip(1),
                ]),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================
  // WEB SIDEBAR
  // ==========================================================

  Widget _buildWebSidebar({
    required bool isExpanded,
    required bool canApproveCme,
    required bool canViewTrainingDashboard,
    required bool canManageCapCchn,
    required bool canManageExternalPractice,
    required bool canViewNuocThai,
    required bool canViewDienNuoc,
    required bool canViewXnTraSau,
    required int pendingCmeCount,
    required bool canManageSuKien,
  }) {
      final List<
      ({
        IconData icon,
        String label,
        int pageIndex,
      })> managementItems = [
    (
      icon:
          Icons.dashboard_rounded,
      label:
          'Tổng quan',
      pageIndex:
          0,
    ),

    (
      icon:
          Icons.groups_2_outlined,
      label:
          'Nhân sự',
      pageIndex:
          1,
    ),

    (
      icon:
          Icons.folder_copy_outlined,
      label:
          'Văn bản',
      pageIndex:
          2,
    ),

    (
      icon:
          Icons.workspace_premium_outlined,
      label:
          'CME',
      pageIndex:
          4,
    ),

    // ========================================================
    // CHỈ WEB PC + ROLE 52
    // ========================================================
    if (canManageSuKien)
      (
        icon:
            Icons.celebration_outlined,
        label:
            'Quản lý sự kiện',
        pageIndex:
            18,
      ),
  ];

    final List<({IconData icon, String label, int pageIndex})> utilityItems = [
      (icon: Icons.fingerprint_rounded, label: 'Chấm công', pageIndex: 6),
      (
        icon: Icons.account_balance_wallet_outlined,
        label: 'Bảng lương',
        pageIndex: 7,
      ),
      (icon: Icons.calendar_month_outlined, label: 'Lịch trực', pageIndex: 8),
      (icon: Icons.restaurant_rounded, label: 'Cơm/Sự kiện', pageIndex: 14),
      (icon: Icons.inventory_2_outlined, label: 'Tài sản', pageIndex: 9),
      (icon: Icons.request_page_outlined, label: 'Dự trù', pageIndex: 10),
      if (canViewNuocThai)
        (icon: Icons.water_drop_outlined, label: 'Nước thải', pageIndex: 11),
      if (canViewDienNuoc)
        (
          icon: Icons.electric_meter_outlined,
          label: 'Điện nước',
          pageIndex: 12,
        ),
      if (canViewXnTraSau)
        (icon: Icons.science_outlined, label: 'XN trả sau', pageIndex: 13),
    ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,

      width: isExpanded ? 252 : 84,

      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0B426B), Color(0xFF082F4D)],
        ),
      ),

      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            isExpanded ? 18 : 12,
            20,
            isExpanded ? 18 : 12,
            18,
          ),

          child: Column(
            children: [
              // ==============================================
              // LOGO
              // ==============================================
              SizedBox(
                height: 54,
                child: Row(
                  mainAxisAlignment: isExpanded
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,

                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.16),
                            blurRadius: 14,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),

                      child: Image.asset(
                        'assets/images/LOGO.png',

                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.local_hospital_rounded,
                              color: Color(0xFF1274BC),
                            ),
                      ),
                    ),

                    if (isExpanded) ...[
                      const SizedBox(width: 13),

                      const Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            Text(
                              'My HungVuong',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),

                            SizedBox(height: 2),

                            Text(
                              'CỔNG THÔNG TIN NỘI BỘ',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Color(0xFF9CCAE8),
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // ==============================================
              // MENU ITEMS
              // ==============================================
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,

                  children: [
                    _buildWebSidebarSectionLabel(
                      'QUẢN LÝ',
                      isExpanded: isExpanded,
                    ),
                    for (
                      int index = 0;
                      index < managementItems.length;
                      index++
                    ) ...[
                      _buildWebSidebarItem(
                        icon: managementItems[index].icon,
                        label: managementItems[index].label,
                        index: managementItems[index].pageIndex,
                        isExpanded: isExpanded,
                        badgeCount:
                            canApproveCme &&
                                managementItems[index].pageIndex == 4
                            ? pendingCmeCount
                            : 0,
                      ),
                      const SizedBox(height: 4),
                    ],
                    _buildTrainingSidebarMenu(
                      isExpanded: isExpanded,
                      canViewDashboard: canViewTrainingDashboard,
                      canManageCapCchn: canManageCapCchn,
                      canManageExternalPractice: canManageExternalPractice,
                    ),
                    const SizedBox(height: 4),

                    _buildWebSidebarSectionLabel(
                      'TIỆN ÍCH',
                      isExpanded: isExpanded,
                    ),
                    for (final item in utilityItems) ...[
                      _buildWebSidebarItem(
                        icon: item.icon,
                        label: item.label,
                        index: item.pageIndex,
                        isExpanded: isExpanded,
                      ),
                      const SizedBox(height: 4),
                    ],

                    _buildWebSidebarSectionLabel(
                      'HỆ THỐNG',
                      isExpanded: isExpanded,
                    ),
                    _buildWebKhthSidebarItem(isExpanded: isExpanded),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ==============================================
              // SECURITY FOOTER
              // ==============================================
              if (isExpanded)
                GestureDetector(
                  onTap: _isLoggingOutWeb ? null : _logoutWeb,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF2B8B5)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEDEC),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: _isLoggingOutWeb
                              ? const Padding(
                                  padding: EdgeInsets.all(9),
                                  child: CircularProgressIndicator(
                                    color: Color(0xFFC43C35),
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.logout_rounded,
                                  color: Color(0xFFC43C35),
                                  size: 19,
                                ),
                        ),

                        const SizedBox(width: 11),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isLoggingOutWeb
                                    ? 'Đang đăng xuất...'
                                    : 'Đăng xuất',
                                style: TextStyle(
                                  color: Color(0xFFC43C35),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),

                              SizedBox(height: 2),

                              Text(
                                'Thoát khỏi tài khoản hiện tại',
                                style: TextStyle(
                                  color: Color(0xFF9A4A45),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Tooltip(
                  message: 'Đăng xuất',
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFF2B8B5)),
                    ),
                    child: IconButton(
                      tooltip: 'Đăng xuất',
                      onPressed: _isLoggingOutWeb ? null : _logoutWeb,
                      icon: _isLoggingOutWeb
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Color(0xFFC43C35),
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.logout_rounded,
                              color: Color(0xFFC43C35),
                              size: 21,
                            ),
                    ),
                  ),
                ),

              if (isExpanded) ...[
                const SizedBox(height: 18),

                Text(
                  '© 2026 thaiit™',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.42),
                    fontSize: 9,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // WEB SIDEBAR ITEM
  // ==========================================================

  Widget _buildWebSidebarSectionLabel(
    String label, {
    required bool isExpanded,
  }) {
    if (!isExpanded) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 7),
        child: Divider(color: Color(0x2E9CCAE8), height: 1),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 7),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF77AED0),
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildWebSidebarItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isExpanded,
    int badgeCount = 0,
  }) {
    final bool isSelected = _currentIndex == index;

    final Widget item = Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: () {
          if (_currentIndex != index) {
            setState(() => _currentIndex = index);
          }
        },

        borderRadius: BorderRadius.circular(14),

        hoverColor: Colors.white.withValues(alpha: 0.08),

        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),

          height: 44,

          padding: EdgeInsets.symmetric(horizontal: isExpanded ? 13 : 0),

          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.14)
                : Colors.transparent,

            borderRadius: BorderRadius.circular(14),

            border: isSelected
                ? Border.all(color: Colors.white.withValues(alpha: 0.1))
                : null,
          ),

          child: Row(
            mainAxisAlignment: isExpanded
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,

            children: [
              Badge(
                isLabelVisible: badgeCount > 0,

                label: Text(
                  badgeCount > 99 ? '99+' : '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                backgroundColor: const Color(0xFFE45B52),

                offset: const Offset(7, -7),

                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : const Color(0xFFA8CDE4),
                  size: 21,
                ),
              ),

              if (isExpanded) ...[
                const SizedBox(width: 13),

                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFFC2DCEA),
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                    ),
                  ),
                ),

                if (isSelected)
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Color(0xFF67D5FF),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );

    return isExpanded ? item : Tooltip(message: label, child: item);
  }

  Widget _buildTrainingSidebarMenu({
    required bool isExpanded,
    required bool canViewDashboard,
    required bool canManageCapCchn,
    required bool canManageExternalPractice,
  }) {
    final bool isSelected =
        _currentIndex == 5 ||
        _currentIndex == 15 ||
        _currentIndex == 16 ||
        _currentIndex == 17;

    if (!isExpanded) {
      return PopupMenuButton<int>(
        tooltip: 'Đào tạo',
        onSelected: (int index) => setState(() => _currentIndex = index),
        itemBuilder: (_) => <PopupMenuEntry<int>>[
          if (canViewDashboard)
            const PopupMenuItem<int>(
              value: 17,
              child: ListTile(
                leading: Icon(Icons.space_dashboard_outlined),
                title: Text('Dashboard'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          const PopupMenuItem<int>(
            value: 5,
            child: ListTile(
              leading: Icon(Icons.class_outlined),
              title: Text('Lớp đào tạo'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          if (canManageCapCchn)
            const PopupMenuItem<int>(
              value: 15,
              child: ListTile(
                leading: Icon(Icons.medical_information_outlined),
                title: Text('Quản lý thực hành'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          if (canManageExternalPractice)
            const PopupMenuItem<int>(
              value: 16,
              child: ListTile(
                leading: Icon(Icons.badge_outlined),
                title: Text('Quản lý sinh viên'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
        ],
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Icon(
              Icons.school_outlined,
              color: isSelected ? Colors.white : const Color(0xFFA8CDE4),
              size: 21,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(
              () => _isTrainingMenuExpanded = !_isTrainingMenuExpanded,
            ),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 13),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.14)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.school_outlined,
                    color: isSelected ? Colors.white : const Color(0xFFA8CDE4),
                    size: 21,
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Text(
                      'Đào tạo',
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFFC2DCEA),
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isTrainingMenuExpanded ? .5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFFA8CDE4),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          child: !_isTrainingMenuExpanded
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 0, 2),
                  child: Column(
                    children: [
                      if (canViewDashboard)
                        _buildTrainingSubItem(
                          icon: Icons.space_dashboard_outlined,
                          label: 'Dashboard',
                          index: 17,
                        ),
                      _buildTrainingSubItem(
                        icon: Icons.class_outlined,
                        label: 'Lớp đào tạo',
                        index: 5,
                      ),
                      if (canManageCapCchn)
                        _buildTrainingSubItem(
                          icon: Icons.medical_information_outlined,
                          label: 'Quản lý thực hành',
                          index: 15,
                        ),
                      if (canManageExternalPractice)
                        _buildTrainingSubItem(
                          icon: Icons.badge_outlined,
                          label: 'Quản lý sinh viên',
                          index: 16,
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildTrainingSubItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool selected = _currentIndex == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        borderRadius: BorderRadius.circular(11),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            color: selected
                ? Colors.white.withValues(alpha: .12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 17,
                color: selected ? Colors.white : const Color(0xFF9CCAE8),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFFB8D7E8),
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebKhthSidebarItem({required bool isExpanded}) {
    final Widget item = Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: _isOpeningKhth ? null : _openKhth,

        borderRadius: BorderRadius.circular(14),

        hoverColor: Colors.white.withValues(alpha: 0.08),

        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),

          height: 44,

          padding: EdgeInsets.symmetric(horizontal: isExpanded ? 13 : 0),

          decoration: BoxDecoration(
            color: Colors.transparent,

            borderRadius: BorderRadius.circular(14),
          ),

          child: Row(
            mainAxisAlignment: isExpanded
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,

            children: [
              // ==================================================
              // ICON / LOADING
              // ==================================================
              if (_isOpeningKhth)
                const SizedBox(
                  width: 21,
                  height: 21,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFA8CDE4),
                  ),
                )
              else
                const Icon(
                  Icons.analytics_outlined,
                  color: Color(0xFFA8CDE4),
                  size: 21,
                ),

              // ==================================================
              // TEXT
              // ==================================================
              if (isExpanded) ...[
                const SizedBox(width: 13),

                const Expanded(
                  child: Text(
                    'Kế hoạch tổng hợp',
                    style: TextStyle(
                      color: Color(0xFFC2DCEA),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // Cho user biết đây không phải tab IndexedStack.
                const Icon(
                  Icons.open_in_browser_outlined,
                  color: Color(0xFF77AED0),
                  size: 16,
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (isExpanded) {
      return item;
    }

    return Tooltip(message: 'Kế hoạch tổng hợp', child: item);
  }
  // ==========================================================
  // MOBILE ANIMATED TAB
  // ==========================================================

  Widget _buildAnimatedTab(
    IconData outlineIcon,
    IconData filledIcon,
    String label,
    int index,
  ) {
    final bool isSelected = _currentIndex.clamp(0, 3) == index;

    const Color activeColor = Color(0xFF1274BC);

    final Color inactiveColor = Colors.grey.shade400;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,

      onTap: () => setState(() => _currentIndex = index),

      child: SizedBox(
        width: 65,

        child: Column(
          mainAxisSize: MainAxisSize.min,

          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),

              curve: Curves.easeOutQuint,

              padding: EdgeInsets.only(
                top: isSelected ? 0 : 4,
                bottom: isSelected ? 4 : 0,
              ),

              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),

                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),

                child: Icon(
                  isSelected ? filledIcon : outlineIcon,

                  key: ValueKey(isSelected),

                  color: isSelected ? activeColor : inactiveColor,

                  size: isSelected ? 26 : 24,
                ),
              ),
            ),

            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),

              style: TextStyle(
                color: isSelected ? activeColor : inactiveColor,

                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,

                fontSize: isSelected ? 12 : 11,
              ),

              child: Text(label),
            ),

            const SizedBox(height: 4),

            AnimatedContainer(
              duration: const Duration(milliseconds: 300),

              height: 4,

              width: isSelected ? 16 : 0,

              decoration: BoxDecoration(
                color: activeColor,

                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
