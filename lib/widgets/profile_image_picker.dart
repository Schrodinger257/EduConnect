import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Widget for selecting and displaying profile images
class ProfileImagePicker extends StatelessWidget {
  final String? currentImageUrl;
  final File? selectedImage;
  final Function(File?) onImageSelected;
  final bool isLoading;

  const ProfileImagePicker({
    super.key,
    this.currentImageUrl,
    this.selectedImage,
    required this.onImageSelected,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final imageSize = size.width * 0.3;

    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              // Profile Image
              Container(
                width: imageSize,
                height: imageSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.primaryColor,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _buildImageWidget(imageSize),
                ),
              ),
              
              // Loading Overlay
              if (isLoading)
                Container(
                  width: imageSize,
                  height: imageSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.5),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              
              // Edit Button
              if (!isLoading)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => _showImagePickerOptions(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.scaffoldBackgroundColor,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.shadowColor.withOpacity(0.3),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Image Info Text
          Text(
            selectedImage != null 
                ? 'New image selected' 
                : 'Tap camera icon to change photo',
            style: TextStyle(
              color: theme.shadowColor.withOpacity(0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildImageWidget(double size) {
    if (selectedImage != null) {
      return Image.file(
        selectedImage!,
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    } else if (currentImageUrl != null && 
               currentImageUrl != 'default_avatar' && 
               currentImageUrl!.isNotEmpty) {
      return Image.network(
        currentImageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultAvatar(size);
        },
      );
    } else {
      return _buildDefaultAvatar(size);
    }
  }

  Widget _buildDefaultAvatar(double size) {
    return Image.asset(
      'assets/images/default_avatar.png',
      width: size,
      height: size,
      fit: BoxFit.cover,
    );
  }

  void _showImagePickerOptions(BuildContext context) {
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
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
                'Select Profile Photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Camera Option
              _buildPickerOption(
                context: context,
                icon: Icons.camera_alt,
                title: 'Take Photo',
                subtitle: 'Use camera to take a new photo',
                onTap: () => _pickImage(context, ImageSource.camera),
              ),
              
              const SizedBox(height: 12),
              
              // Gallery Option
              _buildPickerOption(
                context: context,
                icon: Icons.photo_library,
                title: 'Choose from Gallery',
                subtitle: 'Select from your photo library',
                onTap: () => _pickImage(context, ImageSource.gallery),
              ),
              
              // Remove Photo Option (if there's a current image)
              if (currentImageUrl != null && 
                  currentImageUrl != 'default_avatar' && 
                  currentImageUrl!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildPickerOption(
                  context: context,
                  icon: Icons.delete,
                  title: 'Remove Photo',
                  subtitle: 'Use default avatar',
                  onTap: () {
                    Navigator.pop(context);
                    onImageSelected(null);
                  },
                  isDestructive: true,
                ),
              ],
              
              const SizedBox(height: 20),
            ],
          ),
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
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final color = isDestructive ? Colors.red : theme.primaryColor;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: color.withOpacity(0.2),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
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
                      color: color,
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
              color: color.withOpacity(0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    Navigator.pop(context);
    
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile != null) {
        final imageFile = File(pickedFile.path);
        
        // Validate image file
        final fileSize = await imageFile.length();
        if (fileSize > 5 * 1024 * 1024) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image file size cannot exceed 5MB'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        
        onImageSelected(imageFile);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}