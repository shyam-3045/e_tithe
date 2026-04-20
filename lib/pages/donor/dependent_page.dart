import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../common/constants/api_config.dart';
import '../../common/constants/api_endpoints.dart';
import '../../common/constants/app_colors.dart';
import '../../common/services/auth_service.dart';

class DependentPage extends StatefulWidget {
  const DependentPage({super.key, required this.donorName, this.donorId});

  final String donorName;
  final int? donorId;

  @override
  State<DependentPage> createState() => _DependentPageState();
}

class _DependentPageState extends State<DependentPage> {
  late Future<List<_DependentItem>> _dependentsFuture;

  @override
  void initState() {
    super.initState();
    _dependentsFuture = _fetchDependents();
  }

  Future<List<_DependentItem>> _fetchDependents() async {
    final int donorId = widget.donorId ?? 0;
    if (donorId <= 0) {
      return const <_DependentItem>[];
    }

    final Uri uri = ApiConfig.uri(ApiEndpoints.dependentByDonor(donorId));
    final Map<String, String> headers = await AuthService.instance
        .authenticatedJsonHeaders();

    print('[API] URL: $uri');
    print('[API] Payload: N/A');

    final http.Response response = await http.get(uri, headers: headers);

    print('[API] Response: ${response.statusCode} ${response.body}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to fetch dependents. Please try again.');
    }

    final Object decoded = jsonDecode(response.body);
    final List<dynamic> list = _extractList(decoded);

    return list
        .whereType<Map<String, dynamic>>()
        .map(_DependentItem.fromJson)
        .toList();
  }

  List<dynamic> _extractList(Object decoded) {
    if (decoded is List) {
      return decoded;
    }

    if (decoded is Map<String, dynamic>) {
      final Object? data =
          decoded['data'] ?? decoded['items'] ?? decoded['result'];
      if (data is List) {
        return data;
      }
    }

    return const <dynamic>[];
  }

  @override
  Widget build(BuildContext context) {
    final int donorId = widget.donorId ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Dependent')),
      body: SafeArea(
        child: donorId <= 0
            ? Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Dependent screen for: ${widget.donorName}\n\nDonor ID is missing, so dependent list cannot be loaded.',
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              )
            : FutureBuilder<List<_DependentItem>>(
                future: _dependentsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 46,
                              color: AppColors.textGrey,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              snapshot.error.toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textGrey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: () => setState(() {
                                _dependentsFuture = _fetchDependents();
                              }),
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final List<_DependentItem> items =
                      snapshot.data ?? const <_DependentItem>[];
                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        'No dependents found for ${widget.donorName}.',
                        style: const TextStyle(
                          color: AppColors.textGrey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final _DependentItem item = items[index];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x12000000),
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                            if (item.relation.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                item.relation,
                                style: const TextStyle(
                                  color: AppColors.textGrey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}

class _DependentItem {
  const _DependentItem({required this.name, required this.relation});

  factory _DependentItem.fromJson(Map<String, dynamic> json) {
    final String name =
        (json['relationName'] ?? json['dependentName'] ?? json['name'] ?? '')
            .toString()
            .trim();
    final String relation =
        (json['relationshipToDonor'] ?? json['relation'] ?? '')
            .toString()
            .trim();

    return _DependentItem(
      name: name.isEmpty ? 'Unknown dependent' : name,
      relation: relation,
    );
  }

  final String name;
  final String relation;
}
