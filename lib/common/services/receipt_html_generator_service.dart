import 'receipt_export_service.dart';

class ReceiptHtmlGeneratorService {
  ReceiptHtmlGeneratorService._();

  static final ReceiptHtmlGeneratorService instance =
      ReceiptHtmlGeneratorService._();

  /// Generate clean tabular black & white receipt HTML for WebView
  String generateReceiptHtml(ReceiptExportData data) {
    final notesSection = data.notes.trim().isNotEmpty
        ? '''
        <div class="notes-box">
          <strong>Notes:</strong> ${_escapeHtml(data.notes)}
        </div>'''
        : '';

    return '''<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Receipt ${data.receiptNo}</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Times New Roman', Times, serif; background: #f0f0f0; padding: 20px; }
        .receipt { max-width: 580px; margin: 0 auto; background: #fff; border: 2px solid #000; padding: 24px; }

        h1 { text-align: center; font-size: 20px; letter-spacing: 4px; text-transform: uppercase;
             border-bottom: 2px solid #000; padding-bottom: 8px; margin-bottom: 6px; }
        .receipt-no { text-align: center; font-size: 12px; margin-bottom: 18px; }

        table { width: 100%; border-collapse: collapse; margin-bottom: 14px; }
        td, th { border: 1px solid #000; padding: 7px 10px; font-size: 13px; vertical-align: top; }
        th { background: #000; color: #fff; text-align: left; font-size: 12px;
             letter-spacing: 1px; text-transform: uppercase; }

        .donor-name { font-weight: bold; font-size: 15px; }
        .amount-row td { font-size: 15px; font-weight: bold; }
        .label-col { width: 40%; color: #333; }

        .notes-box { border: 1px solid #000; padding: 8px 10px; font-size: 12px;
                     line-height: 1.5; margin-bottom: 14px; }

        .sig-table { width: 100%; border-collapse: collapse; margin-top: 36px; }
        .sig-table td { border: none; text-align: center; font-size: 12px; padding-top: 6px; width: 50%; }
        .sig-line { border-top: 1px solid #000; padding-top: 5px; margin: 0 20px; }

        .footer { text-align: center; font-size: 11px; color: #555; margin-top: 14px;
                  border-top: 1px solid #000; padding-top: 8px; line-height: 1.6; }

        @media print {
            body { background: white; padding: 0; }
            .receipt { border: none; padding: 0; }
        }
    </style>
</head>
<body>
    <div class="receipt">

        <h1>Receipt</h1>
        <div class="receipt-no">Receipt No: <strong>${_escapeHtml(data.receiptNo)}</strong></div>

        <table>
            <tr><th colspan="2">Donor Details</th></tr>
            <tr>
                <td class="label-col">Name</td>
                <td class="donor-name">${_escapeHtml(data.donorName)}</td>
            </tr>
            <tr>
                <td class="label-col">Address</td>
                <td>${_escapeHtml(data.address)}</td>
            </tr>
            <tr>
                <td class="label-col">Pincode</td>
                <td>${_escapeHtml(data.pincode)}</td>
            </tr>
        </table>

        <table>
            <tr><th colspan="2">Transaction Details</th></tr>
            <tr>
                <td class="label-col">Receipt Date</td>
                <td>${_escapeHtml(data.receiptDate)}</td>
            </tr>
            <tr>
                <td class="label-col">Month</td>
                <td>${_escapeHtml(data.monthLabel)}</td>
            </tr>
            <tr>
                <td class="label-col">Fund Type</td>
                <td>${_escapeHtml(data.fundType)}</td>
            </tr>
            <tr>
                <td class="label-col">Payment Mode</td>
                <td>${_escapeHtml(data.paymentMode)}</td>
            </tr>
        </table>

        <table>
            <tr><th colspan="2">Amount</th></tr>
            <tr class="amount-row">
                <td class="label-col">Total Amount Received</td>
                <td>${_escapeHtml(data.amount)}</td>
            </tr>
        </table>

        $notesSection

        <table class="sig-table">
            <tr>
                <td><div class="sig-line">Donor Signature</div></td>
                <td><div class="sig-line">Authorized Signature</div></td>
            </tr>
        </table>

        <div class="footer">
            Thank you for your generous donation<br>
            Generated on: ${DateTime.now().toString().split('.')[0]}
        </div>

    </div>
</body>
</html>''';
  }

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }
}