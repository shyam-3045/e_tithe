import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../../common/constants/api_config.dart';
import '../../common/constants/app_colors.dart';
import '../../common/widgets/common_alert.dart';
import '../../common/services/auth_service.dart';
import '../../common/services/area_service.dart';
import '../../common/services/donor_service.dart';
import '../../common/services/location_service.dart';
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

  // Org identity doc controllers
  final _gstNumberController = TextEditingController();
  final _tanNumberController = TextEditingController();
  final _udyamNumberController = TextEditingController();
  final _tradeLicenseController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  final _contactPersonNameController = TextEditingController();

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
  int? _editingDependentIndex;

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
  String? _selectedCountry;
  int? _selectedDonorType;

  String? _selectedIdentityDoc;
  static const List<String> _individualIdentityDocOptions = [
    'NaN',
    'Aadhar',
    'PAN',
    'Passport',
    'Voter ID',
    'Driving Licence',
  ];
  static const List<String> _orgIdentityDocOptions = [
    'NaN',
    'GST Number',
    'TAN Number',
    'Udyam Number',
    'Trade License Number',
    'Registration Number',
  ];

  List<String> get _identityDocOptions =>
      _isOrganizationDonor ? _orgIdentityDocOptions : _individualIdentityDocOptions;

  String _lastAutoFilledWhatsApp = '';

  static const List<String> _titles = [
    'Mr.',
    'Mrs.',
    'Ms.',
    'Dr.',
    'Mst.',
    'Mis.',
    'Sir',
    'Rev.',
    'Ps.',
    'Er.',
    'Rt.',
  ];
  static const List<String> _genders = ['Male', 'Female', 'Other'];
  static const List<String> _maritalStatuses = ['Married', 'Single', 'Other'];
  static const List<String> _membershipOptions = ['Member', 'Non-Member'];

  List<StateOption> _stateOptions = <StateOption>[];
  bool _loadingStates = false;
  List<CountryOption> _countryOptions = <CountryOption>[];
  bool _loadingCountries = false;

  @override
  void initState() {
    super.initState();

    _donorNameController.text = widget.donorName;

    _loadUserData();
    _loadDonorFromApi();
    _loadAreas();
    _loadStates();
    _loadCountries();

    _flatBuildingController.addListener(_updateCombinedAddress);
    _streetController.addListener(_updateCombinedAddress);
    _cityController.addListener(_updateCombinedAddress);
    _districtController.addListener(_updateCombinedAddress);
    _pincodeController.addListener(_updateCombinedAddress);

    _mobileController.addListener(() {
      final String mobileText = _mobileController.text;
      if (_whatsAppController.text.isEmpty ||
          _whatsAppController.text == _lastAutoFilledWhatsApp) {
        _whatsAppController.text = mobileText;
        _lastAutoFilledWhatsApp = mobileText;
      }
    });
  }

  String _buildCombinedAddress() {
    final String flat = _flatBuildingController.text.trim();
    final String street = _streetController.text.trim();
    final String city = _cityController.text.trim();
    final String district = _districtController.text.trim();
    final String pincode = _pincodeController.text.trim();
    final String state = (_selectedState ?? '').trim();
    final String country = (_selectedCountry ?? '').trim();

    final String districtPincodeLine = [
      district,
      pincode,
    ].where((String part) => part.isNotEmpty).join(' - ');

    return <String>[
      flat,
      street,
      city,
      districtPincodeLine,
      state,
      country,
    ].where((String line) => line.isNotEmpty).join(',\n');
  }

  void _updateCombinedAddress() {
    _addressController.text = _buildCombinedAddress();
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

  Future<void> _loadStates() async {
    setState(() {
      _loadingStates = true;
    });

    try {
      final List<StateOption> states =
          await LocationService.instance.fetchStates();
      if (!mounted) return;
      setState(() {
        _stateOptions = states;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _stateOptions = <StateOption>[];
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loadingStates = false;
      });
    }
  }

  Future<void> _loadCountries() async {
    setState(() {
      _loadingCountries = true;
    });

    try {
      final List<CountryOption> countries =
          await LocationService.instance.fetchCountries();
      if (!mounted) return;
      setState(() {
        _countryOptions = countries;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _countryOptions = <CountryOption>[];
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loadingCountries = false;
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
        _selectedTitle = _titles.contains(donor.title) ? donor.title : 'Mr.';
        _selectedGender = donor.gender.trim().isEmpty ? null : donor.gender;
        _selectedMaritalStatus =
            donor.maritalStatus.trim().isEmpty ? null : donor.maritalStatus;

        _flatBuildingController.text = donor.flatBuilding;
        _streetController.text = donor.street;
        _cityController.text = donor.city;
        _pincodeController.text = donor.pincode;
        _districtController.text = donor.district;
        _mobileController.text = donor.mobile;
        _whatsAppController.text = donor.whatsApp;
        _contactPersonNameController.text = donor.contactPersonName;
        _emailController.text = donor.email;
        _photoUrlController.text = donor.photo;
        _birthDateController.text = donor.birthDate;
        _weddingDateController.text = donor.weddingDate;
        _aadharController.text = donor.aadharNo;
        _panController.text = donor.panNo;
        _passportController.text = donor.passport;
        _voterIdController.text = donor.voterId;
        _drivingLicenceController.text = donor.drivingLicence;
        _gstNumberController.text = donor.gstNumber;
        _tanNumberController.text = donor.tanNumber;
        _udyamNumberController.text = donor.udyamNumber;
        _tradeLicenseController.text = donor.tradeLicenseNumber;
        _registrationNumberController.text = donor.registrationNumber;
        _selectedDonorType = donor.type > 0 ? donor.type : null;
        _selectedMembership = donor.type == 1
            ? 'Member'
            : donor.type == 2
                ? 'Non-Member'
                : null;
        if (donor.type == 2) {
          if (donor.gstNumber.trim().isNotEmpty) {
            _selectedIdentityDoc = 'GST Number';
          } else if (donor.tanNumber.trim().isNotEmpty) {
            _selectedIdentityDoc = 'TAN Number';
          } else if (donor.udyamNumber.trim().isNotEmpty) {
            _selectedIdentityDoc = 'Udyam Number';
          } else if (donor.tradeLicenseNumber.trim().isNotEmpty) {
            _selectedIdentityDoc = 'Trade License Number';
          } else if (donor.registrationNumber.trim().isNotEmpty) {
            _selectedIdentityDoc = 'Registration Number';
          } else {
            _selectedIdentityDoc = 'NaN';
          }
        } else if (donor.panNo.trim().isNotEmpty &&
            donor.aadharNo.trim().isEmpty) {
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
          _selectedIdentityDoc = 'NaN';
        }

        _selectedState = donor.state.trim().isEmpty ? null : donor.state;
        _selectedCountry =
            donor.country.trim().isEmpty ? null : donor.country;

        if (donor.areaId > 0) {
          _selectedAreaId = donor.areaId;
        }

        _dependents
          ..clear()
          ..addAll(
            donor.dependents.map(
              (d) => _DependentDraft(
                relationID: d.relationId,
                donorID: d.donorId > 0 ? d.donorId : donor.donorId,
                relationName: d.name,
                relationshipToDonor: d.relation,
                relationBirthDate: d.relationBirthDate,
                relationAge: d.relationAge,
                deleted: d.deleted,
                createdOn: d.createdOn ?? DateTime.now().toUtc(),
                createdBy: d.createdBy.isEmpty ? 'mobile-app' : d.createdBy,
                modifiedOn: d.modifiedOn ?? DateTime.now().toUtc(),
                modifiedBy: d.modifiedBy.isEmpty ? 'mobile-app' : d.modifiedBy,
                fromServer: true,
              ),
            ),
          );
      });

      if (donor.addressLine2.trim().isNotEmpty) {
        _addressController.text = donor.addressLine2;
      } else {
        _updateCombinedAddress();
      }
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
    _gstNumberController.dispose();
    _tanNumberController.dispose();
    _udyamNumberController.dispose();
    _tradeLicenseController.dispose();
    _registrationNumberController.dispose();
    _contactPersonNameController.dispose();
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
    final DateTime firstDate = DateTime(1950);
    final DateTime lastDate = DateTime(now.year + 10);
    // Open on the date already held by the field, otherwise today. Dates loaded
    // from the donor record are clamped into range: showDatePicker asserts if
    // initialDate falls outside firstDate/lastDate.
    DateTime initialDate = _parseDateFlexible(controller.text) ?? now;
    if (initialDate.isBefore(firstDate)) initialDate = firstDate;
    if (initialDate.isAfter(lastDate)) initialDate = lastDate;
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
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
    return userTypeName.trim();
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
    final int? editingIndex = _editingDependentIndex;

    setState(() {
      if (editingIndex != null && editingIndex < _dependents.length) {
        // copyWith so fields not shown in the form (relationID, donorID,
        // createdOn/By, fromServer) survive an edit.
        _dependents[editingIndex] = _dependents[editingIndex].copyWith(
          relationName: name,
          relationshipToDonor: relationship,
          relationBirthDate: _parseDateFlexible(
            _dependentBirthDateController.text,
          ),
          overwriteBirthDate: true,
          relationAge: _dependentAgeController.text.trim(),
          modifiedOn: now,
          modifiedBy: 'mobile-app',
        );
      } else {
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
      }

      _editingDependentIndex = null;
      _dependentNameController.clear();
      _dependentRelationshipController.clear();
      _dependentBirthDateController.clear();
      _dependentAgeController.clear();
    });
  }

  void _startEditDependent(int index) {
    if (index < 0 || index >= _dependents.length) return;
    final _DependentDraft dependent = _dependents[index];

    setState(() {
      _editingDependentIndex = index;
      _dependentsExpanded = true;
      _dependentNameController.text = dependent.relationName;
      _dependentRelationshipController.text = dependent.relationshipToDonor;
      _dependentAgeController.text = dependent.relationAge;
      final DateTime? birthDate = dependent.relationBirthDate;
      _dependentBirthDateController.text = birthDate == null
          ? ''
          : '${birthDate.day.toString().padLeft(2, '0')}/'
              '${birthDate.month.toString().padLeft(2, '0')}/'
              '${birthDate.year}';
    });
  }

  void _cancelEditDependent() {
    setState(() {
      _editingDependentIndex = null;
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

  Future<void> _removeDependentAt(int index) async {
    if (index < 0 || index >= _dependents.length) return;
    final _DependentDraft target = _dependents[index];
    // Don't key this off relationID: the donor GET response does not always
    // populate it, and a missing ID would silently downgrade the soft delete
    // into a drop-from-list, which the backend never sees.
    final bool existsOnServer = target.fromServer || target.relationID > 0;

    final String label = target.relationName.trim().isEmpty
        ? 'this dependent'
        : target.relationName.trim();

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Delete dependent?'),
          content: Text(
            'Are you sure you want to delete $label? '
            'This will be removed when you update the donor.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textGrey),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;
    // Re-check bounds: the list index was captured before the dialog await.
    if (index >= _dependents.length) return;

    setState(() {
      if (existsOnServer) {
        // Soft delete: keep it in the payload flagged as deleted so the
        // backend removes the saved record. Hidden from the list below.
        _dependents[index] = target.copyWith(
          deleted: true,
          modifiedOn: DateTime.now().toUtc(),
          modifiedBy: 'mobile-app',
        );
      } else {
        // Never saved, so there is nothing for the backend to delete.
        _dependents.removeAt(index);
      }

      if (_editingDependentIndex == index) {
        _editingDependentIndex = null;
        _dependentNameController.clear();
        _dependentRelationshipController.clear();
        _dependentBirthDateController.clear();
        _dependentAgeController.clear();
      } else if (!existsOnServer &&
          _editingDependentIndex != null &&
          _editingDependentIndex! > index) {
        _editingDependentIndex = _editingDependentIndex! - 1;
      }
    });
  }

  void _clearIdentityDocumentControllers() {
    _aadharController.clear();
    _panController.clear();
    _passportController.clear();
    _voterIdController.clear();
    _drivingLicenceController.clear();
    _gstNumberController.clear();
    _tanNumberController.clear();
    _udyamNumberController.clear();
    _tradeLicenseController.clear();
    _registrationNumberController.clear();
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
      case 'GST Number':
        return _gstNumberController;
      case 'TAN Number':
        return _tanNumberController;
      case 'Udyam Number':
        return _udyamNumberController;
      case 'Trade License Number':
        return _tradeLicenseController;
      case 'Registration Number':
        return _registrationNumberController;
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
      case 'GST Number':
        return 'GST Number';
      case 'TAN Number':
        return 'TAN Number';
      case 'Udyam Number':
        return 'Udyam Number';
      case 'Trade License Number':
        return 'Trade License Number';
      case 'Registration Number':
        return 'Registration Number';
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
  bool get _isIndividualDonor => _selectedDonorType == 1;
  bool get _isOrganizationDonor => _selectedDonorType == 2;

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
    // Determine role IDs based on userTypeID
    // 1 = Area Leader, 2 = Promotion Staff, 3 = Field Staff, 4 = Local Unit
    final int userTypeID = user?.userTypeID ?? 0;
    final int currentUserId = user?.userID ?? 0;
    final int areaLeaderId = userTypeID == 1 ? currentUserId : 0;
    final int promotionStaffId = userTypeID == 2 ? currentUserId : 0;
    final int fieldStaffId = userTypeID == 3 ? currentUserId : 0;
    final int localMemberId = userTypeID == 4 ? currentUserId : 0;

    final List<Map<String, dynamic>> dependentsPayload =
        _dependents.map((d) => d.toJson()).toList();

    return <String, dynamic>{
      'donorID': widget.donorId ?? 0,
      'donorName': _donorNameController.text.trim(),
      'salutation': _isOrganizationDonor ? '' : _selectedTitle.trim(),
      // Individual identity docs
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
      // Org identity docs
      'gstNumber': _selectedIdentityDoc == 'GST Number'
          ? _gstNumberController.text.trim()
          : '',
      'tanNumber': _selectedIdentityDoc == 'TAN Number'
          ? _tanNumberController.text.trim()
          : '',
      'udyamNumber': _selectedIdentityDoc == 'Udyam Number'
          ? _udyamNumberController.text.trim()
          : '',
      'tradeLicenseNumber': _selectedIdentityDoc == 'Trade License Number'
          ? _tradeLicenseController.text.trim()
          : '',
      'registrationNumber': _selectedIdentityDoc == 'Registration Number'
          ? _registrationNumberController.text.trim()
          : '',
      'birthDate': _isOrganizationDonor
          ? null
          : _toApiDateString(_parseDateFlexible(_birthDateController.text)),
      'marriageDate':
          (_isIndividualDonor && _selectedMaritalStatus == 'Married')
              ? _toApiDateString(
                  _parseDateFlexible(_weddingDateController.text),
                )
              : null,
      'gender': _isOrganizationDonor ? '' : (_selectedGender ?? '').trim(),
      'maritalStatus':
          _isOrganizationDonor ? '' : (_selectedMaritalStatus ?? '').trim(),
      'regionID': donor?.regionId ?? 0,
      'areaID': _selectedAreaId,
      'areaName': _areaOptions
          .firstWhere(
            (a) => a.areaId == _selectedAreaId,
            orElse: () => const AreaOption(areaId: 0, areaName: ''),
          )
          .areaName
          .trim(),
      'areaLeaderID': areaLeaderId,
      'promotionStaffID': promotionStaffId,
      'fieldStaffID': fieldStaffId,
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
      'country': (_selectedCountry ?? '').trim(),
      'organization':
          _isOrganizationDonor ? _donorNameController.text.trim() : '',
      'contactPersonName':
          _isOrganizationDonor ? _contactPersonNameController.text.trim() : '',
      'address': _flatBuildingController.text.trim(),
      'addressLine2': _addressController.text.trim(),
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
      'dependents': _isOrganizationDonor
          ? <Map<String, dynamic>>[]
          : dependentsPayload,
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

    if ((_isIndividualDonor &&
            (_selectedGender == null || _selectedMaritalStatus == null)) ||
        _selectedState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isIndividualDonor
                ? 'Select gender, marital status, and state to continue.'
                : 'Select state to continue.',
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
      Navigator.of(context).pop(true);
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
        onDependent: _isOrganizationDonor ? null : _openDependent,
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
                        readOnly: true,
                      ),
                      const SizedBox(height: 14),
                      IgnorePointer(
                        ignoring: !_hasSelectedDonorType,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 180),
                          opacity: _hasSelectedDonorType ? 1 : 0.45,
                          child: Column(
                            children: [
                              if (_isOrganizationDonor)
                                _OutlinedTextField(
                                  controller: _donorNameController,
                                  label: 'Organization Name',
                                  icon: Icons.business_rounded,
                                  validator: (value) => _requiredValidator(
                                    value,
                                    'Organization name is required',
                                  ),
                                )
                              else
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
                              if (_selectedIdentityDoc != null &&
                                  _selectedIdentityDoc != 'NaN') ...[
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
                              if (!_isOrganizationDonor) ...[
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
                            controller: _districtController,
                            label: 'District',
                            icon: Icons.location_on_outlined,
                          ),
                          const SizedBox(height: 14),
                          _OutlinedTextField(
                            controller: _pincodeController,
                            label: 'Pincode',
                            icon: Icons.local_post_office_outlined,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                          const SizedBox(height: 14),
                          _DropdownField(
                            value: _selectedState,
                            label: _loadingStates ? 'Loading States...' : 'State',
                            items: {
                              if (_selectedState != null) _selectedState!,
                              ..._stateOptions.map((s) => s.stateName.trim()),
                            }.where((item) => item.isNotEmpty).toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _selectedState = value;
                                _updateCombinedAddress();
                              });
                            },
                          ),
                          const SizedBox(height: 14),
                          _DropdownField(
                            value: _selectedCountry,
                            label: _loadingCountries
                                ? 'Loading Countries...'
                                : 'Country',
                            items: {
                              if (_selectedCountry != null) _selectedCountry!,
                              ..._countryOptions.map((c) => c.countryName.trim()),
                            }.where((item) => item.isNotEmpty).toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _selectedCountry = value;
                                _updateCombinedAddress();
                              });
                            },
                          ),
                          const SizedBox(height: 14),
                          _OutlinedTextField(
                            controller: _addressController,
                            label: _isOrganizationDonor
                                ? 'Contact Address'
                                : 'Address',
                            icon: Icons.home_rounded,
                            maxLines: null,
                          ),
                          if (_isOrganizationDonor) ...[
                            const SizedBox(height: 14),
                            _OutlinedTextField(
                              controller: _contactPersonNameController,
                              label: 'Contact Person Name',
                              icon: Icons.person_outline_rounded,
                              validator: (value) => _requiredValidator(
                                value,
                                'Contact person name is required',
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          _OutlinedTextField(
                            controller: _mobileController,
                            label: _isOrganizationDonor
                                ? 'Contact Mobile *'
                                : 'Mobile *',
                            icon: Icons.phone_android_rounded,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              final String? error = _requiredValidator(
                                value,
                                'Mobile number is required',
                              );
                              if (error != null) return error;
                              if ((value ?? '').trim().length < 10) {
                                return 'Mobile number must have 10 digits';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          _OutlinedTextField(
                            controller: _whatsAppController,
                            label: _isOrganizationDonor
                                ? 'Contact WhatsApp No'
                                : 'WhatsApp No',
                            icon: Icons.message_outlined,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                          const SizedBox(height: 14),
                          _OutlinedTextField(
                            controller: _emailController,
                            label:
                                _isOrganizationDonor ? 'Contact Email' : 'Email',
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
                if (!_isOrganizationDonor) ...[
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (_editingDependentIndex != null) ...[
                                OutlinedButton(
                                  onPressed: _cancelEditDependent,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.textGrey,
                                    side: const BorderSide(
                                      color: AppColors.borderGrey,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text('Cancel'),
                                ),
                                const SizedBox(width: 10),
                              ],
                              ElevatedButton.icon(
                                onPressed: _addDependentDraft,
                                icon: Icon(
                                  _editingDependentIndex == null
                                      ? Icons.add_rounded
                                      : Icons.check_rounded,
                                ),
                                label: Text(
                                  _editingDependentIndex == null
                                      ? 'Add Dependent'
                                      : 'Update Dependent',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.statusBarPink,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_dependents.any((d) => !d.deleted)) ...[
                            const SizedBox(height: 14),
                            for (int index = 0;
                                index < _dependents.length;
                                index++)
                              if (!_dependents[index].deleted)
                                _DependentTile(
                                  dependent: _dependents[index],
                                  isEditing: _editingDependentIndex == index,
                                  onEdit: () => _startEditDependent(index),
                                  onRemove: () => _removeDependentAt(index),
                                ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                ],
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
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final VoidCallback? onTap;
  final bool readOnly;
  final TextCapitalization textCapitalization;
  final int? maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines,
      maxLength: maxLength,
      buildCounter: maxLength == null
          ? null
          : (context, {required currentLength, required isFocused, maxLength}) =>
              null,
      inputFormatters: inputFormatters,
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
    this.fromServer = false,
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

  /// True when this row came from the donor GET response, i.e. it exists
  /// server-side and must be soft-deleted (deleted: true) rather than dropped.
  final bool fromServer;

  _DependentDraft copyWith({
    String? relationName,
    String? relationshipToDonor,
    DateTime? relationBirthDate,
    // Without this, passing a null relationBirthDate would silently keep the
    // old value, so clearing the date in the form would never stick.
    bool overwriteBirthDate = false,
    String? relationAge,
    bool? deleted,
    DateTime? modifiedOn,
    String? modifiedBy,
  }) {
    return _DependentDraft(
      relationID: relationID,
      donorID: donorID,
      relationName: relationName ?? this.relationName,
      relationshipToDonor: relationshipToDonor ?? this.relationshipToDonor,
      relationBirthDate: overwriteBirthDate
          ? relationBirthDate
          : (relationBirthDate ?? this.relationBirthDate),
      relationAge: relationAge ?? this.relationAge,
      deleted: deleted ?? this.deleted,
      createdOn: createdOn,
      createdBy: createdBy,
      modifiedOn: modifiedOn ?? this.modifiedOn,
      modifiedBy: modifiedBy ?? this.modifiedBy,
      fromServer: fromServer,
    );
  }

  Map<String, dynamic> toJson() {
    final DateTime? birthDate = relationBirthDate;
    return <String, dynamic>{
      'relationID': relationID,
      'donorID': donorID,
      'relationName': relationName,
      // Send the picked calendar date as UTC midnight. Using toUtc() on a
      // local midnight shifts the date back a day in positive-offset zones
      // (e.g. IST 04/08 00:00 -> 03/08 18:30Z).
      'relationBirthDate': birthDate == null
          ? null
          : DateTime.utc(
              birthDate.year,
              birthDate.month,
              birthDate.day,
            ).toIso8601String(),
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
  const _DependentTile({
    required this.dependent,
    required this.onRemove,
    required this.onEdit,
    this.isEditing = false,
  });

  final _DependentDraft dependent;
  final VoidCallback onRemove;
  final VoidCallback onEdit;
  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isEditing ? AppColors.softPurple : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEditing ? AppColors.primaryPurple : AppColors.borderGrey,
          width: isEditing ? 1.4 : 1,
        ),
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
            tooltip: 'Edit',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, color: AppColors.iconPurple),
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

  /// Show about 5 rows, then scroll, so long lists (titles, states, countries)
  /// don't open a menu that covers the whole screen.
  static const double _menuMaxHeight = (kMinInteractiveDimension * 5) + 16;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      menuMaxHeight: _menuMaxHeight,
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
    this.readOnly = false,
  });

  final int? value;
  final ValueChanged<int> onChanged;
  final bool readOnly;

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
                  onTap: readOnly ? null : () => onChanged(1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DonorTypeOption(
                  label: 'Others',
                  selected: value == 2,
                  onTap: readOnly ? null : () => onChanged(2),
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
  final VoidCallback? onTap;

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
    required this.onBack,
    this.onDependent,
  });

  final VoidCallback onUpdate;
  final VoidCallback onPhoto;
  final VoidCallback? onDependent;
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
            if (onDependent != null)
              _BottomAction(
                label: 'Dependent',
                icon: Icons.person_add_alt_1_outlined,
                onTap: onDependent!,
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
