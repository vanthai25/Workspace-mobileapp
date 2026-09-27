import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; 

import '../providers/auth_provider.dart';
import 'change_password_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _appVersion = 'Đang kiểm tra...';
  bool _isBiometricEnabled = false;
  bool _isLoggingOut = false;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    _loadBiometricStatus();
  }

  Future<void> _loadBiometricStatus() async {
    String? status = await _storage.read(key: 'bio_enabled');
    if (mounted) {
      setState(() {
        _isBiometricEnabled = (status == 'true');
      });
    }
  }

  Future<void> _loadAppVersion() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _appVersion = 'Phiên bản ${packageInfo.version} (Build ${packageInfo.buildNumber})');
      }
    } catch (e) {
      if (mounted) setState(() => _appVersion = 'Không thể tải phiên bản');
    }
  }

  // --- HỘP THOẠI NHẬP MẬT KHẨU KHI BẬT VÂN TAY ---
  Future<String?> _showPasswordDialog() {
    final pwdController = TextEditingController();
    bool isVisible = false;
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSB) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Xác nhận mật khẩu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Vui lòng nhập mật khẩu để ứng dụng ghi nhớ cho các lần đăng nhập nhanh sau.', style: TextStyle(fontSize: 14)),
                const SizedBox(height: 16),
                TextField(
                  controller: pwdController,
                  obscureText: !isVisible,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu của bạn',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: IconButton(
                      icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                      onPressed: () => setStateSB(() => isVisible = !isVisible),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('HỦY', style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1274BC)),
                onPressed: () => Navigator.pop(context, pwdController.text),
                child: const Text('BẬT TÍNH NĂNG', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      ),
    );
  }

  Future<void> _handleToggleBiometric(bool enable) async {
  final auth = context.read<AuthProvider>();

  if (!enable) {
    await auth.toggleBiometric(false, '', '');

    if (!mounted) return;

    setState(() => _isBiometricEnabled = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã tắt đăng nhập bằng sinh trắc học!'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  if (!await auth.isBiometricSupported()) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Thiết bị chưa thiết lập vân tay hoặc nhận diện khuôn mặt!',
        ),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  final String? password = await _showPasswordDialog();

  if (!mounted || password == null || password.isEmpty) {
    return;
  }

  final String manv = auth.currentManv ?? '';
  bool loadingOpen = false;

  // Bước 1: xác nhận lại mật khẩu
  try {
    loadingOpen = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF1274BC),
          ),
        ),
      ),
    );

    await auth.login(manv, password);
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Lỗi: ${e.toString().replaceFirst('Exception: ', '')}',
        ),
        backgroundColor: Colors.red,
      ),
    );
    return;
  } finally {
    // Chỉ đóng đúng loading dialog
    if (loadingOpen && mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      loadingOpen = false;
    }
  }

  if (!mounted) return;

  // Bước 2: mở hộp thoại sinh trắc học
  try {
    final bool success = await auth.toggleBiometric(
      true,
      manv,
      password,
    );

    if (!mounted) return;

    if (success) {
      setState(() => _isBiometricEnabled = true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã bật đăng nhập bằng sinh trắc học!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã hủy xác thực sinh trắc học.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  } on LocalAuthException catch (e) {
    if (!mounted) return;

    final bool canceled =
        e.code == LocalAuthExceptionCode.userCanceled ||
        e.code == LocalAuthExceptionCode.systemCanceled;

    final String message;

    if (canceled) {
      message = 'Đã hủy xác thực sinh trắc học.';
    } else if (e.code == LocalAuthExceptionCode.temporaryLockout) {
      message =
          'Sinh trắc học đang tạm khóa do xác thực sai nhiều lần.';
    } else if (e.code == LocalAuthExceptionCode.biometricLockout) {
      message =
          'Sinh trắc học đã bị khóa. Hãy mở khóa thiết bị rồi thử lại.';
    } else if (e.code ==
        LocalAuthExceptionCode.noBiometricsEnrolled) {
      message =
          'Thiết bị chưa đăng ký vân tay hoặc nhận diện khuôn mặt.';
    } else {
      message = e.description ?? 'Không thể xác thực sinh trắc học.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: canceled ? Colors.orange : Colors.red,
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Không thể xác thực sinh trắc học: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
  Widget _buildAvatar(String? base64String, String tenNhanVien) {
    if (base64String != null && base64String.isNotEmpty) {
      try {
        String cleanBase64 = base64String.contains(',') ? base64String.split(',').last : base64String;
        return CircleAvatar(radius: 30, backgroundColor: Colors.white, backgroundImage: MemoryImage(base64Decode(cleanBase64)));
      } catch (e) {
        debugPrint('Lỗi giải mã ảnh Menu: $e');
      }
    }
    return CircleAvatar(
      radius: 30, backgroundColor: const Color(0xFF1274BC).withOpacity(0.1),
      child: Text(tenNhanVien.isNotEmpty ? tenNhanVien[0].toUpperCase() : '?', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1274BC))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tenNhanVien = auth.currentTenNV ?? 'Nhân viên';
    final manv = auth.currentManv ?? '';
    final anhNhanVien = auth.currentAvatar; 

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Menu', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF2C3E50), fontSize: 24)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        // 🔥 Đã sửa ở đây: Tăng khoảng padding bottom lên 120 để khi kéo lên không bị kẹt dưới bottom nav bar
        padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 120),
        child: Column(
          children: [
            InkWell(
              onTap: () {
                if (manv.isNotEmpty) Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(manv: manv)));
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF1274BC).withOpacity(0.2), width: 2)),
                      child: _buildAvatar(anhNhanVien, tenNhanVien),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tenNhanVien, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                          const SizedBox(height: 4),
                          Text('Xem trang cá nhân', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            _buildMenuGroup(
              title: 'Tài khoản & Bảo mật',
              items: [
                _buildMenuItem(
                  icon: Icons.lock_reset_rounded, color: Colors.orange, title: 'Đổi mật khẩu',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen(isForced: false))),
                ),
                _buildSwitchMenuItem(
                  icon: Icons.fingerprint_rounded, 
                  color: Colors.teal, 
                  title: 'Đăng nhập sinh trắc học', 
                  subtitle: 'FaceID / Vân tay',
                  value: _isBiometricEnabled,
                  onChanged: _handleToggleBiometric,
                ),
              ],
            ),
            const SizedBox(height: 24),

            _buildMenuGroup(
              title: 'Ứng dụng',
              items: [
                _buildMenuItem(
                  icon: Icons.info_outline_rounded, color: Colors.blue, title: 'Phiên bản ứng dụng', subtitle: _appVersion, showTrailing: false,
                  onTap: () {},
                ),
                _buildMenuItem(
                  icon: Icons.headset_mic_rounded, color: Colors.green, title: 'Hỗ trợ kỹ thuật', subtitle: '0948.538.115', showTrailing: false,
                  onTap: () async {
                    final Uri telUri = Uri.parse('tel:0948538115');
                    if (await canLaunchUrl(telUri)) {
                      await launchUrl(telUri);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 30),

            ElevatedButton.icon(
              onPressed: _isLoggingOut ? null : () async {
                setState(() => _isLoggingOut = true); 
                
                await context.read<AuthProvider>().logout();
                
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context, 
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false // Quét sạch, không cho back lại
                  );
                }
              },
              icon: _isLoggingOut 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.redAccent, strokeWidth: 2))
                : const Icon(Icons.logout_rounded, color: Colors.redAccent),
              label: Text(
                _isLoggingOut ? 'Đang thoát...' : 'Đăng xuất', 
                style: const TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50, elevation: 0,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            
            // 🔥 Giữ lại phần đẩy bổ sung ở dưới để chừa chỗ an toàn
            const SizedBox(height: 80), 
          ],
        ),
      ),
    );
  }

  Widget _buildMenuGroup({required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(left: 8, bottom: 12), child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildMenuItem({required IconData icon, required Color color, required String title, String? subtitle, required VoidCallback onTap, bool showTrailing = true}) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle), child: Icon(icon, color: color, size: 22)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF2C3E50))),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)) : null,
      trailing: showTrailing ? Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400) : null,
    );
  }

  Widget _buildSwitchMenuItem({required IconData icon, required Color color, required String title, required String subtitle, required bool value, required ValueChanged<bool> onChanged}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle), child: Icon(icon, color: color, size: 22)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF2C3E50))),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF1274BC), 
      ),
    );
  }
}