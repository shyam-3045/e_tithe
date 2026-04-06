import 'package:flutter/material.dart';

import '../common/theme/app_theme.dart';
import '../pages/splash/splash_page.dart';

class ETitheApp extends StatelessWidget {
  const ETitheApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'e-Tithe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashPage(),
    );
  }
}
