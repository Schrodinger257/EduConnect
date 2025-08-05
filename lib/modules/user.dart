import '../core/core.dart';

/// Enum representing different user roles in the system
enum UserRole {
  student('student'),
  instructor('instructor'),
  admin('admin');

  const UserRole(this.value);
  final String value;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => throw ArgumentError('Invalid user role: $value'),
    );
  }

  /// Returns the display name for the role
  String get displayName {
    return switch (this) {
      UserRole.student => 'Student',
      UserRole.instructor => 'Instructor',
      UserRole.admin => 'Administrator',
    };
  }
}

/// Enhanced User model with comprehensive validation and JSON serialization
class User {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? profileImage;
  final String? department;
  final String? fieldOfExpertise;
  final String? grade;
  final DateTime createdAt;
  final List<String> bookmarks;
  final List<String> likedPosts;
  final List<String> enrolledCourses;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.profileImage,
    this.department,
    this.fieldOfExpertise,
    this.grade,
    required this.createdAt,
    this.bookmarks = const [],
    this.likedPosts = const [],
    this.enrolledCourses = const [],
  });

  /// Creates a User from JSON data
  factory User.fromJson(Map<String, dynamic> json) {
    try {
      return User(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String,
        role: UserRole.fromString(json['role'] as String),
        profileImage: json['profileImage'] as String?,
        department: json['department'] as String?,
        fieldOfExpertise: json['fieldOfExpertise'] as String?,
        grade: json['grade'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        bookmarks: List<String>.from(json['bookmarks'] ?? []),
        likedPosts: List<String>.from(json['likedPosts'] ?? []),
        enrolledCourses: List<String>.from(json['enrolledCourses'] ?? []),
      );
    } catch (e) {
      throw FormatException('Invalid user JSON format: $e');
    }
  }

  /// Converts User to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.value,
      'profileImage': profileImage,
      'department': department,
      'fieldOfExpertise': fieldOfExpertise,
      'grade': grade,
      'createdAt': createdAt.toIso8601String(),
      'bookmarks': bookmarks,
      'likedPosts': likedPosts,
      'enrolledCourses': enrolledCourses,
    };
  }

  /// Validates user data and returns a Result with validation errors
  static Result<User> validate({
    required String id,
    required String email,
    required String name,
    required UserRole role,
    String? profileImage,
    String? department,
    String? fieldOfExpertise,
    String? grade,
    required DateTime createdAt,
    List<String> bookmarks = const [],
    List<String> likedPosts = const [],
    List<String> enrolledCourses = const [],
  }) {
    final errors = <String>[];

    // Validate required fields
    if (id.trim().isEmpty) {
      errors.add('User ID cannot be empty');
    }

    if (email.trim().isEmpty) {
      errors.add('Email cannot be empty');
    } else if (!_isValidEmail(email)) {
      errors.add('Invalid email format');
    }

    if (name.trim().isEmpty) {
      errors.add('Name cannot be empty');
    } else if (name.trim().length < 2) {
      errors.add('Name must be at least 2 characters long');
    } else if (name.trim().length > 100) {
      errors.add('Name cannot exceed 100 characters');
    }

    // Role-specific validation
    if (role == UserRole.instructor && fieldOfExpertise?.trim().isEmpty == true) {
      errors.add('Field of expertise is required for instructors');
    }

    if (role == UserRole.student && grade?.trim().isEmpty == true) {
      errors.add('Grade level is required for students');
    }

    // Validate optional fields if provided
    if (department != null && department.trim().length > 100) {
      errors.add('Department name cannot exceed 100 characters');
    }

    if (fieldOfExpertise != null && fieldOfExpertise.trim().length > 200) {
      errors.add('Field of expertise cannot exceed 200 characters');
    }

    if (grade != null && grade.trim().length > 50) {
      errors.add('Grade cannot exceed 50 characters');
    }

    if (errors.isNotEmpty) {
      return Result.error('Validation failed: ${errors.join(', ')}');
    }

    return Result.success(User(
      id: id.trim(),
      email: email.trim().toLowerCase(),
      name: name.trim(),
      role: role,
      profileImage: profileImage?.trim(),
      department: department?.trim(),
      fieldOfExpertise: fieldOfExpertise?.trim(),
      grade: grade?.trim(),
      createdAt: createdAt,
      bookmarks: bookmarks,
      likedPosts: likedPosts,
      enrolledCourses: enrolledCourses,
    ));
  }

  /// Creates a copy of the user with updated fields
  User copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    String? profileImage,
    String? department,
    String? fieldOfExpertise,
    String? grade,
    DateTime? createdAt,
    List<String>? bookmarks,
    List<String>? likedPosts,
    List<String>? enrolledCourses,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      profileImage: profileImage ?? this.profileImage,
      department: department ?? this.department,
      fieldOfExpertise: fieldOfExpertise ?? this.fieldOfExpertise,
      grade: grade ?? this.grade,
      createdAt: createdAt ?? this.createdAt,
      bookmarks: bookmarks ?? this.bookmarks,
      likedPosts: likedPosts ?? this.likedPosts,
      enrolledCourses: enrolledCourses ?? this.enrolledCourses,
    );
  }

  /// Adds a bookmark to the user's bookmark list
  User addBookmark(String postId) {
    if (bookmarks.contains(postId)) return this;
    return copyWith(bookmarks: [...bookmarks, postId]);
  }

  /// Removes a bookmark from the user's bookmark list
  User removeBookmark(String postId) {
    return copyWith(bookmarks: bookmarks.where((id) => id != postId).toList());
  }

  /// Adds a liked post to the user's liked posts list
  User addLikedPost(String postId) {
    if (likedPosts.contains(postId)) return this;
    return copyWith(likedPosts: [...likedPosts, postId]);
  }

  /// Removes a liked post from the user's liked posts list
  User removeLikedPost(String postId) {
    return copyWith(likedPosts: likedPosts.where((id) => id != postId).toList());
  }

  /// Enrolls the user in a course
  User enrollInCourse(String courseId) {
    if (enrolledCourses.contains(courseId)) return this;
    return copyWith(enrolledCourses: [...enrolledCourses, courseId]);
  }

  /// Unenrolls the user from a course
  User unenrollFromCourse(String courseId) {
    return copyWith(enrolledCourses: enrolledCourses.where((id) => id != courseId).toList());
  }

  /// Checks if the user has liked a specific post
  bool hasLikedPost(String postId) => likedPosts.contains(postId);

  /// Checks if the user has bookmarked a specific post
  bool hasBookmarked(String postId) => bookmarks.contains(postId);

  /// Checks if the user is enrolled in a specific course
  bool isEnrolledInCourse(String courseId) => enrolledCourses.contains(courseId);

  /// Returns the display name for the user's role
  String get roleDisplayName {
    return switch (role) {
      UserRole.student => 'Student',
      UserRole.instructor => 'Instructor',
      UserRole.admin => 'Administrator',
    };
  }

  /// Email validation helper
  static bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          name == other.name &&
          role == other.role &&
          profileImage == other.profileImage &&
          department == other.department &&
          fieldOfExpertise == other.fieldOfExpertise &&
          grade == other.grade &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      email.hashCode ^
      name.hashCode ^
      role.hashCode ^
      profileImage.hashCode ^
      department.hashCode ^
      fieldOfExpertise.hashCode ^
      grade.hashCode ^
      createdAt.hashCode;

  @override
  String toString() {
    return 'User(id: $id, email: $email, name: $name, role: ${role.value})';
  }
}

/// Legacy UserClass for backward compatibility
/// @deprecated Use User class instead
class UserClass {
  UserClass({this.password, this.email, this.name, this.roleCode});

  String? email;
  String? password;
  String? name;
  String? roleCode;
}
