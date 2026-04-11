import 'package:flutter/material.dart';

import '../../common/constants/app_colors.dart';
import '../../common/widgets/common_alert.dart';

class NewReceiptPage extends StatefulWidget {
  const NewReceiptPage({super.key, required this.donorName});

  final String donorName;

  @override
  State<NewReceiptPage> createState() => _NewReceiptPageState();
}

class _NewReceiptPageState extends State<NewReceiptPage> {
  String _selectedMonth = 'APRIL';

  final List<_ReceiptPaymentEntry> _payments = <_ReceiptPaymentEntry>[];

  // TODO(API): Replace these sample donor fields with API data.
  late final String _donorDisplayName;
  final List<String> _addressLines = ['Balangir', 'Balangir', 'Northern Division'];
  final String _pincode = '767001';

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
    'Building Fund',
  ];

  @override
  void initState() {
    super.initState();
    _donorDisplayName = 'MR. ${widget.donorName}'.toUpperCase();

    // TODO(API): Load donor address/profile for receipt header.
    // await _loadDonorReceiptHeader();

    // TODO(API): Load fund type list.
    // await _loadFundTypes();
  }

  double get _totalAmount => _payments.fold<double>(
        0,
        (sum, item) => sum + item.amount,
      );

  Future<void> _openAddPayDialog() async {
    final _ReceiptPaymentEntry? created = await showDialog<_ReceiptPaymentEntry>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _AmountDetailDialog(
        fundTypes: _fundTypes,
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
        builder: (_) => _ReceiptReviewPage(
          donorDisplayName: _donorDisplayName,
          month: _selectedMonth,
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment removed.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Receipt'),
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
                'Month Of',
                style: TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedMonth,
                decoration: _fieldDecoration(
                  label: '',
                  icon: Icons.calendar_month_rounded,
                ),
                dropdownColor: AppColors.surface,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textGrey,
                ),
                items: _months
                    .map(
                      (month) => DropdownMenuItem<String>(
                        value: month,
                        child: Text(
                          month,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                children: [
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
                  const SizedBox(height: 4),
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
            colors: [
              AppColors.primaryPurple,
              AppColors.richPurple,
            ],
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
  const _AmountDetailDialog({required this.fundTypes});

  final List<String> fundTypes;

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
    _selectedFundType = widget.fundTypes.isNotEmpty
        ? widget.fundTypes.first
        : 'General Donation';
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
                decoration: _fieldDecoration(
                  label: '',
                  icon: Icons.volunteer_activism_rounded,
                ),
                dropdownColor: AppColors.surface,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textGrey,
                ),
                items: widget.fundTypes
                    .map(
                      (fund) => DropdownMenuItem<String>(
                        value: fund,
                        child: Text(
                          fund,
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
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
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

class _ReceiptReviewPage extends StatelessWidget {
  const _ReceiptReviewPage({
    required this.donorDisplayName,
    required this.month,
    required this.payments,
    required this.totalAmount,
  });

  final String donorDisplayName;
  final String month;
  final List<_ReceiptPaymentEntry> payments;
  final double totalAmount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receipt Review')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                donorDisplayName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Month: $month',
                style: const TextStyle(
                  color: AppColors.textGrey,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: payments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    return _PaymentRowCard(item: payments[index]);
                  },
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Total: ₹${totalAmount.toStringAsFixed(0)}',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: AppColors.primaryPurple,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  // TODO(API): Submit receipt to server.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Hook submit API on this step.'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: const Text('Submit (TODO)'),
              ),
            ],
          ),
        ),
      ),
    );
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
    prefixIcon: Icon(
      icon,
      color: AppColors.iconPurple,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(
        color: AppColors.borderGrey,
        width: 1.2,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(
        color: AppColors.primaryPurple,
        width: 1.6,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(
        color: Colors.redAccent,
        width: 1.2,
      ),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(
        color: Colors.redAccent,
        width: 1.4,
      ),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
  );
}
