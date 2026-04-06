import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/e_tithe_app.dart';
import 'common/constants/app_colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: AppColors.statusBarPink,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  runApp(const ETitheApp());
}

