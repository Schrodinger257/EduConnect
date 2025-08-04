import 'dart:developer' as developer;
import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'logger.dart';

/// Centralized error handling service that provides user-friendly error messages
/// and consistent error handling across the application
class ErrorHandler {
  static final Logger _logger = Logger();

  /// Handles an error by logging it and returning a user-friendly message
  static String handleError(
    Exception error, {
    String? context,
    bool shouldLog = true,
  }) {
    if (shouldLog) {
      _logger.error(
        'Error occurred${context != null ? ' in $context' : ''}',
        error: error,
      );
    }

    return getUserFriendlyMessage(error);
  }

  /// Converts technical errors to user-friendly messages
  static String getUserFriendlyMessage(Exception error) {
    switch (error.runtimeType) {
      // Firebase Auth Errors
      case FirebaseAuthException:
        return _handleFirebaseAuthError(error as FirebaseAuthException);
      
      // Firestore Errors
      case FirebaseException:
        return _handleFirestoreError(error as FirebaseException);
      
      // Network Errors
      case SocketException:
        return 'Please check your internet connection and try again.';
      
      // Timeout Errors
      case TimeoutException:
        return 'The request timed out. Please try again.';
      
      // Generic errors
      default:
        _logger.warning('Unhandled error type: ${error.runtimeType}');
        return 'Something went wrong. Please try again later.';
    }
  }

  /// Handles Firebase Authentication specific errors
  static String _handleFirebaseAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Please contact support.';
      case 'invalid-credential':
        return 'The provided credentials are invalid.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';
      case 'requires-recent-login':
        return 'Please log in again to complete this action.';
      default:
        _logger.warning('Unhandled Firebase Auth error: ${error.code}');
        return 'Authentication failed. Please try again.';
    }
  }

  /// Handles Firestore specific errors
  static String _handleFirestoreError(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'You don\'t have permission to perform this action.';
      case 'not-found':
        return 'The requested data was not found.';
      case 'already-exists':
        return 'This data already exists.';
      case 'resource-exhausted':
        return 'Service is temporarily unavailable. Please try again later.';
      case 'failed-precondition':
        return 'The operation failed due to a conflict. Please refresh and try again.';
      case 'aborted':
        return 'The operation was aborted. Please try again.';
      case 'out-of-range':
        return 'Invalid data provided.';
      case 'unimplemented':
        return 'This feature is not yet available.';
      case 'internal':
        return 'An internal error occurred. Please try again later.';
      case 'unavailable':
        return 'Service is temporarily unavailable. Please try again later.';
      case 'data-loss':
        return 'Data corruption detected. Please contact support.';
      case 'unauthenticated':
        return 'Please log in to continue.';
      case 'deadline-exceeded':
        return 'The request timed out. Please try again.';
      case 'cancelled':
        return 'The operation was cancelled.';
      default:
        _logger.warning('Unhandled Firestore error: ${error.code}');
        return 'Database operation failed. Please try again.';
    }
  }

  /// Shows a user-friendly error message using SnackBar
  static void showErrorSnackBar(
    BuildContext context,
    Exception error, {
    String? errorContext,
    Duration duration = const Duration(seconds: 4),
  }) {
    final message = handleError(error, context: errorContext);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Shows a success message using SnackBar
  static void showSuccessSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Shows an info message using SnackBar
  static void showInfoSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Creates a standardized error dialog
  static void showErrorDialog(
    BuildContext context,
    Exception error, {
    String? title,
    String? errorContext,
    VoidCallback? onRetry,
  }) {
    final message = handleError(error, context: errorContext);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title ?? 'Error'),
          content: Text(message),
          actions: [
            if (onRetry != null)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onRetry();
                },
                child: const Text('Retry'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Wraps an async operation with error handling
  static Future<T?> wrapAsync<T>(
    Future<T> Function() operation, {
    String? context,
    bool shouldLog = true,
  }) async {
    try {
      return await operation();
    } catch (e) {
      if (e is Exception) {
        handleError(e, context: context, shouldLog: shouldLog);
      } else {
        handleError(Exception(e.toString()), context: context, shouldLog: shouldLog);
      }
      return null;
    }
  }

  /// Validates that required fields are not empty
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates email format
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  /// Validates password strength
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    
    return null;
  }

  /// Validates that passwords match
  static String? validatePasswordConfirmation(String? password, String? confirmation) {
    if (confirmation == null || confirmation.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (password != confirmation) {
      return 'Passwords do not match';
    }
    
    return null;
  }
}

/// Custom exceptions for application-specific errors
class AppException implements Exception {
  final String message;
  final String? code;
  
  const AppException(this.message, [this.code]);
  
  @override
  String toString() => 'AppException: $message${code != null ? ' (Code: $code)' : ''}';
}

class ValidationException extends AppException {
  const ValidationException(String message) : super(message, 'validation');
}

class NetworkException extends AppException {
  const NetworkException(String message) : super(message, 'network');
}

class AuthenticationException extends AppException {
  const AuthenticationException(String message) : super(message, 'auth');
}

class PermissionException extends AppException {
  const PermissionException(String message) : super(message, 'permission');
}