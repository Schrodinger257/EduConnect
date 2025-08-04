import 'package:flutter_test/flutter_test.dart';
import 'package:educonnect/modules/user.dart';
import 'package:educonnect/core/core.dart';

void main() {
  group('UserRole', () {
    test('should create UserRole from string', () {
      expect(UserRole.fromString('student'), equals(UserRole.student));
      expect(UserRole.fromString('instructor'), equals(UserRole.instructor));
      expect(UserRole.fromString('admin'), equals(UserRole.admin));
    });

    test('should throw ArgumentError for invalid role string', () {
      expect(() => UserRole.fromString('invalid'), throwsArgumentError);
    });

    test('should have correct string values', () {
      expect(UserRole.student.value, equals('student'));
      expect(UserRole.instructor.value, equals('instructor'));
      expect(UserRole.admin.value, equals('admin'));
    });
  });

  group('User', () {
    late DateTime testDate;
    late User testUser;

    setUp(() {
      testDate = DateTime(2024, 1, 1);
      testUser = User(
        id: 'user123',
        email: 'test@example.com',
        name: 'Test User',
        role: UserRole.student,
        createdAt: testDate,
        bookmarks: ['post1', 'post2'],
        likedPosts: ['post3'],
        enrolledCourses: ['course1'],
      );
    });

    group('JSON serialization', () {
      test('should serialize to JSON correctly', () {
        final json = testUser.toJson();

        expect(json['id'], equals('user123'));
        expect(json['email'], equals('test@example.com'));
        expect(json['name'], equals('Test User'));
        expect(json['role'], equals('student'));
        expect(json['createdAt'], equals(testDate.toIso8601String()));
        expect(json['bookmarks'], equals(['post1', 'post2']));
        expect(json['likedPosts'], equals(['post3']));
        expect(json['enrolledCourses'], equals(['course1']));
      });

      test('should deserialize from JSON correctly', () {
        final json = {
          'id': 'user123',
          'email': 'test@example.com',
          'name': 'Test User',
          'role': 'student',
          'profileImage': 'image.jpg',
          'department': 'Computer Science',
          'grade': '10th',
          'createdAt': testDate.toIso8601String(),
          'bookmarks': ['post1', 'post2'],
          'likedPosts': ['post3'],
          'enrolledCourses': ['course1'],
        };

        final user = User.fromJson(json);

        expect(user.id, equals('user123'));
        expect(user.email, equals('test@example.com'));
        expect(user.name, equals('Test User'));
        expect(user.role, equals(UserRole.student));
        expect(user.profileImage, equals('image.jpg'));
        expect(user.department, equals('Computer Science'));
        expect(user.grade, equals('10th'));
        expect(user.createdAt, equals(testDate));
        expect(user.bookmarks, equals(['post1', 'post2']));
        expect(user.likedPosts, equals(['post3']));
        expect(user.enrolledCourses, equals(['course1']));
      });

      test('should handle null optional fields in JSON', () {
        final json = {
          'id': 'user123',
          'email': 'test@example.com',
          'name': 'Test User',
          'role': 'student',
          'createdAt': testDate.toIso8601String(),
        };

        final user = User.fromJson(json);

        expect(user.profileImage, isNull);
        expect(user.department, isNull);
        expect(user.fieldOfExpertise, isNull);
        expect(user.grade, isNull);
        expect(user.bookmarks, isEmpty);
        expect(user.likedPosts, isEmpty);
        expect(user.enrolledCourses, isEmpty);
      });

      test('should throw FormatException for invalid JSON', () {
        final invalidJson = {
          'id': 'user123',
          'email': 'test@example.com',
          // Missing required 'name' field
          'role': 'student',
          'createdAt': testDate.toIso8601String(),
        };

        expect(() => User.fromJson(invalidJson), throwsFormatException);
      });
    });

    group('validation', () {
      test('should validate correct user data', () {
        final result = User.validate(
          id: 'user123',
          email: 'test@example.com',
          name: 'Test User',
          role: UserRole.student,
          createdAt: testDate,
        );

        expect(result.isSuccess, isTrue);
        expect(result.data?.id, equals('user123'));
        expect(result.data?.email, equals('test@example.com'));
        expect(result.data?.name, equals('Test User'));
      });

      test('should trim and normalize email', () {
        final result = User.validate(
          id: 'user123',
          email: '  TEST@EXAMPLE.COM  ',
          name: 'Test User',
          role: UserRole.student,
          createdAt: testDate,
        );

        expect(result.isSuccess, isTrue);
        expect(result.data?.email, equals('test@example.com'));
      });

      test('should fail validation for empty required fields', () {
        final result = User.validate(
          id: '',
          email: '',
          name: '',
          role: UserRole.student,
          createdAt: testDate,
        );

        expect(result.isError, isTrue);
        expect(result.errorMessage, contains('User ID cannot be empty'));
        expect(result.errorMessage, contains('Email cannot be empty'));
        expect(result.errorMessage, contains('Name cannot be empty'));
      });

      test('should fail validation for invalid email format', () {
        final result = User.validate(
          id: 'user123',
          email: 'invalid-email',
          name: 'Test User',
          role: UserRole.student,
          createdAt: testDate,
        );

        expect(result.isError, isTrue);
        expect(result.errorMessage, contains('Invalid email format'));
      });

      test('should fail validation for short name', () {
        final result = User.validate(
          id: 'user123',
          email: 'test@example.com',
          name: 'A',
          role: UserRole.student,
          createdAt: testDate,
        );

        expect(result.isError, isTrue);
        expect(result.errorMessage, contains('Name must be at least 2 characters long'));
      });

      test('should fail validation for long name', () {
        final result = User.validate(
          id: 'user123',
          email: 'test@example.com',
          name: 'A' * 101,
          role: UserRole.student,
          createdAt: testDate,
        );

        expect(result.isError, isTrue);
        expect(result.errorMessage, contains('Name cannot exceed 100 characters'));
      });

      test('should require field of expertise for instructors', () {
        final result = User.validate(
          id: 'user123',
          email: 'test@example.com',
          name: 'Test User',
          role: UserRole.instructor,
          fieldOfExpertise: '',
          createdAt: testDate,
        );

        expect(result.isError, isTrue);
        expect(result.errorMessage, contains('Field of expertise is required for instructors'));
      });

      test('should require grade for students', () {
        final result = User.validate(
          id: 'user123',
          email: 'test@example.com',
          name: 'Test User',
          role: UserRole.student,
          grade: '',
          createdAt: testDate,
        );

        expect(result.isError, isTrue);
        expect(result.errorMessage, contains('Grade level is required for students'));
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        final updatedUser = testUser.copyWith(
          name: 'Updated Name',
          email: 'updated@example.com',
        );

        expect(updatedUser.name, equals('Updated Name'));
        expect(updatedUser.email, equals('updated@example.com'));
        expect(updatedUser.id, equals(testUser.id)); // Unchanged
        expect(updatedUser.role, equals(testUser.role)); // Unchanged
      });

      test('should preserve original values when no updates provided', () {
        final copiedUser = testUser.copyWith();

        expect(copiedUser.id, equals(testUser.id));
        expect(copiedUser.email, equals(testUser.email));
        expect(copiedUser.name, equals(testUser.name));
        expect(copiedUser.role, equals(testUser.role));
      });
    });

    group('bookmark operations', () {
      test('should add bookmark', () {
        final updatedUser = testUser.addBookmark('post3');

        expect(updatedUser.bookmarks, contains('post3'));
        expect(updatedUser.bookmarks.length, equals(3));
      });

      test('should not add duplicate bookmark', () {
        final updatedUser = testUser.addBookmark('post1');

        expect(updatedUser.bookmarks.length, equals(2));
        expect(updatedUser.bookmarks, equals(testUser.bookmarks));
      });

      test('should remove bookmark', () {
        final updatedUser = testUser.removeBookmark('post1');

        expect(updatedUser.bookmarks, isNot(contains('post1')));
        expect(updatedUser.bookmarks.length, equals(1));
      });

      test('should check if user has bookmarked post', () {
        expect(testUser.hasBookmarked('post1'), isTrue);
        expect(testUser.hasBookmarked('post3'), isFalse);
      });
    });

    group('liked posts operations', () {
      test('should add liked post', () {
        final updatedUser = testUser.addLikedPost('post4');

        expect(updatedUser.likedPosts, contains('post4'));
        expect(updatedUser.likedPosts.length, equals(2));
      });

      test('should not add duplicate liked post', () {
        final updatedUser = testUser.addLikedPost('post3');

        expect(updatedUser.likedPosts.length, equals(1));
        expect(updatedUser.likedPosts, equals(testUser.likedPosts));
      });

      test('should remove liked post', () {
        final updatedUser = testUser.removeLikedPost('post3');

        expect(updatedUser.likedPosts, isNot(contains('post3')));
        expect(updatedUser.likedPosts.length, equals(0));
      });

      test('should check if user has liked post', () {
        expect(testUser.hasLikedPost('post3'), isTrue);
        expect(testUser.hasLikedPost('post1'), isFalse);
      });
    });

    group('course enrollment operations', () {
      test('should enroll in course', () {
        final updatedUser = testUser.enrollInCourse('course2');

        expect(updatedUser.enrolledCourses, contains('course2'));
        expect(updatedUser.enrolledCourses.length, equals(2));
      });

      test('should not enroll in duplicate course', () {
        final updatedUser = testUser.enrollInCourse('course1');

        expect(updatedUser.enrolledCourses.length, equals(1));
        expect(updatedUser.enrolledCourses, equals(testUser.enrolledCourses));
      });

      test('should unenroll from course', () {
        final updatedUser = testUser.unenrollFromCourse('course1');

        expect(updatedUser.enrolledCourses, isNot(contains('course1')));
        expect(updatedUser.enrolledCourses.length, equals(0));
      });

      test('should check if user is enrolled in course', () {
        expect(testUser.isEnrolledInCourse('course1'), isTrue);
        expect(testUser.isEnrolledInCourse('course2'), isFalse);
      });
    });

    group('utility methods', () {
      test('should return correct role display name', () {
        expect(testUser.roleDisplayName, equals('Student'));
        
        final instructor = testUser.copyWith(role: UserRole.instructor);
        expect(instructor.roleDisplayName, equals('Instructor'));
        
        final admin = testUser.copyWith(role: UserRole.admin);
        expect(admin.roleDisplayName, equals('Administrator'));
      });

      test('should have correct string representation', () {
        final userString = testUser.toString();
        expect(userString, contains('user123'));
        expect(userString, contains('test@example.com'));
        expect(userString, contains('Test User'));
        expect(userString, contains('student'));
      });

      test('should implement equality correctly', () {
        final sameUser = User(
          id: 'user123',
          email: 'test@example.com',
          name: 'Test User',
          role: UserRole.student,
          createdAt: testDate,
        );

        final differentUser = testUser.copyWith(id: 'user456');

        expect(testUser == sameUser, isTrue);
        expect(testUser == differentUser, isFalse);
      });
    });
  });
}