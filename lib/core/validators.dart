/// Form validation utilities used across all auth screens.
/// Each method returns null if valid, or an error message string.
class Validators {
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email address is required';
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Mobile number is required';
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.length < 8 || digitsOnly.length > 15) return 'Enter a valid mobile number';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[A-Za-z]').hasMatch(value)) return 'Password must contain letters';
    if (!RegExp(r'\d').hasMatch(value)) return 'Password must contain a number';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != password) return 'Passwords do not match';
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) return 'Full name is required';
    if (value.trim().length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  static String? dob(String? value) {
    if (value == null || value.trim().isEmpty) return 'Date of birth is required';
    return null;
  }

  static String? address(String? value) {
    if (value == null || value.trim().isEmpty) return 'Address is required';
    if (value.trim().length < 10) return 'Please enter a complete address';
    return null;
  }

  static PasswordStrength passwordStrength(String password) {
    if (password.length < 4) return PasswordStrength.none;
    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) score++;
    if (score <= 1) return PasswordStrength.weak;
    if (score == 2) return PasswordStrength.medium;
    if (score == 3) return PasswordStrength.strong;
    return PasswordStrength.veryStrong;
  }
}

enum PasswordStrength { none, weak, medium, strong, veryStrong }
