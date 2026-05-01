class ReceiptExportData {
  const ReceiptExportData({
    required this.receiptId,
    required this.receiptNo,
    required this.receiptDate,
    required this.donorName,
    required this.address,
    required this.pincode,
    required this.fundType,
    required this.amount,
    required this.paymentMode,
    required this.monthLabel,
    required this.notes,
  });

  final int receiptId;
  final String receiptNo;
  final String receiptDate;
  final String donorName;
  final String address;
  final String pincode;
  final String fundType;
  final String amount;
  final String paymentMode;
  final String monthLabel;
  final String notes;
}

class ReceiptExportService {
  ReceiptExportService._();

  static final ReceiptExportService instance = ReceiptExportService._();

  /// Wipe everything (e.g. on logout).
  void clearCache() {
    // No-op since we're not caching PDFs anymore
  }

  String buildShareText(ReceiptExportData data) => [
    'Receipt ${data.receiptNo}',
    'Donor: ${data.donorName}',
    'Date: ${data.receiptDate}',
    'Fund: ${data.fundType}',
    'Amount: ${data.amount}',
    'Mode: ${data.paymentMode}',
  ].join('\n');
}
