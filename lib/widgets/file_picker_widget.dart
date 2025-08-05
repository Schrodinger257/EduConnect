import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/file_service.dart';
import '../core/core.dart';

/// Widget for picking files with support for different file types
class FilePickerWidget extends ConsumerStatefulWidget {
  final FileUploadConfig config;
  final Function(List<File>) onFilesSelected;
  final bool allowMultiple;
  final String? buttonText;
  final Widget? customButton;
  final bool enabled;

  const FilePickerWidget({
    super.key,
    this.config = const FileUploadConfig(),
    required this.onFilesSelected,
    this.allowMultiple = false,
    this.buttonText,
    this.customButton,
    this.enabled = true,
  });

  @override
  ConsumerState<FilePickerWidget> createState() => _FilePickerWidgetState();
}

class _FilePickerWidgetState extends ConsumerState<FilePickerWidget> {
  final FileService _fileService = FileService();
  bool _isLoading = false;

  Future<void> _pickFiles() async {
    if (!widget.enabled || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final Result<List<File>> result;
      
      if (widget.allowMultiple) {
        result = await _fileService.pickMultipleFiles(
          config: widget.config,
          maxFiles: 10,
        );
      } else {
        final singleResult = await _fileService.pickFile(config: widget.config);
        result = singleResult.isSuccess 
            ? Result.success([singleResult.data!])
            : Result.error(singleResult.errorMessage!);
      }

      if (result.isSuccess) {
        widget.onFilesSelected(result.data!);
      } else {
        _showErrorSnackBar(result.errorMessage!);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick files: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
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

  String get _buttonText {
    if (widget.buttonText != null) return widget.buttonText!;
    
    switch (widget.config.fileType) {
      case SupportedFileType.image:
        return widget.allowMultiple ? 'Select Images' : 'Select Image';
      case SupportedFileType.document:
        return widget.allowMultiple ? 'Select Documents' : 'Select Document';
      case SupportedFileType.pdf:
        return widget.allowMultiple ? 'Select PDFs' : 'Select PDF';
      case SupportedFileType.video:
        return widget.allowMultiple ? 'Select Videos' : 'Select Video';
      case SupportedFileType.audio:
        return widget.allowMultiple ? 'Select Audio Files' : 'Select Audio File';
      case SupportedFileType.any:
        return widget.allowMultiple ? 'Select Files' : 'Select File';
    }
  }

  IconData get _buttonIcon {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.customButton != null) {
      return GestureDetector(
        onTap: _pickFiles,
        child: widget.customButton!,
      );
    }

    return ElevatedButton.icon(
      onPressed: widget.enabled && !_isLoading ? _pickFiles : null,
      icon: _isLoading 
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.onPrimary,
                ),
              ),
            )
          : Icon(_buttonIcon),
      label: Text(_buttonText),
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.primaryColor,
        foregroundColor: theme.colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

/// Compact file picker button for use in forms or toolbars
class CompactFilePickerButton extends StatelessWidget {
  final FileUploadConfig config;
  final Function(List<File>) onFilesSelected;
  final bool allowMultiple;
  final String? tooltip;
  final bool enabled;

  const CompactFilePickerButton({
    super.key,
    this.config = const FileUploadConfig(),
    required this.onFilesSelected,
    this.allowMultiple = false,
    this.tooltip,
    this.enabled = true,
  });

  IconData get _icon {
    switch (config.fileType) {
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
    switch (config.fileType) {
      case SupportedFileType.image:
        return allowMultiple ? 'Attach images' : 'Attach image';
      case SupportedFileType.document:
        return allowMultiple ? 'Attach documents' : 'Attach document';
      case SupportedFileType.pdf:
        return allowMultiple ? 'Attach PDFs' : 'Attach PDF';
      case SupportedFileType.video:
        return allowMultiple ? 'Attach videos' : 'Attach video';
      case SupportedFileType.audio:
        return allowMultiple ? 'Attach audio files' : 'Attach audio file';
      case SupportedFileType.any:
        return allowMultiple ? 'Attach files' : 'Attach file';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FilePickerWidget(
      config: config,
      onFilesSelected: onFilesSelected,
      allowMultiple: allowMultiple,
      enabled: enabled,
      customButton: Tooltip(
        message: tooltip ?? _defaultTooltip,
        child: IconButton(
          onPressed: enabled ? null : null, // Will be handled by FilePickerWidget
          icon: Icon(_icon),
          iconSize: 24,
        ),
      ),
    );
  }
}

/// File type selector for choosing what type of files to pick
class FileTypeSelector extends StatelessWidget {
  final SupportedFileType selectedType;
  final Function(SupportedFileType) onTypeChanged;
  final List<SupportedFileType> availableTypes;

  const FileTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
    this.availableTypes = const [
      SupportedFileType.any,
      SupportedFileType.image,
      SupportedFileType.document,
      SupportedFileType.pdf,
      SupportedFileType.video,
      SupportedFileType.audio,
    ],
  });

  String _getTypeLabel(SupportedFileType type) {
    switch (type) {
      case SupportedFileType.image:
        return 'Images';
      case SupportedFileType.document:
        return 'Documents';
      case SupportedFileType.pdf:
        return 'PDFs';
      case SupportedFileType.video:
        return 'Videos';
      case SupportedFileType.audio:
        return 'Audio';
      case SupportedFileType.any:
        return 'All Files';
    }
  }

  IconData _getTypeIcon(SupportedFileType type) {
    switch (type) {
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
        return Icons.folder;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'File Type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableTypes.map((type) {
              final isSelected = type == selectedType;
              return FilterChip(
                selected: isSelected,
                onSelected: (_) => onTypeChanged(type),
                avatar: Icon(
                  _getTypeIcon(type),
                  size: 18,
                  color: isSelected 
                      ? theme.colorScheme.onPrimary
                      : theme.iconTheme.color,
                ),
                label: Text(_getTypeLabel(type)),
                backgroundColor: theme.cardColor,
                selectedColor: theme.primaryColor,
                labelStyle: TextStyle(
                  color: isSelected 
                      ? theme.colorScheme.onPrimary
                      : theme.textTheme.bodyMedium?.color,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}