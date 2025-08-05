import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/result.dart';
import '../core/logger.dart';
import '../modules/course.dart';
import '../modules/user.dart';
import '../services/enrollment_notification_service.dart';

/// State class for enrollment notifications
class EnrollmentNotificationState {
  final List<EnrollmentNotification> notifications;
  final Map<String, List<EnrollmentNotification>> notificationsByUser;
  final Map<String, List<EnrollmentNotification>> notificationsByCourse;
  final bool isLoading;
  final String? error;
  final int unreadCount;

  const EnrollmentNotificationState({
    this.notifications = const [],
    this.notificationsByUser = const {},
    this.notificationsByCourse = const {},
    this.isLoading = false,
    this.error,
    this.unreadCount = 0,
  });

  EnrollmentNotificationState copyWith({
    List<EnrollmentNotification>? notifications,
    Map<String, List<EnrollmentNotification>>? notificationsByUser,
    Map<String, List<EnrollmentNotification>>? notificationsByCourse,
    bool? isLoading,
    String? error,
    int? unreadCount,
    bool clearError = false,
  }) {
    return EnrollmentNotificationState(
      notifications: notifications ?? this.notifications,
      notificationsByUser: notificationsByUser ?? this.notificationsByUser,
      notificationsByCourse: notificationsByCourse ?? this.notificationsByCourse,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

/// Provider for enrollment notification service
final enrollmentNotificationServiceProvider = Provider<EnrollmentNotificationService>((ref) {
  return EnrollmentNotificationService();
});

/// Provider for enrollment notification state management
class EnrollmentNotificationProvider extends StateNotifier<EnrollmentNotificationState> {
  final EnrollmentNotificationService _notificationService;
  final Logger _logger;

  EnrollmentNotificationProvider({
    required EnrollmentNotificationService notificationService,
    Logger? logger,
  }) : _notificationService = notificationService,
       _logger = logger ?? Logger(),
       super(const EnrollmentNotificationState());

  /// Sends enrollment confirmation notifications
  Future<Result<void>> sendEnrollmentConfirmations({
    required Course course,
    required List<User> enrolledStudents,
  }) async {
    try {
      _logger.info('Sending enrollment confirmations for course ${course.id}');
      state = state.copyWith(isLoading: true, clearError: true);

      final result = await _notificationService.sendEnrollmentConfirmations(
        course: course,
        enrolledStudents: enrolledStudents,
      );

      if (result.isSuccess) {
        final notifications = result.data!;
        await _addNotifications(notifications);
        
        _logger.info('Successfully sent ${notifications.length} enrollment confirmations');
        state = state.copyWith(isLoading: false);
        return Result.success(null);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.error,
        );
        return Result.error(result.error!);
      }
    } catch (e) {
      _logger.error('Error sending enrollment confirmations: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to send enrollment confirmations: ${e.toString()}',
      );
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
      state = state.copyWith(isLoading: true, clearError: true);

      final result = await _notificationService.sendCapacityWarnings(
        course: course,
        interestedUsers: interestedUsers,
      );

      if (result.isSuccess) {
        _logger.info('Successfully sent capacity warnings');
        state = state.copyWith(isLoading: false);
        return Result.success(null);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.error,
        );
        return Result.error(result.error!);
      }
    } catch (e) {
      _logger.error('Error sending capacity warnings: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to send capacity warnings: ${e.toString()}',
      );
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
      state = state.copyWith(isLoading: true, clearError: true);

      final result = await _notificationService.sendCourseFullNotifications(
        course: course,
        waitlistedUsers: waitlistedUsers,
      );

      if (result.isSuccess) {
        _logger.info('Successfully sent course full notifications');
        state = state.copyWith(isLoading: false);
        return Result.success(null);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.error,
        );
        return Result.error(result.error!);
      }
    } catch (e) {
      _logger.error('Error sending course full notifications: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to send course full notifications: ${e.toString()}',
      );
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
      state = state.copyWith(isLoading: true, clearError: true);

      final result = await _notificationService.sendEnrollmentReminders(
        course: course,
        enrolledStudents: enrolledStudents,
        reminderDate: reminderDate,
      );

      if (result.isSuccess) {
        _logger.info('Successfully sent enrollment reminders');
        state = state.copyWith(isLoading: false);
        return Result.success(null);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.error,
        );
        return Result.error(result.error!);
      }
    } catch (e) {
      _logger.error('Error sending enrollment reminders: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to send enrollment reminders: ${e.toString()}',
      );
      return Result.error('Failed to send enrollment reminders: ${e.toString()}');
    }
  }

  /// Creates and adds a single notification
  Future<void> createNotification({
    required String userId,
    required Course course,
    required EnrollmentNotificationType type,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      EnrollmentNotification notification;

      switch (type) {
        case EnrollmentNotificationType.enrollmentConfirmation:
          notification = _notificationService.createEnrollmentConfirmation(
            userId: userId,
            course: course,
          );
          break;
        case EnrollmentNotificationType.courseCapacityWarning:
          notification = _notificationService.createCapacityWarning(
            userId: userId,
            course: course,
          );
          break;
        case EnrollmentNotificationType.courseFull:
          notification = _notificationService.createCourseFull(
            userId: userId,
            course: course,
          );
          break;
        case EnrollmentNotificationType.enrollmentReminder:
          final reminderDate = additionalData?['reminderDate'] as DateTime? ?? DateTime.now();
          notification = _notificationService.createEnrollmentReminder(
            userId: userId,
            course: course,
            reminderDate: reminderDate,
          );
          break;
        case EnrollmentNotificationType.waitlistUpdate:
          final position = additionalData?['waitlistPosition'] as int? ?? 1;
          notification = _notificationService.createWaitlistUpdate(
            userId: userId,
            course: course,
            waitlistPosition: position,
          );
          break;
        case EnrollmentNotificationType.courseStatusChange:
          final oldStatus = additionalData?['oldStatus'] as CourseStatus? ?? CourseStatus.draft;
          final newStatus = additionalData?['newStatus'] as CourseStatus? ?? CourseStatus.published;
          notification = _notificationService.createCourseStatusChange(
            userId: userId,
            course: course,
            oldStatus: oldStatus,
            newStatus: newStatus,
          );
          break;
        default:
          notification = _notificationService.createEnrollmentConfirmation(
            userId: userId,
            course: course,
          );
      }

      await _addNotifications([notification]);
      _logger.info('Created notification: ${notification.type.value} for user $userId');
    } catch (e) {
      _logger.error('Error creating notification: $e');
    }
  }

  /// Gets notifications for a specific user
  List<EnrollmentNotification> getNotificationsForUser(String userId) {
    return state.notificationsByUser[userId] ?? [];
  }

  /// Gets notifications for a specific course
  List<EnrollmentNotification> getNotificationsForCourse(String courseId) {
    return state.notificationsByCourse[courseId] ?? [];
  }

  /// Marks a notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final notifications = state.notifications.map((notification) {
        if (notification.id == notificationId && !notification.isRead) {
          return notification.copyWith(isRead: true);
        }
        return notification;
      }).toList();

      await _updateNotifications(notifications);
      _logger.info('Marked notification $notificationId as read');
    } catch (e) {
      _logger.error('Error marking notification as read: $e');
    }
  }

  /// Marks all notifications for a user as read
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final notifications = state.notifications.map((notification) {
        if (notification.userId == userId && !notification.isRead) {
          return notification.copyWith(isRead: true);
        }
        return notification;
      }).toList();

      await _updateNotifications(notifications);
      _logger.info('Marked all notifications as read for user $userId');
    } catch (e) {
      _logger.error('Error marking all notifications as read: $e');
    }
  }

  /// Deletes a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final notifications = state.notifications
          .where((notification) => notification.id != notificationId)
          .toList();

      await _updateNotifications(notifications);
      _logger.info('Deleted notification $notificationId');
    } catch (e) {
      _logger.error('Error deleting notification: $e');
    }
  }

  /// Gets notification analytics
  Map<String, dynamic> getNotificationAnalytics() {
    return _notificationService.getNotificationAnalytics(
      notifications: state.notifications,
    );
  }

  /// Clears all notifications for a user
  Future<void> clearNotificationsForUser(String userId) async {
    try {
      final notifications = state.notifications
          .where((notification) => notification.userId != userId)
          .toList();

      await _updateNotifications(notifications);
      _logger.info('Cleared all notifications for user $userId');
    } catch (e) {
      _logger.error('Error clearing notifications for user: $e');
    }
  }

  /// Gets unread notification count for a user
  int getUnreadCountForUser(String userId) {
    return state.notificationsByUser[userId]
            ?.where((notification) => !notification.isRead)
            .length ?? 0;
  }

  /// Filters notifications by type
  List<EnrollmentNotification> getNotificationsByType(EnrollmentNotificationType type) {
    return state.notifications
        .where((notification) => notification.type == type)
        .toList();
  }

  /// Gets recent notifications (last 7 days)
  List<EnrollmentNotification> getRecentNotifications({int days = 7}) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return state.notifications
        .where((notification) => notification.createdAt.isAfter(cutoffDate))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Adds notifications to the state
  Future<void> _addNotifications(List<EnrollmentNotification> notifications) async {
    final updatedNotifications = [...state.notifications, ...notifications];
    await _updateNotifications(updatedNotifications);
  }

  /// Updates the notifications state and rebuilds indexes
  Future<void> _updateNotifications(List<EnrollmentNotification> notifications) async {
    // Sort notifications by creation date (newest first)
    notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Build user index
    final notificationsByUser = <String, List<EnrollmentNotification>>{};
    for (final notification in notifications) {
      notificationsByUser[notification.userId] = 
          notificationsByUser[notification.userId] ?? [];
      notificationsByUser[notification.userId]!.add(notification);
    }

    // Build course index
    final notificationsByCourse = <String, List<EnrollmentNotification>>{};
    for (final notification in notifications) {
      notificationsByCourse[notification.courseId] = 
          notificationsByCourse[notification.courseId] ?? [];
      notificationsByCourse[notification.courseId]!.add(notification);
    }

    // Calculate unread count
    final unreadCount = notifications.where((n) => !n.isRead).length;

    state = state.copyWith(
      notifications: notifications,
      notificationsByUser: notificationsByUser,
      notificationsByCourse: notificationsByCourse,
      unreadCount: unreadCount,
      clearError: true,
    );
  }

  /// Clears error state
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Refreshes all notifications
  Future<void> refreshNotifications() async {
    // In a real implementation, this would fetch notifications from a database
    // For now, we'll just clear the error state
    state = state.copyWith(clearError: true);
  }
}

/// Provider for enrollment notification state notifier
final enrollmentNotificationProvider = StateNotifierProvider<EnrollmentNotificationProvider, EnrollmentNotificationState>((ref) {
  final notificationService = ref.read(enrollmentNotificationServiceProvider);
  return EnrollmentNotificationProvider(notificationService: notificationService);
});

/// Provider for getting notifications for a specific user
final userNotificationsProvider = Provider.family<List<EnrollmentNotification>, String>((ref, userId) {
  final notificationState = ref.watch(enrollmentNotificationProvider);
  return notificationState.notificationsByUser[userId] ?? [];
});

/// Provider for getting unread notification count for a user
final unreadNotificationCountProvider = Provider.family<int, String>((ref, userId) {
  final notifications = ref.watch(userNotificationsProvider(userId));
  return notifications.where((notification) => !notification.isRead).length;
});

/// Provider for getting recent notifications
final recentNotificationsProvider = Provider<List<EnrollmentNotification>>((ref) {
  final notificationState = ref.watch(enrollmentNotificationProvider);
  final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
  return notificationState.notifications
      .where((notification) => notification.createdAt.isAfter(cutoffDate))
      .toList();
});