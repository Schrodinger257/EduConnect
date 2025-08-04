import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:educonnect/core/error_handler.dart';

void main() {
  group('ErrorHandler', () {
    test('should handle Firebase Auth errors correctly', () {
      final error = FirebaseAuthException(code: 'user-not-found');
      final message = ErrorHandler.getUserFriendlyMessage(error);
      
      expect(message, 'No account found with this email address.');
    });

    test('should handle unknown errors with generic message', () {
      final error = Exception('Unknown error');
      final message = ErrorHandler.getUserFriendlyMessage(error);
      
      expect(message, 'Something went wrong. Please try again later.');
    });

    test('should validate required fields', () {
      expect(ErrorHandler.validateRequired(null, 'Name'), 'Name is required');
      expect(ErrorHandler.validateRequired('', 'Name'), 'Name is required');
      expect(ErrorHandler.validateRequired('  ', 'Name'), 'Name is required');
      expect(ErrorHandler.validateRequired('John', 'Name'), null);
    });

    test('should validate email format', () {
      expect(ErrorHandler.validateEmail(null), 'Email is required');
      expect(ErrorHandler.validateEmail(''), 'Email is required');
      expect(ErrorHandler.validateEmail('invalid'), 'Please enter a valid email address');
      expect(ErrorHandler.validateEmail('test@example.com'), null);
    });

    test('should validate password strength', () {
      expect(ErrorHandler.validatePassword(null), 'Password is required');
      expect(ErrorHandler.validatePassword(''), 'Password is required');
      expect(ErrorHandler.validatePassword('123'), 'Password must be at least 6 characters long');
      expect(ErrorHandler.validatePassword('123456'), null);
    });

    test('should validate password confirmation', () {
      expect(ErrorHandler.validatePasswordConfirmation('password', null), 'Please confirm your password');
      expect(ErrorHandler.validatePasswordConfirmation('password', ''), 'Please confirm your password');
      expect(ErrorHandler.validatePasswordConfirmation('password', 'different'), 'Passwords do not match');
      expect(ErrorHandler.validatePasswordConfirmation('password', 'password'), null);
    });
  });

  group('Custom Exceptions', () {
    test('should create AppException correctly', () {
      final exception = AppException('Test message', 'test_code');
      
      expect(exception.message, 'Test message');
      expect(exception.code, 'test_code');
      expect(exception.toString(), 'AppException: Test message (Code: test_code)');
    });

    test('should create ValidationException correctly', () {
      final exception = ValidationException('Validation failed');
      
      expect(exception.message, 'Validation failed');
      expect(exception.code, 'validation');
    });
  });
}