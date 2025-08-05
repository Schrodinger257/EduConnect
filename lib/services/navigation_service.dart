import 'package:flutter/material.dart';

/// Service for handling navigation throughout the app
/// This centralizes navigation logic and removes it from providers
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  static NavigationService get instance => _instance;

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Get the current context
  BuildContext? get currentContext => navigatorKey.currentContext;

  /// Navigate to a new screen
  Future<T?> navigateTo<T extends Object?>(Widget screen) {
    final context = currentContext;
    if (context == null) return Future.value(null);
    
    return Navigator.of(context).push<T>(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  /// Replace current screen with a new one
  Future<T?> navigateAndReplace<T extends Object?, TO extends Object?>(Widget screen) {
    final context = currentContext;
    if (context == null) return Future.value(null);
    
    return Navigator.of(context).pushReplacement<T, TO>(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  /// Navigate back
  void goBack<T extends Object?>([T? result]) {
    final context = currentContext;
    if (context == null) return;
    
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop<T>(result);
    }
  }

  /// Navigate to named route
  Future<T?> navigateToNamed<T extends Object?>(String routeName, {Object? arguments}) {
    final context = currentContext;
    if (context == null) return Future.value(null);
    
    return Navigator.of(context).pushNamed<T>(routeName, arguments: arguments);
  }

  /// Replace with named route
  Future<T?> navigateAndReplaceNamed<T extends Object?, TO extends Object?>(
    String routeName, {
    Object? arguments,
  }) {
    final context = currentContext;
    if (context == null) return Future.value(null);
    
    return Navigator.of(context).pushReplacementNamed<T, TO>(routeName, arguments: arguments);
  }

  /// Clear navigation stack and navigate to screen
  Future<T?> navigateAndClearStack<T extends Object?>(Widget screen) {
    final context = currentContext;
    if (context == null) return Future.value(null);
    
    return Navigator.of(context).pushAndRemoveUntil<T>(
      MaterialPageRoute(builder: (_) => screen),
      (route) => false,
    );
  }

  /// Show modal bottom sheet
  Future<T?> showCustomModalBottomSheet<T>({
    required Widget child,
    bool isScrollControlled = false,
    bool useSafeArea = false,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    final context = currentContext;
    if (context == null) return Future.value(null);
    
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      useSafeArea: useSafeArea,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      builder: (_) => child,
    );
  }

  /// Show custom dialog
  Future<T?> showCustomDialog<T>({
    required Widget child,
    bool barrierDismissible = true,
  }) {
    final context = currentContext;
    if (context == null) return Future.value(null);
    
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_) => child,
    );
  }

  /// Show snackbar
  void showSnackBar({
    required String message,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    final context = currentContext;
    if (context == null) return;
    
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
        action: action,
      ),
    );
  }

  /// Show success snackbar
  void showSuccessSnackBar(String message) {
    showSnackBar(
      message: message,
      backgroundColor: Colors.green,
    );
  }

  /// Show error snackbar
  void showErrorSnackBar(String message) {
    showSnackBar(
      message: message,
      backgroundColor: Colors.redAccent,
    );
  }

  /// Show info snackbar
  void showInfoSnackBar(String message) {
    showSnackBar(
      message: message,
      backgroundColor: Colors.lightBlueAccent,
    );
  }
}