class Formatter {
  static String currency(double value, {String symbol = '₹'}) {
    return '$symbol${value.toStringAsFixed(2)}';
  }

  static String kwh(double value) => '${value.toStringAsFixed(1)} kWh';
}

