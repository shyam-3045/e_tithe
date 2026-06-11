import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
import '../../common/services/receipt_service.dart';

const PdfColor _receiptLineColor = PdfColor.fromInt(0xFF666666);
const PdfColor _receiptBorderColor = PdfColor.fromInt(0xFF8D67E8);

Future<File> buildReceiptPdfFile({
  required ReceiptExportData data,
  required Directory targetDir,
  String? fileNameSuffix,
}) async {
  final String suffix = (fileNameSuffix ?? '').trim();
  final String fileName = sanitizeReceiptPdfFileName(
    suffix.isEmpty
        ? 'receipt_${data.receiptNo}'
        : 'receipt_${data.receiptNo}_$suffix',
  );
  final Uint8List pdfBytes = await buildReceiptPdfBytes(data);
  final File outputFile = File('${targetDir.path}/$fileName.pdf');
  await outputFile.writeAsBytes(pdfBytes, flush: true);
  return outputFile;
}

Future<Uint8List> buildReceiptPdfBytes(ReceiptExportData data) async {
  final pw.Document doc = pw.Document();
  final ByteData logoBytes = await rootBundle.load('logo.jpeg');
  final pw.MemoryImage logoImage = pw.MemoryImage(
    logoBytes.buffer.asUint8List(),
  );

  final String amountText = _normalizeAmountText(data.amount);

  final List<ReceiptFundDetail> pdfDetails = data.fundDetails.isNotEmpty
      ? data.fundDetails
      : [
          ReceiptFundDetail(
            companyId: 0,
            companyName: '',
            regionName: '',
            regionAddress: '',
            companyAddress: '',
            email: '',
            mobile: '',
            fundName: data.fundType,
            amount: double.tryParse(
                    data.amount.replaceAll(RegExp(r'[^0-9.]'), '')) ??
                0.0,
          ),
        ];
  final ReceiptFundDetail companyDetail = _resolveCompanyDetail(pdfDetails);
  final String companyName = _valueOrFallback(
    companyDetail.companyName,
    'SCRIPTURE UNION & CSSM COUNCIL OF INDIA',
  );
  final String regionName = _valueOrFallback(
    companyDetail.regionName,
    'TAMIL NADU SOUTH',
  );
  final String regionAddress = companyDetail.regionAddress.trim();
  final String companyAddress = _valueOrFallback(
    companyDetail.companyAddress,
    "No.56 C/4 (Upstairs) St. Mary's Street, Perumalpura mTirunelveli-627007",
  );
  final String companyMobile = companyDetail.mobile.trim();
  final String companyEmail = companyDetail.email.trim();
  final String footerContactLine = <String>[
    if (companyMobile.isNotEmpty) 'Phone: $companyMobile',
    if (companyEmail.isNotEmpty) 'Email: $companyEmail',
  ].join(' | ');
  final String donorAddress = _composeDonorAddress(
    address: data.address,
    pincode: data.pincode,
  );

  final List<pw.TableRow> tableRows = [
    pw.TableRow(
      decoration: const pw.BoxDecoration(
        color: PdfColors.white,
      ),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 6),
          child: pw.Text(
            'Particulars',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 6),
          child: pw.Text(
            'Amount (Rs.)',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
    ...pdfDetails.map((detail) {
      final String detailAmountText = 'Rs. ${detail.amount.toStringAsFixed(2)}';
      return pw.TableRow(
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text(
              detail.fundName,
              style: const pw.TextStyle(fontSize: 9.5),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text(
              detailAmountText,
              textAlign: pw.TextAlign.right,
              style: const pw.TextStyle(fontSize: 9.5),
            ),
          ),
        ],
      );
    }),
    pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            'Total',
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            amountText,
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  ];

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a5,
      margin: const pw.EdgeInsets.all(14),
      build: (context) {
        return pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _receiptBorderColor, width: 1),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.fromLTRB(10, 10, 10, 9),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: _receiptLineColor, width: 1),
                  ),
                ),
                child: pw.Table(
                  columnWidths: const {
                    0: pw.FixedColumnWidth(48),
                    1: pw.FlexColumnWidth(),
                    2: pw.FixedColumnWidth(48),
                  },
                  children: [
                    pw.TableRow(
                      verticalAlignment: pw.TableCellVerticalAlignment.top,
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 2),
                          child: pw.SizedBox(
                            width: 42,
                            height: 42,
                            child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                          ),
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                          children: [
                            pw.Text(
                              companyName.toUpperCase(),
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                fontSize: 10.6,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 3),
                            pw.Text(
                              companyAddress,
                              textAlign: pw.TextAlign.center,
                              style: const pw.TextStyle(fontSize: 7.8),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              regionName,
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                fontSize: 7.8,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            if (regionAddress.isNotEmpty)
                              pw.Text(
                                regionAddress,
                                textAlign: pw.TextAlign.center,
                                style: const pw.TextStyle(fontSize: 7.8),
                              ),
                          ],
                        ),
                        pw.SizedBox(),
                      ],
                    ),
                  ],
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 6),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: _receiptLineColor, width: 1),
                  ),
                ),
                child: pw.Text(
                  'RECEIPT',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 10.2,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: _receiptLineColor, width: 1),
                  ),
                ),
                child: pw.Table(
                  columnWidths: const {
                    0: pw.FlexColumnWidth(),
                    1: pw.FixedColumnWidth(184),
                  },
                  children: [
                    pw.TableRow(
                      verticalAlignment: pw.TableCellVerticalAlignment.top,
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(right: 10),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'Received with thanks from ${data.donorName}',
                                style: pw.TextStyle(
                                  fontSize: 8.4,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.SizedBox(height: 8),
                              pw.Text(
                                'Address:',
                                style: pw.TextStyle(
                                  fontSize: 8.0,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.Text(
                                donorAddress,
                                style: const pw.TextStyle(fontSize: 8.0),
                              ),
                            ],
                          ),
                        ),
                        pw.Column(
                          children: [
                            _buildInfoBox(
                              label: 'Receipt #:',
                              value: data.receiptNo,
                            ),
                            pw.SizedBox(height: 8),
                            _buildInfoBox(
                              label: 'Date:',
                              value: data.receiptDate,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.Table(
                border: const pw.TableBorder(
                  top: pw.BorderSide(color: _receiptLineColor, width: 1),
                  bottom: pw.BorderSide(color: _receiptLineColor, width: 1),
                  verticalInside: pw.BorderSide(
                    color: _receiptLineColor,
                    width: 1,
                  ),
                  horizontalInside: pw.BorderSide(
                    color: _receiptLineColor,
                    width: 1,
                  ),
                ),
                columnWidths: const {
                  0: pw.FlexColumnWidth(3.2),
                  1: pw.FlexColumnWidth(1.4),
                },
                children: tableRows,
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 9,
                ),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: _receiptLineColor, width: 1),
                  ),
                ),
                child: pw.RichText(
                  text: pw.TextSpan(
                    style: const pw.TextStyle(fontSize: 8.4),
                    children: [
                      pw.TextSpan(
                        text: 'Received as: ',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.TextSpan(text: data.paymentMode),
                    ],
                  ),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 9,
                ),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: _receiptLineColor, width: 1),
                  ),
                ),
                child: pw.RichText(
                  text: pw.TextSpan(
                    style: const pw.TextStyle(fontSize: 8.4),
                    children: [
                      pw.TextSpan(
                        text: 'Amount in Words: ',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.TextSpan(text: '$amountText only'),
                    ],
                  ),
                ),
              ),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.fromLTRB(10, 14, 10, 14),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: _receiptLineColor, width: 1),
                    ),
                  ),
                  child: pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Column(
                      mainAxisSize: pw.MainAxisSize.min,
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'for Scripture Union & CSSM council of India',
                          style: const pw.TextStyle(fontSize: 8.3),
                        ),
                        pw.Container(
                          margin: const pw.EdgeInsets.only(top: 24),
                          width: 140,
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(
                              top: pw.BorderSide(
                                color: _receiptLineColor,
                                width: 1,
                              ),
                            ),
                          ),
                          padding: const pw.EdgeInsets.only(top: 3),
                          child: pw.Text(
                            'Authorised Signatory',
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                              fontSize: 8.5,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: pw.Column(
                  children: [
                    pw.Text(
                      '"Your word is lamp to my feet and a light for my path. Psalms 119:105"',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 7.6,
                        fontWeight: pw.FontWeight.bold,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      companyAddress,
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(fontSize: 7.4),
                    ),
                    if (footerContactLine.isNotEmpty) pw.SizedBox(height: 3),
                    if (footerContactLine.isNotEmpty)
                      pw.Text(
                        footerContactLine,
                        textAlign: pw.TextAlign.center,
                        style: const pw.TextStyle(fontSize: 7.4),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );

  return doc.save();
}

String sanitizeReceiptPdfFileName(String value) {
  return value.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
}

ReceiptFundDetail _resolveCompanyDetail(List<ReceiptFundDetail> details) {
  for (final ReceiptFundDetail detail in details) {
    if (detail.companyName.trim().isNotEmpty ||
        detail.regionName.trim().isNotEmpty ||
        detail.regionAddress.trim().isNotEmpty ||
        detail.companyAddress.trim().isNotEmpty ||
        detail.mobile.trim().isNotEmpty ||
        detail.email.trim().isNotEmpty) {
      return detail;
    }
  }
  return details.first;
}

String _valueOrFallback(String value, String fallback) {
  final String normalized = value.trim();
  return normalized.isEmpty ? fallback : normalized;
}

String _composeDonorAddress({
  required String address,
  required String pincode,
}) {
  final List<String> values = <String>[
    address.trim(),
    pincode.trim(),
  ].where((value) => value.isNotEmpty).toList();
  return values.isEmpty ? 'Address not provided' : values.join(', ');
}

String _normalizeAmountText(String value) {
  final String normalized = value.trim();
  if (normalized.isEmpty) return '';

  final String digitsOnly = normalized.replaceAll(RegExp(r'[^0-9.]'), '');
  final double? parsed = double.tryParse(digitsOnly);
  if (parsed == null) return normalized;
  return 'Rs. ${parsed.toStringAsFixed(2)}';
}

pw.Widget _buildInfoBox({
  required String label,
  required String value,
}) {
  return pw.Container(
    width: 176,
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: _receiptLineColor, width: 1),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
    ),
    child: pw.Table(
      columnWidths: const {
        0: pw.FixedColumnWidth(72),
        1: pw.FlexColumnWidth(),
      },
      children: [
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.only(right: 8),
              child: pw.Text(
                label,
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(
                  fontSize: 8.3,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Text(
              value,
              textAlign: pw.TextAlign.right,
              style: const pw.TextStyle(fontSize: 8.3),
            ),
          ],
        ),
      ],
    ),
  );
}

class ReceiptPdfWebViewPage extends StatefulWidget {
  const ReceiptPdfWebViewPage({super.key, required this.receiptData});

  final ReceiptExportData receiptData;

  @override
  State<ReceiptPdfWebViewPage> createState() => _ReceiptPdfWebViewPageState();
}

class _ReceiptPdfWebViewPageState extends State<ReceiptPdfWebViewPage> {
  static const MethodChannel _downloadChannel = MethodChannel('download_saver');
  WebViewController? _webViewController;
  bool _isLoading = true;
  bool _isActionRunning = false;
  bool _isWebViewReady = false;
  static const Duration _pdfTimeout = Duration(seconds: 20);

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    try {
      final String logoBase64 = await _loadLogoBase64();
      final WebViewController controller = WebViewController()
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
        );

      await controller.loadHtmlString(
        ReceiptHtmlGeneratorService.instance.generateReceiptHtml(
          widget.receiptData,
          logoBase64: logoBase64,
        ),
      );

      if (!mounted) return;
      setState(() {
        _webViewController = controller;
        _isWebViewReady = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      CommonAlert.showInfo(
        context,
        title: 'Error loading receipt',
        message: error.toString(),
      );
    }
  }

  Future<String> _loadLogoBase64() async {
    final ByteData bytes = await rootBundle.load('logo.jpeg');
    return base64Encode(bytes.buffer.asUint8List());
  }

  Future<File> _buildPdfFile({required Directory targetDir}) async {
    return buildReceiptPdfFile(
      data: widget.receiptData,
      targetDir: targetDir,
      fileNameSuffix: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  Future<Uint8List> _buildPdfBytes() async {
    return buildReceiptPdfBytes(widget.receiptData);
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
    return sanitizeReceiptPdfFileName(value);
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
          if (_isWebViewReady && _webViewController != null)
            WebViewWidget(controller: _webViewController!),
          if (_isLoading || !_isWebViewReady)
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
