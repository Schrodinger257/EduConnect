import '../core/result.dart';
import '../core/logger.dart';
import '../modules/course.dart';
import '../modules/user.dart';

/// Enum representing different types of enrollment notifications
enum EnrollmentNotificationType {
  enrollmentConfirmation('enrollment_confirmation'),
  enrollmentReminder('enrollment_reminder'),
  courseCapacityWarning('course_capacity_warning'),
  courseFull('course_full'),
  enrollmentDeadline('enrollment_deadline'),
  waitlistUpdate('waitlist_update'),
  courseStatusChange('course_status_change');

  const EnrollmentNotificationType(this.value);
  final String value;
}

/// Represents an enrollment notification
class EnrollmentNotification {
  final String id;
  final String userId;
  final String courseId;
  final EnrollmentNotificationType type;
  final String title;
  final String message;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final bool isRead;

  const EnrollmentNotification({
    required this.id,
    required this.userId,
    required this.courseId,
    required this.type,
    required this.title,
    required this.message,
    this.data = const {},
    required this.createdAt,
    this.isRead = false,
  });

  /// Creates notification from JSON
  factory EnrollmentNotification.fromJson(Map<String, dynamic> json) {
    return EnrollmentNotification(
      id: json['id'] as String,
      userId: json['userId'] as String,
      courseId: json['courseId'] as String,
      type: EnrollmentNotificationType.values.firstWhere(
        (t) => t.value == json['type'],
        orElse: () => EnrollmentNotificationType.enrollmentConfirmation,
      ),
      title: json['title'] as String,
      message: json['message'] as String,
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  /// Converts notification to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'courseId': courseId,
      'type': type.value,
      'title': title,
      'message': message,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
    };
  }

  /// Creates a copy with updated fields
  EnrollmentNotification copyWith({
    String? id,
    String? userId,
    String? courseId,
    EnrollmentNotificationType? type,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return EnrollmentNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      courseId: courseId ?? this.courseId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}

/// Service for managing enrollment notifications
class EnrollmentNotificationService {
  final Logger _logger;

  EnrollmentNotificationService({Logger? logger}) : _logger = logger ?? Logger();

  /// Creates an enrollment confirmation notification
  EnrollmentNotification createEnrollmentConfirmation({
    required String userId,
    required Course course,
  }) {
    return EnrollmentNotification(
      id: _generateNotificationId(),
      userId: userId,
      courseId: course.id,
      type: EnrollmentNotificationType.enrollmentConfirmation,
      title: 'Enrollment Confirmed',
      message: 'You have successfully enrolled in "${course.title}". '
               'The course starts on ${_formatDate(course.createdAt)} and has '
               '${course.duration} hours of content.',
      data: {
        'courseTitle': course.title,
        'instructorId': course.instructorId,
        'enrolledCount': course.enrolledStudents.length,
        'maxEnrollment': course.maxEnrollment,
      },
      createdAt: DateTime.now(),
    );
  }

  /// Creates a course capacity warning notification
  EnrollmentNotification createCapacityWarning({
    required String userId,
    required Course course,
  }) {
    final availableSpots = course.availableSpots;
    return EnrollmentNotification(
      id: _generateNotificationId(),
      userId: userId,
      courseId: course.id,
      type: EnrollmentNotificationType.courseCapacityWarning,
      title: 'Course Filling Up',
      message: 'The course "${course.title}" is filling up quickly! '
               'Only $availableSpots spots remaining out of ${course.maxEnrollment}. '
               'Enroll now to secure your place.',
      data: {
        'courseTitle': course.title,
        'availableSpots': availableSpots,
        'maxEnrollment': course.maxEnrollment,
        'enrollmentPercentage': course.enrollmentPercentage,
      },
      createdAt: DateTime.now(),
    );
  }

  /// Creates a course full notification
  EnrollmentNotification createCourseFull({
    required String userId,
    required Course course,
  }) {
    return EnrollmentNotification(
      id: _generateNotificationId(),
      userId: userId,
      courseId: course.id,
      type: EnrollmentNotificationType.courseFull,
      title: 'Course Full',
      message: 'The course "${course.title}" is now full. '
               'You can join the waitlist to be notified if a spot becomes available.',
      data: {
        'courseTitle': course.title,
        'maxEnrollment': course.maxEnrollment,
        'waitlistAvailable': true,
      },
      createdAt: DateTime.now(),
    );
  }

  /// Creates an enrollment reminder notification
  EnrollmentNotification createEnrollmentReminder({
    required String userId,
    required Course course,
    required DateTime reminderDate,
  }) {
    return EnrollmentNotification(
      id: _generateNotificationId(),
      userId: userId,
      courseId: course.id,
      type: EnrollmentNotificationType.enrollmentReminder,
      title: 'Course Starting Soon',
      message: 'Your enrolled course "${course.title}" is starting on '
               '${_formatDate(reminderDate)}. Make sure you\'re prepared!',
      data: {
        'courseTitle': course.title,
        'startDate': reminderDate.toIso8601String(),
        'instructorId': course.instructorId,
      },
      createdAt: DateTime.now(),
    );
  }

  /// Creates a waitlist update notification
  EnrollmentNotification createWaitlistUpdate({
    required String userId,
    required Course course,
    required int waitlistPosition,
  }) {
    return EnrollmentNotification(
      id: _generateNotificationId(),
      userId: userId,
      courseId: course.id,
      type: EnrollmentNotificationType.waitlistUpdate,
      title: 'Waitlist Update',
      message: 'You are #$waitlistPosition on the waitlist for "${course.title}". '
               'We\'ll notify you if a spot becomes available.',
      data: {
        'courseTitle': course.title,
        'waitlistPosition': waitlistPosition,
        'maxEnrollment': course.maxEnrollment,
      },
      createdAt: DateTime.now(),
    );
  }

  /// Creates a course status change notification
  EnrollmentNotification createCourseStatusChange({
    required String userId,
    required Course course,
    required CourseStatus oldStatus,
    required CourseStatus newStatus,
  }) {
    String message;
    switch (newStatus) {
      case CourseStatus.published:
        message = 'The course "${course.title}" is now available for enrollment!';
        break;
      case CourseStatus.suspended:
        message = 'The course "${course.title}" has been temporarily suspended.';
        break;
      case CourseStatus.archived:
        message = 'The course "${course.title}" has been archived and is no longer available.';
        break;
      case CourseStatus.draft:
        message = 'The course "${course.title}" is being updated and is temporarily unavailable.';
        break;
    }

    return EnrollmentNotification(
      id: _generateNotificationId(),
      userId: userId,
      courseId: course.id,
      type: EnrollmentNotificationType.courseStatusChange,
      title: 'Course Status Update',
      message: message,
      data: {
        'courseTitle': course.title,
        'oldStatus': oldStatus.value,
        'newStatus': newStatus.value,
      },
      createdAt: DateTime.now(),
    );
  }

  /// Sends enrollment confirmation notifications to all enrolled students
  Future<Result<List<EnrollmentNotification>>> sendEnrollmentConfirmations({
    required Course course,
    required List<User> enrolledStudents,
  }) async {
    try {
      _logger.info('Sending enrollment confirmations for course ${course.id}');

      final notifications = <EnrollmentNotification>[];

      for (final student in enrolledStudents) {
        final notification = createEnrollmentConfirmation(
          userId: student.id,
          course: course,
        );
        notifications.add(notification);
        
        // In a real implementation, you would send this notification
        // via push notification, email, or in-app notification system
        await _sendNotification(notification);
      }

      _logger.info('Sent ${notifications.length} enrollment confirmations');
      return Result.success(notifications);
    } catch (e) {
      _logger.error('Error sending enrollment confirmations: $e');
      return Result.error('Failed to send enrollment confirmations: ${e.toString()}');
    }
  }

  /// Sends capacity warning notifications
  Future<Result<void>> sendCapacityWarnings({
    required Course course,
    required List<User> interestedUsers,
  }) async {
    try {
      _logger.info('Sending capacity warnings for course ${course.id}');

      if (!course.isNearlyFull) {
        return Result.success(null);
      }

      for (final user in interestedUsers) {
        if (!course.isStudentEnrolled(user.id)) {
          final notification = createCapacityWarning(
            userId: user.id,
            course: course,
          );
          await _sendNotification(notification);
        }
      }

      _logger.info('Sent capacity warnings for course ${course.id}');
      return Result.success(null);
    } catch (e) {
      _logger.error('Error sending capacity warnings: $e');
      return Result.error('Failed to send capacity warnings: ${e.toString()}');
    }
  }

  /// Sends course full notifications
  Future<Result<void>> sendCourseFullNotifications({
    required Course course,
    required List<User> waitlistedUsers,
  }) async {
    try {
      _logger.info('Sending course full notifications for course ${course.id}');

      for (final user in waitlistedUsers) {
        final notification = createCourseFull(
          userId: user.id,
          course: course,
        );
        await _sendNotification(notification);
      }

      _logger.info('Sent course full notifications for course ${course.id}');
      return Result.success(null);
    } catch (e) {
      _logger.error('Error sending course full notifications: $e');
      return Result.error('Failed to send course full notifications: ${e.toString()}');
    }
  }

  /// Sends enrollment reminders
  Future<Result<void>> sendEnrollmentReminders({
    required Course course,
    required List<User> enrolledStudents,
    required DateTime reminderDate,
  }) async {
    try {
      _logger.info('Sending enrollment reminders for course ${course.id}');

      for (final student in enrolledStudents) {
        final notification = createEnrollmentReminder(
          userId: student.id,
          course: course,
          reminderDate: reminderDate,
        );
        await _sendNotification(notification);
      }

      _logger.info('Sent enrollment reminders for course ${course.id}');
      return Result.success(null);
    } catch (e) {
      _logger.error('Error sending enrollment reminders: $e');
      return Result.error('Failed to send enrollment reminders: ${e.toString()}');
    }
  }

  /// Generates a unique notification ID
  String _generateNotificationId() {
    return 'notif_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(6)}';
  }

  /// Generates a random string
  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(length, (index) => chars[DateTime.now().millisecond % chars.length]).join();
  }

  /// Formats a date for display
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Sends a notification (placeholder implementation)
  Future<void> _sendNotification(EnrollmentNotification notification) async {
    // In a real implementation, this would:
    // 1. Save the notification to the database
    // 2. Send push notification if user has enabled them
    // 3. Send email notification if configured
    // 4. Update in-app notification center
    
    _logger.info('Sending notification: ${notification.title} to user ${notification.userId}');
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Gets notification analytics
  Map<String, dynamic> getNotificationAnalytics({
    required List<EnrollmentNotification> notifications,
  }) {
    final typeCount = <String, int>{};
    final readCount = notifications.where((n) => n.isRead).length;
    final unreadCount = notifications.length - readCount;

    for (final notification in notifications) {
      typeCount[notification.type.value] = (typeCount[notification.type.value] ?? 0) + 1;
    }

    return {
      'totalNotifications': notifications.length,
      'readNotifications': readCount,
      'unreadNotifications': unreadCount,
      'readRate': notifications.isEmpty ? 0.0 : (readCount / notifications.length) * 100,
      'notificationsByType': typeCount,
      'recentNotifications': notifications
          .where((n) => n.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 7))))
          .length,
    };
  }
}