import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';


/// Widget for previewing selected files before upload
class FilePreviewWidget extends StatelessWidget {
  final List<File> files;
  final Function(File)? onRemoveFile;
  final Function(File)? onPreviewFile;
  final bool showRemoveButton;
  final bool showPreviewButton;
  final double maxHeight;

  const FilePreviewWidget({
    super.key,
    required this.files,
    this.onRemoveFile,
    this.onPreviewFile,
    this.showRemoveButton = true,
    this.showPreviewButton = true,
    this.maxHeight = 200,
  });

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: files.length,
        itemBuilder: (context, index) {
          final file = files[index];
          return FilePreviewTile(
            file: file,
            onRemove: showRemoveButton ? () => onRemoveFile?.call(file) : null,
            onPreview: showPreviewButton ? () => onPreviewFile?.call(file) : null,
          );
        },
      ),
    );
  }
}

/// Individual file preview tile
class FilePreviewTile extends StatefulWidget {
  final File file;
  final VoidCallback? onRemove;
  final VoidCallback? onPreview;

  const FilePreviewTile({
    super.key,
    required this.file,
    this.onRemove,
    this.onPreview,
  });

  @override
  State<FilePreviewTile> createState() => _FilePreviewTileState();
}

class _FilePreviewTileState extends State<FilePreviewTile> {
  int? _fileSize;
  String? _mimeType;

  @override
  void initState() {
    super.initState();
    _loadFileInfo();
  }

  Future<void> _loadFileInfo() async {
    try {
      final size = await widget.file.length();
      final mime = lookupMimeType(widget.file.path);
      
      if (mounted) {
        setState(() {
          _fileSize = size;
          _mimeType = mime;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  String get _fileName => path.basename(widget.file.path);
  
  String get _fileSizeText {
    if (_fileSize == null) return '';
    
    if (_fileSize! < 1024) {
      return '${_fileSize!} B';
    } else if (_fileSize! < 1024 * 1024) {
      return '${(_fileSize! / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(_fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  IconData get _fileIcon {
    if (_mimeType == null) return Icons.insert_drive_file;
    
    if (_mimeType!.startsWith('image/')) {
      return Icons.image;
    } else if (_mimeType!.startsWith('video/')) {
      return Icons.video_file;
    } else if (_mimeType!.startsWith('audio/')) {
      return Icons.audio_file;
    } else if (_mimeType == 'application/pdf') {
      return Icons.picture_as_pdf;
    } else if (_mimeType!.startsWith('application/') || _mimeType!.startsWith('text/')) {
      return Icons.description;
    } else {
      return Icons.insert_drive_file;
    }
  }

  Color get _fileIconColor {
    if (_mimeType == null) return Colors.grey;
    
    if (_mimeType!.startsWith('image/')) {
      return Colors.green;
    } else if (_mimeType!.startsWith('video/')) {
      return Colors.blue;
    } else if (_mimeType!.startsWith('audio/')) {
      return Colors.orange;
    } else if (_mimeType == 'application/pdf') {
      return Colors.red;
    } else if (_mimeType!.startsWith('application/') || _mimeType!.startsWith('text/')) {
      return Colors.indigo;
    } else {
      return Colors.grey;
    }
  }

  Widget _buildThumbnail() {
    if (_mimeType?.startsWith('image/') == true) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          widget.file,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _fileIconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _fileIcon,
                color: _fileIconColor,
                size: 24,
              ),
            );
          },
        ),
      );
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _fileIconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        _fileIcon,
        color: _fileIconColor,
        size: 24,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Thumbnail
            _buildThumbnail(),
            
            const SizedBox(width: 12),
            
            // File info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _fileName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _fileSizeText,
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            // Action buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.onPreview != null)
                  IconButton(
                    onPressed: widget.onPreview,
                    icon: const Icon(Icons.visibility),
                    iconSize: 20,
                    tooltip: 'Preview',
                  ),
                
                if (widget.onRemove != null)
                  IconButton(
                    onPressed: widget.onRemove,
                    icon: const Icon(Icons.close),
                    iconSize: 20,
                    color: Colors.red,
                    tooltip: 'Remove',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Grid view for file previews (useful for images)
class FilePreviewGrid extends StatelessWidget {
  final List<File> files;
  final Function(File)? onRemoveFile;
  final Function(File)? onPreviewFile;
  final bool showRemoveButton;
  final bool showPreviewButton;
  final int crossAxisCount;
  final double childAspectRatio;

  const FilePreviewGrid({
    super.key,
    required this.files,
    this.onRemoveFile,
    this.onPreviewFile,
    this.showRemoveButton = true,
    this.showPreviewButton = true,
    this.crossAxisCount = 3,
    this.childAspectRatio = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return FilePreviewGridItem(
          file: file,
          onRemove: showRemoveButton ? () => onRemoveFile?.call(file) : null,
          onPreview: showPreviewButton ? () => onPreviewFile?.call(file) : null,
        );
      },
    );
  }
}

/// Grid item for file preview
class FilePreviewGridItem extends StatefulWidget {
  final File file;
  final VoidCallback? onRemove;
  final VoidCallback? onPreview;

  const FilePreviewGridItem({
    super.key,
    required this.file,
    this.onRemove,
    this.onPreview,
  });

  @override
  State<FilePreviewGridItem> createState() => _FilePreviewGridItemState();
}

class _FilePreviewGridItemState extends State<FilePreviewGridItem> {
  String? _mimeType;

  @override
  void initState() {
    super.initState();
    _mimeType = lookupMimeType(widget.file.path);
  }

  String get _fileName => path.basename(widget.file.path);

  Widget _buildPreview() {
    if (_mimeType?.startsWith('image/') == true) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          widget.file,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return _buildIconPreview();
          },
        ),
      );
    }

    return _buildIconPreview();
  }

  Widget _buildIconPreview() {
    IconData icon;
    Color color;

    if (_mimeType?.startsWith('video/') == true) {
      icon = Icons.video_file;
      color = Colors.blue;
    } else if (_mimeType?.startsWith('audio/') == true) {
      icon = Icons.audio_file;
      color = Colors.orange;
    } else if (_mimeType == 'application/pdf') {
      icon = Icons.picture_as_pdf;
      color = Colors.red;
    } else if (_mimeType?.startsWith('application/') == true || _mimeType?.startsWith('text/') == true) {
      icon = Icons.description;
      color = Colors.indigo;
    } else {
      icon = Icons.insert_drive_file;
      color = Colors.grey;
    }

    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 32,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              _fileName,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPreview,
      child: Stack(
        children: [
          // Preview
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
            child: _buildPreview(),
          ),
          
          // Remove button
          if (widget.onRemove != null)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: widget.onRemove,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}