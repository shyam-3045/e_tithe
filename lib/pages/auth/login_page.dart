import 'package:flutter/material.dart';

import '../../common/constants/app_colors.dart';
import '../../common/constants/app_constants.dart';
import '../../common/widgets/app_logo.dart';
import '../../common/widgets/app_text_field.dart';
import '../../common/widgets/common_alert.dart';
import '../../common/widgets/primary_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    this.showEntryAlert = false,
    super.key,
  });

  final bool showEntryAlert;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordHidden = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.showEntryAlert) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          CommonAlert.showInfo(
            context,
            title: 'Welcome',
            message: 'This is a demo login. You can enter any email and password.',
          );
        }
      });
    }
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    await Future<void>.delayed(AppConstants.loginDuration);

    if (!mounted) return;
    setState(() => _isLoading = false);

    await CommonAlert.showInfo(
      context,
      title: 'Login Successful',
      message: 'Any email and password are allowed for now.',
    );
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 46),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: constraints.maxHeight * 0.31),
                      const AppLogo(size: 112),
                      SizedBox(height: constraints.maxHeight * 0.06),
                      AppTextField(
                        controller: _emailController,
                        hintText: 'Email',
                        icon: Icons.mail_outline,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 40),
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
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: AppColors.textGrey,
                            size: 34,
                          ),
                        ),
                      ),
                      const SizedBox(height: 62),
                      PrimaryButton(
                        label: 'Login',
                        isLoading: _isLoading,
                        onPressed: _login,
                      ),
                      const SizedBox(height: 48),
                      const Text(
                        AppConstants.versionLabel,
                        style: TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 25,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
