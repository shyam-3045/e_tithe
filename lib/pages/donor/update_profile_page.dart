import 'package:flutter/material.dart';

import '../../common/constants/app_colors.dart';
import '../../common/widgets/common_alert.dart';
import 'dependent_page.dart';

class UpdateProfilePage extends StatefulWidget {
  const UpdateProfilePage({super.key, required this.donorName});

  final String donorName;

  @override
  State<UpdateProfilePage> createState() => _UpdateProfilePageState();
}

class _UpdateProfilePageState extends State<UpdateProfilePage> {
  final _formKey = GlobalKey<FormState>();

  // Personal
  final _donorNameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _weddingDateController = TextEditingController();
  final _aadharController = TextEditingController();
  final _panController = TextEditingController();

  // Address
  final _flatBuildingController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _districtController = TextEditingController();
  final _mobileController = TextEditingController();
  final _whatsAppController = TextEditingController();
  final _emailController = TextEditingController();

  bool _personalExpanded = true;
  bool _addressExpanded = false;

  String _selectedTitle = 'Mr.';
  String _selectedGender = 'Male';
  String _selectedMaritalStatus = 'Married';
  String _selectedMembership = 'Member';
  String _selectedArea = 'Balangir';
  String _selectedState = 'Odisha';

  static const List<String> _titles = ['Mr.', 'Mrs.', 'Ms.', 'Dr.'];
  static const List<String> _genders = ['Male', 'Female', 'Other'];
  static const List<String> _maritalStatuses = ['Married', 'Single', 'Other'];
  static const List<String> _membershipOptions = ['Member', 'Non-Member'];
  static const List<String> _areas = [
    'Balangir',
    'Bhubaneswar',
    'Cuttack',
    'Sambalpur',
  ];
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

    // TODO(API): Load donor details by donor id/name and prefill the controllers.
    // _loadDonorFromApi();

    // Prefill sample values to match the screenshot feel.
    _flatBuildingController.text = 'Balangir';
    _streetController.text = 'Balangir';
    _cityController.text = 'Northern Division';
    _pincodeController.text = '767001';
    _districtController.text = 'Bolangir';
    _mobileController.text = '9692962159';
    _whatsAppController.text = '9437225071';
    _emailController.text = 'ranjan@gmail.com';
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
      controller.text =
          '${pickedDate.day.toString().padLeft(2, '0')}/'
          '${pickedDate.month.toString().padLeft(2, '0')}/'
          '${pickedDate.year}';
    });
  }

  void _handleUpdate() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    // TODO(API): Call update donor API here.
    // Use controllers/dropdown/radio values to build payload.
    // await _saveUpdateToApi();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('UI is ready. Hook update API in _handleUpdate().'),
      ),
    );
  }

  void _handlePhoto() {
    // TODO(API): Implement photo capture/upload flow.
    CommonAlert.showInfo(
      context,
      title: 'Photo',
      message: 'Photo flow can be connected here.',
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

  void _openDependent() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DependentPage(donorName: _donorNameController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update Donor')),
      bottomNavigationBar: _BottomActionBar(
        onUpdate: _handleUpdate,
        onPhoto: _handlePhoto,
        onFind: _handleFind,
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
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final bool compact = constraints.maxWidth < 420;

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
                          onTap: () => _pickDate(_weddingDateController),
                        ),
                      ],
                      const SizedBox(height: 14),
                      _ChoiceGroup(
                        label: 'Membership',
                        value: _selectedMembership,
                        options: _membershipOptions,
                        onChanged: (value) {
                          setState(() {
                            _selectedMembership = value;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      _OutlinedTextField(
                        controller: _aadharController,
                        label: 'Aadhar No',
                        icon: Icons.credit_card_rounded,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 14),
                      _OutlinedTextField(
                        controller: _panController,
                        label: 'PAN',
                        icon: Icons.badge_outlined,
                        textCapitalization: TextCapitalization.characters,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _SectionPanel(
                  title: 'Address Details',
                  isExpanded: _addressExpanded,
                  onToggle: () {
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
                        items: _areas,
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _selectedArea = value);
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

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.label,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final String label;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: _OutlinedTextField._inputDecoration(
        label,
        Icons.arrow_drop_down,
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

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.onUpdate,
    required this.onPhoto,
    required this.onFind,
    required this.onDependent,
    required this.onBack,
  });

  final VoidCallback onUpdate;
  final VoidCallback onPhoto;
  final VoidCallback onFind;
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
              label: 'Find',
              icon: Icons.location_on_outlined,
              onTap: onFind,
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
