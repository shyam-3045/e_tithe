import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryPurple,
        primary: AppColors.primaryPurple,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
      ),
    );
  }
}
