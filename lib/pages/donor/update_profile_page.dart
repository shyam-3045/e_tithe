import 'package:flutter/material.dart';

import '../../common/constants/app_colors.dart';

class UpdateProfilePage extends StatelessWidget {
  const UpdateProfilePage({super.key, required this.donorName});

  final String donorName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update Profile')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Update Profile screen for: $donorName\n\nShare the fields you want here and I will build the full UI.',
            style: const TextStyle(
              color: AppColors.textGrey,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }
}
