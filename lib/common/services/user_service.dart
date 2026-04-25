import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_config.dart';
import '../constants/api_endpoints.dart';
import 'auth_service.dart';

class UserDetails {
  const UserDetails({
    required this.userId,
    required this.userName,
    required this.userTypeId,
    required this.regionId,
  });

  factory UserDetails.fromJson(Map<String, dynamic> json) {
    return UserDetails(
      userId: _parseInt(json['userID'] ?? json['userId'] ?? json['id']),
      userName: _string(
        json['userName'] ?? json['name'],
        fallback: 'mobile-app',
      ),
      userTypeId: _parseInt(json['userTypeID'] ?? json['userTypeId']),
      regionId: _parseInt(json['regionID'] ?? json['regionId']),
    );
  }

  final int userId;
  final String userName;
  final int userTypeId;
  final int regionId;

  static int _parseInt(Object? value) {
    if (value is int) return value;
    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  static String _string(Object? value, {String fallback = ''}) {
    final String text = (value ?? '').toString().trim();
    return text.isEmpty ? fallback : text;
  }
}

class UserService {
  UserService({http.Client? client}) : _client = client ?? http.Client();

  static final UserService instance = UserService();

  final http.Client _client;

  Future<UserDetails> fetchUserById(int userId) async {
    final Uri uri = ApiConfig.uri(ApiEndpoints.userById(userId));
    final Map<String, String> headers = await AuthService.instance
        .authenticatedJsonHeaders();

    print('[API] URL: $uri');
    print('[API] Payload: N/A');

    final http.Response response = await _client.get(uri, headers: headers);
    print('[API] Response: ${response.statusCode} ${response.body}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to load user details. Please try again.');
    }

    final Object decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      final Object? data = decoded['data'] ?? decoded['result'];
      if (data is Map<String, dynamic>) {
        return UserDetails.fromJson(data);
      }
      return UserDetails.fromJson(decoded);
    }

    throw Exception('Unexpected user detail response.');
  }
}
