import 'package:flutter/material.dart';
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
  late WebViewController _webViewController;
  bool _isLoading = true;

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

  Future<void> _sharePrint() async {
    try {
      // Use WebView's native print dialog (fast, uses native system)
      await _webViewController.runJavaScript('window.print();');
    } catch (error) {
      if (mounted) {
        await CommonAlert.showInfo(
          context,
          title: 'Print failed',
          message: error.toString(),
        );
      }
    }
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
                onTap: _sharePrint,
              ),
              _ActionButton(
                label: 'Save',
                icon: Icons.download_rounded,
                onTap: _sharePrint,
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
