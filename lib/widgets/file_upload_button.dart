import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/file_service.dart';
import '../core/core.dart';
import 'upload_progress_dialog.dart';

/// Simple file upload button that handles the entire upload process
class FileUploadButton extends ConsumerStatefulWidget {
  final FileUploadConfig config;
  final String userId;
  final Function(List<FileInfo>) onFilesUploaded;
  final Function(String)? onError;
  final bool allowMultiple;
  final String? buttonText;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool enabled;

  const FileUploadButton({
    super.key,
    this.config = const FileUploadConfig(),
    required this.userId,
    required this.onFilesUploaded,
    this.onError,
    this.allowMultiple = false,
    this.buttonText,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.enabled = true,
  });

  @override
  ConsumerState<FileUploadButton> createState() => _FileUploadButtonState();
}

class _FileUploadButtonState extends ConsumerState<FileUploadButton> {
  final FileService _fileService = FileService();
  bool _isUploading = false;
  UploadProgressController? _progressController;

  @override
  void dispose() {
    _progressController?.hide();
    super.dispose();
  }

  Future<void> _handleUpload() async {
    if (!widget.enabled || _isUploading) return;

    setState(() {
      _isUploading = true;
    });

    try {
      // Pick files
      final Result<List<File>> pickResult;
      
      if (widget.allowMultiple) {
        pickResult = await _fileService.pickMultipleFiles(
          config: widget.config,
          maxFiles: 10,
        );
      } else {
        final singleResult = await _fileService.pickFile(config: widget.config);
        pickResult = singleResult.isSuccess 
            ? Result.success([singleResult.data!])
            : Result.error(singleResult.errorMessage!);
      }

      if (pickResult.isError) {
        _showErrorSnackBar(pickResult.errorMessage!);
        return;
      }

      final files = pickResult.data!;
      if (files.isEmpty) return;

      // Show progress dialog
      _progressController = UploadProgressController();
      _progressController!.show(
        context,
        message: 'Uploading ${files.length} file(s)...',
        canCancel: false,
      );

      // Upload files
      final uploadResult = await _fileService.uploadMultipleFiles(
        files,
        userId: widget.userId,
        config: widget.config,
        onProgress: (completed, total) {
          final progress = completed / total;
          _progressController?.updateProgress(progress);
        },
      );

      _progressController?.hide();

      if (uploadResult.isSuccess) {
        widget.onFilesUploaded(uploadResult.data!);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully uploaded ${uploadResult.data!.length} file(s)'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        final errorMessage = uploadResult.errorMessage!;
        widget.onError?.call(errorMessage);
        _progressController?.showError(
          errorMessage,
          onRetry: _handleUpload,
        );
      }
    } catch (e) {
      final errorMessage = 'Upload failed: ${e.toString()}';
      widget.onError?.call(errorMessage);
      _progressController?.showError(
        errorMessage,
        onRetry: _handleUpload,
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String get _defaultButtonText {
    if (widget.buttonText != null) return widget.buttonText!;
    
    switch (widget.config.fileType) {
      case SupportedFileType.image:
        return widget.allowMultiple ? 'Upload Images' : 'Upload Image';
      case SupportedFileType.document:
        return widget.allowMultiple ? 'Upload Documents' : 'Upload Document';
      case SupportedFileType.pdf:
        return widget.allowMultiple ? 'Upload PDFs' : 'Upload PDF';
      case SupportedFileType.video:
        return widget.allowMultiple ? 'Upload Videos' : 'Upload Video';
      case SupportedFileType.audio:
        return widget.allowMultiple ? 'Upload Audio Files' : 'Upload Audio File';
      case SupportedFileType.any:
        return widget.allowMultiple ? 'Upload Files' : 'Upload File';
    }
  }

  IconData get _defaultIcon {
    if (widget.icon != null) return widget.icon!;
    
    switch (widget.config.fileType) {
      case SupportedFileType.image:
        return Icons.image;
      case SupportedFileType.document:
        return Icons.description;
      case SupportedFileType.pdf:
        return Icons.picture_as_pdf;
      case SupportedFileType.video:
        return Icons.video_file;
      case SupportedFileType.audio:
        return Icons.audio_file;
      case SupportedFileType.any:
        return Icons.cloud_upload;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ElevatedButton.icon(
      onPressed: widget.enabled && !_isUploading ? _handleUpload : null,
      icon: _isUploading 
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  widget.foregroundColor ?? theme.colorScheme.onPrimary,
                ),
              ),
            )
          : Icon(_defaultIcon),
      label: Text(_isUploading ? 'Uploading...' : _defaultButtonText),
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.backgroundColor ?? theme.primaryColor,
        foregroundColor: widget.foregroundColor ?? theme.colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

/// Compact file upload icon button
class CompactFileUploadButton extends ConsumerStatefulWidget {
  final FileUploadConfig config;
  final String userId;
  final Function(List<FileInfo>) onFilesUploaded;
  final Function(String)? onError;
  final bool allowMultiple;
  final String? tooltip;
  final IconData? icon;
  final Color? iconColor;
  final bool enabled;

  const CompactFileUploadButton({
    super.key,
    this.config = const FileUploadConfig(),
    required this.userId,
    required this.onFilesUploaded,
    this.onError,
    this.allowMultiple = false,
    this.tooltip,
    this.icon,
    this.iconColor,
    this.enabled = true,
  });

  @override
  ConsumerState<CompactFileUploadButton> createState() => _CompactFileUploadButtonState();
}

class _CompactFileUploadButtonState extends ConsumerState<CompactFileUploadButton> {
  final FileService _fileService = FileService();
  bool _isUploading = false;
  UploadProgressController? _progressController;

  @override
  void dispose() {
    _progressController?.hide();
    super.dispose();
  }

  Future<void> _handleUpload() async {
    if (!widget.enabled || _isUploading) return;

    setState(() {
      _isUploading = true;
    });

    try {
      // Pick files
      final Result<List<File>> pickResult;
      
      if (widget.allowMultiple) {
        pickResult = await _fileService.pickMultipleFiles(
          config: widget.config,
          maxFiles: 10,
        );
      } else {
        final singleResult = await _fileService.pickFile(config: widget.config);
        pickResult = singleResult.isSuccess 
            ? Result.success([singleResult.data!])
            : Result.error(singleResult.errorMessage!);
      }

      if (pickResult.isError) {
        _showErrorSnackBar(pickResult.errorMessage!);
        return;
      }

      final files = pickResult.data!;
      if (files.isEmpty) return;

      // Show progress dialog
      _progressController = UploadProgressController();
      _progressController!.show(
        context,
        message: 'Uploading ${files.length} file(s)...',
        canCancel: false,
      );

      // Upload files
      final uploadResult = await _fileService.uploadMultipleFiles(
        files,
        userId: widget.userId,
        config: widget.config,
        onProgress: (completed, total) {
          final progress = completed / total;
          _progressController?.updateProgress(progress);
        },
      );

      _progressController?.hide();

      if (uploadResult.isSuccess) {
        widget.onFilesUploaded(uploadResult.data!);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully uploaded ${uploadResult.data!.length} file(s)'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        final errorMessage = uploadResult.errorMessage!;
        widget.onError?.call(errorMessage);
        _progressController?.showError(
          errorMessage,
          onRetry: _handleUpload,
        );
      }
    } catch (e) {
      final errorMessage = 'Upload failed: ${e.toString()}';
      widget.onError?.call(errorMessage);
      _progressController?.showError(
        errorMessage,
        onRetry: _handleUpload,
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  IconData get _defaultIcon {
    if (widget.icon != null) return widget.icon!;
    
    switch (widget.config.fileType) {
      case SupportedFileType.image:
        return Icons.image;
      case SupportedFileType.document:
        return Icons.description;
      case SupportedFileType.pdf:
        return Icons.picture_as_pdf;
      case SupportedFileType.video:
        return Icons.video_file;
      case SupportedFileType.audio:
        return Icons.audio_file;
      case SupportedFileType.any:
        return Icons.attach_file;
    }
  }

  String get _defaultTooltip {
    if (widget.tooltip != null) return widget.tooltip!;
    
    switch (widget.config.fileType) {
      case SupportedFileType.image:
        return widget.allowMultiple ? 'Upload images' : 'Upload image';
      case SupportedFileType.document:
        return widget.allowMultiple ? 'Upload documents' : 'Upload document';
      case SupportedFileType.pdf:
        return widget.allowMultiple ? 'Upload PDFs' : 'Upload PDF';
      case SupportedFileType.video:
        return widget.allowMultiple ? 'Upload videos' : 'Upload video';
      case SupportedFileType.audio:
        return widget.allowMultiple ? 'Upload audio files' : 'Upload audio file';
      case SupportedFileType.any:
        return widget.allowMultiple ? 'Upload files' : 'Upload file';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: _defaultTooltip,
      child: IconButton(
        onPressed: widget.enabled && !_isUploading ? _handleUpload : null,
        icon: _isUploading 
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.iconColor ?? theme.iconTheme.color ?? Colors.grey,
                  ),
                ),
              )
            : Icon(
                _defaultIcon,
                color: widget.iconColor,
              ),
        iconSize: 24,
      ),
    );
  }
}