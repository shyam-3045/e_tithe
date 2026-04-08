import 'dart:async';

import 'package:flutter/material.dart';

import '../../../common/constants/app_colors.dart';

class DashboardHeroCarousel extends StatefulWidget {
  const DashboardHeroCarousel({super.key});

  @override
  State<DashboardHeroCarousel> createState() => _DashboardHeroCarouselState();
}

class _DashboardHeroCarouselState extends State<DashboardHeroCarousel> {
  static const List<_HeroSlide> _slides = [
    _HeroSlide(
      title: 'Field Collection Overview',
      description: 'Track donor activity, receipts, and updates in one place.',
      icon: Icons.analytics_rounded,
    ),
    _HeroSlide(
      title: 'Donor Care',
      description: 'Keep donor records organized for faster field follow-up.',
      icon: Icons.handshake_rounded,
    ),
    _HeroSlide(
      title: 'Receipt Management',
      description: 'Prepare clean collection workflows for every visit.',
      icon: Icons.fact_check_rounded,
    ),
    _HeroSlide(
      title: 'Notifications',
      description: 'Stay aligned with important tithe updates and reminders.',
      icon: Icons.campaign_rounded,
    ),
  ];

  final PageController _pageController = PageController();
  Timer? _timer;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_pageController.hasClients) return;

      final int nextIndex = (_selectedIndex + 1) % _slides.length;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.82,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.borderGrey),
          boxShadow: [
            BoxShadow(
              color: AppColors.deepPurple.withValues(alpha: 0.08),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() => _selectedIndex = index);
                },
                itemBuilder: (context, index) {
                  return _HeroSlideView(slide: _slides[index]);
                },
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _HeroCaption(
                  slide: _slides[_selectedIndex],
                  selectedIndex: _selectedIndex,
                  slideCount: _slides.length,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroSlideView extends StatelessWidget {
  const _HeroSlideView({
    required this.slide,
  });

  final _HeroSlide slide;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            AppColors.softPurple,
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: 132,
          height: 132,
          decoration: BoxDecoration(
            color: AppColors.primaryPurple.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            slide.icon,
            color: AppColors.primaryPurple,
            size: 68,
          ),
        ),
      ),
    );
  }
}

class _HeroCaption extends StatelessWidget {
  const _HeroCaption({
    required this.slide,
    required this.selectedIndex,
    required this.slideCount,
  });

  final _HeroSlide slide;
  final int selectedIndex;
  final int slideCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      color: AppColors.textDark.withValues(alpha: 0.72),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  slide.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  slide.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.lavender,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Row(
            children: List.generate(
              slideCount,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: index == selectedIndex ? 18 : 8,
                height: 8,
                margin: const EdgeInsets.only(left: 5),
                decoration: BoxDecoration(
                  color: index == selectedIndex
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.26),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSlide {
  const _HeroSlide({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}
