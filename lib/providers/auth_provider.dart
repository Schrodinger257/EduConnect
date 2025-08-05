import 'package:educonnect/modules/user.dart';
import 'package:educonnect/repositories/user_repository.dart';
import 'package:educonnect/screens/auth_screen.dart';
import 'package:educonnect/screens/main_screen.dart';
import 'package:educonnect/services/navigation_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/result.dart';
import '../core/logger.dart';

/// State class for role selection during registration
class RoleState {
  final UserRole? selectedRole;
  final bool isValid;
  final String? error;

  const RoleState({
    this.selectedRole,
    this.isValid = false,
    this.error,
  });

  RoleState copyWith({
    UserRole? selectedRole,
    bool? isValid,
    String? error,
    bool clearError = false,
  }) {
    return RoleState(
      selectedRole: selectedRole ?? this.selectedRole,
      isValid: isValid ?? this.isValid,
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get hasError => error != null;
  bool get isStudent => selectedRole == UserRole.student;
  bool get isInstructor => selectedRole == UserRole.instructor;
  bool get isAdmin => selectedRole == UserRole.admin;
}

/// Provider for managing role selection during user registration
class RoleProvider extends StateNotifier<RoleState> {
  final Logger _logger;

  RoleProvider({Logger? logger}) 
      : _logger = logger ?? Logger(),
        super(const RoleState());

  /// Selects a role and validates the selection
  void selectRole(UserRole role) {
    try {
      _logger.info('Selecting role: ${role.value}');
      
      final validationResult = _validateRoleSelection(role);
      
      if (validationResult.isSuccess) {
        state = state.copyWith(
          selectedRole: role,
          isValid: true,
          clearError: true,
        );
        _logger.info('Role selected successfully: ${role.value}');
      } else {
        state = state.copyWith(
          error: validationResult.errorMessage,
          isValid: false,
        );
        _logger.warning('Role selection validation failed: ${validationResult.errorMessage}');
      }
    } catch (e) {
      _logger.error('Error selecting role: $e');
      state = state.copyWith(
        error: 'An unexpected error occurred',
        isValid: false,
      );
    }
  }

  /// Clears the current role selection
  void clearRole() {
    _logger.info('Clearing role selection');
    state = const RoleState();
  }

  /// Validates role selection
  Result<void> _validateRoleSelection(UserRole role) {
    // Basic validation - ensure role is valid
    if (!UserRole.values.contains(role)) {
      return Result.error('Invalid role selected');
    }

    // Additional validation can be added here
    // For example, checking if certain roles are allowed for registration
    
    return Result.success(null);
  }

  /// Checks if the current user can select a specific role
  bool canSelectRole(UserRole role) {
    // Add any business logic for role selection permissions
    // For now, all roles are selectable during registration
    return true;
  }

  /// Gets the display name for the selected role
  String? get selectedRoleDisplayName {
    return state.selectedRole?.displayName;
  }

  /// Gets all available roles for selection
  List<UserRole> get availableRoles {
    return UserRole.values.where((role) => canSelectRole(role)).toList();
  }
}

final roleProvider = StateNotifierProvider<RoleProvider, RoleState>((ref) {
  return RoleProvider(logger: Logger());
});

/// State for managing authentication screen UI
class AuthScreenState {
  final bool isLoginMode;
  final bool isLoading;
  final String? error;

  const AuthScreenState({
    this.isLoginMode = true,
    this.isLoading = false,
    this.error,
  });

  AuthScreenState copyWith({
    bool? isLoginMode,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AuthScreenState(
      isLoginMode: isLoginMode ?? this.isLoginMode,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get hasError => error != null;
  bool get isSignupMode => !isLoginMode;
}

/// Provider for managing authentication screen state
class AuthScreenProvider extends StateNotifier<AuthScreenState> {
  final Logger _logger;

  AuthScreenProvider({Logger? logger}) 
      : _logger = logger ?? Logger(),
        super(const AuthScreenState());

  /// Toggles between login and signup modes
  void toggleAuthMode() {
    _logger.info('Toggling auth mode from ${state.isLoginMode ? 'login' : 'signup'} to ${state.isLoginMode ? 'signup' : 'login'}');
    state = state.copyWith(
      isLoginMode: !state.isLoginMode,
      clearError: true,
    );
  }

  /// Sets the authentication mode explicitly
  void setAuthMode(bool isLoginMode) {
    _logger.info('Setting auth mode to ${isLoginMode ? 'login' : 'signup'}');
    state = state.copyWith(
      isLoginMode: isLoginMode,
      clearError: true,
    );
  }

  /// Sets loading state
  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  /// Sets error state
  void setError(String error) {
    _logger.warning('Auth screen error: $error');
    state = state.copyWith(error: error, isLoading: false);
  }

  /// Clears error state
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final authScreenProvider = StateNotifierProvider<AuthScreenProvider, AuthScreenState>((ref) {
  return AuthScreenProvider(logger: Logger());
});

/// State for authentication management
class AuthState {
  final String userId;
  final User user;
  final bool isLoading;
  final String error;
  final bool isAuthenticated;

  const AuthState({
    required this.userId,
    required this.user,
    this.isLoading = false,
    this.error = '',
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    String? userId,
    User? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      userId: clearUser ? null : (userId ?? this.userId),
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }

  bool get hasError => error != null;
  bool get hasUser => user != null;
}

/// Provider for managing authentication state and operations
class AuthProvider extends StateNotifier<AuthState> {
  final UserRepository _userRepository;
  final NavigationService _navigationService;
  final Logger _logger;

  AuthProvider({
    required UserRepository userRepository,
    required NavigationService navigationService,
    required Logger logger,
  }) : _userRepository = userRepository,
       _navigationService = navigationService,
       _logger = logger,
       super(AuthState(
         userId: FirebaseAuth.instance.currentUser?.uid,
         isAuthenticated: FirebaseAuth.instance.currentUser != null,
       )) {
    // Initialize user data if already authenticated
    _initializeUser();
  }

  /// Initialize user data on startup if already authenticated
  Future<void> _initializeUser() async {
    if (state.userId != null && !state.hasUser) {
      await _loadUserData(state.userId!);
    }
  }

  /// Load user data from repository
  Future<void> _loadUserData(String userId) async {
    try {
      final result = await _userRepository.getUserById(userId);
      result.when(
        success: (user) {
          state = state.copyWith(user: user);
        },
        error: (message, exception) {
          _logger.error('Error loading user data: $message', exception);
        },
      );
    } catch (e) {
      _logger.error('Unexpected error loading user data: $e');
    }
  }

  /// Login with email and password
  Future<void> login(String email, String password) async {
    try {
      _logger.info('Attempting login for email: $email');
      state = state.copyWith(isLoading: true, clearError: true);
      
      _navigationService.showInfoSnackBar('Logging in...');

      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      if (userCredential.user == null) {
        throw Exception('Login failed: No user returned');
      }

      final userId = userCredential.user!.uid;
      _logger.info('Login successful for user: $userId');

      // Load user data
      final userResult = await _userRepository.getUserById(userId);
      
      userResult.when(
        success: (user) {
          state = state.copyWith(
            userId: userId,
            user: user,
            isLoading: false,
            isAuthenticated: true,
          );
          
          _navigationService.showSuccessSnackBar('Login successful!');
          _navigationService.navigateAndReplace(MainScreen());
        },
        error: (message, exception) {
          _logger.error('Error loading user data after login: $message', exception);
          state = state.copyWith(
            isLoading: false,
            error: 'Failed to load user data: $message',
          );
          _navigationService.showErrorSnackBar('Failed to load user data');
        },
      );
    } catch (e) {
      _logger.error('Login error: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      _navigationService.showErrorSnackBar(getErrorMessage(e));
    }
  }

  /// Sign up with user information
  Future<void> signup(User user, String password) async {
    try {
      _logger.info('Attempting signup for email: ${user.email}');
      state = state.copyWith(isLoading: true, clearError: true);
      
      _navigationService.showInfoSnackBar('Creating account...');

      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: user.email,
            password: password,
          );

      if (userCredential.user == null) {
        throw Exception('Signup failed: No user returned');
      }

      final userId = userCredential.user!.uid;
      _logger.info('Signup successful for user: $userId');

      // Create user profile with the generated ID
      final newUser = user.copyWith(id: userId);
      final createResult = await _userRepository.createUser(newUser);
      
      createResult.when(
        success: (createdUser) {
          state = state.copyWith(
            userId: userId,
            user: createdUser,
            isLoading: false,
            isAuthenticated: true,
          );
          
          _navigationService.showSuccessSnackBar('Account created successfully!');
          _navigationService.navigateAndReplace(MainScreen());
        },
        error: (message, exception) {
          _logger.error('Error creating user profile: $message', exception);
          
          // Clean up Firebase Auth user if profile creation failed
          try {
            await FirebaseAuth.instance.currentUser?.delete();
          } catch (deleteError) {
            _logger.error('Error deleting Firebase Auth user: $deleteError');
          }
          
          state = state.copyWith(
            isLoading: false,
            error: 'Failed to create user profile: $message',
          );
          _navigationService.showErrorSnackBar('Failed to create account');
        },
      );
    } catch (e) {
      _logger.error('Signup error: $e');
      
      // Clean up Firebase Auth user if it was created
      try {
        await FirebaseAuth.instance.currentUser?.delete();
      } catch (deleteError) {
        _logger.error('Error deleting Firebase Auth user: $deleteError');
      }
      
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      _navigationService.showErrorSnackBar(getErrorMessage(e));
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      _logger.info('Logging out user: ${state.userId}');
      
      await FirebaseAuth.instance.signOut();
      
      state = const AuthState();
      
      _navigationService.showSuccessSnackBar('Logged out successfully!');
      _navigationService.navigateAndReplace(AuthScreen());
      
      _logger.info('User logged out successfully');
    } catch (e) {
      _logger.error('Logout error: $e');
      _navigationService.showErrorSnackBar('Failed to logout');
    }
  }

  /// Get user-friendly error message
  String getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('user-not-found')) {
      return 'No account found with this email address';
    } else if (errorString.contains('wrong-password')) {
      return 'Incorrect password';
    } else if (errorString.contains('email-already-in-use')) {
      return 'An account already exists with this email address';
    } else if (errorString.contains('weak-password')) {
      return 'Password is too weak';
    } else if (errorString.contains('invalid-email')) {
      return 'Invalid email address';
    } else if (errorString.contains('network')) {
      return 'Network error. Please check your connection';
    } else {
      return 'An error occurred. Please try again';
    }
  }

  /// Check if user is authenticated
  bool get isAuthenticated => state.isAuthenticated;

  /// Get current user
  User? get currentUser => state.user;

  /// Get current user ID
  String? get currentUserId => state.userId;
}

final authProvider = StateNotifierProvider<AuthProvider, AuthState>((ref) {
  return AuthProvider(
    userRepository: ref.read(userRepositoryProvider),
    navigationService: ref.read(navigationServiceProvider),
    logger: ref.read(loggerProvider),
  );
});

// Import shared providers
import 'providers.dart';
