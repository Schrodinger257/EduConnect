import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/result.dart';
import '../modules/chat.dart';
import '../modules/message.dart';

/// Abstract repository interface for chat-related operations
abstract class ChatRepository {
  /// Creates a new chat
  Future<Result<Chat>> createChat(Chat chat);

  /// Retrieves a chat by ID
  Future<Result<Chat>> getChatById(String chatId);

  /// Retrieves chats for a specific user
  Future<Result<List<Chat>>> getUserChats(String userId);

  /// Gets a stream of chats for real-time updates
  Stream<List<Chat>> getUserChatsStream(String userId);

  /// Updates chat information
  Future<Result<Chat>> updateChat(Chat chat);

  /// Deletes a chat
  Future<Result<void>> deleteChat(String chatId);

  /// Adds a participant to a chat
  Future<Result<void>> addParticipant(String chatId, String userId);

  /// Removes a participant from a chat
  Future<Result<void>> removeParticipant(String chatId, String userId);

  /// Sends a message in a chat
  Future<Result<Message>> sendMessage(Message message);

  /// Retrieves messages for a specific chat
  Future<Result<List<Message>>> getMessages({
    required String chatId,
    int limit = 50,
    DocumentSnapshot? lastDocument,
  });

  /// Gets a stream of messages for real-time updates
  Stream<List<Message>> getMessagesStream(String chatId, {int limit = 50});

  /// Updates message status (delivered, read, etc.)
  Future<Result<void>> updateMessageStatus({
    required String messageId,
    required MessageStatus status,
    DateTime? timestamp,
  });

  /// Marks messages as read for a user
  Future<Result<void>> markMessagesAsRead({
    required String chatId,
    required String userId,
    required List<String> messageIds,
  });

  /// Updates unread count for a user in a chat
  Future<Result<void>> updateUnreadCount({
    required String chatId,
    required String userId,
    required int count,
  });

  /// Gets unread message count for a user across all chats
  Future<Result<int>> getTotalUnreadCount(String userId);

  /// Searches messages within a chat
  Future<Result<List<Message>>> searchMessages({
    required String chatId,
    required String query,
    int limit = 20,
  });

  /// Gets message by ID
  Future<Result<Message>> getMessageById(String messageId);

  /// Deletes a message
  Future<Result<void>> deleteMessage(String messageId);

  /// Updates a message (for editing)
  Future<Result<Message>> updateMessage(Message message);

  /// Archives a chat
  Future<Result<void>> archiveChat(String chatId, String userId);

  /// Unarchives a chat
  Future<Result<void>> unarchiveChat(String chatId, String userId);

  /// Gets typing indicators for a chat
  Stream<List<String>> getTypingIndicators(String chatId);

  /// Sets typing indicator for a user
  Future<Result<void>> setTypingIndicator({
    required String chatId,
    required String userId,
    required bool isTyping,
  });

  /// Retries failed message sending
  Future<Result<Message>> retryMessage(String messageId);

  /// Gets message delivery status for all participants
  Future<Result<Map<String, MessageStatus>>> getMessageDeliveryStatus(String messageId);
}