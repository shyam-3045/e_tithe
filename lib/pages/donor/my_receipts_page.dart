import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../common/constants/app_colors.dart';
import '../../common/services/receipt_export_service.dart';
import '../../common/services/receipt_service.dart';
import '../../common/widgets/common_alert.dart';

class MyReceiptsPage extends StatefulWidget {
  const MyReceiptsPage({super.key, this.donorName});

  final String? donorName;

  @override
  State<MyReceiptsPage> createState() => _MyReceiptsPageState();
}

enum _ReceiptPayFilter { all, cash, bank }

class _MyReceiptsPageState extends State<MyReceiptsPage> {
  static const Color _receiptGreen = Color(0xFF09A83A);
  final ReceiptExportService _receiptExportService =
      ReceiptExportService.instance;
  bool _isReceiptActionRunning = false;

  List<_ReceiptItem> _allReceipts = <_ReceiptItem>[];
  bool _isLoading = true;
  String? _loadError;

  bool _showCancelled = false;
  _ReceiptPayFilter _payFilter = _ReceiptPayFilter.all;
  DateTime? _fromDate;
  DateTime? _toDate;

  List<_ReceiptItem> get _filteredReceipts {
    Iterable<_ReceiptItem> items = _allReceipts;

    final String donor = (widget.donorName ?? '').trim();
    if (donor.isNotEmpty) {
      items = items.where(
        (r) => r.donorDisplayName.toLowerCase().contains(donor.toLowerCase()),
      );
    }

    if (!_showCancelled) {
      items = items.where((r) => !r.isCancelled);
    }

    if (_payFilter == _ReceiptPayFilter.cash) {
      items = items.where((r) => r.mode == _ReceiptMode.cash);
    } else if (_payFilter == _ReceiptPayFilter.bank) {
      items = items.where((r) => r.mode != _ReceiptMode.cash);
    }

    if (_fromDate != null) {
      final DateTime from = DateTime(
        _fromDate!.year,
        _fromDate!.month,
        _fromDate!.day,
      );
      items = items.where((r) => !r.date.isBefore(from));
    }

    if (_toDate != null) {
      final DateTime to = DateTime(
        _toDate!.year,
        _toDate!.month,
        _toDate!.day,
        23,
        59,
        59,
      );
      items = items.where((r) => !r.date.isAfter(to));
    }

    return items.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  double get _totalAmount {
    return _filteredReceipts.fold<double>(0, (sum, r) => sum + r.amount);
  }

  @override
  void initState() {
    super.initState();
    _loadReceipts();
  }

  Future<void> _loadReceipts() async {
    try {
      final List<ReceiptRecord> receipts = await ReceiptService.instance
          .fetchReceipts();
      if (!mounted) return;

      setState(() {
        _allReceipts = receipts.map(_ReceiptItem.fromRecord).toList();
        _loadError = null;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _allReceipts = <_ReceiptItem>[];
        _loadError = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _openFilterDialog() async {
    final _ReceiptFilterDraft draft = _ReceiptFilterDraft(
      showCancelled: _showCancelled,
      payFilter: _payFilter,
      from: _fromDate,
      to: _toDate,
    );

    final _ReceiptFilterDraft? updated = await showDialog<_ReceiptFilterDraft>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ReceiptFilterDialog(draft: draft),
    );

    if (updated == null) return;

    setState(() {
      _showCancelled = updated.showCancelled;
      _payFilter = updated.payFilter;
      _fromDate = updated.from;
      _toDate = updated.to;
    });
  }

  void _resetFilters() {
    setState(() {
      _showCancelled = false;
      _payFilter = _ReceiptPayFilter.all;
      _fromDate = null;
      _toDate = null;
    });
  }

  Future<void> _openSearch() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ReceiptSearchPage(
          receipts: _filteredReceipts,
          onOpenReceipt: _openReceipt,
        ),
      ),
    );
  }

  void _refreshReceipts() {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    _loadReceipts();
  }

  void _openReceipt(_ReceiptItem item) {
    final GlobalKey captureKey = GlobalKey();

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ReceiptViewPage(
          receipt: item,
          receiptGreen: _receiptGreen,
          captureKey: captureKey,
          onShowPdf: () => _openReceiptPdf(item),
          onShare: () => _shareReceiptImage(item, captureKey),
          onMessage: () => _shareReceiptMessage(item),
        ),
      ),
    );
  }

  ReceiptExportData _toExportData(_ReceiptItem item) {
    return ReceiptExportData(
      receiptId: item.receiptId,
      receiptNo: item.receiptNo,
      receiptDate: _formatDateTime(item.date),
      donorName: item.donorDisplayName,
      address: item.addressLines.join(', '),
      pincode: item.pincode,
      fundType: item.fundType,
      amount: 'INR ${_formatMoney(item.amount)}',
      paymentMode: item.mode.listLabel,
      monthLabel: item.monthLabel,
      notes: item.notes,
    );
  }

  Future<String> _ensureReceiptPdfPath(_ReceiptItem item) async {
    final ReceiptExportData data = _toExportData(item);
    final file = await _receiptExportService.getOrCreatePdf(data);
    return file.path;
  }

  Future<T?> _runReceiptAction<T>({
    required String loadingText,
    required String errorTitle,
    required Future<T> Function() task,
  }) async {
    if (_isReceiptActionRunning) {
      return null;
    }

    _isReceiptActionRunning = true;
    bool dialogShown = false;

    if (mounted) {
      dialogShown = true;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (_) {
          return PopScope(
            canPop: false,
            child: AlertDialog(
              content: Row(
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.6),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      loadingText,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    try {
      return await task();
    } catch (error) {
      if (mounted) {
        await CommonAlert.showInfo(
          context,
          title: errorTitle,
          message: error.toString(),
        );
      }
      return null;
    } finally {
      _isReceiptActionRunning = false;
      if (dialogShown && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  Future<void> _openReceiptPdf(_ReceiptItem item) async {
    final String? filePath = await _runReceiptAction<String>(
      loadingText: 'Generating receipt PDF...',
      errorTitle: 'PDF error',
      task: () => _ensureReceiptPdfPath(item),
    );
    if (!mounted || filePath == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            _ReceiptPdfPage(pdfPath: filePath, receiptNo: item.receiptNo),
      ),
    );
  }

  Future<File> _captureReceiptImage(
    GlobalKey captureKey,
    _ReceiptItem item,
  ) async {
    final BuildContext? captureContext = captureKey.currentContext;
    if (captureContext == null) {
      throw StateError('Receipt image is not ready yet.');
    }

    final RenderRepaintBoundary? boundary =
        captureContext.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      throw StateError('Receipt image could not be captured.');
    }

    await WidgetsBinding.instance.endOfFrame;

    final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    if (byteData == null) {
      throw StateError('Receipt image encoding failed.');
    }

    final Directory tempDir = await getTemporaryDirectory();
    final String fileName = _sanitizeFileName(
      'receipt_${item.receiptId}_${item.receiptNo}_share',
    );
    final File file = File('${tempDir.path}/$fileName.png');
    await file.writeAsBytes(byteData.buffer.asUint8List());
    return file;
  }

  Future<void> _shareReceiptImage(
    _ReceiptItem item,
    GlobalKey captureKey,
  ) async {
    final File? imageFile = await _runReceiptAction<File>(
      loadingText: 'Preparing receipt image...',
      errorTitle: 'Share failed',
      task: () => _captureReceiptImage(captureKey, item),
    );
    if (imageFile == null) return;

    try {
      await Share.shareXFiles(
        <XFile>[XFile(imageFile.path)],
        subject: 'Receipt ${item.receiptNo}',
        text: 'Please find receipt ${item.receiptNo} attached.',
      );
    } catch (error) {
      if (!mounted) return;
      await CommonAlert.showInfo(
        context,
        title: 'Share failed',
        message: error.toString(),
      );
    }
  }

  Future<void> _shareReceiptMessage(_ReceiptItem item) async {
    try {
      final ReceiptExportData data = _toExportData(item);
      await Share.share(_receiptExportService.buildShareText(data));
    } catch (error) {
      if (!mounted) return;
      await CommonAlert.showInfo(
        context,
        title: 'Message failed',
        message: error.toString(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<_ReceiptItem> receipts = _filteredReceipts;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Receipts'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refreshReceipts,
            icon: const Icon(Icons.refresh_rounded, size: 20),
          ),
          IconButton(
            tooltip: 'Search receipt',
            onPressed: _openSearch,
            icon: const Icon(Icons.search_rounded),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              color: const Color(0xFFE7E7E7),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Text(
                    'TOTAL',
                    style: TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '₹ ${_formatMoney(_totalAmount)}',
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            _ReceiptListBottomBar(
              onFilter: _openFilterDialog,
              onReset: _resetFilters,
              onBack: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: AppColors.textGrey,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _loadError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textGrey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _refreshReceipts,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              )
            : receipts.isEmpty
            ? Center(
                child: Text(
                  'No receipts found',
                  style: TextStyle(
                    color: AppColors.textGrey.withOpacity(0.85),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                itemCount: receipts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final _ReceiptItem item = receipts[index];
                  return _ReceiptCard(
                    item: item,
                    receiptGreen: _receiptGreen,
                    onTap: () => _openReceipt(item),
                  );
                },
              ),
      ),
    );
  }
}

class _ReceiptItem {
  const _ReceiptItem({
    required this.receiptId,
    required this.receiptNo,
    required this.date,
    required this.donorDisplayName,
    required this.addressLines,
    required this.pincode,
    required this.monthLabel,
    required this.mode,
    required this.amount,
    required this.fundType,
    this.isCancelled = false,
    this.notes = '',
  });

  factory _ReceiptItem.fromRecord(ReceiptRecord record) {
    return _ReceiptItem(
      receiptId: record.receiptId,
      receiptNo: record.receiptNo,
      date: record.date,
      donorDisplayName: record.donorDisplayName,
      addressLines: record.addressLines,
      pincode: record.pincode,
      monthLabel: record.monthLabel,
      mode: _parseMode(record.paymentMode),
      amount: record.amount,
      fundType: record.fundType,
      isCancelled: record.isCancelled,
      notes: record.notes.trim(),
    );
  }

  static _ReceiptMode _parseMode(String value) {
    final String normalized = value.trim().toLowerCase();
    if (normalized.contains('cash')) return _ReceiptMode.cash;
    if (normalized.contains('upi')) return _ReceiptMode.upi;
    if (normalized.contains('cheque')) return _ReceiptMode.cheque;
    return _ReceiptMode.neft;
  }

  final int receiptId;
  final String receiptNo;
  final DateTime date;
  final String donorDisplayName;
  final List<String> addressLines;
  final String pincode;
  final String monthLabel;
  final _ReceiptMode mode;
  final double amount;
  final String fundType;
  final bool isCancelled;
  final String notes;
}

enum _ReceiptMode {
  cash('CASH'),
  cheque('BANK'),
  neft('BANK'),
  upi('BANK');

  const _ReceiptMode(this.listLabel);
  final String listLabel;
}

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({
    required this.item,
    required this.receiptGreen,
    required this.onTap,
  });

  final _ReceiptItem item;
  final Color receiptGreen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color headerColor = item.isCancelled
        ? AppColors.textGrey.withOpacity(0.65)
        : receiptGreen;

    return Material(
      color: AppColors.surface,
      elevation: 2,
      shadowColor: const Color(0x14000000),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderGrey),
          ),
          child: Column(
            children: [
              Container(
                height: 46,
                decoration: BoxDecoration(
                  color: headerColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Text(
                      item.receiptNo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(item.date),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                child: Column(
                  children: [
                    Text(
                      item.donorDisplayName,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primaryPurple,
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...item.addressLines.map(
                      (line) => Text(
                        line,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          height: 1.15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.pincode,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 2,
                width: double.infinity,
                color: AppColors.primaryPurple.withOpacity(0.65),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.monthLabel,
                        style: const TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      item.mode.listLabel,
                      style: TextStyle(
                        color: item.isCancelled
                            ? AppColors.textGrey
                            : receiptGreen,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '₹  ${_formatMoney(item.amount)}',
                      style: const TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptListBottomBar extends StatelessWidget {
  const _ReceiptListBottomBar({
    required this.onFilter,
    required this.onReset,
    required this.onBack,
  });

  final VoidCallback onFilter;
  final VoidCallback onReset;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            label: 'Filter',
            icon: Icons.filter_alt_outlined,
            onTap: onFilter,
          ),
          _BottomAction(
            label: 'Reset',
            icon: Icons.refresh_rounded,
            onTap: onReset,
          ),
          _BottomAction(
            label: 'Back',
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: onBack,
          ),
        ],
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

class _ReceiptFilterDraft {
  _ReceiptFilterDraft({
    required this.showCancelled,
    required this.payFilter,
    required this.from,
    required this.to,
  });

  bool showCancelled;
  _ReceiptPayFilter payFilter;
  DateTime? from;
  DateTime? to;
}

class _ReceiptFilterDialog extends StatefulWidget {
  const _ReceiptFilterDialog({required this.draft});

  final _ReceiptFilterDraft draft;

  @override
  State<_ReceiptFilterDialog> createState() => _ReceiptFilterDialogState();
}

class _ReceiptFilterDialogState extends State<_ReceiptFilterDialog> {
  late bool _showCancelled = widget.draft.showCancelled;
  late _ReceiptPayFilter _pay = widget.draft.payFilter;
  DateTime? _from;
  DateTime? _to;

  @override
  void initState() {
    super.initState();
    _from = widget.draft.from;
    _to = widget.draft.to;
  }

  Future<void> _pickFrom() async {
    final DateTime now = DateTime.now();
    final DateTime initial = _from ?? now;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1),
    );
    if (picked == null) return;
    setState(() => _from = picked);
  }

  Future<void> _pickTo() async {
    final DateTime now = DateTime.now();
    final DateTime initial = _to ?? now;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1),
    );
    if (picked == null) return;
    setState(() => _to = picked);
  }

  Future<void> _apply() async {
    if (_from != null && _to != null) {
      if (_to!.isBefore(_from!)) {
        await CommonAlert.showInfo(
          context,
          title: 'Invalid date range',
          message: 'To date should be on/after From date.',
        );
        return;
      }
    }

    final _ReceiptFilterDraft draft = _ReceiptFilterDraft(
      showCancelled: _showCancelled,
      payFilter: _pay,
      from: _from,
      to: _to,
    );

    if (!mounted) return;
    Navigator.of(context).pop(draft);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Filter'),
      content: SizedBox(
        width: 420,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.68,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _OutlineTile(
                  child: Row(
                    children: [
                      Checkbox(
                        value: _showCancelled,
                        activeColor: AppColors.primaryPurple,
                        onChanged: (v) =>
                            setState(() => _showCancelled = v ?? false),
                      ),
                      const Expanded(
                        child: Text(
                          'Show Cancelled Receipts',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _OutlineTile(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      _PayRadio(
                        label: 'ALL',
                        value: _ReceiptPayFilter.all,
                        groupValue: _pay,
                        onChanged: (v) => setState(() => _pay = v),
                      ),
                      _PayRadio(
                        label: 'CASH',
                        value: _ReceiptPayFilter.cash,
                        groupValue: _pay,
                        onChanged: (v) => setState(() => _pay = v),
                      ),
                      _PayRadio(
                        label: 'BANK',
                        value: _ReceiptPayFilter.bank,
                        groupValue: _pay,
                        onChanged: (v) => setState(() => _pay = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _DateField(value: _from, onTap: _pickFrom),
                const SizedBox(height: 12),
                _DateField(value: _to, onTap: _pickTo),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'CANCEL',
            style: TextStyle(
              color: AppColors.textGrey,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        TextButton(
          onPressed: _apply,
          child: const Text(
            'APPLY',
            style: TextStyle(
              color: AppColors.primaryPurple,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _OutlineTile extends StatelessWidget {
  const _OutlineTile({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.primaryPurple.withOpacity(0.35),
          width: 1.4,
        ),
      ),
      child: child,
    );
  }
}

class _PayRadio extends StatelessWidget {
  const _PayRadio({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String label;
  final _ReceiptPayFilter value;
  final _ReceiptPayFilter groupValue;
  final ValueChanged<_ReceiptPayFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<_ReceiptPayFilter>(
          value: value,
          groupValue: groupValue,
          activeColor: AppColors.primaryPurple,
          onChanged: (v) {
            if (v == null) return;
            onChanged(v);
          },
        ),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.value, required this.onTap});

  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String text = value == null ? 'DD/MM/YYYY' : _formatDate(value!);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: _OutlineTile(
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: value == null
                      ? AppColors.textGrey.withOpacity(0.7)
                      : AppColors.textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.calendar_month_rounded,
              color: AppColors.primaryPurple,
              size: 26,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptSearchPage extends StatefulWidget {
  const _ReceiptSearchPage({
    required this.receipts,
    required this.onOpenReceipt,
  });

  final List<_ReceiptItem> receipts;
  final ValueChanged<_ReceiptItem> onOpenReceipt;

  @override
  State<_ReceiptSearchPage> createState() => _ReceiptSearchPageState();
}

class _ReceiptSearchPageState extends State<_ReceiptSearchPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_ReceiptItem> get _results {
    final String q = _controller.text.trim().toLowerCase();
    if (q.isEmpty) return widget.receipts;

    return widget.receipts.where((r) {
      return r.receiptNo.toLowerCase().contains(q) ||
          r.donorDisplayName.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final List<_ReceiptItem> results = _results;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Search Receipt')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Receipt no / Donor name',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppColors.borderGrey.withOpacity(0.9),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppColors.borderGrey.withOpacity(0.9),
                    ),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                itemCount: results.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = results[index];
                  return _ReceiptCard(
                    item: item,
                    receiptGreen: const Color(0xFF09A83A),
                    onTap: () {
                      Navigator.of(context).pop();
                      widget.onOpenReceipt(item);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptViewPage extends StatelessWidget {
  const _ReceiptViewPage({
    required this.receipt,
    required this.receiptGreen,
    required this.captureKey,
    required this.onShowPdf,
    required this.onShare,
    required this.onMessage,
  });

  final _ReceiptItem receipt;
  final Color receiptGreen;
  final GlobalKey captureKey;
  final VoidCallback onShowPdf;
  final VoidCallback onShare;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Receipt View')),
      bottomNavigationBar: _ReceiptViewBottomBar(
        onShowPdf: onShowPdf,
        onShare: onShare,
        onMessage: onMessage,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 110),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderGrey),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 12,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 46,
                            backgroundColor: AppColors.lavender,
                            child: Icon(
                              Icons.person_rounded,
                              size: 56,
                              color: AppColors.primaryPurple,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.primaryPurple.withOpacity(
                                    0.35,
                                  ),
                                  width: 1.4,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    decoration: const BoxDecoration(
                                      color: AppColors.primaryPurple,
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(10),
                                      ),
                                    ),
                                    child: Text(
                                      receipt.donorDisplayName,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      10,
                                      10,
                                      10,
                                      10,
                                    ),
                                    child: Column(
                                      children: [
                                        ...receipt.addressLines.map(
                                          (line) => Text(
                                            line,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: AppColors.textGrey,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          receipt.pincode,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: AppColors.textGrey,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 2,
                      width: double.infinity,
                      color: AppColors.primaryPurple.withOpacity(0.65),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: onShare,
                            icon: const Icon(Icons.share_rounded),
                            color: AppColors.primaryPurple,
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            onPressed: onShowPdf,
                            icon: const Icon(Icons.picture_as_pdf_rounded),
                            color: AppColors.primaryPurple,
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            onPressed: onMessage,
                            icon: const Icon(Icons.message_rounded),
                            color: AppColors.primaryPurple,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              RepaintBoundary(
                key: captureKey,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryPurple.withOpacity(0.35),
                      width: 1.4,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryPurple,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Receipt',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      _ReceiptLine(
                        icon: Icons.receipt_long_rounded,
                        label: receipt.receiptNo,
                      ),
                      _ReceiptLine(
                        icon: Icons.calendar_month_rounded,
                        label: '${_formatDateTime(receipt.date)}',
                      ),
                      _ReceiptLine(
                        icon: Icons.currency_rupee_rounded,
                        label: _formatMoney(receipt.amount),
                      ),
                      _ReceiptLine(
                        icon: Icons.grid_view_rounded,
                        label: receipt.monthLabel,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.primaryPurple.withOpacity(0.35),
                              width: 1.2,
                            ),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      receipt.fundType,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.primaryPurple,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '₹  ${_formatMoney(receipt.amount)}',
                                    style: const TextStyle(
                                      color: AppColors.primaryPurple,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Payed as :${receipt.mode == _ReceiptMode.cash ? 'CASH' : 'BANK'}',
                                style: const TextStyle(
                                  color: AppColors.primaryPurple,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: Text(
                          'Donation for the month of ${receipt.monthLabel}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.primaryPurple.withOpacity(0.9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (receipt.notes.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Notes',
                                style: TextStyle(
                                  color: AppColors.textGrey,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                receipt.notes,
                                style: const TextStyle(
                                  color: AppColors.textGrey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Signature',
                              style: TextStyle(
                                color: AppColors.textGrey,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              height: 110,
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.borderGrey),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Signature preview (TODO)',
                                style: TextStyle(
                                  color: AppColors.textGrey.withOpacity(0.8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptLine extends StatelessWidget {
  const _ReceiptLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(height: 1, color: AppColors.borderGrey.withOpacity(0.9)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primaryPurple),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReceiptPdfPage extends StatefulWidget {
  const _ReceiptPdfPage({required this.pdfPath, required this.receiptNo});

  final String pdfPath;
  final String receiptNo;

  @override
  State<_ReceiptPdfPage> createState() => _ReceiptPdfPageState();
}

class _ReceiptPdfPageState extends State<_ReceiptPdfPage> {
  bool _isReady = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Receipt ${widget.receiptNo}')),
      body: SafeArea(
        child: Stack(
          children: [
            PDFView(
              filePath: widget.pdfPath,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: true,
              pageFling: true,
              onRender: (_) {
                if (!mounted) return;
                setState(() => _isReady = true);
              },
              onError: (error) {
                if (!mounted) return;
                setState(() {
                  _error = error.toString();
                  _isReady = true;
                });
              },
            ),
            if (!_isReady)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptViewBottomBar extends StatelessWidget {
  const _ReceiptViewBottomBar({
    required this.onShowPdf,
    required this.onShare,
    required this.onMessage,
    required this.onBack,
  });

  final VoidCallback onShowPdf;
  final VoidCallback onShare;
  final VoidCallback onMessage;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            label: 'View PDF',
            icon: Icons.picture_as_pdf_rounded,
            onTap: onShowPdf,
          ),
          _BottomAction(
            label: 'Share',
            icon: Icons.share_rounded,
            onTap: onShare,
          ),
          _BottomAction(
            label: 'Message',
            icon: Icons.message_rounded,
            onTap: onMessage,
          ),
          _BottomAction(
            label: 'Back',
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: onBack,
          ),
        ],
      ),
    );
  }
}

String _sanitizeFileName(String value) {
  return value.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
}

String _formatDate(DateTime date) {
  final String dd = date.day.toString().padLeft(2, '0');
  final String mm = date.month.toString().padLeft(2, '0');
  final String yyyy = date.year.toString();
  return '$dd/$mm/$yyyy';
}

String _formatDateTime(DateTime date) {
  String two(int n) => n.toString().padLeft(2, '0');
  final String dd = two(date.day);
  final String mm = two(date.month);
  final String yyyy = date.year.toString();

  int hour = date.hour;
  final String ampm = hour >= 12 ? 'PM' : 'AM';
  hour = hour % 12;
  if (hour == 0) hour = 12;

  final String hh = two(hour);
  final String min = two(date.minute);

  return '$dd/$mm/$yyyy $hh:$min $ampm';
}

String _formatMoney(double value) {
  return value.toStringAsFixed(2);
}
