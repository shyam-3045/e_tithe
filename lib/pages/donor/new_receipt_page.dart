import 'package:flutter/material.dart';

import '../../common/constants/app_colors.dart';

class NewReceiptPage extends StatelessWidget {
  const NewReceiptPage({super.key, required this.donorName});

  final String donorName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Receipt')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'New Receipt screen for: $donorName\n\nShare the receipt form fields and I will implement the full UI.',
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
