import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_config.dart';
import '../constants/api_endpoints.dart';

class AuthSession {
  const AuthSession({
    required this.token,
    required this.refreshToken,
    required this.expiration,
    required this.userId,
    required this.userGuid,
    required this.userName,
    required this.email,
    required this.userTypeId,
    required this.isActive,
    required this.message,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final Object? userTypeId = json['userTypeId'];
    final Object? isActive = json['isActive'];

    return AuthSession(
      token: (json['token'] ?? '') as String,
      refreshToken: json['refreshToken'] as String?,
      expiration: _parseDateTime(json['expiration']),
      userId: json['userId'] as String?,
      userGuid: json['userGuid'] as String?,
      userName: json['userName'] as String?,
      email: json['email'] as String?,
      userTypeId: userTypeId is int
          ? userTypeId
          : int.tryParse(userTypeId?.toString() ?? ''),
      isActive: isActive is bool ? isActive : _parseBool(isActive),
      message: json['message'] as String?,
    );
  }

  final String token;
  final String? refreshToken;
  final DateTime? expiration;
  final String? userId;
  final String? userGuid;
  final String? userName;
  final String? email;
  final int? userTypeId;
  final bool? isActive;
  final String? message;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'token': token,
      'refreshToken': refreshToken,
      'expiration': expiration?.toUtc().toIso8601String(),
      'userId': userId,
      'userGuid': userGuid,
      'userName': userName,
      'email': email,
      'userTypeId': userTypeId,
      'isActive': isActive,
      'message': message,
    };
  }

  static DateTime? _parseDateTime(Object? value) {
    final String text = value?.toString().trim() ?? '';
    if (text.isEmpty) return null;
    return DateTime.tryParse(text);
  }

  static bool? _parseBool(Object? value) {
    final String text = value?.toString().trim().toLowerCase() ?? '';
    if (text.isEmpty) return null;
    if (text == 'true') return true;
    if (text == 'false') return false;
    return null;
  }
}

class AuthService {
  AuthService({http.Client? client}) : _client = client ?? http.Client();

  static AuthService instance = AuthService();

  static const String _sessionKey = 'auth_session';
  static const String _tokenKey = 'auth_token';

  final http.Client _client;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final Uri uri = ApiConfig.uri(ApiEndpoints.login);
    final Map<String, String> loginPayload = <String, String>{
      'email': email.trim(),
      'password': password,
    };

    print('[API] URL: $uri');
    print('[API] Payload: ${jsonEncode(loginPayload)}');

    final http.Response response = await _client.post(
      uri,
      headers: const <String, String>{
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
      },
      body: jsonEncode(loginPayload),
    );

    print('[API] Response: ${response.statusCode} ${response.body}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(
        _extractMessage(response.body) ??
            'Invalid email or password. Please try again.',
      );
    }

    final Map<String, dynamic> data = _decodeJsonObject(response.body);
    final AuthSession session = AuthSession.fromJson(data);

    if (session.token.trim().isEmpty) {
      throw const AuthException('Login response did not include a token.');
    }

    await _saveSession(session);
    return session;
  }

  Future<Map<String, String>> jsonHeaders() async {
    final Map<String, String> headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
    };

    final String? savedToken = await token;
    if (savedToken != null && savedToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $savedToken';
    }

    return headers;
  }

  Future<Map<String, String>> authenticatedJsonHeaders() async {
    final String? savedToken = await token;
    if (savedToken == null || savedToken.isEmpty) {
      throw const AuthException('No saved token found. Please login again.');
    }

    return <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
      'Authorization': 'Bearer $savedToken',
    };
  }

  Future<String?> get token async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getString(_tokenKey);
  }

  Future<AuthSession?> currentSession() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String? rawSession = preferences.getString(_sessionKey);
    if (rawSession == null || rawSession.isEmpty) {
      return null;
    }

    try {
      return AuthSession.fromJson(
        jsonDecode(rawSession) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> clearSession() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.remove(_sessionKey);
    await preferences.remove(_tokenKey);
  }

  Future<void> _saveSession(AuthSession session) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(_tokenKey, session.token);
    await preferences.setString(_sessionKey, jsonEncode(session.toJson()));
  }

  Map<String, dynamic> _decodeJsonObject(String body) {
    final String trimmedBody = body.trim();
    if (trimmedBody.isEmpty) {
      throw const AuthException('Server returned an empty response.');
    }

    final Object decoded = jsonDecode(trimmedBody);
    if (decoded is! Map<String, dynamic>) {
      throw const AuthException('Unexpected login response format.');
    }

    return decoded;
  }

  String? _extractMessage(String body) {
    final String trimmedBody = body.trim();
    if (trimmedBody.isEmpty) {
      return null;
    }

    try {
      final Object decoded = jsonDecode(trimmedBody);
      if (decoded is Map<String, dynamic>) {
        final Object? message = decoded['message'] ?? decoded['error'];
        if (message != null && message.toString().trim().isNotEmpty) {
          return message.toString();
        }
      }
    } catch (_) {
      return trimmedBody;
    }

    return null;
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
