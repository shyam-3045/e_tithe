import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../../common/constants/api_config.dart';
import '../../common/constants/api_endpoints.dart';
import '../../common/constants/app_colors.dart';
import '../../common/services/auth_service.dart';
import '../../common/services/region_service.dart';
import '../../common/widgets/common_alert.dart';

class NewDonorPage extends StatefulWidget {
  const NewDonorPage({super.key});

  @override
  State<NewDonorPage> createState() => _NewDonorPageState();
}

class _NewDonorPageState extends State<NewDonorPage> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  final _donorNameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _weddingDateController = TextEditingController();
  final _aadharController = TextEditingController();
  final _panController = TextEditingController();
  final _flatBuildingController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _districtController = TextEditingController();
  final _mobileController = TextEditingController();
  final _whatsAppController = TextEditingController();
  final _emailController = TextEditingController();

  // Dependents (inline section)
  final _dependentNameController = TextEditingController();
  final _dependentRelationshipController = TextEditingController();
  final _dependentBirthDateController = TextEditingController();
  final _dependentAgeController = TextEditingController();
  final List<_DependentDraft> _dependents = <_DependentDraft>[];

  bool _personalExpanded = true;
  bool _addressExpanded = true;
  bool _dependentsExpanded = true;

  bool _saving = false;
  late Future<List<RegionOption>> _regionsFuture;

  XFile? _selectedPhoto;
  Uint8List? _selectedPhotoBytes;

  String? _selectedTitle = 'Mr.';
  String? _selectedGender = 'Male';
  String? _selectedMaritalStatus = 'Married';
  String? _selectedMembership = 'Member';
  String? _selectedArea;
  int? _selectedRegionId;
  String? _selectedState = 'Andaman Nicobar';

  static const List<String> _titles = ['Mr.', 'Mrs.', 'Ms.', 'Dr.'];
  static const List<String> _genders = ['Male', 'Female', 'Other'];
  static const List<String> _maritalStatuses = ['Married', 'Single', 'Other'];
  static const List<String> _membershipOptions = ['Member', 'Non-Member'];
  static const List<String> _areas = [
    'Select Area',
    'Central Zone',
    'East Zone',
    'North Zone',
    'South Zone',
    'West Zone',
  ];
  static const List<String> _states = [
    'Andaman Nicobar',
    'Andhra Pradesh',
    'Delhi',
    'Karnataka',
    'Maharashtra',
    'Odisha',
    'Tamil Nadu',
    'West Bengal',
  ];

  @override
  void initState() {
    super.initState();
    _regionsFuture = RegionService.instance.fetchRegions();
  }

  @override
  void dispose() {
    _donorNameController.dispose();
    _birthDateController.dispose();
    _weddingDateController.dispose();
    _aadharController.dispose();
    _panController.dispose();
    _flatBuildingController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _districtController.dispose();
    _mobileController.dispose();
    _whatsAppController.dispose();
    _emailController.dispose();

    _dependentNameController.dispose();
    _dependentRelationshipController.dispose();
    _dependentBirthDateController.dispose();
    _dependentAgeController.dispose();

    super.dispose();
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

    if (pickedDate == null) {
      return;
    }

    setState(() {
      controller.text =
          '${pickedDate.day.toString().padLeft(2, '0')}/'
          '${pickedDate.month.toString().padLeft(2, '0')}/'
          '${pickedDate.year}';
    });
  }

  DateTime? _parseUiDate(String input) {
    final String text = input.trim();
    if (text.isEmpty) return null;

    // UI format used in this screen: dd/MM/yyyy
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

  void _addDependentDraft() {
    final name = _dependentNameController.text.trim();
    final relationship = _dependentRelationshipController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dependent name is required.')),
      );
      return;
    }

    final DateTime now = DateTime.now().toUtc();

    setState(() {
      _dependents.add(
        _DependentDraft(
          relationID: 0,
          donorID: 0,
          relationName: name,
          relationshipToDonor: relationship,
          relationAge: _dependentAgeController.text.trim(),
          relationBirthDate: _parseUiDate(_dependentBirthDateController.text),
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

  void _removeDependentAt(int index) {
    setState(() {
      _dependents.removeAt(index);
    });
  }

  Map<String, dynamic> _buildDonorPayload() {
    final DateTime now = DateTime.now().toUtc();

    return <String, dynamic>{
      'donorID': 0,
      'donorName': _donorNameController.text.trim(),
      'photo': _selectedPhoto?.name ?? '',
      'panNumber': _panController.text.trim(),
      'aadhaarNumber': _aadharController.text.trim(),
      'birthDate': _toApiDateString(_parseUiDate(_birthDateController.text)),
      'marriageDate': (_selectedMaritalStatus == 'Married')
          ? _toApiDateString(_parseUiDate(_weddingDateController.text))
          : null,
      'gender': (_selectedGender ?? '').trim(),
      'maritalStatus': (_selectedMaritalStatus ?? '').trim(),
      'regionID': _selectedRegionId ?? 0,
      'areaID': 0,
      'areaLeaderID': 0,
      'promotionStaffID': 0,
      'mobile': _mobileController.text.trim(),
      'whatsAppNumber': _whatsAppController.text.trim(),
      'email': _emailController.text.trim(),
      'street': _streetController.text.trim(),
      'village': _flatBuildingController.text.trim(),
      'city': _cityController.text.trim(),
      'district': _districtController.text.trim(),
      'state': (_selectedState ?? '').trim(),
      'pincode': _pincodeController.text.trim(),
      'isActive': true,
      'deleted': false,
      'createdOn': now.toIso8601String(),
      'createdBy': 'mobile-app',
      'modifiedOn': now.toIso8601String(),
      'modifiedBy': 'mobile-app',
      'dependents': _dependents.map((d) => d.toJson()).toList(),
    };
  }

  Future<http.Response> _submitDonor(Map<String, dynamic> payload) async {
    final Uri uri = ApiConfig.uri(ApiEndpoints.donor);
    final Map<String, String> headers = await AuthService.instance
        .authenticatedJsonHeaders();
    headers.remove('Content-Type');

    final http.MultipartRequest request = http.MultipartRequest('POST', uri)
      ..headers.addAll(headers);

    payload.forEach((String key, dynamic value) {
      if (value == null) {
        return;
      }
      request.fields[key] = _stringifyFormValue(value);
    });

    final Uint8List? photoBytes = _selectedPhotoBytes;
    final XFile? photoFile = _selectedPhoto;
    if (photoBytes != null && photoFile != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'photoFile',
          photoBytes,
          filename: photoFile.name,
          contentType: _getMimeType(photoFile.name),
        ),
      );
    }

    final http.StreamedResponse streamedResponse = await request.send();
    return http.Response.fromStream(streamedResponse);
  }

  String _stringifyFormValue(Object value) {
    if (value is String) {
      return value;
    }

    if (value is num || value is bool) {
      return value.toString();
    }

    if (value is Map || value is List) {
      return jsonEncode(value);
    }

    return value.toString();
  }

  MediaType _getMimeType(String filename) {
    final String lowerName = filename.toLowerCase();
    if (lowerName.endsWith('.jpg') || lowerName.endsWith('.jpeg')) {
      return MediaType('image', 'jpeg');
    }
    if (lowerName.endsWith('.png')) {
      return MediaType('image', 'png');
    }
    if (lowerName.endsWith('.gif')) {
      return MediaType('image', 'gif');
    }
    if (lowerName.endsWith('.webp')) {
      return MediaType('image', 'webp');
    }
    return MediaType('image', 'jpeg');
  }

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();

    if (_saving) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saving... please wait.')));
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Saving donor...')));

    if (!_formKey.currentState!.validate()) {
      setState(() {
        _personalExpanded = true;
        _addressExpanded = true;
        _dependentsExpanded = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final payload = _buildDonorPayload();
      final Uri uri = ApiConfig.uri(ApiEndpoints.donor);
      print('[API] URL: $uri');
      print(
        '[API] Payload: Creating donor with photo (photo size: ${_selectedPhotoBytes?.length ?? 0} bytes)',
      );

      final response = await _submitDonor(payload);
      print('[API] Response: ${response.statusCode}');

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Donor saved successfully.')),
        );
        return;
      }

      await CommonAlert.showInfo(
        context,
        title: 'Save failed',
        message:
            'Status: ${response.statusCode}\n\n${response.body.isEmpty ? 'No response body' : response.body}',
      );
    } catch (e) {
      if (!mounted) return;

      final String hint = "Error in calling api";

      await CommonAlert.showInfo(
        context,
        title: 'Network error',
        message: '${e.toString()}\n\n$hint',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
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

  void _handleFind() {
    // TODO(API): Implement donor search/find workflow.
    CommonAlert.showInfo(
      context,
      title: 'Find',
      message: 'Find flow can be connected here.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Donor')),
      bottomNavigationBar: _BottomActionBar(
        onSave: _handleSave,
        onPhoto: _handlePhoto,
        onFind: _handleFind,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionCard(
                  title: 'Personal Details',
                  isExpanded: _personalExpanded,
                  onToggle: () {
                    setState(() {
                      _personalExpanded = !_personalExpanded;
                    });
                  },
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _DropdownField<String>(
                              value: _selectedTitle,
                              items: _titles,
                              icon: Icons.arrow_drop_down_rounded,
                              onChanged: (value) {
                                setState(() {
                                  _selectedTitle = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 5,
                            child: _StyledTextField(
                              controller: _donorNameController,
                              label: 'Donor Name',
                              icon: Icons.person_rounded,
                              isRequired: true,
                              validator: (value) => _requiredValidator(
                                value,
                                'Donor name is required',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _PhotoPickerCard(
                        imageBytes: _selectedPhotoBytes,
                        label: _selectedPhoto?.name,
                        onTap: _handlePhoto,
                      ),
                      const SizedBox(height: 16),
                      _ChoiceGroup(
                        label: 'Gender',
                        value: _selectedGender!,
                        options: _genders,
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _StyledTextField(
                        controller: _birthDateController,
                        label: 'Birth Date',
                        icon: Icons.calendar_month_rounded,
                        readOnly: true,
                        onTap: () => _pickDate(_birthDateController),
                      ),
                      const SizedBox(height: 16),
                      _ChoiceGroup(
                        label: 'Marital Status',
                        value: _selectedMaritalStatus!,
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
                        const SizedBox(height: 16),
                        _StyledTextField(
                          controller: _weddingDateController,
                          label: 'Wedding Date',
                          icon: Icons.event_rounded,
                          readOnly: true,
                          onTap: () => _pickDate(_weddingDateController),
                        ),
                      ],
                      const SizedBox(height: 16),
                      _ChoiceGroup(
                        label: 'Membership',
                        value: _selectedMembership!,
                        options: _membershipOptions,
                        onChanged: (value) {
                          setState(() {
                            _selectedMembership = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _StyledTextField(
                        controller: _aadharController,
                        label: 'Aadhar No',
                        icon: Icons.badge_outlined,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      _StyledTextField(
                        controller: _panController,
                        label: 'PAN',
                        icon: Icons.credit_card_rounded,
                        textCapitalization: TextCapitalization.characters,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _SectionCard(
                  title: 'Address Details',
                  isExpanded: _addressExpanded,
                  onToggle: () {
                    setState(() {
                      _addressExpanded = !_addressExpanded;
                    });
                  },
                  child: Column(
                    children: [
                      _DropdownField<String>(
                        value: _selectedArea,
                        hintText: 'Select Area',
                        items: _areas.skip(1).toList(),
                        icon: Icons.place_outlined,
                        isRequired: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Area is required';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          setState(() {
                            _selectedArea = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder<List<RegionOption>>(
                        future: _regionsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                  ),
                                ),
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppColors.borderGrey),
                              ),
                              child: Text(
                                'Unable to load regions: ${snapshot.error}',
                                style: const TextStyle(
                                  color: AppColors.textGrey,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }

                          final List<RegionOption> regions =
                              snapshot.data ?? [];
                          final Map<int, String> regionLabels = {
                            for (final region in regions)
                              region.regionId: region.regionName,
                          };

                          if (regions.isEmpty) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppColors.borderGrey),
                              ),
                              child: const Text(
                                'No regions available.',
                                style: TextStyle(
                                  color: AppColors.textGrey,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }

                          return _DropdownField<int>(
                            value: _selectedRegionId,
                            hintText: 'Select Region',
                            items: regions
                                .map((region) => region.regionId)
                                .toList(),
                            icon: Icons.public_rounded,
                            isRequired: true,
                            validator: (value) {
                              if (value == null || value <= 0) {
                                return 'Region is required';
                              }
                              return null;
                            },
                            itemLabelBuilder: (value) =>
                                regionLabels[value] ?? value.toString(),
                            onChanged: (value) {
                              setState(() {
                                _selectedRegionId = value;
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _StyledTextField(
                        controller: _flatBuildingController,
                        label: 'Flat/Building',
                        icon: Icons.apartment_rounded,
                        isRequired: true,
                        validator: (value) => _requiredValidator(
                          value,
                          'Flat/Building is required',
                        ),
                      ),
                      const SizedBox(height: 16),
                      _StyledTextField(
                        controller: _streetController,
                        label: 'Street/Avenue',
                        icon: Icons.signpost_outlined,
                      ),
                      const SizedBox(height: 16),
                      _StyledTextField(
                        controller: _cityController,
                        label: 'City',
                        icon: Icons.location_city_rounded,
                        isRequired: true,
                        validator: (value) =>
                            _requiredValidator(value, 'City is required'),
                      ),
                      const SizedBox(height: 16),
                      _StyledTextField(
                        controller: _pincodeController,
                        label: 'Pincode',
                        icon: Icons.markunread_mailbox_rounded,
                        isRequired: true,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final String? error = _requiredValidator(
                            value,
                            'Pincode is required',
                          );
                          if (error != null) {
                            return error;
                          }
                          if ((value ?? '').trim().length < 6) {
                            return 'Enter a valid pincode';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _StyledTextField(
                        controller: _districtController,
                        label: 'District',
                        icon: Icons.location_on_outlined,
                        isRequired: true,
                        validator: (value) =>
                            _requiredValidator(value, 'District is required'),
                      ),
                      const SizedBox(height: 16),
                      _DropdownField<String>(
                        value: _selectedState,
                        items: _states,
                        icon: Icons.map_outlined,
                        onChanged: (value) {
                          setState(() {
                            _selectedState = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _StyledTextField(
                        controller: _mobileController,
                        label: 'Mobile',
                        icon: Icons.phone_android_rounded,
                        isRequired: true,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          final String? error = _requiredValidator(
                            value,
                            'Mobile number is required',
                          );
                          if (error != null) {
                            return error;
                          }
                          if ((value ?? '').trim().length < 10) {
                            return 'Enter a valid mobile number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _StyledTextField(
                        controller: _whatsAppController,
                        label: 'WhatsApp No',
                        icon: Icons.message_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      _StyledTextField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          final String input = (value ?? '').trim();
                          if (input.isEmpty) {
                            return null;
                          }
                          final bool isValid = RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          ).hasMatch(input);
                          return isValid ? null : 'Enter a valid email';
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _SectionCard(
                  title: 'Dependent Details',
                  isExpanded: _dependentsExpanded,
                  onToggle: () {
                    setState(() {
                      _dependentsExpanded = !_dependentsExpanded;
                    });
                  },
                  child: Column(
                    children: [
                      _StyledTextField(
                        controller: _dependentNameController,
                        label: 'Dependent Name',
                        icon: Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: 16),
                      _StyledTextField(
                        controller: _dependentRelationshipController,
                        label: 'Relationship To Donor',
                        icon: Icons.family_restroom_outlined,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _StyledTextField(
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
                            child: _StyledTextField(
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
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _requiredValidator(String? value, String message) {
    if ((value ?? '').trim().isEmpty) {
      return message;
    }
    return null;
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
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
            color: AppColors.deepPurple.withValues(alpha: 0.06),
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

class _StyledTextField extends StatelessWidget {
  const _StyledTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
    this.keyboardType,
    this.onTap,
    this.readOnly = false,
    this.isRequired = false,
    this.textCapitalization = TextCapitalization.words,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool isRequired;
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
      style: const TextStyle(
        color: AppColors.textDark,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      decoration: _fieldDecoration(
        label: label,
        icon: icon,
        isRequired: isRequired,
        suffixIcon: readOnly
            ? const Icon(
                Icons.calendar_today_rounded,
                color: AppColors.iconPurple,
              )
            : null,
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.items,
    required this.icon,
    required this.onChanged,
    this.value,
    this.hintText,
    this.validator,
    this.isRequired = false,
    this.itemLabelBuilder,
  });

  final T? value;
  final List<T> items;
  final IconData icon;
  final ValueChanged<T?> onChanged;
  final String? hintText;
  final String? Function(T?)? validator;
  final bool isRequired;
  final String Function(T value)? itemLabelBuilder;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      validator: validator,
      decoration: _fieldDecoration(
        label: hintText ?? '',
        icon: icon,
        isRequired: isRequired,
      ),
      hint: hintText == null
          ? null
          : Text(
              hintText!,
              style: const TextStyle(color: AppColors.textGrey, fontSize: 16),
            ),
      dropdownColor: AppColors.surface,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.textGrey,
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(
                itemLabelBuilder?.call(item) ?? '$item',
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
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
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

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
                    width: 150,
                    child: RadioListTile<String>(
                      value: option,
                      groupValue: value,
                      contentPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      activeColor: AppColors.statusBarPink,
                      title: Text(
                        option,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onChanged: (selected) {
                        if (selected != null) {
                          onChanged(selected);
                        }
                      },
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

class _PhotoPickerCard extends StatelessWidget {
  const _PhotoPickerCard({
    required this.imageBytes,
    required this.onTap,
    this.label,
  });

  final Uint8List? imageBytes;
  final String? label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Widget preview = imageBytes == null
        ? Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: AppColors.lavender.withOpacity(0.55),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AppColors.primaryPurple,
              size: 42,
            ),
          )
        : ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.memory(
              imageBytes!,
              width: 84,
              height: 84,
              fit: BoxFit.cover,
            ),
          );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.borderGrey),
        ),
        child: Row(
          children: [
            preview,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Photo',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label == null || label!.trim().isEmpty
                        ? 'Tap to take a photo or pick from gallery'
                        : label!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.photo_camera_outlined,
              color: AppColors.iconPurple,
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.onSave,
    required this.onPhoto,
    required this.onFind,
    required this.onBack,
  });

  final VoidCallback onSave;
  final VoidCallback onPhoto;
  final VoidCallback onFind;
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
              label: 'Save',
              icon: Icons.save_outlined,
              onTap: onSave,
            ),
            _BottomAction(
              label: 'Photo',
              icon: Icons.photo_camera_outlined,
              onTap: onPhoto,
            ),
            _BottomAction(
              label: 'Find',
              icon: Icons.location_on_outlined,
              onTap: onFind,
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

InputDecoration _fieldDecoration({
  required String label,
  required IconData icon,
  Widget? suffixIcon,
  bool isRequired = false,
}) {
  final String displayLabel = isRequired ? '$label *' : label;

  return InputDecoration(
    labelText: displayLabel.isEmpty ? null : displayLabel,
    floatingLabelBehavior: FloatingLabelBehavior.auto,
    labelStyle: const TextStyle(
      color: AppColors.textGrey,
      fontSize: 15,
      fontWeight: FontWeight.w600,
    ),
    filled: true,
    fillColor: AppColors.surface,
    prefixIcon: Icon(icon, color: AppColors.iconPurple),
    suffixIcon: suffixIcon,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: AppColors.borderGrey, width: 1.2),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: AppColors.primaryPurple, width: 1.6),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
  );
}
