import '../core/core.dart';

/// Represents a post in the social feed with like and comment functionality
class Post {
  final String id;
  final String content;
  final String userId;
  final String? imageUrl;
  final List<String> tags;
  final DateTime timestamp;
  final int likeCount;
  final List<String> likedBy;
  final int commentCount;
  final List<String> commentIds;

  const Post({
    required this.id,
    required this.content,
    required this.userId,
    this.imageUrl,
    this.tags = const [],
    required this.timestamp,
    this.likeCount = 0,
    this.likedBy = const [],
    this.commentCount = 0,
    this.commentIds = const [],
  });

  /// Creates a Post from JSON data
  factory Post.fromJson(Map<String, dynamic> json) {
    try {
      final userId = json['userId']?.toString() ?? '';
      if (userId.trim().isEmpty) {
        throw FormatException('Post userId cannot be empty');
      }
      
      return Post(
        id: json['id']?.toString() ?? '',
        content: json['content']?.toString() ?? '',
        userId: userId.trim(),
        imageUrl: json['imageUrl']?.toString(),
        tags: List<String>.from(json['tags'] ?? []),
        timestamp: json['timestamp'] != null 
            ? DateTime.parse(json['timestamp'].toString()) 
            : DateTime.now(),
        likeCount: json['likeCount'] as int? ?? 0,
        likedBy: List<String>.from(json['likedBy'] ?? []),
        commentCount: json['commentCount'] as int? ?? 0,
        commentIds: List<String>.from(json['commentIds'] ?? []),
      );
    } catch (e) {
      throw FormatException('Invalid post JSON format: $e');
    }
  }

  /// Converts Post to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'userId': userId,
      'imageUrl': imageUrl,
      'tags': tags,
      'timestamp': timestamp.toIso8601String(),
      'likeCount': likeCount,
      'likedBy': likedBy,
      'commentCount': commentCount,
      'commentIds': commentIds,
    };
  }

  /// Validates post data and returns a Result with validation errors
  static Result<Post> validate({
    required String id,
    required String content,
    required String userId,
    String? imageUrl,
    List<String> tags = const [],
    required DateTime timestamp,
    int likeCount = 0,
    List<String> likedBy = const [],
    int commentCount = 0,
    List<String> commentIds = const [],
  }) {
    final errors = <String>[];

    // Validate required fields
    if (id.trim().isEmpty) {
      errors.add('Post ID cannot be empty');
    }

    if (content.trim().isEmpty) {
      errors.add('Post content cannot be empty');
    } else if (content.trim().length > 5000) {
      errors.add('Post content cannot exceed 5000 characters');
    }

    if (userId.trim().isEmpty) {
      errors.add('User ID cannot be empty');
    }

    // Validate optional fields
    if (imageUrl != null && imageUrl.trim().isEmpty) {
      errors.add('Image URL cannot be empty if provided');
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

    if (tags.length > 10) {
      errors.add('Cannot have more than 10 tags');
    }

    // Validate counts
    if (likeCount < 0) {
      errors.add('Like count cannot be negative');
    }

    if (commentCount < 0) {
      errors.add('Comment count cannot be negative');
    }

    // Validate consistency between counts and arrays
    if (likedBy.length != likeCount) {
      errors.add('Like count must match likedBy array length');
    }

    if (commentIds.length != commentCount) {
      errors.add('Comment count must match commentIds array length');
    }

    // Validate timestamp
    if (timestamp.isAfter(DateTime.now().add(const Duration(minutes: 5)))) {
      errors.add('Post timestamp cannot be in the future');
    }

    if (errors.isNotEmpty) {
      return Result.error('Validation failed: ${errors.join(', ')}');
    }

    return Result.success(Post(
      id: id.trim(),
      content: content.trim(),
      userId: userId.trim(),
      imageUrl: imageUrl?.trim(),
      tags: tags.map((tag) => tag.trim()).toList(),
      timestamp: timestamp,
      likeCount: likeCount,
      likedBy: likedBy,
      commentCount: commentCount,
      commentIds: commentIds,
    ));
  }

  /// Creates a copy of the post with updated fields
  Post copyWith({
    String? id,
    String? content,
    String? userId,
    String? imageUrl,
    List<String>? tags,
    DateTime? timestamp,
    int? likeCount,
    List<String>? likedBy,
    int? commentCount,
    List<String>? commentIds,
  }) {
    return Post(
      id: id ?? this.id,
      content: content ?? this.content,
      userId: userId ?? this.userId,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      timestamp: timestamp ?? this.timestamp,
      likeCount: likeCount ?? this.likeCount,
      likedBy: likedBy ?? this.likedBy,
      commentCount: commentCount ?? this.commentCount,
      commentIds: commentIds ?? this.commentIds,
    );
  }

  /// Adds a like from a user
  Post addLike(String userId) {
    if (likedBy.contains(userId)) return this;
    
    return copyWith(
      likeCount: likeCount + 1,
      likedBy: [...likedBy, userId],
    );
  }

  /// Removes a like from a user
  Post removeLike(String userId) {
    if (!likedBy.contains(userId)) return this;
    
    return copyWith(
      likeCount: likeCount - 1,
      likedBy: likedBy.where((id) => id != userId).toList(),
    );
  }

  /// Toggles like status for a user
  Post toggleLike(String userId) {
    return isLikedBy(userId) ? removeLike(userId) : addLike(userId);
  }

  /// Adds a comment to the post
  Post addComment(String commentId) {
    if (commentIds.contains(commentId)) return this;
    
    return copyWith(
      commentCount: commentCount + 1,
      commentIds: [...commentIds, commentId],
    );
  }

  /// Removes a comment from the post
  Post removeComment(String commentId) {
    if (!commentIds.contains(commentId)) return this;
    
    return copyWith(
      commentCount: commentCount - 1,
      commentIds: commentIds.where((id) => id != commentId).toList(),
    );
  }

  /// Checks if the post is liked by a specific user
  bool isLikedBy(String userId) => likedBy.contains(userId);

  /// Checks if the post has any comments
  bool get hasComments => commentCount > 0;

  /// Checks if the post has any likes
  bool get hasLikes => likeCount > 0;

  /// Checks if the post has an image
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  /// Checks if the post has tags
  bool get hasTags => tags.isNotEmpty;

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

  /// Returns a preview of the content (first 100 characters)
  String get contentPreview {
    if (content.length <= 100) return content;
    return '${content.substring(0, 97)}...';
  }

  /// Checks if the post matches a search query
  bool matchesSearch(String query) {
    final lowerQuery = query.toLowerCase();
    return content.toLowerCase().contains(lowerQuery) ||
           tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
  }

  /// Returns the post's engagement score (likes + comments)
  int get engagementScore => likeCount + commentCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Post &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          content == other.content &&
          userId == other.userId &&
          imageUrl == other.imageUrl &&
          timestamp == other.timestamp;

  @override
  int get hashCode =>
      id.hashCode ^
      content.hashCode ^
      userId.hashCode ^
      imageUrl.hashCode ^
      timestamp.hashCode;

  @override
  String toString() {
    return 'Post(id: $id, userId: $userId, content: $contentPreview, likes: $likeCount, comments: $commentCount)';
  }
}