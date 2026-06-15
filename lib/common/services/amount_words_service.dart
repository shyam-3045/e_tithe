class AmountWordsService {
  AmountWordsService._();

  static String formatCurrency(String value) {
    final double? amount = _parseAmount(value);
    if (amount == null) return value.trim();
    return 'Rs. ${amount.toStringAsFixed(2)}';
  }

  static String formatAmountInWords(String value) {
    final double? amount = _parseAmount(value);
    if (amount == null) return value.trim();

    final int totalPaise = (amount * 100).round();
    final int rupees = totalPaise ~/ 100;
    final int paise = totalPaise % 100;

    final List<String> parts = <String>[];
    if (rupees > 0) {
      parts.add(
        '${_integerToWords(rupees)} ${rupees == 1 ? 'Rupee' : 'Rupees'}',
      );
    } else {
      parts.add('Zero Rupees');
    }

    if (paise > 0) {
      parts.add(
        'and ${_integerToWords(paise)} ${paise == 1 ? 'Paisa' : 'Paise'}',
      );
    }

    return parts.join(' ');
  }

  static double? _parseAmount(String value) {
    final String normalized = value.trim();
    if (normalized.isEmpty) return null;

    final Match? numericMatch = RegExp(r'\d[\d,]*(?:\.\d+)?').firstMatch(
      normalized,
    );
    if (numericMatch == null) return null;

    final String numericText = numericMatch.group(0)!.replaceAll(',', '');
    return double.tryParse(numericText);
  }

  static String _integerToWords(int value) {
    if (value == 0) return 'Zero';

    final List<String> parts = <String>[];
    final List<MapEntry<int, String>> scales = <MapEntry<int, String>>[
      const MapEntry<int, String>(10000000, 'Crore'),
      const MapEntry<int, String>(100000, 'Lakh'),
      const MapEntry<int, String>(1000, 'Thousand'),
      const MapEntry<int, String>(100, 'Hundred'),
    ];

    int remainder = value;

    for (final MapEntry<int, String> scale in scales) {
      if (remainder >= scale.key) {
        final int quotient = remainder ~/ scale.key;
        remainder %= scale.key;
        if (scale.key == 100) {
          parts.add('${_belowHundredToWords(quotient)} ${scale.value}');
        } else {
          parts.add('${_integerToWords(quotient)} ${scale.value}');
        }
      }
    }

    if (remainder > 0) {
      parts.add(_belowHundredToWords(remainder));
    }

    return parts.join(' ');
  }

  static String _belowHundredToWords(int value) {
    const List<String> units = <String>[
      'Zero',
      'One',
      'Two',
      'Three',
      'Four',
      'Five',
      'Six',
      'Seven',
      'Eight',
      'Nine',
      'Ten',
      'Eleven',
      'Twelve',
      'Thirteen',
      'Fourteen',
      'Fifteen',
      'Sixteen',
      'Seventeen',
      'Eighteen',
      'Nineteen',
    ];
    const List<String> tens = <String>[
      '',
      '',
      'Twenty',
      'Thirty',
      'Forty',
      'Fifty',
      'Sixty',
      'Seventy',
      'Eighty',
      'Ninety',
    ];

    if (value < 20) return units[value];

    final int ten = value ~/ 10;
    final int unit = value % 10;
    if (unit == 0) return tens[ten];
    return '${tens[ten]} ${units[unit]}';
  }
}
