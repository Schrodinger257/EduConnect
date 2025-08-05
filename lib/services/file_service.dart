import 'dart:io';
import 'package:file_picker/file_picker.dart' as file_picker;
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/core.dart';

/// Supported file types for upload
enum SupportedFileType {
  image,
  document,
  pdf,
  video,
  audio,
  any,
}

/// File upload configuration
class FileUploadConfig {
  final int maxSizeInMB;
  final List<String> allowedExtensions;
  final SupportedFileType fileType;
  final bool enableCompression;
  final String? customPath;

  const FileUploadConfig({
    this.maxSizeInMB = 10,
    this.allowedExtensions = const [],
    this.fileType = SupportedFileType.any,
    this.enableCompression = false,
    this.customPath,
  });

  /// Default configuration for images
  static const image = FileUploadConfig(
    maxSizeInMB: 5,
    allowedExtensions: ['.jpg', '.jpeg', '.png', '.gif', '.webp'],
    fileType: SupportedFileType.image,
    enableCompression: true,
  );

  /// Default configuration for documents
  static const document = FileUploadConfig(
    maxSizeInMB: 25,
    allowedExtensions: ['.pdf', '.doc', '.docx', '.txt', '.rtf'],
    fileType: SupportedFileType.document,
  );

  /// Default configuration for PDFs
  static const pdf = FileUploadConfig(
    maxSizeInMB: 50,
    allowedExtensions: ['.pdf'],
    fileType: SupportedFileType.pdf,
  );

  /// Default configuration for videos
  static const video = FileUploadConfig(
    maxSizeInMB: 100,
    allowedExtensions: ['.mp4', '.mov', '.avi', '.mkv', '.webm'],
    fileType: SupportedFileType.video,
  );

  /// Default configuration for audio
  static const audio = FileUploadConfig(
    maxSizeInMB: 25,
    allowedExtensions: ['.mp3', '.wav', '.aac', '.ogg', '.m4a'],
    fileType: SupportedFileType.audio,
  );
}

/// Information about an uploaded file
class FileInfo {
  final String id;
  final String name;
  final String url;
  final String mimeType;
  final int sizeInBytes;
  final DateTime uploadedAt;
  final String uploadedBy;
  final Map<String, dynamic>? metadata;

  const FileInfo({
    required this.id,
    required this.name,
    required this.url,
    required this.mimeType,
    required this.sizeInBytes,
    required this.uploadedAt,
    required this.uploadedBy,
    this.metadata,
  });

  /// File size in MB
  double get sizeInMB => sizeInBytes / (1024 * 1024);

  /// File extension
  String get extension => path.extension(name).toLowerCase();

  /// Whether the file is an image
  bool get isImage => mimeType.startsWith('image/');

  /// Whether the file is a document
  bool get isDocument => mimeType.startsWith('application/') || 
                        mimeType.startsWith('text/');

  /// Whether the file is a video
  bool get isVideo => mimeType.startsWith('video/');

  /// Whether the file is audio
  bool get isAudio => mimeType.startsWith('audio/');

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'mimeType': mimeType,
      'sizeInBytes': sizeInBytes,
      'uploadedAt': uploadedAt.toIso8601String(),
      'uploadedBy': uploadedBy,
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory FileInfo.fromJson(Map<String, dynamic> json) {
    return FileInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      mimeType: json['mimeType'] as String,
      sizeInBytes: json['sizeInBytes'] as int,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      uploadedBy: json['uploadedBy'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  String toString() {
    return 'FileInfo(name: $name, size: ${sizeInMB.toStringAsFixed(2)}MB, type: $mimeType)';
  }
}

/// Service for handling file operations including upload, validation, and management
class FileService {
  final SupabaseClient _supabase;
  final Logger _logger;
  static const String _bucketName = 'files';

  FileService({
    SupabaseClient? supabase,
    Logger? logger,
  }) : _supabase = supabase ?? Supabase.instance.client,
       _logger = logger ?? Logger();

  /// Picks a file from device storage
  Future<Result<File>> pickFile({
    FileUploadConfig config = const FileUploadConfig(),
  }) async {
    try {
      _logger.info('Picking file with config: ${config.fileType}');

      // Convert our FileType to FilePicker's FileType
      final pickerType = _convertFileType(config.fileType);
      
      final result = await file_picker.FilePicker.platform.pickFiles(
        type: pickerType,
        allowedExtensions: config.allowedExtensions.isNotEmpty 
            ? config.allowedExtensions.map((e) => e.replaceFirst('.', '')).toList()
            : null,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        _logger.info('No file selected');
        return Result.error('No file selected');
      }

      final platformFile = result.files.first;
      if (platformFile.path == null) {
        return Result.error('Unable to access selected file');
      }

      final file = File(platformFile.path!);
      
      // Validate the file
      final validationResult = await validateFile(file, config: config);
      if (validationResult.isError) {
        return Result.error(validationResult.errorMessage!);
      }

      _logger.info('File picked and validated successfully: ${file.path}');
      return Result.success(file);
    } catch (e) {
      _logger.error('Error picking file: $e');
      return Result.error('Failed to pick file: ${e.toString()}');
    }
  }

  /// Picks multiple files from device storage
  Future<Result<List<File>>> pickMultipleFiles({
    FileUploadConfig config = const FileUploadConfig(),
    int maxFiles = 10,
  }) async {
    try {
      _logger.info('Picking multiple files with config: ${config.fileType}');

      final pickerType = _convertFileType(config.fileType);
      
      final result = await file_picker.FilePicker.platform.pickFiles(
        type: pickerType,
        allowedExtensions: config.allowedExtensions.isNotEmpty 
            ? config.allowedExtensions.map((e) => e.replaceFirst('.', '')).toList()
            : null,
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) {
        _logger.info('No files selected');
        return Result.error('No files selected');
      }

      if (result.files.length > maxFiles) {
        return Result.error('Cannot select more than $maxFiles files');
      }

      final files = <File>[];
      for (final platformFile in result.files) {
        if (platformFile.path == null) {
          return Result.error('Unable to access one or more selected files');
        }

        final file = File(platformFile.path!);
        
        // Validate each file
        final validationResult = await validateFile(file, config: config);
        if (validationResult.isError) {
          return Result.error('File ${platformFile.name}: ${validationResult.errorMessage}');
        }

        files.add(file);
      }

      _logger.info('${files.length} files picked and validated successfully');
      return Result.success(files);
    } catch (e) {
      _logger.error('Error picking multiple files: $e');
      return Result.error('Failed to pick files: ${e.toString()}');
    }
  }

  /// Validates a file against the provided configuration
  Future<Result<void>> validateFile(
    File file, {
    FileUploadConfig config = const FileUploadConfig(),
  }) async {
    try {
      _logger.info('Validating file: ${file.path}');
      
      // Check if file exists
      if (!await file.exists()) {
        return Result.error('File does not exist');
      }

      // Check file size
      final fileSize = await file.length();
      final maxSizeInBytes = config.maxSizeInMB * 1024 * 1024;
      
      if (fileSize > maxSizeInBytes) {
        return Result.error('File size cannot exceed ${config.maxSizeInMB}MB');
      }

      // Check file extension if specified
      if (config.allowedExtensions.isNotEmpty) {
        final fileName = file.path.toLowerCase();
        final hasValidExtension = config.allowedExtensions.any((ext) => fileName.endsWith(ext.toLowerCase()));
        
        if (!hasValidExtension) {
          final extensionsText = config.allowedExtensions.join(', ').toUpperCase();
          return Result.error('Only $extensionsText files are allowed');
        }
      }

      // Validate MIME type
      final mimeType = lookupMimeType(file.path);
      if (mimeType == null) {
        return Result.error('Unable to determine file type');
      }

      // Additional validation based on file type
      final typeValidation = _validateFileType(mimeType, config.fileType);
      if (typeValidation.isError) {
        return typeValidation;
      }

      _logger.info('File validation successful');
      return Result.success(null);
    } catch (e) {
      _logger.error('Error validating file: $e');
      return Result.error('Failed to validate file: ${e.toString()}');
    }
  }

  /// Uploads a file to Supabase storage
  Future<Result<FileInfo>> uploadFile(
    File file, {
    required String userId,
    FileUploadConfig config = const FileUploadConfig(),
    String? customFileName,
    Map<String, dynamic>? metadata,
    void Function(double progress)? onProgress,
  }) async {
    try {
      _logger.info('Uploading file: ${file.path}');

      // Validate file first
      final validationResult = await validateFile(file, config: config);
      if (validationResult.isError) {
        return Result.error(validationResult.errorMessage!);
      }

      // Generate unique file name
      final originalName = path.basename(file.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = customFileName ?? '${userId}_${timestamp}_$originalName';
      
      // Determine storage path
      final storagePath = config.customPath ?? _getStoragePath(config.fileType);
      final fullPath = '$storagePath/$fileName';

      // Read file bytes
      final fileBytes = await file.readAsBytes();
      
      // Upload to Supabase
      await _supabase.storage
          .from(_bucketName)
          .uploadBinary(
            fullPath,
            fileBytes,
            fileOptions: FileOptions(
              contentType: lookupMimeType(file.path),
              upsert: false,
            ),
          );

      // Get public URL
      final publicUrl = _supabase.storage
          .from(_bucketName)
          .getPublicUrl(fullPath);

      // Create file info
      final fileInfo = FileInfo(
        id: fullPath,
        name: originalName,
        url: publicUrl,
        mimeType: lookupMimeType(file.path) ?? 'application/octet-stream',
        sizeInBytes: fileBytes.length,
        uploadedAt: DateTime.now(),
        uploadedBy: userId,
        metadata: metadata,
      );

      _logger.info('File uploaded successfully: $publicUrl');
      return Result.success(fileInfo);
    } catch (e) {
      _logger.error('Error uploading file: $e');
      return Result.error('Failed to upload file: ${e.toString()}');
    }
  }

  /// Uploads multiple files
  Future<Result<List<FileInfo>>> uploadMultipleFiles(
    List<File> files, {
    required String userId,
    FileUploadConfig config = const FileUploadConfig(),
    Map<String, dynamic>? metadata,
    void Function(int completed, int total)? onProgress,
  }) async {
    try {
      _logger.info('Uploading ${files.length} files');

      final uploadedFiles = <FileInfo>[];
      
      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        
        final result = await uploadFile(
          file,
          userId: userId,
          config: config,
          metadata: metadata,
        );

        if (result.isError) {
          // Clean up already uploaded files on error
          await _cleanupUploadedFiles(uploadedFiles);
          return Result.error('Failed to upload ${path.basename(file.path)}: ${result.errorMessage}');
        }

        uploadedFiles.add(result.data!);
        onProgress?.call(i + 1, files.length);
      }

      _logger.info('All ${files.length} files uploaded successfully');
      return Result.success(uploadedFiles);
    } catch (e) {
      _logger.error('Error uploading multiple files: $e');
      return Result.error('Failed to upload files: ${e.toString()}');
    }
  }

  /// Deletes a file from Supabase storage
  Future<Result<void>> deleteFile(String fileId) async {
    try {
      _logger.info('Deleting file: $fileId');

      await _supabase.storage
          .from(_bucketName)
          .remove([fileId]);

      _logger.info('File deleted successfully: $fileId');
      return Result.success(null);
    } catch (e) {
      _logger.error('Error deleting file: $e');
      return Result.error('Failed to delete file: ${e.toString()}');
    }
  }

  /// Deletes multiple files
  Future<Result<void>> deleteMultipleFiles(List<String> fileIds) async {
    try {
      _logger.info('Deleting ${fileIds.length} files');

      await _supabase.storage
          .from(_bucketName)
          .remove(fileIds);

      _logger.info('${fileIds.length} files deleted successfully');
      return Result.success(null);
    } catch (e) {
      _logger.error('Error deleting multiple files: $e');
      return Result.error('Failed to delete files: ${e.toString()}');
    }
  }

  /// Gets file information from URL
  Future<Result<FileInfo>> getFileInfo(String fileUrl) async {
    try {
      _logger.info('Getting file info for: $fileUrl');

      // Extract file path from URL
      final uri = Uri.parse(fileUrl);
      final pathSegments = uri.pathSegments;
      
      if (pathSegments.length < 3) {
        return Result.error('Invalid file URL format');
      }

      final filePath = pathSegments.skip(2).join('/');
      
      // This is a simplified version - in a real app, you might want to
      // store file metadata in a database for more detailed information
      final fileName = path.basename(filePath);
      final mimeType = lookupMimeType(fileName) ?? 'application/octet-stream';

      final fileInfo = FileInfo(
        id: filePath,
        name: fileName,
        url: fileUrl,
        mimeType: mimeType,
        sizeInBytes: 0, // Would need to be stored separately
        uploadedAt: DateTime.now(), // Would need to be stored separately
        uploadedBy: '', // Would need to be stored separately
      );

      _logger.info('File info retrieved successfully');
      return Result.success(fileInfo);
    } catch (e) {
      _logger.error('Error getting file info: $e');
      return Result.error('Failed to get file information: ${e.toString()}');
    }
  }

  /// Compresses a file if supported
  Future<Result<File>> compressFile(
    File file, {
    int quality = 80,
    int maxWidth = 1920,
    int maxHeight = 1080,
  }) async {
    try {
      _logger.info('Compressing file: ${file.path}');

      final mimeType = lookupMimeType(file.path);
      
      // Only compress images for now
      if (mimeType == null || !mimeType.startsWith('image/')) {
        _logger.info('File type not supported for compression');
        return Result.success(file);
      }

      // For image compression, we would typically use a library like flutter_image_compress
      // For now, return the original file
      _logger.info('Image compression not implemented yet');
      return Result.success(file);
    } catch (e) {
      _logger.error('Error compressing file: $e');
      return Result.error('Failed to compress file: ${e.toString()}');
    }
  }

  /// Converts our SupportedFileType enum to FilePicker's FileType
  file_picker.FileType _convertFileType(SupportedFileType fileType) {
    switch (fileType) {
      case SupportedFileType.image:
        return file_picker.FileType.image;
      case SupportedFileType.video:
        return file_picker.FileType.video;
      case SupportedFileType.audio:
        return file_picker.FileType.audio;
      case SupportedFileType.document:
      case SupportedFileType.pdf:
        return file_picker.FileType.custom;
      case SupportedFileType.any:
        return file_picker.FileType.any;
    }
  }

  /// Validates file type against expected type
  Result<void> _validateFileType(String mimeType, SupportedFileType expectedType) {
    switch (expectedType) {
      case SupportedFileType.image:
        if (!mimeType.startsWith('image/')) {
          return Result.error('File must be an image');
        }
        break;
      case SupportedFileType.video:
        if (!mimeType.startsWith('video/')) {
          return Result.error('File must be a video');
        }
        break;
      case SupportedFileType.audio:
        if (!mimeType.startsWith('audio/')) {
          return Result.error('File must be an audio file');
        }
        break;
      case SupportedFileType.document:
        if (!mimeType.startsWith('application/') && !mimeType.startsWith('text/')) {
          return Result.error('File must be a document');
        }
        break;
      case SupportedFileType.pdf:
        if (mimeType != 'application/pdf') {
          return Result.error('File must be a PDF');
        }
        break;
      case SupportedFileType.any:
        // Any file type is allowed
        break;
    }
    return Result.success(null);
  }

  /// Gets storage path based on file type
  String _getStoragePath(SupportedFileType fileType) {
    switch (fileType) {
      case SupportedFileType.image:
        return 'images';
      case SupportedFileType.document:
        return 'documents';
      case SupportedFileType.pdf:
        return 'pdfs';
      case SupportedFileType.video:
        return 'videos';
      case SupportedFileType.audio:
        return 'audio';
      case SupportedFileType.any:
        return 'files';
    }
  }

  /// Cleans up uploaded files in case of error
  Future<void> _cleanupUploadedFiles(List<FileInfo> uploadedFiles) async {
    try {
      final fileIds = uploadedFiles.map((f) => f.id).toList();
      if (fileIds.isNotEmpty) {
        await deleteMultipleFiles(fileIds);
      }
    } catch (e) {
      _logger.error('Error cleaning up uploaded files: $e');
    }
  }
}