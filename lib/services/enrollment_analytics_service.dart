import '../core/result.dart';
import '../core/logger.dart';
import '../modules/course.dart';
import '../modules/user.dart';
import '../repositories/course_repository.dart';
import '../repositories/user_repository.dart';

/// Represents enrollment analytics data
class EnrollmentAnalytics {
  final String courseId;
  final String courseName;
  final int totalEnrollments;
  final int currentEnrollments;
  final int maxCapacity;
  final double enrollmentRate;
  final double completionRate;
  final Map<String, int> enrollmentsByMonth;
  final Map<String, int> enrollmentsByDepartment;
  final Map<String, int> enrollmentsByGrade;
  final List<EnrollmentTrend> trends;
  final DateTime generatedAt;

  const EnrollmentAnalytics({
    required this.courseId,
    required this.courseName,
    required this.totalEnrollments,
    required this.currentEnrollments,
    required this.maxCapacity,
    required this.enrollmentRate,
    required this.completionRate,
    required this.enrollmentsByMonth,
    required this.enrollmentsByDepartment,
    required this.enrollmentsByGrade,
    required this.trends,
    required this.generatedAt,
  });

  /// Converts analytics to JSON
  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'courseName': courseName,
      'totalEnrollments': totalEnrollments,
      'currentEnrollments': currentEnrollments,
      'maxCapacity': maxCapacity,
      'enrollmentRate': enrollmentRate,
      'completionRate': completionRate,
      'enrollmentsByMonth': enrollmentsByMonth,
      'enrollmentsByDepartment': enrollmentsByDepartment,
      'enrollmentsByGrade': enrollmentsByGrade,
      'trends': trends.map((t) => t.toJson()).toList(),
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  /// Creates analytics from JSON
  factory EnrollmentAnalytics.fromJson(Map<String, dynamic> json) {
    return EnrollmentAnalytics(
      courseId: json['courseId'] as String,
      courseName: json['courseName'] as String,
      totalEnrollments: json['totalEnrollments'] as int,
      currentEnrollments: json['currentEnrollments'] as int,
      maxCapacity: json['maxCapacity'] as int,
      enrollmentRate: json['enrollmentRate'] as double,
      completionRate: json['completionRate'] as double,
      enrollmentsByMonth: Map<String, int>.from(json['enrollmentsByMonth']),
      enrollmentsByDepartment: Map<String, int>.from(json['enrollmentsByDepartment']),
      enrollmentsByGrade: Map<String, int>.from(json['enrollmentsByGrade']),
      trends: (json['trends'] as List)
          .map((t) => EnrollmentTrend.fromJson(t))
          .toList(),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );
  }
}

/// Represents an enrollment trend data point
class EnrollmentTrend {
  final DateTime date;
  final int enrollments;
  final int unenrollments;
  final int netChange;

  const EnrollmentTrend({
    required this.date,
    required this.enrollments,
    required this.unenrollments,
    required this.netChange,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'enrollments': enrollments,
      'unenrollments': unenrollments,
      'netChange': netChange,
    };
  }

  factory EnrollmentTrend.fromJson(Map<String, dynamic> json) {
    return EnrollmentTrend(
      date: DateTime.parse(json['date'] as String),
      enrollments: json['enrollments'] as int,
      unenrollments: json['unenrollments'] as int,
      netChange: json['netChange'] as int,
    );
  }
}

/// Represents system-wide enrollment metrics
class SystemEnrollmentMetrics {
  final int totalCourses;
  final int totalStudents;
  final int totalEnrollments;
  final double averageEnrollmentRate;
  final Map<String, int> coursesByStatus;
  final Map<String, int> enrollmentsByDepartment;
  final List<Course> mostPopularCourses;
  final List<Course> leastPopularCourses;
  final DateTime generatedAt;

  const SystemEnrollmentMetrics({
    required this.totalCourses,
    required this.totalStudents,
    required this.totalEnrollments,
    required this.averageEnrollmentRate,
    required this.coursesByStatus,
    required this.enrollmentsByDepartment,
    required this.mostPopularCourses,
    required this.leastPopularCourses,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalCourses': totalCourses,
      'totalStudents': totalStudents,
      'totalEnrollments': totalEnrollments,
      'averageEnrollmentRate': averageEnrollmentRate,
      'coursesByStatus': coursesByStatus,
      'enrollmentsByDepartment': enrollmentsByDepartment,
      'mostPopularCourses': mostPopularCourses.map((c) => c.toJson()).toList(),
      'leastPopularCourses': leastPopularCourses.map((c) => c.toJson()).toList(),
      'generatedAt': generatedAt.toIso8601String(),
    };
  }
}

/// Service for generating enrollment analytics and reports
class EnrollmentAnalyticsService {
  final CourseRepository _courseRepository;
  final UserRepository _userRepository;
  final Logger _logger;

  // In-memory storage for analytics cache (in production, use a proper cache)
  final Map<String, EnrollmentAnalytics> _analyticsCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(hours: 1);

  EnrollmentAnalyticsService({
    required CourseRepository courseRepository,
    required UserRepository userRepository,
    Logger? logger,
  }) : _courseRepository = courseRepository,
       _userRepository = userRepository,
       _logger = logger ?? Logger();

  /// Generates comprehensive enrollment analytics for a course
  Future<Result<EnrollmentAnalytics>> generateCourseAnalytics(String courseId) async {
    try {
      _logger.info('Generating enrollment analytics for course $courseId');

      // Check cache first
      if (_isCacheValid(courseId)) {
        _logger.info('Returning cached analytics for course $courseId');
        return Result.success(_analyticsCache[courseId]!);
      }

      // Get course details
      final courseResult = await _courseRepository.getCourseById(courseId);
      if (courseResult.isError) {
        return Result.error('Course not found: ${courseResult.error}');
      }
      final course = courseResult.data!;

      // Get enrolled students
      final studentsResult = await _courseRepository.getEnrolledStudents(courseId);
      if (studentsResult.isError) {
        return Result.error('Failed to get enrolled students: ${studentsResult.error}');
      }
      final enrolledStudents = studentsResult.data!;

      // Calculate analytics
      final analytics = await _calculateCourseAnalytics(course, enrolledStudents);

      // Cache the results
      _analyticsCache[courseId] = analytics;
      _cacheTimestamps[courseId] = DateTime.now();

      _logger.info('Successfully generated analytics for course $courseId');
      return Result.success(analytics);
    } catch (e) {
      _logger.error('Error generating course analytics: $e');
      return Result.error('Failed to generate course analytics: ${e.toString()}');
    }
  }

  /// Generates system-wide enrollment metrics
  Future<Result<SystemEnrollmentMetrics>> generateSystemMetrics() async {
    try {
      _logger.info('Generating system-wide enrollment metrics');

      // Get all courses
      final coursesResult = await _courseRepository.getCourses(limit: 1000);
      if (coursesResult.isError) {
        return Result.error('Failed to get courses: ${coursesResult.error}');
      }
      final courses = coursesResult.data!;

      // Calculate system metrics
      final metrics = await _calculateSystemMetrics(courses);

      _logger.info('Successfully generated system metrics');
      return Result.success(metrics);
    } catch (e) {
      _logger.error('Error generating system metrics: $e');
      return Result.error('Failed to generate system metrics: ${e.toString()}');
    }
  }

  /// Gets enrollment trends for a course over a specified period
  Future<Result<List<EnrollmentTrend>>> getEnrollmentTrends({
    required String courseId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      _logger.info('Getting enrollment trends for course $courseId from $startDate to $endDate');

      // In a real implementation, this would query enrollment history from the database
      // For now, we'll generate sample trend data
      final trends = _generateSampleTrends(startDate, endDate);

      return Result.success(trends);
    } catch (e) {
      _logger.error('Error getting enrollment trends: $e');
      return Result.error('Failed to get enrollment trends: ${e.toString()}');
    }
  }

  /// Compares enrollment metrics between multiple courses
  Future<Result<Map<String, EnrollmentAnalytics>>> compareCourses(List<String> courseIds) async {
    try {
      _logger.info('Comparing enrollment metrics for ${courseIds.length} courses');

      final comparisons = <String, EnrollmentAnalytics>{};

      for (final courseId in courseIds) {
        final analyticsResult = await generateCourseAnalytics(courseId);
        if (analyticsResult.isSuccess) {
          comparisons[courseId] = analyticsResult.data!;
        }
      }

      return Result.success(comparisons);
    } catch (e) {
      _logger.error('Error comparing courses: $e');
      return Result.error('Failed to compare courses: ${e.toString()}');
    }
  }

  /// Gets enrollment predictions based on historical data
  Future<Result<Map<String, dynamic>>> getEnrollmentPredictions(String courseId) async {
    try {
      _logger.info('Generating enrollment predictions for course $courseId');

      final analyticsResult = await generateCourseAnalytics(courseId);
      if (analyticsResult.isError) {
        return Result.error(analyticsResult.errorMessage ?? 'Failed to generate analytics', analyticsResult.exception);
      }

      final analytics = analyticsResult.data!;
      final predictions = _calculateEnrollmentPredictions(analytics);

      return Result.success(predictions);
    } catch (e) {
      _logger.error('Error generating enrollment predictions: $e');
      return Result.error('Failed to generate enrollment predictions: ${e.toString()}');
    }
  }

  /// Exports analytics data to various formats
  Future<Result<String>> exportAnalytics({
    required String courseId,
    required String format, // 'json', 'csv', 'pdf'
  }) async {
    try {
      _logger.info('Exporting analytics for course $courseId in $format format');

      final analyticsResult = await generateCourseAnalytics(courseId);
      if (analyticsResult.isError) {
        return Result.error(analyticsResult.errorMessage ?? 'Failed to generate analytics', analyticsResult.exception);
      }

      final analytics = analyticsResult.data!;
      String exportedData;

      switch (format.toLowerCase()) {
        case 'json':
          exportedData = _exportToJson(analytics);
          break;
        case 'csv':
          exportedData = _exportToCsv(analytics);
          break;
        case 'pdf':
          exportedData = _exportToPdf(analytics);
          break;
        default:
          return Result.error('Unsupported export format: $format');
      }

      return Result.success(exportedData);
    } catch (e) {
      _logger.error('Error exporting analytics: $e');
      return Result.error('Failed to export analytics: ${e.toString()}');
    }
  }

  /// Calculates course-specific analytics
  Future<EnrollmentAnalytics> _calculateCourseAnalytics(Course course, List<User> enrolledStudents) async {
    final enrollmentsByMonth = <String, int>{};
    final enrollmentsByDepartment = <String, int>{};
    final enrollmentsByGrade = <String, int>{};

    // Analyze enrolled students
    for (final student in enrolledStudents) {
      // Group by enrollment month (using course creation date as proxy)
      final monthKey = '${course.createdAt.year}-${course.createdAt.month.toString().padLeft(2, '0')}';
      enrollmentsByMonth[monthKey] = (enrollmentsByMonth[monthKey] ?? 0) + 1;

      // Group by department
      if (student.department != null) {
        enrollmentsByDepartment[student.department!] = 
            (enrollmentsByDepartment[student.department!] ?? 0) + 1;
      }

      // Group by grade
      if (student.grade != null) {
        enrollmentsByGrade[student.grade!] = 
            (enrollmentsByGrade[student.grade!] ?? 0) + 1;
      }
    }

    // Generate sample trends
    final trends = _generateSampleTrends(
      course.createdAt,
      DateTime.now(),
    );

    return EnrollmentAnalytics(
      courseId: course.id,
      courseName: course.title,
      totalEnrollments: enrolledStudents.length,
      currentEnrollments: enrolledStudents.length,
      maxCapacity: course.maxEnrollment,
      enrollmentRate: course.enrollmentPercentage / 100,
      completionRate: 0.85, // Sample completion rate
      enrollmentsByMonth: enrollmentsByMonth,
      enrollmentsByDepartment: enrollmentsByDepartment,
      enrollmentsByGrade: enrollmentsByGrade,
      trends: trends,
      generatedAt: DateTime.now(),
    );
  }

  /// Calculates system-wide metrics
  Future<SystemEnrollmentMetrics> _calculateSystemMetrics(List<Course> courses) async {
    final coursesByStatus = <String, int>{};
    final enrollmentsByDepartment = <String, int>{};
    int totalEnrollments = 0;
    double totalEnrollmentRate = 0;

    for (final course in courses) {
      // Count courses by status
      coursesByStatus[course.status.value] = 
          (coursesByStatus[course.status.value] ?? 0) + 1;

      // Sum enrollments
      totalEnrollments += course.enrolledStudents.length;
      totalEnrollmentRate += course.enrollmentPercentage;

      // Get enrolled students for department analysis
      final studentsResult = await _courseRepository.getEnrolledStudents(course.id);
      if (studentsResult.isSuccess) {
        for (final student in studentsResult.data!) {
          if (student.department != null) {
            enrollmentsByDepartment[student.department!] = 
                (enrollmentsByDepartment[student.department!] ?? 0) + 1;
          }
        }
      }
    }

    // Sort courses by popularity
    courses.sort((a, b) => b.enrolledStudents.length.compareTo(a.enrolledStudents.length));
    final mostPopular = courses.take(5).toList();
    final leastPopular = courses.reversed.take(5).toList();

    return SystemEnrollmentMetrics(
      totalCourses: courses.length,
      totalStudents: 0, // Would need to query user repository
      totalEnrollments: totalEnrollments,
      averageEnrollmentRate: courses.isNotEmpty ? totalEnrollmentRate / courses.length : 0,
      coursesByStatus: coursesByStatus,
      enrollmentsByDepartment: enrollmentsByDepartment,
      mostPopularCourses: mostPopular,
      leastPopularCourses: leastPopular,
      generatedAt: DateTime.now(),
    );
  }

  /// Generates sample enrollment trends
  List<EnrollmentTrend> _generateSampleTrends(DateTime startDate, DateTime endDate) {
    final trends = <EnrollmentTrend>[];
    final duration = endDate.difference(startDate);
    final days = duration.inDays;

    for (int i = 0; i <= days; i += 7) { // Weekly trends
      final date = startDate.add(Duration(days: i));
      final enrollments = (i / 7 + 1).round() * 2; // Sample data
      final unenrollments = (i / 14).round(); // Sample data
      
      trends.add(EnrollmentTrend(
        date: date,
        enrollments: enrollments,
        unenrollments: unenrollments,
        netChange: enrollments - unenrollments,
      ));
    }

    return trends;
  }

  /// Calculates enrollment predictions
  Map<String, dynamic> _calculateEnrollmentPredictions(EnrollmentAnalytics analytics) {
    // Simple linear prediction based on current trends
    final currentRate = analytics.enrollmentRate;
    final capacity = analytics.maxCapacity;
    final current = analytics.currentEnrollments;

    final predictedGrowthRate = 0.1; // 10% growth per month (sample)
    final monthsToFull = capacity > current 
        ? ((capacity - current) / (current * predictedGrowthRate)).ceil()
        : 0;

    return {
      'currentEnrollments': current,
      'predictedGrowthRate': predictedGrowthRate,
      'monthsToFull': monthsToFull,
      'predictedFullDate': monthsToFull > 0 
          ? DateTime.now().add(Duration(days: monthsToFull * 30)).toIso8601String()
          : null,
      'recommendedActions': _getRecommendedActions(analytics),
    };
  }

  /// Gets recommended actions based on analytics
  List<String> _getRecommendedActions(EnrollmentAnalytics analytics) {
    final recommendations = <String>[];

    if (analytics.enrollmentRate > 0.9) {
      recommendations.add('Consider increasing course capacity');
      recommendations.add('Create waitlist for interested students');
    } else if (analytics.enrollmentRate < 0.3) {
      recommendations.add('Review course marketing and visibility');
      recommendations.add('Consider adjusting course content or schedule');
    }

    if (analytics.completionRate < 0.7) {
      recommendations.add('Review course difficulty and pacing');
      recommendations.add('Provide additional student support resources');
    }

    return recommendations;
  }

  /// Checks if cached analytics are still valid
  bool _isCacheValid(String courseId) {
    final timestamp = _cacheTimestamps[courseId];
    if (timestamp == null) return false;
    
    return DateTime.now().difference(timestamp) < _cacheExpiry;
  }

  /// Exports analytics to JSON format
  String _exportToJson(EnrollmentAnalytics analytics) {
    // In a real implementation, use a proper JSON encoder
    return analytics.toJson().toString();
  }

  /// Exports analytics to CSV format
  String _exportToCsv(EnrollmentAnalytics analytics) {
    final buffer = StringBuffer();
    buffer.writeln('Course Analytics Report');
    buffer.writeln('Course,${analytics.courseName}');
    buffer.writeln('Total Enrollments,${analytics.totalEnrollments}');
    buffer.writeln('Current Enrollments,${analytics.currentEnrollments}');
    buffer.writeln('Max Capacity,${analytics.maxCapacity}');
    buffer.writeln('Enrollment Rate,${(analytics.enrollmentRate * 100).toStringAsFixed(1)}%');
    buffer.writeln('Completion Rate,${(analytics.completionRate * 100).toStringAsFixed(1)}%');
    buffer.writeln('Generated At,${analytics.generatedAt}');
    
    return buffer.toString();
  }

  /// Exports analytics to PDF format (placeholder)
  String _exportToPdf(EnrollmentAnalytics analytics) {
    // In a real implementation, use a PDF generation library
    return 'PDF export not implemented yet';
  }

  /// Clears the analytics cache
  void clearCache() {
    _analyticsCache.clear();
    _cacheTimestamps.clear();
    _logger.info('Analytics cache cleared');
  }

  /// Gets cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'cachedCourses': _analyticsCache.length,
      'oldestCache': _cacheTimestamps.values.isEmpty 
          ? null 
          : _cacheTimestamps.values.reduce((a, b) => a.isBefore(b) ? a : b),
      'newestCache': _cacheTimestamps.values.isEmpty 
          ? null 
          : _cacheTimestamps.values.reduce((a, b) => a.isAfter(b) ? a : b),
    };
  }
}