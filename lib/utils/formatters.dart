class AppFormatters {
  static String formatPhone(String? phone) {
    if (phone == null || phone.isEmpty) return 'N/A';
    
    // Remove non-numeric characters
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    
    if (digits.length == 10) {
      return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
    } else if (digits.length == 11) {
      return '+${digits.substring(0, 1)} (${digits.substring(1, 4)}) ${digits.substring(4, 7)}-${digits.substring(7)}';
    }
    
    return phone; // Return original if it doesn't match standard patterns
  }
}
