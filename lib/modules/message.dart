import '../core/core.dart';

/// Enum representing different message types
enum MessageType {
  text('text'),
  image('image'),
  file('file'),
  system('system');

  const MessageType(this.value);
  final String value;

  static MessageType fromString(String value) {
    return MessageType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => throw ArgumentError('Invalid message type: $value'),
    );
  }
}

/// Enum representing message status
enum MessageStatus {
  sending('sending'),
  sent('sent'),
  delivered('delivered'),
  read('read'),
  failed('failed');

  const MessageStatus(this.value);
  final String value;

  static MessageStatus fromString(String value) {
    return MessageStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => throw ArgumentError('Invalid message status: $value'),
    );
  }
}

/// Represents a message in a chat conversation
class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final DateTime timestamp;
  final DateTime? readAt;
  final DateTime? deliveredAt;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final String? replyToMessageId;
  final Map<String, dynamic> metadata;

  const Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.type,
    required this.status,
    required this.timestamp,
    this.readAt,
    this.deliveredAt,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.replyToMessageId,
    this.metadata = const {},
  });

  /// Creates a Message from JSON data
  factory Message.fromJson(Map<String, dynamic> json) {
    try {
      return Message(
        id: json['id'] as String,
        chatId: json['chatId'] as String,
        senderId: json['senderId'] as String,
        content: json['content'] as String,
        type: MessageType.fromString(json['type'] as String),
        status: MessageStatus.fromString(json['status'] as String),
        timestamp: DateTime.parse(json['timestamp'] as String),
        readAt: json['readAt'] != null ? DateTime.parse(json['readAt'] as String) : null,
        deliveredAt: json['deliveredAt'] != null ? DateTime.parse(json['deliveredAt'] as String) : null,
        fileUrl: json['fileUrl'] as String?,
        fileName: json['fileName'] as String?,
        fileSize: json['fileSize'] as int?,
        replyToMessageId: json['replyToMessageId'] as String?,
        metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      );
    } catch (e) {
      throw FormatException('Invalid message JSON format: $e');
    }
  }

  /// Converts Message to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'content': content,
      'type': type.value,
      'status': status.value,
      'timestamp': timestamp.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'replyToMessageId': replyToMessageId,
      'metadata': metadata,
    };
  }

  /// Validates message data and returns a Result with validation errors
  static Result<Message> validate({
    required String id,
    required String chatId,
    required String senderId,
    required String content,
    required MessageType type,
    required MessageStatus status,
    required DateTime timestamp,
    DateTime? readAt,
    DateTime? deliveredAt,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    String? replyToMessageId,
    Map<String, dynamic> metadata = const {},
  }) {
    final errors = <String>[];

    // Validate required fields
    if (id.trim().isEmpty) {
      errors.add('Message ID cannot be empty');
    }

    if (chatId.trim().isEmpty) {
      errors.add('Chat ID cannot be empty');
    }

    if (senderId.trim().isEmpty) {
      errors.add('Sender ID cannot be empty');
    }

    // Validate content based on message type
    if (type == MessageType.text && content.trim().isEmpty) {
      errors.add('Text message content cannot be empty');
    }

    if (content.trim().length > 10000) {
      errors.add('Message content cannot exceed 10000 characters');
    }

    // Validate file-related fields for file/image messages
    if ((type == MessageType.file || type == MessageType.image)) {
      if (fileUrl == null || fileUrl.trim().isEmpty) {
        errors.add('File URL is required for file/image messages');
      }
      if (fileName == null || fileName.trim().isEmpty) {
        errors.add('File name is required for file/image messages');
      }
      if (fileSize == null || fileSize <= 0) {
        errors.add('Valid file size is required for file/image messages');
      }
    }

    // Validate timestamp
    if (timestamp.isAfter(DateTime.now().add(const Duration(minutes: 5)))) {
      errors.add('Message timestamp cannot be in the future');
    }

    // Validate status timestamps
    if (readAt != null && readAt.isBefore(timestamp)) {
      errors.add('Read timestamp cannot be before message timestamp');
    }

    if (deliveredAt != null && deliveredAt.isBefore(timestamp)) {
      errors.add('Delivered timestamp cannot be before message timestamp');
    }

    if (readAt != null && deliveredAt != null && readAt.isBefore(deliveredAt)) {
      errors.add('Read timestamp cannot be before delivered timestamp');
    }

    // Validate status consistency
    if (status == MessageStatus.read && readAt == null) {
      errors.add('Read messages must have a read timestamp');
    }

    if (status == MessageStatus.delivered && deliveredAt == null) {
      errors.add('Delivered messages must have a delivered timestamp');
    }

    if (errors.isNotEmpty) {
      return Result.error('Validation failed: ${errors.join(', ')}');
    }

    return Result.success(Message(
      id: id.trim(),
      chatId: chatId.trim(),
      senderId: senderId.trim(),
      content: content.trim(),
      type: type,
      status: status,
      timestamp: timestamp,
      readAt: readAt,
      deliveredAt: deliveredAt,
      fileUrl: fileUrl?.trim(),
      fileName: fileName?.trim(),
      fileSize: fileSize,
      replyToMessageId: replyToMessageId?.trim(),
      metadata: metadata,
    ));
  }

  /// Creates a copy of the message with updated fields
  Message copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? content,
    MessageType? type,
    MessageStatus? status,
    DateTime? timestamp,
    DateTime? readAt,
    DateTime? deliveredAt,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      readAt: readAt ?? this.readAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Marks the message as delivered
  Message markAsDelivered() {
    if (status == MessageStatus.delivered || status == MessageStatus.read) {
      return this;
    }
    
    return copyWith(
      status: MessageStatus.delivered,
      deliveredAt: DateTime.now(),
    );
  }

  /// Marks the message as read
  Message markAsRead() {
    final now = DateTime.now();
    return copyWith(
      status: MessageStatus.read,
      readAt: now,
      deliveredAt: deliveredAt ?? now,
    );
  }

  /// Marks the message as failed
  Message markAsFailed() {
    return copyWith(status: MessageStatus.failed);
  }

  /// Updates the message status
  Message updateStatus(MessageStatus newStatus) {
    return switch (newStatus) {
      MessageStatus.delivered => markAsDelivered(),
      MessageStatus.read => markAsRead(),
      MessageStatus.failed => markAsFailed(),
      _ => copyWith(status: newStatus),
    };
  }

  /// Checks if the message is sent by a specific user
  bool isSentBy(String userId) => senderId == userId;

  /// Checks if the message has been read
  bool get isRead => status == MessageStatus.read;

  /// Checks if the message has been delivered
  bool get isDelivered => status == MessageStatus.delivered || status == MessageStatus.read;

  /// Checks if the message failed to send
  bool get hasFailed => status == MessageStatus.failed;

  /// Checks if the message is currently being sent
  bool get isSending => status == MessageStatus.sending;

  /// Checks if the message is a reply to another message
  bool get isReply => replyToMessageId != null;

  /// Checks if the message contains a file
  bool get hasFile => type == MessageType.file || type == MessageType.image;

  /// Checks if the message is a system message
  bool get isSystemMessage => type == MessageType.system;

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

  /// Returns a formatted file size string
  String? get formattedFileSize {
    if (fileSize == null) return null;
    
    const units = ['B', 'KB', 'MB', 'GB'];
    double size = fileSize!.toDouble();
    int unitIndex = 0;
    
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    
    return '${size.toStringAsFixed(1)} ${units[unitIndex]}';
  }

  /// Returns a preview of the message content
  String get contentPreview {
    switch (type) {
      case MessageType.text:
        if (content.length <= 50) return content;
        return '${content.substring(0, 47)}...';
      case MessageType.image:
        return '📷 Image';
      case MessageType.file:
        return '📎 ${fileName ?? 'File'}';
      case MessageType.system:
        return content;
    }
  }

  /// Checks if the message matches a search query
  bool matchesSearch(String query) {
    final lowerQuery = query.toLowerCase();
    return content.toLowerCase().contains(lowerQuery) ||
           (fileName?.toLowerCase().contains(lowerQuery) ?? false);
  }

  /// Returns the age of the message in minutes
  int get ageInMinutes {
    final now = DateTime.now();
    return now.difference(timestamp).inMinutes;
  }

  /// Checks if the message is recent (less than 5 minutes old)
  bool get isRecent => ageInMinutes < 5;

  /// Returns the display name for the message type
  String get typeDisplayName {
    return switch (type) {
      MessageType.text => 'Text',
      MessageType.image => 'Image',
      MessageType.file => 'File',
      MessageType.system => 'System',
    };
  }

  /// Returns the display name for the message status
  String get statusDisplayName {
    return switch (status) {
      MessageStatus.sending => 'Sending',
      MessageStatus.sent => 'Sent',
      MessageStatus.delivered => 'Delivered',
      MessageStatus.read => 'Read',
      MessageStatus.failed => 'Failed',
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Message &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          chatId == other.chatId &&
          senderId == other.senderId &&
          content == other.content &&
          type == other.type &&
          status == other.status &&
          timestamp == other.timestamp;

  @override
  int get hashCode =>
      id.hashCode ^
      chatId.hashCode ^
      senderId.hashCode ^
      content.hashCode ^
      type.hashCode ^
      status.hashCode ^
      timestamp.hashCode;

  @override
  String toString() {
    return 'Message(id: $id, chatId: $chatId, senderId: $senderId, type: ${type.value}, status: ${status.value}, content: $contentPreview)';
  }
}