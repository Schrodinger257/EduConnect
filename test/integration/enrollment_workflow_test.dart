import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:educonnect/core/result.dart';
import 'package:educonnect/modules/course.dart';
import 'package:educonnect/modules/user.dart';
import 'package:educonnect/services/enrollment_service.dart';
import 'package:educonnect/services/enrollment_notification_service.dart';
import 'package:educonnect/services/waitlist_service.dart';
import 'package:educonnect/repositories/course_repository.dart';
import 'package:educonnect/repositories/user_repository.dart';

import 'enrollment_workflow_test.mocks.dart';

@GenerateMocks([CourseRepository, UserRepository])
void main() {
  group('Enrollment Workflow Integration Tests', () {
    late MockCourseRepository mockCourseRepository;
    late MockUserRepository mockUserRepository;
    late EnrollmentService enrollmentService;
    late EnrollmentNotificationService notificationService;
    late WaitlistService waitlistService;

    late Course testCourse;
    late User testStudent;
    late User testInstructor;

    setUp(() {
      mockCourseRepository = MockCourseRepository();
      mockUserRepository = MockUserRepository();
      
      enrollmentService = EnrollmentService(
        courseRepository: mockCourseRepository,
        userRepository: mockUserRepository,
      );
      
      notificationService = EnrollmentNotificationService();
      
      waitlistService = WaitlistService(
        courseRepository: mockCourseRepository,
        userRepository: mockUserRepository,
      );

      // Create test data
      testCourse = Course(
        id: 'course_1',
        title: 'Test Course',
        description: 'A test course for enrollment',
        instructorId: 'instructor_1',
        createdAt: DateTime.now(),
        maxEnrollment: 2,
        status: CourseStatus.published,
        enrolledStudents: [],
      );

      testStudent = User(
        id: 'student_1',
        email: 'student@test.com',
        name: 'Test Student',
        role: UserRole.student,
        createdAt: DateTime.now(),
        grade: '10th Grade',
      );

      testInstructor = User(
        id: 'instructor_1',
        email: 'instructor@test.com',
        name: 'Test Instructor',
        role: UserRole.instructor,
        createdAt: DateTime.now(),
        fieldOfExpertise: 'Computer Science',
      );
    });

    group('Successful Enrollment Flow', () {
      test('should successfully enroll a student in an available course', () async {
        // Arrange
        when(mockCourseRepository.getCourseById('course_1'))
            .thenAnswer((_) async => Result.success(testCourse));
        when(mockUserRepository.getUserById('student_1'))
            .thenAnswer((_) async => Result.success(testStudent));
        when(mockCourseRepository.enrollStudent('course_1', 'student_1'))
            .thenAnswer((_) async => Result.success(null));

        // Act
        final result = await enrollmentService.enrollStudent(
          courseId: 'course_1',
          studentId: 'student_1',
        );

        // Assert
        expect(result.isSuccess, true);
        verify(mockCourseRepository.getCourseById('course_1')).called(1);
        verify(mockUserRepository.getUserById('student_1')).called(1);
        verify(mockCourseRepository.enrollStudent('course_1', 'student_1')).called(1);
      });

      test('should create enrollment confirmation notification', () async {
        // Act
        final notification = notificationService.createEnrollmentConfirmation(
          userId: testStudent.id,
          course: testCourse,
        );

        // Assert
        expect(notification.type, EnrollmentNotificationType.enrollmentConfirmation);
        expect(notification.userId, testStudent.id);
        expect(notification.courseId, testCourse.id);
        expect(notification.title, 'Enrollment Confirmed');
        expect(notification.message, contains(testCourse.title));
      });

      test('should get enrollment info for enrolled student', () async {
        // Arrange
        final enrolledCourse = testCourse.copyWith(
          enrolledStudents: ['student_1'],
        );
        when(mockCourseRepository.getCourseById('course_1'))
            .thenAnswer((_) async => Result.success(enrolledCourse));

        // Act
        final result = await enrollmentService.getEnrollmentInfo(
          courseId: 'course_1',
          userId: 'student_1',
        );

        // Assert
        expect(result.isSuccess, true);
        final enrollmentInfo = result.data!;
        expect(enrollmentInfo.status, EnrollmentStatus.enrolled);
        expect(enrollmentInfo.enrolledCount, 1);
        expect(enrollmentInfo.availableSpots, 1);
        expect(enrollmentInfo.canEnroll, false);
      });
    });

    group('Enrollment Validation', () {
      test('should reject enrollment when course is full', () async {
        // Arrange
        final fullCourse = testCourse.copyWith(
          enrolledStudents: ['student_2', 'student_3'], // Max capacity reached
        );
        when(mockCourseRepository.getCourseById('course_1'))
            .thenAnswer((_) async => Result.success(fullCourse));
        when(mockUserRepository.getUserById('student_1'))
            .thenAnswer((_) async => Result.success(testStudent));

        // Act
        final result = await enrollmentService.enrollStudent(
          courseId: 'course_1',
          studentId: 'student_1',
        );

        // Assert
        expect(result.isError, true);
        expect(result.error, contains('Course is full'));
        verifyNever(mockCourseRepository.enrollStudent(any, any));
      });

      test('should reject enrollment when student is already enrolled', () async {
        // Arrange
        final courseWithStudent = testCourse.copyWith(
          enrolledStudents: ['student_1'],
        );
        when(mockCourseRepository.getCourseById('course_1'))
            .thenAnswer((_) async => Result.success(courseWithStudent));
        when(mockUserRepository.getUserById('student_1'))
            .thenAnswer((_) async => Result.success(testStudent));

        // Act
        final result = await enrollmentService.enrollStudent(
          courseId: 'course_1',
          studentId: 'student_1',
        );

        // Assert
        expect(result.isError, true);
        expect(result.error, contains('already enrolled'));
        verifyNever(mockCourseRepository.enrollStudent(any, any));
      });

      test('should reject enrollment when course is not published', () async {
        // Arrange
        final draftCourse = testCourse.copyWith(status: CourseStatus.draft);
        when(mockCourseRepository.getCourseById('course_1'))
            .thenAnswer((_) async => Result.success(draftCourse));
        when(mockUserRepository.getUserById('student_1'))
            .thenAnswer((_) async => Result.success(testStudent));

        // Act
        final result = await enrollmentService.enrollStudent(
          courseId: 'course_1',
          studentId: 'student_1',
        );

        // Assert
        expect(result.isError, true);
        expect(result.error, contains('not available for enrollment'));
        verifyNever(mockCourseRepository.enrollStudent(any, any));
      });

      test('should reject enrollment for non-student users', () async {
        // Arrange
        when(mockCourseRepository.getCourseById('course_1'))
            .thenAnswer((_) async => Result.success(testCourse));
        when(mockUserRepository.getUserById('instructor_1'))
            .thenAnswer((_) async => Result.success(testInstructor));

        // Act
        final result = await enrollmentService.enrollStudent(
          courseId: 'course_1',
          studentId: 'instructor_1',
        );

        // Assert
        expect(result.isError, true);
        expect(result.error, contains('Only students can enroll'));
        verifyNever(mockCourseRepository.enrollStudent(any, any));
      });
    });

    group('Unenrollment Flow', () {
      test('should successfully unenroll a student from a course', () async {
        // Arrange
        when(mockCourseRepository.isStudentEnrolled('course_1', 'student_1'))
            .thenAnswer((_) async => Result.success(true));
        when(mockCourseRepository.unenrollStudent('course_1', 'student_1'))
            .thenAnswer((_) async => Result.success(null));

        // Act
        final result = await enrollmentService.unenrollStudent(
          courseId: 'course_1',
          studentId: 'student_1',
        );

        // Assert
        expect(result.isSuccess, true);
        verify(mockCourseRepository.isStudentEnrolled('course_1', 'student_1')).called(1);
        verify(mockCourseRepository.unenrollStudent('course_1', 'student_1')).called(1);
      });

      test('should reject unenrollment when student is not enrolled', () async {
        // Arrange
        when(mockCourseRepository.isStudentEnrolled('course_1', 'student_1'))
            .thenAnswer((_) async => Result.success(false));

        // Act
        final result = await enrollmentService.unenrollStudent(
          courseId: 'course_1',
          studentId: 'student_1',
        );

        // Assert
        expect(result.isError, true);
        expect(result.error, contains('not enrolled'));
        verifyNever(mockCourseRepository.unenrollStudent(any, any));
      });
    });

    group('Waitlist Management', () {
      test('should add student to waitlist when course is full', () async {
        // Arrange
        final fullCourse = testCourse.copyWith(
          enrolledStudents: ['student_2', 'student_3'],
        );
        when(mockCourseRepository.getCourseById('course_1'))
            .thenAnswer((_) async => Result.success(fullCourse));
        when(mockUserRepository.getUserById('student_1'))
            .thenAnswer((_) async => Result.success(testStudent));

        // Act
        final result = await waitlistService.addToWaitlist(
          courseId: 'course_1',
          studentId: 'student_1',
        );

        // Assert
        expect(result.isSuccess, true);
        final waitlistEntry = result.data!;
        expect(waitlistEntry.courseId, 'course_1');
        expect(waitlistEntry.studentId, 'student_1');
        expect(waitlistEntry.position, 1);
        expect(waitlistEntry.isActive, true);
      });

      test('should process waitlist when spot becomes available', () async {
        // Arrange
        final courseWithSpot = testCourse.copyWith(
          enrolledStudents: ['student_2'], // One spot available
        );
        
        // Add student to waitlist first
        await waitlistService.addToWaitlist(
          courseId: 'course_1',
          studentId: 'student_1',
        );

        when(mockCourseRepository.getCourseById('course_1'))
            .thenAnswer((_) async => Result.success(courseWithSpot));
        when(mockCourseRepository.enrollStudent('course_1', 'student_1'))
            .thenAnswer((_) async => Result.success(null));

        // Act
        final result = await waitlistService.processWaitlistForAvailableSpot(
          courseId: 'course_1',
        );

        // Assert
        expect(result.isSuccess, true);
        final processedEntry = result.data!;
        expect(processedEntry.studentId, 'student_1');
        verify(mockCourseRepository.enrollStudent('course_1', 'student_1')).called(1);
      });

      test('should get waitlist statistics', () async {
        // Arrange
        await waitlistService.addToWaitlist(
          courseId: 'course_1',
          studentId: 'student_1',
        );
        await waitlistService.addToWaitlist(
          courseId: 'course_1',
          studentId: 'student_2',
        );

        // Act
        final result = await waitlistService.getWaitlistStatistics('course_1');

        // Assert
        expect(result.isSuccess, true);
        final stats = result.data!;
        expect(stats['totalWaitlisted'], 2);
        expect(stats['averageWaitTime'], isA<double>());
        expect(stats['oldestEntry'], isNotNull);
        expect(stats['newestEntry'], isNotNull);
      });
    });

    group('Enrollment Statistics', () {
      test('should get course enrollment statistics', () async {
        // Arrange
        final enrolledCourse = testCourse.copyWith(
          enrolledStudents: ['student_1'],
        );
        when(mockCourseRepository.getCourseStatistics('course_1'))
            .thenAnswer((_) async => Result.success({
              'enrolledCount': 1,
              'maxEnrollment': 2,
              'availableSpots': 1,
              'enrollmentPercentage': 50,
            }));

        // Act
        final result = await enrollmentService.getEnrollmentStatistics('course_1');

        // Assert
        expect(result.isSuccess, true);
        final stats = result.data!;
        expect(stats['enrolledCount'], 1);
        expect(stats['maxEnrollment'], 2);
        expect(stats['availableSpots'], 1);
        expect(stats['enrollmentPercentage'], 50);
        expect(stats['isNearlyFull'], false);
        expect(stats['isFull'], false);
        expect(stats['enrollmentRate'], 0.5);
      });

      test('should get enrolled students for instructor', () async {
        // Arrange
        final enrolledStudents = [testStudent];
        when(mockCourseRepository.getEnrolledStudents('course_1'))
            .thenAnswer((_) async => Result.success(enrolledStudents));

        // Act
        final result = await enrollmentService.getEnrolledStudents('course_1');

        // Assert
        expect(result.isSuccess, true);
        expect(result.data!.length, 1);
        expect(result.data!.first.id, testStudent.id);
        verify(mockCourseRepository.getEnrolledStudents('course_1')).called(1);
      });
    });

    group('Notification Workflows', () {
      test('should send capacity warning when course is nearly full', () async {
        // Arrange
        final nearlyFullCourse = testCourse.copyWith(
          enrolledStudents: ['student_2'], // 1/2 enrolled (50%)
          maxEnrollment: 2,
        );
        final interestedUsers = [testStudent];

        // Act
        final result = await notificationService.sendCapacityWarnings(
          course: nearlyFullCourse,
          interestedUsers: interestedUsers,
        );

        // Assert
        expect(result.isSuccess, true);
      });

      test('should create course full notification', () async {
        // Arrange
        final fullCourse = testCourse.copyWith(
          enrolledStudents: ['student_2', 'student_3'],
        );

        // Act
        final notification = notificationService.createCourseFull(
          userId: testStudent.id,
          course: fullCourse,
        );

        // Assert
        expect(notification.type, EnrollmentNotificationType.courseFull);
        expect(notification.title, 'Course Full');
        expect(notification.message, contains('full'));
        expect(notification.message, contains('waitlist'));
      });

      test('should create enrollment reminder notification', () async {
        // Arrange
        final reminderDate = DateTime.now().add(const Duration(days: 1));

        // Act
        final notification = notificationService.createEnrollmentReminder(
          userId: testStudent.id,
          course: testCourse,
          reminderDate: reminderDate,
        );

        // Assert
        expect(notification.type, EnrollmentNotificationType.enrollmentReminder);
        expect(notification.title, 'Course Starting Soon');
        expect(notification.message, contains('starting'));
      });
    });

    group('Error Handling', () {
      test('should handle course not found error', () async {
        // Arrange
        when(mockCourseRepository.getCourseById('invalid_course'))
            .thenAnswer((_) async => Result.error('Course not found'));

        // Act
        final result = await enrollmentService.enrollStudent(
          courseId: 'invalid_course',
          studentId: 'student_1',
        );

        // Assert
        expect(result.isError, true);
        expect(result.error, contains('Course not found'));
      });

      test('should handle student not found error', () async {
        // Arrange
        when(mockCourseRepository.getCourseById('course_1'))
            .thenAnswer((_) async => Result.success(testCourse));
        when(mockUserRepository.getUserById('invalid_student'))
            .thenAnswer((_) async => Result.error('Student not found'));

        // Act
        final result = await enrollmentService.enrollStudent(
          courseId: 'course_1',
          studentId: 'invalid_student',
        );

        // Assert
        expect(result.isError, true);
        expect(result.error, contains('Student not found'));
      });

      test('should handle enrollment failure', () async {
        // Arrange
        when(mockCourseRepository.getCourseById('course_1'))
            .thenAnswer((_) async => Result.success(testCourse));
        when(mockUserRepository.getUserById('student_1'))
            .thenAnswer((_) async => Result.success(testStudent));
        when(mockCourseRepository.enrollStudent('course_1', 'student_1'))
            .thenAnswer((_) async => Result.error('Database error'));

        // Act
        final result = await enrollmentService.enrollStudent(
          courseId: 'course_1',
          studentId: 'student_1',
        );

        // Assert
        expect(result.isError, true);
        expect(result.error, contains('Database error'));
      });
    });
  });
}