import '../core/core.dart';

/// Enum representing different course statuses
enum CourseStatus {
  draft('draft'),
  published('published'),
  archived('archived'),
  suspended('suspended');

  const CourseStatus(this.value);
  final String value;

  static CourseStatus fromString(String value) {
    return CourseStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => throw ArgumentError('Invalid course status: $value'),
    );
  }
}

/// Represents a course with enrollment tracking capabilities
class Course {
  final String id;
  final String title;
  final String description;
  final String instructorId;
  final String? imageUrl;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> enrolledStudents;
  final int maxEnrollment;
  final CourseStatus status;
  final String? category;
  final int duration; // Duration in hours
  final String? prerequisites;

  const Course({
    required this.id,
    required this.title,
    required this.description,
    required this.instructorId,
    this.imageUrl,
    this.tags = const [],
    required this.createdAt,
    this.updatedAt,
    this.enrolledStudents = const [],
    this.maxEnrollment = 50,
    this.status = CourseStatus.draft,
    this.category,
    this.duration = 0,
    this.prerequisites,
  });

  /// Creates a Course from JSON data
  factory Course.fromJson(Map<String, dynamic> json) {
    try {
      return Course(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        instructorId: json['instructorId'] as String,
        imageUrl: json['imageUrl'] as String?,
        tags: List<String>.from(json['tags'] ?? []),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
        enrolledStudents: List<String>.from(json['enrolledStudents'] ?? []),
        maxEnrollment: json['maxEnrollment'] as int? ?? 50,
        status: CourseStatus.fromString(json['status'] as String? ?? 'draft'),
        category: json['category'] as String?,
        duration: json['duration'] as int? ?? 0,
        prerequisites: json['prerequisites'] as String?,
      );
    } catch (e) {
      throw FormatException('Invalid course JSON format: $e');
    }
  }

  /// Converts Course to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'instructorId': instructorId,
      'imageUrl': imageUrl,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'enrolledStudents': enrolledStudents,
      'maxEnrollment': maxEnrollment,
      'status': status.value,
      'category': category,
      'duration': duration,
      'prerequisites': prerequisites,
    };
  }

  /// Validates course data and returns a Result with validation errors
  static Result<Course> validate({
    required String id,
    required String title,
    required String description,
    required String instructorId,
    String? imageUrl,
    List<String> tags = const [],
    required DateTime createdAt,
    DateTime? updatedAt,
    List<String> enrolledStudents = const [],
    int maxEnrollment = 50,
    CourseStatus status = CourseStatus.draft,
    String? category,
    int duration = 0,
    String? prerequisites,
  }) {
    final errors = <String>[];

    // Validate required fields
    if (id.trim().isEmpty) {
      errors.add('Course ID cannot be empty');
    }

    if (title.trim().isEmpty) {
      errors.add('Course title cannot be empty');
    } else if (title.trim().length < 3) {
      errors.add('Course title must be at least 3 characters long');
    } else if (title.trim().length > 200) {
      errors.add('Course title cannot exceed 200 characters');
    }

    if (description.trim().isEmpty) {
      errors.add('Course description cannot be empty');
    } else if (description.trim().length < 10) {
      errors.add('Course description must be at least 10 characters long');
    } else if (description.trim().length > 5000) {
      errors.add('Course description cannot exceed 5000 characters');
    }

    if (instructorId.trim().isEmpty) {
      errors.add('Instructor ID cannot be empty');
    }

    // Validate optional fields
    if (imageUrl != null && imageUrl.trim().isEmpty) {
      errors.add('Image URL cannot be empty if provided');
    }

    if (category != null && category.trim().isEmpty) {
      errors.add('Category cannot be empty if provided');
    } else if (category != null && category.trim().length > 100) {
      errors.add('Category cannot exceed 100 characters');
    }

    if (prerequisites != null && prerequisites.trim().length > 1000) {
      errors.add('Prerequisites cannot exceed 1000 characters');
    }

    // Validate tags
    for (final tag in tags) {
      if (tag.trim().isEmpty) {
        errors.add('Tags cannot be empty');
        break;
      }
      if (tag.trim().length > 50) {
        errors.add('Tags cannot exceed 50 characters');
        break;
      }
    }

    if (tags.length > 15) {
      errors.add('Cannot have more than 15 tags');
    }

    // Validate enrollment limits
    if (maxEnrollment <= 0) {
      errors.add('Maximum enrollment must be greater than 0');
    } else if (maxEnrollment > 1000) {
      errors.add('Maximum enrollment cannot exceed 1000');
    }

    if (enrolledStudents.length > maxEnrollment) {
      errors.add('Enrolled students count cannot exceed maximum enrollment');
    }

    // Validate duration
    if (duration < 0) {
      errors.add('Course duration cannot be negative');
    } else if (duration > 10000) {
      errors.add('Course duration cannot exceed 10000 hours');
    }

    // Validate timestamps
    if (createdAt.isAfter(DateTime.now().add(const Duration(minutes: 5)))) {
      errors.add('Course creation date cannot be in the future');
    }

    if (updatedAt != null) {
      if (updatedAt.isBefore(createdAt)) {
        errors.add('Update date cannot be before creation date');
      }
      if (updatedAt.isAfter(DateTime.now().add(const Duration(minutes: 5)))) {
        errors.add('Update date cannot be in the future');
      }
    }

    // Validate enrollment list for duplicates
    if (enrolledStudents.length != enrolledStudents.toSet().length) {
      errors.add('Enrolled students list cannot contain duplicates');
    }

    if (errors.isNotEmpty) {
      return Result.error('Validation failed: ${errors.join(', ')}');
    }

    return Result.success(Course(
      id: id.trim(),
      title: title.trim(),
      description: description.trim(),
      instructorId: instructorId.trim(),
      imageUrl: imageUrl?.trim(),
      tags: tags.map((tag) => tag.trim()).toList(),
      createdAt: createdAt,
      updatedAt: updatedAt,
      enrolledStudents: enrolledStudents,
      maxEnrollment: maxEnrollment,
      status: status,
      category: category?.trim(),
      duration: duration,
      prerequisites: prerequisites?.trim(),
    ));
  }

  /// Creates a copy of the course with updated fields
  Course copyWith({
    String? id,
    String? title,
    String? description,
    String? instructorId,
    String? imageUrl,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? enrolledStudents,
    int? maxEnrollment,
    CourseStatus? status,
    String? category,
    int? duration,
    String? prerequisites,
  }) {
    return Course(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      instructorId: instructorId ?? this.instructorId,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      enrolledStudents: enrolledStudents ?? this.enrolledStudents,
      maxEnrollment: maxEnrollment ?? this.maxEnrollment,
      status: status ?? this.status,
      category: category ?? this.category,
      duration: duration ?? this.duration,
      prerequisites: prerequisites ?? this.prerequisites,
    );
  }

  /// Enrolls a student in the course
  Course enrollStudent(String studentId) {
    if (enrolledStudents.contains(studentId)) return this;
    if (enrolledStudents.length >= maxEnrollment) return this;
    
    return copyWith(
      enrolledStudents: [...enrolledStudents, studentId],
      updatedAt: DateTime.now(),
    );
  }

  /// Unenrolls a student from the course
  Course unenrollStudent(String studentId) {
    if (!enrolledStudents.contains(studentId)) return this;
    
    return copyWith(
      enrolledStudents: enrolledStudents.where((id) => id != studentId).toList(),
      updatedAt: DateTime.now(),
    );
  }

  /// Updates the course status
  Course updateStatus(CourseStatus newStatus) {
    return copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
    );
  }

  /// Publishes the course
  Course publish() => updateStatus(CourseStatus.published);

  /// Archives the course
  Course archive() => updateStatus(CourseStatus.archived);

  /// Suspends the course
  Course suspend() => updateStatus(CourseStatus.suspended);

  /// Checks if a student is enrolled in the course
  bool isStudentEnrolled(String studentId) => enrolledStudents.contains(studentId);

  /// Checks if the course is full
  bool get isFull => enrolledStudents.length >= maxEnrollment;

  /// Checks if the course is nearly full (80% capacity)
  bool get isNearlyFull => enrollmentPercentage >= 80.0;

  /// Checks if the course has available spots
  bool get hasAvailableSpots => enrolledStudents.length < maxEnrollment;

  /// Returns the number of available spots
  int get availableSpots => maxEnrollment - enrolledStudents.length;

  /// Returns the enrollment percentage
  double get enrollmentPercentage => (enrolledStudents.length / maxEnrollment) * 100;

  /// Checks if the course is published
  bool get isPublished => status == CourseStatus.published;

  /// Checks if the course is archived
  bool get isArchived => status == CourseStatus.archived;

  /// Checks if the course is suspended
  bool get isSuspended => status == CourseStatus.suspended;

  /// Checks if the course is in draft
  bool get isDraft => status == CourseStatus.draft;

  /// Checks if the course can accept enrollments
  bool get canAcceptEnrollments => isPublished && hasAvailableSpots;

  /// Checks if the course has an image
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  /// Checks if the course has tags
  bool get hasTags => tags.isNotEmpty;

  /// Checks if the course has prerequisites
  bool get hasPrerequisites => prerequisites != null && prerequisites!.isNotEmpty;

  /// Returns the display name for the course status
  String get statusDisplayName {
    return switch (status) {
      CourseStatus.draft => 'Draft',
      CourseStatus.published => 'Published',
      CourseStatus.archived => 'Archived',
      CourseStatus.suspended => 'Suspended',
    };
  }

  /// Returns a formatted duration string
  String get formattedDuration {
    if (duration == 0) return 'Duration not specified';
    if (duration == 1) return '1 hour';
    if (duration < 24) return '$duration hours';
    
    final days = duration ~/ 24;
    final remainingHours = duration % 24;
    
    if (remainingHours == 0) {
      return days == 1 ? '1 day' : '$days days';
    } else {
      return '$days days, $remainingHours hours';
    }
  }

  /// Returns a preview of the description (first 100 characters)
  String get descriptionPreview {
    if (description.length <= 100) return description;
    return '${description.substring(0, 97)}...';
  }

  /// Checks if the course matches a search query
  bool matchesSearch(String query) {
    final lowerQuery = query.toLowerCase();
    return title.toLowerCase().contains(lowerQuery) ||
           description.toLowerCase().contains(lowerQuery) ||
           tags.any((tag) => tag.toLowerCase().contains(lowerQuery)) ||
           (category?.toLowerCase().contains(lowerQuery) ?? false);
  }

  /// Returns the course's popularity score based on enrollment
  double get popularityScore => enrollmentPercentage / 100;

  /// Checks if the course was recently created (within last 30 days)
  bool get isRecentlyCreated {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    return createdAt.isAfter(thirtyDaysAgo);
  }

  /// Checks if the course was recently updated (within last 7 days)
  bool get isRecentlyUpdated {
    if (updatedAt == null) return false;
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    return updatedAt!.isAfter(sevenDaysAgo);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Course &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          instructorId == other.instructorId &&
          imageUrl == other.imageUrl &&
          createdAt == other.createdAt &&
          status == other.status;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      description.hashCode ^
      instructorId.hashCode ^
      imageUrl.hashCode ^
      createdAt.hashCode ^
      status.hashCode;

  @override
  String toString() {
    return 'Course(id: $id, title: $title, instructor: $instructorId, enrolled: ${enrolledStudents.length}/$maxEnrollment, status: ${status.value})';
  }
}