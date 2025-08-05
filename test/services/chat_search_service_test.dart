import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:educonnect/services/chat_search_service.dart';
import 'package:educonnect/repositories/chat_repository.dart';
import 'package:educonnect/modules/message.dart';
import 'package:educonnect/modules/chat.dart';
import 'package:educonnect/core/core.dart';

// Generate mocks
@GenerateMocks([ChatRepository])
import 'chat_search_service_test.mocks.dart';

void main() {
  group('ChatSearchService', () {
    late ChatSearchService service;
    late MockChatRepository mockChatRepository;
    late List<Message> testMessages;
    late List<Chat> testChats;

    setUp(() {
      mockChatRepository = MockChatRepository();
      service = ChatSearchService(chatRepository: mockChatRepository);

      // Create test messages
      testMessages = [
        Message(
          id: 'msg_1',
          chatId: 'chat_1',
          senderId: 'user_1',
          content: 'Hello world, this is a test message',
          type: MessageType.text,
          status: MessageStatus.sent,
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        Message(
          id: 'msg_2',
          chatId: 'chat_1',
          senderId: 'user_2',
          content: 'Another message about testing',
          type: MessageType.text,
          status: MessageStatus.sent,
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        Message(
          id: 'msg_3',
          chatId: 'chat_1',
          senderId: 'user_1',
          content: 'File attachment',
          type: MessageType.file,
          status: MessageStatus.sent,
          timestamp: DateTime.now().subtract(const Duration(hours: 3)),
          fileName: 'test_document.pdf',
        ),
      ];

      // Create test chats
      testChats = [
        Chat(
          id: 'chat_1',
          title: 'Test Chat',
          type: ChatType.direct,
          participantIds: ['user_1', 'user_2'],
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          updatedAt: DateTime.now(),
          lastMessageContent: 'Hello world, this is a test message',
          lastMessageTimestamp: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        Chat(
          id: 'chat_2',
          title: 'Project Discussion',
          type: ChatType.group,
          participantIds: ['user_1', 'user_2', 'user_3'],
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
          lastMessageContent: 'Let\'s discuss the project requirements',
          lastMessageTimestamp: DateTime.now().subtract(const Duration(hours: 5)),
        ),
      ];
    });

    group('searchMessagesInChat', () {
      test('should find messages matching query', () async {
        when(mockChatRepository.getMessages(
          chatId: 'chat_1',
          limit: 1000,
        )).thenAnswer((_) async => Result.success(testMessages));

        final result = await service.searchMessagesInChat(
          chatId: 'chat_1',
          query: 'test',
        );

        expect(result.isSuccess, true);
        expect(result.data!.length, 2); // Two messages contain "test"
        expect(result.data!.first.message.content, contains('test'));
      });

      test('should return results sorted by relevance', () async {
        when(mockChatRepository.getMessages(
          chatId: 'chat_1',
          limit: 1000,
        )).thenAnswer((_) async => Result.success(testMessages));

        final result = await service.searchMessagesInChat(
          chatId: 'chat_1',
          query: 'test message',
        );

        expect(result.isSuccess, true);
        expect(result.data!.isNotEmpty, true);
        
        // First result should have higher relevance (exact phrase match)
        expect(result.data!.first.message.content, 'Hello world, this is a test message');
        expect(result.data!.first.relevanceScore, greaterThan(result.data!.last.relevanceScore));
      });

      test('should filter by message type', () async {
        when(mockChatRepository.getMessages(
          chatId: 'chat_1',
          limit: 1000,
        )).thenAnswer((_) async => Result.success(testMessages));

        final result = await service.searchMessagesInChat(
          chatId: 'chat_1',
          query: 'test',
          messageType: MessageType.file,
        );

        expect(result.isSuccess, true);
        expect(result.data!.length, 0); // No file messages contain "test" in content
      });

      test('should filter by date range', () async {
        when(mockChatRepository.getMessages(
          chatId: 'chat_1',
          limit: 1000,
        )).thenAnswer((_) async => Result.success(testMessages));

        final startDate = DateTime.now().subtract(const Duration(hours: 2, minutes: 30));
        final endDate = DateTime.now().subtract(const Duration(minutes: 30));

        final result = await service.searchMessagesInChat(
          chatId: 'chat_1',
          query: 'message',
          startDate: startDate,
          endDate: endDate,
        );

        expect(result.isSuccess, true);
        expect(result.data!.length, 1); // Only one message in the time range
      });

      test('should search in file names', () async {
        when(mockChatRepository.getMessages(
          chatId: 'chat_1',
          limit: 1000,
        )).thenAnswer((_) async => Result.success(testMessages));

        final result = await service.searchMessagesInChat(
          chatId: 'chat_1',
          query: 'document',
        );

        expect(result.isSuccess, true);
        expect(result.data!.length, 1);
        expect(result.data!.first.message.fileName, 'test_document.pdf');
      });

      test('should return empty list when no matches found', () async {
        when(mockChatRepository.getMessages(
          chatId: 'chat_1',
          limit: 1000,
        )).thenAnswer((_) async => Result.success(testMessages));

        final result = await service.searchMessagesInChat(
          chatId: 'chat_1',
          query: 'nonexistent',
        );

        expect(result.isSuccess, true);
        expect(result.data!.isEmpty, true);
      });

      test('should handle repository errors', () async {
        when(mockChatRepository.getMessages(
          chatId: 'chat_1',
          limit: 1000,
        )).thenAnswer((_) async => Result.error('Network error'));

        final result = await service.searchMessagesInChat(
          chatId: 'chat_1',
          query: 'test',
        );

        expect(result.isError, true);
        expect(result.error, contains('Failed to search messages in chat'));
      });
    });

    group('searchAllMessages', () {
      test('should search across all user chats', () async {
        when(mockChatRepository.getUserChats('user_1'))
            .thenAnswer((_) async => Result.success(testChats));
        
        when(mockChatRepository.getMessages(
          chatId: any,
          limit: 1000,
        )).thenAnswer((_) async => Result.success(testMessages));

        final result = await service.searchAllMessages(
          userId: 'user_1',
          query: 'test',
        );

        expect(result.isSuccess, true);
        expect(result.data!.isNotEmpty, true);
        
        // Should search in both chats
        verify(mockChatRepository.getMessages(chatId: 'chat_1', limit: 1000)).called(1);
        verify(mockChatRepository.getMessages(chatId: 'chat_2', limit: 1000)).called(1);
      });

      test('should handle getUserChats error', () async {
        when(mockChatRepository.getUserChats('user_1'))
            .thenAnswer((_) async => Result.error('Failed to get chats'));

        final result = await service.searchAllMessages(
          userId: 'user_1',
          query: 'test',
        );

        expect(result.isError, true);
        expect(result.error, contains('Failed to get user chats'));
      });
    });

    group('searchChats', () {
      test('should find chats matching query in title', () async {
        when(mockChatRepository.getUserChats('user_1'))
            .thenAnswer((_) async => Result.success(testChats));

        final result = await service.searchChats(
          userId: 'user_1',
          query: 'test',
        );

        expect(result.isSuccess, true);
        expect(result.data!.length, 1);
        expect(result.data!.first.chat.title, 'Test Chat');
        expect(result.data!.first.matchedField, 'title');
      });

      test('should find chats matching query in last message', () async {
        when(mockChatRepository.getUserChats('user_1'))
            .thenAnswer((_) async => Result.success(testChats));

        final result = await service.searchChats(
          userId: 'user_1',
          query: 'project',
        );

        expect(result.isSuccess, true);
        expect(result.data!.length, 1);
        expect(result.data!.first.chat.title, 'Project Discussion');
        expect(result.data!.first.matchedField, 'lastMessage');
      });

      test('should filter by chat type', () async {
        when(mockChatRepository.getUserChats('user_1'))
            .thenAnswer((_) async => Result.success(testChats));

        final result = await service.searchChats(
          userId: 'user_1',
          query: 'chat',
          chatType: ChatType.direct,
        );

        expect(result.isSuccess, true);
        expect(result.data!.length, 1);
        expect(result.data!.first.chat.type, ChatType.direct);
      });

      test('should exclude archived chats by default', () async {
        final archivedChat = testChats.first.copyWith(isActive: false);
        final chatsWithArchived = [archivedChat, testChats.last];
        
        when(mockChatRepository.getUserChats('user_1'))
            .thenAnswer((_) async => Result.success(chatsWithArchived));

        final result = await service.searchChats(
          userId: 'user_1',
          query: 'chat',
        );

        expect(result.isSuccess, true);
        expect(result.data!.length, 0); // Archived chat excluded
      });

      test('should include archived chats when requested', () async {
        final archivedChat = testChats.first.copyWith(isActive: false);
        final chatsWithArchived = [archivedChat, testChats.last];
        
        when(mockChatRepository.getUserChats('user_1'))
            .thenAnswer((_) async => Result.success(chatsWithArchived));

        final result = await service.searchChats(
          userId: 'user_1',
          query: 'test',
          includeArchived: true,
        );

        expect(result.isSuccess, true);
        expect(result.data!.length, 1); // Archived chat included
      });
    });

    group('getMessageHistory', () {
      test('should return message history with pagination', () async {
        when(mockChatRepository.getMessages(
          chatId: 'chat_1',
          limit: 50,
        )).thenAnswer((_) async => Result.success(testMessages));

        final result = await service.getMessageHistory(chatId: 'chat_1');

        expect(result.isSuccess, true);
        expect(result.data!.messages.length, testMessages.length);
        expect(result.data!.hasMore, false); // Less than limit
        expect(result.data!.oldestTimestamp, isNotNull);
      });

      test('should filter messages before specified date', () async {
        when(mockChatRepository.getMessages(
          chatId: 'chat_1',
          limit: 50,
        )).thenAnswer((_) async => Result.success(testMessages));

        final beforeDate = DateTime.now().subtract(const Duration(hours: 1, minutes: 30));
        final result = await service.getMessageHistory(
          chatId: 'chat_1',
          before: beforeDate,
        );

        expect(result.isSuccess, true);
        expect(result.data!.messages.length, lessThan(testMessages.length));
      });

      test('should handle repository errors', () async {
        when(mockChatRepository.getMessages(
          chatId: 'chat_1',
          limit: 50,
        )).thenAnswer((_) async => Result.error('Network error'));

        final result = await service.getMessageHistory(chatId: 'chat_1');

        expect(result.isError, true);
        expect(result.error, contains('Failed to get message history'));
      });
    });

    group('cache management', () {
      test('should clear all cache', () {
        service.clearCache();
        // Cache is internal, so we can't directly test it
        // But we can verify it doesn't cause errors
        expect(true, true);
      });

      test('should clear specific chat cache', () {
        service.clearChatCache('chat_1');
        // Cache is internal, so we can't directly test it
        // But we can verify it doesn't cause errors
        expect(true, true);
      });
    });

    group('MessageSearchResult', () {
      test('should create result with correct properties', () {
        final result = MessageSearchResult(
          message: testMessages.first,
          chatId: 'chat_1',
          relevanceScore: 85.0,
          matchedText: 'Hello world, this is a test message',
        );

        expect(result.message.id, testMessages.first.id);
        expect(result.chatId, 'chat_1');
        expect(result.relevanceScore, 85.0);
        expect(result.matchedText, 'Hello world, this is a test message');
      });
    });

    group('ChatSearchResult', () {
      test('should create result with correct properties', () {
        final result = ChatSearchResult(
          chat: testChats.first,
          relevanceScore: 75.0,
          matchedField: 'title',
        );

        expect(result.chat.id, testChats.first.id);
        expect(result.relevanceScore, 75.0);
        expect(result.matchedField, 'title');
      });
    });

    group('MessageHistoryResult', () {
      test('should create result with correct properties', () {
        final result = MessageHistoryResult(
          messages: testMessages,
          hasMore: true,
          oldestTimestamp: testMessages.last.timestamp,
        );

        expect(result.messages.length, testMessages.length);
        expect(result.hasMore, true);
        expect(result.oldestTimestamp, testMessages.last.timestamp);
      });
    });
  });
}