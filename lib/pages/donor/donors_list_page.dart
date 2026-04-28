import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../common/constants/api_config.dart';
import '../../common/constants/api_endpoints.dart';
import '../../common/constants/app_colors.dart';
import '../../common/services/auth_service.dart';
import '../../common/widgets/common_alert.dart';
import 'update_profile_page.dart';
import 'my_receipts_page.dart';
import 'dependent_page.dart';
import 'new_receipt_page.dart';

class DonorsListPage extends StatefulWidget {
  const DonorsListPage({super.key});

  @override
  State<DonorsListPage> createState() => _DonorsListPageState();
}

class _DonorsListPageState extends State<DonorsListPage> {
  late Future<List<_DonorListItem>> _donorsFuture;

  @override
  void initState() {
    super.initState();
    _donorsFuture = _fetchDonors();
  }

  Future<List<_DonorListItem>> _fetchDonors() async {
    try {
      final Uri uri = ApiConfig.uri(ApiEndpoints.donor);
      final Map<String, String> headers = await AuthService.instance
          .authenticatedJsonHeaders();

      print('[API] URL: $uri');

      final http.Response response = await http.get(uri, headers: headers);

      print('[API] Response: ${response.statusCode}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to fetch donors. Please try again.');
      }

      final Object decoded = jsonDecode(response.body);
      final List<dynamic> donorsList = _extractList(decoded);

      final List<_DonorListItem> donors = donorsList
          .cast<Map<String, dynamic>>()
          .map((data) => _DonorListItem.fromJson(data))
          .toList();

      return donors;
    } on AuthException {
      rethrow;
    } catch (error) {
      throw Exception(error.toString());
    }
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

  void _refreshDonors() {
    setState(() {
      _donorsFuture = _fetchDonors();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Donors'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refreshDonors,
            icon: const Icon(Icons.refresh_rounded, size: 20),
          ),
          IconButton(
            tooltip: 'Search',
            onPressed: () => CommonAlert.showInfo(
              context,
              title: 'Search',
              message: 'Search UI can be connected next.',
            ),
            icon: const Icon(Icons.search_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<_DonorListItem>>(
          future: _donorsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: AppColors.textGrey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _refreshDonors,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              );
            }

            final List<_DonorListItem> donors = snapshot.data ?? [];
            if (donors.isEmpty) {
              return const Center(child: Text('No donors found'));
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: donors.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final donor = donors[index];
                return _DonorCard(
                  donor: donor,
                  onAddReceipt: () => _handleMenuSelection(
                    context,
                    donor: donor,
                    action: _DonorMenuAction.newReceipt,
                  ),
                  onMenuSelected: (action) => _handleMenuSelection(
                    context,
                    donor: donor,
                    action: action,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _handleMenuSelection(
    BuildContext context, {
    required _DonorListItem donor,
    required _DonorMenuAction action,
  }) {
    Widget page;

    switch (action) {
      case _DonorMenuAction.updateProfile:
        page = UpdateProfilePage(donorName: donor.name, donorId: donor.donorId);
      case _DonorMenuAction.myReceipts:
        page = MyReceiptsPage(donorName: donor.name);
      case _DonorMenuAction.dependent:
        page = DependentPage(donorName: donor.name, donorId: donor.donorId);
      case _DonorMenuAction.newReceipt:
        page = NewReceiptPage(donorName: donor.name, donorId: donor.donorId);
    }

    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}

enum _DonorMenuAction { updateProfile, myReceipts, dependent, newReceipt }

class _DonorListItem {
  const _DonorListItem({
    required this.donorId,
    required this.name,
    required this.membership,
    required this.addressLines,
    required this.email,
    required this.phone,
    this.dependents = const <String>[],
    this.avatarUrl,
    this.photoBase64,
  });

  factory _DonorListItem.fromJson(Map<String, dynamic> json) {
    final Object? photoRaw =
        json['photo'] ?? json['Photo'] ?? json['photoUrl'] ?? json['photoPath'];
    final String photoString = photoRaw?.toString() ?? '';

    String? avatarUrl;
    String? photoBase64;

    if (photoString.isNotEmpty) {
      if (_isBase64(photoString)) {
        photoBase64 = photoString;
      } else {
        avatarUrl = _photoUrl(photoString);
      }
    }

    return _DonorListItem(
      donorId: _parseInt(
        json['donorId'] ?? json['donorID'] ?? json['id'] ?? json['ID'],
      ),
      name:
          json['donorName']?.toString() ??
          json['name']?.toString() ??
          'Unknown',
      membership: json['membership']?.toString() ?? 'Member',
      addressLines: _parseAddressLines(json),
      email: json['email']?.toString() ?? '',
      phone: json['mobileNo']?.toString() ?? json['phone']?.toString() ?? '',
      dependents: _parseDependents(json),
      avatarUrl: avatarUrl,
      photoBase64: photoBase64,
    );
  }

  _DonorListItem copyWith({
    int? donorId,
    String? name,
    String? membership,
    List<String>? addressLines,
    String? email,
    String? phone,
    List<String>? dependents,
    String? avatarUrl,
    String? photoBase64,
  }) {
    return _DonorListItem(
      donorId: donorId ?? this.donorId,
      name: name ?? this.name,
      membership: membership ?? this.membership,
      addressLines: addressLines ?? this.addressLines,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dependents: dependents ?? this.dependents,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      photoBase64: photoBase64 ?? this.photoBase64,
    );
  }

  static int _parseInt(Object? value) {
    if (value is int) return value;
    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  static List<String> _parseAddressLines(Map<String, dynamic> json) {
    final List<String> lines = [];
    if (json['city'] != null && json['city'].toString().isNotEmpty) {
      lines.add(json['city'].toString());
    }
    if (json['area'] != null && json['area'].toString().isNotEmpty) {
      lines.add(json['area'].toString());
    }
    if (json['pincode'] != null && json['pincode'].toString().isNotEmpty) {
      final String addressLine = '${json['state'] ?? ""} - ${json['pincode']}'
          .replaceAll(RegExp(r'^\s*-\s*'), '');
      lines.add(addressLine);
    }
    return lines.isEmpty ? ['Address not provided'] : lines;
  }

  static List<String> _parseDependents(Map<String, dynamic> json) {
    final Object? value =
        json['dependents'] ?? json['dependentList'] ?? json['dependentDetails'];

    if (value is! List) {
      return const <String>[];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map((entry) {
          final String name =
              (entry['relationName'] ??
                      entry['dependentName'] ??
                      entry['name'] ??
                      '')
                  .toString()
                  .trim();
          final String relation =
              (entry['relationshipToDonor'] ?? entry['relation'] ?? '')
                  .toString()
                  .trim();

          if (name.isEmpty) {
            return '';
          }

          return relation.isEmpty ? name : '$name ($relation)';
        })
        .where((entry) => entry.isNotEmpty)
        .toList();
  }

  static bool _isBase64(String value) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      return false;
    }
    if (trimmed.startsWith('data:image')) {
      return true;
    }
    if (trimmed.length < 50) {
      return false;
    }
    try {
      base64Decode(trimmed);
      return true;
    } catch (_) {
      return false;
    }
  }

  static String? _photoUrl(Object? value) {
    final String raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) {
      return null;
    }

    final Uri? uri = Uri.tryParse(raw);
    if (uri != null && uri.hasScheme) {
      return raw;
    }

    final String normalizedPath = raw.startsWith('/') ? raw : '/$raw';
    return '${ApiConfig.baseUrl}$normalizedPath';
  }

  final int donorId;
  final String name;
  final String membership;
  final List<String> addressLines;
  final String email;
  final String phone;
  final List<String> dependents;
  final String? avatarUrl;
  final String? photoBase64;
}

class _DonorCard extends StatelessWidget {
  const _DonorCard({
    required this.donor,
    required this.onMenuSelected,
    required this.onAddReceipt,
  });

  final _DonorListItem donor;
  final ValueChanged<_DonorMenuAction> onMenuSelected;
  final VoidCallback onAddReceipt;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
              color: AppColors.statusBarPink,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      donor.name.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _QuickAddReceiptButton(onTap: onAddReceipt),
                  const SizedBox(width: 8),
                  _MenuButton(onSelected: onMenuSelected),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Avatar(
                        name: donor.name,
                        avatarUrl: donor.avatarUrl,
                        photoBase64: donor.photoBase64,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              donor.membership,
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ...donor.addressLines.map(
                              (line) => Text(
                                line,
                                style: const TextStyle(
                                  color: AppColors.textGrey,
                                  fontSize: 15,
                                  height: 1.25,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (donor.dependents.isEmpty)
                              const Text(
                                'Dependents: None',
                                style: TextStyle(
                                  color: AppColors.textGrey,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            else ...[
                              Text(
                                'Dependents (${donor.dependents.length}):',
                                style: const TextStyle(
                                  color: AppColors.textGrey,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: donor.dependents
                                    .map(
                                      (name) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.softPurple,
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          name,
                                          style: const TextStyle(
                                            color: AppColors.primaryPurple,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 2,
                    width: double.infinity,
                    color: AppColors.statusBarPink.withOpacity(0.7),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.email_outlined,
                        size: 18,
                        color: AppColors.textGrey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          donor.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textGrey,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Icon(
                        Icons.call_rounded,
                        size: 18,
                        color: AppColors.statusBarPink,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        donor.phone,
                        style: const TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAddReceiptButton extends StatelessWidget {
  const _QuickAddReceiptButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Add Receipt',
      child: Material(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: const SizedBox(
            width: 34,
            height: 34,
            child: Icon(
              Icons.receipt_long_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.avatarUrl, this.photoBase64});

  final String name;
  final String? avatarUrl;
  final String? photoBase64;

  String get _initials {
    final List<String> parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return '?';
    }

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    final String first = parts.first.substring(0, 1).toUpperCase();
    final String second = parts.last.substring(0, 1).toUpperCase();
    return '$first$second';
  }

  ImageProvider? _getImageProvider() {
    if (photoBase64 != null && photoBase64!.isNotEmpty) {
      try {
        String base64Data = photoBase64!;
        if (base64Data.startsWith('data:image')) {
          base64Data = base64Data.split(',').last;
        }
        final Uint8List imageBytes = base64Decode(base64Data);
        return MemoryImage(imageBytes);
      } catch (_) {
        return null;
      }
    }

    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return NetworkImage(avatarUrl!);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 38,
      backgroundColor: AppColors.lavender,
      foregroundImage: _getImageProvider(),
      child: Text(
        _initials,
        style: const TextStyle(
          color: AppColors.primaryPurple,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.onSelected});

  final ValueChanged<_DonorMenuAction> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.primaryPurple,
        borderRadius: BorderRadius.circular(12),
      ),
      child: PopupMenuButton<_DonorMenuAction>(
        tooltip: 'Options',
        padding: EdgeInsets.zero,
        onSelected: onSelected,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: _DonorMenuAction.updateProfile,
            child: Text('Update Profile'),
          ),
          PopupMenuItem(
            value: _DonorMenuAction.myReceipts,
            child: Text('My Receipts'),
          ),
          PopupMenuItem(
            value: _DonorMenuAction.dependent,
            child: Text('Dependent'),
          ),
          PopupMenuItem(
            value: _DonorMenuAction.newReceipt,
            child: Text('Add Receipt'),
          ),
        ],
        child: const Center(
          child: Icon(Icons.more_vert_rounded, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
