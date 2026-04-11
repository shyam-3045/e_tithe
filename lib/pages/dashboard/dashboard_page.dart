import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../common/constants/app_colors.dart';
import '../../common/constants/app_constants.dart';
import '../../common/widgets/common_alert.dart';
import '../donor/new_donor_page.dart';
import '../donor/donors_list_page.dart';
import 'widgets/dashboard_action_card.dart';
import 'widgets/dashboard_hero_carousel.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  static const String _userName = 'Wilson Behera';
  static const String _role = 'Field Officer';

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.primaryPurple,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        drawer: const _DashboardDrawer(
          userName: _userName,
          role: _role,
        ),
        appBar: AppBar(
          toolbarHeight: 78,
          titleSpacing: 0,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('e-Tithe'),
              SizedBox(height: 2),
              Text(
                'Wilson Behera  -  [Field Officer]',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        body: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double maxWidth = constraints.maxWidth > 720 ? 680 : 720;

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const DashboardHeroCarousel(),
                        const SizedBox(height: 28),
                        GridView.count(
                          crossAxisCount: constraints.maxWidth >= 620 ? 4 : 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 18,
                          mainAxisSpacing: 18,
                          childAspectRatio: 1.72,
                          children: [
                            DashboardActionCard(
                              title: 'New Donor',
                              icon: Icons.person_add_alt_1_rounded,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const NewDonorPage(),
                                ),
                              ),
                            ),
                            DashboardActionCard(
                              title: 'Donors',
                              icon: Icons.volunteer_activism_rounded,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const DonorsListPage(),
                                ),
                              ),
                            ),
                            DashboardActionCard(
                              title: 'Receipts',
                              icon: Icons.receipt_long_rounded,
                              onTap: () => _showComingSoon(context, 'Receipts'),
                            ),
                            DashboardActionCard(
                              title: 'Notifications',
                              icon: Icons.notifications_active_rounded,
                              onTap: () => _showComingSoon(
                                context,
                                'Notifications',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  static void _showComingSoon(BuildContext context, String title) {
    CommonAlert.showInfo(
      context,
      title: title,
      message: 'This section is ready for the next workflow to be connected.',
    );
  }
}

class _DashboardDrawer extends StatelessWidget {
  const _DashboardDrawer({
    required this.userName,
    required this.role,
  });

  final String userName;
  final String role;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryPurple,
                    AppColors.richPurple,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person_rounded,
                      color: AppColors.primaryPurple,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role,
                    style: const TextStyle(
                      color: AppColors.lavender,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _DrawerTile(
              icon: Icons.dashboard_rounded,
              label: 'Dashboard',
              selected: true,
              onTap: () => Navigator.of(context).pop(),
            ),
            _DrawerTile(
              icon: Icons.people_alt_rounded,
              label: 'Donor Management',
              onTap: () => _showDrawerInfo(context, 'Donor Management'),
            ),
            _DrawerTile(
              icon: Icons.receipt_long_rounded,
              label: 'Receipts',
              onTap: () => _showDrawerInfo(context, 'Receipts'),
            ),
            _DrawerTile(
              icon: Icons.notifications_rounded,
              label: 'Notifications',
              onTap: () => _showDrawerInfo(context, 'Notifications'),
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.only(bottom: 18),
              child: Text(
                AppConstants.versionLabel,
                style: TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _showDrawerInfo(BuildContext context, String title) {
    Navigator.of(context).pop();
    DashboardPage._showComingSoon(context, title);
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: ListTile(
        selected: selected,
        selectedTileColor: AppColors.softPurple,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        leading: Icon(
          icon,
          color: selected ? AppColors.primaryPurple : AppColors.textGrey,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.primaryPurple : AppColors.textDark,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
