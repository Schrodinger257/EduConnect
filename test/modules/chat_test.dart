import 'package:flutter_test/flutter_test.dart';
import 'package:educonnect/modules/chat.dart';

void main() {
  group('ChatType', () {
    test('should convert from string correctly', () {
      expect(ChatType.fromString('direct'), ChatType.direct);
      expect(ChatType.fromString('group'), ChatType.group);
      expect(ChatType.fromString('course'), ChatType.course);
    });

    test('should throw error for invalid string', () {
      expect(() => ChatType.fromString('invalid'), throwsArgumentError);
    });
  });

  group('Chat', () {
    late Chat testChat;
    late DateTime testCreatedAt;
    late DateTime testUpdatedAt;

    setUp(() {
      testCreatedAt = DateTime.now().subtract(const Duration(days: 1));
      testUpdatedAt = DateTime.now();
      testChat = Chat(
        id: 'chat_123',
        title: 'Test Chat',
        type: ChatType.direct,
        participantIds: ['user_1', 'user_2'],
        createdAt: testCreatedAt,
        updatedAt: testUpdatedAt,
      );
    });

    group('constructor', () {
      test('should create chat with required fields', () {
        expect(testChat.id, 'chat_123');
        expect(testChat.title, 'Test Chat');
        expect(testChat.type, ChatType.direct);
        expect(testChat.participantIds, ['user_1', 'user_2']);
        expect(testChat.createdAt, testCreatedAt);
        expect(testChat.updatedAt, testUpdatedAt);
        expect(testChat.isActive, true);
      });

      test('should create chat with optional fields', () {
        final lastMessageTimestamp = DateTime.now();
        final chat = Chat(
          id: 'chat_123',
          title: 'Test Chat',
          type: ChatType.group,
          participantIds: ['user_1', 'user_2', 'user_3'],
          lastMessageId: 'msg_456',
          lastMessageContent: 'Hello everyone!',
          lastMessageTimestamp: lastMessageTimestamp,
          lastMessageSenderId: 'user_1',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          createdBy: 'user_1',
          imageUrl: 'https://example.com/chat.jpg',
          unreadCounts: {'user_2': 3, 'user_3': 1},
          lastReadTimestamps: {'user_1': DateTime.now()},
          isActive: false,
          metadata: {'key': 'value'},
        );

        expect(chat.lastMessageId, 'msg_456');
        expect(chat.lastMessageContent, 'Hello everyone!');
        expect(chat.lastMessageTimestamp, lastMessageTimestamp);
        expect(chat.lastMessageSenderId, 'user_1');
        expect(chat.createdBy, 'user_1');
        expect(chat.imageUrl, 'https://example.com/chat.jpg');
        expect(chat.unreadCounts, {'user_2': 3, 'user_3': 1});
        expect(chat.isActive, false);
        expect(chat.metadata, {'key': 'value'});
      });
    });

    group('fromJson', () {
      test('should create chat from valid JSON', () {
        final json = {
          'id': 'chat_123',
          'title': 'Test Chat',
          'type': 'direct',
          'participantIds': ['user_1', 'user_2'],
          'createdAt': testCreatedAt.toIso8601String(),
          'updatedAt': testUpdatedAt.toIso8601String(),
        };

        final chat = Chat.fromJson(json);

        expect(chat.id, 'chat_123');
        expect(chat.title, 'Test Chat');
        expect(chat.type, ChatType.direct);
        expect(chat.participantIds, ['user_1', 'user_2']);
        expect(chat.createdAt, testCreatedAt);
        expect(chat.updatedAt, testUpdatedAt);
      });

      test('should create chat from JSON with optional fields', () {
        final lastMessageTimestamp = DateTime.now();
        final lastReadTimestamp = DateTime.now();
        
        final json = {
          'id': 'chat_123',
          'title': 'Test Chat',
          'type': 'group',
          'participantIds': ['user_1', 'user_2', 'user_3'],
          'lastMessageId': 'msg_456',
          'lastMessageContent': 'Hello everyone!',
          'lastMessageTimestamp': lastMessageTimestamp.toIso8601String(),
          'lastMessageSenderId': 'user_1',
          'createdAt': testCreatedAt.toIso8601String(),
          'updatedAt': testUpdatedAt.toIso8601String(),
          'createdBy': 'user_1',
          'imageUrl': 'https://example.com/chat.jpg',
          'unreadCounts': {'user_2': 3, 'user_3': 1},
          'lastReadTimestamps': {'user_1': lastReadTimestamp.toIso8601String()},
          'isActive': false,
          'metadata': {'key': 'value'},
        };

        final chat = Chat.fromJson(json);

        expect(chat.lastMessageId, 'msg_456');
        expect(chat.lastMessageContent, 'Hello everyone!');
        expect(chat.lastMessageTimestamp, lastMessageTimestamp);
        expect(chat.lastMessageSenderId, 'user_1');
        expect(chat.createdBy, 'user_1');
        expect(chat.imageUrl, 'https://example.com/chat.jpg');
        expect(chat.unreadCounts, {'user_2': 3, 'user_3': 1});
        expect(chat.lastReadTimestamps['user_1'], lastReadTimestamp);
        expect(chat.isActive, false);
        expect(chat.metadata, {'key': 'value'});
      });

      test('should throw FormatException for invalid JSON', () {
        final json = {
          'id': 'chat_123',
          'title': 'Test Chat',
          // Missing required fields
        };

        expect(() => Chat.fromJson(json), throwsFormatException);
      });
    });

    group('toJson', () {
      test('should convert chat to JSON', () {
        final json = testChat.toJson();

        expect(json['id'], 'chat_123');
        expect(json['title'], 'Test Chat');
        expect(json['type'], 'direct');
        expect(json['participantIds'], ['user_1', 'user_2']);
        expect(json['createdAt'], testCreatedAt.toIso8601String());
        expect(json['updatedAt'], testUpdatedAt.toIso8601String());
        expect(json['isActive'], true);
      });

      test('should include optional fields in JSON', () {
        final lastMessageTimestamp = DateTime.now();
        final chat = testChat.copyWith(
          lastMessageId: 'msg_456',
          lastMessageContent: 'Hello!',
          lastMessageTimestamp: lastMessageTimestamp,
          unreadCounts: {'user_2': 3},
          metadata: {'key': 'value'},
        );

        final json = chat.toJson();

        expect(json['lastMessageId'], 'msg_456');
        expect(json['lastMessageContent'], 'Hello!');
        expect(json['lastMessageTimestamp'], lastMessageTimestamp.toIso8601String());
        expect(json['unreadCounts'], {'user_2': 3});
        expect(json['metadata'], {'key': 'value'});
      });
    });

    group('validate', () {
      test('should return success for valid chat data', () {
        final result = Chat.validate(
          id: 'chat_123',
          title: 'Test Chat',
          type: ChatType.direct,
          participantIds: ['user_1', 'user_2'],
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(result.isSuccess, true);
        expect(result.data!.id, 'chat_123');
      });

      test('should return error for empty ID', () {
        final result = Chat.validate(
          id: '',
          title: 'Test Chat',
          type: ChatType.direct,
          participantIds: ['user_1', 'user_2'],
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(result.isError, true);
        expect(result.error, contains('Chat ID cannot be empty'));
      });

      test('should return error for empty title', () {
        final result = Chat.validate(
          id: 'chat_123',
          title: '',
          type: ChatType.direct,
          participantIds: ['user_1', 'user_2'],
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(result.isError, true);
        expect(result.error, contains('Chat title cannot be empty'));
      });

      test('should return error for title exceeding limit', () {
        final longTitle = 'a' * 101;
        final result = Chat.validate(
          id: 'chat_123',
          title: longTitle,
          type: ChatType.direct,
          participantIds: ['user_1', 'user_2'],
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(result.isError, true);
        expect(result.error, contains('Chat title cannot exceed 100 characters'));
      });

      test('should return error for empty participants', () {
        final result = Chat.validate(
          id: 'chat_123',
          title: 'Test Chat',
          type: ChatType.direct,
          participantIds: [],
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(result.isError, true);
        expect(result.error, contains('Chat must have at least one participant'));
      });

      test('should return error for direct chat with wrong participant count', () {
        final result = Chat.validate(
          id: 'chat_123',
          title: 'Test Chat',
          type: ChatType.direct,
          participantIds: ['user_1', 'user_2', 'user_3'],
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(result.isError, true);
        expect(result.error, contains('Direct chats must have exactly 2 participants'));
      });

      test('should return error for group chat with insufficient participants', () {
        final result = Chat.validate(
          id: 'chat_123',
          title: 'Test Chat',
          type: ChatType.group,
          participantIds: ['user_1', 'user_2'],
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(result.isError, true);
        expect(result.error, contains('Group chats must have at least 3 participants'));
      });

      test('should return error for duplicate participants', () {
        final result = Chat.validate(
          id: 'chat_123',
          title: 'Test Chat',
          type: ChatType.direct,
          participantIds: ['user_1', 'user_1'],
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(result.isError, true);
        expect(result.error, contains('Duplicate participants are not allowed'));
      });

      test('should return error for future created timestamp', () {
        final futureTimestamp = DateTime.now().add(const Duration(hours: 1));
        final result = Chat.validate(
          id: 'chat_123',
          title: 'Test Chat',
          type: ChatType.direct,
          participantIds: ['user_1', 'user_2'],
          createdAt: futureTimestamp,
          updatedAt: testUpdatedAt,
        );

        expect(result.isError, true);
        expect(result.error, contains('Created timestamp cannot be in the future'));
      });

      test('should return error for updated timestamp before created timestamp', () {
        final result = Chat.validate(
          id: 'chat_123',
          title: 'Test Chat',
          type: ChatType.direct,
          participantIds: ['user_1', 'user_2'],
          createdAt: testUpdatedAt,
          updatedAt: testCreatedAt,
        );

        expect(result.isError, true);
        expect(result.error, contains('Updated timestamp cannot be before created timestamp'));
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        final updatedChat = testChat.copyWith(
          title: 'Updated Chat',
          isActive: false,
        );

        expect(updatedChat.title, 'Updated Chat');
        expect(updatedChat.isActive, false);
        expect(updatedChat.id, testChat.id); // Unchanged
        expect(updatedChat.type, testChat.type); // Unchanged
      });
    });

    group('participant management', () {
      test('should add participant', () {
        final updatedChat = testChat.addParticipant('user_3');

        expect(updatedChat.participantIds, contains('user_3'));
        expect(updatedChat.participantCount, 3);
      });

      test('should not add duplicate participant', () {
        final updatedChat = testChat.addParticipant('user_1');

        expect(updatedChat.participantIds, testChat.participantIds);
        expect(updatedChat.participantCount, testChat.participantCount);
      });

      test('should remove participant', () {
        final updatedChat = testChat.removeParticipant('user_1');

        expect(updatedChat.participantIds, isNot(contains('user_1')));
        expect(updatedChat.participantCount, 1);
      });

      test('should not remove non-existent participant', () {
        final updatedChat = testChat.removeParticipant('user_3');

        expect(updatedChat.participantIds, testChat.participantIds);
        expect(updatedChat.participantCount, testChat.participantCount);
      });

      test('should check if user is participant', () {
        expect(testChat.hasParticipant('user_1'), true);
        expect(testChat.hasParticipant('user_3'), false);
      });
    });

    group('unread count management', () {
      test('should update unread count', () {
        final updatedChat = testChat.updateUnreadCount('user_1', 5);

        expect(updatedChat.getUnreadCount('user_1'), 5);
      });

      test('should clear unread count when set to zero', () {
        final chatWithUnread = testChat.copyWith(
          unreadCounts: {'user_1': 5},
        );
        final updatedChat = chatWithUnread.updateUnreadCount('user_1', 0);

        expect(updatedChat.getUnreadCount('user_1'), 0);
        expect(updatedChat.unreadCounts.containsKey('user_1'), false);
      });

      test('should increment unread count', () {
        final chatWithUnread = testChat.copyWith(
          unreadCounts: {'user_1': 3},
        );
        final updatedChat = chatWithUnread.incrementUnreadCount('user_1');

        expect(updatedChat.getUnreadCount('user_1'), 4);
      });

      test('should increment unread count from zero', () {
        final updatedChat = testChat.incrementUnreadCount('user_1');

        expect(updatedChat.getUnreadCount('user_1'), 1);
      });

      test('should clear unread count', () {
        final chatWithUnread = testChat.copyWith(
          unreadCounts: {'user_1': 5},
        );
        final updatedChat = chatWithUnread.clearUnreadCount('user_1');

        expect(updatedChat.getUnreadCount('user_1'), 0);
      });

      test('should check if has unread messages', () {
        expect(testChat.hasUnreadMessages('user_1'), false);

        final chatWithUnread = testChat.copyWith(
          unreadCounts: {'user_1': 3},
        );
        expect(chatWithUnread.hasUnreadMessages('user_1'), true);
      });
    });

    group('last message management', () {
      test('should update last message', () {
        final timestamp = DateTime.now();
        final updatedChat = testChat.updateLastMessage(
          messageId: 'msg_456',
          content: 'Hello!',
          timestamp: timestamp,
          senderId: 'user_1',
        );

        expect(updatedChat.lastMessageId, 'msg_456');
        expect(updatedChat.lastMessageContent, 'Hello!');
        expect(updatedChat.lastMessageTimestamp, timestamp);
        expect(updatedChat.lastMessageSenderId, 'user_1');
      });

      test('should check if has last message', () {
        expect(testChat.hasLastMessage, false);

        final chatWithMessage = testChat.copyWith(lastMessageId: 'msg_456');
        expect(chatWithMessage.hasLastMessage, true);
      });
    });

    group('read timestamp management', () {
      test('should update last read timestamp', () {
        final timestamp = DateTime.now();
        final updatedChat = testChat.updateLastReadTimestamp('user_1', timestamp);

        expect(updatedChat.getLastReadTimestamp('user_1'), timestamp);
      });

      test('should mark as read', () {
        final chatWithUnread = testChat.copyWith(
          unreadCounts: {'user_1': 5},
        );
        final updatedChat = chatWithUnread.markAsRead('user_1');

        expect(updatedChat.getUnreadCount('user_1'), 0);
        expect(updatedChat.getLastReadTimestamp('user_1'), isNotNull);
      });
    });

    group('archive management', () {
      test('should archive chat', () {
        final archivedChat = testChat.archive();

        expect(archivedChat.isActive, false);
      });

      test('should unarchive chat', () {
        final inactiveChat = testChat.copyWith(isActive: false);
        final unarchivedChat = inactiveChat.unarchive();

        expect(unarchivedChat.isActive, true);
      });
    });

    group('helper methods', () {
      test('should check chat types', () {
        expect(testChat.isDirectMessage, true);
        expect(testChat.isGroupChat, false);
        expect(testChat.isCourseChat, false);

        final groupChat = testChat.copyWith(type: ChatType.group);
        expect(groupChat.isDirectMessage, false);
        expect(groupChat.isGroupChat, true);
        expect(groupChat.isCourseChat, false);
      });

      test('should get other participant ID in direct message', () {
        expect(testChat.getOtherParticipantId('user_1'), 'user_2');
        expect(testChat.getOtherParticipantId('user_2'), 'user_1');

        final groupChat = testChat.copyWith(type: ChatType.group);
        expect(groupChat.getOtherParticipantId('user_1'), null);
      });

      test('should calculate total unread count', () {
        final chatWithUnread = testChat.copyWith(
          unreadCounts: {'user_1': 3, 'user_2': 2},
        );

        expect(chatWithUnread.totalUnreadCount, 5);
      });
    });

    group('formatting', () {
      test('should provide last message preview', () {
        final chatWithMessage = testChat.copyWith(
          lastMessageContent: 'Hello, world!',
        );
        expect(chatWithMessage.lastMessagePreview, 'Hello, world!');

        final chatWithLongMessage = testChat.copyWith(
          lastMessageContent: 'a' * 100,
        );
        expect(chatWithLongMessage.lastMessagePreview, '${'a' * 47}...');

        expect(testChat.lastMessagePreview, null);
      });
    });

    group('search', () {
      test('should match search query in title', () {
        expect(testChat.matchesSearch('test'), true);
        expect(testChat.matchesSearch('TEST'), true);
        expect(testChat.matchesSearch('chat'), true);
        expect(testChat.matchesSearch('other'), false);
      });

      test('should match search query in last message content', () {
        final chatWithMessage = testChat.copyWith(
          lastMessageContent: 'Hello, world!',
        );

        expect(chatWithMessage.matchesSearch('hello'), true);
        expect(chatWithMessage.matchesSearch('world'), true);
        expect(chatWithMessage.matchesSearch('goodbye'), false);
      });
    });

    group('permissions', () {
      test('should check if chat can be deleted by user', () {
        final chatWithCreator = testChat.copyWith(createdBy: 'user_1');
        expect(chatWithCreator.canBeDeletedBy('user_1'), true);
        expect(chatWithCreator.canBeDeletedBy('user_2'), true); // Direct message
        expect(chatWithCreator.canBeDeletedBy('user_3'), false);
      });

      test('should check if user can add participants', () {
        final groupChat = testChat.copyWith(
          type: ChatType.group,
          participantIds: ['user_1', 'user_2', 'user_3'],
        );

        expect(groupChat.canAddParticipants('user_1'), true);
        expect(groupChat.canAddParticipants('user_4'), false);
        expect(testChat.canAddParticipants('user_1'), false); // Direct message
      });

      test('should check if user can remove participants', () {
        final groupChatWithCreator = testChat.copyWith(
          type: ChatType.group,
          participantIds: ['user_1', 'user_2', 'user_3'],
          createdBy: 'user_1',
        );

        expect(groupChatWithCreator.canRemoveParticipants('user_1'), true);
        expect(groupChatWithCreator.canRemoveParticipants('user_2'), true);
        expect(groupChatWithCreator.canRemoveParticipants('user_4'), false);
      });
    });

    group('equality and hashCode', () {
      test('should be equal for same chat data', () {
        final chat1 = Chat(
          id: 'chat_123',
          title: 'Test Chat',
          type: ChatType.direct,
          participantIds: ['user_1', 'user_2'],
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        final chat2 = Chat(
          id: 'chat_123',
          title: 'Test Chat',
          type: ChatType.direct,
          participantIds: ['user_1', 'user_2'],
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(chat1, chat2);
        expect(chat1.hashCode, chat2.hashCode);
      });

      test('should not be equal for different chat data', () {
        final chat2 = testChat.copyWith(id: 'chat_456');

        expect(testChat, isNot(chat2));
        expect(testChat.hashCode, isNot(chat2.hashCode));
      });
    });

    group('toString', () {
      test('should return string representation', () {
        final string = testChat.toString();

        expect(string, contains('chat_123'));
        expect(string, contains('Test Chat'));
        expect(string, contains('direct'));
        expect(string, contains('2')); // participant count
        expect(string, contains('true')); // active status
      });
    });
  });
}