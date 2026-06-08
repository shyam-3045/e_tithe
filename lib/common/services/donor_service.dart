import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_config.dart';
import '../constants/api_endpoints.dart';
import 'auth_service.dart';

class DonorDetails {
  const DonorDetails({
    required this.donorId,
    required this.type,
    required this.regionId,
    required this.areaId,
    required this.name,
    required this.photo,
    required this.title,
    required this.gender,
    required this.maritalStatus,
    required this.membership,
    required this.flatBuilding,
    required this.street,
    required this.city,
    required this.area,
    required this.state,
    required this.district,
    required this.pincode,
    required this.mobile,
    required this.whatsApp,
    required this.email,
    required this.birthDate,
    required this.weddingDate,
    required this.aadharNo,
    required this.panNo,
    required this.passport,
    required this.voterId,
    required this.drivingLicence,
    required this.organization,
    required this.address,
    required this.dependents,
  });

  factory DonorDetails.fromJson(Map<String, dynamic> json) {
    return DonorDetails(
      donorId: _parseInt(json['donorId'] ?? json['donorID'] ?? json['id']),
      type: _parseInt(json['type']),
      regionId: _parseInt(json['regionID'] ?? json['regionId']),
      name: _string(json['donorName'] ?? json['name'] ?? json['fullName']),
      areaId: _parseInt(json['areaID'] ?? json['areaId']),
      photo: _string(
        json['photo'] ?? json['Photo'] ?? json['photoUrl'] ?? json['photoPath'],
      ),
      title: _string(json['title'] ?? json['salutation'], fallback: 'Mr.'),
      gender: _string(json['gender'], fallback: 'Male'),
      maritalStatus: _string(json['maritalStatus'], fallback: 'Married'),
      membership: _string(json['membership'], fallback: 'Member'),
      flatBuilding: _string(
        json['flatBuilding'] ?? json['flatNo'] ?? json['houseNo'],
      ),
      street: _string(json['street'] ?? json['addressLine1'] ?? json['road']),
      city: _string(json['city']),
      area: _string(json['area']),
      state: _string(json['state']),
      district: _string(json['district']),
      pincode: _string(json['pincode'] ?? json['pinCode'] ?? json['zipcode']),
      mobile: _string(json['mobileNo'] ?? json['mobile'] ?? json['phone']),
      whatsApp: _string(
        json['whatsAppNo'] ?? json['whatsappNo'] ?? json['whatsapp'],
      ),
      email: _string(json['email']),
      birthDate: _string(json['birthDate'] ?? json['dob']),
      weddingDate: _string(json['weddingDate'] ?? json['anniversaryDate']),
      aadharNo: _string(
        json['aadharNo'] ??
            json['aadhaarNo'] ??
            json['aadhaar'] ??
            json['aadhaarNumber'],
      ),
      panNo: _string(json['panNo'] ?? json['panNumber']),
      passport: _string(json['passport']),
      voterId: _string(json['voterID'] ?? json['voterId']),
      drivingLicence: _string(
        json['drivingLicence'] ?? json['drivingLicense'],
      ),
      organization: _string(json['organization']),
      address: _string(json['address']),
      dependents: _parseDependents(json),
    );
  }

  final int donorId;
  final int type;
  final int regionId;
  final int areaId;
  final String name;
  final String photo;
  final String title;
  final String gender;
  final String maritalStatus;
  final String membership;
  final String flatBuilding;
  final String street;
  final String city;
  final String area;
  final String state;
  final String district;
  final String pincode;
  final String mobile;
  final String whatsApp;
  final String email;
  final String birthDate;
  final String weddingDate;
  final String aadharNo;
  final String panNo;
  final String passport;
  final String voterId;
  final String drivingLicence;
  final String organization;
  final String address;
  final List<DonorDependent> dependents;

  static int _parseInt(Object? value) {
    if (value is int) return value;
    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  static String _string(Object? value, {String fallback = ''}) {
    final String text = (value ?? '').toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static List<DonorDependent> _parseDependents(Map<String, dynamic> json) {
    final Object? value =
        json['dependents'] ?? json['dependentList'] ?? json['dependentDetails'];

    if (value is! List) {
      return const <DonorDependent>[];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(DonorDependent.fromJson)
        .toList();
  }
}

class DonorDependent {
  const DonorDependent({
    required this.relationId,
    required this.donorId,
    required this.name,
    required this.relation,
    required this.relationBirthDate,
    required this.relationAge,
    required this.deleted,
    required this.createdOn,
    required this.createdBy,
    required this.modifiedOn,
    required this.modifiedBy,
  });

  factory DonorDependent.fromJson(Map<String, dynamic> json) {
    final String name =
        (json['relationName'] ?? json['dependentName'] ?? json['name'] ?? '')
            .toString()
            .trim();
    final String relation =
        (json['relationshipToDonor'] ?? json['relation'] ?? '')
            .toString()
            .trim();

    return DonorDependent(
      relationId: _parseInt(json['relationID'] ?? json['relationId']),
      donorId: _parseInt(json['donorID'] ?? json['donorId']),
      name: name.isEmpty ? 'Unknown dependent' : name,
      relation: relation,
      relationBirthDate: _parseDate(json['relationBirthDate']),
      relationAge: _string(json['relationAge']),
      deleted: _parseBool(json['deleted']) ?? false,
      createdOn: _parseDate(json['createdOn']),
      createdBy: _string(json['createdBy']),
      modifiedOn: _parseDate(json['modifiedOn']),
      modifiedBy: _string(json['modifiedBy']),
    );
  }

  final int relationId;
  final int donorId;
  final String name;
  final String relation;
  final DateTime? relationBirthDate;
  final String relationAge;
  final bool deleted;
  final DateTime? createdOn;
  final String createdBy;
  final DateTime? modifiedOn;
  final String modifiedBy;

  static int _parseInt(Object? value) {
    if (value is int) return value;
    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  static String _string(Object? value, {String fallback = ''}) {
    final String text = (value ?? '').toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static DateTime? _parseDate(Object? value) {
    final String text = (value ?? '').toString().trim();
    if (text.isEmpty) return null;
    return DateTime.tryParse(text);
  }

  static bool? _parseBool(Object? value) {
    final String text = (value ?? '').toString().trim().toLowerCase();
    if (text.isEmpty) return null;
    if (text == 'true' || text == '1' || text == 'yes') return true;
    if (text == 'false' || text == '0' || text == 'no') return false;
    return null;
  }
}

class DonorService {
  DonorService({http.Client? client}) : _client = client ?? http.Client();

  static final DonorService instance = DonorService();

  final http.Client _client;

  Future<DonorDetails> fetchDonorById(int donorId) async {
    final Uri uri = ApiConfig.uri(ApiEndpoints.donorById(donorId));
    final Map<String, String> headers =
        await AuthService.instance.authenticatedJsonHeaders();

    print('[API] URL: $uri');
    print('[API] Payload: N/A');

    final http.Response response = await _client.get(uri, headers: headers);
    print('[API] Response: ${response.statusCode} ${response.body}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to load donor details. Please try again.');
    }

    final Object decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      final Object? data = decoded['data'] ?? decoded['result'];
      if (data is Map<String, dynamic>) {
        return DonorDetails.fromJson(data);
      }
      return DonorDetails.fromJson(decoded);
    }

    throw Exception('Unexpected donor detail response.');
  }

  Future<void> updateDonor({
    required int donorId,
    required Map<String, dynamic> payload,
  }) async {
    final Uri uri = ApiConfig.uri(ApiEndpoints.donorById(donorId));
    final Map<String, String> headers =
        await AuthService.instance.authenticatedJsonHeaders();

    final String body = jsonEncode(payload);
    print('[API] PUT $uri');
    print('[API] Request headers: ${jsonEncode(headers)}');
    print('[API] Request body: $body');

    final http.Response response = await _client.put(
      uri,
      headers: headers,
      body: body,
    );

    print('[API] Response: ${response.statusCode} ${response.body}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to update donor. Status: ${response.statusCode}');
    }
  }
}
