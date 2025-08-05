import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:educonnect/providers/auth_provider.dart';
import 'package:educonnect/repositories/user_repository.dart';
import 'package:educonnect/services/navigation_service.dart';
import 'package:educonnect/core/logger.dart';
import 'package:educonnect/core/result.dart';
import 'package:educonnect/modules/user.dart';

// Generate mocks
@GenerateMocks([UserRepository, NavigationService, Logger])
import 'auth_provider_test.mocks.dart';

void main() {
  group('AuthProvider Tests', () {
    late MockUserRepository mockUserRepository;
    late MockNavigationService mockNavigationService;
    late MockLogger mockLogger;
    late AuthProvider authProvider;

    setUp(() {
      mockUserRepository = MockUserRepository();
      mockNavigationService = MockNavigationService();
      mockLogger = MockLogger();
      
      authProvider = AuthProvider(
        userRepository: mockUserRepository,
        navigationService: mockNavigationService,
        logger: mockLogger,
      );
    });

    group('Initial State', () {
      test('should have correct initial state when not authenticated', () {
        expect(authProvider.state.userId, isNull);
        expect(authProvider.state.user, isNull);
        expect(authProvider.state.isLoading, isFalse);
        expect(authProvider.state.error, isNull);
        expect(authProvider.state.isAuthenticated, isFalse);
        expect(authProvider.state.hasError, isFalse);
        expect(authProvider.state.hasUser, isFalse);
      });
    });

    group('Login', () {
      test('should handle successful login', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password123';
        const userId = 'user123';
        
        final mockUser = User(
          id: userId,
          name: 'Test User',
          email: email,
          role: UserRole.student,
          createdAt: DateTime.now(),
        );

        when(mockUserRepository.getUserById(userId))
            .thenAnswer((_) async => Result.success(mockUser));

        // Act
        await authProvider.login(email, password);

        // Assert
        expect(authProvider.state.isLoading, isFalse);
        expect(authProvider.state.error, isNull);
        expect(authProvider.state.isAuthenticated, isTrue);
        expect(authProvider.state.userId, equals(userId));
        expect(authProvider.state.user, equals(mockUser));

        // Verify interactions
        verify(mockNavigationService.showInfoSnackBar('Logging in...')).called(1);
        verify(mockNavigationService.showSuccessSnackBar('Login successful!')).called(1);
        verify(mockUserRepository.getUserById(userId)).called(1);
      });

      test('should handle login failure', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'wrongpassword';

        // Act
        await authProvider.login(email, password);

        // Assert
        expect(authProvider.state.isLoading, isFalse);
        expect(authProvider.state.error, isNotNull);
        expect(authProvider.state.isAuthenticated, isFalse);
        expect(authProvider.state.userId, isNull);
        expect(authProvider.state.user, isNull);

        // Verify error handling
        verify(mockNavigationService.showErrorSnackBar(any)).called(1);
      });

      test('should handle user data loading failure after successful auth', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password123';
        const userId = 'user123';

        when(mockUserRepository.getUserById(userId))
            .thenAnswer((_) async => Result.error('User not found'));

        // Act
        await authProvider.login(email, password);

        // Assert
        expect(authProvider.state.isLoading, isFalse);
        expect(authProvider.state.error, contains('Failed to load user data'));
        expect(authProvider.state.user, isNull);

        // Verify error handling
        verify(mockNavigationService.showErrorSnackBar('Failed to load user data')).called(1);
      });
    });

    group('Signup', () {
      test('should handle successful signup', () async {
        // Arrange
        final user = User(
          id: '',
          name: 'Test User',
          email: 'test@example.com',
          role: UserRole.student,
          createdAt: DateTime.now(),
        );
        const password = 'password123';
        const userId = 'user123';
        
        final createdUser = user.copyWith(id: userId);

        when(mockUserRepository.createUser(any))
            .thenAnswer((_) async => Result.success(createdUser));

        // Act
        await authProvider.signup(user, password);

        // Assert
        expect(authProvider.state.isLoading, isFalse);
        expect(authProvider.state.error, isNull);
        expect(authProvider.state.isAuthenticated, isTrue);
        expect(authProvider.state.userId, equals(userId));
        expect(authProvider.state.user, equals(createdUser));

        // Verify interactions
        verify(mockNavigationService.showInfoSnackBar('Creating account...')).called(1);
        verify(mockNavigationService.showSuccessSnackBar('Account created successfully!')).called(1);
        verify(mockUserRepository.createUser(any)).called(1);
      });

      test('should handle signup failure', () async {
        // Arrange
        final user = User(
          id: '',
          name: 'Test User',
          email: 'invalid-email',
          role: UserRole.student,
          createdAt: DateTime.now(),
        );
        const password = 'password123';

        // Act
        await authProvider.signup(user, password);

        // Assert
        expect(authProvider.state.isLoading, isFalse);
        expect(authProvider.state.error, isNotNull);
        expect(authProvider.state.isAuthenticated, isFalse);
        expect(authProvider.state.userId, isNull);
        expect(authProvider.state.user, isNull);

        // Verify error handling
        verify(mockNavigationService.showErrorSnackBar(any)).called(1);
      });

      test('should handle user profile creation failure', () async {
        // Arrange
        final user = User(
          id: '',
          name: 'Test User',
          email: 'test@example.com',
          role: UserRole.student,
          createdAt: DateTime.now(),
        );
        const password = 'password123';

        when(mockUserRepository.createUser(any))
            .thenAnswer((_) async => Result.error('Failed to create profile'));

        // Act
        await authProvider.signup(user, password);

        // Assert
        expect(authProvider.state.isLoading, isFalse);
        expect(authProvider.state.error, contains('Failed to create user profile'));
        expect(authProvider.state.isAuthenticated, isFalse);

        // Verify error handling
        verify(mockNavigationService.showErrorSnackBar('Failed to create account')).called(1);
      });
    });

    group('Logout', () {
      test('should handle successful logout', () async {
        // Arrange - set up authenticated state
        authProvider.state = authProvider.state.copyWith(
          userId: 'user123',
          isAuthenticated: true,
        );

        // Act
        await authProvider.logout();

        // Assert
        expect(authProvider.state.userId, isNull);
        expect(authProvider.state.user, isNull);
        expect(authProvider.state.isAuthenticated, isFalse);
        expect(authProvider.state.error, isNull);

        // Verify interactions
        verify(mockNavigationService.showSuccessSnackBar('Logged out successfully!')).called(1);
      });
    });

    group('Error Messages', () {
      test('should return user-friendly error messages', () {
        expect(authProvider.getErrorMessage('user-not-found'), 
               equals('No account found with this email address'));
        expect(authProvider.getErrorMessage('wrong-password'), 
               equals('Incorrect password'));
        expect(authProvider.getErrorMessage('email-already-in-use'), 
               equals('An account already exists with this email address'));
        expect(authProvider.getErrorMessage('weak-password'), 
               equals('Password is too weak'));
        expect(authProvider.getErrorMessage('invalid-email'), 
               equals('Invalid email address'));
        expect(authProvider.getErrorMessage('network error'), 
               equals('Network error. Please check your connection'));
        expect(authProvider.getErrorMessage('unknown error'), 
               equals('An error occurred. Please try again'));
      });
    });

    group('Getters', () {
      test('should return correct authentication status', () {
        expect(authProvider.isAuthenticated, isFalse);
        
        authProvider.state = authProvider.state.copyWith(isAuthenticated: true);
        expect(authProvider.isAuthenticated, isTrue);
      });

      test('should return current user', () {
        expect(authProvider.currentUser, isNull);
        
        final user = User(
          id: 'user123',
          name: 'Test User',
          email: 'test@example.com',
          role: UserRole.student,
          createdAt: DateTime.now(),
        );
        
        authProvider.state = authProvider.state.copyWith(user: user);
        expect(authProvider.currentUser, equals(user));
      });

      test('should return current user ID', () {
        expect(authProvider.currentUserId, isNull);
        
        authProvider.state = authProvider.state.copyWith(userId: 'user123');
        expect(authProvider.currentUserId, equals('user123'));
      });
    });
  });

  group('AuthState Tests', () {
    test('should create state with correct defaults', () {
      const state = AuthState();
      expect(state.userId, isNull);
      expect(state.user, isNull);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.isAuthenticated, isFalse);
      expect(state.hasError, isFalse);
      expect(state.hasUser, isFalse);
    });

    test('should copy state correctly', () {
      final user = User(
        id: 'user123',
        name: 'Test User',
        email: 'test@example.com',
        role: UserRole.student,
        createdAt: DateTime.now(),
      );

      const originalState = AuthState(
        userId: 'user123',
        isLoading: true,
        error: 'test error',
        isAuthenticated: true,
      );

      final copiedState = originalState.copyWith(
        user: user,
        isLoading: false,
      );

      expect(copiedState.userId, equals('user123'));
      expect(copiedState.user, equals(user));
      expect(copiedState.isLoading, isFalse);
      expect(copiedState.error, equals('test error')); // Should preserve original error
      expect(copiedState.isAuthenticated, isTrue);
    });

    test('should clear error when specified', () {
      const originalState = AuthState(
        userId: 'user123',
        isAuthenticated: true,
        error: 'test error',
      );

      final copiedState = originalState.copyWith(clearError: true);

      expect(copiedState.userId, equals('user123'));
      expect(copiedState.isAuthenticated, isTrue);
      expect(copiedState.error, isNull);
      expect(copiedState.hasError, isFalse);
    });

    test('should clear user when specified', () {
      final user = User(
        id: 'user123',
        name: 'Test User',
        email: 'test@example.com',
        role: UserRole.student,
        createdAt: DateTime.now(),
      );

      final originalState = AuthState(
        userId: 'user123',
        user: user,
        isAuthenticated: true,
      );

      final copiedState = originalState.copyWith(clearUser: true);

      expect(copiedState.userId, isNull);
      expect(copiedState.user, isNull);
      expect(copiedState.hasUser, isFalse);
      expect(copiedState.isAuthenticated, isTrue); // Should preserve other fields
    });
  });
}