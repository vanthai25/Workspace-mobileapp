import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/auth_api_exception.dart';
import '../utils/helpers.dart';

class ChangePasswordScreen
    extends StatefulWidget {
  final bool isForced;
  final String? manv;

  const ChangePasswordScreen({
    super.key,
    this.isForced = false,
    this.manv,
  });

  @override
  State<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState
    extends State<ChangePasswordScreen> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final TextEditingController
      _oldPasswordController =
      TextEditingController();

  final TextEditingController
      _newPasswordController =
      TextEditingController();

  final TextEditingController
      _confirmPasswordController =
      TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  final Color primaryColor =
      const Color(0xFF1274BC);

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }
  Future<void> _backToLogin() async {
  final bool? confirmed =
      await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text(
          'Quay về đăng nhập',
        ),
        content: const Text(
          'Bạn có muốn thoát khỏi màn hình '
          'đổi mật khẩu và quay về đăng nhập không?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(
                dialogContext,
                false,
              );
            },
            child: const Text('Ở lại'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(
                dialogContext,
                true,
              );
            },
            child: const Text(
              'Về đăng nhập',
            ),
          ),
        ],
      );
    },
  );

  if (confirmed != true || !mounted) {
    return;
  }

  await context
      .read<AuthProvider>()
      .exitPasswordChangeToLogin();

  if (!mounted) {
    return;
  }

  Navigator.pushNamedAndRemoveUntil(
    context,
    '/login',
    (Route<dynamic> route) => false,
  );
}
  Future<void> _submitChangePassword() async {
    final bool isValid =
        _formKey.currentState?.validate() ??
            false;

    if (!isValid) {
      return;
    }

    FocusScope.of(context).unfocus();

    final String oldPassword =
        _oldPasswordController.text;

    final String newPassword =
        _newPasswordController.text;

    final String confirmPassword =
        _confirmPasswordController.text;

    if (newPassword != confirmPassword) {
      AppHelpers.showSnackBar(
        'Mật khẩu xác nhận không khớp.',
        isError: true,
      );
      return;
    }

    try {
      final bool success = await context
          .read<AuthProvider>()
          .changePassword(
            oldPassword,
            newPassword,
            manv: widget.manv,
          );

      if (!mounted) {
        return;
      }

      if (success) {
        AppHelpers.showSnackBar(
          'Đổi mật khẩu thành công. '
          'Vui lòng đăng nhập lại.',
        );

        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (Route<dynamic> route) => false,
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoading =
        context.watch<AuthProvider>().isLoading;

    return PopScope(
      canPop: !widget.isForced,
      child: Scaffold(
        backgroundColor:
            const Color(0xFFF0F2F5),
        appBar: AppBar(
          automaticallyImplyLeading:
              !widget.isForced,
          title: const Text(
            'Đổi mật khẩu',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Container(
                      padding:
                          const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: primaryColor
                            .withValues(
                          alpha: 0.1,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_reset_rounded,
                        size: 60,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  if (widget.isForced) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Mật khẩu của bạn đã hết hạn!\n'
                      'Vui lòng đổi mật khẩu mới '
                      'để tiếp tục sử dụng hệ thống.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 15,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                  _buildPasswordField(
                    controller:
                        _oldPasswordController,
                    label: 'Mật khẩu hiện tại',
                    hint:
                        'Nhập mật khẩu đang sử dụng',
                    obscureText: _obscureOld,
                    textInputAction:
                        TextInputAction.next,
                    onToggleVisibility: () {
                      setState(() {
                        _obscureOld =
                            !_obscureOld;
                      });
                    },
                    validator: (String? value) {
                      if (value == null ||
                          value.isEmpty) {
                        return 'Vui lòng nhập '
                            'mật khẩu hiện tại';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildPasswordField(
                    controller:
                        _newPasswordController,
                    label: 'Mật khẩu mới',
                    hint: 'Nhập mật khẩu mới',
                    obscureText: _obscureNew,
                    textInputAction:
                        TextInputAction.next,
                    onToggleVisibility: () {
                      setState(() {
                        _obscureNew =
                            !_obscureNew;
                      });
                    },
                    validator: (String? value) {
                      if (value == null ||
                          value.isEmpty) {
                        return 'Vui lòng nhập '
                            'mật khẩu mới';
                      }

                      if (value.length < 6) {
                        return 'Mật khẩu phải có '
                            'ít nhất 6 ký tự';
                      }

                      if (value ==
                          _oldPasswordController
                              .text) {
                        return 'Mật khẩu mới phải '
                            'khác mật khẩu cũ';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildPasswordField(
                    controller:
                        _confirmPasswordController,
                    label:
                        'Xác nhận mật khẩu mới',
                    hint: 'Nhập lại mật khẩu mới',
                    obscureText:
                        _obscureConfirm,
                    textInputAction:
                        TextInputAction.done,
                    onFieldSubmitted: (_) {
                      if (!isLoading) {
                        _submitChangePassword();
                      }
                    },
                    onToggleVisibility: () {
                      setState(() {
                        _obscureConfirm =
                            !_obscureConfirm;
                      });
                    },
                    validator: (String? value) {
                      if (value == null ||
                          value.isEmpty) {
                        return 'Vui lòng xác nhận '
                            'mật khẩu';
                      }

                      if (value !=
                          _newPasswordController
                              .text) {
                        return 'Mật khẩu xác nhận '
                            'không khớp';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : _submitChangePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'CẬP NHẬT MẬT KHẨU',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: isLoading
                          ? null
                          : _backToLogin,
                      icon: const Icon(
                        Icons.logout_rounded,
                      ),
                      label: const Text(
                        'QUAY VỀ ĐĂNG NHẬP',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(
                          color: Colors.redAccent,
                          width: 1.3,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscureText,
    required TextInputAction textInputAction,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
    ValueChanged<String>? onFieldSubmitted,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          textInputAction: textInputAction,
          onFieldSubmitted:
              onFieldSubmitted,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(12),
              borderSide: BorderSide(
                color: primaryColor,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1.5,
              ),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: Colors.grey,
              ),
              onPressed:
                  onToggleVisibility,
            ),
          ),
        ),
      ],
    );
  }
}