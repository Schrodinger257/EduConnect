import 'dart:async';
import '../core/core.dart';
import '../modules/message.dart';
import '../modules/chat.dart';
import '../repositories/chat_repository.dart';

/// Service for searching messages and chat history with advanced filtering
class ChatSearchService with LoggerMixin {
  final ChatRepository _chatRepository;
  final Map<String, List<Message>> _messageCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  ChatSearchService({
    required ChatRepository chatRepository,
  }) : _chatRepository = chatRepository;

  /// Searches for messages across all chats for a user
  Future<Result<List<MessageSearchResult>>> searchAllMessages({
    required String userId,
    required String query,
    MessageType? messageType,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    logInfo('Searching all messages for user: $userId with query: "$query"');

    try {
      // Get user's chats first
      final chatsResult = await _chatRepository.getUserChats(userId);
      if (chatsResult.isError) {
        return Result.error('Failed to get user chats: ${chatsResult.error}');
      }

      final chats = chatsResult.data!;
      final allResults = <MessageSearchResult>[];

      // Search in each chat
      for (final chat in chats) {
        final chatResults = await searchMessagesInChat(
          chatId: chat.id,
          query: query,
          messageType: messageType,
          startDate: startDate,
          endDate: endDate,
          limit: limit,
        );

        if (chatResults.isSuccess) {
          allResults.addAll(chatResults.data!);
        }
      }

      // Sort by relevance and timestamp
      allResults.sort((a, b) {
        // First sort by relevance score
        final relevanceComparison = b.relevanceScore.compareTo(a.relevanceScore);
        if (relevanceComparison != 0) return relevanceComparison;
        
        // Then by timestamp (newest first)
        return b.message.timestamp.compareTo(a.message.timestamp);
      });

      // Limit results
      final limitedResults = allResults.take(limit).toList();

      logInfo('Found ${limitedResults.length} messages matching search criteria');
      return Result.success(limitedResults);
    } catch (e) {
      logError('Error searching all messages', error: e);
      return Result.error('Failed to search messages: ${e.toString()}');
    }
  }

  /// Searches for messages within a specific chat
  Future<Result<List<MessageSearchResult>>> searchMessagesInChat({
    required String chatId,
    required String query,
    MessageType? messageType,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    logInfo('Searching messages in chat: $chatId with query: "$query"');

    try {
      // Get messages from cache or repository
      final messages = await _getMessagesForChat(chatId);
      if (messages.isEmpty) {
        return Result.success(<MessageSearchResult>[]);
      }

      final results = <MessageSearchResult>[];
      final queryLower = query.toLowerCase();

      for (final message in messages) {
        // Apply filters
        if (messageType != null && message.type != messageType) continue;
        if (startDate != null && message.timestamp.isBefore(startDate)) continue;
        if (endDate != null && message.timestamp.isAfter(endDate)) continue;

        // Calculate relevance score
        final relevanceScore = _calculateRelevanceScore(message, queryLower);
        if (relevanceScore > 0) {
          results.add(MessageSearchResult(
            message: message,
            chatId: chatId,
            relevanceScore: relevanceScore,
            matchedText: _getMatchedText(message, queryLower),
          ));
        }
      }

      // Sort by relevance and timestamp
      results.sort((a, b) {
        final relevanceComparison = b.relevanceScore.compareTo(a.relevanceScore);
        if (relevanceComparison != 0) return relevanceComparison;
        return b.message.timestamp.compareTo(a.message.timestamp);
      });

      final limitedResults = results.take(limit).toList();
      logInfo('Found ${limitedResults.length} messages in chat: $chatId');
      return Result.success(limitedResults);
    } catch (e) {
      logError('Error searching messages in chat', error: e);
      return Result.error('Failed to search messages in chat: ${e.toString()}');
    }
  }

  /// Searches for chats by name or participants
  Future<Result<List<ChatSearchResult>>> searchChats({
    required String userId,
    required String query,
    ChatType? chatType,
    bool includeArchived = false,
    int limit = 20,
  }) async {
    logInfo('Searching chats for user: $userId with query: "$query"');

    try {
      final chatsResult = await _chatRepository.getUserChats(userId);
      if (chatsResult.isError) {
        return Result.error('Failed to get user chats: ${chatsResult.error}');
      }

      final chats = chatsResult.data!;
      final results = <ChatSearchResult>[];
      final queryLower = query.toLowerCase();

      for (final chat in chats) {
        // Apply filters
        if (!includeArchived && !chat.isActive) continue;
        if (chatType != null && chat.type != chatType) continue;

        // Calculate relevance score
        final relevanceScore = _calculateChatRelevanceScore(chat, queryLower);
        if (relevanceScore > 0) {
          results.add(ChatSearchResult(
            chat: chat,
            relevanceScore: relevanceScore,
            matchedField: _getChatMatchedField(chat, queryLower),
          ));
        }
      }

      // Sort by relevance
      results.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));

      final limitedResults = results.take(limit).toList();
      logInfo('Found ${limitedResults.length} chats matching search criteria');
      return Result.success(limitedResults);
    } catch (e) {
      logError('Error searching chats', error: e);
      return Result.error('Failed to search chats: ${e.toString()}');
    }
  }

  /// Gets message history for a chat with pagination
  Future<Result<MessageHistoryResult>> getMessageHistory({
    required String chatId,
    DateTime? before,
    int limit = 50,
  }) async {
    logInfo('Getting message history for chat: $chatId');

    try {
      final result = await _chatRepository.getMessages(
        chatId: chatId,
        limit: limit,
      );

      if (result.isError) {
        return Result.error('Failed to get message history: ${result.error}');
      }

      final messages = result.data!;
      final filteredMessages = before != null
          ? messages.where((m) => m.timestamp.isBefore(before)).toList()
          : messages;

      final hasMore = messages.length == limit;

      return Result.success(MessageHistoryResult(
        messages: filteredMessages,
        hasMore: hasMore,
        oldestTimestamp: filteredMessages.isNotEmpty 
            ? filteredMessages.last.timestamp 
            : null,
      ));
    } catch (e) {
      logError('Error getting message history', error: e);
      return Result.error('Failed to get message history: ${e.toString()}');
    }
  }

  /// Clears the message cache
  void clearCache() {
    logInfo('Clearing message cache');
    _messageCache.clear();
    _cacheTimestamps.clear();
  }

  /// Clears cache for a specific chat
  void clearChatCache(String chatId) {
    logInfo('Clearing cache for chat: $chatId');
    _messageCache.remove(chatId);
    _cacheTimestamps.remove(chatId);
  }

  /// Gets messages for a chat (with caching)
  Future<List<Message>> _getMessagesForChat(String chatId) async {
    // Check cache first
    final cacheTimestamp = _cacheTimestamps[chatId];
    if (cacheTimestamp != null && 
        DateTime.now().difference(cacheTimestamp) < _cacheExpiry) {
      final cachedMessages = _messageCache[chatId];
      if (cachedMessages != null) {
        logDebug('Using cached messages for chat: $chatId');
        return cachedMessages;
      }
    }

    // Fetch from repository
    logDebug('Fetching messages from repository for chat: $chatId');
    final result = await _chatRepository.getMessages(
      chatId: chatId,
      limit: 1000, // Get more messages for search
    );

    if (result.isSuccess) {
      final messages = result.data!;
      _messageCache[chatId] = messages;
      _cacheTimestamps[chatId] = DateTime.now();
      return messages;
    } else {
      logWarning('Failed to fetch messages for chat: $chatId - ${result.error}');
      return [];
    }
  }

  /// Calculates relevance score for a message
  double _calculateRelevanceScore(Message message, String queryLower) {
    double score = 0.0;
    final contentLower = message.content.toLowerCase();

    // Exact match gets highest score
    if (contentLower == queryLower) {
      score += 100.0;
    }
    // Contains exact phrase
    else if (contentLower.contains(queryLower)) {
      score += 50.0;
      
      // Bonus for match at beginning
      if (contentLower.startsWith(queryLower)) {
        score += 20.0;
      }
    }
    // Word matches
    else {
      final queryWords = queryLower.split(' ');
      final contentWords = contentLower.split(' ');
      
      for (final queryWord in queryWords) {
        for (final contentWord in contentWords) {
          if (contentWord == queryWord) {
            score += 10.0;
          } else if (contentWord.contains(queryWord)) {
            score += 5.0;
          }
        }
      }
    }

    // Bonus for file name matches
    if (message.fileName != null) {
      final fileNameLower = message.fileName!.toLowerCase();
      if (fileNameLower.contains(queryLower)) {
        score += 25.0;
      }
    }

    // Recent messages get slight bonus
    final daysSinceMessage = DateTime.now().difference(message.timestamp).inDays;
    if (daysSinceMessage < 7) {
      score += 5.0;
    } else if (daysSinceMessage < 30) {
      score += 2.0;
    }

    return score;
  }

  /// Calculates relevance score for a chat
  double _calculateChatRelevanceScore(Chat chat, String queryLower) {
    double score = 0.0;
    final titleLower = chat.title.toLowerCase();

    // Exact match
    if (titleLower == queryLower) {
      score += 100.0;
    }
    // Contains query
    else if (titleLower.contains(queryLower)) {
      score += 50.0;
      
      if (titleLower.startsWith(queryLower)) {
        score += 20.0;
      }
    }

    // Check last message content
    if (chat.lastMessageContent != null) {
      final lastMessageLower = chat.lastMessageContent!.toLowerCase();
      if (lastMessageLower.contains(queryLower)) {
        score += 25.0;
      }
    }

    // Recent activity bonus
    if (chat.lastMessageTimestamp != null) {
      final daysSinceLastMessage = DateTime.now().difference(chat.lastMessageTimestamp!).inDays;
      if (daysSinceLastMessage < 1) {
        score += 10.0;
      } else if (daysSinceLastMessage < 7) {
        score += 5.0;
      }
    }

    return score;
  }

  /// Gets the matched text snippet for a message
  String _getMatchedText(Message message, String queryLower) {
    final content = message.content;
    final contentLower = content.toLowerCase();
    
    final index = contentLower.indexOf(queryLower);
    if (index == -1) return content;

    // Get context around the match
    const contextLength = 50;
    final start = (index - contextLength).clamp(0, content.length);
    final end = (index + queryLower.length + contextLength).clamp(0, content.length);
    
    String snippet = content.substring(start, end);
    
    // Add ellipsis if truncated
    if (start > 0) snippet = '...$snippet';
    if (end < content.length) snippet = '$snippet...';
    
    return snippet;
  }

  /// Gets the matched field for a chat
  String _getChatMatchedField(Chat chat, String queryLower) {
    if (chat.title.toLowerCase().contains(queryLower)) {
      return 'title';
    } else if (chat.lastMessageContent?.toLowerCase().contains(queryLower) == true) {
      return 'lastMessage';
    }
    return 'unknown';
  }
}

/// Result of a message search
class MessageSearchResult {
  final Message message;
  final String chatId;
  final double relevanceScore;
  final String matchedText;

  const MessageSearchResult({
    required this.message,
    required this.chatId,
    required this.relevanceScore,
    required this.matchedText,
  });

  @override
  String toString() {
    return 'MessageSearchResult(messageId: ${message.id}, chatId: $chatId, score: $relevanceScore)';
  }
}

/// Result of a chat search
class ChatSearchResult {
  final Chat chat;
  final double relevanceScore;
  final String matchedField;

  const ChatSearchResult({
    required this.chat,
    required this.relevanceScore,
    required this.matchedField,
  });

  @override
  String toString() {
    return 'ChatSearchResult(chatId: ${chat.id}, score: $relevanceScore, field: $matchedField)';
  }
}

/// Result of message history retrieval
class MessageHistoryResult {
  final List<Message> messages;
  final bool hasMore;
  final DateTime? oldestTimestamp;

  const MessageHistoryResult({
    required this.messages,
    required this.hasMore,
    this.oldestTimestamp,
  });

  @override
  String toString() {
    return 'MessageHistoryResult(count: ${messages.length}, hasMore: $hasMore)';
  }
}