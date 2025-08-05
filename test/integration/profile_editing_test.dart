import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:educonnect/screens/profile_edit_screen.dart';
import 'package:educonnect/modules/user.dart';
import 'package:educonnect/repositories/user_repository.dart';
import 'package:educonnect/services/navigation_service.dart';
import 'package:educonnect/services/image_service.dart';
import 'package:educonnect/core/logger.dart';
import 'package:educonnect/core/result.dart';
import 'package:educonnect/providers/providers.dart';

import '../providers/profile_edit_provider_test.mocks.dart';

@GenerateMocks([UserRepository, NavigationService, ImageService, Logger])
void main() {
  group('Profile Editing Integration Tests', () {
    late MockUserRepository mockUserRepository;
    late MockNavigationService mockNavigationService;
    late MockImageService mockImageService;
    late MockLogger mockLogger;

    setUp(() {
      mockUserRepository = MockUserRepository();
      mockNavigationService = MockNavigationService();
      mockImageService = MockImageService();
      mockLogger = MockLogger();
    });

    Widget createApp(User user) {
      return ProviderScope(
        overrides: [
          userRepositoryProvider.overrideWithValue(mockUserRepository),
          navigationServiceProvider.overrideWithValue(mockNavigationService),
          imageServiceProvider.overrideWithValue(mockImageService),
          loggerProvider.overrideWithValue(mockLogger),
        ],
        child: MaterialApp(
          home: ProfileEditScreen(user: user),
        ),
      );
    }

    User createTestUser({UserRole role = UserRole.student}) {
      return User(
        id: 'test-id',
        email: 'test@example.com',
        name: 'Test User',
        role: role,
        createdAt: DateTime.now(),
        department: role == UserRole.student ? 'Computer Science' : null,
        grade: role == UserRole.student ? '2nd Year' : null,
        fieldOfExpertise: role == UserRole.instructor ? 'Machine Learning' : null,
      );
    }

    testWidgets('student can edit profile with role-specific fields', (tester) async {
      final student = createTestUser(role: UserRole.student);
      
      when(mockUserRepository.updateUser(any))
          .thenAnswer((_) async => Result.success(student));

      await tester.pumpWidget(createApp(student));
      await tester.pumpAndSettle();

      // Verify student-specific fields are present
      expect(find.text('Department'), findsOneWidget);
      expect(find.text('Grade Level'), findsOneWidget);
      expect(find.text('Field of Expertise'), findsNothing);

      // Edit the name
      final nameField = find.widgetWithText(TextFormField, 'Test User');
      await tester.enterText(nameField, 'Updated Student Name');

      // Change department
      final departmentField = find.ancestor(
        of: find.text('Department'),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(departmentField, 'Mathematics');

      // Change grade
      final gradeDropdown = find.byType(DropdownButtonFormField<String>);
      await tester.tap(gradeDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('3rd Year'));
      await tester.pumpAndSettle();

      // Save changes
      final saveButton = find.text('Save');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Verify the update was called with correct data
      verify(mockUserRepository.updateUser(argThat(
        predicate<User>((user) =>
          user.name == 'Updated Student Name' &&
          user.department == 'Mathematics' &&
          user.grade == '3rd Year' &&
          user.role == UserRole.student
        )
      ))).called(1);
    });

    testWidgets('instructor can edit profile with role-specific fields', (tester) async {
      final instructor = createTestUser(role: UserRole.instructor);
      
      when(mockUserRepository.updateUser(any))
          .thenAnswer((_) async => Result.success(instructor));

      await tester.pumpWidget(createApp(instructor));
      await tester.pumpAndSettle();

      // Verify instructor-specific fields are present
      expect(find.text('Field of Expertise'), findsOneWidget);
      expect(find.text('Department'), findsOneWidget);
      expect(find.text('Grade Level'), findsNothing);

      // Edit the field of expertise
      final expertiseField = find.ancestor(
        of: find.text('Field of Expertise'),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(expertiseField, 'Deep Learning');

      // Edit department
      final departmentField = find.ancestor(
        of: find.text('Department'),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(departmentField, 'AI Research');

      // Save changes
      final saveButton = find.text('Save');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Verify the update was called with correct data
      verify(mockUserRepository.updateUser(argThat(
        predicate<User>((user) =>
          user.fieldOfExpertise == 'Deep Learning' &&
          user.department == 'AI Research' &&
          user.role == UserRole.instructor
        )
      ))).called(1);
    });

    testWidgets('admin can edit profile with role-specific fields', (tester) async {
      final admin = createTestUser(role: UserRole.admin);
      
      when(mockUserRepository.updateUser(any))
          .thenAnswer((_) async => Result.success(admin));

      await tester.pumpWidget(createApp(admin));
      await tester.pumpAndSettle();

      // Verify admin-specific fields are present
      expect(find.text('Department/Division'), findsOneWidget);
      expect(find.text('Field of Expertise'), findsNothing);
      expect(find.text('Grade Level'), findsNothing);

      // Edit department/division
      final departmentField = find.ancestor(
        of: find.text('Department/Division'),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(departmentField, 'System Administration');

      // Save changes
      final saveButton = find.text('Save');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Verify the update was called with correct data
      verify(mockUserRepository.updateUser(argThat(
        predicate<User>((user) =>
          user.department == 'System Administration' &&
          user.role == UserRole.admin
        )
      ))).called(1);
    });

    testWidgets('shows validation errors for required fields', (tester) async {
      final instructor = createTestUser(role: UserRole.instructor);
      
      await tester.pumpWidget(createApp(instructor));
      await tester.pumpAndSettle();

      // Clear the required field of expertise
      final expertiseField = find.ancestor(
        of: find.text('Field of Expertise'),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(expertiseField, '');

      // Try to save
      final saveButton = find.text('Save');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Field of expertise is required for instructors'), findsOneWidget);
      
      // Should not call repository update
      verifyNever(mockUserRepository.updateUser(any));
    });

    testWidgets('displays role information correctly', (tester) async {
      final student = createTestUser(role: UserRole.student);
      
      await tester.pumpWidget(createApp(student));
      await tester.pumpAndSettle();

      // Should show role information section
      expect(find.text('Role Information'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      
      // Should show student-specific description
      expect(find.textContaining('As a student'), findsOneWidget);
      expect(find.textContaining('enroll in courses'), findsOneWidget);
    });

    testWidgets('handles repository errors gracefully', (tester) async {
      final student = createTestUser(role: UserRole.student);
      
      when(mockUserRepository.updateUser(any))
          .thenAnswer((_) async => Result.error('Network error'));

      await tester.pumpWidget(createApp(student));
      await tester.pumpAndSettle();

      // Make a change and save
      final nameField = find.widgetWithText(TextFormField, 'Test User');
      await tester.enterText(nameField, 'Updated Name');

      final saveButton = find.text('Save');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Should show error message
      expect(find.textContaining('Failed to update profile'), findsOneWidget);
      
      // Should call error snackbar
      verify(mockNavigationService.showErrorSnackBar('Failed to update profile')).called(1);
    });

    testWidgets('shows loading state during save', (tester) async {
      final student = createTestUser(role: UserRole.student);
      
      // Make the repository call take some time
      when(mockUserRepository.updateUser(any))
          .thenAnswer((_) async {
            await Future.delayed(const Duration(milliseconds: 100));
            return Result.success(student);
          });

      await tester.pumpWidget(createApp(student));
      await tester.pumpAndSettle();

      // Make a change
      final nameField = find.widgetWithText(TextFormField, 'Test User');
      await tester.enterText(nameField, 'Updated Name');

      // Tap save button
      final saveButton = find.text('Save');
      await tester.tap(saveButton);
      
      // Should show loading state immediately
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      
      // Wait for completion
      await tester.pumpAndSettle();
      
      // Loading should be gone
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}