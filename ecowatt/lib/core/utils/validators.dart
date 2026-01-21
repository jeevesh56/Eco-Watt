class Validators {
  static String? requiredNum(String? value, {String message = 'Required'}) {
    if (value == null || value.trim().isEmpty) return message;
    final n = num.tryParse(value.trim());
    if (n == null) return 'Invalid number';
    if (n < 0) return 'Must be >= 0';
    return null;
  }
}

