import 'package:flutter/material.dart';

import '../../common/constants/app_colors.dart';
import '../../common/constants/app_constants.dart';
import '../../common/services/auth_service.dart';
import '../../common/widgets/common_alert.dart';
import '../../common/widgets/app_logo.dart';
import '../../common/widgets/app_text_field.dart';
import '../../common/widgets/primary_button.dart';
import '../dashboard/dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordHidden = true;
  bool _isLoading = false;

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    final String email = _emailController.text.trim();
    final String password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      await CommonAlert.showInfo(
        context,
        title: 'Missing details',
        message: 'Enter both email and password to continue.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService.instance.login(email: email, password: password);

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const DashboardPage()),
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      await CommonAlert.showInfo(
        context,
        title: 'Login failed',
        message: error.message,
      );
    } catch (error) {
      if (!mounted) return;
      await CommonAlert.showInfo(
        context,
        title: 'Login failed',
        message: error.toString(),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.borderGrey),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AppLogo(size: 112),
                          const SizedBox(height: 24),
                          const Text(
                            'Welcome back',
                            style: TextStyle(
                              color: AppColors.textDark,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Sign in to continue',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textGrey,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 24),
                          AppTextField(
                            controller: _emailController,
                            hintText: 'Email',
                            icon: Icons.mail_outline,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 14),
                          AppTextField(
                            controller: _passwordController,
                            hintText: 'Password',
                            icon: Icons.key,
                            obscureText: _isPasswordHidden,
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(
                                  () => _isPasswordHidden = !_isPasswordHidden,
                                );
                              },
                              icon: Icon(
                                _isPasswordHidden
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppColors.textGrey,
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          PrimaryButton(
                            label: 'Login',
                            isLoading: _isLoading,
                            onPressed: _login,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            AppConstants.versionLabel,
                            style: TextStyle(
                              color: AppColors.textGrey,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
