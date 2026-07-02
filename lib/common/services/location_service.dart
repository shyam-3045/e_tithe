import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_config.dart';
import '../constants/api_endpoints.dart';
import '../services/auth_service.dart';

class StateOption {
  const StateOption({required this.stateId, required this.stateName});

  factory StateOption.fromJson(Map<String, dynamic> json) {
    return StateOption(
      stateId: json['stateID'] as int? ?? json['stateId'] as int? ?? json['id'] as int? ?? 0,
      stateName: json['stateName'] as String? ?? json['name'] as String? ?? '',
    );
  }

  final int stateId;
  final String stateName;
}

class DistrictOption {
  const DistrictOption({required this.districtId, required this.districtName});

  factory DistrictOption.fromJson(Map<String, dynamic> json) {
    return DistrictOption(
      districtId: json['districtID'] as int? ?? json['districtId'] as int? ?? json['id'] as int? ?? 0,
      districtName: json['districtName'] as String? ?? json['name'] as String? ?? '',
    );
  }

  final int districtId;
  final String districtName;
}

class CountryOption {
  const CountryOption({required this.countryId, required this.countryName});

  factory CountryOption.fromJson(Map<String, dynamic> json) {
    return CountryOption(
      countryId: json['countryID'] as int? ?? json['countryId'] as int? ?? json['id'] as int? ?? 0,
      countryName: json['countryName'] as String? ?? json['name'] as String? ?? '',
    );
  }

  final int countryId;
  final String countryName;
}

class LocationService {
  LocationService({http.Client? client}) : _client = client ?? http.Client();

  static LocationService instance = LocationService();

  final http.Client _client;

  Future<List<StateOption>> fetchStates() async {
    print('[LocationService] ======== FETCHING STATES ========');
    final Uri uri = ApiConfig.uri(ApiEndpoints.state);
    final Map<String, String> headers = await AuthService.instance.authenticatedJsonHeaders();

    final http.Response response = await _client.get(uri, headers: headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to fetch states: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    List items = [];
    if (decoded is List) {
      items = decoded;
    } else if (decoded is Map<String, dynamic>) {
      final data = decoded['data'] ?? decoded['result'];
      if (data is List) items = data;
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map((json) => StateOption.fromJson(json))
        .toList();
  }

  Future<List<DistrictOption>> fetchDistricts() async {
    print('[LocationService] ======== FETCHING DISTRICTS ========');
    final Uri uri = ApiConfig.uri(ApiEndpoints.district);
    final Map<String, String> headers = await AuthService.instance.authenticatedJsonHeaders();

    final http.Response response = await _client.get(uri, headers: headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to fetch districts: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    List items = [];
    if (decoded is List) {
      items = decoded;
    } else if (decoded is Map<String, dynamic>) {
      final data = decoded['data'] ?? decoded['result'];
      if (data is List) items = data;
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map((json) => DistrictOption.fromJson(json))
        .toList();
  }

  Future<List<CountryOption>> fetchCountries() async {
    print('[LocationService] ======== FETCHING COUNTRIES ========');
    final Uri uri = ApiConfig.uri(ApiEndpoints.country);
    final Map<String, String> headers = await AuthService.instance.authenticatedJsonHeaders();

    final http.Response response = await _client.get(uri, headers: headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to fetch countries: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    List items = [];
    if (decoded is List) {
      items = decoded;
    } else if (decoded is Map<String, dynamic>) {
      final data = decoded['data'] ?? decoded['result'];
      if (data is List) items = data;
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map((json) => CountryOption.fromJson(json))
        .toList();
  }
}
