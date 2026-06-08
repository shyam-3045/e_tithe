import 'package:flutter/material.dart';

import '../../common/constants/app_colors.dart';
import '../dashboard/dashboard_page.dart';

class DonorCreationSuccessPage extends StatefulWidget {
  const DonorCreationSuccessPage({super.key});

  @override
  State<DonorCreationSuccessPage> createState() =>
      _DonorCreationSuccessPageState();
}

class _DonorCreationSuccessPageState extends State<DonorCreationSuccessPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _circleScale;
  late final Animation<double> _circleFade;
  late final Animation<double> _checkScale;
  late final Animation<double> _checkFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _circleScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
    );
    _circleFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );
    _checkScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 1.0, curve: Curves.elasticOut),
    );
    _checkFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.75, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToDashboard() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const DashboardPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x16000000),
                    blurRadius: 28,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return SizedBox(
                        width: 140,
                        height: 140,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Opacity(
                              opacity: _circleFade.value,
                              child: Transform.scale(
                                scale: _circleScale.value,
                                child: Container(
                                  width: 128,
                                  height: 128,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF6BE675),
                                        Color(0xFF19B84C),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0x3323B44D),
                                        blurRadius: 22,
                                        offset: Offset(0, 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Opacity(
                              opacity: _checkFade.value,
                              child: Transform.scale(
                                scale: _checkScale.value,
                                child: const Icon(
                                  Icons.check_rounded,
                                  size: 84,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Donor Created Successfully',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _goToDashboard,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'OK',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
