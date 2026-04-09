import 'package:flutter/material.dart';

import '../../common/constants/app_colors.dart';

class NewDonorPage extends StatefulWidget {
  const NewDonorPage({super.key});

  @override
  State<NewDonorPage> createState() => _NewDonorPageState();
}

class _NewDonorPageState extends State<NewDonorPage> {
  final _formKey = GlobalKey<FormState>();

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

  bool _personalExpanded = true;
  bool _addressExpanded = true;

  String? _selectedTitle = 'Mr.';
  String? _selectedGender = 'Male';
  String? _selectedMaritalStatus = 'Married';
  String? _selectedMembership = 'Member';
  String? _selectedArea;
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

  void _handleSave() {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Implement API call 
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Form is ready. Hook the save API in _handleSave().'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Donor'),
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
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _StyledTextField(
                        controller: _weddingDateController,
                        label: 'Wedding Date',
                        icon: Icons.event_rounded,
                        readOnly: true,
                        onTap: () => _pickDate(_weddingDateController),
                      ),
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
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save Donor'),
                ),
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
        border: Border.all(
          color: AppColors.lavender,
          width: 1.4,
        ),
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
                  colors: [
                    AppColors.statusBarPink,
                    AppColors.mutedPurple,
                  ],
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
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
  });

  final T? value;
  final List<T> items;
  final IconData icon;
  final ValueChanged<T?> onChanged;
  final String? hintText;
  final String? Function(T?)? validator;
  final bool isRequired;

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
              style: const TextStyle(
                color: AppColors.textGrey,
                fontSize: 16,
              ),
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
                '$item',
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
        border: Border.all(
          color: AppColors.borderGrey,
        ),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
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
    prefixIcon: Icon(
      icon,
      color: AppColors.iconPurple,
    ),
    suffixIcon: suffixIcon,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(
        color: AppColors.borderGrey,
        width: 1.2,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(
        color: AppColors.primaryPurple,
        width: 1.6,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(
        color: Colors.redAccent,
        width: 1.2,
      ),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(
        color: Colors.redAccent,
        width: 1.4,
      ),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
  );
}
