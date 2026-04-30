import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_config.dart';
import '../constants/api_endpoints.dart';
import 'auth_service.dart';

class CompanyInfo {
  const CompanyInfo({required this.companyId, required this.companyName});

  factory CompanyInfo.fromJson(Map<String, dynamic> json) {
    return CompanyInfo(
      companyId: _parseInt(
        json['companyID'] ?? json['companyId'] ?? json['id'] ?? json['value'],
      ),
      companyName: _string(
        json['companyName'] ?? json['name'] ?? json['label'] ?? json['text'],
        fallback: 'Unknown Company',
      ),
    );
  }

  final int companyId;
  final String companyName;

  static int _parseInt(Object? value) {
    if (value is int) return value;
    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  static String _string(Object? value, {String fallback = ''}) {
    final String text = (value ?? '').toString().trim();
    return text.isEmpty ? fallback : text;
  }
}

class CompanyService {
  CompanyService({http.Client? client}) : _client = client ?? http.Client();

  static final CompanyService instance = CompanyService();

  final http.Client _client;

  Future<List<CompanyInfo>> fetchCompanies() async {
    final Uri uri = ApiConfig.uri(ApiEndpoints.company);
    final Map<String, String> headers = await AuthService.instance
        .authenticatedJsonHeaders();

    print('[API] URL: $uri');
    print('[API] Payload: N/A');

    final http.Response response = await _client.get(uri, headers: headers);
    print('[API] Response: ${response.statusCode} ${response.body}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to load companies. Please try again.');
    }

    final Object decoded = jsonDecode(response.body);
    final List<dynamic> items = _extractList(decoded);

    return items
        .whereType<Map<String, dynamic>>()
        .map(CompanyInfo.fromJson)
        .where((item) => item.companyId > 0)
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
