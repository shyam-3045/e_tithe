import 'receipt_export_service.dart';

class ReceiptHtmlGeneratorService {
  ReceiptHtmlGeneratorService._();

  static final ReceiptHtmlGeneratorService instance =
      ReceiptHtmlGeneratorService._();

  /// Generate receipt HTML for WebView
  String generateReceiptHtml(ReceiptExportData data, {String? logoBase64}) {
    final String logoTag = (logoBase64 == null || logoBase64.trim().isEmpty)
        ? ''
        : '<img class="logo" src="data:image/jpeg;base64,$logoBase64" alt="Logo" />';

    final String notesLine = data.notes.trim().isNotEmpty
        ? _escapeHtml(data.notes)
        : '-';

    final String amountText = data.amount.trim().isEmpty
        ? ''
        : data.amount.trim();

    return '''<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Receipt ${data.receiptNo}</title>
    <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                body { font-family: Arial, Helvetica, sans-serif; background: #ffffff; padding: 12px; color: #111; }
                .receipt { max-width: 820px; margin: 0 auto; background: #fff; border: 1.5px solid #000; }

                .header { border-bottom: 1px solid #000; padding: 10px 12px; position: relative; min-height: 100px; }
                .header-left { position: absolute; left: 12px; top: 50%; transform: translateY(-50%); }
                .logo { width: 80px; height: 80px; object-fit: contain; }
                .header-right { position: absolute; right: 12px; top: 50%; transform: translateY(-50%);font-size: 12px; }
                .org-title { text-align: right; font-weight: 800; font-size: 11px; letter-spacing: 0.3px; }
                .org-sub { text-align: right; font-size: 10px; font-weight: 600; margin-top: 2px; }
                .org-line { text-align: right; font-size: 10px; margin-top: 2px; }

                .row { display: flex; justify-content: space-between; align-items: center; }
                .col { flex: 1; }

                .section { border-bottom: 1px solid #000; padding: 8px 12px; }
                .section-title { text-align: center; font-weight: 700; font-size: 12px; letter-spacing: 0.4px; }

                .meta { display: flex; justify-content: space-between; gap: 16px; }
                .meta-left { font-size: 12px; }
                .meta-right { text-align: right; font-size: 12px; min-width: 140px; }

                .label { font-weight: 700; }
                .value { font-weight: 600; }

                .grid { width: 100%; border-collapse: collapse; }
                .grid th, .grid td { border-top: 1px solid #000; padding: 8px 10px; font-size: 12px; }
                .grid th { font-weight: 700; text-align: center; }
                .grid td:first-child { border-right: 1px solid #000; }
                .grid td:last-child { text-align: right; }
                .grid .total td { font-weight: 800; }

                .note-line { font-size: 12px; padding: 8px 12px; border-bottom: 1px solid #000; }
                .sign-row { display: flex; justify-content: flex-end; padding: 18px 12px 8px; font-size: 12px; }
                .sign-block { text-align: center; min-width: 220px; }
                .sign-line { border-top: 1px solid #000; margin-top: 22px; padding-top: 4px; font-weight: 700; }

                .footer { text-align: center; font-size: 10.5px; padding: 10px 12px 12px; }
                .footer .verse { font-weight: 700; margin-bottom: 4px; }

                @media (max-width: 640px) {
                    body { padding: 6px; }
                    .header { min-height: 80px; }
                    .logo { width: 66px; height: 66px; }
                    .org-title { font-size: 10px; }
                    .org-sub, .org-line { font-size: 9px; }
                    .meta-left, .meta-right, .grid th, .grid td { font-size: 11px; }
                    .meta { flex-direction: column; }
                    .meta-right { text-align: left; }
                }

                @media print {
                    body { padding: 0; }
                    .receipt { border: 1px solid #000; }
                }
    </style>
</head>
<body>
        <div class="receipt">
            <div class="header">
                <div class="header-left">
                    $logoTag
                </div>
                <div class="header-right">
                    <div class="org-title">SCRIPTURE UNION &amp; CSSM COUNCIL OF INDIA</div>
                    <div class="org-sub">Society Registration Number : 1/1975</div>
                    <div class="org-sub">TAMIL NADU SOUTH</div>
                    <div class="org-line">No.56 C/4 (Upstairs) St. Mary&#39;s Street, Perumalpura mTirunelveli-627007</div>
                </div>
            </div>

            <div class="section">
                <div class="section-title">RECEIPT</div>
            </div>

            <div class="section meta">
                <div class="meta-left">
                    <div>Received with thanks from <span class="value">${_escapeHtml(data.donorName)}</span></div>
                    <div style="margin-top: 8px;">Address:</div>
                    <div class="value">${_escapeHtml(data.address)}</div>
                    <div class="value">${_escapeHtml(data.pincode)}</div>
                </div>
                <div class="meta-right">
                    <div><span class="label">Receipt #:</span> ${_escapeHtml(data.receiptNo)}</div>
                    <div style="margin-top: 6px;"><span class="label">Date :</span> ${_escapeHtml(data.receiptDate)}</div>
                </div>
            </div>

            <table class="grid">
                <thead>
                    <tr>
                        <th>Particulars</th>
                        <th>Amount</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td>${_escapeHtml(data.fundType)}</td>
                        <td>${_escapeHtml(amountText)}</td>
                    </tr>
                    <tr class="total">
                        <td style="text-align:right;">Total</td>
                        <td>${_escapeHtml(amountText)}</td>
                    </tr>
                </tbody>
            </table>

            <div class="note-line">Received as: <span class="value">${_escapeHtml(data.paymentMode)}</span></div>
            <div class="note-line">Rupees ${_escapeHtml(amountText)} only</div>
            <div class="note-line">Notes: ${notesLine}</div>

            <div class="sign-row">
                <div class="sign-block">
                    for Scripture Union &amp; CSSM council of India
                    <div class="sign-line">Authorised Signatory</div>
                </div>
            </div>

            <div class="footer">
                <div class="verse">"Your word is lamp to my feet and a light for my path. Psalms 119:105"</div>
                <div>Head Office: No. 27 First Main Road, United India Nagar, Ayanavaram, Chennai-600023</div>
                <div>Phone: 044-2674 0137  Email: scriptureunionindia@gmail.com</div>
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
