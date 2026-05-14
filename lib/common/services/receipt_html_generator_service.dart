import 'receipt_export_service.dart';

class ReceiptHtmlGeneratorService {
  ReceiptHtmlGeneratorService._();

  static final ReceiptHtmlGeneratorService instance =
      ReceiptHtmlGeneratorService._();

  /// Generate lightweight HTML for receipt that can be rendered in WebView
  String generateReceiptHtml(ReceiptExportData data) {
    return '''<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Receipt ${data.receiptNo}</title>
    <style>
        * { margin: 0; padding: 0; }
        body { font-family: Arial, sans-serif; background: #f5f5f5; padding: 20px; }
        .container { max-width: 600px; margin: 0 auto; background: white; padding: 25px; }
        .header { text-align: center; border-bottom: 2px solid #7B3FF2; padding-bottom: 15px; margin-bottom: 20px; }
        .title { font-size: 22px; font-weight: bold; }
        .number { font-size: 13px; color: #666; margin-top: 5px; }
        .donor-box { border: 1px solid #7B3FF2; padding: 12px; text-align: center; margin: 15px 0; }
        .donor-name { font-size: 14px; font-weight: bold; color: #7B3FF2; margin-bottom: 3px; }
        .donor-info { font-size: 11px; color: #666; line-height: 1.3; }
        .section { margin: 15px 0; }
        .row { display: flex; justify-content: space-between; font-size: 12px; padding: 4px 0; }
        .label { color: #666; }
        .value { font-weight: bold; }
        .amount-box { background: #7B3FF2; color: white; padding: 12px; text-align: center; margin: 15px 0; }
        .amount-label { font-size: 11px; }
        .amount { font-size: 18px; font-weight: bold; margin-top: 3px; }
        .notes { font-size: 11px; color: #555; margin: 10px 0; line-height: 1.3; }
        .signature { display: flex; justify-content: space-between; margin-top: 30px; }
        .sig-block { flex: 1; text-align: center; font-size: 10px; }
        .sig-line { border-top: 1px solid #333; height: 30px; margin-bottom: 3px; }
        @media print { body { background: white; padding: 0; } .container { padding: 20px; } }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="title">RECEIPT</div>
            <div class="number">Receipt #${data.receiptNo}</div>
        </div>
        
        <div class="donor-box">
            <div class="donor-name">${_escapeHtml(data.donorName)}</div>
            <div class="donor-info">
                ${_escapeHtml(data.address)}<br>
                ${_escapeHtml(data.pincode)}
            </div>
        </div>
        
        <div class="section">
            <div class="row">
                <span class="label">Date:</span>
                <span class="value">${_escapeHtml(data.receiptDate)}</span>
            </div>
            <div class="row">
                <span class="label">Month:</span>
                <span class="value">${_escapeHtml(data.monthLabel)}</span>
            </div>
            <div class="row">
                <span class="label">Fund:</span>
                <span class="value">${_escapeHtml(data.fundType)}</span>
            </div>
            <div class="row">
                <span class="label">Mode:</span>
                <span class="value">${_escapeHtml(data.paymentMode)}</span>
            </div>
        </div>
        
        <div class="amount-box">
            <div class="amount-label">AMOUNT</div>
            <div class="amount">${_escapeHtml(data.amount)}</div>
        </div>
        
        ${data.notes.trim().isNotEmpty ? '''
        <div class="notes">
            <strong>Notes:</strong><br>
            ${_escapeHtml(data.notes)}
        </div>
        ''' : ''}
        
        <div class="signature">
            <div class="sig-block">
                <div class="sig-line"></div>
                Donor
            </div>
            <div class="sig-block">
                <div class="sig-line"></div>
                Authorized
            </div>
        </div>
    </div>
</body>
</html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Receipt ${data.receiptNo}</title>
    <style>
        * { margin: 0; padding: 0; }
        body { font-family: Arial, sans-serif; background: #f5f5f5; padding: 20px; }
        .container { max-width: 600px; margin: 0 auto; background: white; padding: 30px; }
        .header { text-align: center; border-bottom: 2px solid #7B3FF2; padding-bottom: 15px; margin-bottom: 20px; }
        .title { font-size: 24px; font-weight: bold; color: #333; }
        .number { font-size: 14px; color: #666; }
        .section { margin-bottom: 20px; }
        .section-title { font-weight: bold; color: #7B3FF2; margin-bottom: 10px; font-size: 14px; }
        .row { display: flex; justify-content: space-between; padding: 5px 0; font-size: 14px; }
        .label { color: #666; }
        .value { font-weight: bold; color: #333; }
        .donor-box { border: 2px solid #7B3FF2; padding: 15px; text-align: center; margin-bottom: 20px; }
        .donor-name { font-size: 16px; font-weight: bold; color: #7B3FF2; margin-bottom: 5px; }
        .donor-info { font-size: 12px; color: #666; line-height: 1.4; }
        .amount-box { background: #7B3FF2; color: white; padding: 15px; text-align: center; margin: 20px 0; border-radius: 4px; }
        .amount { font-size: 20px; font-weight: bold; }
        .notes { font-size: 12px; color: #555; line-height: 1.4; }
        .signature { display: flex; justify-content: space-between; margin-top: 40px; text-align: center; }
        .sig-block { flex: 1; }
        .sig-line { border-top: 1px solid #333; height: 40px; margin-bottom: 5px; }
        .sig-label { font-size: 12px; color: #333; }
            margin-bottom: 10px;
        }
        
        .receipt-number {
            font-size: 18px;
            color: #666;
            font-weight: 600;
        }
        
        .donor-section {
            background: #F3E5FF;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 25px;
            border-left: 4px solid #7B3FF2;
        }
        
        .donor-name {
            font-size: 24px;
            font-weight: bold;
            color: #7B3FF2;
            margin-bottom: 10px;
        }
        
        .donor-address {
            font-size: 14px;
            color: #555;
            line-height: 1.8;
        }
        
        .donor-pincode {
            font-size: 14px;
            color: #555;
            margin-top: 8px;
            font-weight: 600;
        }
        
        .details-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
            margin-bottom: 30px;
        }
        
        .detail-item {
            padding: 15px;
            background: #f9f9f9;
            border-radius: 6px;
            border-left: 3px solid #7B3FF2;
        }
        
        .detail-label {
            font-size: 12px;
            text-transform: uppercase;
            color: #999;
            font-weight: 700;
            letter-spacing: 0.5px;
            margin-bottom: 5px;
        }
        
        .detail-value {
            font-size: 16px;
            color: #333;
            font-weight: 600;
        }
        
        .amount-box {
            grid-column: 1 / -1;
            background: linear-gradient(135deg, #7B3FF2, #9f5dd8);
            color: white;
            padding: 25px;
            border-radius: 6px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            font-size: 18px;
            font-weight: bold;
        }
        
        .amount-label {
            font-size: 14px;
            opacity: 0.9;
            font-weight: 600;
        }
        
        .amount-value {
            font-size: 28px;
            font-weight: bold;
        }
        
        .fund-details {
            background: #fff9e6;
            border: 1px solid #ffe58f;
            padding: 20px;
            border-radius: 6px;
            margin-bottom: 25px;
        }
        
        .fund-type {
            font-size: 16px;
            font-weight: bold;
            color: #7B3FF2;
            margin-bottom: 10px;
        }
        
        .fund-info {
            font-size: 14px;
            color: #555;
            margin: 8px 0;
        }
        
        .notes-section {
            background: #f0f4ff;
            padding: 20px;
            border-radius: 6px;
            margin-bottom: 25px;
            border-left: 4px solid #7B3FF2;
        }
        
        .notes-title {
            font-size: 14px;
            font-weight: bold;
            color: #7B3FF2;
            text-transform: uppercase;
            margin-bottom: 10px;
            letter-spacing: 0.5px;
        }
        
        .notes-content {
            font-size: 14px;
            color: #555;
            line-height: 1.6;
        }
        
        .signature-section {
            margin-top: 40px;
            padding-top: 40px;
            border-top: 2px solid #ddd;
        }
        
        .signature-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 40px;
            margin-top: 30px;
        }
        
        .signature-block {
            text-align: center;
        }
        
        .signature-line {
            border-top: 2px solid #333;
            margin-bottom: 8px;
            height: 60px;
            display: flex;
            align-items: flex-end;
        }
        
        .signature-label {
            font-size: 12px;
            color: #666;
            font-weight: 600;
        }
        
        .footer {
            text-align: center;
            margin-top: 40px;
            padding-top: 20px;
            border-top: 1px solid #eee;
            font-size: 12px;
            color: #999;
        }
        
        .date-generated {
            font-size: 12px;
            color: #999;
            margin-top: 10px;
        }
        
        @media print {
            body {
                background: white;
                padding: 0;
            }
            
            .container {
                box-shadow: none;
                padding: 0;
                margin: 0;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="receipt-title">RECEIPT</div>
            <div class="receipt-number">Receipt #${data.receiptNo}</div>
        </div>
        
        <div class="donor-section">
            <div class="donor-name">${_escapeHtml(data.donorName)}</div>
            <div class="donor-address">
                ${_escapeHtml(data.address)}
            </div>
            <div class="donor-pincode">${_escapeHtml(data.pincode)}</div>
        </div>
        
        <div class="details-grid">
            <div class="detail-item">
                <div class="detail-label">Receipt Date</div>
                <div class="detail-value">${_escapeHtml(data.receiptDate)}</div>
            </div>
            
            <div class="detail-item">
                <div class="detail-label">Month</div>
                <div class="detail-value">${_escapeHtml(data.monthLabel)}</div>
            </div>
            
            <div class="detail-item">
                <div class="detail-label">Payment Mode</div>
                <div class="detail-value">${_escapeHtml(data.paymentMode)}</div>
            </div>
            
            <div class="detail-item">
                <div class="detail-label">Fund Type</div>
                <div class="detail-value">${_escapeHtml(data.fundType)}</div>
            </div>
            
            <div class="amount-box">
                <span class="amount-label">AMOUNT</span>
                <span class="amount-value">${_escapeHtml(data.amount)}</span>
            </div>
        </div>
        
        <div class="fund-details">
            <div class="fund-type">${_escapeHtml(data.fundType)}</div>
            <div class="fund-info">Donation for the month of ${_escapeHtml(data.monthLabel)}</div>
            <div class="fund-info"><strong>Amount:</strong> ${_escapeHtml(data.amount)}</div>
            <div class="fund-info"><strong>Payment Mode:</strong> ${_escapeHtml(data.paymentMode)}</div>
        </div>
        
        ${data.notes.trim().isNotEmpty ? '''
        <div class="notes-section">
            <div class="notes-title">Notes</div>
            <div class="notes-content">${_escapeHtml(data.notes)}</div>
        </div>
        ''' : ''}
        
        <div class="signature-section">
            <div class="signature-grid">
                <div class="signature-block">
                    <div class="signature-line"></div>
                    <div class="signature-label">Donor Signature</div>
                </div>
                <div class="signature-block">
                    <div class="signature-line"></div>
                    <div class="signature-label">Authorized Signature</div>
                </div>
            </div>
        </div>
        
        <div class="footer">
            <div>Thank you for your generous donation</div>
            <div class="date-generated">Generated on: ${DateTime.now().toString().split('.')[0]}</div>
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
