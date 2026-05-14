import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_config.dart';
import '../services/auth_service.dart';

class AgentAreaOption {
  const AgentAreaOption({required this.areaId, required this.areaName});

  factory AgentAreaOption.fromJson(Map<String, dynamic> json) {
    return AgentAreaOption(
      areaId: json['areaID'] as int? ?? json['areaId'] as int? ?? 0,
      areaName: json['areaName'] as String? ?? json['name'] as String? ?? '',
    );
  }

  final int areaId;
  final String areaName;
}

class AgentAreaService {
  AgentAreaService({http.Client? client}) : _client = client ?? http.Client();

  static AgentAreaService instance = AgentAreaService();

  final http.Client _client;

  Future<List<AgentAreaOption>> fetchAreasByUserTypeAndUserId({
    required int userTypeId,
    required int userId,
  }) async {
    print('[AgentAreaService] ======== FETCHING AREAS ========');
    print('[AgentAreaService] userTypeId: $userTypeId, userId: $userId');

    final Uri uri = ApiConfig.uri(
      '/api/AgentArea/getareasnamebyusertypeanduserid?usertypeid=$userTypeId&userid=$userId',
    );
    final Map<String, String> headers = await AuthService.instance
        .authenticatedJsonHeaders();

    print('[AgentAreaService] Fetch Areas URL: $uri');

    final http.Response response = await _client.get(uri, headers: headers);

    print(
      '[AgentAreaService] Fetch Areas Response Status: ${response.statusCode}',
    );
    print('[AgentAreaService] Fetch Areas Response Body: ${response.body}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to fetch areas: ${response.statusCode}');
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

    final List<AgentAreaOption>
    areas = items.whereType<Map<String, dynamic>>().map((json) {
      final area = AgentAreaOption.fromJson(json);
      print(
        '[AgentAreaService] Parsed: areaId=${area.areaId}, areaName=${area.areaName}',
      );
      return area;
    }).toList();

    print('[AgentAreaService] Total areas: ${areas.length}');
    return areas;
  }
}
