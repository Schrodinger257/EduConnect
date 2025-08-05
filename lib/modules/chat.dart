import '../core/core.dart';

/// Enum representing different chat types
enum ChatType {
  direct('direct'),
  group('group'),
  course('course');

  const ChatType(this.value);
  final String value;

  static ChatType fromString(String value) {
    return ChatType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => throw ArgumentError('Invalid chat type: $value'),
    );
  }
}

/// Represents a chat conversation between users
class Chat {
  final String id;
  final String title;
  final ChatType type;
  final List<String> participantIds;
  final String? lastMessageId;
  final String? lastMessageContent;
  final DateTime? lastMessageTimestamp;
  final String? lastMessageSenderId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? imageUrl;
  final Map<String, int> unreadCounts;
  final Map<String, DateTime> lastReadTimestamps;
  final bool isActive;
  final Map<String, dynamic> metadata;

  const Chat({
    required this.id,
    required this.title,
    required this.type,
    required this.participantIds,
    this.lastMessageId,
    this.lastMessageContent,
    this.lastMessageTimestamp,
    this.lastMessageSenderId,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.imageUrl,
    this.unreadCounts = const {},
    this.lastReadTimestamps = const {},
    this.isActive = true,
    this.metadata = const {},
  });

  /// Creates a Chat from JSON data
  factory Chat.fromJson(Map<String, dynamic> json) {
    try {
      return Chat(
        id: json['id'] as String,
        title: json['title'] as String,
        type: ChatType.fromString(json['type'] as String),
        participantIds: List<String>.from(json['participantIds'] ?? []),
        lastMessageId: json['lastMessageId'] as String?,
        lastMessageContent: json['lastMessageContent'] as String?,
        lastMessageTimestamp: json['lastMessageTimestamp'] != null 
            ? DateTime.parse(json['lastMessageTimestamp'] as String) 
            : null,
        lastMessageSenderId: json['lastMessageSenderId'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        createdBy: json['createdBy'] as String?,
        imageUrl: json['imageUrl'] as String?,
        unreadCounts: Map<String, int>.from(json['unreadCounts'] ?? {}),
        lastReadTimestamps: (json['lastReadTimestamps'] as Map<String, dynamic>?)
            ?.map((key, value) => MapEntry(key, DateTime.parse(value as String))) ?? {},
        isActive: json['isActive'] as bool? ?? true,
        metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      );
    } catch (e) {
      throw FormatException('Invalid chat JSON format: $e');
    }
  }

  /// Converts Chat to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.value,
      'participantIds': participantIds,
      'lastMessageId': lastMessageId,
      'lastMessageContent': lastMessageContent,
      'lastMessageTimestamp': lastMessageTimestamp?.toIso8601String(),
      'lastMessageSenderId': lastMessageSenderId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdBy': createdBy,
      'imageUrl': imageUrl,
      'unreadCounts': unreadCounts,
      'lastReadTimestamps': lastReadTimestamps.map(
        (key, value) => MapEntry(key, value.toIso8601String()),
      ),
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  /// Validates chat data and returns a Result with validation errors
  static Result<Chat> validate({
    required String id,
    required String title,
    required ChatType type,
    required List<String> participantIds,
    String? lastMessageId,
    String? lastMessageContent,
    DateTime? lastMessageTimestamp,
    String? lastMessageSenderId,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? createdBy,
    String? imageUrl,
    Map<String, int> unreadCounts = const {},
    Map<String, DateTime> lastReadTimestamps = const {},
    bool isActive = true,
    Map<String, dynamic> metadata = const {},
  }) {
    final errors = <String>[];

    // Validate required fields
    if (id.trim().isEmpty) {
      errors.add('Chat ID cannot be empty');
    }

    if (title.trim().isEmpty) {
      errors.add('Chat title cannot be empty');
    } else if (title.trim().length > 100) {
      errors.add('Chat title cannot exceed 100 characters');
    }

    // Validate participants
    if (participantIds.isEmpty) {
      errors.add('Chat must have at least one participant');
    }

    if (participantIds.length > 1000) {
      errors.add('Chat cannot have more than 1000 participants');
    }

    // Validate participant IDs
    for (final participantId in participantIds) {
      if (participantId.trim().isEmpty) {
        errors.add('Participant IDs cannot be empty');
        break;
      }
    }

    // Check for duplicate participants
    if (participantIds.toSet().length != participantIds.length) {
      errors.add('Duplicate participants are not allowed');
    }

    // Validate chat type specific rules
    if (type == ChatType.direct && participantIds.length != 2) {
      errors.add('Direct chats must have exactly 2 participants');
    }

    if (type == ChatType.group && participantIds.length < 3) {
      errors.add('Group chats must have at least 3 participants');
    }

    // Validate timestamps
    if (createdAt.isAfter(DateTime.now().add(const Duration(minutes: 5)))) {
      errors.add('Created timestamp cannot be in the future');
    }

    if (updatedAt.isBefore(createdAt)) {
      errors.add('Updated timestamp cannot be before created timestamp');
    }

    if (updatedAt.isAfter(DateTime.now().add(const Duration(minutes: 5)))) {
      errors.add('Updated timestamp cannot be in the future');
    }

    // Validate last message data consistency
    if (lastMessageId != null && lastMessageContent == null) {
      errors.add('Last message content is required when last message ID is provided');
    }

    if (lastMessageContent != null && lastMessageId == null) {
      errors.add('Last message ID is required when last message content is provided');
    }

    if (lastMessageTimestamp != null && lastMessageId == null) {
      errors.add('Last message ID is required when last message timestamp is provided');
    }

    if (lastMessageSenderId != null && lastMessageId == null) {
      errors.add('Last message ID is required when last message sender ID is provided');
    }

    // Validate last message sender is a participant
    if (lastMessageSenderId != null && !participantIds.contains(lastMessageSenderId)) {
      errors.add('Last message sender must be a participant in the chat');
    }

    // Validate unread counts
    for (final entry in unreadCounts.entries) {
      if (!participantIds.contains(entry.key)) {
        errors.add('Unread count user must be a participant in the chat');
        break;
      }
      if (entry.value < 0) {
        errors.add('Unread count cannot be negative');
        break;
      }
    }

    // Validate last read timestamps
    for (final entry in lastReadTimestamps.entries) {
      if (!participantIds.contains(entry.key)) {
        errors.add('Last read timestamp user must be a participant in the chat');
        break;
      }
      if (entry.value.isAfter(DateTime.now().add(const Duration(minutes: 5)))) {
        errors.add('Last read timestamp cannot be in the future');
        break;
      }
    }

    // Validate creator is a participant
    if (createdBy != null && !participantIds.contains(createdBy)) {
      errors.add('Chat creator must be a participant in the chat');
    }

    if (errors.isNotEmpty) {
      return Result.error('Validation failed: ${errors.join(', ')}');
    }

    return Result.success(Chat(
      id: id.trim(),
      title: title.trim(),
      type: type,
      participantIds: participantIds.map((id) => id.trim()).toList(),
      lastMessageId: lastMessageId?.trim(),
      lastMessageContent: lastMessageContent?.trim(),
      lastMessageTimestamp: lastMessageTimestamp,
      lastMessageSenderId: lastMessageSenderId?.trim(),
      createdAt: createdAt,
      updatedAt: updatedAt,
      createdBy: createdBy?.trim(),
      imageUrl: imageUrl?.trim(),
      unreadCounts: unreadCounts,
      lastReadTimestamps: lastReadTimestamps,
      isActive: isActive,
      metadata: metadata,
    ));
  }

  /// Creates a copy of the chat with updated fields
  Chat copyWith({
    String? id,
    String? title,
    ChatType? type,
    List<String>? participantIds,
    String? lastMessageId,
    String? lastMessageContent,
    DateTime? lastMessageTimestamp,
    String? lastMessageSenderId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? imageUrl,
    Map<String, int>? unreadCounts,
    Map<String, DateTime>? lastReadTimestamps,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return Chat(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      participantIds: participantIds ?? this.participantIds,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastMessageContent: lastMessageContent ?? this.lastMessageContent,
      lastMessageTimestamp: lastMessageTimestamp ?? this.lastMessageTimestamp,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      imageUrl: imageUrl ?? this.imageUrl,
      unreadCounts: unreadCounts ?? this.unreadCounts,
      lastReadTimestamps: lastReadTimestamps ?? this.lastReadTimestamps,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Updates the last message information
  Chat updateLastMessage({
    required String messageId,
    required String content,
    required DateTime timestamp,
    required String senderId,
  }) {
    return copyWith(
      lastMessageId: messageId,
      lastMessageContent: content,
      lastMessageTimestamp: timestamp,
      lastMessageSenderId: senderId,
      updatedAt: DateTime.now(),
    );
  }

  /// Adds a participant to the chat
  Chat addParticipant(String userId) {
    if (participantIds.contains(userId)) return this;
    
    return copyWith(
      participantIds: [...participantIds, userId],
      updatedAt: DateTime.now(),
    );
  }

  /// Removes a participant from the chat
  Chat removeParticipant(String userId) {
    if (!participantIds.contains(userId)) return this;
    
    final newParticipants = participantIds.where((id) => id != userId).toList();
    final newUnreadCounts = Map<String, int>.from(unreadCounts)..remove(userId);
    final newLastReadTimestamps = Map<String, DateTime>.from(lastReadTimestamps)..remove(userId);
    
    return copyWith(
      participantIds: newParticipants,
      unreadCounts: newUnreadCounts,
      lastReadTimestamps: newLastReadTimestamps,
      updatedAt: DateTime.now(),
    );
  }

  /// Updates the unread count for a specific user
  Chat updateUnreadCount(String userId, int count) {
    if (!participantIds.contains(userId)) return this;
    
    final newUnreadCounts = Map<String, int>.from(unreadCounts);
    if (count <= 0) {
      newUnreadCounts.remove(userId);
    } else {
      newUnreadCounts[userId] = count;
    }
    
    return copyWith(unreadCounts: newUnreadCounts);
  }

  /// Increments the unread count for a specific user
  Chat incrementUnreadCount(String userId) {
    if (!participantIds.contains(userId)) return this;
    
    final currentCount = unreadCounts[userId] ?? 0;
    return updateUnreadCount(userId, currentCount + 1);
  }

  /// Clears the unread count for a specific user
  Chat clearUnreadCount(String userId) {
    return updateUnreadCount(userId, 0);
  }

  /// Updates the last read timestamp for a specific user
  Chat updateLastReadTimestamp(String userId, DateTime timestamp) {
    if (!participantIds.contains(userId)) return this;
    
    final newLastReadTimestamps = Map<String, DateTime>.from(lastReadTimestamps);
    newLastReadTimestamps[userId] = timestamp;
    
    return copyWith(lastReadTimestamps: newLastReadTimestamps);
  }

  /// Marks the chat as read for a specific user
  Chat markAsRead(String userId) {
    final now = DateTime.now();
    return updateLastReadTimestamp(userId, now).clearUnreadCount(userId);
  }

  /// Archives or deactivates the chat
  Chat archive() {
    return copyWith(isActive: false, updatedAt: DateTime.now());
  }

  /// Unarchives or reactivates the chat
  Chat unarchive() {
    return copyWith(isActive: true, updatedAt: DateTime.now());
  }

  /// Checks if a user is a participant in the chat
  bool hasParticipant(String userId) => participantIds.contains(userId);

  /// Gets the unread count for a specific user
  int getUnreadCount(String userId) => unreadCounts[userId] ?? 0;

  /// Gets the last read timestamp for a specific user
  DateTime? getLastReadTimestamp(String userId) => lastReadTimestamps[userId];

  /// Checks if the chat has unread messages for a specific user
  bool hasUnreadMessages(String userId) => getUnreadCount(userId) > 0;

  /// Checks if the chat is a direct message
  bool get isDirectMessage => type == ChatType.direct;

  /// Checks if the chat is a group chat
  bool get isGroupChat => type == ChatType.group;

  /// Checks if the chat is a course chat
  bool get isCourseChat => type == ChatType.course;

  /// Checks if the chat has a last message
  bool get hasLastMessage => lastMessageId != null;

  /// Returns the number of participants
  int get participantCount => participantIds.length;

  /// Returns the total unread count across all users
  int get totalUnreadCount => unreadCounts.values.fold(0, (sum, count) => sum + count);

  /// Returns a formatted timestamp string for the last message
  String? get formattedLastMessageTimestamp {
    if (lastMessageTimestamp == null) return null;
    
    final now = DateTime.now();
    final difference = now.difference(lastMessageTimestamp!);

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

  /// Returns a preview of the last message content
  String? get lastMessagePreview {
    if (lastMessageContent == null) return null;
    
    if (lastMessageContent!.length <= 50) return lastMessageContent;
    return '${lastMessageContent!.substring(0, 47)}...';
  }

  /// Gets the other participant's ID in a direct message
  String? getOtherParticipantId(String currentUserId) {
    if (!isDirectMessage) return null;
    
    return participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  /// Checks if the chat matches a search query
  bool matchesSearch(String query) {
    final lowerQuery = query.toLowerCase();
    return title.toLowerCase().contains(lowerQuery) ||
           (lastMessageContent?.toLowerCase().contains(lowerQuery) ?? false);
  }

  /// Returns the age of the chat in days
  int get ageInDays {
    final now = DateTime.now();
    return now.difference(createdAt).inDays;
  }

  /// Checks if the chat is recent (less than 1 day old)
  bool get isRecent => ageInDays < 1;

  /// Returns the display name for the chat type
  String get typeDisplayName {
    return switch (type) {
      ChatType.direct => 'Direct Message',
      ChatType.group => 'Group Chat',
      ChatType.course => 'Course Chat',
    };
  }

  /// Checks if the chat can be deleted by a specific user
  bool canBeDeletedBy(String userId) {
    return createdBy == userId || (isDirectMessage && hasParticipant(userId));
  }

  /// Checks if a user can add participants to the chat
  bool canAddParticipants(String userId) {
    return (isGroupChat || isCourseChat) && hasParticipant(userId);
  }

  /// Checks if a user can remove participants from the chat
  bool canRemoveParticipants(String userId) {
    return createdBy == userId || (isGroupChat && hasParticipant(userId));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Chat &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          type == other.type &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      type.hashCode ^
      createdAt.hashCode;

  @override
  String toString() {
    return 'Chat(id: $id, title: $title, type: ${type.value}, participants: ${participantIds.length}, active: $isActive)';
  }
}