import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_config.dart';
import '../constants/api_endpoints.dart';
import 'auth_service.dart';

class AreaOption {
  const AreaOption({required this.areaId, required this.areaName});

  factory AreaOption.fromJson(Map<String, dynamic> json) {
    return AreaOption(
      areaId: _parseInt(json['areaID'] ?? json['areaId'] ?? json['id']),
      areaName: _string(
        json['areaName'] ?? json['name'] ?? json['label'] ?? json['text'],
      ),
    );
  }

  final int areaId;
  final String areaName;

  static int _parseInt(Object? value) {
    if (value is int) return value;
    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  static String _string(Object? value, {String fallback = ''}) {
    final String text = (value ?? '').toString().trim();
    return text.isEmpty ? fallback : text;
  }
}

class AreaService {
  AreaService({http.Client? client}) : _client = client ?? http.Client();

  static final AreaService instance = AreaService();

  final http.Client _client;

  Future<List<AreaOption>> fetchAreas() async {
    final Uri uri = ApiConfig.uri(ApiEndpoints.area);
    final Map<String, String> headers = await AuthService.instance
        .authenticatedJsonHeaders();

    print('[API] URL: $uri');
    print('[API] Payload: N/A');

    final http.Response response = await _client.get(uri, headers: headers);
    print('[API] Response: ${response.statusCode} ${response.body}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to load areas. Please try again.');
    }

    final Object decoded = jsonDecode(response.body);
    final List<dynamic> items = _extractList(decoded);

    return items
        .whereType<Map<String, dynamic>>()
        .map(AreaOption.fromJson)
        .where((item) => item.areaId > 0 || item.areaName.isNotEmpty)
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
