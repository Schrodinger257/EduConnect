import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:educonnect/widgets/role_specific_fields.dart';
import 'package:educonnect/modules/user.dart';

void main() {
  group('RoleSpecificFields Widget Tests', () {
    late TextEditingController departmentController;
    late TextEditingController fieldOfExpertiseController;
    String? selectedGrade;
    Function(String?)? onGradeChanged;

    setUp(() {
      departmentController = TextEditingController();
      fieldOfExpertiseController = TextEditingController();
      selectedGrade = null;
      onGradeChanged = (grade) => selectedGrade = grade;
    });

    tearDown(() {
      departmentController.dispose();
      fieldOfExpertiseController.dispose();
    });

    Widget createWidget(User user) {
      return MaterialApp(
        home: Scaffold(
          body: RoleSpecificFields(
            user: user,
            departmentController: departmentController,
            fieldOfExpertiseController: fieldOfExpertiseController,
            selectedGrade: selectedGrade,
            onGradeChanged: onGradeChanged!,
          ),
        ),
      );
    }

    testWidgets('displays student-specific fields for student role', (tester) async {
      final studentUser = User(
        id: 'test-id',
        email: 'student@test.com',
        name: 'Test Student',
        role: UserRole.student,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(createWidget(studentUser));

      // Should show department field
      expect(find.text('Department'), findsOneWidget);
      expect(find.text('Grade Level'), findsOneWidget);
      
      // Should not show instructor-specific fields
      expect(find.text('Field of Expertise'), findsNothing);
    });

    testWidgets('displays instructor-specific fields for instructor role', (tester) async {
      final instructorUser = User(
        id: 'test-id',
        email: 'instructor@test.com',
        name: 'Test Instructor',
        role: UserRole.instructor,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(createWidget(instructorUser));

      // Should show instructor-specific fields
      expect(find.text('Field of Expertise'), findsOneWidget);
      expect(find.text('Department'), findsOneWidget);
      
      // Should not show student-specific fields
      expect(find.text('Grade Level'), findsNothing);
    });

    testWidgets('displays admin-specific fields for admin role', (tester) async {
      final adminUser = User(
        id: 'test-id',
        email: 'admin@test.com',
        name: 'Test Admin',
        role: UserRole.admin,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(createWidget(adminUser));

      // Should show admin-specific fields
      expect(find.text('Department/Division'), findsOneWidget);
      
      // Should not show role-specific fields from other roles
      expect(find.text('Field of Expertise'), findsNothing);
      expect(find.text('Grade Level'), findsNothing);
    });

    testWidgets('shows role information section', (tester) async {
      final studentUser = User(
        id: 'test-id',
        email: 'student@test.com',
        name: 'Test Student',
        role: UserRole.student,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(createWidget(studentUser));

      // Should show role information section
      expect(find.text('Role Information'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      
      // Should show student-specific description
      expect(find.textContaining('As a student'), findsOneWidget);
    });

    testWidgets('grade dropdown works correctly for students', (tester) async {
      final studentUser = User(
        id: 'test-id',
        email: 'student@test.com',
        name: 'Test Student',
        role: UserRole.student,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(createWidget(studentUser));

      // Find and tap the dropdown
      final dropdown = find.byType(DropdownButtonFormField<String>);
      expect(dropdown, findsOneWidget);

      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      // Should show grade options
      expect(find.text('1st Year'), findsOneWidget);
      expect(find.text('2nd Year'), findsOneWidget);
      expect(find.text('3rd Year'), findsOneWidget);
      expect(find.text('4th Year'), findsOneWidget);
      expect(find.text('Graduate'), findsOneWidget);
      expect(find.text('PhD'), findsOneWidget);
    });

    testWidgets('validates required fields correctly', (tester) async {
      final instructorUser = User(
        id: 'test-id',
        email: 'instructor@test.com',
        name: 'Test Instructor',
        role: UserRole.instructor,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(createWidget(instructorUser));

      // Find the field of expertise field
      final fieldOfExpertiseField = find.widgetWithText(TextFormField, 'Field of Expertise');
      expect(fieldOfExpertiseField, findsOneWidget);

      // The field should have a validator that requires input for instructors
      final textFormField = tester.widget<TextFormField>(fieldOfExpertiseField);
      expect(textFormField.validator, isNotNull);
      
      // Test validation with empty value
      final validationResult = textFormField.validator!('');
      expect(validationResult, contains('required for instructors'));
    });

    testWidgets('shows correct role descriptions', (tester) async {
      // Test student description
      final studentUser = User(
        id: 'test-id',
        email: 'student@test.com',
        name: 'Test Student',
        role: UserRole.student,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(createWidget(studentUser));
      expect(find.textContaining('enroll in courses'), findsOneWidget);

      // Test instructor description
      final instructorUser = User(
        id: 'test-id',
        email: 'instructor@test.com',
        name: 'Test Instructor',
        role: UserRole.instructor,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(createWidget(instructorUser));
      await tester.pumpAndSettle();
      expect(find.textContaining('create courses'), findsOneWidget);

      // Test admin description
      final adminUser = User(
        id: 'test-id',
        email: 'admin@test.com',
        name: 'Test Admin',
        role: UserRole.admin,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(createWidget(adminUser));
      await tester.pumpAndSettle();
      expect(find.textContaining('system management'), findsOneWidget);
    });
  });
}