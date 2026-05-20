import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../common/constants/app_colors.dart';
import '../../common/services/receipt_export_service.dart';
import '../../common/services/receipt_html_generator_service.dart';
import '../../common/widgets/common_alert.dart';

class ReceiptPdfWebViewPage extends StatefulWidget {
  const ReceiptPdfWebViewPage({super.key, required this.receiptData});

  final ReceiptExportData receiptData;

  @override
  State<ReceiptPdfWebViewPage> createState() => _ReceiptPdfWebViewPageState();
}

class _ReceiptPdfWebViewPageState extends State<ReceiptPdfWebViewPage> {
  static const MethodChannel _downloadChannel = MethodChannel('download_saver');
  late WebViewController _webViewController;
  bool _isLoading = true;
  bool _isActionRunning = false;
  static const Duration _pdfTimeout = Duration(seconds: 20);

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              setState(() => _isLoading = false);
              CommonAlert.showInfo(
                context,
                title: 'Error loading receipt',
                message: error.description,
              );
            }
          },
        ),
      )
      ..loadHtmlString(
        ReceiptHtmlGeneratorService.instance.generateReceiptHtml(
          widget.receiptData,
        ),
      );
  }

  Future<File> _buildPdfFile({required Directory targetDir}) async {
    final String fileName = _sanitizeFileName(
      'receipt_${widget.receiptData.receiptNo}',
    );
    final Uint8List pdfBytes = await _buildPdfBytes();
    final File outputFile = File('${targetDir.path}/$fileName.pdf');
    await outputFile.writeAsBytes(pdfBytes, flush: true);
    return outputFile;
  }

  Future<Uint8List> _buildPdfBytes() async {
    final ReceiptExportData data = widget.receiptData;
    final pw.Document doc = pw.Document();

    final String amountValue = data.amount.trim();
    final String amountText = amountValue.isEmpty
        ? ''
        : (amountValue.toLowerCase().startsWith('rs')
              ? amountValue
              : 'Rs $amountValue');

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Text(
                'RECEIPT',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Receipt No: ${data.receiptNo}',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.SizedBox(height: 16),
              _pdfSection(
                title: 'Donor Details',
                rows: [
                  _pdfRow('Name', data.donorName),
                  _pdfRow('Address', data.address),
                  _pdfRow('Pincode', data.pincode),
                ],
              ),
              pw.SizedBox(height: 12),
              _pdfSection(
                title: 'Transaction Details',
                rows: [
                  _pdfRow('Receipt Date', data.receiptDate),
                  _pdfRow('Month', data.monthLabel),
                  _pdfRow('Fund Type', data.fundType),
                  _pdfRow('Payment Mode', data.paymentMode),
                ],
              ),
              pw.SizedBox(height: 12),
              _pdfSection(
                title: 'Amount',
                rows: [_pdfRow('Total Amount Received', amountText)],
              ),
              if (data.notes.trim().isNotEmpty) ...[
                pw.SizedBox(height: 12),
                _pdfNotes(data.notes),
              ],
              pw.Spacer(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _pdfSignatureLine('Donor Signature'),
                  _pdfSignatureLine('Authorized Signature'),
                ],
              ),
              pw.SizedBox(height: 14),
              pw.Text(
                'Thank you for your generous donation',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Generated on: ${DateTime.now().toString().split('.').first}',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  pw.Widget _pdfSection({
    required String title,
    required List<pw.Widget> rows,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            color: PdfColors.black,
            padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: pw.Text(
              title.toUpperCase(),
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 10,
                letterSpacing: 1.2,
              ),
            ),
          ),
          ...rows,
        ],
      ),
    );
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.black, width: 0.5),
        ),
      ),
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 140,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value.trim().isEmpty ? 'N/A' : value,
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfNotes(String notes) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black),
      ),
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        'Notes: ${notes.trim()}',
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
  }

  pw.Widget _pdfSignatureLine(String label) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(width: 160, height: 1, color: PdfColors.black),
        pw.SizedBox(height: 4),
        pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
      ],
    );
  }

  Future<T?> _runAction<T>({
    required String loadingText,
    required String errorTitle,
    required Future<T> Function() task,
  }) async {
    if (_isActionRunning) return null;
    _isActionRunning = true;

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
      return await task().timeout(
        _pdfTimeout,
        onTimeout: () {
          throw TimeoutException('PDF generation timed out.');
        },
      );
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
      _isActionRunning = false;
      if (dialogShown && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  Future<Directory> _resolveSaveDirectory() async {
    if (Platform.isAndroid) {
      final Directory downloads = Directory('/storage/emulated/0/Download');
      if (!await downloads.exists()) {
        await downloads.create(recursive: true);
      }
      return downloads;
    }

    if (Platform.isIOS) {
      return getApplicationDocumentsDirectory();
    }

    final Directory? downloads = await getDownloadsDirectory();
    if (downloads != null) return downloads;

    return getApplicationDocumentsDirectory();
  }

  String _sanitizeFileName(String value) {
    return value.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  Future<void> _sharePdf() async {
    final Directory tempDir = await getTemporaryDirectory();
    final File? pdfFile = await _runAction<File>(
      loadingText: 'Preparing PDF...',
      errorTitle: 'Share failed',
      task: () => _buildPdfFile(targetDir: tempDir),
    );
    if (pdfFile == null) return;

    try {
      await Share.shareXFiles(
        <XFile>[XFile(pdfFile.path)],
        subject: 'Receipt ${widget.receiptData.receiptNo}',
        text: ReceiptExportService.instance.buildShareText(widget.receiptData),
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

  Future<void> _savePdf() async {
    try {
      if (Platform.isAndroid) {
        final String fileName =
            '${_sanitizeFileName('receipt_${widget.receiptData.receiptNo}')}.pdf';
        final String? savedPath = await _runAction<String>(
          loadingText: 'Saving PDF...',
          errorTitle: 'Save failed',
          task: () => _savePdfToDownloads(fileName),
        );
        if (savedPath == null || !mounted) return;

        await CommonAlert.showInfo(
          context,
          title: 'PDF saved',
          message: 'Saved to Downloads ($savedPath)',
        );
      } else {
        final Directory targetDir = await _resolveSaveDirectory();
        final File? pdfFile = await _runAction<File>(
          loadingText: 'Saving PDF...',
          errorTitle: 'Save failed',
          task: () => _buildPdfFile(targetDir: targetDir),
        );
        if (pdfFile == null || !mounted) return;

        await CommonAlert.showInfo(
          context,
          title: 'PDF saved',
          message: 'Saved to ${pdfFile.path}',
        );
      }
    } catch (error) {
      if (mounted) {
        await CommonAlert.showInfo(
          context,
          title: 'Save failed',
          message: error.toString(),
        );
      }
    }
  }

  Future<String> _savePdfToDownloads(String fileName) async {
    final Uint8List pdfBytes = await _buildPdfBytes();

    final String? savedPath = await _downloadChannel.invokeMethod<String>(
      'savePdfToDownloads',
      <String, dynamic>{'fileName': fileName, 'bytes': pdfBytes},
    );

    if (savedPath == null || savedPath.trim().isEmpty) {
      throw StateError('Save failed: empty path.');
    }
    return savedPath;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Receipt'), elevation: 2),
      body: Stack(
        children: [
          WebViewWidget(controller: _webViewController),
          if (_isLoading)
            Container(
              color: Colors.white.withValues(alpha: 0.7),
              alignment: Alignment.center,
              child: const CircularProgressIndicator(),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
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
              _ActionButton(
                label: 'Share',
                icon: Icons.share_rounded,
                onTap: _sharePdf,
              ),
              _ActionButton(
                label: 'Save',
                icon: Icons.download_rounded,
                onTap: _savePdf,
              ),
              _ActionButton(
                label: 'Back',
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
