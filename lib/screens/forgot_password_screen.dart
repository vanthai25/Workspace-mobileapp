import 'package:flutter/material.dart';

import '../services/auth_api_exception.dart';
import '../services/auth_service.dart';
import '../utils/helpers.dart';

class ForgotPasswordScreen
    extends StatefulWidget {
  const ForgotPasswordScreen({
    super.key,
  });

  @override
  State<ForgotPasswordScreen>
      createState() =>
          _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {
  final AuthService _authService =
      AuthService();

  final TextEditingController _manvCtrl =
      TextEditingController();

  final TextEditingController _emailCtrl =
      TextEditingController();

  final TextEditingController _otpCtrl =
      TextEditingController();

  final TextEditingController _newPassCtrl =
      TextEditingController();

  bool _isLoading = false;
  bool _isOtpSent = false;
  bool _isPasswordVisible = false;

  final Color primaryColor =
      const Color(0xFF1274BC);

  @override
  void dispose() {
    _manvCtrl.dispose();
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _newPassCtrl.dispose();

    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    final String manv =
        _manvCtrl.text.trim();

    final String email =
        _emailCtrl.text.trim();

    if (manv.isEmpty || email.isEmpty) {
      AppHelpers.showSnackBar(
        'Vui lòng nhập mã nhân viên '
        'và Email.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final bool success =
          await _authService.forgotPassword(
        manv,
        email,
      );

      if (!mounted) {
        return;
      }

      if (success) {
        setState(() {
          _isOtpSent = true;
        });

        AppHelpers.showSnackBar(
          'Đã gửi mã OTP đến Email '
          'của bạn.',
        );
      }
    } on AuthApiException catch (e) {
      if (!mounted) {
        return;
      }

      AppHelpers.showSnackBar(
        e.message,
        isError: true,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      AppHelpers.showSnackBar(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleResetPassword() async {
    final String otp =
        _otpCtrl.text.trim();

    /*
     * Không trim mật khẩu để không tự ý
     * thay đổi dữ liệu người dùng nhập.
     */
    final String newPassword =
        _newPassCtrl.text;

    final String email =
        _emailCtrl.text.trim();

    if (otp.isEmpty ||
        newPassword.isEmpty) {
      AppHelpers.showSnackBar(
        'Vui lòng nhập đầy đủ mã OTP '
        'và mật khẩu mới.',
        isError: true,
      );
      return;
    }

    if (otp.length != 6) {
      AppHelpers.showSnackBar(
        'Mã OTP phải gồm 6 chữ số.',
        isError: true,
      );
      return;
    }

    if (newPassword.length < 6) {
      AppHelpers.showSnackBar(
        'Mật khẩu mới phải có ít nhất '
        '6 ký tự.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final bool success =
          await _authService.resetPassword(
        email,
        otp,
        newPassword,
      );

      if (!mounted) {
        return;
      }

      if (success) {
        AppHelpers.showSnackBar(
          'Khôi phục mật khẩu thành công. '
          'Vui lòng đăng nhập lại.',
        );

        Navigator.pop(context);
      }
    } on AuthApiException catch (e) {
      if (!mounted) {
        return;
      }

      AppHelpers.showSnackBar(
        e.message,
        isError: true,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      AppHelpers.showSnackBar(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor:
              Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: primaryColor,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 24,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Icon(
                  Icons.lock_reset_rounded,
                  size: 80,
                  color: primaryColor,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Khôi phục\nmật khẩu',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _isOtpSent
                      ? 'Vui lòng kiểm tra Email '
                          'nội bộ và nhập mã OTP '
                          '6 số cùng mật khẩu mới.'
                      : 'Nhập mã nhân viên và '
                          'Email nội bộ để nhận '
                          'mã xác thực OTP.',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                if (!_isOtpSent)
                  _buildSendOtpStep(),
                if (_isOtpSent)
                  _buildResetPasswordStep(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSendOtpStep() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Mã nhân viên (5 chữ số)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _manvCtrl,
          decoration: InputDecoration(
            hintText: 'VD: 01368',
            prefixIcon: Icon(
              Icons.badge_rounded,
              color: primaryColor,
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Email nội bộ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailCtrl,
          keyboardType:
              TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText:
                'VD: thai01368@benhvienhungvuong.vn',
            prefixIcon: Icon(
              Icons.email_rounded,
              color: primaryColor,
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading
                ? null
                : _handleSendOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(16),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(
                    color: Colors.white,
                  )
                : const Text(
                    'GỬI MÃ XÁC THỰC',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildResetPasswordStep() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Mã xác thực (OTP)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _otpCtrl,
          keyboardType:
              TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 8,
          ),
          decoration: InputDecoration(
            hintText: 'Nhập mã 6 số',
            counterText: '',
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Mật khẩu mới',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _newPassCtrl,
          obscureText:
              !_isPasswordVisible,
          textInputAction:
              TextInputAction.done,
          onFieldSubmitted: (_) {
            if (!_isLoading) {
              _handleResetPassword();
            }
          },
          decoration: InputDecoration(
            hintText: 'Nhập mật khẩu mới',
            prefixIcon: Icon(
              Icons.lock_outline_rounded,
              color: primaryColor,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible
                    ? Icons.visibility
                    : Icons.visibility_off,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible =
                      !_isPasswordVisible;
                });
              },
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading
                ? null
                : _handleResetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  Colors.green.shade600,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(16),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(
                    color: Colors.white,
                  )
                : const Text(
                    'XÁC NHẬN ĐỔI MẬT KHẨU',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: _isLoading
                ? null
                : () {
                    setState(() {
                      _isOtpSent = false;
                      _otpCtrl.clear();
                      _newPassCtrl.clear();
                    });
                  },
            child: const Text(
              'Nhập sai Email? '
              'Gửi lại mã khác',
            ),
          ),
        ),
      ],
    );
  }
}