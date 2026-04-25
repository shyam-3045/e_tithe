import 'package:flutter/material.dart';

import '../../common/constants/app_colors.dart';
import '../../common/services/auth_service.dart';
import '../../common/services/donor_service.dart';
import '../../common/services/receipt_service.dart';
import '../../common/services/user_service.dart';
import '../../common/widgets/common_alert.dart';

class NewReceiptPage extends StatefulWidget {
  const NewReceiptPage({
    super.key,
    required this.donorName,
    required this.donorId,
  });

  final String donorName;
  final int donorId;

  @override
  State<NewReceiptPage> createState() => _NewReceiptPageState();
}

class _NewReceiptPageState extends State<NewReceiptPage> {
  late String _selectedMonth;
  late int _selectedYear;
  final TextEditingController _notesController = TextEditingController();

  final List<_ReceiptPaymentEntry> _payments = <_ReceiptPaymentEntry>[];

  late String _donorDisplayName;
  List<String> _addressLines = <String>[];
  String _pincode = '';

  static const List<String> _months = <String>[
    'JANUARY',
    'FEBRUARY',
    'MARCH',
    'APRIL',
    'MAY',
    'JUNE',
    'JULY',
    'AUGUST',
    'SEPTEMBER',
    'OCTOBER',
    'NOVEMBER',
    'DECEMBER',
  ];

  static const List<String> _fundTypes = <String>[
    'General Donation',
    'Tithe',
    'Mission',
    'VBS/Camps/Retreats/Rally/Seminars',
    'Building Fund',
    'Vehicle Fund',
    'Devotional Book Promotion',
    'Offering',
    'Equipment Fund',
    'Educational Fund',
    'Christmas Gift Fund',
    'North India Support',
    'Staff Welfare Fund',
    'Staff Support from LU',
    'Travel Refund',
    'From Departments',
    'From States',
    'VBS Support from LU',
    'Vehicle Fund from LU',
    'Spl.Contribution from LU',
    'Promise Card from LU',
    'NID Support from LU',
    'Educational Fund from LU',
    'Christmas Gift From LU',
    'Building Fund from LU',
    'Staff Support From Donor',
    'Staff Donation',
    'From Head Quarters',
    'Subscription',
  ];

  String _currentMonthLabel() {
    final DateTime now = DateTime.now();
    final int monthIndex = (now.month - 1).clamp(0, _months.length - 1);
    return _months[monthIndex];
  }

  List<int> _yearOptions() {
    final int currentYear = DateTime.now().year;
    return List<int>.generate(11, (index) => currentYear - 5 + index);
  }

  Future<void> _loadDonorHeader() async {
    try {
      final DonorDetails donor = await DonorService.instance.fetchDonorById(
        widget.donorId,
      );
      if (!mounted) return;

      final List<String> addressLines = <String>[
        donor.street,
        donor.city,
        donor.district,
        donor.state,
      ].where((line) => line.trim().isNotEmpty).toList();

      setState(() {
        _donorDisplayName = donor.name.toUpperCase();
        _addressLines = addressLines;
        _pincode = donor.pincode;
      });
    } catch (_) {
      // Keep fallback donor header when donor detail API is unavailable.
    }
  }

  @override
  void initState() {
    super.initState();

    _selectedMonth = _currentMonthLabel();
    _selectedYear = DateTime.now().year;

    _donorDisplayName = widget.donorName.toUpperCase();
    _addressLines = <String>[];
    _pincode = '';
    _loadDonorHeader();

    // TODO(API): Load fund type list.
    // await _loadFundTypes();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  double get _totalAmount =>
      _payments.fold<double>(0, (sum, item) => sum + item.amount);

  Future<void> _openAddPayDialog() async {
    final Set<String> takenFunds = _payments.map((e) => e.fundType).toSet();
    final List<String> availableFunds = _fundTypes
        .where((f) => !takenFunds.contains(f))
        .toList();

    if (availableFunds.isEmpty) {
      await CommonAlert.showInfo(
        context,
        title: 'No more funds',
        message: 'You have already added all available fund types.',
      );
      return;
    }

    final _ReceiptPaymentEntry? created =
        await showDialog<_ReceiptPaymentEntry>(
          context: context,
          barrierDismissible: false,
          builder: (context) => _AmountDetailDialog(
            fundTypes: _fundTypes,
            takenFundTypes: takenFunds,
          ),
        );

    if (created == null) return;

    setState(() {
      _payments.add(created);
    });
  }

  Future<void> _handleNext() async {
    final List<String> errors = [];

    if (_selectedMonth.trim().isEmpty) {
      errors.add('Please select Month.');
    }

    if (_payments.isEmpty) {
      errors.add('Please add at least one payment (Add Pay).');
    }

    if (_notesController.text.trim().isEmpty) {
      errors.add('Please enter Notes.');
    }

    if (errors.isNotEmpty) {
      await CommonAlert.showInfo(
        context,
        title: 'Incomplete',
        message: errors.join('\n'),
      );
      return;
    }

    // TODO(API): Validate against backend rules / create receipt draft.
    // await _createReceiptDraft();

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ReceiptSignaturePage(
          donorId: widget.donorId,
          donorName: widget.donorName,
          donorDisplayName: _donorDisplayName,
          month: _selectedMonth,
          year: _selectedYear,
          notes: _notesController.text.trim(),
          payments: List<_ReceiptPaymentEntry>.unmodifiable(_payments),
          totalAmount: _totalAmount,
        ),
      ),
    );
  }

  Future<void> _handleCancel() async {
    if (_payments.isEmpty) {
      Navigator.of(context).maybePop();
      return;
    }

    final bool? discard = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Discard receipt?'),
          content: const Text('Your added payment details will be lost.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'No',
                style: TextStyle(color: AppColors.textGrey),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Yes',
                style: TextStyle(
                  color: AppColors.primaryPurple,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (discard == true && mounted) {
      Navigator.of(context).maybePop();
    }
  }

  void _handleBack() {
    Navigator.of(context).maybePop();
  }

  Future<void> _removePayment(int index) async {
    setState(() {
      _payments.removeAt(index);
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Payment removed.')));
  }

  Future<void> _handleClearReceipt() async {
    if (_payments.isEmpty) {
      setState(() {
        _selectedMonth = _currentMonthLabel();
      });
      return;
    }

    final bool? clear = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Clear receipt?'),
          content: const Text('This will remove all added payments.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'No',
                style: TextStyle(color: AppColors.textGrey),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Yes',
                style: TextStyle(
                  color: AppColors.primaryPurple,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (clear == true && mounted) {
      setState(() {
        _payments.clear();
        _selectedMonth = _currentMonthLabel();
        _selectedYear = DateTime.now().year;
        _notesController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Receipt'),
        actions: [
          IconButton(
            tooltip: 'Clear receipt',
            onPressed: _handleClearReceipt,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      bottomNavigationBar: _ReceiptBottomBar(
        onAddPay: _openAddPayDialog,
        onNext: _handleNext,
        onCancel: _handleCancel,
        onBack: _handleBack,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DonorHeaderCard(
                donorDisplayName: _donorDisplayName,
                addressLines: _addressLines,
                pincode: _pincode,
              ),
              const SizedBox(height: 22),
              const Text(
                'Month & Year Of',
                style: TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedMonth,
                    isExpanded: true,
                    decoration: _fieldDecoration(
                      label: 'Month',
                      icon: Icons.calendar_month_rounded,
                    ),
                    dropdownColor: AppColors.surface,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textGrey,
                    ),
                    selectedItemBuilder: (context) {
                      return _months
                          .map(
                            (month) => Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                month,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textDark,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                          .toList();
                    },
                    items: _months
                        .map(
                          (month) => DropdownMenuItem<String>(
                            value: month,
                            child: Text(
                              month,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textDark,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedMonth = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: _selectedYear,
                    isExpanded: true,
                    decoration: _fieldDecoration(
                      label: 'Year',
                      icon: Icons.event_rounded,
                    ),
                    dropdownColor: AppColors.surface,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textGrey,
                    ),
                    items: _yearOptions()
                        .map(
                          (year) => DropdownMenuItem<int>(
                            value: year,
                            child: Text(
                              year.toString(),
                              style: const TextStyle(
                                color: AppColors.textDark,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedYear = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    decoration: _fieldDecoration(
                      label: 'Notes',
                      icon: Icons.notes_rounded,
                    ),
                    minLines: 2,
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                _payments.isEmpty
                    ? 'NO RECEIPT AMOUNT'
                    : 'TOTAL: ₹${_totalAmount.toStringAsFixed(0)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.statusBarPink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 2,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.statusBarPink.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 18),
              if (_payments.isEmpty)
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '* Long press to remove fund(s)',
                    style: TextStyle(
                      color: AppColors.textGrey.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    ...List.generate(_payments.length, (index) {
                      final item = _payments[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GestureDetector(
                          onLongPress: () => _removePayment(index),
                          child: _PaymentRowCard(item: item),
                        ),
                      );
                    }),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '* Long press to remove fund(s)',
                        style: TextStyle(
                          color: AppColors.textGrey.withOpacity(0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptPaymentEntry {
  const _ReceiptPaymentEntry({
    required this.fundType,
    required this.amount,
    required this.mode,
  });

  final String fundType;
  final double amount;
  final _PaymentMode mode;
}

enum _PaymentMode {
  cash('CASH'),
  cheque('CHEQUE'),
  neft('NEFT'),
  upi('UPI');

  const _PaymentMode(this.label);
  final String label;
}

class _DonorHeaderCard extends StatelessWidget {
  const _DonorHeaderCard({
    required this.donorDisplayName,
    required this.addressLines,
    required this.pincode,
  });

  final String donorDisplayName;
  final List<String> addressLines;
  final String pincode;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.statusBarPink.withOpacity(0.65),
          width: 1.6,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: AppColors.statusBarPink,
              child: Text(
                donorDisplayName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            if (addressLines.isNotEmpty || pincode.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  children: [
                    if (addressLines.isNotEmpty)
                      ...addressLines.map(
                        (line) => Text(
                          line,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textGrey,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                      ),
                    if (addressLines.isNotEmpty && pincode.trim().isNotEmpty)
                      const SizedBox(height: 4),
                    if (pincode.trim().isNotEmpty)
                      Text(
                        pincode,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
                        ),
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

class _PaymentRowCard extends StatelessWidget {
  const _PaymentRowCard({required this.item});

  final _ReceiptPaymentEntry item;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.fundType,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.mode.label,
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '₹${item.amount.toStringAsFixed(0)}',
            style: const TextStyle(
              color: AppColors.primaryPurple,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptBottomBar extends StatelessWidget {
  const _ReceiptBottomBar({
    required this.onAddPay,
    required this.onNext,
    required this.onCancel,
    required this.onBack,
  });

  final VoidCallback onAddPay;
  final VoidCallback onNext;
  final VoidCallback onCancel;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryPurple, AppColors.richPurple],
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 18,
              offset: Offset(0, -8),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _BottomAction(
              label: 'Add Pay',
              icon: Icons.add_circle_outline_rounded,
              onTap: onAddPay,
            ),
            _BottomAction(
              label: 'Next',
              icon: Icons.playlist_add_check_rounded,
              onTap: onNext,
            ),
            _BottomAction(
              label: 'Cancel',
              icon: Icons.close_rounded,
              onTap: onCancel,
            ),
            _BottomAction(
              label: 'Back',
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: onBack,
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountDetailDialog extends StatefulWidget {
  const _AmountDetailDialog({
    required this.fundTypes,
    required this.takenFundTypes,
  });

  final List<String> fundTypes;
  final Set<String> takenFundTypes;

  @override
  State<_AmountDetailDialog> createState() => _AmountDetailDialogState();
}

class _AmountDetailDialogState extends State<_AmountDetailDialog> {
  final _formKey = GlobalKey<FormState>();

  late String _selectedFundType;
  final _amountController = TextEditingController();
  _PaymentMode _selectedMode = _PaymentMode.cash;

  @override
  void initState() {
    super.initState();

    final List<String> available = widget.fundTypes
        .where((fund) => !widget.takenFundTypes.contains(fund))
        .toList();

    _selectedFundType = available.contains('General Donation')
        ? 'General Donation'
        : (available.isNotEmpty ? available.first : 'General Donation');
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _handleOk() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final double amount = double.tryParse(_amountController.text.trim()) ?? 0;

    if (amount <= 0) {
      await CommonAlert.showInfo(
        context,
        title: 'Invalid',
        message: 'Enter a valid amount.',
      );
      return;
    }

    if (widget.takenFundTypes.contains(_selectedFundType)) {
      await CommonAlert.showInfo(
        context,
        title: 'Duplicate fund',
        message: 'This fund type is already added. Please select another one.',
      );
      return;
    }

    // TODO(API): You can validate fund type/mode rules here.

    if (!mounted) return;

    Navigator.of(context).pop(
      _ReceiptPaymentEntry(
        fundType: _selectedFundType,
        amount: amount,
        mode: _selectedMode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Amount Detail'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Fund Type',
                  style: TextStyle(
                    color: AppColors.textGrey.withOpacity(0.9),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedFundType,
                isExpanded: true,
                decoration: _fieldDecoration(
                  label: '',
                  icon: Icons.volunteer_activism_rounded,
                ),
                dropdownColor: AppColors.surface,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textGrey,
                ),
                selectedItemBuilder: (context) {
                  return widget.fundTypes
                      .map(
                        (fund) => Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            fund,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textDark,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList();
                },
                items: widget.fundTypes.map((fund) {
                  final bool isTaken = widget.takenFundTypes.contains(fund);
                  return DropdownMenuItem<String>(
                    value: fund,
                    enabled: !isTaken,
                    child: Text(
                      fund,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isTaken
                            ? AppColors.textGrey.withOpacity(0.65)
                            : AppColors.textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedFundType = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: _fieldDecoration(
                  label: 'Amount',
                  icon: Icons.currency_rupee_rounded,
                ),
                validator: (value) {
                  final String input = (value ?? '').trim();
                  if (input.isEmpty) {
                    return 'Amount is required';
                  }
                  final double? parsed = double.tryParse(input);
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.statusBarPink.withOpacity(0.55),
                    width: 1.4,
                  ),
                ),
                child: Column(
                  children: _PaymentMode.values
                      .map(
                        (mode) => RadioListTile<_PaymentMode>(
                          value: mode,
                          groupValue: _selectedMode,
                          activeColor: AppColors.statusBarPink,
                          title: Text(
                            mode.label,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _selectedMode = value;
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'CANCEL',
            style: TextStyle(
              color: AppColors.statusBarPink,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        TextButton(
          onPressed: _handleOk,
          child: const Text(
            'OK',
            style: TextStyle(
              color: AppColors.statusBarPink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReceiptSignaturePage extends StatefulWidget {
  const _ReceiptSignaturePage({
    required this.donorId,
    required this.donorName,
    required this.donorDisplayName,
    required this.month,
    required this.year,
    required this.notes,
    required this.payments,
    required this.totalAmount,
  });

  final int donorId;
  final String donorName;
  final String donorDisplayName;
  final String month;
  final int year;
  final String notes;
  final List<_ReceiptPaymentEntry> payments;
  final double totalAmount;

  @override
  State<_ReceiptSignaturePage> createState() => _ReceiptSignaturePageState();
}

class _ReceiptSignaturePageState extends State<_ReceiptSignaturePage> {
  final _SignatureController _signatureController = _SignatureController();
  bool _isSubmitting = false;

  String _dateOnly(DateTime dateTime) {
    final DateTime local = dateTime.toLocal();
    final String month = local.month.toString().padLeft(2, '0');
    final String day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  Future<UserDetails> _resolveCurrentUser() async {
    final AuthSession? session = await AuthService.instance.currentSession();
    final int userId = int.tryParse(session?.userId ?? '') ?? 0;
    if (userId <= 0) {
      throw Exception('Logged-in user ID not found. Please login again.');
    }

    return UserService.instance.fetchUserById(userId);
  }

  String _combinedPaymentMode() {
    final Set<String> modes = widget.payments.map((p) => p.mode.label).toSet();
    if (modes.length == 1) {
      return modes.first;
    }
    return 'MIXED';
  }

  Future<Map<String, dynamic>> _buildReceiptPayload() async {
    final UserDetails user = await _resolveCurrentUser();
    final DonorDetails donor = await DonorService.instance.fetchDonorById(
      widget.donorId,
    );

    final DateTime now = DateTime.now();
    final String utcNow = now.toUtc().toIso8601String();
    final String paymentMonth = '${widget.month}-${widget.year}';
    final String paymentMode = _combinedPaymentMode();
    final int totalAmount = widget.totalAmount.round();
    final String createdBy = user.userName;
    final String modifiedBy = user.userName;
    final String receiptNo = 'APP-${now.millisecondsSinceEpoch}';
    final String notes = widget.notes.trim();
    final String companyName = 'N/A';
    final String regionName = user.regionId.toString();
    final String repType = user.userTypeId.toString();
    final String repName = user.userName;

    return <String, dynamic>{
      'ReceiptID': 0,
      'Amount': totalAmount,
      'Cancel': 0,
      'CompanyID': 0,
      'RegionID': user.regionId,
      'RepID': user.userId,
      'Notes': notes,
      'PaymentMonth': paymentMonth,
      'SignURL': 'signed-from-mobile',
      'Deleted': false,
      'CreatedOn': utcNow,
      'CreatedBy': createdBy,
      'ModifiedOn': utcNow,
      'ModifiedBy': modifiedBy,
      'ReceiptDate': _dateOnly(now),
      'ReceiptNo': receiptNo,
      'DonorID': donor.donorId,
      'PaymentMode': paymentMode,
      'RegionName': regionName,
      'CompanyName': companyName,
      'RepType': repType,
      'RepName': repName,
      'DonorName': donor.name,
      'ReceiptLines': widget.payments.map((item) {
        return <String, dynamic>{
          'ReceiptLineID': 0,
          'ReceiptID': 0,
          'Amount': item.amount.round(),
          'BankName': 'N/A',
          'ChequeDate': utcNow,
          'ChequeNo': 'N/A',
          'FundID': 0,
          'FundName': item.fundType,
          'PaymentMode': item.mode.label,
          'Deleted': false,
          'CreatedOn': utcNow,
          'CreatedBy': createdBy,
          'ModifiedOn': utcNow,
          'ModifiedBy': modifiedBy,
        };
      }).toList(),
    };
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final Map<String, dynamic> payload = await _buildReceiptPayload();
      await ReceiptService.instance.createReceipt(payload: payload);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receipt added successfully.')),
      );

      Navigator.of(context).pop();
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      await CommonAlert.showInfo(
        context,
        title: 'Add receipt failed',
        message: error.toString(),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _handleClearSignature() {
    _signatureController.clear();
  }

  void _handleBack() {
    Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Signature & Submit')),
      bottomNavigationBar: AnimatedBuilder(
        animation: _signatureController,
        builder: (context, _) {
          return _SignatureBottomBar(
            canSubmit: true,
            isSubmitting: _isSubmitting,
            onClear: _handleClearSignature,
            onBack: _handleBack,
            onSubmit: _handleSubmit,
          );
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DonorHeaderCard(
                donorDisplayName: widget.donorDisplayName,
                addressLines: const [],
                pincode: '',
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.borderGrey),
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Month: ${widget.month} ${widget.year}',
                      style: const TextStyle(
                        color: AppColors.textGrey,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...widget.payments.map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                p.fundType,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '₹${p.amount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: AppColors.primaryPurple,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Total: ₹${widget.totalAmount.toStringAsFixed(0)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: AppColors.statusBarPink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Donor Signature',
                style: TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              AnimatedBuilder(
                animation: _signatureController,
                builder: (context, _) {
                  return _SignaturePad(
                    controller: _signatureController,
                    height: 220,
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Please ask the donor to sign inside the box.',
                style: TextStyle(
                  color: AppColors.textGrey.withOpacity(0.85),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignatureBottomBar extends StatelessWidget {
  const _SignatureBottomBar({
    required this.canSubmit,
    required this.isSubmitting,
    required this.onClear,
    required this.onBack,
    required this.onSubmit,
  });

  final bool canSubmit;
  final bool isSubmitting;
  final VoidCallback onClear;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryPurple, AppColors.richPurple],
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 18,
              offset: Offset(0, -8),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _BottomAction(
              label: 'Clear',
              icon: Icons.delete_outline_rounded,
              onTap: onClear,
            ),
            _BottomAction(
              label: 'Back',
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: onBack,
            ),
            Opacity(
              opacity: canSubmit && !isSubmitting ? 1 : 0.55,
              child: IgnorePointer(
                ignoring: !canSubmit || isSubmitting,
                child: _BottomAction(
                  label: isSubmitting ? 'Saving...' : 'Submit',
                  icon: isSubmitting
                      ? Icons.hourglass_top_rounded
                      : Icons.check_circle_outline_rounded,
                  onTap: onSubmit,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignatureController extends ChangeNotifier {
  final List<Offset?> _points = <Offset?>[];

  List<Offset?> get points => List<Offset?>.unmodifiable(_points);

  bool get hasSignature => _points.any((p) => p != null);

  void addPoint(Offset point) {
    _points.add(point);
    notifyListeners();
  }

  void endStroke() {
    _points.add(null);
    notifyListeners();
  }

  void clear() {
    _points.clear();
    notifyListeners();
  }
}

class _SignaturePad extends StatefulWidget {
  const _SignaturePad({required this.controller, required this.height});

  final _SignatureController controller;
  final double height;

  @override
  State<_SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<_SignaturePad> {
  void _add(Offset globalPosition) {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final Offset local = box.globalToLocal(globalPosition);
    if (local.dx < 0 || local.dy < 0) return;
    if (local.dx > box.size.width || local.dy > box.size.height) return;
    widget.controller.addPoint(local);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.statusBarPink.withOpacity(0.55),
          width: 1.4,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            if (!widget.controller.hasSignature)
              Center(
                child: Text(
                  'Sign here',
                  style: TextStyle(
                    color: AppColors.textGrey.withOpacity(0.5),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            GestureDetector(
              onPanStart: (d) => _add(d.globalPosition),
              onPanUpdate: (d) => _add(d.globalPosition),
              onPanEnd: (_) => widget.controller.endStroke(),
              child: CustomPaint(
                painter: _SignaturePainter(widget.controller.points),
                size: Size.infinite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  const _SignaturePainter(this.points);

  final List<Offset?> points;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = AppColors.textDark
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length - 1; i++) {
      final Offset? p1 = points[i];
      final Offset? p2 = points[i + 1];
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

InputDecoration _fieldDecoration({
  required String label,
  required IconData icon,
}) {
  return InputDecoration(
    labelText: label.isEmpty ? null : label,
    floatingLabelBehavior: FloatingLabelBehavior.auto,
    labelStyle: const TextStyle(
      color: AppColors.textGrey,
      fontSize: 15,
      fontWeight: FontWeight.w600,
    ),
    filled: true,
    fillColor: AppColors.surface,
    prefixIcon: Icon(icon, color: AppColors.iconPurple),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: AppColors.borderGrey, width: 1.2),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: AppColors.primaryPurple, width: 1.6),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
  );
}
