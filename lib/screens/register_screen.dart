import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/helpers.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _manvController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  bool _isPasswordVisible = false;

  final Color primaryColor = const Color(0xFF1274BC);
  final Color primaryLight = const Color(0xFF4FA5E5);

  void _handleRegister() async {
    final manv = _manvController.text.trim();
    final password = _passwordController.text.trim();
    final email = _emailController.text.trim();
    final role = _roleController.text.trim();

    if (manv.isEmpty || password.isEmpty || email.isEmpty || role.isEmpty) {
      AppHelpers.showSnackBar('Vui lòng nhập đầy đủ thông tin để đăng ký', isError: true);
      return;
    }

    try {
      final success = await context.read<AuthProvider>().register(manv, password, email, role);
      if (success && mounted) {
        AppHelpers.showSnackBar('Đăng ký thành công! Vui lòng đăng nhập.');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(e.toString(), isError: true);
      }
    }
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, bool isPassword = false, TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && !_isPasswordVisible,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: primaryColor),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                  onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                )
              : null,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primaryColor, width: 1.5)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryLight, primaryColor, const Color(0xFF0A4E80)],
              ),
            ),
          ),
          Positioned(top: -30, right: -30, child: CircleAvatar(radius: 100, backgroundColor: Colors.white.withOpacity(0.08))),
          Positioned(bottom: -50, left: -50, child: CircleAvatar(radius: 120, backgroundColor: Colors.white.withOpacity(0.05))),

          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
                child: Column(
                  children: [
                    Hero(
                      tag: 'app_logo',
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.3), blurRadius: 20, spreadRadius: 3)],
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Image.asset(
                          'assets/images/LOGO.png',
                          errorBuilder: (context, error, stackTrace) => Icon(Icons.local_hospital, size: 40, color: primaryColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Mở Tài Khoản Mới', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.0)),
                    const SizedBox(height: 30),
                    
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 40, offset: const Offset(0, 15))],
                      ),
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        children: [
                          _buildTextField(controller: _manvController, label: 'Mã nhân viên', icon: Icons.badge_rounded),
                          _buildTextField(controller: _emailController, label: 'Email', icon: Icons.email_rounded, keyboardType: TextInputType.emailAddress),
                          _buildTextField(controller: _roleController, label: 'Phân quyền', icon: Icons.admin_panel_settings_rounded),
                          _buildTextField(controller: _passwordController, label: 'Mật khẩu', icon: Icons.lock_rounded, isPassword: true),
                          const SizedBox(height: 20),
                          
                          Container(
                            width: double.infinity,
                            height: 55,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(colors: [primaryColor, const Color(0xFF0A4E80)]),
                              boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))],
                            ),
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _handleRegister,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text('XÁC NHẬN ĐĂNG KÝ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
