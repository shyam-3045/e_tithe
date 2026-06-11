import 'receipt_export_service.dart';
import 'receipt_service.dart';

class ReceiptHtmlGeneratorService {
  ReceiptHtmlGeneratorService._();

  static final ReceiptHtmlGeneratorService instance =
      ReceiptHtmlGeneratorService._();

  /// Generate receipt HTML for WebView
  String generateReceiptHtml(ReceiptExportData data, {String? logoBase64}) {
    final String logoTag = (logoBase64 == null || logoBase64.trim().isEmpty)
        ? ''
        : '<img class="logo" src="data:image/jpeg;base64,$logoBase64" alt="Logo" />';

    final String amountText = _normalizeAmountText(data.amount);

    final List<ReceiptFundDetail> details = data.fundDetails.isNotEmpty
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
            )
          ];

    final ReceiptFundDetail companyDetail = _resolveCompanyDetail(details);
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
    final String footerContact = [
      if (companyMobile.isNotEmpty) 'Phone: ${_escapeHtml(companyMobile)}',
      if (companyEmail.isNotEmpty) 'Email: ${_escapeHtml(companyEmail)}',
    ].join(' | ');

    final String donorAddress = _composeDonorAddress(
      address: data.address,
      pincode: data.pincode,
    );

    final String tableRows = details.map((detail) {
      final String detailAmount = 'Rs. ${detail.amount.toStringAsFixed(2)}';
      return '''
                    <tr>
                        <td>${_escapeHtml(detail.fundName)}</td>
                        <td>${_escapeHtml(detailAmount)}</td>
                    </tr>''';
    }).join('\n');

    return '''<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Receipt ${data.receiptNo}</title>
    <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                @page { size: A5 portrait; margin: 7mm; }
                body { font-family: Arial, Helvetica, sans-serif; background: #ffffff; padding: 8px; color: #111; }
                .receipt { width: 100%; max-width: 540px; margin: 0 auto; background: #fff; border: 1px solid #8d67e8; }
                .header { border-bottom: 1px solid #666; padding: 10px 12px; }
                .header-shell { display: table; width: 100%; }
                .header-logo, .header-body, .header-spacer { display: table-cell; vertical-align: top; }
                .header-logo, .header-spacer { width: 56px; }
                .logo { width: 42px; height: 42px; object-fit: contain; display: block; margin-top: 2px; }
                .header-body { text-align: center; }
                .org-title { font-weight: 800; font-size: 10.6px; letter-spacing: 0.15px; line-height: 1.2; text-transform: uppercase; }
                .org-line { font-size: 8px; margin-top: 3px; line-height: 1.25; }
                .org-sub { font-size: 8px; font-weight: 700; margin-top: 4px; line-height: 1.25; }
                .section-title { text-align: center; font-weight: 800; font-size: 10px; letter-spacing: 0.8px; padding: 8px 12px; border-bottom: 1px solid #666; }
                .meta { display: table; width: 100%; border-bottom: 1px solid #666; }
                .meta-left, .meta-right { display: table-cell; vertical-align: top; padding: 10px 12px; font-size: 8.3px; }
                .meta-right { width: 190px; }
                .value { font-weight: 700; }
                .field-label { font-weight: 700; margin-top: 8px; }
                .info-box { border: 1px solid #666; border-radius: 2px; padding: 6px 8px; margin-bottom: 8px; }
                .info-box table { width: 100%; border-collapse: collapse; }
                .info-box td { font-size: 8.3px; }
                .info-box td:first-child { width: 72px; font-weight: 700; text-align: right; padding-right: 8px; }
                .info-box td:last-child { text-align: right; }
                .grid-wrap { padding: 10px 12px; border-bottom: 1px solid #666; }
                .grid { width: 100%; border-collapse: collapse; table-layout: fixed; }
                .grid th, .grid td { border: 1px solid #666; padding: 5px 8px; font-size: 8.3px; }
                .grid th { font-weight: 700; text-align: center; }
                .grid td:last-child { text-align: right; width: 34%; }
                .grid .total td { font-weight: 800; }
                .detail-line { font-size: 8.3px; padding: 9px 12px; border-bottom: 1px solid #666; min-height: 32px; }
                .detail-line .label { font-weight: 700; }
                .sign-row { padding: 24px 12px 20px; border-bottom: 1px solid #666; min-height: 146px; }
                .sign-block { width: 230px; margin-left: auto; text-align: center; font-size: 8.3px; }
                .sign-line { border-top: 1px solid #666; margin-top: 24px; padding-top: 4px; font-weight: 700; }
                .footer { text-align: center; font-size: 7.8px; line-height: 1.35; padding: 10px 12px 12px; }
                .footer .verse { font-weight: 700; font-style: italic; margin-bottom: 4px; }
                .footer .contact-line { white-space: nowrap; }

                @media (max-width: 640px) {
                    body { padding: 4px; }
                    .receipt { max-width: 100%; }
                }

                @media print {
                    body { padding: 0; }
                    .receipt { max-width: none; width: 100%; }
                }
    </style>
</head>
<body>
        <div class="receipt">
            <div class="header">
                <div class="header-shell">
                    <div class="header-logo">
                        $logoTag
                    </div>
                    <div class="header-body">
                        <div class="org-title">${_escapeHtml(companyName)}</div>
                        <div class="org-line">${_escapeHtml(companyAddress)}</div>
                        <div class="org-sub">${_escapeHtml(regionName)}</div>
                        ${regionAddress.isEmpty ? '' : '<div class="org-line">${_escapeHtml(regionAddress)}</div>'}
                    </div>
                    <div class="header-spacer"></div>
                </div>
            </div>

            <div class="section-title">RECEIPT</div>

            <div class="meta">
                <div class="meta-left">
                    <div>Received with thanks from <span class="value">${_escapeHtml(data.donorName)}</span></div>
                    <div class="field-label">Address:</div>
                    <div>${_escapeHtml(donorAddress)}</div>
                </div>
                <div class="meta-right">
                    <div class="info-box">
                        <table>
                            <tr>
                                <td>Receipt #:</td>
                                <td>${_escapeHtml(data.receiptNo)}</td>
                            </tr>
                        </table>
                    </div>
                    <div class="info-box">
                        <table>
                            <tr>
                                <td>Date:</td>
                                <td>${_escapeHtml(data.receiptDate)}</td>
                            </tr>
                        </table>
                    </div>
                </div>
            </div>

            <div class="grid-wrap">
                <table class="grid">
                    <thead>
                        <tr>
                            <th>Particulars</th>
                            <th>Amount (Rs.)</th>
                        </tr>
                    </thead>
                    <tbody>
                        $tableRows
                        <tr class="total">
                            <td style="text-align:right;">Total</td>
                            <td>${_escapeHtml(amountText)}</td>
                        </tr>
                    </tbody>
                </table>
            </div>

            <div class="detail-line"><span class="label">Received as:</span> ${_escapeHtml(data.paymentMode)}</div>
            <div class="detail-line"><span class="label">Amount in Words:</span> ${_escapeHtml(amountText)} only</div>
            <div class="sign-row">
                <div class="sign-block">
                    for Scripture Union &amp; CSSM council of India
                    <div class="sign-line">Authorised Signatory</div>
                </div>
            </div>

            <div class="footer">
                <div class="verse">"Your word is lamp to my feet and a light for my path. Psalms 119:105"</div>
                <div>${_escapeHtml(companyAddress)}</div>
                ${footerContact.isEmpty ? '' : '<div class="contact-line">$footerContact</div>'}
            </div>
        </div>
</body>
</html>''';
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

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }
}
