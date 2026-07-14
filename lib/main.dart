import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app/e_tithe_app.dart';
import 'common/constants/app_colors.dart';
import 'common/constants/app_constants.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        // Bypass certificate validation for local development
        return host == 'localhost' ||
            host == '127.0.0.1' ||
            host == '10.0.2.2' ||
            host.startsWith('192.168.');
      };
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();

  try {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    AppConstants.versionLabel = 'V.${packageInfo.version}';
  } catch (_) {
    // Fallback if PackageInfo fails (e.g. during testing)
  }

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Allow app to run even if .env is missing (falls back in ApiConfig).
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: AppColors.background,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  runApp(const ETitheApp());
}

