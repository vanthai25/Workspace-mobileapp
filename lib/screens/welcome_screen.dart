import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/auth_provider.dart';
import '../services/app_config_service.dart';
import 'change_password_screen.dart';
import 'login_screen.dart';
import 'main_root_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({
    super.key,
  });

  @override
  State<WelcomeScreen> createState() =>
      _WelcomeScreenState();
}

class _WelcomeScreenState
    extends State<WelcomeScreen> {
  final Color primaryColor =
      const Color(0xFF1274BC);

  final Color primaryLight =
      const Color(0xFF4FA5E5);

  @override
  void initState() {
    super.initState();

    _preloadAndNavigate();
  }

  // =========================================================
  // KHỞI TẠO APP
  // =========================================================

  Future<void> _preloadAndNavigate() async {
    try {
      // =====================================================
      // 1. KIỂM TRA CẤU HÌNH HỆ THỐNG
      // =====================================================

      await _checkSystemConfig();

      if (!mounted) {
        return;
      }

      // =====================================================
      // 2. KIỂM TRA PHIÊN ĐĂNG NHẬP
      // =====================================================

      await _checkAuthenticationAndNavigate();
    } catch (e, stackTrace) {
      debugPrint(
        'WelcomeScreen: Lỗi khởi tạo: $e',
      );

      debugPrint(
        'WelcomeScreen: $stackTrace',
      );

      if (!mounted) {
        return;
      }

      // =====================================================
      // Nếu lỗi kiểm tra config/version,
      // không để Welcome quay vô hạn.
      //
      // Vẫn thử kiểm tra phiên đăng nhập.
      // =====================================================

      try {
        await _checkAuthenticationAndNavigate();
      } catch (authError) {
        debugPrint(
          'WelcomeScreen: '
          'Lỗi kiểm tra đăng nhập: '
          '$authError',
        );

        if (!mounted) {
          return;
        }

        _goToLogin();
      }
    }
  }

  // =========================================================
  // SYSTEM CONFIG
  // =========================================================

  Future<void> _checkSystemConfig() async {
    try {
      final config =
          await AppConfigService()
              .getSystemConfig();

      if (!mounted) {
        return;
      }

      if (config == null) {
        debugPrint(
          'WelcomeScreen: '
          'Không lấy được SystemConfig, '
          'tiếp tục vào ứng dụng.',
        );

        return;
      }

      // =====================================================
      // BẢO TRÌ:
      // Áp dụng cho cả Android / iOS / Web.
      // =====================================================

      if (config.isMaintenanceMode) {
        _showMaintenanceScreen(
          config.maintenanceMessage,
        );

        throw const _NavigationHandledException();
      }

      // =====================================================
      // WEB:
      // KHÔNG CHECK VERSION.
      //
      // Web publish phiên bản mới trên server,
      // người dùng chỉ cần tải lại trang.
      // =====================================================

      if (kIsWeb) {
        debugPrint(
          'WelcomeScreen: '
          'Web - bỏ qua kiểm tra phiên bản.',
        );

        return;
      }

      // =====================================================
      // ANDROID / IOS:
      // GIỮ NGUYÊN CƠ CHẾ CHECK VERSION CŨ.
      // =====================================================

      final PackageInfo packageInfo =
          await PackageInfo.fromPlatform();

      final String currentVersion =
          packageInfo.version;

      final bool isIOS =
          defaultTargetPlatform ==
              TargetPlatform.iOS;

      final String latestVersion =
          isIOS
              ? config.iosVersion
              : config.androidVersion;

      debugPrint(
        'WelcomeScreen: '
        'Current=$currentVersion, '
        'Latest=$latestVersion',
      );

      if (!_isUpdateRequired(
        currentVersion,
        latestVersion,
      )) {
        return;
      }

      final String? downloadUrl =
          isIOS
              ? config.iosDownloadUrl
              : config.androidDownloadUrl;

      final bool shouldProceed =
          await _showUpdateDialog(
        updateMessage:
            config.updateMessage,
        downloadUrl:
            downloadUrl,
        isForceUpdate:
            config.forceUpdate,
      );

      if (!shouldProceed) {
        throw const _NavigationHandledException();
      }
    } on _NavigationHandledException {
      rethrow;
    } catch (e) {
      // =====================================================
      // Lỗi config/version không được phép làm app treo
      // ở Welcome.
      // =====================================================

      debugPrint(
        'WelcomeScreen: '
        'Không kiểm tra được cấu hình hệ thống: '
        '$e',
      );
    }
  }

  // =========================================================
  // AUTHENTICATION
  // =========================================================

  Future<void>
      _checkAuthenticationAndNavigate() async {
    if (!mounted) {
      return;
    }

    final AuthProvider auth =
        context.read<AuthProvider>();

    debugPrint(
      'WelcomeScreen: '
      'Đang kiểm tra phiên đăng nhập...',
    );

    final bool isLoggedIn =
        await auth.tryAutoLogin();

    debugPrint(
      'WelcomeScreen: '
      'isLoggedIn=$isLoggedIn',
    );

    if (!mounted) {
      return;
    }

    if (!isLoggedIn) {
      _goToLogin();
      return;
    }

    final bool isExpired =
        auth.isPasswordExpired();

    debugPrint(
      'WelcomeScreen: '
      'passwordExpired=$isExpired',
    );

    if (isExpired) {
      _goToChangePassword();
      return;
    }

    _goToHome();
  }

  // =========================================================
  // NAVIGATION
  // =========================================================

  void _goToHome() {
    if (!mounted) {
      return;
    }

    debugPrint(
      'WelcomeScreen: '
      'Điều hướng MainRootScreen.',
    );

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration:
            const Duration(
          milliseconds: 400,
        ),
        pageBuilder:
            (_, __, ___) =>
                const MainRootScreen(),
        transitionsBuilder:
            (
              _,
              animation,
              __,
              child,
            ) {
          const Curve curve =
              Curves.easeOutCubic;

          final Animation<double> opacity =
              animation.drive(
            Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).chain(
              CurveTween(
                curve: curve,
              ),
            ),
          );

          final Animation<double> scale =
              animation.drive(
            Tween<double>(
              begin: 1.02,
              end: 1.0,
            ).chain(
              CurveTween(
                curve: curve,
              ),
            ),
          );

          return FadeTransition(
            opacity: opacity,
            child: ScaleTransition(
              scale: scale,
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _goToLogin() {
    if (!mounted) {
      return;
    }

    debugPrint(
      'WelcomeScreen: '
      'Điều hướng LoginScreen.',
    );

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration:
            const Duration(
          milliseconds: 400,
        ),
        pageBuilder:
            (_, __, ___) =>
                const LoginScreen(),
        transitionsBuilder:
            (
              _,
              animation,
              __,
              child,
            ) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  void _goToChangePassword() {
    if (!mounted) {
      return;
    }

    debugPrint(
      'WelcomeScreen: '
      'Điều hướng ChangePasswordScreen.',
    );

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration:
            const Duration(
          milliseconds: 400,
        ),
        pageBuilder:
            (_, __, ___) =>
                const ChangePasswordScreen(
          isForced: true,
        ),
        transitionsBuilder:
            (
              _,
              animation,
              __,
              child,
            ) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  // =========================================================
  // VERSION
  // =========================================================

  bool _isUpdateRequired(
    String current,
    String latest,
  ) {
    try {
      final List<int> currentParts =
          current
              .split('.')
              .map(
                (String e) =>
                    int.tryParse(e) ?? 0,
              )
              .toList();

      final List<int> latestParts =
          latest
              .split('.')
              .map(
                (String e) =>
                    int.tryParse(e) ?? 0,
              )
              .toList();

      final int maxLength =
          currentParts.length >
                  latestParts.length
              ? currentParts.length
              : latestParts.length;

      for (int i = 0;
          i < maxLength;
          i++) {
        final int currentValue =
            i < currentParts.length
                ? currentParts[i]
                : 0;

        final int latestValue =
            i < latestParts.length
                ? latestParts[i]
                : 0;

        if (latestValue >
            currentValue) {
          return true;
        }

        if (latestValue <
            currentValue) {
          return false;
        }
      }
    } catch (e) {
      debugPrint(
        'WelcomeScreen: '
        'Lỗi so sánh phiên bản: $e',
      );
    }

    return false;
  }

  // =========================================================
  // MAINTENANCE
  // =========================================================

  void _showMaintenanceScreen(
    String? message,
  ) {
    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder:
            (BuildContext context) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(
                  24,
                ),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.engineering,
                      size: 80,
                      color: Colors.blue,
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    const Text(
                      'ĐANG BẢO TRÌ',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      message ??
                          'Hệ thống đang bảo trì',
                      textAlign:
                          TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // =========================================================
  // UPDATE DIALOG
  // Chỉ được gọi trên Android/iOS.
  // =========================================================

  Future<bool> _showUpdateDialog({
    String? updateMessage,
    String? downloadUrl,
    required bool isForceUpdate,
  }) async {
    if (!mounted) {
      return false;
    }

    return await showDialog<bool>(
          context: context,
          barrierDismissible:
              !isForceUpdate,
          builder:
              (BuildContext dialogContext) {
            return PopScope(
              canPop:
                  !isForceUpdate,
              child: AlertDialog(
                title:
                    const Text(
                  'Cập nhật phiên bản mới',
                ),
                content:
                    Text(
                  updateMessage ??
                      'Vui lòng cập nhật '
                          'để tiếp tục.',
                ),
                actions: [
                  if (!isForceUpdate)
                    TextButton(
                      onPressed: () {
                        Navigator.of(
                          dialogContext,
                        ).pop(
                          true,
                        );
                      },
                      child:
                          const Text(
                        'Để sau',
                      ),
                    ),
                  ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(
                        0xFF1274BC,
                      ),
                      foregroundColor:
                          Colors.white,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          10,
                        ),
                      ),
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onPressed:
                        () async {
                      if (downloadUrl ==
                              null ||
                          downloadUrl
                              .trim()
                              .isEmpty) {
                        return;
                      }

                      final Uri uri =
                          Uri.parse(
                        downloadUrl,
                      );

                      await launchUrl(
                        uri,
                        mode:
                            LaunchMode
                                .externalApplication,
                      );
                    },
                    child:
                        const Text(
                      'Cập nhật',
                    ),
                  ),
                ],
              ),
            );
          },
        ) ??
        false;
  }

  // =========================================================
  // UI
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final AuthProvider auth =
        context.watch<AuthProvider>();

    final String displayName =
        auth.currentManv ??
        '';

    final String tenNhanVien =
        auth.currentTenNV ??
        '';

    return Scaffold(
      body: Container(
        width:
            double.infinity,
        decoration:
            BoxDecoration(
          gradient:
              LinearGradient(
            begin:
                Alignment.topLeft,
            end:
                Alignment.bottomRight,
            colors: [
              primaryLight,
              primaryColor,
              const Color(
                0xFF0A4E80,
              ),
            ],
          ),
        ),
        child:
            Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Stack(
              alignment:
                  Alignment.center,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child:
                      CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<
                            Color>(
                      Colors.white
                          .withOpacity(
                        0.8,
                      ),
                    ),
                    strokeWidth: 3,
                  ),
                ),
                Hero(
                  tag: 'app_logo',
                  child:
                      Container(
                    width: 100,
                    height: 100,
                    decoration:
                        BoxDecoration(
                      color:
                          Colors.white,
                      shape:
                          BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              Colors.white
                                  .withOpacity(
                            0.3,
                          ),
                          blurRadius:
                              20,
                          spreadRadius:
                              5,
                        ),
                      ],
                    ),
                    padding:
                        const EdgeInsets.all(
                      18,
                    ),
                    child:
                        Image.asset(
                      'assets/images/LOGO.png',
                      errorBuilder:
                          (
                            _,
                            __,
                            ___,
                          ) {
                        return Icon(
                          Icons.local_hospital,
                          size: 45,
                          color:
                              primaryColor,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 40,
            ),
            TweenAnimationBuilder<double>(
              duration:
                  const Duration(
                milliseconds: 800,
              ),
              tween:
                  Tween<double>(
                begin: 0,
                end: 1,
              ),
              curve:
                  Curves.easeOutCubic,
              builder:
                  (
                    BuildContext context,
                    double value,
                    Widget? child,
                  ) {
                return Opacity(
                  opacity: value,
                  child:
                      Transform.translate(
                    offset:
                        Offset(
                      0,
                      20 *
                          (1 - value),
                    ),
                    child: child,
                  ),
                );
              },
              child:
                  Column(
                children: [
                  const Text(
                    'Xin chào',
                    style:
                        TextStyle(
                      fontSize: 20,
                      color:
                          Colors.white70,
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Text(
                    displayName.isEmpty
                        ? 'Đang kết nối...'
                        : '$displayName'
                            ' - '
                            '$tenNhanVien',
                    style:
                        const TextStyle(
                      fontSize: 26,
                      fontWeight:
                          FontWeight.w900,
                      color:
                          Colors.white,
                      letterSpacing:
                          1.0,
                    ),
                    textAlign:
                        TextAlign.center,
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  Text(
                    kIsWeb
                        ? 'My HungVuong - '
                            'Đang khởi tạo Web'
                        : 'My HungVuong - '
                            'Đang khởi tạo hệ thống',
                    style:
                        TextStyle(
                      fontSize: 15,
                      color:
                          Colors.white
                              .withOpacity(
                        0.8,
                      ),
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
}


class _NavigationHandledException
    implements Exception {
  const _NavigationHandledException();
}
