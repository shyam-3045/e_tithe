import 'package:flutter/material.dart';

import '../../common/constants/app_colors.dart';

class MyReceiptsPage extends StatelessWidget {
  const MyReceiptsPage({super.key, required this.donorName});

  final String donorName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Receipts')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'My Receipts screen for: $donorName\n\nWhen you share the receipt list/details layout, I will implement it.',
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
