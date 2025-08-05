import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:educonnect/core/result.dart';
import 'package:educonnect/modules/course.dart';
import 'package:educonnect/modules/user.dart';
import 'package:educonnect/services/enrollment_notification_service.dart';
import 'package:educonnect/services/waitlist_service.dart';
import 'package:educonnect/services/enrollment_analytics_service.dart';
import 'package:educonnect/repositories/course_repository.dart';
import 'package:educonnect/repositories/user_repository.dart';

import 'enrollment_notification_test.mocks.dart';

@GenerateMocks([CourseRepository, UserRepository])
void main() {
  group('Enrollment Notification Integration Tests', () {
    late MockCourseRepository mockCourseRepository;
    late MockUserRepository mockUserRepository;
    late EnrollmentNotificationService notificationService;
    late WaitlistService waitlistService;
    late EnrollmentAnalyticsService analyticsService;

    late Course testCourse;
    late User testStudent1;
    late User testStudent2;
    late User testInstructor;

    setUp(() {
      mockCourseRepository = MockCourseRepository();
      mockUserRepository = MockUserRepository();
      
      notificationService = EnrollmentNotificationService();
      
      waitlistService = WaitlistService(
        courseRepository: mockCourseRepository,
        userRepository: mockUserRepository,
      );
      
      analyticsService = EnrollmentAnalyticsService(
        courseRepository: mockCourseRepository,
        userRepository: mockUserRepository,
      );

      // Create test data
      testCourse = Course(
        id: 'course_1',
        title: 'Advanced Flutter Development',
        description: 'Learn advanced Flutter concepts and patterns',
        instructorId: 'instructor_1',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        maxEnrollment: 3,
        status: CourseStatus.published,
        enrolledStudents: ['student_1', 'student_2'],
        duration: 40,
        category: 'Programming',
      );

      testStudent1 = User(
        id: 'student_1',
        email: 'student1@test.com',
        name: 'Alice Johnson',
        role: UserRole.student,
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
        grade: '12th Grade',
        department: 'Computer Science',
      );

      testStudent2 = User(
        id: 'student_2',
        email: 'student2@test.com',
        name: 'Bob Smith',
        role: UserRole.student,
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
        grade: '11th Grade',
        department: 'Computer Science',
      );

      testInstructor = User(
        id: 'instructor_1',
        email: 'instructor@test.com',
        name: 'Dr. Sarah Wilson',
        role: UserRole.instructor,
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
        fieldOfExpertise: 'Mobile Development',
        department: 'Computer Science',
      );
    });

    group('Enrollment Confirmation Notifications', () {
      test('should create enrollment confirmation notification with correct details', () {
        // Act
        final notification = notificationService.createEnrollmentConfirmation(
          userId: testStudent1.id,
          course: testCourse,
        );

        // Assert
        expect(notification.type, EnrollmentNotificationType.enrollmentConfirmation);
        expect(notification.userId, testStudent1.id);
        expect(notification.courseId, testCourse.id);
        expect(notification.title, 'Enrollment Confirmed');
        expect(notification.message, contains(testCourse.title));
        expect(notification.message, contains('40 hours'));
        expect(notification.data['courseTitle'], testCourse.title);
        expect(notification.data['instructorId'], testCourse.instructorId);
        expect(notification.data['enrolledCount'], testCourse.enrolledStudents.length);
        expect(notification.data['maxEnrollment'], testCourse.maxEnrollment);
        expect(notification.isRead, false);
      });

      test('should send enrollment confirmations to multiple students', () async {
        // Arrange
        final enrolledStudents = [testStudent1, testStudent2];

        // Act
        final result = await notificationService.sendEnrollmentConfirmations(
          course: testCourse,
          enrolledStudents: enrolledStudents,
        );

        // Assert
        expect(result.isSuccess, true);
        final notifications = result.data!;
        expect(notifications.length, 2);
        
        expect(notifications[0].userId, testStudent1.id);
        expect(notifications[1].userId, testStudent2.id);
        
        for (final notification in notifications) {
          expect(notification.type, EnrollmentNotificationType.enrollmentConfirmation);
          expect(notification.courseId, testCourse.id);
          expect(notification.title, 'Enrollment Confirmed');
        }
      });
    });

    group('Capacity Warning Notifications', () {
      test('should create capacity warning notification when course is nearly full', () {
        // Arrange
        final nearlyFullCourse = testCourse.copyWith(
          enrolledStudents: ['student_1', 'student_2'], // 2/3 enrolled (67%)
        );

        // Act
        final notification = notificationService.createCapacityWarning(
          userId: 'interested_student',
          course: nearlyFullCourse,
        );

        // Assert
        expect(notification.type, EnrollmentNotificationType.courseCapacityWarning);
        expect(notification.title, 'Course Filling Up');
        expect(notification.message, contains('filling up quickly'));
        expect(notification.message, contains('1 spots remaining'));
        expect(notification.data['availableSpots'], 1);
        expect(notification.data['maxEnrollment'], 3);
      });

      test('should send capacity warnings to interested users', () async {
        // Arrange
        final nearlyFullCourse = testCourse.copyWith(
          enrolledStudents: ['student_1', 'student_2'],
        );
        final interestedUser = User(
          id: 'interested_student',
          email: 'interested@test.com',
          name: 'Charlie Brown',
          role: UserRole.student,
          createdAt: DateTime.now(),
          grade: '10th Grade',
        );

        // Act
        final result = await notificationService.sendCapacityWarnings(
          course: nearlyFullCourse,
          interestedUsers: [interestedUser],
        );

        // Assert
        expect(result.isSuccess, true);
      });

      test('should not send capacity warnings when course is not nearly full', () async {
        // Arrange
        final courseWithSpace = testCourse.copyWith(
          enrolledStudents: ['student_1'], // Only 1/3 enrolled (33%)
        );
        final interestedUser = User(
          id: 'interested_student',
          email: 'interested@test.com',
          name: 'Charlie Brown',
          role: UserRole.student,
          createdAt: DateTime.now(),
          grade: '10th Grade',
        );

        // Act
        final result = await notificationService.sendCapacityWarnings(
          course: courseWithSpace,
          interestedUsers: [interestedUser],
        );

        // Assert
        expect(result.isSuccess, true);
      });
    });

    group('Course Full Notifications', () {
      test('should create course full notification', () {
        // Arrange
        final fullCourse = testCourse.copyWith(
          enrolledStudents: ['student_1', 'student_2', 'student_3'],
        );

        // Act
        final notification = notificationService.createCourseFull(
          userId: 'waitlisted_student',
          course: fullCourse,
        );

        // Assert
        expect(notification.type, EnrollmentNotificationType.courseFull);
        expect(notification.title, 'Course Full');
        expect(notification.message, contains('now full'));
        expect(notification.message, contains('waitlist'));
        expect(notification.data['maxEnrollment'], 3);
        expect(notification.data['waitlistAvailable'], true);
      });

      test('should send course full notifications to waitlisted users', () async {
        // Arrange
        final fullCourse = testCourse.copyWith(
          enrolledStudents: ['student_1', 'student_2', 'student_3'],
        );
        final waitlistedUser = User(
          id: 'waitlisted_student',
          email: 'waitlisted@test.com',
          name: 'Diana Prince',
          role: UserRole.student,
          createdAt: DateTime.now(),
          grade: '12th Grade',
        );

        // Act
        final result = await notificationService.sendCourseFullNotifications(
          course: fullCourse,
          waitlistedUsers: [waitlistedUser],
        );

        // Assert
        expect(result.isSuccess, true);
      });
    });

    group('Enrollment Reminder Notifications', () {
      test('should create enrollment reminder notification', () {
        // Arrange
        final reminderDate = DateTime.now().add(const Duration(days: 3));

        // Act
        final notification = notificationService.createEnrollmentReminder(
          userId: testStudent1.id,
          course: testCourse,
          reminderDate: reminderDate,
        );

        // Assert
        expect(notification.type, EnrollmentNotificationType.enrollmentReminder);
        expect(notification.title, 'Course Starting Soon');
        expect(notification.message, contains('starting on'));
        expect(notification.data['courseTitle'], testCourse.title);
        expect(notification.data['instructorId'], testCourse.instructorId);
      });

      test('should send enrollment reminders to enrolled students', () async {
        // Arrange
        final reminderDate = DateTime.now().add(const Duration(days: 1));
        final enrolledStudents = [testStudent1, testStudent2];

        // Act
        final result = await notificationService.sendEnrollmentReminders(
          course: testCourse,
          enrolledStudents: enrolledStudents,
          reminderDate: reminderDate,
        );

        // Assert
        expect(result.isSuccess, true);
      });
    });

    group('Waitlist Notifications', () {
      test('should create waitlist update notification', () {
        // Act
        final notification = notificationService.createWaitlistUpdate(
          userId: 'waitlisted_student',
          course: testCourse,
          waitlistPosition: 2,
        );

        // Assert
        expect(notification.type, EnrollmentNotificationType.waitlistUpdate);
        expect(notification.title, 'Waitlist Update');
        expect(notification.message, contains('#2 on the waitlist'));
        expect(notification.data['waitlistPosition'], 2);
        expect(notification.data['courseTitle'], testCourse.title);
      });
    });

    group('Course Status Change Notifications', () {
      test('should create course status change notification for published course', () {
        // Act
        final notification = notificationService.createCourseStatusChange(
          userId: testStudent1.id,
          course: testCourse,
          oldStatus: CourseStatus.draft,
          newStatus: CourseStatus.published,
        );

        // Assert
        expect(notification.type, EnrollmentNotificationType.courseStatusChange);
        expect(notification.title, 'Course Status Update');
        expect(notification.message, contains('now available for enrollment'));
        expect(notification.data['oldStatus'], 'draft');
        expect(notification.data['newStatus'], 'published');
      });

      test('should create course status change notification for suspended course', () {
        // Act
        final notification = notificationService.createCourseStatusChange(
          userId: testStudent1.id,
          course: testCourse,
          oldStatus: CourseStatus.published,
          newStatus: CourseStatus.suspended,
        );

        // Assert
        expect(notification.type, EnrollmentNotificationType.courseStatusChange);
        expect(notification.title, 'Course Status Update');
        expect(notification.message, contains('temporarily suspended'));
        expect(notification.data['oldStatus'], 'published');
        expect(notification.data['newStatus'], 'suspended');
      });

      test('should create course status change notification for archived course', () {
        // Act
        final notification = notificationService.createCourseStatusChange(
          userId: testStudent1.id,
          course: testCourse,
          oldStatus: CourseStatus.published,
          newStatus: CourseStatus.archived,
        );

        // Assert
        expect(notification.type, EnrollmentNotificationType.courseStatusChange);
        expect(notification.title, 'Course Status Update');
        expect(notification.message, contains('archived and is no longer available'));
        expect(notification.data['oldStatus'], 'published');
        expect(notification.data['newStatus'], 'archived');
      });
    });

    group('Waitlist Integration', () {
      test('should add student to waitlist when course is full', () async {
        // Arrange
        final fullCourse = testCourse.copyWith(
          enrolledStudents: ['student_1', 'student_2', 'student_3'],
        );
        when(mockCourseRepository.getCourseById('course_1'))
            .thenAnswer((_) async => Result.success(fullCourse));
        when(mockUserRepository.getUserById('new_student'))
            .thenAnswer((_) async => Result.success(User(
              id: 'new_student',
              email: 'new@test.com',
              name: 'New Student',
              role: UserRole.student,
              createdAt: DateTime.now(),
            )));

        // Act
        final result = await waitlistService.addToWaitlist(
          courseId: 'course_1',
          studentId: 'new_student',
        );

        // Assert
        expect(result.isSuccess, true);
        final waitlistEntry = result.data!;
        expect(waitlistEntry.courseId, 'course_1');
        expect(waitlistEntry.studentId, 'new_student');
        expect(waitlistEntry.position, 1);
        expect(waitlistEntry.isActive, true);
      });

      test('should process waitlist when spot becomes available', () async {
        // Arrange
        final courseWithSpot = testCourse.copyWith(
          enrolledStudents: ['student_1', 'student_2'], // One spot available
        );
        
        // Add student to waitlist first
        await waitlistService.addToWaitlist(
          courseId: 'course_1',
          studentId: 'waitlisted_student',
        );

        when(mockCourseRepository.getCourseById('course_1'))
            .thenAnswer((_) async => Result.success(courseWithSpot));
        when(mockCourseRepository.enrollStudent('course_1', 'waitlisted_student'))
            .thenAnswer((_) async => Result.success(null));

        // Act
        final result = await waitlistService.processWaitlistForAvailableSpot(
          courseId: 'course_1',
        );

        // Assert
        expect(result.isSuccess, true);
        final processedEntry = result.data!;
        expect(processedEntry.studentId, 'waitlisted_student');
        verify(mockCourseRepository.enrollStudent('course_1', 'waitlisted_student')).called(1);
      });
    });

    group('Analytics Integration', () {
      test('should generate course analytics with enrollment data', () async {
        // Arrange
        when(mockCourseRepository.getCourseById('course_1'))
            .thenAnswer((_) async => Result.success(testCourse));
        when(mockCourseRepository.getEnrolledStudents('course_1'))
            .thenAnswer((_) async => Result.success([testStudent1, testStudent2]));

        // Act
        final result = await analyticsService.generateCourseAnalytics('course_1');

        // Assert
        expect(result.isSuccess, true);
        final analytics = result.data!;
        expect(analytics.courseId, 'course_1');
        expect(analytics.courseName, testCourse.title);
        expect(analytics.totalEnrollments, 2);
        expect(analytics.currentEnrollments, 2);
        expect(analytics.maxCapacity, 3);
        expect(analytics.enrollmentsByDepartment['Computer Science'], 2);
        expect(analytics.enrollmentsByGrade['12th Grade'], 1);
        expect(analytics.enrollmentsByGrade['11th Grade'], 1);
        expect(analytics.trends.isNotEmpty, true);
      });

      test('should generate system-wide metrics', () async {
        // Arrange
        final courses = [testCourse];
        when(mockCourseRepository.getCourses(limit: 1000))
            .thenAnswer((_) async => Result.success(courses));
        when(mockCourseRepository.getEnrolledStudents('course_1'))
            .thenAnswer((_) async => Result.success([testStudent1, testStudent2]));

        // Act
        final result = await analyticsService.generateSystemMetrics();

        // Assert
        expect(result.isSuccess, true);
        final metrics = result.data!;
        expect(metrics.totalCourses, 1);
        expect(metrics.totalEnrollments, 2);
        expect(metrics.coursesByStatus['published'], 1);
        expect(metrics.mostPopularCourses.length, 1);
        expect(metrics.mostPopularCourses.first.id, testCourse.id);
      });
    });

    group('Notification Analytics', () {
      test('should provide notification analytics', () {
        // Arrange
        final notifications = [
          notificationService.createEnrollmentConfirmation(
            userId: testStudent1.id,
            course: testCourse,
          ),
          notificationService.createCapacityWarning(
            userId: testStudent2.id,
            course: testCourse,
          ),
          notificationService.createCourseFull(
            userId: 'other_student',
            course: testCourse,
          ).copyWith(isRead: true),
        ];

        // Act
        final analytics = notificationService.getNotificationAnalytics(
          notifications: notifications,
        );

        // Assert
        expect(analytics['totalNotifications'], 3);
        expect(analytics['readNotifications'], 1);
        expect(analytics['unreadNotifications'], 2);
        expect(analytics['readRate'], closeTo(33.33, 0.1));
        expect(analytics['notificationsByType']['enrollment_confirmation'], 1);
        expect(analytics['notificationsByType']['course_capacity_warning'], 1);
        expect(analytics['notificationsByType']['course_full'], 1);
      });
    });

    group('Error Handling', () {
      test('should handle course not found error in notifications', () async {
        // Arrange
        when(mockCourseRepository.getCourseById('invalid_course'))
            .thenAnswer((_) async => Result.error('Course not found'));

        // Act
        final result = await analyticsService.generateCourseAnalytics('invalid_course');

        // Assert
        expect(result.isError, true);
        expect(result.error, contains('Course not found'));
      });

      test('should handle failed enrollment in waitlist processing', () async {
        // Arrange
        final courseWithSpot = testCourse.copyWith(
          enrolledStudents: ['student_1', 'student_2'],
        );
        
        await waitlistService.addToWaitlist(
          courseId: 'course_1',
          studentId: 'waitlisted_student',
        );

        when(mockCourseRepository.getCourseById('course_1'))
            .thenAnswer((_) async => Result.success(courseWithSpot));
        when(mockCourseRepository.enrollStudent('course_1', 'waitlisted_student'))
            .thenAnswer((_) async => Result.error('Enrollment failed'));

        // Act
        final result = await waitlistService.processWaitlistForAvailableSpot(
          courseId: 'course_1',
        );

        // Assert
        expect(result.isError, true);
        expect(result.error, contains('Failed to enroll waitlisted student'));
      });
    });
  });
}