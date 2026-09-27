import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/auth_api_exception.dart';
import '../utils/helpers.dart';
import 'forgot_password_screen.dart';
import 'welcome_screen.dart';
import 'danhbatruc_screen.dart';
import 'change_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _manvController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  // Cờ kiểm tra xem thiết bị có hỗ trợ Sinh trắc học hay không
  bool _isBiometricSupported = false;

  final Color primaryColor = const Color(0xFF1274BC);
  final Color primaryLight = const Color(0xFF4FA5E5);

  @override
  void initState() {
    super.initState();
    DanhBaTrucScreen.preloadData();
    _checkBiometricSupport(); // Gọi hàm kiểm tra khi khởi tạo màn hình
  }

  @override
  void dispose() {
    _manvController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- HÀM KIỂM TRA HỖ TRỢ SINH TRẮC HỌC ---
  Future<void> _checkBiometricSupport() async {
    Future.microtask(() async {
      final isSupported = await context
          .read<AuthProvider>()
          .isBiometricSupported();
      if (mounted) {
        setState(() {
          _isBiometricSupported = isSupported;
        });
      }
    });
  }

  // --- HÀM CHUYỂN HƯỚNG DÙNG CHUNG ---
  void _goToWelcome() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const WelcomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const curve = Curves.easeOutCubic;
          var slideTween = Tween(
            begin: const Offset(0.0, 0.1),
            end: Offset.zero,
          ).chain(CurveTween(curve: curve));
          var fadeTween = Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).chain(CurveTween(curve: curve));
          var scaleTween = Tween<double>(
            begin: 0.95,
            end: 1.0,
          ).chain(CurveTween(curve: curve));

          return FadeTransition(
            opacity: animation.drive(fadeTween),
            child: ScaleTransition(
              scale: animation.drive(scaleTween),
              child: SlideTransition(
                position: animation.drive(slideTween),
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleBiometricLogin() async {
    final AuthProvider auth = context.read<AuthProvider>();

    try {
      final bool success = await auth.loginWithBiometric();

      if (success && mounted) {
        _goToWelcome();
      }
    } on AuthApiException catch (e) {
      if (!mounted) return;

      if (e.code == 'PASSWORD_EXPIRED') {
        final String? manv = auth.pendingPasswordChangeManv;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChangePasswordScreen(isForced: true, manv: manv),
          ),
        );

        return;
      }

      AppHelpers.showSnackBar(e.message, isError: true);
    } catch (e) {
      if (!mounted) return;

      AppHelpers.showSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> _handleLogin() async {
    final String manv = _manvController.text.trim();

    /*
   * Không trim mật khẩu vì khoảng trắng
   * có thể là một ký tự hợp lệ.
   */
    final String password = _passwordController.text;

    if (manv.isEmpty || password.isEmpty) {
      AppHelpers.showSnackBar('Vui lòng nhập đầy đủ thông tin', isError: true);
      return;
    }

    try {
      final bool success = await context.read<AuthProvider>().login(
        manv,
        password,
      );

      if (success && mounted) {
        _goToWelcome();
      }
    } on AuthApiException catch (e) {
      if (!mounted) return;

      switch (e.code) {
        case 'PASSWORD_EXPIRED':
          AppHelpers.showSnackBar(e.message, isError: true);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ChangePasswordScreen(isForced: true, manv: manv),
            ),
          );
          break;

        case 'USER_LOCKED':
          AppHelpers.showSnackBar(e.message, isError: true);
          break;

        case 'INVALID_PASSWORD':
        case 'USER_NOT_FOUND':
          AppHelpers.showSnackBar(e.message, isError: true);
          break;

        default:
          AppHelpers.showSnackBar(e.message, isError: true);
      }
    } catch (e) {
      if (!mounted) return;

      AppHelpers.showSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Widget _buildWebLayout(BuildContext context, bool isLoading) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth >= 960;
        final double horizontalPadding = constraints.maxWidth >= 1440 ? 48 : 24;
        final double verticalPadding = constraints.maxHeight >= 760 ? 36 : 20;
        final double availableHeight =
            constraints.maxHeight - (verticalPadding * 2);
        final double minimumContentHeight = availableHeight > 0
            ? availableHeight
            : 0;
        final double desktopHeight = availableHeight < 680
            ? 680
            : availableHeight > 790
            ? 790
            : availableHeight;

        return Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0xFFF2F7FB)),
            Positioned(
              top: -180,
              right: -110,
              child: Container(
                width: 430,
                height: 430,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryLight.withValues(alpha: 0.09),
                ),
              ),
            ),
            Positioned(
              bottom: -220,
              left: -130,
              child: Container(
                width: 500,
                height: 500,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withValues(alpha: 0.07),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: minimumContentHeight),
                  child: Center(
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      tween: Tween<double>(begin: 0, end: 1),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: isWide
                          ? ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1180),
                              child: SizedBox(
                                width: double.infinity,
                                height: desktopHeight,
                                child: _buildWebDesktopPanel(isLoading),
                              ),
                            )
                          : ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 560),
                              child: _buildWebCompactPanel(isLoading),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWebDesktopPanel(bool isLoading) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF12324A).withValues(alpha: 0.13),
            blurRadius: 50,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(flex: 11, child: _buildWebBrandPanel()),
          Expanded(flex: 9, child: _buildWebFormPanel(isLoading)),
        ],
      ),
    );
  }

  Widget _buildWebBrandPanel() {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1683CF), Color(0xFF0F69AA), Color(0xFF08466F)],
            ),
          ),
        ),
        Positioned(
          top: -90,
          right: -70,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 38,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -100,
          left: -80,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(48, 44, 48, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/LOGO.png',
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.local_hospital_rounded,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My HungVuong',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'CỔNG THÔNG TIN NỘI BỘ',
                        style: TextStyle(
                          color: Color(0xFFCBE8FC),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.25,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 34),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: const Text(
                  'KHÔNG GIAN LÀM VIỆC SỐ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Kết nối công việc,\nđồng hành chăm sóc.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  height: 1.16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Truy cập nhanh các tiện ích và thông tin nội bộ '
                'trên một nền tảng thống nhất.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(
                            Icons.phone_android_rounded,
                            color: Colors.white,
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 11),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'My HungVuong trên điện thoại',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Quét mã QR để cài đặt ứng dụng',
                                style: TextStyle(
                                  color: Color(0xFFCBE8FC),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildWebQrCard(
                            assetPath: 'assets/QRapp/MyHungVuong-CHPlay.png',
                            storeName: 'Google Play',
                            platformName: 'Dành cho Android',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildWebQrCard(
                            assetPath: 'assets/QRapp/MyHungVuongAppStore.png',
                            storeName: 'App Store',
                            platformName: 'Dành cho iPhone',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Divider(color: Colors.white.withValues(alpha: 0.18)),
              const SizedBox(height: 12),
              Text(
                '© 2026 Phòng Công Nghệ Thông Tin - thaiit™',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.62),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWebQrCard({
    required String assetPath,
    required String storeName,
    required String platformName,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 108,
            height: 108,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Image.asset(
              assetPath,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.none,
              semanticLabel: 'Mã QR tải ứng dụng từ $storeName',
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.qr_code_2_rounded, color: primaryColor, size: 46),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            storeName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            platformName,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.66),
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebCompactQrSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: Color(0xFFE5ECF2), height: 1),
        const SizedBox(height: 20),
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                Icons.phone_android_rounded,
                color: primaryColor,
                size: 19,
              ),
            ),
            const SizedBox(width: 11),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tải ứng dụng My HungVuong',
                    style: TextStyle(
                      color: Color(0xFF29465A),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Quét mã QR phù hợp với điện thoại của bạn',
                    style: TextStyle(color: Color(0xFF7A8D9A), fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final Widget googlePlayCard = _buildWebCompactQrCard(
              assetPath: 'assets/QRapp/MyHungVuong-CHPlay.png',
              storeName: 'Google Play',
            );
            final Widget appStoreCard = _buildWebCompactQrCard(
              assetPath: 'assets/QRapp/MyHungVuongAppStore.png',
              storeName: 'App Store',
            );

            if (constraints.maxWidth < 330) {
              return Column(
                children: [
                  googlePlayCard,
                  const SizedBox(height: 12),
                  appStoreCard,
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: googlePlayCard),
                const SizedBox(width: 12),
                Expanded(child: appStoreCard),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildWebCompactQrCard({
    required String assetPath,
    required String storeName,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE1EAF0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 92,
            height: 92,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE7EDF2)),
            ),
            child: Image.asset(
              assetPath,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.none,
              semanticLabel: 'Mã QR tải ứng dụng từ $storeName',
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.qr_code_2_rounded, color: primaryColor, size: 44),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            storeName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF29465A),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebCompactPanel(bool isLoading) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF12324A).withValues(alpha: 0.13),
            blurRadius: 42,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(30, 26, 30, 25),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1683CF), Color(0xFF0A568A)],
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Image.asset(
                    'assets/images/LOGO.png',
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.local_hospital_rounded, color: primaryColor),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My HungVuong',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Cổng thông tin nội bộ',
                        style: TextStyle(
                          color: Color(0xFFD8EEFC),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildWebFormPanel(isLoading, compact: true),
        ],
      ),
    );
  }

  Widget _buildWebFormPanel(bool isLoading, {bool compact = false}) {
    return Container(
      color: Colors.white,
      padding: compact
          ? const EdgeInsets.fromLTRB(30, 34, 30, 26)
          : const EdgeInsets.symmetric(horizontal: 54, vertical: 46),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: AutofillGroup(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'ĐĂNG NHẬP HỆ THỐNG',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.05,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Chào mừng trở lại',
                  style: TextStyle(
                    color: Color(0xFF18354A),
                    fontSize: 30,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.45,
                  ),
                ),
                const SizedBox(height: 9),
                const Text(
                  'Nhập tài khoản nhân viên để tiếp tục.',
                  style: TextStyle(
                    color: Color(0xFF6D8190),
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 8),
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFFC62828),
                      size: 18,
                    ),
                    SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        'Đăng nhập bằng tài khoản sử dụng app My HungVuong',
                        style: TextStyle(
                          color: Color(0xFFC62828),
                          fontSize: 13,
                          height: 1.4,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 28 : 34),
                TextFormField(
                  controller: _manvController,
                  autofillHints: const [AutofillHints.username],
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.text,
                  style: const TextStyle(
                    color: Color(0xFF18354A),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: _webInputDecoration(
                    label: 'Mã nhân viên',
                    hint: 'Nhập mã nhân viên',
                    icon: Icons.badge_outlined,
                  ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (!isLoading) {
                      _handleLogin();
                    }
                  },
                  style: const TextStyle(
                    color: Color(0xFF18354A),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: _webInputDecoration(
                    label: 'Mật khẩu',
                    hint: 'Nhập mật khẩu',
                    icon: Icons.lock_outline_rounded,
                    suffixIcon: IconButton(
                      tooltip: _isPasswordVisible
                          ? 'Ẩn mật khẩu'
                          : 'Hiện mật khẩu',
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: const Color(0xFF7A8D9A),
                        size: 21,
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _openForgotPassword,
                    style: TextButton.styleFrom(
                      foregroundColor: primaryColor,
                      padding: const EdgeInsets.fromLTRB(10, 12, 0, 8),
                      minimumSize: Size.zero,
                    ),
                    child: const Text(
                      'Quên mật khẩu?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: primaryColor,
                      disabledBackgroundColor: primaryColor.withValues(
                        alpha: 0.58,
                      ),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.4,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'ĐĂNG NHẬP',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              SizedBox(width: 9),
                              Icon(Icons.arrow_forward_rounded, size: 19),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 28),
                const Divider(color: Color(0xFFE5ECF2), height: 1),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F7FC),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        Icons.support_agent_rounded,
                        color: primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bạn cần hỗ trợ?',
                            style: TextStyle(
                              color: Color(0xFF7A8D9A),
                              fontSize: 11,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Số trực toàn hệ thống',
                            style: TextStyle(
                              color: Color(0xFF29465A),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _openDutyDirectory,
                      style: TextButton.styleFrom(
                        foregroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                      child: const Text(
                        'Mở danh bạ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                if (compact) ...[
                  const SizedBox(height: 24),
                  _buildWebCompactQrSection(),
                  const SizedBox(height: 24),
                  const Center(
                    child: Text(
                      '© 2026 Phòng Công Nghệ Thông Tin - thaiit™',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF9AABB7), fontSize: 10),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _webInputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    final OutlineInputBorder defaultBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFDDE7EE)),
    );

    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFFA5B3BD),
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      labelStyle: const TextStyle(
        color: Color(0xFF6D8190),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: TextStyle(
        color: primaryColor,
        fontWeight: FontWeight.w700,
      ),
      prefixIcon: Icon(icon, color: primaryColor, size: 21),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: defaultBorder,
      enabledBorder: defaultBorder,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: primaryColor, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
    );
  }

  void _openForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
    );
  }

  void _openDutyDirectory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DanhBaTrucScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        body: kIsWeb
            ? _buildWebLayout(context, isLoading)
            : Stack(
                children: [
                  // Nền Gradient sâu và sang trọng hơn
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          primaryLight,
                          primaryColor,
                          const Color(0xFF0D4B7A),
                        ],
                      ),
                    ),
                  ),

                  // Pattern trang trí
                  Positioned(
                    top: -100,
                    right: -50,
                    child: CircleAvatar(
                      radius: 140,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  Positioned(
                    bottom: -50,
                    left: -80,
                    child: CircleAvatar(
                      radius: 120,
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),

                  SafeArea(
                    child: Center(
                      child: SingleChildScrollView(
                        child: TweenAnimationBuilder(
                          duration: const Duration(milliseconds: 1000),
                          tween: Tween<double>(begin: 0, end: 1),
                          curve: Curves.easeOutExpo,
                          builder: (context, double value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 40 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24.0,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // LOGO
                                Hero(
                                  tag: 'app_logo',
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.1,
                                          ),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    child: Image.asset(
                                      'assets/images/LOGO.png',
                                      errorBuilder:
                                          (context, error, stackTrace) => Icon(
                                            Icons.local_hospital,
                                            size: 50,
                                            color: primaryColor,
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'My HungVuong',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Cổng thông tin nội bộ',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                                const SizedBox(height: 40),

                                // CARD ĐĂNG NHẬP HIỆN ĐẠI
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(32),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 30,
                                        offset: const Offset(0, 15),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    children: [
                                      TextFormField(
                                        controller: _manvController,
                                        decoration: InputDecoration(
                                          labelText: 'Mã nhân viên',
                                          labelStyle: TextStyle(
                                            color: Colors.grey.shade600,
                                          ),
                                          prefixIcon: Icon(
                                            Icons.badge_rounded,
                                            color: primaryColor,
                                          ),
                                          filled: true,
                                          fillColor: const Color(0xFFF8FAFC),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            borderSide: BorderSide(
                                              color: primaryColor,
                                              width: 1.5,
                                            ),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                vertical: 18,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      TextFormField(
                                        controller: _passwordController,
                                        obscureText: !_isPasswordVisible,
                                        decoration: InputDecoration(
                                          labelText: 'Mật khẩu',
                                          labelStyle: TextStyle(
                                            color: Colors.grey.shade600,
                                          ),
                                          prefixIcon: Icon(
                                            Icons.lock_rounded,
                                            color: primaryColor,
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _isPasswordVisible
                                                  ? Icons.visibility
                                                  : Icons.visibility_off,
                                              color: Colors.grey.shade500,
                                            ),
                                            onPressed: () => setState(
                                              () => _isPasswordVisible =
                                                  !_isPasswordVisible,
                                            ),
                                          ),
                                          filled: true,
                                          fillColor: const Color(0xFFF8FAFC),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            borderSide: BorderSide(
                                              color: primaryColor,
                                              width: 1.5,
                                            ),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                vertical: 18,
                                              ),
                                        ),
                                      ),

                                      // 🔥 1. ĐƯA "QUÊN MẬT KHẨU" LÊN ĐÂY (Sát dưới ô Mật khẩu)
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const ForgotPasswordScreen(),
                                              ),
                                            );
                                          },
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.only(
                                              top: 12,
                                              bottom: 4,
                                            ), // Căn chỉnh khoảng cách tinh tế
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          child: Text(
                                            'Quên mật khẩu?',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: primaryColor,
                                            ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(
                                        height: 24,
                                      ), // Khoảng cách tới nút Đăng nhập chính
                                      // --- NÚT ĐĂNG NHẬP CHÍNH ---
                                      SizedBox(
                                        width: double.infinity,
                                        height: 56,
                                        child: ElevatedButton(
                                          onPressed: isLoading
                                              ? null
                                              : _handleLogin,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: primaryColor,
                                            elevation: 5,
                                            shadowColor: primaryColor
                                                .withOpacity(0.5),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                          ),
                                          child: isLoading
                                              ? const CircularProgressIndicator(
                                                  color: Colors.white,
                                                )
                                              : const Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      'ĐĂNG NHẬP',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        letterSpacing: 1.2,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    SizedBox(width: 8),
                                                    Icon(
                                                      Icons
                                                          .arrow_forward_rounded,
                                                      color: Colors.white,
                                                      size: 20,
                                                    ),
                                                  ],
                                                ),
                                        ),
                                      ),

                                      // 🔥 2. THIẾT KẾ LẠI KHỐI SINH TRẮC HỌC (Gọn gàng, cân đối)
                                      if (_isBiometricSupported) ...[
                                        const SizedBox(height: 24),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Divider(
                                                color: Colors.grey.shade300,
                                                thickness: 1,
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                  ),
                                              child: Text(
                                                'HOẶC',
                                                style: TextStyle(
                                                  color: Colors.grey.shade400,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Divider(
                                                color: Colors.grey.shade300,
                                                thickness: 1,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        SizedBox(
                                          width: double.infinity,
                                          height:
                                              56, // Cùng chiều cao với nút Đăng nhập
                                          child: OutlinedButton.icon(
                                            onPressed: isLoading
                                                ? null
                                                : _handleBiometricLogin,
                                            style: OutlinedButton.styleFrom(
                                              side: BorderSide(
                                                color: primaryColor.withOpacity(
                                                  0.4,
                                                ),
                                                width: 1.5,
                                              ),
                                              backgroundColor: primaryColor
                                                  .withOpacity(
                                                    0.04,
                                                  ), // Phủ lớp nền siêu nhạt
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              elevation: 0,
                                            ),
                                            icon: Icon(
                                              Icons.fingerprint_rounded,
                                              size: 28,
                                              color: primaryColor,
                                            ),
                                            label: Text(
                                              'Đăng nhập bằng Sinh trắc học',
                                              style: TextStyle(
                                                color: primaryColor,
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 30),

                                Container(
                                  width: double.infinity,
                                  height:
                                      65, // Chiều cao cố định cho khối hotline
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(
                                      50,
                                    ), // Bo tròn hoàn toàn
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
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
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const DanhBaTrucScreen(),
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        child: Row(
                                          children: [
                                            // Icon bên trái
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: primaryColor.withOpacity(
                                                  0.1,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.phone_in_talk_rounded,
                                                color: primaryColor,
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 12),

                                            // Text ở giữa
                                            const Expanded(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Liên hệ',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Số trực toàn hệ thống',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFF2C3E50),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 8,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: primaryColor,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: const Text(
                                                'Gọi điện',
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
                                ),

                                const SizedBox(height: 40),

                                const Text(
                                  '© 2026 Phòng Công Nghệ Thông Tin - thaiit™',
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 207, 206, 206),
                                    fontSize: 12,
                                    fontStyle: FontStyle.normal,
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
