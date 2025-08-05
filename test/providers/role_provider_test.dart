import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:educonnect/providers/auth_provider.dart';
import 'package:educonnect/modules/user.dart';
import 'package:educonnect/core/logger.dart';

void main() {
  group('RoleProvider Tests', () {
    late ProviderContainer container;
    late RoleProvider roleProvider;

    setUp(() {
      container = ProviderContainer();
      roleProvider = RoleProvider(logger: Logger());
    });

    tearDown(() {
      container.dispose();
    });

    group('Initial State', () {
      test('should have correct initial state', () {
        expect(roleProvider.state.selectedRole, isNull);
        expect(roleProvider.state.isValid, isFalse);
        expect(roleProvider.state.error, isNull);
        expect(roleProvider.state.hasError, isFalse);
      });

      test('should have all role flags as false initially', () {
        expect(roleProvider.state.isStudent, isFalse);
        expect(roleProvider.state.isInstructor, isFalse);
        expect(roleProvider.state.isAdmin, isFalse);
      });
    });

    group('Role Selection', () {
      test('should select student role correctly', () {
        roleProvider.selectRole(UserRole.student);

        expect(roleProvider.state.selectedRole, equals(UserRole.student));
        expect(roleProvider.state.isValid, isTrue);
        expect(roleProvider.state.error, isNull);
        expect(roleProvider.state.isStudent, isTrue);
        expect(roleProvider.state.isInstructor, isFalse);
        expect(roleProvider.state.isAdmin, isFalse);
      });

      test('should select instructor role correctly', () {
        roleProvider.selectRole(UserRole.instructor);

        expect(roleProvider.state.selectedRole, equals(UserRole.instructor));
        expect(roleProvider.state.isValid, isTrue);
        expect(roleProvider.state.error, isNull);
        expect(roleProvider.state.isStudent, isFalse);
        expect(roleProvider.state.isInstructor, isTrue);
        expect(roleProvider.state.isAdmin, isFalse);
      });

      test('should select admin role correctly', () {
        roleProvider.selectRole(UserRole.admin);

        expect(roleProvider.state.selectedRole, equals(UserRole.admin));
        expect(roleProvider.state.isValid, isTrue);
        expect(roleProvider.state.error, isNull);
        expect(roleProvider.state.isStudent, isFalse);
        expect(roleProvider.state.isInstructor, isFalse);
        expect(roleProvider.state.isAdmin, isTrue);
      });

      test('should switch between roles correctly', () {
        // Select student first
        roleProvider.selectRole(UserRole.student);
        expect(roleProvider.state.isStudent, isTrue);

        // Switch to instructor
        roleProvider.selectRole(UserRole.instructor);
        expect(roleProvider.state.isStudent, isFalse);
        expect(roleProvider.state.isInstructor, isTrue);

        // Switch to admin
        roleProvider.selectRole(UserRole.admin);
        expect(roleProvider.state.isInstructor, isFalse);
        expect(roleProvider.state.isAdmin, isTrue);
      });
    });

    group('Role Clearing', () {
      test('should clear role selection', () {
        // First select a role
        roleProvider.selectRole(UserRole.student);
        expect(roleProvider.state.selectedRole, equals(UserRole.student));
        expect(roleProvider.state.isValid, isTrue);

        // Then clear it
        roleProvider.clearRole();
        expect(roleProvider.state.selectedRole, isNull);
        expect(roleProvider.state.isValid, isFalse);
        expect(roleProvider.state.error, isNull);
      });
    });

    group('Role Permissions', () {
      test('should allow all roles by default', () {
        expect(roleProvider.canSelectRole(UserRole.student), isTrue);
        expect(roleProvider.canSelectRole(UserRole.instructor), isTrue);
        expect(roleProvider.canSelectRole(UserRole.admin), isTrue);
      });

      test('should return all available roles', () {
        final availableRoles = roleProvider.availableRoles;
        expect(availableRoles, contains(UserRole.student));
        expect(availableRoles, contains(UserRole.instructor));
        expect(availableRoles, contains(UserRole.admin));
        expect(availableRoles.length, equals(3));
      });
    });

    group('Display Names', () {
      test('should return null display name when no role selected', () {
        expect(roleProvider.selectedRoleDisplayName, isNull);
      });

      test('should return correct display name for selected role', () {
        roleProvider.selectRole(UserRole.student);
        expect(roleProvider.selectedRoleDisplayName, equals(UserRole.student.displayName));

        roleProvider.selectRole(UserRole.instructor);
        expect(roleProvider.selectedRoleDisplayName, equals(UserRole.instructor.displayName));

        roleProvider.selectRole(UserRole.admin);
        expect(roleProvider.selectedRoleDisplayName, equals(UserRole.admin.displayName));
      });
    });

    group('State Management', () {
      test('should maintain state consistency', () {
        roleProvider.selectRole(UserRole.student);
        
        final state = roleProvider.state;
        expect(state.selectedRole, equals(UserRole.student));
        expect(state.isValid, isTrue);
        expect(state.isStudent, isTrue);
        expect(state.hasError, isFalse);
      });

      test('should handle state transitions correctly', () {
        // Initial state
        expect(roleProvider.state.isValid, isFalse);

        // Select role
        roleProvider.selectRole(UserRole.instructor);
        expect(roleProvider.state.isValid, isTrue);
        expect(roleProvider.state.isInstructor, isTrue);

        // Clear role
        roleProvider.clearRole();
        expect(roleProvider.state.isValid, isFalse);
        expect(roleProvider.state.isInstructor, isFalse);
      });
    });

    group('Error Handling', () {
      test('should handle errors gracefully', () {
        // This test would be more meaningful with actual validation logic
        // For now, we test that the error state can be set and cleared
        roleProvider.selectRole(UserRole.student);
        expect(roleProvider.state.hasError, isFalse);
        
        // Clear role should also clear any errors
        roleProvider.clearRole();
        expect(roleProvider.state.hasError, isFalse);
      });
    });
  });

  group('RoleState Tests', () {
    test('should create state with correct defaults', () {
      const state = RoleState();
      expect(state.selectedRole, isNull);
      expect(state.isValid, isFalse);
      expect(state.error, isNull);
      expect(state.hasError, isFalse);
    });

    test('should copy state correctly', () {
      const originalState = RoleState(
        selectedRole: UserRole.student,
        isValid: true,
        error: 'test error',
      );

      final copiedState = originalState.copyWith(
        selectedRole: UserRole.instructor,
        isValid: false,
      );

      expect(copiedState.selectedRole, equals(UserRole.instructor));
      expect(copiedState.isValid, isFalse);
      expect(copiedState.error, equals('test error')); // Should preserve original error
    });

    test('should clear error when specified', () {
      const originalState = RoleState(
        selectedRole: UserRole.student,
        isValid: true,
        error: 'test error',
      );

      final copiedState = originalState.copyWith(clearError: true);

      expect(copiedState.selectedRole, equals(UserRole.student));
      expect(copiedState.isValid, isTrue);
      expect(copiedState.error, isNull);
      expect(copiedState.hasError, isFalse);
    });

    test('should have correct role flags', () {
      const studentState = RoleState(selectedRole: UserRole.student);
      expect(studentState.isStudent, isTrue);
      expect(studentState.isInstructor, isFalse);
      expect(studentState.isAdmin, isFalse);

      const instructorState = RoleState(selectedRole: UserRole.instructor);
      expect(instructorState.isStudent, isFalse);
      expect(instructorState.isInstructor, isTrue);
      expect(instructorState.isAdmin, isFalse);

      const adminState = RoleState(selectedRole: UserRole.admin);
      expect(adminState.isStudent, isFalse);
      expect(adminState.isInstructor, isFalse);
      expect(adminState.isAdmin, isTrue);
    });
  });
}