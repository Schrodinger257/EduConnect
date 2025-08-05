import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:educonnect/providers/profile_edit_provider.dart';
import 'package:educonnect/repositories/user_repository.dart';
import 'package:educonnect/services/navigation_service.dart';
import 'package:educonnect/services/image_service.dart';
import 'package:educonnect/core/logger.dart';
import 'package:educonnect/core/result.dart';
import 'package:educonnect/modules/user.dart';

import 'profile_edit_provider_test.mocks.dart';

@GenerateMocks([UserRepository, NavigationService, ImageService, Logger])
void main() {
  group('ProfileEditProvider Tests', () {
    late MockUserRepository mockUserRepository;
    late MockNavigationService mockNavigationService;
    late MockImageService mockImageService;
    late MockLogger mockLogger;
    late ProviderContainer container;

    setUp(() {
      mockUserRepository = MockUserRepository();
      mockNavigationService = MockNavigationService();
      mockImageService = MockImageService();
      mockLogger = MockLogger();

      container = ProviderContainer(
        overrides: [
          userRepositoryProvider.overrideWithValue(mockUserRepository),
          navigationServiceProvider.overrideWithValue(mockNavigationService),
          imageServiceProvider.overrideWithValue(mockImageService),
          loggerProvider.overrideWithValue(mockLogger),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    User createTestUser({UserRole role = UserRole.student}) {
      return User(
        id: 'test-id',
        email: 'test@example.com',
        name: 'Test User',
        role: role,
        createdAt: DateTime.now(),
      );
    }

    test('initial state is correct', () {
      final provider = container.read(profileEditProvider);
      
      expect(provider.isLoading, false);
      expect(provider.isUploadingImage, false);
      expect(provider.uploadProgress, null);
      expect(provider.error, null);
      expect(provider.isSuccess, false);
      expect(provider.hasError, false);
      expect(provider.isProcessing, false);
    });

    test('updateProfile updates user successfully without image', () async {
      final user = createTestUser();
      final updatedUser = user.copyWith(name: 'Updated Name');
      
      when(mockUserRepository.updateUser(any))
          .thenAnswer((_) async => Result.success(updatedUser));

      final notifier = container.read(profileEditProvider.notifier);
      await notifier.updateProfile(updatedUser);

      final state = container.read(profileEditProvider);
      expect(state.isLoading, false);
      expect(state.isSuccess, true);
      expect(state.hasError, false);

      verify(mockUserRepository.updateUser(updatedUser)).called(1);
      verify(mockNavigationService.showSuccessSnackBar('Profile updated successfully!')).called(1);
      verify(mockNavigationService.goBack(updatedUser)).called(1);
    });

    test('updateProfile handles validation errors', () async {
      final user = createTestUser().copyWith(name: ''); // Invalid name
      
      final notifier = container.read(profileEditProvider.notifier);
      await notifier.updateProfile(user);

      final state = container.read(profileEditProvider);
      expect(state.isLoading, false);
      expect(state.hasError, true);
      expect(state.error, contains('Name cannot be empty'));

      verifyNever(mockUserRepository.updateUser(any));
    });

    test('updateProfile handles repository errors', () async {
      final user = createTestUser();
      
      when(mockUserRepository.updateUser(any))
          .thenAnswer((_) async => Result.error('Database error'));

      final notifier = container.read(profileEditProvider.notifier);
      await notifier.updateProfile(user);

      final state = container.read(profileEditProvider);
      expect(state.isLoading, false);
      expect(state.hasError, true);
      expect(state.error, contains('Failed to update profile'));

      verify(mockNavigationService.showErrorSnackBar('Failed to update profile')).called(1);
    });

    test('validateProfileImage validates file correctly', () async {
      final mockFile = MockFile();
      when(mockFile.lengthSync()).thenReturn(1024 * 1024); // 1MB
      when(mockFile.path).thenReturn('/path/to/image.jpg');

      final notifier = container.read(profileEditProvider.notifier);
      final result = notifier.validateProfileImage(mockFile);

      expect(result.isSuccess, true);
    });

    test('validateProfileImage rejects oversized files', () async {
      final mockFile = MockFile();
      when(mockFile.lengthSync()).thenReturn(6 * 1024 * 1024); // 6MB
      when(mockFile.path).thenReturn('/path/to/image.jpg');

      final notifier = container.read(profileEditProvider.notifier);
      final result = notifier.validateProfileImage(mockFile);

      expect(result.isError, true);
      expect(result.errorMessage, contains('cannot exceed 5MB'));
    });

    test('validateProfileImage rejects invalid file types', () async {
      final mockFile = MockFile();
      when(mockFile.lengthSync()).thenReturn(1024 * 1024); // 1MB
      when(mockFile.path).thenReturn('/path/to/document.pdf');

      final notifier = container.read(profileEditProvider.notifier);
      final result = notifier.validateProfileImage(mockFile);

      expect(result.isError, true);
      expect(result.errorMessage, contains('Only JPG, JPEG, and PNG files are allowed'));
    });

    test('clearError clears error state', () async {
      final user = createTestUser().copyWith(name: ''); // Invalid to trigger error
      
      final notifier = container.read(profileEditProvider.notifier);
      await notifier.updateProfile(user);

      // Verify error state
      var state = container.read(profileEditProvider);
      expect(state.hasError, true);

      // Clear error
      notifier.clearError();

      // Verify error is cleared
      state = container.read(profileEditProvider);
      expect(state.hasError, false);
      expect(state.error, null);
    });

    test('reset resets provider state', () async {
      final user = createTestUser().copyWith(name: ''); // Invalid to trigger error
      
      final notifier = container.read(profileEditProvider.notifier);
      await notifier.updateProfile(user);

      // Verify error state
      var state = container.read(profileEditProvider);
      expect(state.hasError, true);

      // Reset state
      notifier.reset();

      // Verify state is reset
      state = container.read(profileEditProvider);
      expect(state.isLoading, false);
      expect(state.isUploadingImage, false);
      expect(state.uploadProgress, null);
      expect(state.error, null);
      expect(state.isSuccess, false);
    });

    group('Role-specific validation tests', () {
      test('validates instructor field of expertise requirement', () async {
        final instructor = createTestUser(role: UserRole.instructor)
            .copyWith(fieldOfExpertise: ''); // Empty field of expertise
        
        final notifier = container.read(profileEditProvider.notifier);
        await notifier.updateProfile(instructor);

        final state = container.read(profileEditProvider);
        expect(state.hasError, true);
        expect(state.error, contains('Field of expertise is required for instructors'));
      });

      test('validates student grade requirement', () async {
        final student = createTestUser(role: UserRole.student)
            .copyWith(grade: ''); // Empty grade
        
        final notifier = container.read(profileEditProvider.notifier);
        await notifier.updateProfile(student);

        final state = container.read(profileEditProvider);
        expect(state.hasError, true);
        expect(state.error, contains('Grade level is required for students'));
      });

      test('allows valid instructor profile', () async {
        final instructor = createTestUser(role: UserRole.instructor)
            .copyWith(
              fieldOfExpertise: 'Computer Science',
              department: 'Engineering',
            );
        
        when(mockUserRepository.updateUser(any))
            .thenAnswer((_) async => Result.success(instructor));

        final notifier = container.read(profileEditProvider.notifier);
        await notifier.updateProfile(instructor);

        final state = container.read(profileEditProvider);
        expect(state.hasError, false);
        expect(state.isSuccess, true);
      });

      test('allows valid student profile', () async {
        final student = createTestUser(role: UserRole.student)
            .copyWith(
              grade: '2nd Year',
              department: 'Computer Science',
            );
        
        when(mockUserRepository.updateUser(any))
            .thenAnswer((_) async => Result.success(student));

        final notifier = container.read(profileEditProvider.notifier);
        await notifier.updateProfile(student);

        final state = container.read(profileEditProvider);
        expect(state.hasError, false);
        expect(state.isSuccess, true);
      });

      test('allows valid admin profile', () async {
        final admin = createTestUser(role: UserRole.admin)
            .copyWith(department: 'IT Administration');
        
        when(mockUserRepository.updateUser(any))
            .thenAnswer((_) async => Result.success(admin));

        final notifier = container.read(profileEditProvider.notifier);
        await notifier.updateProfile(admin);

        final state = container.read(profileEditProvider);
        expect(state.hasError, false);
        expect(state.isSuccess, true);
      });
    });
  });
}

// Mock File class for testing
class MockFile extends Mock implements File {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) => 'MockFile';
}