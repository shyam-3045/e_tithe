import 'package:flutter/material.dart';

import '../../common/constants/app_colors.dart';

class DependentPage extends StatelessWidget {
  const DependentPage({super.key, required this.donorName});

  final String donorName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dependent')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Dependent screen for: $donorName\n\nShare the dependent form/list requirements and I will build it.',
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
