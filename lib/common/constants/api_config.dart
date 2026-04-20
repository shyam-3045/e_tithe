import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  const ApiConfig._();

  static String get baseUrl {
    final String fromEnv = (dotenv.env['API_BASE_URL'] ?? '').trim();
    final String fallback = Platform.isAndroid
        ? 'http://10.0.2.2:5089'
        : 'http://localhost:5089';

    final String value = fromEnv.isEmpty ? fallback : fromEnv;

    // Convenience: if someone sets localhost on Android emulator, map it.
    if (Platform.isAndroid && value.contains('://localhost')) {
      return value.replaceFirst('://localhost', '://10.0.2.2');
    }

    return value;
  }

  static Uri uri(String path) {
    final String normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final String normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$normalizedBase$normalizedPath');
  }
}
