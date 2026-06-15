import 'package:e_tithe/common/services/amount_words_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AmountWordsService', () {
    test('formats numeric amount for totals', () {
      expect(AmountWordsService.formatCurrency('1500'), 'Rs. 1500.00');
    });

    test('formats currency with commas and prefix', () {
      expect(AmountWordsService.formatCurrency('Rs. 1,234.50'), 'Rs. 1234.50');
    });

    test('converts whole amount into words', () {
      expect(
        AmountWordsService.formatAmountInWords('1500'),
        'One Thousand Five Hundred Rupees',
      );
    });

    test('converts decimal amount into rupees and paise', () {
      expect(
        AmountWordsService.formatAmountInWords('1234.50'),
        'One Thousand Two Hundred Thirty Four Rupees and Fifty Paise',
      );
    });

    test('converts zero amount', () {
      expect(AmountWordsService.formatAmountInWords('0'), 'Zero Rupees');
    });

    test('converts low whole numbers', () {
      expect(AmountWordsService.formatAmountInWords('1'), 'One Rupee');
      expect(AmountWordsService.formatAmountInWords('19'), 'Nineteen Rupees');
      expect(AmountWordsService.formatAmountInWords('20'), 'Twenty Rupees');
      expect(
        AmountWordsService.formatAmountInWords('99'),
        'Ninety Nine Rupees',
      );
    });

    test('converts hundreds correctly', () {
      expect(
          AmountWordsService.formatAmountInWords('100'), 'One Hundred Rupees');
      expect(
        AmountWordsService.formatAmountInWords('101'),
        'One Hundred One Rupees',
      );
    });

    test('converts lakhs and crores using indian numbering', () {
      expect(
        AmountWordsService.formatAmountInWords('100000'),
        'One Lakh Rupees',
      );
      expect(
        AmountWordsService.formatAmountInWords('10000000'),
        'One Crore Rupees',
      );
      expect(
        AmountWordsService.formatAmountInWords('123456.78'),
        'One Lakh Twenty Three Thousand Four Hundred Fifty Six Rupees and Seventy Eight Paise',
      );
    });

    test('handles rounded paise carry into rupees', () {
      expect(
        AmountWordsService.formatAmountInWords('1.999'),
        'Two Rupees',
      );
    });

    test('uses singular paisa when needed', () {
      expect(
        AmountWordsService.formatAmountInWords('0.01'),
        'Zero Rupees and One Paisa',
      );
    });

    test('returns original text for malformed input', () {
      expect(AmountWordsService.formatAmountInWords('abc'), 'abc');
    });
  });
}
