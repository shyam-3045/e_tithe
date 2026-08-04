import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../common/constants/app_colors.dart';
import '../../common/services/auth_service.dart';
import '../../common/widgets/app_form_text_field.dart';
import '../../common/widgets/common_alert.dart';
import '../../common/widgets/primary_button.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _hideOld = true;
  bool _hideNew = true;
  bool _hideConfirm = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();

    if (_oldPasswordController.text.trim().isEmpty) {
      _showToast('Old password is required');
      return;
    }
    if (_newPasswordController.text.trim().isEmpty) {
      _showToast('New password is required');
      return;
    }
    if (_confirmPasswordController.text.trim().isEmpty) {
      _showToast('Please retype password');
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showToast('Passwords do not match');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final AuthSession? session = await AuthService.instance.currentSession();
      final String email = session?.email?.trim() ?? '';
      if (email.isEmpty) {
        if (!mounted) return;
        await CommonAlert.showInfo(
          context,
          title: 'Session expired',
          message: 'Could not find your account email. Please login again.',
        );
        return;
      }

      await AuthService.instance.changePassword(
        emailID: email,
        oldPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully.')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      await CommonAlert.showInfo(
        context,
        title: 'Change password failed',
        message: error.toString(),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.primaryPurple,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        appBar: AppBar(title: const Text('Change Password')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
            child: Column(
              children: [
                  AppFormTextField(
                    controller: _oldPasswordController,
                    hintText: 'Old Password',
                    icon: Icons.key,
                    obscureText: _hideOld,
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _hideOld = !_hideOld),
                      icon: Icon(
                        _hideOld
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.textGrey,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppFormTextField(
                    controller: _newPasswordController,
                    hintText: 'Password',
                    icon: Icons.key,
                    obscureText: _hideNew,
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _hideNew = !_hideNew),
                      icon: Icon(
                        _hideNew
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.textGrey,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppFormTextField(
                    controller: _confirmPasswordController,
                    hintText: 'Retype Password',
                    icon: Icons.key,
                    obscureText: _hideConfirm,
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _hideConfirm = !_hideConfirm),
                      icon: Icon(
                        _hideConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.textGrey,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  PrimaryButton(
                    label: 'Submit',
                    isLoading: _isSubmitting,
                    onPressed: _isSubmitting ? null : _handleSubmit,
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }
}


class _GradientAppBarBackground extends StatelessWidget {
  const _GradientAppBarBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.statusBarPink, AppColors.primaryPurple],
        ),
      ),
    );
  }
}

class _OutlinedPasswordField extends StatelessWidget {
  const _OutlinedPasswordField({
    required this.controller,
    required this.label,
    required this.obscureText,
    required this.onToggle,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.key, color: AppColors.iconPurple),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: AppColors.textGrey,
          ),
        ),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.borderGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.borderGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: AppColors.primaryPurple,
            width: 1.2,
          ),
        ),
      ),
    );
  }
}
