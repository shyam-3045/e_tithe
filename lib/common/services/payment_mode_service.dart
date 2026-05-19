import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_config.dart';
import '../constants/api_endpoints.dart';
import 'auth_service.dart';

class PaymentModeInfo {
  const PaymentModeInfo({required this.paymentModeId, required this.name});

  factory PaymentModeInfo.fromJson(Map<String, dynamic> json) {
    return PaymentModeInfo(
      paymentModeId: _parseInt(
        json['paymentModeID'] ??
            json['paymentModeId'] ??
            json['id'] ??
            json['value'],
      ),
      name: _string(
        json['paymentModeName'] ??
            json['paymentMode'] ??
            json['name'] ??
            json['label'] ??
            json['text'],
        fallback: 'UNKNOWN',
      ),
    );
  }

  final int paymentModeId;
  final String name;

  static int _parseInt(Object? value) {
    if (value is int) return value;
    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  static String _string(Object? value, {String fallback = ''}) {
    final String text = (value ?? '').toString().trim();
    return text.isEmpty ? fallback : text;
  }
}

class PaymentModeService {
  PaymentModeService({http.Client? client}) : _client = client ?? http.Client();

  static final PaymentModeService instance = PaymentModeService();

  final http.Client _client;

  Future<List<PaymentModeInfo>> fetchPaymentModes() async {
    final Uri uri = ApiConfig.uri(ApiEndpoints.paymentMode);
    final Map<String, String> headers = await AuthService.instance
        .authenticatedJsonHeaders();

    print('[API] URL: $uri');
    print('[API] Payload: N/A');

    final http.Response response = await _client.get(uri, headers: headers);
    print('[API] Response: ${response.statusCode} ${response.body}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to load payment modes. Please try again.');
    }

    final Object decoded = jsonDecode(response.body);
    final List<dynamic> items = _extractList(decoded);

    return items
        .whereType<Map<String, dynamic>>()
        .map(PaymentModeInfo.fromJson)
        .where((item) => item.paymentModeId > 0 || item.name.isNotEmpty)
        .toList();
  }

  List<dynamic> _extractList(Object decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map<String, dynamic>) {
      final Object? data =
          decoded['data'] ?? decoded['items'] ?? decoded['result'];
      if (data is List) return data;
    }
    return const <dynamic>[];
  }
}
