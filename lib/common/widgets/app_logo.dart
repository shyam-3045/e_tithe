import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 128,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    final double iconSize = size * 0.55;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(size * 0.03),
              topRight: Radius.circular(size * 0.2),
              bottomLeft: Radius.circular(size * 0.2),
              bottomRight: Radius.circular(size * 0.03),
            ),
            border: Border.all(
              color: AppColors.lightGold,
              width: 2,
            ),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.gold,
                AppColors.darkGold,
                AppColors.gold,
                AppColors.darkGold,
              ],
              stops: [0.05, 0.42, 0.62, 1],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.35),
                blurRadius: size * 0.08,
                spreadRadius: size * 0.01,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.local_fire_department_outlined,
                size: iconSize,
                color: Colors.white,
                shadows: const [
                  Shadow(
                    color: AppColors.gold,
                    blurRadius: 12,
                  ),
                ],
              ),
              Positioned(
                bottom: size * 0.16,
                child: Text(
                  'SU-INDIA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size * 0.12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
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
            shadows: const [
              Shadow(
                color: AppColors.gold,
                blurRadius: 3,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
