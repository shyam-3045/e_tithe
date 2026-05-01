import 'dart:io';

import 'package:flutter_html_to_pdf/flutter_html_to_pdf.dart';
import 'package:path_provider/path_provider.dart';

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

  /// In-memory path cache: cacheKey → absolute PDF path
  final Map<String, String> _pdfPathCache = {};

  /// In-flight generation futures to prevent duplicate conversions
  final Map<String, Future<File>> _inFlight = {};

  /// Optionally call this early (e.g. when a receipt screen opens) so the PDF
  /// is ready before the user taps Share/Download.
  void prewarm(ReceiptExportData data) {
    getOrCreatePdf(data); // fire-and-forget
  }

  Future<File> getOrCreatePdf(ReceiptExportData data) {
    final key = _cacheKey(data);

    // If already generating, return the same future — no duplicate work.
    if (_inFlight.containsKey(key)) return _inFlight[key]!;

    final future = _generatePdf(key, data);
    _inFlight[key] = future;

    // Remove from in-flight map once done (success or error).
    future.whenComplete(() => _inFlight.remove(key));

    return future;
  }

  Future<File> _generatePdf(String key, ReceiptExportData data) async {
    // 1. Return cached file if it still exists on disk.
    final cachedPath = _pdfPathCache[key];
    if (cachedPath != null) {
      final cached = File(cachedPath);
      if (await cached.exists()) return cached;
      _pdfPathCache.remove(key); // stale entry
    }

    // 2. Build output path deterministically so we can also check disk cache
    //    across cold starts (process restarts keep the temp dir on most OSes).
    final tempDir = await getTemporaryDirectory();
    final fileName = _safeFileName('receipt_${data.receiptId}_${data.receiptNo}');
    final expectedPath = '${tempDir.path}/$fileName.pdf';

    final existing = File(expectedPath);
    if (await existing.exists()) {
      _pdfPathCache[key] = expectedPath;
      return existing;
    }

    // 3. Generate — the actual platform-channel call.
    final html = _buildHtml(_placeholderMap(data));
    final generated = await FlutterHtmlToPdf.convertFromHtmlContent(
      html,
      tempDir.path,
      fileName,
    );

    _pdfPathCache[key] = generated.path;
    return generated;
  }

  String buildShareText(ReceiptExportData data) => [
        'Receipt ${data.receiptNo}',
        'Donor: ${data.donorName}',
        'Date: ${data.receiptDate}',
        'Fund: ${data.fundType}',
        'Amount: ${data.amount}',
        'Mode: ${data.paymentMode}',
      ].join('\n');

  /// Evict a single entry (call after editing a receipt so it regenerates).
  void invalidate(ReceiptExportData data) => _pdfPathCache.remove(_cacheKey(data));

  /// Wipe everything (e.g. on logout).
  void clearCache() => _pdfPathCache.clear();

  // ─── helpers ────────────────────────────────────────────────────────────────

  String _cacheKey(ReceiptExportData data) =>
      '${data.receiptId}_${data.receiptNo}'.toLowerCase();

  String _safeFileName(String value) =>
      value.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');

  Map<String, String> _placeholderMap(ReceiptExportData data) => {
        'receipt_no': _esc(data.receiptNo),
        'receipt_date': _esc(data.receiptDate),
        'donor_name': _esc(data.donorName),
        'address': _esc(data.address),
        'pincode': _esc(data.pincode),
        'fund_type': _esc(data.fundType),
        'amount': _esc(data.amount),
        'payment_mode': _esc(data.paymentMode),
        'month_label': _esc(data.monthLabel),
        'notes': _esc(data.notes.isEmpty ? '-' : data.notes),
      };

  // Minimal, fast HTML — no web-fonts, no external resources, flat CSS.
  String _buildHtml(Map<String, String> v) => '''<!DOCTYPE html>
<html><head><meta charset="utf-8"><style>
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:Arial,sans-serif;font-size:13px;color:#222;padding:20px}
h1{text-align:center;font-size:20px;letter-spacing:1px;margin-bottom:14px}
.box{border:1px solid #ddd;border-radius:6px;padding:10px;margin-bottom:12px}
.row{margin-bottom:6px}
.lbl{font-weight:700}
table{width:100%;border-collapse:collapse;margin-bottom:12px}
th,td{border:1px solid #ddd;padding:7px;text-align:left;font-size:13px}
th{background:#f5f5f5}
.r{text-align:right}
.foot{font-size:11px;color:#888;margin-top:10px}
</style></head><body>
<h1>RECEIPT</h1>
<div class="box">
  <div class="row"><span class="lbl">Receipt No:</span> ${v['receipt_no']}</div>
  <div class="row"><span class="lbl">Date:</span> ${v['receipt_date']}</div>
  <div class="row"><span class="lbl">Donor:</span> ${v['donor_name']}</div>
  <div class="row"><span class="lbl">Address:</span> ${v['address']} - ${v['pincode']}</div>
</div>
<table>
  <thead><tr><th>Particulars</th><th>Month</th><th>Mode</th><th class="r">Amount</th></tr></thead>
  <tbody><tr>
    <td>${v['fund_type']}</td><td>${v['month_label']}</td>
    <td>${v['payment_mode']}</td><td class="r">${v['amount']}</td>
  </tr></tbody>
</table>
<div class="box"><div class="row"><span class="lbl">Notes:</span> ${v['notes']}</div></div>
<div class="foot">Generated from e_tithe mobile application.</div>
</body></html>''';

  String _esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
}