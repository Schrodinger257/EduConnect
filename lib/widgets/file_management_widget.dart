import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';
import '../services/file_service.dart';

import 'file_picker_widget.dart';
import 'file_preview_widget.dart';
import 'upload_progress_dialog.dart';

/// Comprehensive file management widget that handles picking, previewing, and uploading files
class FileManagementWidget extends ConsumerStatefulWidget {
  final FileUploadConfig config;
  final String userId;
  final Function(List<FileInfo>)? onFilesUploaded;
  final Function(String)? onError;
  final bool allowMultiple;
  final bool showPreviewGrid;
  final String? title;
  final String? description;
  final Widget? customPickerButton;

  const FileManagementWidget({
    super.key,
    this.config = const FileUploadConfig(),
    required this.userId,
    this.onFilesUploaded,
    this.onError,
    this.allowMultiple = false,
    this.showPreviewGrid = false,
    this.title,
    this.description,
    this.customPickerButton,
  });

  @override
  ConsumerState<FileManagementWidget> createState() =>
      _FileManagementWidgetState();
}

class _FileManagementWidgetState extends ConsumerState<FileManagementWidget> {
  final FileService _fileService = FileService();
  final List<File> _selectedFiles = [];
  final List<FileInfo> _uploadedFiles = [];
  bool _isUploading = false;

  UploadProgressController? _progressController;

  @override
  void dispose() {
    _progressController?.hide();
    super.dispose();
  }

  void _onFilesSelected(List<File> files) {
    setState(() {
      if (widget.allowMultiple) {
        _selectedFiles.addAll(files);
      } else {
        _selectedFiles.clear();
        _selectedFiles.addAll(files);
      }
    });
  }

  void _removeFile(File file) {
    setState(() {
      _selectedFiles.remove(file);
    });
  }

  void _previewFile(File file) {
    // Show file preview dialog
    showDialog(
      context: context,
      builder: (context) => FilePreviewDialog(file: file),
    );
  }

  Future<void> _uploadFiles() async {
    if (_selectedFiles.isEmpty || _isUploading) return;
    double _uploadProgress = 0.0;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    _progressController = UploadProgressController();
    _progressController!.show(
      context,
      message: 'Uploading ${_selectedFiles.length} file(s)...',
      canCancel: false,
    );

    try {
      final result = await _fileService.uploadMultipleFiles(
        _selectedFiles,
        userId: widget.userId,
        config: widget.config,
        onProgress: (completed, total) {
          final progress = completed / total;
          setState(() {
            _uploadProgress = progress;
          });
          _progressController?.updateProgress(progress);
        },
      );

      _progressController?.hide();

      if (result.isSuccess) {
        setState(() {
          _uploadedFiles.addAll(result.data!);
          _selectedFiles.clear();
        });

        widget.onFilesUploaded?.call(result.data!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Successfully uploaded ${result.data!.length} file(s)',
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        widget.onError?.call(result.errorMessage!);
        _progressController?.showError(
          result.errorMessage!,
          onRetry: _uploadFiles,
        );
      }
    } catch (e) {
      final errorMessage = 'Upload failed: ${e.toString()}';
      widget.onError?.call(errorMessage);
      _progressController?.showError(errorMessage, onRetry: _uploadFiles);
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
    }
  }

  void _removeUploadedFile(FileInfo fileInfo) async {
    try {
      final result = await _fileService.deleteFile(fileInfo.id);

      if (result.isSuccess) {
        setState(() {
          _uploadedFiles.remove(fileInfo);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File deleted successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        widget.onError?.call(result.errorMessage!);
      }
    } catch (e) {
      widget.onError?.call('Failed to delete file: ${e.toString()}');
    }
  }

  Widget _buildFileConstraints() {
    final theme = Theme.of(context);
    final constraints = <String>[];

    if (widget.config.maxSizeInMB > 0) {
      constraints.add('Max size: ${widget.config.maxSizeInMB}MB');
    }

    if (widget.config.allowedExtensions.isNotEmpty) {
      final extensions = widget.config.allowedExtensions
          .map((e) => e.toUpperCase())
          .join(', ');
      constraints.add('Allowed: $extensions');
    }

    if (constraints.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: theme.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              constraints.join(' • '),
              style: TextStyle(
                fontSize: 12,
                color: theme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and description
        if (widget.title != null) ...[
          Text(
            widget.title!,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
        ],

        if (widget.description != null) ...[
          Text(
            widget.description!,
            style: TextStyle(
              fontSize: 14,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 16),
        ],

        // File constraints
        _buildFileConstraints(),
        const SizedBox(height: 16),

        // File picker
        if (widget.customPickerButton != null)
          GestureDetector(
            onTap: () => _onFilesSelected([]),
            child: widget.customPickerButton!,
          )
        else
          FilePickerWidget(
            config: widget.config,
            onFilesSelected: _onFilesSelected,
            allowMultiple: widget.allowMultiple,
            enabled: !_isUploading,
          ),

        const SizedBox(height: 16),

        // Selected files preview
        if (_selectedFiles.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Selected Files (${_selectedFiles.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_selectedFiles.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: _isUploading ? null : _uploadFiles,
                  icon: _isUploading
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
                      : const Icon(Icons.cloud_upload),
                  label: Text(_isUploading ? 'Uploading...' : 'Upload'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (widget.showPreviewGrid)
            FilePreviewGrid(
              files: _selectedFiles,
              onRemoveFile: _removeFile,
              onPreviewFile: _previewFile,
              showRemoveButton: !_isUploading,
            )
          else
            FilePreviewWidget(
              files: _selectedFiles,
              onRemoveFile: _removeFile,
              onPreviewFile: _previewFile,
              showRemoveButton: !_isUploading,
            ),

          const SizedBox(height: 16),
        ],

        // Uploaded files
        if (_uploadedFiles.isNotEmpty) ...[
          const Divider(),
          const SizedBox(height: 16),

          Text(
            'Uploaded Files (${_uploadedFiles.length})',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          UploadedFilesList(
            files: _uploadedFiles,
            onRemoveFile: _removeUploadedFile,
          ),
        ],
      ],
    );
  }
}

/// Widget to display uploaded files
class UploadedFilesList extends StatelessWidget {
  final List<FileInfo> files;
  final Function(FileInfo)? onRemoveFile;

  const UploadedFilesList({super.key, required this.files, this.onRemoveFile});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return UploadedFileTile(
          fileInfo: file,
          onRemove: onRemoveFile != null ? () => onRemoveFile!(file) : null,
        );
      },
    );
  }
}

/// Tile for displaying uploaded file information
class UploadedFileTile extends StatelessWidget {
  final FileInfo fileInfo;
  final VoidCallback? onRemove;

  const UploadedFileTile({super.key, required this.fileInfo, this.onRemove});

  IconData get _fileIcon {
    if (fileInfo.isImage) return Icons.image;
    if (fileInfo.isVideo) return Icons.video_file;
    if (fileInfo.isAudio) return Icons.audio_file;
    if (fileInfo.mimeType == 'application/pdf') return Icons.picture_as_pdf;
    if (fileInfo.isDocument) return Icons.description;
    return Icons.insert_drive_file;
  }

  Color get _fileIconColor {
    if (fileInfo.isImage) return Colors.green;
    if (fileInfo.isVideo) return Colors.blue;
    if (fileInfo.isAudio) return Colors.orange;
    if (fileInfo.mimeType == 'application/pdf') return Colors.red;
    if (fileInfo.isDocument) return Colors.indigo;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _fileIconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_fileIcon, color: _fileIconColor, size: 20),
        ),
        title: Text(
          fileInfo.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${fileInfo.sizeInMB.toStringAsFixed(1)} MB • Uploaded ${_formatDate(fileInfo.uploadedAt)}',
          style: TextStyle(
            color: theme.textTheme.bodySmall?.color,
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _openFile(context),
              icon: const Icon(Icons.open_in_new),
              iconSize: 20,
              tooltip: 'Open file',
            ),
            if (onRemove != null)
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete),
                iconSize: 20,
                color: Colors.red,
                tooltip: 'Delete file',
              ),
          ],
        ),
      ),
    );
  }

  void _openFile(BuildContext context) {
    // Open file URL in browser or show preview
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(fileInfo.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Size: ${fileInfo.sizeInMB.toStringAsFixed(1)} MB'),
            Text('Type: ${fileInfo.mimeType}'),
            Text('Uploaded: ${_formatDate(fileInfo.uploadedAt)}'),
            const SizedBox(height: 16),
            Text('URL: ${fileInfo.url}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

/// Dialog for previewing files
class FilePreviewDialog extends StatelessWidget {
  final File file;

  const FilePreviewDialog({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    final mimeType = lookupMimeType(file.path);
    final fileName = path.basename(file.path);

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      fileName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildPreviewContent(mimeType),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewContent(String? mimeType) {
    if (mimeType?.startsWith('image/') == true) {
      return Center(
        child: Image.file(
          file,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Unable to preview image'),
                ],
              ),
            );
          },
        ),
      );
    }

    // For non-image files, show file info
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getFileIcon(mimeType),
            size: 64,
            color: _getFileIconColor(mimeType),
          ),
          const SizedBox(height: 16),
          Text(
            'File preview not available',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'File type: ${mimeType ?? 'Unknown'}',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String? mimeType) {
    if (mimeType?.startsWith('video/') == true) return Icons.video_file;
    if (mimeType?.startsWith('audio/') == true) return Icons.audio_file;
    if (mimeType == 'application/pdf') return Icons.picture_as_pdf;
    if (mimeType?.startsWith('application/') == true ||
        mimeType?.startsWith('text/') == true) {
      return Icons.description;
    }
    return Icons.insert_drive_file;
  }

  Color _getFileIconColor(String? mimeType) {
    if (mimeType?.startsWith('video/') == true) return Colors.blue;
    if (mimeType?.startsWith('audio/') == true) return Colors.orange;
    if (mimeType == 'application/pdf') return Colors.red;
    if (mimeType?.startsWith('application/') == true ||
        mimeType?.startsWith('text/') == true) {
      return Colors.indigo;
    }
    return Colors.grey;
  }
}
