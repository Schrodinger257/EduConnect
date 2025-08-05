import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/core.dart';
import '../modules/message.dart';
import '../repositories/chat_repository.dart';

/// Service for managing message queuing and retry functionality for offline scenarios
class MessageQueueService with LoggerMixin {
  static const String _queueKey = 'message_queue';
  static const String _failedMessagesKey = 'failed_messages';
  static const int _maxRetryAttempts = 3;
  static const Duration _retryDelay = Duration(seconds: 5);

  final ChatRepository _chatRepository;
  final List<QueuedMessage> _messageQueue = [];
  final List<QueuedMessage> _failedMessages = [];
  Timer? _retryTimer;
  bool _isProcessing = false;

  MessageQueueService({
    required ChatRepository chatRepository,
  }) : _chatRepository = chatRepository;

  /// Initializes the message queue service
  Future<void> initialize() async {
    logInfo('Initializing message queue service');
    await _loadQueueFromStorage();
    await _loadFailedMessagesFromStorage();
    _startRetryTimer();
  }

  /// Disposes the service and cleans up resources
  void dispose() {
    logInfo('Disposing message queue service');
    _retryTimer?.cancel();
  }

  /// Queues a message for sending
  Future<void> queueMessage(Message message) async {
    logInfo('Queuing message: ${message.id}');
    
    final queuedMessage = QueuedMessage(
      message: message,
      attempts: 0,
      queuedAt: DateTime.now(),
    );
    
    _messageQueue.add(queuedMessage);
    await _saveQueueToStorage();
    
    // Try to process the queue immediately
    _processQueue();
  }

  /// Gets all queued messages
  List<QueuedMessage> get queuedMessages => List.unmodifiable(_messageQueue);

  /// Gets all failed messages
  List<QueuedMessage> get failedMessages => List.unmodifiable(_failedMessages);

  /// Retries a specific failed message
  Future<Result<void>> retryMessage(String messageId) async {
    logInfo('Retrying message: $messageId');
    
    final failedMessage = _failedMessages.firstWhere(
      (qm) => qm.message.id == messageId,
      orElse: () => throw ArgumentError('Message not found in failed queue'),
    );
    
    // Move from failed to queue
    _failedMessages.remove(failedMessage);
    failedMessage.attempts = 0; // Reset attempts
    _messageQueue.add(failedMessage);
    
    await _saveQueueToStorage();
    await _saveFailedMessagesToStorage();
    
    // Process immediately
    _processQueue();
    
    return Result.success(null);
  }

  /// Retries all failed messages
  Future<Result<void>> retryAllFailedMessages() async {
    logInfo('Retrying all failed messages: ${_failedMessages.length}');
    
    if (_failedMessages.isEmpty) {
      return Result.success(null);
    }
    
    // Move all failed messages back to queue
    for (final failedMessage in _failedMessages) {
      failedMessage.attempts = 0; // Reset attempts
      _messageQueue.add(failedMessage);
    }
    
    _failedMessages.clear();
    
    await _saveQueueToStorage();
    await _saveFailedMessagesToStorage();
    
    // Process queue
    _processQueue();
    
    return Result.success(null);
  }

  /// Removes a message from the failed queue
  Future<Result<void>> removeFailedMessage(String messageId) async {
    logInfo('Removing failed message: $messageId');
    
    _failedMessages.removeWhere((qm) => qm.message.id == messageId);
    await _saveFailedMessagesToStorage();
    
    return Result.success(null);
  }

  /// Clears all failed messages
  Future<Result<void>> clearFailedMessages() async {
    logInfo('Clearing all failed messages');
    
    _failedMessages.clear();
    await _saveFailedMessagesToStorage();
    
    return Result.success(null);
  }

  /// Gets the queue status
  QueueStatus get queueStatus => QueueStatus(
    queuedCount: _messageQueue.length,
    failedCount: _failedMessages.length,
    isProcessing: _isProcessing,
  );

  /// Processes the message queue
  Future<void> _processQueue() async {
    if (_isProcessing || _messageQueue.isEmpty) {
      return;
    }

    _isProcessing = true;
    logInfo('Processing message queue: ${_messageQueue.length} messages');

    try {
      final messagesToProcess = List<QueuedMessage>.from(_messageQueue);
      
      for (final queuedMessage in messagesToProcess) {
        await _processQueuedMessage(queuedMessage);
      }
    } catch (e) {
      logError('Error processing message queue', error: e);
    } finally {
      _isProcessing = false;
    }
  }

  /// Processes a single queued message
  Future<void> _processQueuedMessage(QueuedMessage queuedMessage) async {
    logInfo('Processing queued message: ${queuedMessage.message.id}');
    
    queuedMessage.attempts++;
    
    try {
      // Update message status to sending
      final sendingMessage = queuedMessage.message.copyWith(
        status: MessageStatus.sending,
      );
      
      // Attempt to send the message
      final result = await _chatRepository.sendMessage(sendingMessage);
      
      if (result.isSuccess) {
        logInfo('Successfully sent queued message: ${queuedMessage.message.id}');
        
        // Remove from queue
        _messageQueue.remove(queuedMessage);
        await _saveQueueToStorage();
      } else {
        logWarning('Failed to send queued message: ${queuedMessage.message.id} - ${result.error}');
        await _handleFailedMessage(queuedMessage, result.error ?? 'Unknown error');
      }
    } catch (e) {
      logError('Error sending queued message: ${queuedMessage.message.id}', error: e);
      await _handleFailedMessage(queuedMessage, e.toString());
    }
  }

  /// Handles a failed message attempt
  Future<void> _handleFailedMessage(QueuedMessage queuedMessage, String error) async {
    if (queuedMessage.attempts >= _maxRetryAttempts) {
      logWarning('Message exceeded max retry attempts: ${queuedMessage.message.id}');
      
      // Move to failed messages
      _messageQueue.remove(queuedMessage);
      queuedMessage.lastError = error;
      queuedMessage.failedAt = DateTime.now();
      _failedMessages.add(queuedMessage);
      
      await _saveQueueToStorage();
      await _saveFailedMessagesToStorage();
      
      // Update message status to failed
      await _chatRepository.updateMessageStatus(
        messageId: queuedMessage.message.id,
        status: MessageStatus.failed,
      );
    } else {
      logInfo('Will retry message: ${queuedMessage.message.id} (attempt ${queuedMessage.attempts}/$_maxRetryAttempts)');
      queuedMessage.lastError = error;
      await _saveQueueToStorage();
    }
  }

  /// Starts the retry timer for periodic queue processing
  void _startRetryTimer() {
    _retryTimer = Timer.periodic(_retryDelay, (timer) {
      if (_messageQueue.isNotEmpty) {
        _processQueue();
      }
    });
  }

  /// Loads the message queue from local storage
  Future<void> _loadQueueFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_queueKey);
      
      if (queueJson != null) {
        final queueData = jsonDecode(queueJson) as List<dynamic>;
        _messageQueue.clear();
        
        for (final item in queueData) {
          try {
            final queuedMessage = QueuedMessage.fromJson(item as Map<String, dynamic>);
            _messageQueue.add(queuedMessage);
          } catch (e) {
            logError('Error parsing queued message from storage', error: e);
          }
        }
        
        logInfo('Loaded ${_messageQueue.length} messages from queue storage');
      }
    } catch (e) {
      logError('Error loading message queue from storage', error: e);
    }
  }

  /// Saves the message queue to local storage
  Future<void> _saveQueueToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueData = _messageQueue.map((qm) => qm.toJson()).toList();
      await prefs.setString(_queueKey, jsonEncode(queueData));
    } catch (e) {
      logError('Error saving message queue to storage', error: e);
    }
  }

  /// Loads failed messages from local storage
  Future<void> _loadFailedMessagesFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final failedJson = prefs.getString(_failedMessagesKey);
      
      if (failedJson != null) {
        final failedData = jsonDecode(failedJson) as List<dynamic>;
        _failedMessages.clear();
        
        for (final item in failedData) {
          try {
            final queuedMessage = QueuedMessage.fromJson(item as Map<String, dynamic>);
            _failedMessages.add(queuedMessage);
          } catch (e) {
            logError('Error parsing failed message from storage', error: e);
          }
        }
        
        logInfo('Loaded ${_failedMessages.length} failed messages from storage');
      }
    } catch (e) {
      logError('Error loading failed messages from storage', error: e);
    }
  }

  /// Saves failed messages to local storage
  Future<void> _saveFailedMessagesToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final failedData = _failedMessages.map((qm) => qm.toJson()).toList();
      await prefs.setString(_failedMessagesKey, jsonEncode(failedData));
    } catch (e) {
      logError('Error saving failed messages to storage', error: e);
    }
  }
}

/// Represents a queued message with retry information
class QueuedMessage {
  final Message message;
  int attempts;
  final DateTime queuedAt;
  DateTime? failedAt;
  String? lastError;

  QueuedMessage({
    required this.message,
    required this.attempts,
    required this.queuedAt,
    this.failedAt,
    this.lastError,
  });

  /// Creates a QueuedMessage from JSON
  factory QueuedMessage.fromJson(Map<String, dynamic> json) {
    return QueuedMessage(
      message: Message.fromJson(json['message'] as Map<String, dynamic>),
      attempts: json['attempts'] as int,
      queuedAt: DateTime.parse(json['queuedAt'] as String),
      failedAt: json['failedAt'] != null ? DateTime.parse(json['failedAt'] as String) : null,
      lastError: json['lastError'] as String?,
    );
  }

  /// Converts QueuedMessage to JSON
  Map<String, dynamic> toJson() {
    return {
      'message': message.toJson(),
      'attempts': attempts,
      'queuedAt': queuedAt.toIso8601String(),
      'failedAt': failedAt?.toIso8601String(),
      'lastError': lastError,
    };
  }

  /// Checks if this message has failed
  bool get hasFailed => failedAt != null;

  /// Gets the time since the message was queued
  Duration get timeSinceQueued => DateTime.now().difference(queuedAt);

  /// Gets the time since the message failed (if applicable)
  Duration? get timeSinceFailed => failedAt != null ? DateTime.now().difference(failedAt!) : null;

  @override
  String toString() {
    return 'QueuedMessage(messageId: ${message.id}, attempts: $attempts, queued: $queuedAt, failed: $hasFailed)';
  }
}

/// Represents the current status of the message queue
class QueueStatus {
  final int queuedCount;
  final int failedCount;
  final bool isProcessing;

  const QueueStatus({
    required this.queuedCount,
    required this.failedCount,
    required this.isProcessing,
  });

  /// Gets the total number of messages in the system
  int get totalCount => queuedCount + failedCount;

  /// Checks if there are any messages in the queue or failed
  bool get hasMessages => totalCount > 0;

  /// Checks if there are any failed messages
  bool get hasFailedMessages => failedCount > 0;

  @override
  String toString() {
    return 'QueueStatus(queued: $queuedCount, failed: $failedCount, processing: $isProcessing)';
  }
}