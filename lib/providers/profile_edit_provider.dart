import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/result.dart';
import '../core/logger.dart';
import '../modules/user.dart';
import '../repositories/user_repository.dart';
import '../services/navigation_service.dart';
import '../services/image_service.dart';
import '../widgets/upload_progress_dialog.dart';
import 'providers.dart';

/// State for profile editing operations
class ProfileEditState {
  final bool isLoading;
  final bool isUploadingImage;
  final double? uploadProgress;
  final String? error;
  final bool isSuccess;

  const ProfileEditState({
    this.isLoading = false,
    this.isUploadingImage = false,
    this.uploadProgress,
    this.error,
    this.isSuccess = false,
  });

  ProfileEditState copyWith({
    bool? isLoading,
    bool? isUploadingImage,
    double? uploadProgress,
    String? error,
    bool? isSuccess,
    bool clearError = false,
    bool clearProgress = false,
  }) {
    return ProfileEditState(
      isLoading: isLoading ?? this.isLoading,
      isUploadingImage: isUploadingImage ?? this.isUploadingImage,
      uploadProgress: clearProgress ? null : (uploadProgress ?? this.uploadProgress),
      error: clearError ? null : (error ?? this.error),
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }

  bool get hasError => error != null;
  bool get isProcessing => isLoading || isUploadingImage;
}

/// Provider for managing profile editing operations
class ProfileEditProvider extends StateNotifier<ProfileEditState> {
  final UserRepository _userRepository;
  final NavigationService _navigationService;
  final ImageService _imageService;
  final Logger _logger;
  final UploadProgressController _uploadController = UploadProgressController();

  ProfileEditProvider({
    required UserRepository userRepository,
    required NavigationService navigationService,
    required ImageService imageService,
    required Logger logger,
  }) : _userRepository = userRepository,
       _navigationService = navigationService,
       _imageService = imageService,
       _logger = logger,
       super(const ProfileEditState());

  /// Updates user profile with optional image upload
  Future<void> updateProfile(
    User user, {
    File? profileImage,
    BuildContext? context,
  }) async {
    try {
      _logger.info('Updating profile for user: ${user.id}');
      state = state.copyWith(isLoading: true, clearError: true);

      User updatedUser = user;

      // Upload profile image if provided
      if (profileImage != null) {
        updatedUser = await _uploadProfileImageWithProgress(
          user,
          profileImage,
          context,
        );
        if (state.hasError) return; // Exit if image upload failed
      }

      // Validate user data
      final validationResult = User.validate(
        id: updatedUser.id,
        email: updatedUser.email,
        name: updatedUser.name,
        role: updatedUser.role,
        profileImage: updatedUser.profileImage,
        department: updatedUser.department,
        fieldOfExpertise: updatedUser.fieldOfExpertise,
        grade: updatedUser.grade,
        createdAt: updatedUser.createdAt,
        bookmarks: updatedUser.bookmarks,
        likedPosts: updatedUser.likedPosts,
        enrolledCourses: updatedUser.enrolledCourses,
      );

      if (validationResult.isError) {
        _logger.warning('Profile validation failed: ${validationResult.errorMessage}');
        state = state.copyWith(
          isLoading: false,
          error: validationResult.errorMessage,
        );
        return;
      }

      // Update user profile
      final updateResult = await _userRepository.updateUser(updatedUser);

      updateResult.when(
        success: (user) {
          _logger.info('Profile updated successfully for user: ${user.id}');
          state = state.copyWith(
            isLoading: false,
            isSuccess: true,
          );
          
          _navigationService.showSuccessSnackBar('Profile updated successfully!');
          _navigationService.goBack(user);
        },
        error: (message, exception) {
          _logger.error('Failed to update profile: $message', exception);
          state = state.copyWith(
            isLoading: false,
            error: 'Failed to update profile: $message',
          );
          _navigationService.showErrorSnackBar('Failed to update profile');
        },
      );
    } catch (e) {
      _logger.error('Unexpected error updating profile: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
      _navigationService.showErrorSnackBar('An unexpected error occurred');
    }
  }

  /// Uploads profile image with progress tracking and retry functionality
  Future<User> _uploadProfileImageWithProgress(
    User user,
    File profileImage,
    BuildContext? context,
  ) async {
    _logger.info('Uploading profile image with progress for user: ${user.id}');
    
    state = state.copyWith(
      isUploadingImage: true,
      uploadProgress: 0.0,
    );

    // Show progress dialog if context is available
    if (context != null) {
      _uploadController.show(
        context,
        message: 'Uploading profile image...',
        canCancel: false,
      );
    }

    try {
      // Validate image before upload
      final validationResult = await _imageService.validateImage(profileImage);
      if (validationResult.isError) {
        throw Exception(validationResult.errorMessage);
      }

      // Simulate progress updates (in a real implementation, this would come from the upload service)
      for (int i = 1; i <= 5; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        final progress = i / 10.0; // 0.1 to 0.5
        state = state.copyWith(uploadProgress: progress);
        _uploadController.updateProgress(progress);
      }

      // Perform the actual upload
      final imageResult = await _userRepository.uploadProfileImage(
        profileImage,
        user.id,
      );

      // Complete progress
      state = state.copyWith(uploadProgress: 1.0);
      _uploadController.updateProgress(1.0);

      await Future.delayed(const Duration(milliseconds: 300));

      return await imageResult.when(
        success: (imageUrl) {
          _logger.info('Profile image uploaded successfully: $imageUrl');
          state = state.copyWith(
            isUploadingImage: false,
            clearProgress: true,
          );
          
          _uploadController.hide();
          return user.copyWith(profileImage: imageUrl);
        },
        error: (message, exception) {
          _logger.error('Failed to upload profile image: $message', exception);
          
          state = state.copyWith(
            isLoading: false,
            isUploadingImage: false,
            clearProgress: true,
            error: 'Failed to upload profile image: $message',
          );

          if (context != null) {
            _uploadController.showError(
              'Failed to upload image: $message',
              onRetry: () {
                _uploadController.hide();
                // Retry the upload
                updateProfile(user, profileImage: profileImage, context: context);
              },
            );
          }
          
          throw Exception(message);
        },
      );
    } catch (e) {
      _logger.error('Error during image upload: $e');
      
      state = state.copyWith(
        isLoading: false,
        isUploadingImage: false,
        clearProgress: true,
        error: 'Failed to upload image: ${e.toString()}',
      );

      if (context != null) {
        _uploadController.showError(
          'Failed to upload image: ${e.toString()}',
          onRetry: () {
            _uploadController.hide();
            updateProfile(user, profileImage: profileImage, context: context);
          },
        );
      }
      
      throw e;
    }
  }

  /// Picks and validates an image from the specified source
  Future<Result<File>> pickImage(
    BuildContext context, {
    ImageSource? source,
    int imageQuality = 80,
    int maxWidth = 1024,
    int maxHeight = 1024,
    int maxSizeInMB = 5,
  }) async {
    try {
      if (source != null) {
        return await _imageService.pickImage(
          source: source,
          imageQuality: imageQuality,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          maxSizeInMB: maxSizeInMB,
        );
      } else {
        return await _imageService.showImagePickerOptions(
          context,
          imageQuality: imageQuality,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          maxSizeInMB: maxSizeInMB,
        );
      }
    } catch (e) {
      _logger.error('Error picking image: $e');
      return Result.error('Failed to pick image: ${e.toString()}');
    }
  }

  /// Validates profile image file
  Result<void> validateProfileImage(File image) {
    try {
      // Check file size (max 5MB)
      final fileSize = image.lengthSync();
      if (fileSize > 5 * 1024 * 1024) {
        return Result.error('Image file size cannot exceed 5MB');
      }

      // Check file extension
      final fileName = image.path.toLowerCase();
      final validExtensions = ['.jpg', '.jpeg', '.png'];
      final hasValidExtension = validExtensions.any((ext) => fileName.endsWith(ext));
      
      if (!hasValidExtension) {
        return Result.error('Only JPG, JPEG, and PNG files are allowed');
      }

      return Result.success(null);
    } catch (e) {
      return Result.error('Failed to validate image file');
    }
  }

  /// Clears the current error state
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Resets the provider state
  void reset() {
    state = const ProfileEditState();
  }
}

// Image service provider
final imageServiceProvider = Provider<ImageService>((ref) {
  return ImageService(logger: ref.read(loggerProvider));
});

final profileEditProvider = StateNotifierProvider<ProfileEditProvider, ProfileEditState>((ref) {
  return ProfileEditProvider(
    userRepository: ref.read(userRepositoryProvider),
    navigationService: ref.read(navigationServiceProvider),
    imageService: ref.read(imageServiceProvider),
    logger: ref.read(loggerProvider),
  );
});