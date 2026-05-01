import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 128});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.12),
            border: Border.all(color: AppColors.lightGold, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.35),
                blurRadius: size * 0.08,
                spreadRadius: size * 0.01,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.12),
            child: Image.asset(
              'logo.jpeg',
              fit: BoxFit.cover,
              width: size,
              height: size,
            ),
          ),
        ),
        SizedBox(height: size * 0.08),
        Text(
          'e-Tithe',
          style: TextStyle(
            color: AppColors.darkGold,
            fontSize: size * 0.14,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.2,
            shadows: const [Shadow(color: AppColors.gold, blurRadius: 3)],
          ),
        ),
      ],
    );
  }
}
