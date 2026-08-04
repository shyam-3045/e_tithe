import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_config.dart';
import '../constants/api_endpoints.dart';
import 'auth_service.dart';

class RegionOption {
  const RegionOption({required this.regionId, required this.regionName});

  factory RegionOption.fromJson(Map<String, dynamic> json) {
    return RegionOption(
      regionId: _parseInt(json['regionID'] ?? json['regionId'] ?? json['id']),
      regionName: _string(json['regionName'] ?? json['name'] ?? json['region']),
    );
  }

  final int regionId;
  final String regionName;

  static int _parseInt(Object? value) {
    if (value is int) return value;
    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  static String _string(Object? value, {String fallback = ''}) {
    final String text = (value ?? '').toString().trim();
    return text.isEmpty ? fallback : text;
  }
}

class RegionService {
  RegionService({http.Client? client}) : _client = client ?? http.Client();

  static final RegionService instance = RegionService();

  final http.Client _client;

  Future<List<RegionOption>> fetchRegions() async {
    final Uri uri = ApiConfig.uri(ApiEndpoints.region);
    final Map<String, String> headers = await AuthService.instance
        .authenticatedJsonHeaders();

    print('[API] URL: $uri');
    print('[API] Payload: N/A');

    final http.Response response = await _client.get(uri, headers: headers);
    print('[API] Response: ${response.statusCode} ${response.body}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to load regions. Please try again.');
    }

    final Object decoded = jsonDecode(response.body);
    final List<dynamic> items = _extractList(decoded);

    return items
        .whereType<Map<String, dynamic>>()
        .map(RegionOption.fromJson)
        .where((region) => region.regionId > 0)
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

  Future<String> checkReceiptDateValidation({
    required DateTime receiptDate,
    required int regionId,
  }) async {
    final Uri uri = ApiConfig.uri(ApiEndpoints.checkReceiptDateValidation)
        .replace(
      queryParameters: <String, String>{
        'receiptDate': _formatDate(receiptDate),
        'regionId': regionId.toString(),
      },
    );
    final Map<String, String> headers = await AuthService.instance
        .authenticatedJsonHeaders();

    print('[API] URL: $uri');

    final http.Response response = await _client.get(uri, headers: headers);
    print('[API] Response: ${response.statusCode} ${response.body}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to validate receipt date. Please try again.');
    }

    final Object decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return (decoded['message'] ?? '').toString().trim();
    }
    return decoded.toString().trim();
  }

  Future<String> fetchUpiIdByRegionName(String regionName) async {
    final Uri uri = ApiConfig.uri(
      '${ApiEndpoints.upiIdByRegionName}/${Uri.encodeComponent(regionName)}',
    );
    final Map<String, String> headers = await AuthService.instance
        .authenticatedJsonHeaders();

    print('[API] URL: $uri');

    final http.Response response = await _client.get(uri, headers: headers);
    print('[API] Response: ${response.statusCode} ${response.body}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to load UPI ID for this region.');
    }

    final Object decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return (decoded['upi'] ?? '').toString().trim();
    }
    return decoded.toString().trim();
  }

  String _formatDate(DateTime date) {
    final String year = date.year.toString().padLeft(4, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
