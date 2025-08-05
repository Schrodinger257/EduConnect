import 'package:flutter_test/flutter_test.dart';
import 'package:educonnect/modules/message.dart';

void main() {
  group('MessageType', () {
    test('should convert from string correctly', () {
      expect(MessageType.fromString('text'), MessageType.text);
      expect(MessageType.fromString('image'), MessageType.image);
      expect(MessageType.fromString('file'), MessageType.file);
      expect(MessageType.fromString('system'), MessageType.system);
    });

    test('should throw error for invalid string', () {
      expect(() => MessageType.fromString('invalid'), throwsArgumentError);
    });
  });

  group('MessageStatus', () {
    test('should convert from string correctly', () {
      expect(MessageStatus.fromString('sending'), MessageStatus.sending);
      expect(MessageStatus.fromString('sent'), MessageStatus.sent);
      expect(MessageStatus.fromString('delivered'), MessageStatus.delivered);
      expect(MessageStatus.fromString('read'), MessageStatus.read);
      expect(MessageStatus.fromString('failed'), MessageStatus.failed);
    });

    test('should throw error for invalid string', () {
      expect(() => MessageStatus.fromString('invalid'), throwsArgumentError);
    });
  });

  group('Message', () {
    late Message testMessage;
    late DateTime testTimestamp;

    setUp(() {
      testTimestamp = DateTime.now();
      testMessage = Message(
        id: 'msg_123',
        chatId: 'chat_456',
        senderId: 'user_789',
        content: 'Hello, world!',
        type: MessageType.text,
        status: MessageStatus.sent,
        timestamp: testTimestamp,
      );
    });

    group('constructor', () {
      test('should create message with required fields', () {
        expect(testMessage.id, 'msg_123');
        expect(testMessage.chatId, 'chat_456');
        expect(testMessage.senderId, 'user_789');
        expect(testMessage.content, 'Hello, world!');
        expect(testMessage.type, MessageType.text);
        expect(testMessage.status, MessageStatus.sent);
        expect(testMessage.timestamp, testTimestamp);
      });

      test('should create message with optional fields', () {
        final readAt = DateTime.now();
        final deliveredAt = DateTime.now().subtract(const Duration(minutes: 1));
        
        final message = Message(
          id: 'msg_123',
          chatId: 'chat_456',
          senderId: 'user_789',
          content: 'Hello, world!',
          type: MessageType.text,
          status: MessageStatus.read,
          timestamp: testTimestamp,
          readAt: readAt,
          deliveredAt: deliveredAt,
          fileUrl: 'https://example.com/file.jpg',
          fileName: 'image.jpg',
          fileSize: 1024,
          replyToMessageId: 'msg_000',
          metadata: {'key': 'value'},
        );

        expect(message.readAt, readAt);
        expect(message.deliveredAt, deliveredAt);
        expect(message.fileUrl, 'https://example.com/file.jpg');
        expect(message.fileName, 'image.jpg');
        expect(message.fileSize, 1024);
        expect(message.replyToMessageId, 'msg_000');
        expect(message.metadata, {'key': 'value'});
      });
    });

    group('fromJson', () {
      test('should create message from valid JSON', () {
        final json = {
          'id': 'msg_123',
          'chatId': 'chat_456',
          'senderId': 'user_789',
          'content': 'Hello, world!',
          'type': 'text',
          'status': 'sent',
          'timestamp': testTimestamp.toIso8601String(),
        };

        final message = Message.fromJson(json);

        expect(message.id, 'msg_123');
        expect(message.chatId, 'chat_456');
        expect(message.senderId, 'user_789');
        expect(message.content, 'Hello, world!');
        expect(message.type, MessageType.text);
        expect(message.status, MessageStatus.sent);
        expect(message.timestamp, testTimestamp);
      });

      test('should create message from JSON with optional fields', () {
        final readAt = DateTime.now();
        final deliveredAt = DateTime.now().subtract(const Duration(minutes: 1));
        
        final json = {
          'id': 'msg_123',
          'chatId': 'chat_456',
          'senderId': 'user_789',
          'content': 'Hello, world!',
          'type': 'image',
          'status': 'read',
          'timestamp': testTimestamp.toIso8601String(),
          'readAt': readAt.toIso8601String(),
          'deliveredAt': deliveredAt.toIso8601String(),
          'fileUrl': 'https://example.com/file.jpg',
          'fileName': 'image.jpg',
          'fileSize': 1024,
          'replyToMessageId': 'msg_000',
          'metadata': {'key': 'value'},
        };

        final message = Message.fromJson(json);

        expect(message.readAt, readAt);
        expect(message.deliveredAt, deliveredAt);
        expect(message.fileUrl, 'https://example.com/file.jpg');
        expect(message.fileName, 'image.jpg');
        expect(message.fileSize, 1024);
        expect(message.replyToMessageId, 'msg_000');
        expect(message.metadata, {'key': 'value'});
      });

      test('should throw FormatException for invalid JSON', () {
        final json = {
          'id': 'msg_123',
          'chatId': 'chat_456',
          // Missing required fields
        };

        expect(() => Message.fromJson(json), throwsFormatException);
      });
    });

    group('toJson', () {
      test('should convert message to JSON', () {
        final json = testMessage.toJson();

        expect(json['id'], 'msg_123');
        expect(json['chatId'], 'chat_456');
        expect(json['senderId'], 'user_789');
        expect(json['content'], 'Hello, world!');
        expect(json['type'], 'text');
        expect(json['status'], 'sent');
        expect(json['timestamp'], testTimestamp.toIso8601String());
      });

      test('should include optional fields in JSON', () {
        final readAt = DateTime.now();
        final message = testMessage.copyWith(
          readAt: readAt,
          fileUrl: 'https://example.com/file.jpg',
          metadata: {'key': 'value'},
        );

        final json = message.toJson();

        expect(json['readAt'], readAt.toIso8601String());
        expect(json['fileUrl'], 'https://example.com/file.jpg');
        expect(json['metadata'], {'key': 'value'});
      });
    });

    group('validate', () {
      test('should return success for valid message data', () {
        final result = Message.validate(
          id: 'msg_123',
          chatId: 'chat_456',
          senderId: 'user_789',
          content: 'Hello, world!',
          type: MessageType.text,
          status: MessageStatus.sent,
          timestamp: testTimestamp,
        );

        expect(result.isSuccess, true);
        expect(result.data!.id, 'msg_123');
      });

      test('should return error for empty ID', () {
        final result = Message.validate(
          id: '',
          chatId: 'chat_456',
          senderId: 'user_789',
          content: 'Hello, world!',
          type: MessageType.text,
          status: MessageStatus.sent,
          timestamp: testTimestamp,
        );

        expect(result.isError, true);
        expect(result.error, contains('Message ID cannot be empty'));
      });

      test('should return error for empty chat ID', () {
        final result = Message.validate(
          id: 'msg_123',
          chatId: '',
          senderId: 'user_789',
          content: 'Hello, world!',
          type: MessageType.text,
          status: MessageStatus.sent,
          timestamp: testTimestamp,
        );

        expect(result.isError, true);
        expect(result.error, contains('Chat ID cannot be empty'));
      });

      test('should return error for empty sender ID', () {
        final result = Message.validate(
          id: 'msg_123',
          chatId: 'chat_456',
          senderId: '',
          content: 'Hello, world!',
          type: MessageType.text,
          status: MessageStatus.sent,
          timestamp: testTimestamp,
        );

        expect(result.isError, true);
        expect(result.error, contains('Sender ID cannot be empty'));
      });

      test('should return error for empty text message content', () {
        final result = Message.validate(
          id: 'msg_123',
          chatId: 'chat_456',
          senderId: 'user_789',
          content: '',
          type: MessageType.text,
          status: MessageStatus.sent,
          timestamp: testTimestamp,
        );

        expect(result.isError, true);
        expect(result.error, contains('Text message content cannot be empty'));
      });

      test('should return error for content exceeding limit', () {
        final longContent = 'a' * 10001;
        final result = Message.validate(
          id: 'msg_123',
          chatId: 'chat_456',
          senderId: 'user_789',
          content: longContent,
          type: MessageType.text,
          status: MessageStatus.sent,
          timestamp: testTimestamp,
        );

        expect(result.isError, true);
        expect(result.error, contains('Message content cannot exceed 10000 characters'));
      });

      test('should return error for file message without file URL', () {
        final result = Message.validate(
          id: 'msg_123',
          chatId: 'chat_456',
          senderId: 'user_789',
          content: 'File message',
          type: MessageType.file,
          status: MessageStatus.sent,
          timestamp: testTimestamp,
        );

        expect(result.isError, true);
        expect(result.error, contains('File URL is required for file/image messages'));
      });

      test('should return error for future timestamp', () {
        final futureTimestamp = DateTime.now().add(const Duration(hours: 1));
        final result = Message.validate(
          id: 'msg_123',
          chatId: 'chat_456',
          senderId: 'user_789',
          content: 'Hello, world!',
          type: MessageType.text,
          status: MessageStatus.sent,
          timestamp: futureTimestamp,
        );

        expect(result.isError, true);
        expect(result.error, contains('Message timestamp cannot be in the future'));
      });

      test('should return error for read message without read timestamp', () {
        final result = Message.validate(
          id: 'msg_123',
          chatId: 'chat_456',
          senderId: 'user_789',
          content: 'Hello, world!',
          type: MessageType.text,
          status: MessageStatus.read,
          timestamp: testTimestamp,
        );

        expect(result.isError, true);
        expect(result.error, contains('Read messages must have a read timestamp'));
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        final updatedMessage = testMessage.copyWith(
          content: 'Updated content',
          status: MessageStatus.read,
        );

        expect(updatedMessage.content, 'Updated content');
        expect(updatedMessage.status, MessageStatus.read);
        expect(updatedMessage.id, testMessage.id); // Unchanged
        expect(updatedMessage.chatId, testMessage.chatId); // Unchanged
      });
    });

    group('status updates', () {
      test('should mark message as delivered', () {
        final deliveredMessage = testMessage.markAsDelivered();

        expect(deliveredMessage.status, MessageStatus.delivered);
        expect(deliveredMessage.deliveredAt, isNotNull);
      });

      test('should not change already delivered message', () {
        final deliveredMessage = testMessage.copyWith(status: MessageStatus.delivered);
        final result = deliveredMessage.markAsDelivered();

        expect(result, deliveredMessage);
      });

      test('should mark message as read', () {
        final readMessage = testMessage.markAsRead();

        expect(readMessage.status, MessageStatus.read);
        expect(readMessage.readAt, isNotNull);
        expect(readMessage.deliveredAt, isNotNull);
      });

      test('should mark message as failed', () {
        final failedMessage = testMessage.markAsFailed();

        expect(failedMessage.status, MessageStatus.failed);
      });
    });

    group('helper methods', () {
      test('should check if message is sent by user', () {
        expect(testMessage.isSentBy('user_789'), true);
        expect(testMessage.isSentBy('other_user'), false);
      });

      test('should check message status', () {
        expect(testMessage.isRead, false);
        expect(testMessage.isDelivered, false);
        expect(testMessage.hasFailed, false);
        expect(testMessage.isSending, false);

        final readMessage = testMessage.markAsRead();
        expect(readMessage.isRead, true);
        expect(readMessage.isDelivered, true);
      });

      test('should check if message is reply', () {
        expect(testMessage.isReply, false);

        final replyMessage = testMessage.copyWith(replyToMessageId: 'msg_000');
        expect(replyMessage.isReply, true);
      });

      test('should check if message has file', () {
        expect(testMessage.hasFile, false);

        final fileMessage = testMessage.copyWith(type: MessageType.file);
        expect(fileMessage.hasFile, true);
      });

      test('should check if message is system message', () {
        expect(testMessage.isSystemMessage, false);

        final systemMessage = testMessage.copyWith(type: MessageType.system);
        expect(systemMessage.isSystemMessage, true);
      });
    });

    group('formatting', () {
      test('should format file size correctly', () {
        final fileMessage = testMessage.copyWith(fileSize: 1024);
        expect(fileMessage.formattedFileSize, '1.0 KB');

        final largeFileMessage = testMessage.copyWith(fileSize: 1048576);
        expect(largeFileMessage.formattedFileSize, '1.0 MB');
      });

      test('should return null for no file size', () {
        expect(testMessage.formattedFileSize, null);
      });

      test('should provide content preview', () {
        expect(testMessage.contentPreview, 'Hello, world!');

        final longMessage = testMessage.copyWith(content: 'a' * 100);
        expect(longMessage.contentPreview, '${'a' * 47}...');

        final imageMessage = testMessage.copyWith(type: MessageType.image);
        expect(imageMessage.contentPreview, '📷 Image');

        final fileMessage = testMessage.copyWith(
          type: MessageType.file,
          fileName: 'document.pdf',
        );
        expect(fileMessage.contentPreview, '📎 document.pdf');
      });
    });

    group('search', () {
      test('should match search query in content', () {
        expect(testMessage.matchesSearch('hello'), true);
        expect(testMessage.matchesSearch('HELLO'), true);
        expect(testMessage.matchesSearch('world'), true);
        expect(testMessage.matchesSearch('goodbye'), false);
      });

      test('should match search query in file name', () {
        final fileMessage = testMessage.copyWith(
          type: MessageType.file,
          fileName: 'important_document.pdf',
        );

        expect(fileMessage.matchesSearch('important'), true);
        expect(fileMessage.matchesSearch('document'), true);
        expect(fileMessage.matchesSearch('pdf'), true);
        expect(fileMessage.matchesSearch('image'), false);
      });
    });

    group('equality and hashCode', () {
      test('should be equal for same message data', () {
        final message1 = Message(
          id: 'msg_123',
          chatId: 'chat_456',
          senderId: 'user_789',
          content: 'Hello, world!',
          type: MessageType.text,
          status: MessageStatus.sent,
          timestamp: testTimestamp,
        );

        final message2 = Message(
          id: 'msg_123',
          chatId: 'chat_456',
          senderId: 'user_789',
          content: 'Hello, world!',
          type: MessageType.text,
          status: MessageStatus.sent,
          timestamp: testTimestamp,
        );

        expect(message1, message2);
        expect(message1.hashCode, message2.hashCode);
      });

      test('should not be equal for different message data', () {
        final message2 = testMessage.copyWith(id: 'msg_456');

        expect(testMessage, isNot(message2));
        expect(testMessage.hashCode, isNot(message2.hashCode));
      });
    });

    group('toString', () {
      test('should return string representation', () {
        final string = testMessage.toString();

        expect(string, contains('msg_123'));
        expect(string, contains('chat_456'));
        expect(string, contains('user_789'));
        expect(string, contains('text'));
        expect(string, contains('sent'));
      });
    });
  });
}