import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../common/constants/app_colors.dart';
import '../../common/widgets/app_form_text_field.dart';
import '../../common/widgets/common_alert.dart';
import '../../common/widgets/primary_button.dart';

class UpdateUserProfilePage extends StatefulWidget {
  const UpdateUserProfilePage({super.key});

  @override
  State<UpdateUserProfilePage> createState() => _UpdateUserProfilePageState();
}

class _UpdateUserProfilePageState extends State<UpdateUserProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController(text: 'Wilson Behera');
  final _flatBuildingController = TextEditingController(
    text: 'S3M1 - 66 RDA Colony',
  );
  final _streetController = TextEditingController(text: 'Near Transformer');
  final _cityController = TextEditingController(text: 'Rourkela');
  final _pincodeController = TextEditingController(text: '769015');
  final _stateController = TextEditingController(text: 'Odisha');
  final _mobileController = TextEditingController(text: '8596004610');
  final _whatsAppController = TextEditingController(text: '8596004610');
  final _emailController = TextEditingController(
    text: 'wilsonbehera@gmail.com',
  );

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // TODO(API): Load current user profile and prefill controllers.
    // await _loadProfileFromApi();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _flatBuildingController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _stateController.dispose();
    _mobileController.dispose();
    _whatsAppController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      // TODO(API): Call update profile API here.
      // Build payload using controller values.
      await Future<void>.delayed(const Duration(milliseconds: 450));

      if (!mounted) return;
      CommonAlert.showInfo(
        context,
        title: 'Profile',
        message: 'UI is ready. Hook API call in _handleUpdate().',
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _handleChangePhoto() {
    // TODO(API): Implement photo capture/gallery + upload.
    CommonAlert.showInfo(
      context,
      title: 'Profile Photo',
      message: 'Connect camera/gallery upload here.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.primaryPurple,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Update Profile'),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PrimaryButton(
                  label: 'Update',
                  isLoading: _isSaving,
                  onPressed: _isSaving ? null : _handleUpdate,
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Back'),
                ),
              ],
            ),
          ),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
              child: Column(
                children: [
                  _ProfileHeaderCard(
                    name: _nameController.text.trim().isEmpty
                        ? 'Your Name'
                        : _nameController.text.trim(),
                    location: _stateController.text.trim().isEmpty
                        ? ' '
                        : _stateController.text.trim().toUpperCase(),
                    onCameraTap: _handleChangePhoto,
                  ),
                  const SizedBox(height: 18),
                  AppFormTextField(
                    controller: _nameController,
                    hintText: 'Name',
                    icon: Icons.person_rounded,
                    validator: (value) => _required(value, 'Name is required'),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 14),
                  AppFormTextField(
                    controller: _flatBuildingController,
                    hintText: 'Flat/Building',
                    icon: Icons.apartment_rounded,
                  ),
                  const SizedBox(height: 14),
                  AppFormTextField(
                    controller: _streetController,
                    hintText: 'Street/Avenue',
                    icon: Icons.person_pin_circle_rounded,
                  ),
                  const SizedBox(height: 14),
                  AppFormTextField(
                    controller: _cityController,
                    hintText: 'City',
                    icon: Icons.location_city_rounded,
                  ),
                  const SizedBox(height: 14),
                  AppFormTextField(
                    controller: _pincodeController,
                    hintText: 'Pincode',
                    icon: Icons.local_post_office_outlined,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 14),
                  AppFormTextField(
                    controller: _stateController,
                    hintText: 'State',
                    icon: Icons.help_outline_rounded,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 14),
                  AppFormTextField(
                    controller: _mobileController,
                    hintText: 'Mobile *',
                    icon: Icons.phone_android_rounded,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      final String? base = _required(
                        value,
                        'Mobile number is required',
                      );
                      if (base != null) return base;
                      if ((value ?? '').trim().length < 10) {
                        return 'Enter a valid mobile number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  AppFormTextField(
                    controller: _whatsAppController,
                    hintText: 'WhatsApp No',
                    icon: Icons.message_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),
                  AppFormTextField(
                    controller: _emailController,
                    hintText: 'Email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      final input = (value ?? '').trim();
                      if (input.isEmpty) return null;
                      final bool ok = RegExp(
                        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                      ).hasMatch(input);
                      return ok ? null : 'Enter a valid email';
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String? _required(String? value, String message) {
    return (value ?? '').trim().isEmpty ? message : null;
  }
}

class _GradientAppBarBackground extends StatelessWidget {
  const _GradientAppBarBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.statusBarPink, AppColors.primaryPurple],
        ),
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({
    required this.name,
    required this.location,
    required this.onCameraTap,
  });

  final String name;
  final String location;
  final VoidCallback onCameraTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              const CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.lavender,
                child: Icon(
                  Icons.person_rounded,
                  color: AppColors.primaryPurple,
                  size: 42,
                ),
              ),
              Positioned(
                right: -8,
                bottom: -6,
                child: Material(
                  color: AppColors.primaryPurple,
                  shape: const CircleBorder(),
                  child: IconButton(
                    onPressed: onCameraTap,
                    icon: const Icon(
                      Icons.photo_camera_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    constraints: const BoxConstraints.tightFor(
                      width: 44,
                      height: 44,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  location,
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlinedFormField extends StatelessWidget {
  const _OutlinedFormField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.validator,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.iconPurple),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.borderGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.borderGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: AppColors.primaryPurple,
            width: 1.2,
          ),
        ),
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.onUpdate,
    required this.onBack,
    required this.isLoading,
  });

  final VoidCallback onUpdate;
  final VoidCallback onBack;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 74,
        decoration: const BoxDecoration(color: AppColors.statusBarPink),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: isLoading ? null : onUpdate,
                child: _BottomAction(
                  icon: Icons.save_rounded,
                  label: isLoading ? 'Updating...' : 'Update',
                ),
              ),
            ),
            Container(
              width: 1,
              height: 44,
              color: Colors.white.withValues(alpha: 0.35),
            ),
            Expanded(
              child: InkWell(
                onTap: onBack,
                child: const _BottomAction(
                  icon: Icons.arrow_back_rounded,
                  label: 'Back',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
