import '../core/result.dart';
import '../core/logger.dart';
import '../modules/user.dart';
import '../repositories/course_repository.dart';
import '../repositories/user_repository.dart';

/// Represents a waitlist entry
class WaitlistEntry {
  final String id;
  final String courseId;
  final String studentId;
  final DateTime joinedAt;
  final int position;
  final bool isActive;

  const WaitlistEntry({
    required this.id,
    required this.courseId,
    required this.studentId,
    required this.joinedAt,
    required this.position,
    this.isActive = true,
  });

  /// Creates waitlist entry from JSON
  factory WaitlistEntry.fromJson(Map<String, dynamic> json) {
    return WaitlistEntry(
      id: json['id'] as String,
      courseId: json['courseId'] as String,
      studentId: json['studentId'] as String,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      position: json['position'] as int,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// Converts waitlist entry to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'studentId': studentId,
      'joinedAt': joinedAt.toIso8601String(),
      'position': position,
      'isActive': isActive,
    };
  }

  /// Creates a copy with updated fields
  WaitlistEntry copyWith({
    String? id,
    String? courseId,
    String? studentId,
    DateTime? joinedAt,
    int? position,
    bool? isActive,
  }) {
    return WaitlistEntry(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      studentId: studentId ?? this.studentId,
      joinedAt: joinedAt ?? this.joinedAt,
      position: position ?? this.position,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Service for managing course waitlists
class WaitlistService {
  final CourseRepository _courseRepository;
  final UserRepository _userRepository;
  final Logger _logger;

  // In-memory storage for waitlists (in production, this would be in a database)
  final Map<String, List<WaitlistEntry>> _waitlists = {};

  WaitlistService({
    required CourseRepository courseRepository,
    required UserRepository userRepository,
    Logger? logger,
  }) : _courseRepository = courseRepository,
       _userRepository = userRepository,
       _logger = logger ?? Logger();

  /// Adds a student to a course waitlist
  Future<Result<WaitlistEntry>> addToWaitlist({
    required String courseId,
    required String studentId,
  }) async {
    try {
      _logger.info('Adding student $studentId to waitlist for course $courseId');

      // Validate course exists and is full
      final courseResult = await _courseRepository.getCourseById(courseId);
      if (courseResult.isError) {
        return Result.error('Course not found: ${courseResult.error}');
      }

      final course = courseResult.data!;
      if (!course.isFull) {
        return Result.error('Course is not full, student can enroll directly');
      }

      // Validate student exists
      final studentResult = await _userRepository.getUserById(studentId);
      if (studentResult.isError) {
        return Result.error('Student not found: ${studentResult.error}');
      }

      final student = studentResult.data!;
      if (student.role != UserRole.student) {
        return Result.error('Only students can join waitlists');
      }

      // Check if student is already enrolled
      if (course.isStudentEnrolled(studentId)) {
        return Result.error('Student is already enrolled in this course');
      }

      // Check if student is already on waitlist
      if (await isOnWaitlist(courseId: courseId, studentId: studentId)) {
        return Result.error('Student is already on the waitlist for this course');
      }

      // Add to waitlist
      final waitlistEntry = WaitlistEntry(
        id: _generateWaitlistId(),
        courseId: courseId,
        studentId: studentId,
        joinedAt: DateTime.now(),
        position: await _getNextWaitlistPosition(courseId),
      );

      _waitlists[courseId] = _waitlists[courseId] ?? [];
      _waitlists[courseId]!.add(waitlistEntry);

      _logger.info('Successfully added student $studentId to waitlist at position ${waitlistEntry.position}');
      return Result.success(waitlistEntry);
    } catch (e) {
      _logger.error('Error adding to waitlist: $e');
      return Result.error('Failed to add to waitlist: ${e.toString()}');
    }
  }

  /// Removes a student from a course waitlist
  Future<Result<void>> removeFromWaitlist({
    required String courseId,
    required String studentId,
  }) async {
    try {
      _logger.info('Removing student $studentId from waitlist for course $courseId');

      final waitlist = _waitlists[courseId];
      if (waitlist == null) {
        return Result.error('No waitlist exists for this course');
      }

      final entryIndex = waitlist.indexWhere((entry) => 
          entry.studentId == studentId && entry.isActive);
      
      if (entryIndex == -1) {
        return Result.error('Student is not on the waitlist for this course');
      }

      // Remove the entry
      waitlist.removeAt(entryIndex);

      // Update positions for remaining entries
      await _updateWaitlistPositions(courseId);

      _logger.info('Successfully removed student $studentId from waitlist');
      return Result.success(null);
    } catch (e) {
      _logger.error('Error removing from waitlist: $e');
      return Result.error('Failed to remove from waitlist: ${e.toString()}');
    }
  }

  /// Gets the waitlist for a course
  Future<Result<List<WaitlistEntry>>> getWaitlist(String courseId) async {
    try {
      _logger.info('Getting waitlist for course $courseId');

      final waitlist = _waitlists[courseId] ?? [];
      final activeEntries = waitlist
          .where((entry) => entry.isActive)
          .toList()
        ..sort((a, b) => a.position.compareTo(b.position));

      return Result.success(activeEntries);
    } catch (e) {
      _logger.error('Error getting waitlist: $e');
      return Result.error('Failed to get waitlist: ${e.toString()}');
    }
  }

  /// Gets a student's waitlist position for a course
  Future<Result<int?>> getWaitlistPosition({
    required String courseId,
    required String studentId,
  }) async {
    try {
      final waitlistResult = await getWaitlist(courseId);
      if (waitlistResult.isError) {
        return Result.error(waitlistResult.error!);
      }

      final waitlist = waitlistResult.data!;
      final entry = waitlist.firstWhere(
        (entry) => entry.studentId == studentId,
        orElse: () => throw StateError('Not found'),
      );

      return Result.success(entry.position);
    } catch (e) {
      return Result.success(null); // Student not on waitlist
    }
  }

  /// Checks if a student is on a waitlist
  Future<bool> isOnWaitlist({
    required String courseId,
    required String studentId,
  }) async {
    final positionResult = await getWaitlistPosition(
      courseId: courseId,
      studentId: studentId,
    );
    return positionResult.isSuccess && positionResult.data != null;
  }

  /// Processes waitlist when a spot becomes available
  Future<Result<WaitlistEntry?>> processWaitlistForAvailableSpot({
    required String courseId,
  }) async {
    try {
      _logger.info('Processing waitlist for available spot in course $courseId');

      final waitlistResult = await getWaitlist(courseId);
      if (waitlistResult.isError) {
        return Result.error(waitlistResult.error!);
      }

      final waitlist = waitlistResult.data!;
      if (waitlist.isEmpty) {
        _logger.info('No students on waitlist for course $courseId');
        return Result.success(null);
      }

      // Get the first student on the waitlist
      final nextStudent = waitlist.first;

      // Validate course still has available spots
      final courseResult = await _courseRepository.getCourseById(courseId);
      if (courseResult.isError) {
        return Result.error('Course not found: ${courseResult.error}');
      }

      final course = courseResult.data!;
      if (!course.hasAvailableSpots) {
        return Result.error('No available spots in course');
      }

      // Attempt to enroll the student
      final enrollResult = await _courseRepository.enrollStudent(courseId, nextStudent.studentId);
      if (enrollResult.isError) {
        _logger.warning('Failed to enroll waitlisted student: ${enrollResult.error}');
        return Result.error('Failed to enroll waitlisted student: ${enrollResult.error}');
      }

      // Remove student from waitlist
      await removeFromWaitlist(courseId: courseId, studentId: nextStudent.studentId);

      _logger.info('Successfully enrolled waitlisted student ${nextStudent.studentId}');
      return Result.success(nextStudent);
    } catch (e) {
      _logger.error('Error processing waitlist: $e');
      return Result.error('Failed to process waitlist: ${e.toString()}');
    }
  }

  /// Gets waitlist statistics for a course
  Future<Result<Map<String, dynamic>>> getWaitlistStatistics(String courseId) async {
    try {
      final waitlistResult = await getWaitlist(courseId);
      if (waitlistResult.isError) {
        return Result.error(waitlistResult.error!);
      }

      final waitlist = waitlistResult.data!;
      final now = DateTime.now();

      final statistics = {
        'totalWaitlisted': waitlist.length,
        'averageWaitTime': _calculateAverageWaitTime(waitlist, now),
        'oldestEntry': waitlist.isEmpty ? null : waitlist
            .reduce((a, b) => a.joinedAt.isBefore(b.joinedAt) ? a : b)
            .joinedAt.toIso8601String(),
        'newestEntry': waitlist.isEmpty ? null : waitlist
            .reduce((a, b) => a.joinedAt.isAfter(b.joinedAt) ? a : b)
            .joinedAt.toIso8601String(),
        'waitlistByDay': _groupWaitlistByDay(waitlist),
      };

      return Result.success(statistics);
    } catch (e) {
      _logger.error('Error getting waitlist statistics: $e');
      return Result.error('Failed to get waitlist statistics: ${e.toString()}');
    }
  }

  /// Gets all waitlists for a student
  Future<Result<List<WaitlistEntry>>> getStudentWaitlists(String studentId) async {
    try {
      _logger.info('Getting all waitlists for student $studentId');

      final studentWaitlists = <WaitlistEntry>[];

      for (final courseWaitlist in _waitlists.values) {
        final studentEntries = courseWaitlist
            .where((entry) => entry.studentId == studentId && entry.isActive)
            .toList();
        studentWaitlists.addAll(studentEntries);
      }

      studentWaitlists.sort((a, b) => a.joinedAt.compareTo(b.joinedAt));

      return Result.success(studentWaitlists);
    } catch (e) {
      _logger.error('Error getting student waitlists: $e');
      return Result.error('Failed to get student waitlists: ${e.toString()}');
    }
  }

  /// Clears inactive waitlist entries
  Future<Result<int>> clearInactiveEntries(String courseId) async {
    try {
      _logger.info('Clearing inactive entries for course $courseId');

      final waitlist = _waitlists[courseId];
      if (waitlist == null) {
        return Result.success(0);
      }

      final initialCount = waitlist.length;
      waitlist.removeWhere((entry) => !entry.isActive);
      final removedCount = initialCount - waitlist.length;

      // Update positions
      await _updateWaitlistPositions(courseId);

      _logger.info('Cleared $removedCount inactive entries');
      return Result.success(removedCount);
    } catch (e) {
      _logger.error('Error clearing inactive entries: $e');
      return Result.error('Failed to clear inactive entries: ${e.toString()}');
    }
  }

  /// Generates a unique waitlist ID
  String _generateWaitlistId() {
    return 'waitlist_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(6)}';
  }

  /// Generates a random string
  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(length, (index) => chars[DateTime.now().millisecond % chars.length]).join();
  }

  /// Gets the next position in the waitlist
  Future<int> _getNextWaitlistPosition(String courseId) async {
    final waitlist = _waitlists[courseId] ?? [];
    final activeEntries = waitlist.where((entry) => entry.isActive).toList();
    return activeEntries.isEmpty ? 1 : activeEntries.map((e) => e.position).reduce((a, b) => a > b ? a : b) + 1;
  }

  /// Updates waitlist positions after removal
  Future<void> _updateWaitlistPositions(String courseId) async {
    final waitlist = _waitlists[courseId];
    if (waitlist == null) return;

    final activeEntries = waitlist.where((entry) => entry.isActive).toList()
      ..sort((a, b) => a.joinedAt.compareTo(b.joinedAt));

    for (int i = 0; i < activeEntries.length; i++) {
      final index = waitlist.indexOf(activeEntries[i]);
      waitlist[index] = activeEntries[i].copyWith(position: i + 1);
    }
  }

  /// Calculates average wait time
  double _calculateAverageWaitTime(List<WaitlistEntry> waitlist, DateTime now) {
    if (waitlist.isEmpty) return 0.0;

    final totalWaitTime = waitlist
        .map((entry) => now.difference(entry.joinedAt).inHours)
        .reduce((a, b) => a + b);

    return totalWaitTime / waitlist.length;
  }

  /// Groups waitlist entries by day
  Map<String, int> _groupWaitlistByDay(List<WaitlistEntry> waitlist) {
    final groupedByDay = <String, int>{};

    for (final entry in waitlist) {
      final day = '${entry.joinedAt.year}-${entry.joinedAt.month.toString().padLeft(2, '0')}-${entry.joinedAt.day.toString().padLeft(2, '0')}';
      groupedByDay[day] = (groupedByDay[day] ?? 0) + 1;
    }

    return groupedByDay;
  }
}