import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 72,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryPurple,
          disabledBackgroundColor: AppColors.primaryPurple.withValues(
            alpha: 0.75,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.8,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2,
                ),
              ),
      ),
    );
  }
}
