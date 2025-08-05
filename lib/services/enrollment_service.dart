import '../core/result.dart';
import '../core/logger.dart';
import '../modules/course.dart';
import '../modules/user.dart';
import '../repositories/course_repository.dart';
import '../repositories/user_repository.dart';

/// Enum representing different enrollment statuses
enum EnrollmentStatus {
  enrolled('enrolled'),
  notEnrolled('not_enrolled'),
  waitlisted('waitlisted'),
  full('full'),
  unavailable('unavailable');

  const EnrollmentStatus(this.value);
  final String value;
}

/// Represents enrollment information for a course
class EnrollmentInfo {
  final String courseId;
  final String courseName;
  final EnrollmentStatus status;
  final int enrolledCount;
  final int maxEnrollment;
  final int availableSpots;
  final bool canEnroll;
  final String? message;

  const EnrollmentInfo({
    required this.courseId,
    required this.courseName,
    required this.status,
    required this.enrolledCount,
    required this.maxEnrollment,
    required this.availableSpots,
    required this.canEnroll,
    this.message,
  });

  /// Creates enrollment info from a course and user context
  factory EnrollmentInfo.fromCourse(Course course, {String? userId}) {
    final isEnrolled = userId != null && course.isStudentEnrolled(userId);
    final canEnroll = course.canAcceptEnrollments && !isEnrolled;
    
    EnrollmentStatus status;
    String? message;
    
    if (isEnrolled) {
      status = EnrollmentStatus.enrolled;
      message = 'You are enrolled in this course';
    } else if (!course.isPublished) {
      status = EnrollmentStatus.unavailable;
      message = 'Course is not available for enrollment';
    } else if (course.isFull) {
      status = EnrollmentStatus.full;
      message = 'Course is full';
    } else {
      status = EnrollmentStatus.notEnrolled;
      message = 'Available for enrollment';
    }

    return EnrollmentInfo(
      courseId: course.id,
      courseName: course.title,
      status: status,
      enrolledCount: course.enrolledStudents.length,
      maxEnrollment: course.maxEnrollment,
      availableSpots: course.availableSpots,
      canEnroll: canEnroll,
      message: message,
    );
  }

  /// Returns enrollment percentage
  double get enrollmentPercentage => (enrolledCount / maxEnrollment) * 100;

  /// Checks if course is nearly full (>80% enrolled)
  bool get isNearlyFull => enrollmentPercentage > 80;
}

/// Service for managing course enrollments
class EnrollmentService {
  final CourseRepository _courseRepository;
  final UserRepository _userRepository;
  final Logger _logger;

  EnrollmentService({
    required CourseRepository courseRepository,
    required UserRepository userRepository,
    Logger? logger,
  }) : _courseRepository = courseRepository,
       _userRepository = userRepository,
       _logger = logger ?? Logger();

  /// Enrolls a student in a course with validation
  Future<Result<void>> enrollStudent({
    required String courseId,
    required String studentId,
  }) async {
    try {
      _logger.info('Attempting to enroll student $studentId in course $courseId');

      // Get course details
      final courseResult = await _courseRepository.getCourseById(courseId);
      if (courseResult.isError) {
        return Result.error('Course not found: ${courseResult.error}');
      }
      final course = courseResult.data!;

      // Get student details
      final studentResult = await _userRepository.getUserById(studentId);
      if (studentResult.isError) {
        return Result.error('Student not found: ${studentResult.error}');
      }
      final student = studentResult.data!;

      // Validate enrollment eligibility
      final validationResult = _validateEnrollment(course, student);
      if (validationResult.isError) {
        return validationResult;
      }

      // Perform enrollment
      final enrollResult = await _courseRepository.enrollStudent(courseId, studentId);
      if (enrollResult.isError) {
        return enrollResult;
      }

      _logger.info('Successfully enrolled student $studentId in course $courseId');
      return Result.success(null);
    } catch (e) {
      _logger.error('Error enrolling student: $e');
      return Result.error('Failed to enroll student: ${e.toString()}');
    }
  }

  /// Unenrolls a student from a course
  Future<Result<void>> unenrollStudent({
    required String courseId,
    required String studentId,
  }) async {
    try {
      _logger.info('Attempting to unenroll student $studentId from course $courseId');

      // Check if student is enrolled
      final enrollmentResult = await _courseRepository.isStudentEnrolled(courseId, studentId);
      if (enrollmentResult.isError) {
        return Result.error('Failed to check enrollment status: ${enrollmentResult.error}');
      }

      if (!enrollmentResult.data!) {
        return Result.error('Student is not enrolled in this course');
      }

      // Perform unenrollment
      final unenrollResult = await _courseRepository.unenrollStudent(courseId, studentId);
      if (unenrollResult.isError) {
        return unenrollResult;
      }

      _logger.info('Successfully unenrolled student $studentId from course $courseId');
      return Result.success(null);
    } catch (e) {
      _logger.error('Error unenrolling student: $e');
      return Result.error('Failed to unenroll student: ${e.toString()}');
    }
  }

  /// Gets enrollment information for a course
  Future<Result<EnrollmentInfo>> getEnrollmentInfo({
    required String courseId,
    String? userId,
  }) async {
    try {
      _logger.info('Getting enrollment info for course $courseId');

      final courseResult = await _courseRepository.getCourseById(courseId);
      if (courseResult.isError) {
        return Result.error('Course not found: ${courseResult.error}');
      }

      final course = courseResult.data!;
      final enrollmentInfo = EnrollmentInfo.fromCourse(course, userId: userId);

      return Result.success(enrollmentInfo);
    } catch (e) {
      _logger.error('Error getting enrollment info: $e');
      return Result.error('Failed to get enrollment info: ${e.toString()}');
    }
  }

  /// Gets enrolled students for a course (instructor view)
  Future<Result<List<User>>> getEnrolledStudents(String courseId) async {
    try {
      _logger.info('Getting enrolled students for course $courseId');

      return await _courseRepository.getEnrolledStudents(courseId);
    } catch (e) {
      _logger.error('Error getting enrolled students: $e');
      return Result.error('Failed to get enrolled students: ${e.toString()}');
    }
  }

  /// Gets enrollment statistics for a course
  Future<Result<Map<String, dynamic>>> getEnrollmentStatistics(String courseId) async {
    try {
      _logger.info('Getting enrollment statistics for course $courseId');

      final statsResult = await _courseRepository.getCourseStatistics(courseId);
      if (statsResult.isError) {
        return statsResult;
      }

      final stats = statsResult.data!;
      
      // Add additional calculated statistics
      final enhancedStats = Map<String, dynamic>.from(stats);
      enhancedStats['isNearlyFull'] = stats['enrollmentPercentage']! > 80;
      enhancedStats['isFull'] = stats['availableSpots']! <= 0;
      enhancedStats['enrollmentRate'] = stats['enrollmentPercentage']! / 100;

      return Result.success(enhancedStats);
    } catch (e) {
      _logger.error('Error getting enrollment statistics: $e');
      return Result.error('Failed to get enrollment statistics: ${e.toString()}');
    }
  }

  /// Gets courses a student is enrolled in
  Future<Result<List<Course>>> getStudentEnrolledCourses({
    required String studentId,
    int limit = 10,
  }) async {
    try {
      _logger.info('Getting enrolled courses for student $studentId');

      return await _courseRepository.getEnrolledCourses(
        studentId: studentId,
        limit: limit,
      );
    } catch (e) {
      _logger.error('Error getting student enrolled courses: $e');
      return Result.error('Failed to get enrolled courses: ${e.toString()}');
    }
  }

  /// Checks if a student can enroll in a course
  Future<Result<bool>> canStudentEnroll({
    required String courseId,
    required String studentId,
  }) async {
    try {
      _logger.info('Checking if student $studentId can enroll in course $courseId');

      final courseResult = await _courseRepository.getCourseById(courseId);
      if (courseResult.isError) {
        return Result.error('Course not found: ${courseResult.error}');
      }

      final course = courseResult.data!;
      final canEnroll = course.canAcceptEnrollments && !course.isStudentEnrolled(studentId);

      return Result.success(canEnroll);
    } catch (e) {
      _logger.error('Error checking enrollment eligibility: $e');
      return Result.error('Failed to check enrollment eligibility: ${e.toString()}');
    }
  }

  /// Validates enrollment eligibility
  Result<void> _validateEnrollment(Course course, User student) {
    final errors = <String>[];

    // Check if course is published
    if (!course.isPublished) {
      errors.add('Course is not available for enrollment');
    }

    // Check if course is full
    if (course.isFull) {
      errors.add('Course is full');
    }

    // Check if student is already enrolled
    if (course.isStudentEnrolled(student.id)) {
      errors.add('Student is already enrolled in this course');
    }

    // Check if student role is valid
    if (student.role != UserRole.student) {
      errors.add('Only students can enroll in courses');
    }

    if (errors.isNotEmpty) {
      return Result.error('Enrollment validation failed: ${errors.join(', ')}');
    }

    return Result.success(null);
  }

  /// Gets enrollment capacity information for multiple courses
  Future<Result<Map<String, EnrollmentInfo>>> getBulkEnrollmentInfo({
    required List<String> courseIds,
    String? userId,
  }) async {
    try {
      _logger.info('Getting bulk enrollment info for ${courseIds.length} courses');

      final enrollmentInfoMap = <String, EnrollmentInfo>{};

      for (final courseId in courseIds) {
        final infoResult = await getEnrollmentInfo(courseId: courseId, userId: userId);
        if (infoResult.isSuccess) {
          enrollmentInfoMap[courseId] = infoResult.data!;
        }
      }

      return Result.success(enrollmentInfoMap);
    } catch (e) {
      _logger.error('Error getting bulk enrollment info: $e');
      return Result.error('Failed to get bulk enrollment info: ${e.toString()}');
    }
  }

  /// Transfers a student from one course to another
  Future<Result<void>> transferStudent({
    required String fromCourseId,
    required String toCourseId,
    required String studentId,
  }) async {
    try {
      _logger.info('Transferring student $studentId from course $fromCourseId to $toCourseId');

      // Validate target course enrollment eligibility
      final canEnrollResult = await canStudentEnroll(
        courseId: toCourseId,
        studentId: studentId,
      );
      if (canEnrollResult.isError) {
        return Result.error('Cannot transfer: ${canEnrollResult.error}');
      }
      if (!canEnrollResult.data!) {
        return Result.error('Student cannot enroll in target course');
      }

      // Enroll in new course first
      final enrollResult = await enrollStudent(
        courseId: toCourseId,
        studentId: studentId,
      );
      if (enrollResult.isError) {
        return Result.error('Failed to enroll in target course: ${enrollResult.error}');
      }

      // Unenroll from old course
      final unenrollResult = await unenrollStudent(
        courseId: fromCourseId,
        studentId: studentId,
      );
      if (unenrollResult.isError) {
        // Rollback enrollment in new course
        await unenrollStudent(courseId: toCourseId, studentId: studentId);
        return Result.error('Failed to unenroll from source course: ${unenrollResult.error}');
      }

      _logger.info('Successfully transferred student $studentId');
      return Result.success(null);
    } catch (e) {
      _logger.error('Error transferring student: $e');
      return Result.error('Failed to transfer student: ${e.toString()}');
    }
  }
}