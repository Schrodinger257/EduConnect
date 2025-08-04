import 'package:flutter_test/flutter_test.dart';
import 'package:educonnect/modules/course.dart';
import 'package:educonnect/core/core.dart';

void main() {
  group('CourseStatus', () {
    test('should create CourseStatus from string', () {
      expect(CourseStatus.fromString('draft'), equals(CourseStatus.draft));
      expect(CourseStatus.fromString('published'), equals(CourseStatus.published));
      expect(CourseStatus.fromString('archived'), equals(CourseStatus.archived));
      expect(CourseStatus.fromString('suspended'), equals(CourseStatus.suspended));
    });

    test('should throw ArgumentError for invalid status string', () {
      expect(() => CourseStatus.fromString('invalid'), throwsArgumentError);
    });

    test('should have correct string values', () {
      expect(CourseStatus.draft.value, equals('draft'));
      expect(CourseStatus.published.value, equals('published'));
      expect(CourseStatus.archived.value, equals('archived'));
      expect(CourseStatus.suspended.value, equals('suspended'));
    });
  });

  group('Course', () {
    late DateTime testDate;
    late DateTime updateDate;
    late Course testCourse;

    setUp(() {
      testDate = DateTime(2024, 1, 1, 12, 0, 0);
      updateDate = DateTime(2024, 1, 2, 12, 0, 0);
      testCourse = Course(
        id: 'course123',
        title: 'Introduction to Flutter',
        description: 'Learn Flutter development from basics to advanced concepts',
        instructorId: 'instructor123',
        imageUrl: 'https://example.com/course.jpg',
        tags: ['flutter', 'mobile', 'development'],
        createdAt: testDate,
        enrolledStudents: ['student1', 'student2'],
        maxEnrollment: 30,
        status: CourseStatus.published,
        category: 'Programming',
        duration: 40,
        prerequisites: 'Basic programming knowledge',
      );
    });    gr
oup('JSON serialization', () {
      test('should serialize to JSON correctly', () {
        final json = testCourse.toJson();

        expect(json['id'], equals('course123'));
        expect(json['title'], equals('Introduction to Flutter'));
        expect(json['description'], equals('Learn Flutter development from basics to advanced concepts'));
        expect(json['instructorId'], equals('instructor123'));
        expect(json['imageUrl'], equals('https://example.com/course.jpg'));
        expect(json['tags'], equals(['flutter', 'mobile', 'development']));
        expect(json['createdAt'], equals(testDate.toIso8601String()));
        expect(json['enrolledStudents'], equals(['student1', 'student2']));
        expect(json['maxEnrollment'], equals(30));
        expect(json['status'], equals('published'));
        expect(json['category'], equals('Programming'));
        expect(json['duration'], equals(40));
        expect(json['prerequisites'], equals('Basic programming knowledge'));
      });

      test('should deserialize from JSON correctly', () {
        final json = {
          'id': 'course123',
          'title': 'Introduction to Flutter',
          'description': 'Learn Flutter development from basics to advanced concepts',
          'instructorId': 'instructor123',
          'imageUrl': 'https://example.com/course.jpg',
          'tags': ['flutter', 'mobile', 'development'],
          'createdAt': testDate.toIso8601String(),
          'updatedAt': updateDate.toIso8601String(),
          'enrolledStudents': ['student1', 'student2'],
          'maxEnrollment': 30,
          'status': 'published',
          'category': 'Programming',
          'duration': 40,
          'prerequisites': 'Basic programming knowledge',
        };

        final course = Course.fromJson(json);

        expect(course.id, equals('course123'));
        expect(course.title, equals('Introduction to Flutter'));
        expect(course.description, equals('Learn Flutter development from basics to advanced concepts'));
        expect(course.instructorId, equals('instructor123'));
        expect(course.imageUrl, equals('https://example.com/course.jpg'));
        expect(course.tags, equals(['flutter', 'mobile', 'development']));
        expect(course.createdAt, equals(testDate));
        expect(course.updatedAt, equals(updateDate));
        expect(course.enrolledStudents, equals(['student1', 'student2']));
        expect(course.maxEnrollment, equals(30));
        expect(course.status, equals(CourseStatus.published));
        expect(course.category, equals('Programming'));
        expect(course.duration, equals(40));
        expect(course.prerequisites, equals('Basic programming knowledge'));
      });

      test('should handle null optional fields in JSON', () {
        final json = {
          'id': 'course123',
          'title': 'Introduction to Flutter',
          'description': 'Learn Flutter development',
          'instructorId': 'instructor123',
          'createdAt': testDate.toIso8601String(),
        };

        final course = Course.fromJson(json);

        expect(course.imageUrl, isNull);
        expect(course.tags, isEmpty);
        expect(course.updatedAt, isNull);
        expect(course.enrolledStudents, isEmpty);
        expect(course.maxEnrollment, equals(50)); // Default value
        expect(course.status, equals(CourseStatus.draft)); // Default value
        expect(course.category, isNull);
        expect(course.duration, equals(0)); // Default value
        expect(course.prerequisites, isNull);
      });

      test('should throw FormatException for invalid JSON', () {
        final invalidJson = {
          'id': 'course123',
          'title': 'Introduction to Flutter',
          // Missing required 'description' field
          'instructorId': 'instructor123',
          'createdAt': testDate.toIso8601String(),
        };

        expect(() => Course.fromJson(invalidJson), throwsFormatException);
      });
    });    gr
oup('validation', () {
      test('should validate correct course data', () {
        final result = Course.validate(
          id: 'course123',
          title: 'Introduction to Flutter',
          description: 'Learn Flutter development from basics to advanced concepts',
          instructorId: 'instructor123',
          createdAt: testDate,
        );

        expect(result.isSuccess, isTrue);
        expect(result.data?.id, equals('course123'));
        expect(result.data?.title, equals('Introduction to Flutter'));
        expect(result.data?.description, equals('Learn Flutter development from basics to advanced concepts'));
        expect(result.data?.instructorId, equals('instructor123'));
      });

      test('should trim whitespace from fields', () {
        final result = Course.validate(
          id: '  course123  ',
          title: '  Introduction to Flutter  ',
          description: '  Learn Flutter development  ',
          instructorId: '  instructor123  ',
          createdAt: testDate,
        );

        expect(result.isSuccess, isTrue);
        expect(result.data?.id, equals('course123'));
        expect(result.data?.title, equals('Introduction to Flutter'));
        expect(result.data?.description, equals('Learn Flutter development'));
        expect(result.data?.instructorId, equals('instructor123'));
      });

      test('should fail validation for empty required fields', () {
        final result = Course.validate(
          id: '',
          title: '',
          description: '',
          instructorId: '',
          createdAt: testDate,
        );

        expect(result.isError, isTrue);
        expect(result.errorMessage, contains('Course ID cannot be empty'));
        expect(result.errorMessage, contains('Course title cannot be empty'));
        expect(result.errorMessage, contains('Course description cannot be empty'));
        expect(result.errorMessage, contains('Instructor ID cannot be empty'));
      });

      test('should fail validation for short title', () {
        final result = Course.validate(
          id: 'course123',
          title: 'AB',
          description: 'Learn Flutter development',
          instructorId: 'instructor123',
          createdAt: testDate,
        );

        expect(result.isError, isTrue);
        expect(result.errorMessage, contains('Course title must be at least 3 characters long'));
      });

      test('should fail validation for long title', () {
        final result = Course.validate(
          id: 'course123',
          title: 'A' * 201,
          description: 'Learn Flutter development',
          instructorId: 'instructor123',
          createdAt: testDate,
        );

        expect(result.isError, isTrue);
        expect(result.errorMessage, contains('Course title cannot exceed 200 characters'));
      });

      test('should fail validation for short description', () {
        final result = Course.validate(
          id: 'course123',
          title: 'Flutter Course',
          description: 'Short',
          instructorId: 'instructor123',
          createdAt: testDate,
        );

        expect(result.isError, isTrue);
        expect(result.errorMessage, contains('Course description must be at least 10 characters long'));
      });

      test('should fail validation for long description', () {
        final result = Course.validate(
          id: 'course123',
          title: 'Flutter Course',
          description: 'A' * 5001,
          instructorId: 'instructor123',
          createdAt: testDate,
        );

        expect(result.isError, isTrue);
        expect(result.errorMessage, contains('Course description cannot exceed 5000 characters'));
      });

      test('should fail validation for invalid enrollment limits', () {
        final result = Course.validate(
          id: 'course123',
          title: 'Flutter Course',
          description: 'Learn Flutter development',
          instructorId: 'instructor123',
          createdAt: testDate,
          maxEnrollment: 0,
        );

        expect(result.isError, isTrue);
        expect(result.errorMessage, contains('Maximum enrollment must be greater than 0'));
      });

      test('should fail validation for too many enrolled students', () {
        final result = Course.validate(
          id: 'course123',
          title: 'Flutter Course',
          description: 'Learn Flutter development',
          instructorId: 'instructor123',
          createdAt: testDate,
          maxEnrollment: 2,
          enrolledStudents: ['student1', 'student2', 'student3'],
        );

        expect(result.isError, isTrue);
        expect(result.errorMessage, contains('Enrolled students count cannot exceed maximum enrollment'));
      });

      test('should fail validation for duplicate enrolled students', () {
        final result = Course.validate(
          id: 'course123',
          title: 'Flutter Course',
          description: 'Learn Flutter development',
          instructorId: 'instructor123',
          createdAt: testDate,
          enrolledStudents: ['student1', 'student1'],
        );

        expect(result.isError, isTrue);
        expect(result.errorMessage, contains('Enrolled students list cannot contain duplicates'));
      });
    });    group(
'enrollment operations', () {
      test('should enroll student', () {
        final updatedCourse = testCourse.enrollStudent('student3');

        expect(updatedCourse.enrolledStudents, contains('student3'));
        expect(updatedCourse.enrolledStudents.length, equals(3));
        expect(updatedCourse.updatedAt, isNotNull);
      });

      test('should not enroll duplicate student', () {
        final updatedCourse = testCourse.enrollStudent('student1');

        expect(updatedCourse.enrolledStudents.length, equals(2));
        expect(updatedCourse.enrolledStudents, equals(testCourse.enrolledStudents));
      });

      test('should not enroll student when course is full', () {
        final fullCourse = testCourse.copyWith(
          enrolledStudents: List.generate(30, (index) => 'student$index'),
        );
        final updatedCourse = fullCourse.enrollStudent('newStudent');

        expect(updatedCourse.enrolledStudents.length, equals(30));
        expect(updatedCourse.enrolledStudents, equals(fullCourse.enrolledStudents));
      });

      test('should unenroll student', () {
        final updatedCourse = testCourse.unenrollStudent('student1');

        expect(updatedCourse.enrolledStudents, isNot(contains('student1')));
        expect(updatedCourse.enrolledStudents.length, equals(1));
        expect(updatedCourse.updatedAt, isNotNull);
      });

      test('should not unenroll non-enrolled student', () {
        final updatedCourse = testCourse.unenrollStudent('student3');

        expect(updatedCourse.enrolledStudents.length, equals(2));
        expect(updatedCourse.enrolledStudents, equals(testCourse.enrolledStudents));
      });

      test('should check if student is enrolled', () {
        expect(testCourse.isStudentEnrolled('student1'), isTrue);
        expect(testCourse.isStudentEnrolled('student3'), isFalse);
      });
    });

    group('status operations', () {
      test('should update status', () {
        final updatedCourse = testCourse.updateStatus(CourseStatus.archived);

        expect(updatedCourse.status, equals(CourseStatus.archived));
        expect(updatedCourse.updatedAt, isNotNull);
      });

      test('should publish course', () {
        final draftCourse = testCourse.copyWith(status: CourseStatus.draft);
        final publishedCourse = draftCourse.publish();

        expect(publishedCourse.status, equals(CourseStatus.published));
        expect(publishedCourse.updatedAt, isNotNull);
      });

      test('should archive course', () {
        final archivedCourse = testCourse.archive();

        expect(archivedCourse.status, equals(CourseStatus.archived));
        expect(archivedCourse.updatedAt, isNotNull);
      });

      test('should suspend course', () {
        final suspendedCourse = testCourse.suspend();

        expect(suspendedCourse.status, equals(CourseStatus.suspended));
        expect(suspendedCourse.updatedAt, isNotNull);
      });
    });

    group('utility methods', () {
      test('should check if course is full', () {
        expect(testCourse.isFull, isFalse);
        expect(testCourse.hasAvailableSpots, isTrue);
        expect(testCourse.availableSpots, equals(28));

        final fullCourse = testCourse.copyWith(
          enrolledStudents: List.generate(30, (index) => 'student$index'),
        );
        expect(fullCourse.isFull, isTrue);
        expect(fullCourse.hasAvailableSpots, isFalse);
        expect(fullCourse.availableSpots, equals(0));
      });

      test('should calculate enrollment percentage', () {
        expect(testCourse.enrollmentPercentage, closeTo(6.67, 0.01));

        final halfFullCourse = testCourse.copyWith(
          enrolledStudents: List.generate(15, (index) => 'student$index'),
        );
        expect(halfFullCourse.enrollmentPercentage, equals(50.0));
      });

      test('should check status booleans', () {
        expect(testCourse.isPublished, isTrue);
        expect(testCourse.isDraft, isFalse);
        expect(testCourse.isArchived, isFalse);
        expect(testCourse.isSuspended, isFalse);

        final draftCourse = testCourse.copyWith(status: CourseStatus.draft);
        expect(draftCourse.isDraft, isTrue);
        expect(draftCourse.isPublished, isFalse);
      });

      test('should check if can accept enrollments', () {
        expect(testCourse.canAcceptEnrollments, isTrue);

        final draftCourse = testCourse.copyWith(status: CourseStatus.draft);
        expect(draftCourse.canAcceptEnrollments, isFalse);

        final fullCourse = testCourse.copyWith(
          enrolledStudents: List.generate(30, (index) => 'student$index'),
        );
        expect(fullCourse.canAcceptEnrollments, isFalse);
      });

      test('should return status display name', () {
        expect(testCourse.statusDisplayName, equals('Published'));
        
        final draftCourse = testCourse.copyWith(status: CourseStatus.draft);
        expect(draftCourse.statusDisplayName, equals('Draft'));
      });

      test('should return formatted duration', () {
        expect(testCourse.formattedDuration, equals('40 hours'));

        final oneDayCourse = testCourse.copyWith(duration: 24);
        expect(oneDayCourse.formattedDuration, equals('1 day'));

        final mixedCourse = testCourse.copyWith(duration: 26);
        expect(mixedCourse.formattedDuration, equals('1 days, 2 hours'));

        final noDurationCourse = testCourse.copyWith(duration: 0);
        expect(noDurationCourse.formattedDuration, equals('Duration not specified'));
      });

      test('should return description preview', () {
        expect(testCourse.descriptionPreview, equals('Learn Flutter development from basics to advanced concepts'));

        final longDescription = 'A' * 150;
        final longCourse = testCourse.copyWith(description: longDescription);
        expect(longCourse.descriptionPreview, equals('${'A' * 97}...'));
        expect(longCourse.descriptionPreview.length, equals(100));
      });

      test('should match search query', () {
        expect(testCourse.matchesSearch('flutter'), isTrue);
        expect(testCourse.matchesSearch('FLUTTER'), isTrue);
        expect(testCourse.matchesSearch('mobile'), isTrue);
        expect(testCourse.matchesSearch('Programming'), isTrue);
        expect(testCourse.matchesSearch('development'), isTrue);
        expect(testCourse.matchesSearch('nonexistent'), isFalse);
      });

      test('should calculate popularity score', () {
        expect(testCourse.popularityScore, closeTo(0.067, 0.001));

        final popularCourse = testCourse.copyWith(
          enrolledStudents: List.generate(15, (index) => 'student$index'),
        );
        expect(popularCourse.popularityScore, equals(0.5));
      });

      test('should check if recently created or updated', () {
        final now = DateTime.now();
        
        final recentCourse = testCourse.copyWith(createdAt: now.subtract(const Duration(days: 15)));
        expect(recentCourse.isRecentlyCreated, isTrue);
        
        final oldCourse = testCourse.copyWith(createdAt: now.subtract(const Duration(days: 45)));
        expect(oldCourse.isRecentlyCreated, isFalse);

        final recentlyUpdatedCourse = testCourse.copyWith(updatedAt: now.subtract(const Duration(days: 3)));
        expect(recentlyUpdatedCourse.isRecentlyUpdated, isTrue);

        final notRecentlyUpdatedCourse = testCourse.copyWith(updatedAt: now.subtract(const Duration(days: 10)));
        expect(notRecentlyUpdatedCourse.isRecentlyUpdated, isFalse);
      });

      test('should have correct string representation', () {
        final courseString = testCourse.toString();
        expect(courseString, contains('course123'));
        expect(courseString, contains('Introduction to Flutter'));
        expect(courseString, contains('instructor123'));
        expect(courseString, contains('enrolled: 2/30'));
        expect(courseString, contains('status: published'));
      });

      test('should implement equality correctly', () {
        final sameCourse = Course(
          id: 'course123',
          title: 'Introduction to Flutter',
          description: 'Learn Flutter development from basics to advanced concepts',
          instructorId: 'instructor123',
          imageUrl: 'https://example.com/course.jpg',
          createdAt: testDate,
          status: CourseStatus.published,
        );

        final differentCourse = testCourse.copyWith(id: 'course456');

        expect(testCourse == sameCourse, isTrue);
        expect(testCourse == differentCourse, isFalse);
      });
    });
  });
}