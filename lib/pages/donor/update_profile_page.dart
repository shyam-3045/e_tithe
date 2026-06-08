import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../../common/constants/api_config.dart';
import '../../common/constants/app_colors.dart';
import '../../common/widgets/common_alert.dart';
import '../../common/services/auth_service.dart';
import '../../common/services/area_service.dart';
import '../../common/services/donor_service.dart';
import '../../common/models/user_data.dart';
import 'dependent_page.dart';

class UpdateProfilePage extends StatefulWidget {
  const UpdateProfilePage({super.key, required this.donorName, this.donorId});

  final String donorName;
  final int? donorId;

  @override
  State<UpdateProfilePage> createState() => _UpdateProfilePageState();
}

class _UpdateProfilePageState extends State<UpdateProfilePage> {
  final _formKey = GlobalKey<FormState>();
  DonorDetails? _loadedDonor;
  UserData? _userData;
  bool _isSaving = false;

  final _imagePicker = ImagePicker();
  XFile? _selectedPhoto;
  Uint8List? _selectedPhotoBytes;

  // Personal
  final _donorNameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _weddingDateController = TextEditingController();
  final _aadharController = TextEditingController();
  final _panController = TextEditingController();
  final _passportController = TextEditingController();
  final _voterIdController = TextEditingController();
  final _drivingLicenceController = TextEditingController();

  // Address
  final _flatBuildingController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _districtController = TextEditingController();
  final _addressController = TextEditingController();
  final _mobileController = TextEditingController();
  final _whatsAppController = TextEditingController();
  final _emailController = TextEditingController();
  final _photoUrlController = TextEditingController();

  // Dependents
  final _dependentNameController = TextEditingController();
  final _dependentRelationshipController = TextEditingController();
  final _dependentBirthDateController = TextEditingController();
  final _dependentAgeController = TextEditingController();
  final List<_DependentDraft> _dependents = <_DependentDraft>[];

  List<AreaOption> _areaOptions = <AreaOption>[];
  bool _loadingAreas = false;
  int _selectedAreaId = 0;

  bool _personalExpanded = true;
  bool _addressExpanded = false;
  bool _dependentsExpanded = false;

  String _selectedTitle = 'Mr.';
  String? _selectedGender;
  String? _selectedMaritalStatus;
  String? _selectedMembership;
  String? _selectedArea;
  String? _selectedState;
  int? _selectedDonorType;

  String? _selectedIdentityDoc;
  static const List<String> _identityDocOptions = [
    'Aadhar',
    'PAN',
    'Passport',
    'Voter ID',
    'Driving Licence',
  ];

  static const List<String> _titles = ['Mr.', 'Mrs.', 'Ms.', 'Dr.'];
  static const List<String> _genders = ['Male', 'Female', 'Other'];
  static const List<String> _maritalStatuses = ['Married', 'Single', 'Other'];
  static const List<String> _membershipOptions = ['Member', 'Non-Member'];
  static const List<String> _states = [
    'Odisha',
    'Andhra Pradesh',
    'Delhi',
    'Karnataka',
    'Maharashtra',
    'Tamil Nadu',
    'West Bengal',
  ];

  @override
  void initState() {
    super.initState();

    _donorNameController.text = widget.donorName;

    _loadUserData();
    _loadDonorFromApi();
    _loadAreas();
  }

  Future<void> _loadUserData() async {
    final UserData? userData = await AuthService.instance.currentUserData();
    if (!mounted) return;
    setState(() {
      _userData = userData;
    });
  }

  Future<void> _loadAreas() async {
    setState(() {
      _loadingAreas = true;
    });

    try {
      final List<AreaOption> areas = await AreaService.instance.fetchAreas();
      if (!mounted) return;
      setState(() {
        _areaOptions = areas;
      });
      _syncAreaSelection();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _areaOptions = <AreaOption>[];
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loadingAreas = false;
      });
    }
  }

  void _syncAreaSelection() {
    final DonorDetails? donor = _loadedDonor;
    if (donor == null || _areaOptions.isEmpty) return;

    AreaOption? matched;
    if (donor.areaId > 0) {
      matched = _areaOptions.cast<AreaOption?>().firstWhere(
            (a) => a?.areaId == donor.areaId,
            orElse: () => null,
          );
    }

    matched ??= _areaOptions.cast<AreaOption?>().firstWhere(
          (a) => (a?.areaName ?? '').toLowerCase() == donor.area.toLowerCase(),
          orElse: () => null,
        );

    if (matched == null) return;
    setState(() {
      _selectedArea = matched!.areaName;
      _selectedAreaId = matched.areaId;
    });
  }

  Future<void> _loadDonorFromApi() async {
    final int donorId = widget.donorId ?? 0;
    if (donorId <= 0) return;

    try {
      final donor = await DonorService.instance.fetchDonorById(donorId);
      if (!mounted) return;

      setState(() {
        _loadedDonor = donor;
        _donorNameController.text = donor.name;
        _selectedTitle = donor.title;
        _selectedGender = donor.gender.trim().isEmpty ? null : donor.gender;
        _selectedMaritalStatus =
            donor.maritalStatus.trim().isEmpty ? null : donor.maritalStatus;

        _flatBuildingController.text = donor.flatBuilding;
        _streetController.text = donor.street;
        _cityController.text = donor.city;
        _pincodeController.text = donor.pincode;
        _districtController.text = donor.district;
        _addressController.text = donor.address;
        _mobileController.text = donor.mobile;
        _whatsAppController.text = donor.whatsApp;
        _emailController.text = donor.email;
        _photoUrlController.text = donor.photo;
        _birthDateController.text = donor.birthDate;
        _weddingDateController.text = donor.weddingDate;
        _aadharController.text = donor.aadharNo;
        _panController.text = donor.panNo;
        _passportController.text = donor.passport;
        _voterIdController.text = donor.voterId;
        _drivingLicenceController.text = donor.drivingLicence;
        _selectedDonorType = donor.type > 0 ? donor.type : null;
        _selectedMembership = donor.type == 1
            ? 'Member'
            : donor.type == 2
                ? 'Non-Member'
                : null;
        if (donor.panNo.trim().isNotEmpty && donor.aadharNo.trim().isEmpty) {
          _selectedIdentityDoc = 'PAN';
        } else if (donor.passport.trim().isNotEmpty) {
          _selectedIdentityDoc = 'Passport';
        } else if (donor.voterId.trim().isNotEmpty) {
          _selectedIdentityDoc = 'Voter ID';
        } else if (donor.drivingLicence.trim().isNotEmpty) {
          _selectedIdentityDoc = 'Driving Licence';
        } else if (donor.aadharNo.trim().isNotEmpty) {
          _selectedIdentityDoc = 'Aadhar';
        } else {
          _selectedIdentityDoc = null;
        }

        if (_states.contains(donor.state)) {
          _selectedState = donor.state;
        }

        if (donor.areaId > 0) {
          _selectedAreaId = donor.areaId;
        }

        _dependents
          ..clear()
          ..addAll(
            donor.dependents.map(
              (d) => _DependentDraft(
                relationID: 0,
                donorID: donor.donorId,
                relationName: d.name,
                relationshipToDonor: d.relation,
                relationBirthDate: null,
                relationAge: '',
                deleted: false,
                createdOn: DateTime.now().toUtc(),
                createdBy: 'mobile-app',
                modifiedOn: DateTime.now().toUtc(),
                modifiedBy: 'mobile-app',
              ),
            ),
          );
      });

      _syncAreaSelection();
    } catch (error) {
      if (!mounted) return;
      await CommonAlert.showInfo(
        context,
        title: 'Load failed',
        message: error.toString(),
      );
    }
  }

  @override
  void dispose() {
    _donorNameController.dispose();
    _birthDateController.dispose();
    _weddingDateController.dispose();
    _aadharController.dispose();
    _panController.dispose();
    _passportController.dispose();
    _voterIdController.dispose();
    _drivingLicenceController.dispose();
    _flatBuildingController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _districtController.dispose();
    _addressController.dispose();
    _mobileController.dispose();
    _whatsAppController.dispose();
    _emailController.dispose();
    _photoUrlController.dispose();
    _dependentNameController.dispose();
    _dependentRelationshipController.dispose();
    _dependentBirthDateController.dispose();
    _dependentAgeController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final DateTime now = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(1950),
      lastDate: DateTime(now.year + 10),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryPurple,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return;

    setState(() {
      controller.text = '${pickedDate.day.toString().padLeft(2, '0')}/'
          '${pickedDate.month.toString().padLeft(2, '0')}/'
          '${pickedDate.year}';
      if (controller == _dependentBirthDateController) {
        final DateTime today = DateTime.now();
        int age = today.year - pickedDate.year;
        if (today.month < pickedDate.month ||
            (today.month == pickedDate.month && today.day < pickedDate.day)) {
          age--;
        }
        _dependentAgeController.text = age.toString();
      }
    });
  }

  DateTime? _parseDateFlexible(String input) {
    final String text = input.trim();
    if (text.isEmpty) return null;

    final DateTime? direct = DateTime.tryParse(text);
    if (direct != null) return direct;

    final parts = text.split('/');
    if (parts.length != 3) return null;
    final int? day = int.tryParse(parts[0]);
    final int? month = int.tryParse(parts[1]);
    final int? year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  String? _toApiDateString(DateTime? date) {
    if (date == null) return null;
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _toApiUserType(String userTypeName) {
    final String normalized = userTypeName.trim();
    if (normalized.isEmpty) return '';

    final String lower = normalized.toLowerCase();
    if (lower.contains('local') && lower.contains('member')) {
      return 'localUnit';
    }

    return normalized;
  }

  void _addDependentDraft() {
    final String name = _dependentNameController.text.trim();
    final String relationship = _dependentRelationshipController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dependent name is required.')),
      );
      return;
    }

    final DateTime now = DateTime.now().toUtc();
    final int donorId = widget.donorId ?? _loadedDonor?.donorId ?? 0;

    setState(() {
      _dependents.add(
        _DependentDraft(
          relationID: 0,
          donorID: donorId,
          relationName: name,
          relationshipToDonor: relationship,
          relationBirthDate: _parseDateFlexible(
            _dependentBirthDateController.text,
          ),
          relationAge: _dependentAgeController.text.trim(),
          deleted: false,
          createdOn: now,
          createdBy: 'mobile-app',
          modifiedOn: now,
          modifiedBy: 'mobile-app',
        ),
      );

      _dependentNameController.clear();
      _dependentRelationshipController.clear();
      _dependentBirthDateController.clear();
      _dependentAgeController.clear();
    });
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final XFile? pickedPhoto = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
    );

    if (pickedPhoto == null) {
      return;
    }

    final Uint8List photoBytes = await pickedPhoto.readAsBytes();

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedPhoto = pickedPhoto;
      _selectedPhotoBytes = photoBytes;
    });
  }

  static String? _photoUrl(Object? value) {
    final String raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) {
      return null;
    }

    final Uri? uri = Uri.tryParse(raw);
    if (uri != null && uri.hasScheme) {
      if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
        final Uri base = Uri.parse(ApiConfig.baseUrl);
        return uri
            .replace(scheme: base.scheme, host: base.host, port: base.port)
            .toString();
      }
      return raw;
    }

    final String normalizedPath = raw.startsWith('/') ? raw : '/$raw';
    return '${ApiConfig.baseUrl}$normalizedPath';
  }

  void _removePhoto() {
    setState(() {
      _photoUrlController.clear();
      _selectedPhoto = null;
      _selectedPhotoBytes = null;
    });
  }

  void _removeDependentAt(int index) {
    setState(() {
      _dependents.removeAt(index);
    });
  }

  void _clearIdentityDocumentControllers() {
    _aadharController.clear();
    _panController.clear();
    _passportController.clear();
    _voterIdController.clear();
    _drivingLicenceController.clear();
  }

  TextEditingController get _selectedIdentityController {
    switch (_selectedIdentityDoc) {
      case 'PAN':
        return _panController;
      case 'Passport':
        return _passportController;
      case 'Voter ID':
        return _voterIdController;
      case 'Driving Licence':
        return _drivingLicenceController;
      case 'Aadhar':
      case null:
      default:
        return _aadharController;
    }
  }

  String get _selectedIdentityLabel {
    switch (_selectedIdentityDoc) {
      case 'PAN':
        return 'PAN';
      case 'Passport':
        return 'Passport';
      case 'Voter ID':
        return 'Voter ID';
      case 'Driving Licence':
        return 'Driving Licence';
      case 'Aadhar':
      case null:
      default:
        return 'Aadhar No';
    }
  }

  TextInputType? get _selectedIdentityKeyboardType {
    switch (_selectedIdentityDoc) {
      case 'Aadhar':
      case null:
        return TextInputType.number;
      default:
        return TextInputType.text;
    }
  }

  TextCapitalization get _selectedIdentityCapitalization {
    switch (_selectedIdentityDoc) {
      case 'Aadhar':
      case null:
        return TextCapitalization.none;
      default:
        return TextCapitalization.characters;
    }
  }

  bool get _hasSelectedDonorType => _selectedDonorType != null;

  void _selectDonorType(int value) {
    setState(() {
      _selectedDonorType = value;
      _selectedMembership = value == 1 ? 'Member' : 'Non-Member';
    });
  }

  Map<String, dynamic> _buildUpdatePayload() {
    final DateTime now = DateTime.now().toUtc();
    final DonorDetails? donor = _loadedDonor;
    final UserData? user = _userData;
    final String updatedBy = user?.userName ?? 'mobile-app';
    final String userTypeLower = (user?.userTypeName ?? '').toLowerCase();
    final int currentUserId = user?.userID ?? 0;
    final int areaLeaderId =
        (userTypeLower.contains('area') && userTypeLower.contains('leader'))
            ? currentUserId
            : 0;
    final int promotionStaffId = (userTypeLower.contains('promo') ||
            userTypeLower.contains('promotional') ||
            userTypeLower.contains('promotion'))
        ? currentUserId
        : 0;
    final int localMemberId =
        (userTypeLower.contains('local') && userTypeLower.contains('member'))
            ? currentUserId
            : 0;

    final Map<String, _DependentDraft> mergedDependents =
        <String, _DependentDraft>{};

    void addDependent(_DependentDraft draft) {
      final String key =
          '${draft.relationName.toLowerCase()}|${draft.relationshipToDonor.toLowerCase()}';
      final _DependentDraft? existing = mergedDependents[key];
      if (existing != null &&
          existing.relationID != 0 &&
          draft.relationID == 0) {
        return;
      }
      mergedDependents[key] = draft;
    }

    for (final DonorDependent d
        in donor?.dependents ?? const <DonorDependent>[]) {
      addDependent(
        _DependentDraft(
          relationID: d.relationId,
          donorID: d.donorId,
          relationName: d.name,
          relationshipToDonor: d.relation,
          relationBirthDate: d.relationBirthDate,
          relationAge: d.relationAge,
          deleted: d.deleted,
          createdOn: d.createdOn ?? now,
          createdBy: d.createdBy.isEmpty ? updatedBy : d.createdBy,
          modifiedOn: d.modifiedOn ?? now,
          modifiedBy: d.modifiedBy.isEmpty ? updatedBy : d.modifiedBy,
        ),
      );
    }

    for (final _DependentDraft d in _dependents) {
      addDependent(d);
    }

    final List<Map<String, dynamic>> dependentsPayload =
        mergedDependents.values.map((d) => d.toJson()).toList();

    return <String, dynamic>{
      'donorID': widget.donorId ?? 0,
      'donorName': _donorNameController.text.trim(),
      'panNumber':
          _selectedIdentityDoc == 'PAN' ? _panController.text.trim() : '',
      'aadhaarNumber':
          _selectedIdentityDoc == 'Aadhar' ? _aadharController.text.trim() : '',
      'passport': _selectedIdentityDoc == 'Passport'
          ? _passportController.text.trim()
          : '',
      'voterID': _selectedIdentityDoc == 'Voter ID'
          ? _voterIdController.text.trim()
          : '',
      'drivingLicence': _selectedIdentityDoc == 'Driving Licence'
          ? _drivingLicenceController.text.trim()
          : '',
      'birthDate': _toApiDateString(
        _parseDateFlexible(_birthDateController.text),
      ),
      'marriageDate': (_selectedMaritalStatus == 'Married')
          ? _toApiDateString(_parseDateFlexible(_weddingDateController.text))
          : null,
      'gender': (_selectedGender ?? '').trim(),
      'maritalStatus': (_selectedMaritalStatus ?? '').trim(),
      'regionID': donor?.regionId ?? 0,
      'areaID': _selectedAreaId,
      'areaLeaderID': areaLeaderId,
      'promotionStaffID': promotionStaffId,
      'localMemberID': localMemberId,
      'mobile': _mobileController.text.trim(),
      'whatsAppNumber': _whatsAppController.text.trim(),
      'email': _emailController.text.trim(),
      'street': _streetController.text.trim(),
      'village': _flatBuildingController.text.trim(),
      'city': _cityController.text.trim(),
      'district': _districtController.text.trim(),
      'state': (_selectedState ?? '').trim(),
      'pincode': _pincodeController.text.trim(),
      'organization': donor?.organization ?? '',
      'address': _addressController.text.trim(),
      'type': _selectedDonorType ?? 0,
      'userType': _toApiUserType(user?.userTypeName ?? ''),
      'userID': user?.userID ?? 0,
      'isActive': true,
      'deleted': false,
      'photo':
          _selectedPhotoBytes != null ? '' : _photoUrlController.text.trim(),
      'createdOn': now.toIso8601String(),
      'createdBy': updatedBy,
      'modifiedOn': now.toIso8601String(),
      'modifiedBy': updatedBy,
      'dependents': dependentsPayload,
    };
  }

  Future<void> _handleUpdate() async {
    FocusScope.of(context).unfocus();

    if (!_hasSelectedDonorType) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select Individual or Others to continue.'),
        ),
      );
      return;
    }

    if (_selectedGender == null ||
        _selectedMaritalStatus == null ||
        _selectedState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Select gender, marital status, and state to continue.',
          ),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final int donorId = widget.donorId ?? 0;
    if (donorId <= 0) {
      await CommonAlert.showInfo(
        context,
        title: 'Missing donor',
        message: 'Donor ID is missing. Please refresh and try again.',
      );
      return;
    }

    if (_isSaving) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Updating... please wait.')));
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final payload = _buildUpdatePayload();
      print('[UpdateProfilePage] Update donor payload: ${payload.toString()}');
      await DonorService.instance.updateDonor(
        donorId: donorId,
        payload: payload,
      );

      if (_selectedPhotoBytes != null) {
        try {
          final String? token = await AuthService.instance.token;
          final Uri photoUri = ApiConfig.uri('/api/Donor/$donorId/photo');
          final request = http.MultipartRequest('POST', photoUri);
          if (token != null) {
            request.headers['Authorization'] = 'Bearer $token';
          }
          request.files.add(
            http.MultipartFile.fromBytes(
              'Photo',
              _selectedPhotoBytes!,
              filename: _selectedPhoto?.name ?? 'photo.jpg',
            ),
          );

          print('[API] Uploading photo to $photoUri...');
          final streamedResponse = await request.send();
          final photoResponse =
              await http.Response.fromStream(streamedResponse);
          print('[API] Photo upload status: ${photoResponse.statusCode}');
          print('[API] Photo upload body: ${photoResponse.body}');
        } catch (e) {
          print('[API] Error uploading photo: $e');
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Donor updated successfully.')),
      );
    } catch (error) {
      if (!mounted) return;

      await CommonAlert.showInfo(
        context,
        title: 'Update failed',
        message: error.toString(),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _handlePhoto() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded),
                title: const Text('Take photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickPhoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openDependent() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DependentPage(
          donorName: _donorNameController.text,
          donorId: widget.donorId,
        ),
      ),
    );
  }

  void _refreshDonor() {
    _loadDonorFromApi();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Donor'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refreshDonor,
            icon: const Icon(Icons.refresh_rounded, size: 20),
          ),
        ],
      ),
      bottomNavigationBar: _BottomActionBar(
        onUpdate: _handleUpdate,
        onPhoto: _handlePhoto,
        onDependent: _openDependent,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 110),
            child: Column(
              children: [
                _SectionPanel(
                  title: 'Personal Details',
                  isExpanded: _personalExpanded,
                  onToggle: () {
                    setState(() {
                      _personalExpanded = !_personalExpanded;
                      if (_personalExpanded) _addressExpanded = false;
                    });
                  },
                  child: Column(
                    children: [
                      _DonorTypeSelector(
                        value: _selectedDonorType,
                        onChanged: _selectDonorType,
                      ),
                      const SizedBox(height: 14),
                      IgnorePointer(
                        ignoring: !_hasSelectedDonorType,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 180),
                          opacity: _hasSelectedDonorType ? 1 : 0.45,
                          child: Column(
                            children: [
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final bool compact =
                                      constraints.maxWidth < 420;

                                  final titleField = _DropdownField(
                                    value: _selectedTitle,
                                    label: 'Title',
                                    items: _titles,
                                    onChanged: (value) {
                                      if (value == null) return;
                                      setState(() => _selectedTitle = value);
                                    },
                                  );

                                  final nameField = _OutlinedTextField(
                                    controller: _donorNameController,
                                    label: 'Donor Name',
                                    icon: Icons.person_rounded,
                                    validator: (value) => _requiredValidator(
                                      value,
                                      'Donor name is required',
                                    ),
                                  );

                                  if (compact) {
                                    return Column(
                                      children: [
                                        titleField,
                                        const SizedBox(height: 14),
                                        nameField,
                                      ],
                                    );
                                  }

                                  return Row(
                                    children: [
                                      Expanded(flex: 2, child: titleField),
                                      const SizedBox(width: 12),
                                      Expanded(flex: 5, child: nameField),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 14),
                              _ChoiceGroup(
                                label: 'Gender',
                                value: _selectedGender,
                                options: _genders,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedGender = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 14),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(18),
                                  border:
                                      Border.all(color: AppColors.borderGrey),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Photo',
                                      style: TextStyle(
                                        color: AppColors.textGrey,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Container(
                                          width: 68,
                                          height: 68,
                                          decoration: BoxDecoration(
                                            color: AppColors.lavender,
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            border: Border.all(
                                              color: AppColors.borderGrey,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            child: _selectedPhotoBytes != null
                                                ? Image.memory(
                                                    _selectedPhotoBytes!,
                                                    fit: BoxFit.cover,
                                                  )
                                                : _photoUrlController.text
                                                        .trim()
                                                        .isEmpty
                                                    ? const Icon(
                                                        Icons.person_rounded,
                                                        color: AppColors
                                                            .iconPurple,
                                                        size: 32,
                                                      )
                                                    : Image.network(
                                                        _photoUrl(
                                                              _photoUrlController
                                                                  .text
                                                                  .trim(),
                                                            ) ??
                                                            '',
                                                        fit: BoxFit.cover,
                                                        errorBuilder:
                                                            (context, _, __) {
                                                          return const Icon(
                                                            Icons
                                                                .broken_image_outlined,
                                                            color: AppColors
                                                                .textGrey,
                                                          );
                                                        },
                                                      ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            _selectedPhotoBytes != null
                                                ? (_selectedPhoto?.name ??
                                                    'New image selected')
                                                : _photoUrlController.text
                                                        .trim()
                                                        .isEmpty
                                                    ? 'No photo selected'
                                                    : _photoUrlController.text
                                                        .trim(),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: AppColors.textGrey,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: _handlePhoto,
                                          icon: const Icon(
                                            Icons.add_a_photo_outlined,
                                          ),
                                          label: const Text('Add Photo'),
                                        ),
                                        const SizedBox(width: 10),
                                        OutlinedButton.icon(
                                          onPressed: (_photoUrlController.text
                                                      .trim()
                                                      .isEmpty &&
                                                  _selectedPhotoBytes == null)
                                              ? null
                                              : _removePhoto,
                                          icon: const Icon(
                                            Icons.delete_outline_rounded,
                                          ),
                                          label: const Text('Remove'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              _OutlinedTextField(
                                controller: _birthDateController,
                                label: 'Birth Date',
                                icon: Icons.calendar_month_rounded,
                                readOnly: true,
                                onTap: () => _pickDate(_birthDateController),
                              ),
                              const SizedBox(height: 14),
                              _ChoiceGroup(
                                label: 'Marital Status',
                                value: _selectedMaritalStatus,
                                options: _maritalStatuses,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedMaritalStatus = value;
                                    if (_selectedMaritalStatus != 'Married') {
                                      _weddingDateController.clear();
                                    }
                                  });
                                },
                              ),
                              if (_selectedMaritalStatus == 'Married') ...[
                                const SizedBox(height: 14),
                                _OutlinedTextField(
                                  controller: _weddingDateController,
                                  label: 'Wedding Date',
                                  icon: Icons.calendar_month_rounded,
                                  readOnly: true,
                                  onTap: () =>
                                      _pickDate(_weddingDateController),
                                ),
                              ],
                              const SizedBox(height: 14),
                              _ChoiceGroup(
                                label: 'Membership',
                                value: _selectedMembership,
                                options: _membershipOptions,
                              ),
                              const SizedBox(height: 14),
                              _DropdownField(
                                value: _selectedIdentityDoc,
                                label: 'Identity Document Type',
                                items: _identityDocOptions,
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() {
                                    _selectedIdentityDoc = value;
                                    _clearIdentityDocumentControllers();
                                  });
                                },
                              ),
                              if (_selectedIdentityDoc != null) ...[
                                const SizedBox(height: 14),
                                _OutlinedTextField(
                                  controller: _selectedIdentityController,
                                  label: _selectedIdentityLabel,
                                  icon: Icons.badge_outlined,
                                  keyboardType: _selectedIdentityKeyboardType,
                                  textCapitalization:
                                      _selectedIdentityCapitalization,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                IgnorePointer(
                  ignoring: !_hasSelectedDonorType,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: _hasSelectedDonorType ? 1 : 0.45,
                    child: _SectionPanel(
                      title: 'Address Details',
                      isExpanded: _addressExpanded,
                      onToggle: () {
                        if (!_hasSelectedDonorType) return;
                        setState(() {
                          _addressExpanded = !_addressExpanded;
                          if (_addressExpanded) _personalExpanded = false;
                        });
                      },
                      child: Column(
                        children: [
                          _DropdownField(
                            value: _selectedArea,
                            label: 'Area',
                            items: _areaOptions
                                .map((area) => area.areaName)
                                .where((name) => name.trim().isNotEmpty)
                                .toSet()
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              final AreaOption? selectedOption =
                                  _areaOptions.cast<AreaOption?>().firstWhere(
                                        (area) => area?.areaName == value,
                                        orElse: () => null,
                                      );
                              setState(() {
                                _selectedArea = value;
                                _selectedAreaId = selectedOption?.areaId ?? 0;
                              });
                            },
                          ),
                          const SizedBox(height: 14),
                          _OutlinedTextField(
                            controller: _flatBuildingController,
                            label: 'Flat/Building',
                            icon: Icons.apartment_rounded,
                          ),
                          const SizedBox(height: 14),
                          _OutlinedTextField(
                            controller: _streetController,
                            label: 'Street/Avenue',
                            icon: Icons.person_pin_circle_rounded,
                          ),
                          const SizedBox(height: 14),
                          _OutlinedTextField(
                            controller: _cityController,
                            label: 'City',
                            icon: Icons.location_city_rounded,
                          ),
                          const SizedBox(height: 14),
                          _OutlinedTextField(
                            controller: _pincodeController,
                            label: 'Pincode',
                            icon: Icons.local_post_office_outlined,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 14),
                          _OutlinedTextField(
                            controller: _districtController,
                            label: 'District',
                            icon: Icons.location_on_outlined,
                          ),
                          const SizedBox(height: 14),
                          _OutlinedTextField(
                            controller: _addressController,
                            label: 'Address',
                            icon: Icons.home_rounded,
                          ),
                          const SizedBox(height: 14),
                          _DropdownField(
                            value: _selectedState,
                            label: 'State',
                            items: _states,
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _selectedState = value);
                            },
                          ),
                          const SizedBox(height: 14),
                          _OutlinedTextField(
                            controller: _mobileController,
                            label: 'Mobile *',
                            icon: Icons.phone_android_rounded,
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              final String? error = _requiredValidator(
                                value,
                                'Mobile number is required',
                              );
                              if (error != null) return error;
                              if ((value ?? '').trim().length < 10) {
                                return 'Enter a valid mobile number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          _OutlinedTextField(
                            controller: _whatsAppController,
                            label: 'WhatsApp No',
                            icon: Icons.message_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 14),
                          _OutlinedTextField(
                            controller: _emailController,
                            label: 'Email',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              final String input = (value ?? '').trim();
                              if (input.isEmpty) return null;
                              final bool isValid = RegExp(
                                r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                              ).hasMatch(input);
                              return isValid ? null : 'Enter a valid email';
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                IgnorePointer(
                  ignoring: !_hasSelectedDonorType,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: _hasSelectedDonorType ? 1 : 0.45,
                    child: _SectionPanel(
                      title: 'Dependent Details',
                      isExpanded: _dependentsExpanded,
                      onToggle: () {
                        if (!_hasSelectedDonorType) return;
                        setState(() {
                          _dependentsExpanded = !_dependentsExpanded;
                        });
                      },
                      child: Column(
                        children: [
                          _OutlinedTextField(
                            controller: _dependentNameController,
                            label: 'Dependent Name',
                            icon: Icons.person_outline_rounded,
                          ),
                          const SizedBox(height: 14),
                          _OutlinedTextField(
                            controller: _dependentRelationshipController,
                            label: 'Relationship To Donor',
                            icon: Icons.family_restroom_outlined,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _OutlinedTextField(
                                  controller: _dependentBirthDateController,
                                  label: 'Birth Date',
                                  icon: Icons.cake_outlined,
                                  readOnly: true,
                                  onTap: () =>
                                      _pickDate(_dependentBirthDateController),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _OutlinedTextField(
                                  controller: _dependentAgeController,
                                  label: 'Age',
                                  icon: Icons.numbers_rounded,
                                  keyboardType: TextInputType.number,
                                  textCapitalization: TextCapitalization.none,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              onPressed: _addDependentDraft,
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Add Dependent'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.statusBarPink,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          if (_dependents.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            ...List.generate(
                              _dependents.length,
                              (index) => _DependentTile(
                                dependent: _dependents[index],
                                onRemove: () => _removeDependentAt(index),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _requiredValidator(String? value, String message) {
    if ((value ?? '').trim().isEmpty) return message;
    return null;
  }
}

class _SectionPanel extends StatelessWidget {
  const _SectionPanel({
    required this.title,
    required this.isExpanded,
    required this.onToggle,
    required this.child,
  });

  final String title;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.lavender, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepPurple.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            onTap: onToggle,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.statusBarPink, AppColors.mutedPurple],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }
}

class _OutlinedTextField extends StatelessWidget {
  const _OutlinedTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
    this.keyboardType,
    this.onTap,
    this.readOnly = false,
    this.textCapitalization = TextCapitalization.words,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final VoidCallback? onTap;
  final bool readOnly;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      textCapitalization: textCapitalization,
      decoration: _inputDecoration(label, icon),
      style: const TextStyle(
        color: AppColors.textDark,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  static InputDecoration _inputDecoration(String label, IconData icon) {
    const borderSide = BorderSide(color: AppColors.borderGrey, width: 1.2);

    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: AppColors.textGrey,
        fontWeight: FontWeight.w600,
      ),
      prefixIcon: Icon(icon, color: AppColors.iconPurple),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderSide: borderSide,
        borderRadius: BorderRadius.circular(18),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: borderSide,
        borderRadius: BorderRadius.circular(18),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(
          color: AppColors.primaryPurple,
          width: 1.6,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }
}

class _DependentDraft {
  const _DependentDraft({
    required this.relationID,
    required this.donorID,
    required this.relationName,
    required this.relationshipToDonor,
    required this.relationBirthDate,
    required this.relationAge,
    required this.deleted,
    required this.createdOn,
    required this.createdBy,
    required this.modifiedOn,
    required this.modifiedBy,
  });

  final int relationID;
  final int donorID;
  final String relationName;
  final DateTime? relationBirthDate;
  final String relationAge;
  final String relationshipToDonor;
  final bool deleted;
  final DateTime createdOn;
  final String createdBy;
  final DateTime modifiedOn;
  final String modifiedBy;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'relationID': relationID,
      'donorID': donorID,
      'relationName': relationName,
      'relationBirthDate': relationBirthDate?.toUtc().toIso8601String(),
      'relationAge': relationAge,
      'relationshipToDonor': relationshipToDonor,
      'deleted': deleted,
      'createdOn': createdOn.toUtc().toIso8601String(),
      'createdBy': createdBy,
      'modifiedOn': modifiedOn.toUtc().toIso8601String(),
      'modifiedBy': modifiedBy,
    };
  }
}

class _DependentTile extends StatelessWidget {
  const _DependentTile({required this.dependent, required this.onRemove});

  final _DependentDraft dependent;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_rounded, color: AppColors.iconPurple),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dependent.relationName,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (dependent.relationshipToDonor.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      dependent.relationshipToDonor,
                      style: const TextStyle(
                        color: AppColors.textGrey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove',
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded, color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.label,
    required this.items,
    required this.onChanged,
  });

  final String? value;
  final String label;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: _OutlinedTextField._inputDecoration(
        value == null ? '' : label,
        Icons.arrow_drop_down,
      ),
      hint: Text(
        label,
        style: const TextStyle(
          color: AppColors.textGrey,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      icon: const Icon(Icons.arrow_drop_down_rounded),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _ChoiceGroup extends StatelessWidget {
  const _ChoiceGroup({
    required this.label,
    required this.options,
    this.value,
    this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textGrey,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: options
                .map(
                  (option) => SizedBox(
                    width: 170,
                    child: Material(
                      color: Colors.transparent,
                      child: RadioListTile<String>(
                        value: option,
                        groupValue: value,
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        activeColor: AppColors.statusBarPink,
                        title: Text(
                          option,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        onChanged: (selected) {
                          if (selected != null && onChanged != null) {
                            onChanged!.call(selected);
                          }
                        },
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _DonorTypeSelector extends StatelessWidget {
  const _DonorTypeSelector({
    required this.value,
    required this.onChanged,
  });

  final int? value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Donor Type *',
            style: TextStyle(
              color: AppColors.textGrey,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _DonorTypeOption(
                  label: 'Individual',
                  selected: value == 1,
                  onTap: () => onChanged(1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DonorTypeOption(
                  label: 'Others',
                  selected: value == 2,
                  onTap: () => onChanged(2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonorTypeOption extends StatelessWidget {
  const _DonorTypeOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? AppColors.statusBarPink
                      : AppColors.textGrey.withValues(alpha: 0.7),
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.statusBarPink,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.onUpdate,
    required this.onPhoto,
    required this.onDependent,
    required this.onBack,
  });

  final VoidCallback onUpdate;
  final VoidCallback onPhoto;
  final VoidCallback onDependent;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryPurple, AppColors.richPurple],
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 18,
              offset: Offset(0, -8),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _BottomAction(
              label: 'Update',
              icon: Icons.save_outlined,
              onTap: onUpdate,
            ),
            _BottomAction(
              label: 'Photo',
              icon: Icons.photo_camera_outlined,
              onTap: onPhoto,
            ),
            _BottomAction(
              label: 'Dependent',
              icon: Icons.person_add_alt_1_outlined,
              onTap: onDependent,
            ),
            _BottomAction(
              label: 'Back',
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: onBack,
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
