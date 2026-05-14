import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_config.dart';
import '../constants/api_endpoints.dart';
import '../models/user_data.dart';

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
  static const String _userDataKey = 'user_data';

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

    print('[API] Login URL: $uri');
    print('[API] Payload: ${jsonEncode(loginPayload)}');

    final http.Response response = await _client.post(
      uri,
      headers: const <String, String>{
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
      },
      body: jsonEncode(loginPayload),
    );

    print('[API] Login Response: ${response.statusCode} ${response.body}');

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

    // Fetch and save user data after login
    print('[API] ======== FETCHING USER DATA AFTER LOGIN ========');
    print('[API] session.userTypeId: ${session.userTypeId}');
    print('[API] session.userId: ${session.userId}');

    if (session.userTypeId == null) {
      print('[API] ERROR: userTypeId is null in login response');
    }
    if (session.userId == null) {
      print('[API] ERROR: userId is null in login response');
    }

    if (session.userTypeId != null && session.userId != null) {
      try {
        final int userId = int.tryParse(session.userId!) ?? 0;
        print('[API] Attempting to fetch user data with userId: $userId');

        if (userId > 0) {
          final UserData userData = await fetchAndSaveUserData(
            userTypeId: session.userTypeId!,
            userId: userId,
          );
          print(
            '[API] ✅ User Data fetched and stored successfully: ${jsonEncode(userData.toJson())}',
          );
        } else {
          print('[API] ❌ userId is 0 or invalid');
        }
      } catch (e) {
        print('[API] ❌ Error fetching user data: $e');
        print('[API] Stack trace: ${StackTrace.current}');
        // Continue even if user data fetch fails
      }
    } else {
      print('[API] ❌ Cannot fetch user data: userTypeId or userId is null');
    }

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
    print('[AuthService] ======== CLEARING SESSION ========');
    print('[AuthService] Removing: $_sessionKey');
    print('[AuthService] Removing: $_tokenKey');
    print('[AuthService] Removing: $_userDataKey');

    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.remove(_sessionKey);
    await preferences.remove(_tokenKey);
    await preferences.remove(_userDataKey);

    print('[AuthService] ======== SESSION CLEARED ========');
    print('[AuthService] All user data and tokens removed from local storage');
  }

  Future<UserData?> currentUserData() async {
    print('[AuthService] ======== RETRIEVING STORED USER DATA ========');
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String? rawUserData = preferences.getString(_userDataKey);

    if (rawUserData == null) {
      print(
        '[AuthService] ❌ No user data found in local storage (_userDataKey = $_userDataKey)',
      );
      return null;
    }

    if (rawUserData.isEmpty) {
      print('[AuthService] ❌ User data is empty in local storage');
      return null;
    }

    print('[AuthService] ✅ Raw user data found: $rawUserData');

    try {
      final UserData userData = UserData.fromJson(
        jsonDecode(rawUserData) as Map<String, dynamic>,
      );
      print('[AuthService] ✅ User data parsed successfully');
      print('[AuthService] - userTypeID: ${userData.userTypeID}');
      print('[AuthService] - userTypeName: ${userData.userTypeName}');
      print('[AuthService] - userID: ${userData.userID}');
      print('[AuthService] - regionID: ${userData.regionID}');
      return userData;
    } catch (e) {
      print('[AuthService] ❌ Error parsing user data: $e');
      return null;
    }
  }

  Future<UserData> fetchAndSaveUserData({
    required int userTypeId,
    required int userId,
  }) async {
    print('[API] ======== FETCHING USER DATA ========');
    print('[API] userTypeId: $userTypeId, userId: $userId');

    final Uri uri = ApiConfig.uri(
      '/api/User/getuserbyusertypeanduserid?usertypeid=$userTypeId&userid=$userId',
    );
    final Map<String, String> headers = await authenticatedJsonHeaders();

    print('[API] Fetch User Data URL: $uri');
    print('[API] Headers: $headers');

    final http.Response response = await _client.get(uri, headers: headers);

    print('[API] Fetch User Data Response Status: ${response.statusCode}');
    print('[API] Fetch User Data Response Body: ${response.body}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException('Failed to fetch user data: ${response.statusCode}');
    }

    final Object decoded = jsonDecode(response.body);
    List items = <Object>[];

    if (decoded is List) {
      items = decoded;
    } else if (decoded is Map<String, dynamic>) {
      final Object? data = decoded['data'] ?? decoded['result'];
      if (data is List) {
        items = data;
      }
    }

    if (items.isEmpty) {
      throw const AuthException('No user data found in response');
    }

    final Map<String, dynamic> userData = items.first as Map<String, dynamic>;
    final UserData userDataObj = UserData.fromJson(userData);

    print('[API] ======== USER DATA PARSED ========');
    print('[API] userTypeID: ${userDataObj.userTypeID}');
    print('[API] userTypeName: ${userDataObj.userTypeName}');
    print('[API] userID: ${userDataObj.userID}');
    print('[API] userName: ${userDataObj.userName}');
    print('[API] regionID: ${userDataObj.regionID}');
    print('[API] regionName: ${userDataObj.regionName}');
    print('[API] ================================');

    await _saveUserData(userDataObj);
    return userDataObj;
  }

  Future<void> _saveUserData(UserData userData) async {
    print('[AuthService] ======== SAVING USER DATA ========');
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String jsonData = jsonEncode(userData.toJson());
    print('[AuthService] Saving user data with key: $_userDataKey');
    print('[AuthService] User data: $jsonData');

    await preferences.setString(_userDataKey, jsonData);
    print('[AuthService] ✅ User data saved successfully');
  }

  Future<void> _saveSession(AuthSession session) async {
    print('[AuthService] ======== SAVING SESSION ========');
    final SharedPreferences preferences = await SharedPreferences.getInstance();

    print('[AuthService] Saving token with key: $_tokenKey');
    print('[AuthService] Token: ${session.token.substring(0, 20)}...');
    await preferences.setString(_tokenKey, session.token);

    print('[AuthService] Saving session with key: $_sessionKey');
    await preferences.setString(_sessionKey, jsonEncode(session.toJson()));
    print('[AuthService] ✅ Session saved successfully');
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
