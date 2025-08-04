import '../core/core.dart';

/// Represents a comment on a post with user and timestamp information
class Comment {
  final String id;
  final String postId;
  final String userId;
  final String content;
  final DateTime timestamp;
  final DateTime? editedAt;
  final bool isEdited;

  const Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.timestamp,
    this.editedAt,
    this.isEdited = false,
  });

  /// Creates a Comment from JSON data
  factory Comment.fromJson(Map<String, dynamic> json) {
    try {
      return Comment(
        id: json['id'] as String,
        postId: json['postId'] as String,
        userId: json['userId'] as String,
        content: json['content'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        editedAt: json['editedAt'] != null ? DateTime.parse(json['editedAt'] as String) : null,
        isEdited: json['isEdited'] as bool? ?? false,
      );
    } catch (e) {
      throw FormatException('Invalid comment JSON format: $e');
    }
  }

  /// Converts Comment to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'userId': userId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'editedAt': editedAt?.toIso8601String(),
      'isEdited': isEdited,
    };
  }

  /// Validates comment data and returns a Result with validation errors
  static Result<Comment> validate({
    required String id,
    required String postId,
    required String userId,
    required String content,
    required DateTime timestamp,
    DateTime? editedAt,
    bool isEdited = false,
  }) {
    final errors = <String>[];

    // Validate required fields
    if (id.trim().isEmpty) {
      errors.add('Comment ID cannot be empty');
    }

    if (postId.trim().isEmpty) {
      errors.add('Post ID cannot be empty');
    }

    if (userId.trim().isEmpty) {
      errors.add('User ID cannot be empty');
    }

    if (content.trim().isEmpty) {
      errors.add('Comment content cannot be empty');
    } else if (content.trim().length > 1000) {
      errors.add('Comment content cannot exceed 1000 characters');
    }

    // Validate timestamp
    if (timestamp.isAfter(DateTime.now().add(const Duration(minutes: 5)))) {
      errors.add('Comment timestamp cannot be in the future');
    }

    // Validate edit timestamp
    if (editedAt != null) {
      if (editedAt.isBefore(timestamp)) {
        errors.add('Edit timestamp cannot be before original timestamp');
      }
      if (editedAt.isAfter(DateTime.now().add(const Duration(minutes: 5)))) {
        errors.add('Edit timestamp cannot be in the future');
      }
    }

    // Validate edit consistency
    if (isEdited && editedAt == null) {
      errors.add('Edited comments must have an edit timestamp');
    }

    if (!isEdited && editedAt != null) {
      errors.add('Non-edited comments cannot have an edit timestamp');
    }

    if (errors.isNotEmpty) {
      return Result.error('Validation failed: ${errors.join(', ')}');
    }

    return Result.success(Comment(
      id: id.trim(),
      postId: postId.trim(),
      userId: userId.trim(),
      content: content.trim(),
      timestamp: timestamp,
      editedAt: editedAt,
      isEdited: isEdited,
    ));
  }

  /// Creates a copy of the comment with updated fields
  Comment copyWith({
    String? id,
    String? postId,
    String? userId,
    String? content,
    DateTime? timestamp,
    DateTime? editedAt,
    bool? isEdited,
  }) {
    return Comment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      editedAt: editedAt ?? this.editedAt,
      isEdited: isEdited ?? this.isEdited,
    );
  }

  /// Creates an edited version of the comment with new content
  Comment edit(String newContent) {
    final now = DateTime.now();
    return copyWith(
      content: newContent.trim(),
      editedAt: now,
      isEdited: true,
    );
  }

  /// Returns a formatted timestamp string
  String get formattedTimestamp {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  /// Returns a formatted edit timestamp string
  String? get formattedEditTimestamp {
    if (editedAt == null) return null;
    
    final now = DateTime.now();
    final difference = now.difference(editedAt!);

    if (difference.inDays > 0) {
      return 'edited ${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return 'edited ${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return 'edited ${difference.inMinutes}m ago';
    } else {
      return 'edited just now';
    }
  }

  /// Returns a preview of the content (first 50 characters)
  String get contentPreview {
    if (content.length <= 50) return content;
    return '${content.substring(0, 47)}...';
  }

  /// Checks if the comment matches a search query
  bool matchesSearch(String query) {
    final lowerQuery = query.toLowerCase();
    return content.toLowerCase().contains(lowerQuery);
  }

  /// Checks if the comment can be edited (within edit time limit)
  bool canBeEdited({Duration editTimeLimit = const Duration(hours: 24)}) {
    final now = DateTime.now();
    final timeSinceCreation = now.difference(timestamp);
    return timeSinceCreation <= editTimeLimit;
  }

  /// Checks if the comment can be deleted by a specific user
  bool canBeDeletedBy(String currentUserId, {bool isCurrentUserModerator = false}) {
    return userId == currentUserId || isCurrentUserModerator;
  }

  /// Checks if the comment can be edited by a specific user
  bool canBeEditedBy(String currentUserId) {
    return userId == currentUserId && canBeEdited();
  }

  /// Returns the age of the comment in minutes
  int get ageInMinutes {
    final now = DateTime.now();
    return now.difference(timestamp).inMinutes;
  }

  /// Returns the age of the comment in hours
  int get ageInHours {
    final now = DateTime.now();
    return now.difference(timestamp).inHours;
  }

  /// Returns the age of the comment in days
  int get ageInDays {
    final now = DateTime.now();
    return now.difference(timestamp).inDays;
  }

  /// Checks if the comment is recent (less than 1 hour old)
  bool get isRecent => ageInHours < 1;

  /// Checks if the comment is old (more than 7 days old)
  bool get isOld => ageInDays > 7;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Comment &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          postId == other.postId &&
          userId == other.userId &&
          content == other.content &&
          timestamp == other.timestamp &&
          editedAt == other.editedAt &&
          isEdited == other.isEdited;

  @override
  int get hashCode =>
      id.hashCode ^
      postId.hashCode ^
      userId.hashCode ^
      content.hashCode ^
      timestamp.hashCode ^
      editedAt.hashCode ^
      isEdited.hashCode;

  @override
  String toString() {
    return 'Comment(id: $id, postId: $postId, userId: $userId, content: ${contentPreview}${isEdited ? ' (edited)' : ''})';
  }
}