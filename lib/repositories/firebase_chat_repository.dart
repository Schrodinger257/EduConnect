import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/result.dart';
import '../core/logger.dart';
import '../modules/chat.dart';
import '../modules/message.dart';
import 'chat_repository.dart';

/// Firebase implementation of ChatRepository
class FirebaseChatRepository implements ChatRepository {
  final FirebaseFirestore _firestore;
  final Logger _logger;

  FirebaseChatRepository({
    FirebaseFirestore? firestore,
    Logger? logger,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _logger = logger ?? Logger();

  @override
  Future<Result<Chat>> createChat(Chat chat) async {
    try {
      _logger.info('Creating chat: ${chat.id}');
      
      final chatData = chat.toJson();
      chatData.remove('id');
      
      // Convert DateTime to Firestore Timestamp
      chatData['createdAt'] = Timestamp.fromDate(chat.createdAt);
      chatData['updatedAt'] = Timestamp.fromDate(chat.updatedAt);
      
      if (chat.lastMessageTimestamp != null) {
        chatData['lastMessageTimestamp'] = Timestamp.fromDate(chat.lastMessageTimestamp!);
      }
      
      // Convert lastReadTimestamps to Firestore format
      final lastReadTimestamps = <String, Timestamp>{};
      for (final entry in chat.lastReadTimestamps.entries) {
        lastReadTimestamps[entry.key] = Timestamp.fromDate(entry.value);
      }
      chatData['lastReadTimestamps'] = lastReadTimestamps;
      
      await _firestore.collection('chats').doc(chat.id).set(chatData);
      
      _logger.info('Successfully created chat: ${chat.id}');
      return Result.success(chat);
    } catch (e) {
      _logger.error('Error creating chat: $e');
      return Result.error('Failed to create chat: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<Chat>> getChatById(String chatId) async {
    try {
      _logger.info('Fetching chat with ID: $chatId');
      
      final doc = await _firestore.collection('chats').doc(chatId).get();
      
      if (!doc.exists) {
        _logger.warning('Chat not found: $chatId');
        return Result.error('Chat not found');
      }

      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      
      // Convert Firestore Timestamps to DateTime
      if (data['createdAt'] is Timestamp) {
        data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
      }
      if (data['updatedAt'] is Timestamp) {
        data['updatedAt'] = (data['updatedAt'] as Timestamp).toDate().toIso8601String();
      }
      if (data['lastMessageTimestamp'] is Timestamp) {
        data['lastMessageTimestamp'] = (data['lastMessageTimestamp'] as Timestamp).toDate().toIso8601String();
      }
      
      // Convert lastReadTimestamps from Firestore format
      if (data['lastReadTimestamps'] is Map) {
        final lastReadTimestamps = <String, String>{};
        final firestoreTimestamps = data['lastReadTimestamps'] as Map<String, dynamic>;
        for (final entry in firestoreTimestamps.entries) {
          if (entry.value is Timestamp) {
            lastReadTimestamps[entry.key] = (entry.value as Timestamp).toDate().toIso8601String();
          }
        }
        data['lastReadTimestamps'] = lastReadTimestamps;
      }
      
      final chat = Chat.fromJson(data);
      
      _logger.info('Successfully fetched chat: $chatId');
      return Result.success(chat);
    } catch (e) {
      _logger.error('Error fetching chat: $e');
      return Result.error('Failed to fetch chat: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<List<Chat>>> getUserChats(String userId) async {
    try {
      _logger.info('Fetching chats for user: $userId');
      
      final snapshot = await _firestore
          .collection('chats')
          .where('participantIds', arrayContains: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('updatedAt', descending: true)
          .get();
      
      final chats = <Chat>[];
      
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          
          // Convert Firestore Timestamps to DateTime
          if (data['createdAt'] is Timestamp) {
            data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
          }
          if (data['updatedAt'] is Timestamp) {
            data['updatedAt'] = (data['updatedAt'] as Timestamp).toDate().toIso8601String();
          }
          if (data['lastMessageTimestamp'] is Timestamp) {
            data['lastMessageTimestamp'] = (data['lastMessageTimestamp'] as Timestamp).toDate().toIso8601String();
          }
          
          // Convert lastReadTimestamps from Firestore format
          if (data['lastReadTimestamps'] is Map) {
            final lastReadTimestamps = <String, String>{};
            final firestoreTimestamps = data['lastReadTimestamps'] as Map<String, dynamic>;
            for (final entry in firestoreTimestamps.entries) {
              if (entry.value is Timestamp) {
                lastReadTimestamps[entry.key] = (entry.value as Timestamp).toDate().toIso8601String();
              }
            }
            data['lastReadTimestamps'] = lastReadTimestamps;
          }
          
          final chat = Chat.fromJson(data);
          chats.add(chat);
        } catch (e) {
          _logger.error('Error parsing chat ${doc.id}: $e');
        }
      }
      
      _logger.info('Successfully fetched ${chats.length} chats for user: $userId');
      return Result.success(chats);
    } catch (e) {
      _logger.error('Error fetching user chats: $e');
      return Result.error('Failed to fetch user chats: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Stream<List<Chat>> getUserChatsStream(String userId) {
    _logger.info('Starting chat stream for user: $userId');
    
    return _firestore
        .collection('chats')
        .where('participantIds', arrayContains: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final chats = <Chat>[];
      
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          
          // Convert Firestore Timestamps to DateTime
          if (data['createdAt'] is Timestamp) {
            data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
          }
          if (data['updatedAt'] is Timestamp) {
            data['updatedAt'] = (data['updatedAt'] as Timestamp).toDate().toIso8601String();
          }
          if (data['lastMessageTimestamp'] is Timestamp) {
            data['lastMessageTimestamp'] = (data['lastMessageTimestamp'] as Timestamp).toDate().toIso8601String();
          }
          
          // Convert lastReadTimestamps from Firestore format
          if (data['lastReadTimestamps'] is Map) {
            final lastReadTimestamps = <String, String>{};
            final firestoreTimestamps = data['lastReadTimestamps'] as Map<String, dynamic>;
            for (final entry in firestoreTimestamps.entries) {
              if (entry.value is Timestamp) {
                lastReadTimestamps[entry.key] = (entry.value as Timestamp).toDate().toIso8601String();
              }
            }
            data['lastReadTimestamps'] = lastReadTimestamps;
          }
          
          final chat = Chat.fromJson(data);
          chats.add(chat);
        } catch (e) {
          _logger.error('Error parsing chat ${doc.id} in stream: $e');
        }
      }
      
      return chats;
    }).handleError((error) {
      _logger.error('Error in chat stream: $error');
      return <Chat>[];
    });
  }

  @override
  Future<Result<Chat>> updateChat(Chat chat) async {
    try {
      _logger.info('Updating chat: ${chat.id}');
      
      final chatData = chat.toJson();
      chatData.remove('id');
      
      // Convert DateTime to Firestore Timestamp
      chatData['createdAt'] = Timestamp.fromDate(chat.createdAt);
      chatData['updatedAt'] = Timestamp.fromDate(DateTime.now());
      
      if (chat.lastMessageTimestamp != null) {
        chatData['lastMessageTimestamp'] = Timestamp.fromDate(chat.lastMessageTimestamp!);
      }
      
      // Convert lastReadTimestamps to Firestore format
      final lastReadTimestamps = <String, Timestamp>{};
      for (final entry in chat.lastReadTimestamps.entries) {
        lastReadTimestamps[entry.key] = Timestamp.fromDate(entry.value);
      }
      chatData['lastReadTimestamps'] = lastReadTimestamps;
      
      await _firestore.collection('chats').doc(chat.id).update(chatData);
      
      // Return the updated chat
      final updatedChatResult = await getChatById(chat.id);
      if (updatedChatResult.isError) {
        return updatedChatResult;
      }
      
      _logger.info('Successfully updated chat: ${chat.id}');
      return Result.success(updatedChatResult.data!);
    } catch (e) {
      _logger.error('Error updating chat: $e');
      return Result.error('Failed to update chat: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteChat(String chatId) async {
    try {
      _logger.info('Deleting chat: $chatId');
      
      // Delete all messages in the chat first
      final messagesSnapshot = await _firestore
          .collection('messages')
          .where('chatId', isEqualTo: chatId)
          .get();
      
      final batch = _firestore.batch();
      
      for (final doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete the chat document
      batch.delete(_firestore.collection('chats').doc(chatId));
      
      await batch.commit();
      
      _logger.info('Successfully deleted chat: $chatId');
      return Result.success(null);
    } catch (e) {
      _logger.error('Error deleting chat: $e');
      return Result.error('Failed to delete chat: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> addParticipant(String chatId, String userId) async {
    try {
      _logger.info('Adding participant $userId to chat: $chatId');
      
      await _firestore.collection('chats').doc(chatId).update({
        'participantIds': FieldValue.arrayUnion([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      _logger.info('Successfully added participant $userId to chat: $chatId');
      return Result.success(null);
    } catch (e) {
      _logger.error('Error adding participant: $e');
      return Result.error('Failed to add participant: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> removeParticipant(String chatId, String userId) async {
    try {
      _logger.info('Removing participant $userId from chat: $chatId');
      
      await _firestore.collection('chats').doc(chatId).update({
        'participantIds': FieldValue.arrayRemove([userId]),
        'unreadCounts.$userId': FieldValue.delete(),
        'lastReadTimestamps.$userId': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      _logger.info('Successfully removed participant $userId from chat: $chatId');
      return Result.success(null);
    } catch (e) {
      _logger.error('Error removing participant: $e');
      return Result.error('Failed to remove participant: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<Message>> sendMessage(Message message) async {
    try {
      _logger.info('Sending message: ${message.id}');
      
      final messageData = message.toJson();
      messageData.remove('id');
      
      // Convert DateTime to Firestore Timestamp
      messageData['timestamp'] = Timestamp.fromDate(message.timestamp);
      if (message.readAt != null) {
        messageData['readAt'] = Timestamp.fromDate(message.readAt!);
      }
      if (message.deliveredAt != null) {
        messageData['deliveredAt'] = Timestamp.fromDate(message.deliveredAt!);
      }
      
      // Use a transaction to ensure consistency
      await _firestore.runTransaction((transaction) async {
        // Add the message
        final messageRef = _firestore.collection('messages').doc(message.id);
        transaction.set(messageRef, messageData);
        
        // Update the chat's last message info and increment unread counts
        final chatRef = _firestore.collection('chats').doc(message.chatId);
        final chatDoc = await transaction.get(chatRef);
        
        if (chatDoc.exists) {
          final chatData = chatDoc.data() as Map<String, dynamic>;
          final participantIds = List<String>.from(chatData['participantIds'] ?? []);
          final currentUnreadCounts = Map<String, int>.from(chatData['unreadCounts'] ?? {});
          
          // Increment unread count for all participants except the sender
          for (final participantId in participantIds) {
            if (participantId != message.senderId) {
              currentUnreadCounts[participantId] = (currentUnreadCounts[participantId] ?? 0) + 1;
            }
          }
          
          transaction.update(chatRef, {
            'lastMessageId': message.id,
            'lastMessageContent': message.content,
            'lastMessageTimestamp': Timestamp.fromDate(message.timestamp),
            'lastMessageSenderId': message.senderId,
            'unreadCounts': currentUnreadCounts,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
      
      _logger.info('Successfully sent message: ${message.id}');
      return Result.success(message);
    } catch (e) {
      _logger.error('Error sending message: $e');
      return Result.error('Failed to send message: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<List<Message>>> getMessages({
    required String chatId,
    int limit = 50,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      _logger.info('Fetching messages for chat: $chatId');
      
      Query query = _firestore
          .collection('messages')
          .where('chatId', isEqualTo: chatId)
          .orderBy('timestamp', descending: true)
          .limit(limit);
      
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      
      final snapshot = await query.get();
      final messages = <Message>[];
      
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          
          // Convert Firestore Timestamps to DateTime
          if (data['timestamp'] is Timestamp) {
            data['timestamp'] = (data['timestamp'] as Timestamp).toDate().toIso8601String();
          }
          if (data['readAt'] is Timestamp) {
            data['readAt'] = (data['readAt'] as Timestamp).toDate().toIso8601String();
          }
          if (data['deliveredAt'] is Timestamp) {
            data['deliveredAt'] = (data['deliveredAt'] as Timestamp).toDate().toIso8601String();
          }
          
          final message = Message.fromJson(data);
          messages.add(message);
        } catch (e) {
          _logger.error('Error parsing message ${doc.id}: $e');
        }
      }
      
      // Reverse to get chronological order (oldest first)
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      _logger.info('Successfully fetched ${messages.length} messages for chat: $chatId');
      return Result.success(messages);
    } catch (e) {
      _logger.error('Error fetching messages: $e');
      return Result.error('Failed to fetch messages: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Stream<List<Message>> getMessagesStream(String chatId, {int limit = 50}) {
    _logger.info('Starting message stream for chat: $chatId');
    
    return _firestore
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .orderBy('timestamp', descending: false)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final messages = <Message>[];
      
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          
          // Convert Firestore Timestamps to DateTime
          if (data['timestamp'] is Timestamp) {
            data['timestamp'] = (data['timestamp'] as Timestamp).toDate().toIso8601String();
          }
          if (data['readAt'] is Timestamp) {
            data['readAt'] = (data['readAt'] as Timestamp).toDate().toIso8601String();
          }
          if (data['deliveredAt'] is Timestamp) {
            data['deliveredAt'] = (data['deliveredAt'] as Timestamp).toDate().toIso8601String();
          }
          
          final message = Message.fromJson(data);
          messages.add(message);
        } catch (e) {
          _logger.error('Error parsing message ${doc.id} in stream: $e');
        }
      }
      
      return messages;
    }).handleError((error) {
      _logger.error('Error in message stream: $error');
      return <Message>[];
    });
  }

  @override
  Future<Result<void>> updateMessageStatus({
    required String messageId,
    required MessageStatus status,
    DateTime? timestamp,
  }) async {
    try {
      _logger.info('Updating message status: $messageId to ${status.value}');
      
      final updateData = <String, dynamic>{
        'status': status.value,
      };
      
      final now = timestamp ?? DateTime.now();
      
      switch (status) {
        case MessageStatus.delivered:
          updateData['deliveredAt'] = Timestamp.fromDate(now);
          break;
        case MessageStatus.read:
          updateData['readAt'] = Timestamp.fromDate(now);
          updateData['deliveredAt'] = Timestamp.fromDate(now);
          break;
        case MessageStatus.failed:
        case MessageStatus.sent:
        case MessageStatus.sending:
          // No additional timestamp needed
          break;
      }
      
      await _firestore.collection('messages').doc(messageId).update(updateData);
      
      _logger.info('Successfully updated message status: $messageId');
      return Result.success(null);
    } catch (e) {
      _logger.error('Error updating message status: $e');
      return Result.error('Failed to update message status: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> markMessagesAsRead({
    required String chatId,
    required String userId,
    required List<String> messageIds,
  }) async {
    try {
      _logger.info('Marking ${messageIds.length} messages as read for user: $userId in chat: $chatId');
      
      final batch = _firestore.batch();
      final now = Timestamp.fromDate(DateTime.now());
      
      // Update message statuses
      for (final messageId in messageIds) {
        final messageRef = _firestore.collection('messages').doc(messageId);
        batch.update(messageRef, {
          'status': MessageStatus.read.value,
          'readAt': now,
          'deliveredAt': now,
        });
      }
      
      // Update chat's unread count and last read timestamp
      final chatRef = _firestore.collection('chats').doc(chatId);
      batch.update(chatRef, {
        'unreadCounts.$userId': 0,
        'lastReadTimestamps.$userId': now,
      });
      
      await batch.commit();
      
      _logger.info('Successfully marked messages as read for user: $userId in chat: $chatId');
      return Result.success(null);
    } catch (e) {
      _logger.error('Error marking messages as read: $e');
      return Result.error('Failed to mark messages as read: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> updateUnreadCount({
    required String chatId,
    required String userId,
    required int count,
  }) async {
    try {
      _logger.info('Updating unread count for user: $userId in chat: $chatId to $count');
      
      final updateData = <String, dynamic>{};
      
      if (count <= 0) {
        updateData['unreadCounts.$userId'] = FieldValue.delete();
      } else {
        updateData['unreadCounts.$userId'] = count;
      }
      
      await _firestore.collection('chats').doc(chatId).update(updateData);
      
      _logger.info('Successfully updated unread count for user: $userId in chat: $chatId');
      return Result.success(null);
    } catch (e) {
      _logger.error('Error updating unread count: $e');
      return Result.error('Failed to update unread count: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<int>> getTotalUnreadCount(String userId) async {
    try {
      _logger.info('Fetching total unread count for user: $userId');
      
      final snapshot = await _firestore
          .collection('chats')
          .where('participantIds', arrayContains: userId)
          .where('isActive', isEqualTo: true)
          .get();
      
      int totalUnread = 0;
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final unreadCounts = Map<String, int>.from(data['unreadCounts'] ?? {});
        totalUnread += unreadCounts[userId] ?? 0;
      }
      
      _logger.info('Successfully fetched total unread count for user: $userId - $totalUnread');
      return Result.success(totalUnread);
    } catch (e) {
      _logger.error('Error fetching total unread count: $e');
      return Result.error('Failed to fetch total unread count: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<List<Message>>> searchMessages({
    required String chatId,
    required String query,
    int limit = 20,
  }) async {
    try {
      _logger.info('Searching messages in chat: $chatId with query: $query');
      
      // Note: Firestore doesn't support full-text search natively
      // This is a basic implementation that searches for exact matches
      // For production, consider using Algolia or Elasticsearch
      
      final snapshot = await _firestore
          .collection('messages')
          .where('chatId', isEqualTo: chatId)
          .where('content', isGreaterThanOrEqualTo: query)
          .where('content', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(limit)
          .get();
      
      final messages = <Message>[];
      
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          
          // Convert Firestore Timestamps to DateTime
          if (data['timestamp'] is Timestamp) {
            data['timestamp'] = (data['timestamp'] as Timestamp).toDate().toIso8601String();
          }
          if (data['readAt'] is Timestamp) {
            data['readAt'] = (data['readAt'] as Timestamp).toDate().toIso8601String();
          }
          if (data['deliveredAt'] is Timestamp) {
            data['deliveredAt'] = (data['deliveredAt'] as Timestamp).toDate().toIso8601String();
          }
          
          final message = Message.fromJson(data);
          messages.add(message);
        } catch (e) {
          _logger.error('Error parsing message ${doc.id} in search: $e');
        }
      }
      
      _logger.info('Successfully found ${messages.length} messages matching query: $query');
      return Result.success(messages);
    } catch (e) {
      _logger.error('Error searching messages: $e');
      return Result.error('Failed to search messages: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<Message>> getMessageById(String messageId) async {
    try {
      _logger.info('Fetching message with ID: $messageId');
      
      final doc = await _firestore.collection('messages').doc(messageId).get();
      
      if (!doc.exists) {
        _logger.warning('Message not found: $messageId');
        return Result.error('Message not found');
      }

      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      
      // Convert Firestore Timestamps to DateTime
      if (data['timestamp'] is Timestamp) {
        data['timestamp'] = (data['timestamp'] as Timestamp).toDate().toIso8601String();
      }
      if (data['readAt'] is Timestamp) {
        data['readAt'] = (data['readAt'] as Timestamp).toDate().toIso8601String();
      }
      if (data['deliveredAt'] is Timestamp) {
        data['deliveredAt'] = (data['deliveredAt'] as Timestamp).toDate().toIso8601String();
      }
      
      final message = Message.fromJson(data);
      
      _logger.info('Successfully fetched message: $messageId');
      return Result.success(message);
    } catch (e) {
      _logger.error('Error fetching message: $e');
      return Result.error('Failed to fetch message: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteMessage(String messageId) async {
    try {
      _logger.info('Deleting message: $messageId');
      
      await _firestore.collection('messages').doc(messageId).delete();
      
      _logger.info('Successfully deleted message: $messageId');
      return Result.success(null);
    } catch (e) {
      _logger.error('Error deleting message: $e');
      return Result.error('Failed to delete message: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<Message>> updateMessage(Message message) async {
    try {
      _logger.info('Updating message: ${message.id}');
      
      final messageData = message.toJson();
      messageData.remove('id');
      
      // Convert DateTime to Firestore Timestamp
      messageData['timestamp'] = Timestamp.fromDate(message.timestamp);
      if (message.readAt != null) {
        messageData['readAt'] = Timestamp.fromDate(message.readAt!);
      }
      if (message.deliveredAt != null) {
        messageData['deliveredAt'] = Timestamp.fromDate(message.deliveredAt!);
      }
      
      await _firestore.collection('messages').doc(message.id).update(messageData);
      
      _logger.info('Successfully updated message: ${message.id}');
      return Result.success(message);
    } catch (e) {
      _logger.error('Error updating message: $e');
      return Result.error('Failed to update message: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> archiveChat(String chatId, String userId) async {
    try {
      _logger.info('Archiving chat: $chatId for user: $userId');
      
      // For now, we'll mark the chat as inactive
      // In a more sophisticated implementation, you might have per-user archive status
      await _firestore.collection('chats').doc(chatId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      _logger.info('Successfully archived chat: $chatId for user: $userId');
      return Result.success(null);
    } catch (e) {
      _logger.error('Error archiving chat: $e');
      return Result.error('Failed to archive chat: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> unarchiveChat(String chatId, String userId) async {
    try {
      _logger.info('Unarchiving chat: $chatId for user: $userId');
      
      await _firestore.collection('chats').doc(chatId).update({
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      _logger.info('Successfully unarchived chat: $chatId for user: $userId');
      return Result.success(null);
    } catch (e) {
      _logger.error('Error unarchiving chat: $e');
      return Result.error('Failed to unarchive chat: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Stream<List<String>> getTypingIndicators(String chatId) {
    _logger.info('Starting typing indicators stream for chat: $chatId');
    
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('typing')
        .where('isTyping', isEqualTo: true)
        .where('timestamp', isGreaterThan: Timestamp.fromDate(DateTime.now().subtract(const Duration(seconds: 10))))
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.id).toList();
    }).handleError((error) {
      _logger.error('Error in typing indicators stream: $error');
      return <String>[];
    });
  }

  @override
  Future<Result<void>> setTypingIndicator({
    required String chatId,
    required String userId,
    required bool isTyping,
  }) async {
    try {
      _logger.info('Setting typing indicator for user: $userId in chat: $chatId to $isTyping');
      
      final typingRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('typing')
          .doc(userId);
      
      if (isTyping) {
        await typingRef.set({
          'isTyping': true,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        await typingRef.delete();
      }
      
      _logger.info('Successfully set typing indicator for user: $userId in chat: $chatId');
      return Result.success(null);
    } catch (e) {
      _logger.error('Error setting typing indicator: $e');
      return Result.error('Failed to set typing indicator: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<Message>> retryMessage(String messageId) async {
    try {
      _logger.info('Retrying message: $messageId');
      
      // Get the failed message
      final messageResult = await getMessageById(messageId);
      if (messageResult.isError) {
        return Result.error('Failed to get message for retry: ${messageResult.error}');
      }
      
      final message = messageResult.data!;
      
      // Update status to sending and retry
      final retryMessage = message.copyWith(
        status: MessageStatus.sending,
        timestamp: DateTime.now(),
      );
      
      // Attempt to send again
      final sendResult = await sendMessage(retryMessage);
      if (sendResult.isError) {
        // Mark as failed again
        await updateMessageStatus(
          messageId: messageId,
          status: MessageStatus.failed,
        );
        return sendResult;
      }
      
      _logger.info('Successfully retried message: $messageId');
      return sendResult;
    } catch (e) {
      _logger.error('Error retrying message: $e');
      return Result.error('Failed to retry message: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<Map<String, MessageStatus>>> getMessageDeliveryStatus(String messageId) async {
    try {
      _logger.info('Fetching delivery status for message: $messageId');
      
      // Get the message
      final messageResult = await getMessageById(messageId);
      if (messageResult.isError) {
        return Result.error('Failed to get message: ${messageResult.error}');
      }
      
      final message = messageResult.data!;
      
      // Get the chat to find all participants
      final chatResult = await getChatById(message.chatId);
      if (chatResult.isError) {
        return Result.error('Failed to get chat: ${chatResult.error}');
      }
      
      final chat = chatResult.data!;
      final deliveryStatus = <String, MessageStatus>{};
      
      // For now, we'll return the same status for all participants
      // In a more sophisticated implementation, you'd track per-user delivery status
      for (final participantId in chat.participantIds) {
        if (participantId != message.senderId) {
          deliveryStatus[participantId] = message.status;
        }
      }
      
      _logger.info('Successfully fetched delivery status for message: $messageId');
      return Result.success(deliveryStatus);
    } catch (e) {
      _logger.error('Error fetching message delivery status: $e');
      return Result.error('Failed to fetch message delivery status: ${e.toString()}', Exception(e.toString()));
    }
  }
}