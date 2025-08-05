import 'package:flutter/material.dart';

/// Dialog widget that shows upload progress with retry functionality
class UploadProgressDialog extends StatelessWidget {
  final double? progress;
  final String message;
  final bool hasError;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;
  final bool canCancel;

  const UploadProgressDialog({
    super.key,
    this.progress,
    this.message = 'Uploading...',
    this.hasError = false,
    this.errorMessage,
    this.onRetry,
    this.onCancel,
    this.canCancel = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return PopScope(
      canPop: canCancel && !hasError,
      child: Dialog(
        backgroundColor: theme.scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: hasError 
                      ? Colors.red.withOpacity(0.1)
                      : theme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasError ? Icons.error : Icons.cloud_upload,
                  color: hasError ? Colors.red : theme.primaryColor,
                  size: 32,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Title
              Text(
                hasError ? 'Upload Failed' : 'Uploading Image',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              // Message
              Text(
                hasError ? (errorMessage ?? 'An error occurred') : message,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.shadowColor.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 20),
              
              // Progress indicator or error state
              if (!hasError) ...[
                // Progress bar
                if (progress != null) ...[
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: theme.cardColor,
                    valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(progress! * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.shadowColor.withOpacity(0.6),
                    ),
                  ),
                ] else ...[
                  // Indeterminate progress
                  LinearProgressIndicator(
                    backgroundColor: theme.cardColor,
                    valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                  ),
                ],
              ],
              
              const SizedBox(height: 24),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (hasError && onRetry != null) ...[
                    TextButton(
                      onPressed: onRetry,
                      child: Text(
                        'Retry',
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  
                  if (canCancel || hasError)
                    TextButton(
                      onPressed: onCancel ?? () => Navigator.of(context).pop(),
                      child: Text(
                        hasError ? 'Close' : 'Cancel',
                        style: TextStyle(
                          color: theme.shadowColor.withOpacity(0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows an upload progress dialog
Future<T?> showUploadProgressDialog<T>(
  BuildContext context, {
  double? progress,
  String message = 'Uploading...',
  bool hasError = false,
  String? errorMessage,
  VoidCallback? onRetry,
  VoidCallback? onCancel,
  bool canCancel = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: canCancel && !hasError,
    builder: (context) => UploadProgressDialog(
      progress: progress,
      message: message,
      hasError: hasError,
      errorMessage: errorMessage,
      onRetry: onRetry,
      onCancel: onCancel,
      canCancel: canCancel,
    ),
  );
}

/// Controller for managing upload progress dialog state
class UploadProgressController {
  BuildContext? _context;
  bool _isShowing = false;

  /// Shows the progress dialog
  void show(
    BuildContext context, {
    String message = 'Uploading...',
    bool canCancel = true,
  }) {
    if (_isShowing) return;
    
    _context = context;
    _isShowing = true;
    
    showUploadProgressDialog(
      context,
      message: message,
      canCancel: canCancel,
      onCancel: () {
        hide();
      },
    ).then((_) {
      _isShowing = false;
      _context = null;
    });
  }

  /// Updates the progress (0.0 to 1.0)
  void updateProgress(double progress, {String? message}) {
    if (!_isShowing || _context == null) return;
    
    // In a real implementation, you would update the dialog state
    // For now, we'll just log the progress
    debugPrint('Upload progress: ${(progress * 100).toInt()}%');
  }

  /// Shows error state
  void showError(String errorMessage, {VoidCallback? onRetry}) {
    if (!_isShowing || _context == null) return;
    
    // Hide current dialog and show error dialog
    hide();
    
    showUploadProgressDialog(
      _context!,
      hasError: true,
      errorMessage: errorMessage,
      onRetry: onRetry,
      canCancel: true,
    );
  }

  /// Hides the dialog
  void hide() {
    if (!_isShowing || _context == null) return;
    
    Navigator.of(_context!).pop();
    _isShowing = false;
    _context = null;
  }

  /// Whether the dialog is currently showing
  bool get isShowing => _isShowing;
}