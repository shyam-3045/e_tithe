import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_config.dart';
import '../constants/api_endpoints.dart';
import 'auth_service.dart';

class ReceiptRecord {
  const ReceiptRecord({
    required this.receiptId,
    required this.receiptNo,
    required this.date,
    required this.donorDisplayName,
    required this.addressLines,
    required this.pincode,
    required this.monthLabel,
    required this.paymentMode,
    required this.amount,
    required this.fundType,
    required this.isCancelled,
    this.notes = '',
  });

  factory ReceiptRecord.fromJson(Map<String, dynamic> json) {
    final DateTime date = _parseDate(
      json['date'] ??
          json['receiptDate'] ??
          json['createdAt'] ??
          json['createdOn'],
    );

    return ReceiptRecord(
      receiptId: _parseInt(
        json['receiptId'] ?? json['receiptID'] ?? json['id'],
      ),
      receiptNo: _string(
        json['receiptNo'] ??
            json['receiptNumber'] ??
            json['receiptNoId'] ??
            json['receiptCode'],
        fallback: 'N/A',
      ),
      date: date,
      donorDisplayName: _string(
        json['donorDisplayName'] ?? json['donorName'] ?? json['name'],
        fallback: 'Unknown Donor',
      ),
      addressLines: _parseAddressLines(json),
      pincode: _string(json['pincode'] ?? json['pinCode'] ?? json['zipcode']),
      monthLabel: _string(
        json['monthLabel'] ?? json['month'] ?? _monthLabel(date),
      ),
      paymentMode: _string(
        json['paymentMode'] ??
            json['mode'] ??
            json['paymentType'] ??
            json['payMode'],
        fallback: 'BANK',
      ),
      amount: _parseDouble(
        json['amount'] ?? json['receiptAmount'] ?? json['totalAmount'],
      ),
      fundType: _string(
        json['fundType'] ?? json['particulars'] ?? json['purpose'],
        fallback: 'General Donation',
      ),
      isCancelled:
          _parseBool(
            json['isCancelled'] ?? json['cancelled'] ?? json['isActive'],
          ) ??
          false,
      notes: _string(
        json['notes'] ?? json['note'] ?? json['remarks'] ?? json['message'],
      ),
    );
  }

  final int receiptId;
  final String receiptNo;
  final DateTime date;
  final String donorDisplayName;
  final List<String> addressLines;
  final String pincode;
  final String monthLabel;
  final String paymentMode;
  final double amount;
  final String fundType;
  final bool isCancelled;
  final String notes;

  static int _parseInt(Object? value) {
    if (value is int) return value;
    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  static double _parseDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '').toString()) ?? 0;
  }

  static DateTime _parseDate(Object? value) {
    final String text = (value ?? '').toString().trim();
    final DateTime? parsed = DateTime.tryParse(text);
    return parsed ?? DateTime.now();
  }

  static bool? _parseBool(Object? value) {
    final String text = (value ?? '').toString().trim().toLowerCase();
    if (text.isEmpty) return null;
    if (text == 'true' || text == '1' || text == 'yes') return true;
    if (text == 'false' || text == '0' || text == 'no') return false;
    return null;
  }

  static String _string(Object? value, {String fallback = ''}) {
    final String text = (value ?? '').toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static List<String> _parseAddressLines(Map<String, dynamic> json) {
    final Object? raw =
        json['addressLines'] ?? json['address'] ?? json['fullAddress'];
    if (raw is List) {
      final List<String> lines = raw
          .whereType<String>()
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      if (lines.isNotEmpty) return lines;
    } else if (raw is String && raw.trim().isNotEmpty) {
      return raw
          .split(RegExp(r'\r?\n|,'))
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
    }

    final List<String> lines = [];
    for (final String key in [
      'addressLine1',
      'addressLine2',
      'street',
      'area',
      'city',
      'district',
    ]) {
      final String value = _string(json[key]);
      if (value.isNotEmpty) lines.add(value);
    }
    if (lines.isEmpty) {
      lines.add('Address not provided');
    }
    return lines;
  }

  static String _monthLabel(DateTime date) {
    const List<String> months = <String>[
      'JANUARY',
      'FEBRUARY',
      'MARCH',
      'APRIL',
      'MAY',
      'JUNE',
      'JULY',
      'AUGUST',
      'SEPTEMBER',
      'OCTOBER',
      'NOVEMBER',
      'DECEMBER',
    ];

    final int index = (date.month - 1).clamp(0, months.length - 1);
    return '${months[index]}-${date.year}';
  }
}

class ReceiptService {
  ReceiptService({http.Client? client}) : _client = client ?? http.Client();

  static final ReceiptService instance = ReceiptService();

  final http.Client _client;

  Future<Map<String, dynamic>> createReceipt({
    required Map<String, dynamic> payload,
  }) async {
    final Uri uri = ApiConfig.uri(ApiEndpoints.receipt);
    final Map<String, String> headers = await AuthService.instance
        .authenticatedJsonHeaders();

    print('[API] URL: $uri');
    print('[API] Payload: ${jsonEncode(payload)}');

    final http.Response response = await _client.post(
      uri,
      headers: headers,
      body: jsonEncode(payload),
    );

    print('[API] Response: ${response.statusCode} ${response.body}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _extractErrorMessage(response.body) ??
            'Failed to add receipt. Please try again.',
      );
    }

    final String body = response.body.trim();
    if (body.isEmpty) {
      return <String, dynamic>{};
    }

    final Object decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return <String, dynamic>{'data': decoded};
  }

  Future<List<ReceiptRecord>> fetchReceipts() async {
    final Uri uri = ApiConfig.uri(ApiEndpoints.receipt);
    final Map<String, String> headers = await AuthService.instance
        .authenticatedJsonHeaders();

    print('[API] URL: $uri');
    print('[API] Payload: N/A');

    final http.Response response = await _client.get(uri, headers: headers);
    print('[API] Response: ${response.statusCode} ${response.body}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to load receipts. Please try again.');
    }

    final Object decoded = jsonDecode(response.body);
    final List<dynamic> items = _extractList(decoded);

    return items
        .whereType<Map<String, dynamic>>()
        .map(ReceiptRecord.fromJson)
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

  String? _extractErrorMessage(String body) {
    final String trimmed = body.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    try {
      final Object decoded = jsonDecode(trimmed);
      if (decoded is! Map<String, dynamic>) {
        return trimmed;
      }

      final Object? errorsObj = decoded['errors'];
      if (errorsObj is Map<String, dynamic>) {
        final List<String> messages = <String>[];
        errorsObj.forEach((key, value) {
          if (value is List && value.isNotEmpty) {
            messages.add('$key: ${value.first}');
          } else if (value != null) {
            messages.add('$key: $value');
          }
        });
        if (messages.isNotEmpty) {
          return messages.join('\n');
        }
      }

      final Object? title = decoded['title'];
      if (title != null && title.toString().trim().isNotEmpty) {
        return title.toString();
      }
    } catch (_) {
      return trimmed;
    }

    return null;
  }
}
