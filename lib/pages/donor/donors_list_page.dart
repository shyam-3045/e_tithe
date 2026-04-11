import 'package:flutter/material.dart';

import '../../common/constants/app_colors.dart';
import '../../common/widgets/common_alert.dart';
import 'update_profile_page.dart';
import 'my_receipts_page.dart';
import 'dependent_page.dart';
import 'new_receipt_page.dart';

class DonorsListPage extends StatelessWidget {
  const DonorsListPage({super.key});

  static final List<_DonorListItem> _donors = <_DonorListItem>[
    const _DonorListItem(
      name: 'Mukti Ranjan Nag',
      membership: 'Member',
      addressLines: ['Balangir', 'Balangir', 'Northern Division-767001'],
      email: 'ranjan@gmail.com',
      phone: '9692962159',
      avatarUrl: 'https://i.pravatar.cc/150?img=12',
    ),
    const _DonorListItem(
      name: 'Prasanta Pattnaik',
      membership: 'Member',
      addressLines: ['Malipada', 'Bhawanipatna', 'Bhawanipatna -766001'],
      email: 'prasanta@gmail.com',
      phone: '9861380163',
      avatarUrl: 'https://i.pravatar.cc/150?img=47',
    ),
    const _DonorListItem(
      name: 'Samuel Suna',
      membership: 'Member',
      addressLines: [
        'Brajrajnagar',
        'St. Peter church',
        'Brajrajnagar -768225',
      ],
      email: 'samuel@gmail.com',
      phone: '9658214124',
    ),
    const _DonorListItem(
      name: 'Sipra Rani Das',
      membership: 'Member',
      addressLines: ['Katabaga', 'Full gospel church', 'Brajrajnagar -768225'],
      email: 'suprarani@gmail.com',
      phone: '9438856985',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Donors'),
        actions: [
          IconButton(
            tooltip: 'Search',
            onPressed: () => CommonAlert.showInfo(
              context,
              title: 'Search',
              message: 'Search UI can be connected next.',
            ),
            icon: const Icon(Icons.search_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: _donors.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final donor = _donors[index];
            return _DonorCard(
              donor: donor,
              onMenuSelected: (action) =>
                  _handleMenuSelection(context, donor: donor, action: action),
            );
          },
        ),
      ),
    );
  }

  static void _handleMenuSelection(
    BuildContext context, {
    required _DonorListItem donor,
    required _DonorMenuAction action,
  }) {
    Widget page;

    switch (action) {
      case _DonorMenuAction.updateProfile:
        page = UpdateProfilePage(donorName: donor.name);
      case _DonorMenuAction.myReceipts:
        page = MyReceiptsPage(donorName: donor.name);
      case _DonorMenuAction.dependent:
        page = DependentPage(donorName: donor.name);
      case _DonorMenuAction.newReceipt:
        page = NewReceiptPage(donorName: donor.name);
    }

    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}

enum _DonorMenuAction { updateProfile, myReceipts, dependent, newReceipt }

class _DonorListItem {
  const _DonorListItem({
    required this.name,
    required this.membership,
    required this.addressLines,
    required this.email,
    required this.phone,
    this.avatarUrl,
  });

  final String name;
  final String membership;
  final List<String> addressLines;
  final String email;
  final String phone;
  final String? avatarUrl;
}

class _DonorCard extends StatelessWidget {
  const _DonorCard({required this.donor, required this.onMenuSelected});

  final _DonorListItem donor;
  final ValueChanged<_DonorMenuAction> onMenuSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
              color: AppColors.statusBarPink,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      donor.name.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _MenuButton(onSelected: onMenuSelected),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Avatar(avatarUrl: donor.avatarUrl),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              donor.membership,
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ...donor.addressLines.map(
                              (line) => Text(
                                line,
                                style: const TextStyle(
                                  color: AppColors.textGrey,
                                  fontSize: 15,
                                  height: 1.25,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 2,
                    width: double.infinity,
                    color: AppColors.statusBarPink.withOpacity(0.7),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.email_outlined,
                        size: 18,
                        color: AppColors.textGrey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          donor.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textGrey,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Icon(
                        Icons.call_rounded,
                        size: 18,
                        color: AppColors.statusBarPink,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        donor.phone,
                        style: const TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.avatarUrl});

  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 38,
      backgroundColor: AppColors.lavender,
      foregroundImage: avatarUrl == null ? null : NetworkImage(avatarUrl!),
      child: const Icon(
        Icons.person_rounded,
        color: AppColors.primaryPurple,
        size: 40,
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.onSelected});

  final ValueChanged<_DonorMenuAction> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.primaryPurple,
        borderRadius: BorderRadius.circular(12),
      ),
      child: PopupMenuButton<_DonorMenuAction>(
        tooltip: 'Options',
        padding: EdgeInsets.zero,
        onSelected: onSelected,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: _DonorMenuAction.updateProfile,
            child: Text('Update Profile'),
          ),
          PopupMenuItem(
            value: _DonorMenuAction.myReceipts,
            child: Text('My Receipts'),
          ),
          PopupMenuItem(
            value: _DonorMenuAction.dependent,
            child: Text('Dependent'),
          ),
          PopupMenuItem(
            value: _DonorMenuAction.newReceipt,
            child: Text('New Receipt'),
          ),
        ],
        child: const Center(
          child: Icon(Icons.more_vert_rounded, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
