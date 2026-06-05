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
    final ByteData logoBytes = await rootBundle.load('logo.jpeg');
    final pw.MemoryImage logoImage = pw.MemoryImage(
      logoBytes.buffer.asUint8List(),
    );

    final String amountValue = data.amount.trim();
    final String amountText = amountValue.isEmpty
        ? ''
        : (amountValue.toLowerCase().startsWith('rs')
              ? amountValue
              : 'Rs $amountValue');

    final List<ReceiptFundDetail> pdfDetails = data.fundDetails.isNotEmpty
        ? data.fundDetails
        : [
            ReceiptFundDetail(
              companyId: 0,
              companyName: '',
              regionName: '',
              companyAddress: '',
              email: '',
              mobile: '',
              fundName: data.fundType,
              amount: double.tryParse(data.amount.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0,
            )
          ];

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
              'Amount',
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
        final String detailAmountText = 'Rs ${detail.amount.toStringAsFixed(2)}';
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
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(18),
        build: (context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.black, width: 1),
                    ),
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 68,
                        height: 68,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                            color: PdfColors.black,
                            width: 1,
                          ),
                        ),
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                          children: [
                            pw.Text(
                              'SCRIPTURE UNION & CSSM COUNCIL OF INDIA',
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'Society Registration Number : 1/1975',
                              textAlign: pw.TextAlign.center,
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                            pw.Text(
                              'TAMIL NADU SOUTH',
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                fontSize: 9.5,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              "No.56 C/4 (Upstairs) St. Mary's Street, Perumalpura mTirunelveli-627007",
                              textAlign: pw.TextAlign.center,
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 68),
                    ],
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 6),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.black, width: 1),
                    ),
                  ),
                  child: pw.Text(
                    'RECEIPT',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.black, width: 1),
                    ),
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Received with thanks from ${data.donorName}',
                              style: pw.TextStyle(
                                fontSize: 9.5,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 6),
                            pw.Text(
                              'Address:',
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                            pw.Text(
                              data.address,
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                            pw.Text(
                              data.pincode,
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 12),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'Receipt #: ${data.receiptNo}',
                            style: const pw.TextStyle(fontSize: 9.5),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Date : ${data.receiptDate}',
                            style: const pw.TextStyle(fontSize: 9.5),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.Table(
                  border: const pw.TableBorder(
                    top: pw.BorderSide(color: PdfColors.black, width: 1),
                    bottom: pw.BorderSide(color: PdfColors.black, width: 1),
                    verticalInside: pw.BorderSide(
                      color: PdfColors.black,
                      width: 1,
                    ),
                    horizontalInside: pw.BorderSide(
                      color: PdfColors.black,
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
                  padding: const pw.EdgeInsets.all(8),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.black, width: 1),
                    ),
                  ),
                  child: pw.Text(
                    'Received as: ${data.paymentMode}',
                    style: const pw.TextStyle(fontSize: 9.5),
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.black, width: 1),
                    ),
                  ),
                  child: pw.Text(
                    'Rupees $amountText only',
                    style: const pw.TextStyle(fontSize: 9.5),
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.black, width: 1),
                    ),
                  ),
                  child: pw.Text(
                    'Notes: ${data.notes.trim().isEmpty ? '-' : data.notes.trim()}',
                    style: const pw.TextStyle(fontSize: 9.5),
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.fromLTRB(8, 18, 8, 8),
                  child: pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'for Scripture Union & CSSM council of India',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                        pw.Container(
                          margin: const pw.EdgeInsets.only(top: 18),
                          width: 180,
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(
                              top: pw.BorderSide(
                                color: PdfColors.black,
                                width: 1,
                              ),
                            ),
                          ),
                          padding: const pw.EdgeInsets.only(top: 3),
                          child: pw.Text(
                            'Authorised Signatory',
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        '"Your word is lamp to my feet and a light for my path. Psalms 119:105"',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 8.5,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Head Office: No. 27 First Main Road, United India Nagar, Ayanavaram, Chennai-600023',
                        textAlign: pw.TextAlign.center,
                        style: const pw.TextStyle(fontSize: 8.2),
                      ),
                      pw.Text(
                        'Phone: 044-2674 0137  Email: scriptureunionindia@gmail.com',
                        textAlign: pw.TextAlign.center,
                        style: const pw.TextStyle(fontSize: 8.2),
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
