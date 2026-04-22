import 'package:flutter/material.dart';

import '../../common/constants/app_colors.dart';
import '../../common/services/donor_service.dart';

class DependentPage extends StatefulWidget {
  const DependentPage({super.key, required this.donorName, this.donorId});

  final String donorName;
  final int? donorId;

  @override
  State<DependentPage> createState() => _DependentPageState();
}

class _DependentPageState extends State<DependentPage> {
  late Future<DonorDetails> _donorFuture;

  @override
  void initState() {
    super.initState();
    _donorFuture = _fetchDonor();
  }

  Future<DonorDetails> _fetchDonor() {
    final int donorId = widget.donorId ?? 0;
    if (donorId <= 0) {
      throw Exception('Donor ID is missing.');
    }

    return DonorService.instance.fetchDonorById(donorId);
  }

  @override
  Widget build(BuildContext context) {
    final int donorId = widget.donorId ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Dependent')),
      body: SafeArea(
        child: donorId <= 0
            ? Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Dependent screen for: ${widget.donorName}\n\nDonor ID is missing, so dependent list cannot be loaded.',
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              )
            : FutureBuilder<DonorDetails>(
                future: _donorFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 46,
                              color: AppColors.textGrey,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              snapshot.error.toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textGrey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: () => setState(() {
                                _donorFuture = _fetchDonor();
                              }),
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final DonorDetails donor = snapshot.data!;
                  final List<DonorDependent> dependents = donor.dependents;

                  if (dependents.isEmpty) {
                    return Center(
                      child: Text(
                        'No dependents found for ${widget.donorName}.',
                        style: const TextStyle(
                          color: AppColors.textGrey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: dependents.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final DonorDependent item = dependents[index];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x12000000),
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                            if (item.relation.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                item.relation,
                                style: const TextStyle(
                                  color: AppColors.textGrey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
