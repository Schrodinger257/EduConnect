import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/result.dart';
import '../core/logger.dart';
import '../modules/course.dart';
import '../modules/user.dart';
import '../services/enrollment_service.dart';
import '../repositories/firebase_course_repository.dart';
import '../repositories/firebase_user_repository.dart';

/// State class for enrollment management
class EnrollmentState {
  final Map<String, EnrollmentInfo> enrollmentInfoCache;
  final List<Course> enrolledCourses;
  final List<User> enrolledStudents;
  final Map<String, dynamic> enrollmentStatistics;
  final bool isLoading;
  final String? error;

  const EnrollmentState({
    this.enrollmentInfoCache = const {},
    this.enrolledCourses = const [],
    this.enrolledStudents = const [],
    this.enrollmentStatistics = const {},
    this.isLoading = false,
    this.error,
  });

  EnrollmentState copyWith({
    Map<String, EnrollmentInfo>? enrollmentInfoCache,
    List<Course>? enrolledCourses,
    List<User>? enrolledStudents,
    Map<String, dynamic>? enrollmentStatistics,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return EnrollmentState(
      enrollmentInfoCache: enrollmentInfoCache ?? this.enrollmentInfoCache,
      enrolledCourses: enrolledCourses ?? this.enrolledCourses,
      enrolledStudents: enrolledStudents ?? this.enrolledStudents,
      enrollmentStatistics: enrollmentStatistics ?? this.enrollmentStatistics,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Provider for enrollment service
final enrollmentServiceProvider = Provider<EnrollmentService>((ref) {
  return EnrollmentService(
    courseRepository: FirebaseCourseRepository(),
    userRepository: FirebaseUserRepository(),
    logger: Logger(),
  );
});

/// Provider for enrollment state management
class EnrollmentProvider extends StateNotifier<EnrollmentState> {
  final EnrollmentService _enrollmentService;
  final Logger _logger;

  EnrollmentProvider({
    required EnrollmentService enrollmentService,
    Logger? logger,
  }) : _enrollmentService = enrollmentService,
       _logger = logger ?? Logger(),
       super(const EnrollmentState());

  /// Enrolls a student in a course
  Future<Result<void>> enrollStudent({
    required String courseId,
    required String studentId,
  }) async {
    try {
      _logger.info('Enrolling student $studentId in course $courseId');
      state = state.copyWith(isLoading: true, clearError: true);

      final result = await _enrollmentService.enrollStudent(
        courseId: courseId,
        studentId: studentId,
      );

      if (result.isSuccess) {
        // Refresh enrollment info for this course
        await _refreshEnrollmentInfo(courseId, studentId);
        
        // Refresh enrolled courses for student
        await loadStudentEnrolledCourses(studentId);
        
        _logger.info('Successfully enrolled student $studentId in course $courseId');
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.error,
        );
      }

      return result;
    } catch (e) {
      _logger.error('Error in enrollStudent: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to enroll student: ${e.toString()}',
      );
      return Result.error('Failed to enroll student: ${e.toString()}');
    }
  }

  /// Unenrolls a student from a course
  Future<Result<void>> unenrollStudent({
    required String courseId,
    required String studentId,
  }) async {
    try {
      _logger.info('Unenrolling student $studentId from course $courseId');
      state = state.copyWith(isLoading: true, clearError: true);

      final result = await _enrollmentService.unenrollStudent(
        courseId: courseId,
        studentId: studentId,
      );

      if (result.isSuccess) {
        // Refresh enrollment info for this course
        await _refreshEnrollmentInfo(courseId, studentId);
        
        // Refresh enrolled courses for student
        await loadStudentEnrolledCourses(studentId);
        
        _logger.info('Successfully unenrolled student $studentId from course $courseId');
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.error,
        );
      }

      return result;
    } catch (e) {
      _logger.error('Error in unenrollStudent: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to unenroll student: ${e.toString()}',
      );
      return Result.error('Failed to unenroll student: ${e.toString()}');
    }
  }

  /// Loads enrollment information for a course
  Future<void> loadEnrollmentInfo({
    required String courseId,
    String? userId,
  }) async {
    try {
      _logger.info('Loading enrollment info for course $courseId');

      final result = await _enrollmentService.getEnrollmentInfo(
        courseId: courseId,
        userId: userId,
      );

      if (result.isSuccess) {
        final updatedCache = Map<String, EnrollmentInfo>.from(state.enrollmentInfoCache);
        updatedCache[courseId] = result.data!;
        
        state = state.copyWith(
          enrollmentInfoCache: updatedCache,
          isLoading: false,
          clearError: true,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.error,
        );
      }
    } catch (e) {
      _logger.error('Error loading enrollment info: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load enrollment info: ${e.toString()}',
      );
    }
  }

  /// Loads enrolled courses for a student
  Future<void> loadStudentEnrolledCourses(String studentId) async {
    try {
      _logger.info('Loading enrolled courses for student $studentId');
      state = state.copyWith(isLoading: true, clearError: true);

      final result = await _enrollmentService.getStudentEnrolledCourses(
        studentId: studentId,
      );

      if (result.isSuccess) {
        state = state.copyWith(
          enrolledCourses: result.data!,
          isLoading: false,
          clearError: true,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.error,
        );
      }
    } catch (e) {
      _logger.error('Error loading enrolled courses: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load enrolled courses: ${e.toString()}',
      );
    }
  }

  /// Loads enrolled students for a course (instructor view)
  Future<void> loadEnrolledStudents(String courseId) async {
    try {
      _logger.info('Loading enrolled students for course $courseId');
      state = state.copyWith(isLoading: true, clearError: true);

      final result = await _enrollmentService.getEnrolledStudents(courseId);

      if (result.isSuccess) {
        state = state.copyWith(
          enrolledStudents: result.data!,
          isLoading: false,
          clearError: true,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.error,
        );
      }
    } catch (e) {
      _logger.error('Error loading enrolled students: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load enrolled students: ${e.toString()}',
      );
    }
  }

  /// Loads enrollment statistics for a course
  Future<void> loadEnrollmentStatistics(String courseId) async {
    try {
      _logger.info('Loading enrollment statistics for course $courseId');

      final result = await _enrollmentService.getEnrollmentStatistics(courseId);

      if (result.isSuccess) {
        final updatedStats = Map<String, dynamic>.from(state.enrollmentStatistics);
        updatedStats[courseId] = result.data!;
        
        state = state.copyWith(
          enrollmentStatistics: updatedStats,
          clearError: true,
        );
      } else {
        state = state.copyWith(error: result.error);
      }
    } catch (e) {
      _logger.error('Error loading enrollment statistics: $e');
      state = state.copyWith(
        error: 'Failed to load enrollment statistics: ${e.toString()}',
      );
    }
  }

  /// Checks if a student can enroll in a course
  Future<bool> canStudentEnroll({
    required String courseId,
    required String studentId,
  }) async {
    try {
      final result = await _enrollmentService.canStudentEnroll(
        courseId: courseId,
        studentId: studentId,
      );
      return result.isSuccess ? result.data! : false;
    } catch (e) {
      _logger.error('Error checking enrollment eligibility: $e');
      return false;
    }
  }

  /// Gets enrollment info from cache or loads it
  EnrollmentInfo? getEnrollmentInfo(String courseId) {
    return state.enrollmentInfoCache[courseId];
  }

  /// Gets enrollment statistics from cache
  Map<String, dynamic>? getEnrollmentStatistics(String courseId) {
    return state.enrollmentStatistics[courseId];
  }

  /// Refreshes enrollment info for a course
  Future<void> _refreshEnrollmentInfo(String courseId, String? userId) async {
    await loadEnrollmentInfo(courseId: courseId, userId: userId);
  }

  /// Clears error state
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Refreshes all enrollment data
  Future<void> refreshAll({String? studentId, String? courseId}) async {
    if (studentId != null) {
      await loadStudentEnrolledCourses(studentId);
    }
    if (courseId != null) {
      await loadEnrolledStudents(courseId);
      await loadEnrollmentStatistics(courseId);
    }
  }

  /// Transfers a student between courses
  Future<Result<void>> transferStudent({
    required String fromCourseId,
    required String toCourseId,
    required String studentId,
  }) async {
    try {
      _logger.info('Transferring student $studentId from $fromCourseId to $toCourseId');
      state = state.copyWith(isLoading: true, clearError: true);

      final result = await _enrollmentService.transferStudent(
        fromCourseId: fromCourseId,
        toCourseId: toCourseId,
        studentId: studentId,
      );

      if (result.isSuccess) {
        // Refresh data for both courses
        await _refreshEnrollmentInfo(fromCourseId, studentId);
        await _refreshEnrollmentInfo(toCourseId, studentId);
        await loadStudentEnrolledCourses(studentId);
        
        _logger.info('Successfully transferred student $studentId');
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.error,
        );
      }

      return result;
    } catch (e) {
      _logger.error('Error transferring student: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to transfer student: ${e.toString()}',
      );
      return Result.error('Failed to transfer student: ${e.toString()}');
    }
  }
}

/// Provider for enrollment state notifier
final enrollmentProvider = StateNotifierProvider<EnrollmentProvider, EnrollmentState>((ref) {
  final enrollmentService = ref.read(enrollmentServiceProvider);
  return EnrollmentProvider(enrollmentService: enrollmentService);
});

/// Provider for getting enrollment info for a specific course
final courseEnrollmentInfoProvider = FutureProvider.family<EnrollmentInfo?, String>((ref, courseId) async {
  final enrollmentService = ref.read(enrollmentServiceProvider);
  final result = await enrollmentService.getEnrollmentInfo(courseId: courseId);
  return result.isSuccess ? result.data : null;
});

/// Provider for getting enrolled courses for a student
final studentEnrolledCoursesProvider = FutureProvider.family<List<Course>, String>((ref, studentId) async {
  final enrollmentService = ref.read(enrollmentServiceProvider);
  final result = await enrollmentService.getStudentEnrolledCourses(studentId: studentId);
  return result.isSuccess ? result.data! : [];
});

/// Provider for getting enrolled students for a course
final courseEnrolledStudentsProvider = FutureProvider.family<List<User>, String>((ref, courseId) async {
  final enrollmentService = ref.read(enrollmentServiceProvider);
  final result = await enrollmentService.getEnrolledStudents(courseId);
  return result.isSuccess ? result.data! : [];
});