import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/result.dart';
import '../modules/course.dart';
import '../modules/user.dart';

/// Abstract repository interface for course-related operations
abstract class CourseRepository {
  /// Retrieves a paginated list of courses
  Future<Result<List<Course>>> getCourses({
    int limit = 10,
    DocumentSnapshot? lastDocument,
    CourseStatus? status,
  });

  /// Retrieves courses for a specific instructor
  Future<Result<List<Course>>> getInstructorCourses({
    required String instructorId,
    int limit = 10,
    DocumentSnapshot? lastDocument,
  });

  /// Retrieves enrolled courses for a student
  Future<Result<List<Course>>> getEnrolledCourses({
    required String studentId,
    int limit = 10,
    DocumentSnapshot? lastDocument,
  });

  /// Retrieves a course by its ID
  Future<Result<Course>> getCourseById(String courseId);

  /// Creates a new course
  Future<Result<Course>> createCourse(Course course);

  /// Updates an existing course
  Future<Result<Course>> updateCourse(Course course);

  /// Deletes a course
  Future<Result<void>> deleteCourse(String courseId);

  /// Enrolls a student in a course
  Future<Result<void>> enrollStudent(String courseId, String studentId);

  /// Unenrolls a student from a course
  Future<Result<void>> unenrollStudent(String courseId, String studentId);

  /// Gets enrolled students for a course
  Future<Result<List<User>>> getEnrolledStudents(String courseId);

  /// Checks if a student is enrolled in a course
  Future<Result<bool>> isStudentEnrolled(String courseId, String studentId);

  /// Gets course enrollment statistics
  Future<Result<Map<String, int>>> getCourseStatistics(String courseId);

  /// Searches courses by title, description, or tags
  Future<Result<List<Course>>> searchCourses(String query);

  /// Gets courses by category
  Future<Result<List<Course>>> getCoursesByCategory(String category);

  /// Gets courses by status
  Future<Result<List<Course>>> getCoursesByStatus(CourseStatus status);

  /// Gets popular courses (sorted by enrollment)
  Future<Result<List<Course>>> getPopularCourses({int limit = 10});

  /// Gets recently created courses
  Future<Result<List<Course>>> getRecentCourses({int limit = 10});

  /// Updates course status
  Future<Result<Course>> updateCourseStatus(String courseId, CourseStatus status);

  /// Gets a stream of courses for real-time updates
  Stream<List<Course>> getCoursesStream({int limit = 10});

  /// Gets a stream of enrolled students for a course
  Stream<List<User>> getEnrolledStudentsStream(String courseId);

  /// Checks if enrollment is available for a course
  Future<Result<bool>> isEnrollmentAvailable(String courseId);

  /// Gets course categories
  Future<Result<List<String>>> getCourseCategories();
}