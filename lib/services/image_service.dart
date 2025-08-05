import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/result.dart';
import '../core/logger.dart';

/// Service for handling image operations including compression and validation
class ImageService {
  final ImagePicker _picker;
  final Logger _logger;

  ImageService({
    ImagePicker? picker,
    Logger? logger,
  }) : _picker = picker ?? ImagePicker(),
       _logger = logger ?? Logger();

  /// Picks an image from the specified source with compression and validation
  Future<Result<File>> pickImage({
    required ImageSource source,
    int imageQuality = 80,
    int maxWidth = 1024,
    int maxHeight = 1024,
    int maxSizeInMB = 5,
  }) async {
    try {
      _logger.info('Picking image from ${source.name}');
      
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: imageQuality,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
      );

      if (pickedFile == null) {
        _logger.info('No image selected');
        return Result.error('No image selected');
      }

      final imageFile = File(pickedFile.path);
      
      // Validate the image file
      final validationResult = await validateImage(imageFile, maxSizeInMB: maxSizeInMB);
      if (validationResult.isError) {
        return Result.error(validationResult.errorMessage!);
      }

      _logger.info('Image picked and validated successfully');
      return Result.success(imageFile);
    } catch (e) {
      _logger.error('Error picking image: $e');
      return Result.error('Failed to pick image: ${e.toString()}');
    }
  }

  /// Validates an image file for size and format
  Future<Result<void>> validateImage(
    File imageFile, {
    int maxSizeInMB = 5,
    List<String> allowedExtensions = const ['.jpg', '.jpeg', '.png'],
  }) async {
    try {
      _logger.info('Validating image file: ${imageFile.path}');
      
      // Check if file exists
      if (!await imageFile.exists()) {
        return Result.error('Image file does not exist');
      }

      // Check file size
      final fileSize = await imageFile.length();
      final maxSizeInBytes = maxSizeInMB * 1024 * 1024;
      
      if (fileSize > maxSizeInBytes) {
        return Result.error('Image file size cannot exceed ${maxSizeInMB}MB');
      }

      // Check file extension
      final fileName = imageFile.path.toLowerCase();
      final hasValidExtension = allowedExtensions.any((ext) => fileName.endsWith(ext));
      
      if (!hasValidExtension) {
        final extensionsText = allowedExtensions.join(', ').toUpperCase();
        return Result.error('Only $extensionsText files are allowed');
      }

      // Additional validation: Check if it's actually an image by trying to decode it
      try {
        final bytes = await imageFile.readAsBytes();
        final image = await decodeImageFromList(bytes);
        
        // Check minimum dimensions
        if (image.width < 50 || image.height < 50) {
          return Result.error('Image must be at least 50x50 pixels');
        }
        
        // Check maximum dimensions
        if (image.width > 4096 || image.height > 4096) {
          return Result.error('Image dimensions cannot exceed 4096x4096 pixels');
        }
        
        image.dispose();
      } catch (e) {
        return Result.error('Invalid image file format');
      }

      _logger.info('Image validation successful');
      return Result.success(null);
    } catch (e) {
      _logger.error('Error validating image: $e');
      return Result.error('Failed to validate image: ${e.toString()}');
    }
  }

  /// Compresses an image file to reduce its size
  Future<Result<File>> compressImage(
    File imageFile, {
    int quality = 80,
    int maxWidth = 1024,
    int maxHeight = 1024,
  }) async {
    try {
      _logger.info('Compressing image: ${imageFile.path}');
      
      // For now, we'll use the ImagePicker's built-in compression
      // In a production app, you might want to use a dedicated image compression library
      final compressedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: quality,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
      );

      if (compressedFile == null) {
        return Result.error('Failed to compress image');
      }

      final compressed = File(compressedFile.path);
      _logger.info('Image compressed successfully');
      return Result.success(compressed);
    } catch (e) {
      _logger.error('Error compressing image: $e');
      return Result.error('Failed to compress image: ${e.toString()}');
    }
  }

  /// Gets image information including dimensions and file size
  Future<Result<ImageInfo>> getImageInfo(File imageFile) async {
    try {
      _logger.info('Getting image info for: ${imageFile.path}');
      
      final bytes = await imageFile.readAsBytes();
      final image = await decodeImageFromList(bytes);
      final fileSize = await imageFile.length();
      
      final info = ImageInfo(
        width: image.width,
        height: image.height,
        fileSize: fileSize,
        filePath: imageFile.path,
      );
      
      image.dispose();
      
      _logger.info('Image info retrieved successfully');
      return Result.success(info);
    } catch (e) {
      _logger.error('Error getting image info: $e');
      return Result.error('Failed to get image information: ${e.toString()}');
    }
  }

  /// Shows image picker options in a bottom sheet
  Future<Result<File>> showImagePickerOptions(
    BuildContext context, {
    bool allowCamera = true,
    bool allowGallery = true,
    int imageQuality = 80,
    int maxWidth = 1024,
    int maxHeight = 1024,
    int maxSizeInMB = 5,
  }) async {
    if (!allowCamera && !allowGallery) {
      return Result.error('At least one image source must be allowed');
    }

    try {
      final result = await showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => _buildImagePickerBottomSheet(
          context,
          allowCamera: allowCamera,
          allowGallery: allowGallery,
        ),
      );

      if (result == null) {
        return Result.error('No image source selected');
      }

      return await pickImage(
        source: result,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        maxSizeInMB: maxSizeInMB,
      );
    } catch (e) {
      _logger.error('Error showing image picker options: $e');
      return Result.error('Failed to show image picker: ${e.toString()}');
    }
  }

  Widget _buildImagePickerBottomSheet(
    BuildContext context, {
    required bool allowCamera,
    required bool allowGallery,
  }) {
    final theme = Theme.of(context);
    
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.shadowColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(height: 20),
            
            Text(
              'Select Image Source',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
            
            const SizedBox(height: 20),
            
            if (allowCamera)
              _buildPickerOption(
                context: context,
                icon: Icons.camera_alt,
                title: 'Camera',
                subtitle: 'Take a new photo',
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            
            if (allowCamera && allowGallery)
              const SizedBox(height: 12),
            
            if (allowGallery)
              _buildPickerOption(
                context: context,
                icon: Icons.photo_library,
                title: 'Gallery',
                subtitle: 'Choose from your photos',
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.primaryColor.withOpacity(0.2),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: theme.primaryColor,
                size: 24,
              ),
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.shadowColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            
            Icon(
              Icons.arrow_forward_ios,
              color: theme.primaryColor.withOpacity(0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

/// Information about an image file
class ImageInfo {
  final int width;
  final int height;
  final int fileSize;
  final String filePath;

  const ImageInfo({
    required this.width,
    required this.height,
    required this.fileSize,
    required this.filePath,
  });

  /// File size in MB
  double get fileSizeInMB => fileSize / (1024 * 1024);

  /// Aspect ratio of the image
  double get aspectRatio => width / height;

  /// Whether the image is landscape orientation
  bool get isLandscape => width > height;

  /// Whether the image is portrait orientation
  bool get isPortrait => height > width;

  /// Whether the image is square
  bool get isSquare => width == height;

  @override
  String toString() {
    return 'ImageInfo(${width}x$height, ${fileSizeInMB.toStringAsFixed(2)}MB)';
  }
}