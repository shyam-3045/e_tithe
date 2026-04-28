import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_config.dart';
import '../constants/api_endpoints.dart';
import 'auth_service.dart';

class DonorDetails {
  const DonorDetails({
    required this.donorId,
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
    required this.dependents,
  });

  factory DonorDetails.fromJson(Map<String, dynamic> json) {
    return DonorDetails(
      donorId: _parseInt(json['donorId'] ?? json['donorID'] ?? json['id']),
      name: _string(json['donorName'] ?? json['name'] ?? json['fullName']),
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
        json['aadharNo'] ?? json['aadhaarNo'] ?? json['aadhaar'],
      ),
      panNo: _string(json['panNo'] ?? json['panNumber']),
      dependents: _parseDependents(json),
    );
  }

  final int donorId;
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
  const DonorDependent({required this.name, required this.relation});

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
      name: name.isEmpty ? 'Unknown dependent' : name,
      relation: relation,
    );
  }

  final String name;
  final String relation;
}

class DonorService {
  DonorService({http.Client? client}) : _client = client ?? http.Client();

  static final DonorService instance = DonorService();

  final http.Client _client;

  Future<DonorDetails> fetchDonorById(int donorId) async {
    final Uri uri = ApiConfig.uri(ApiEndpoints.donorById(donorId));
    final Map<String, String> headers = await AuthService.instance
        .authenticatedJsonHeaders();

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
}
