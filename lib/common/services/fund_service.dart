import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_config.dart';
import '../constants/api_endpoints.dart';
import 'auth_service.dart';

class FundInfo {
  const FundInfo({required this.fundId, required this.fundName});

  factory FundInfo.fromJson(Map<String, dynamic> json) {
    return FundInfo(
      fundId: _parseInt(json['fundID'] ?? json['fundId'] ?? json['id']),
      fundName: _string(
        json['fundName'] ?? json['name'] ?? json['label'] ?? json['text'],
        fallback: 'Unknown Fund',
      ),
    );
  }

  final int fundId;
  final String fundName;

  static int _parseInt(Object? value) {
    if (value is int) return value;
    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  static String _string(Object? value, {String fallback = ''}) {
    final String text = (value ?? '').toString().trim();
    return text.isEmpty ? fallback : text;
  }
}

class FundService {
  FundService({http.Client? client}) : _client = client ?? http.Client();

  static final FundService instance = FundService();

  final http.Client _client;

  Future<List<FundInfo>> fetchFunds() async {
    final Uri uri = ApiConfig.uri(ApiEndpoints.fund);
    final Map<String, String> headers = await AuthService.instance
        .authenticatedJsonHeaders();

    print('[API] URL: $uri');
    print('[API] Payload: N/A');

    final http.Response response = await _client.get(uri, headers: headers);
    print('[API] Response: ${response.statusCode} ${response.body}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to load funds. Please try again.');
    }

    final Object decoded = jsonDecode(response.body);
    final List<dynamic> items = _extractList(decoded);

    return items
        .whereType<Map<String, dynamic>>()
        .map(FundInfo.fromJson)
        .where((item) => item.fundId > 0 || item.fundName.isNotEmpty)
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
