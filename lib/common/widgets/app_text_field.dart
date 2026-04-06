import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.hintText,
    required this.icon,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    super.key,
  });

  final String hintText;
  final IconData icon;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.borderGrey,
          width: 1.4,
        ),
        borderRadius: BorderRadius.circular(5),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: AppColors.textGrey,
          fontSize: 28,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: AppColors.textGrey,
            fontSize: 28,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 22, right: 14),
            child: Icon(
              icon,
              color: AppColors.iconPurple,
              size: 36,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 78,
          ),
          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(vertical: 19),
        ),
      ),
    );
  }
}
