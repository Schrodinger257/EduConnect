import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:educonnect/services/message_queue_service.dart';
import 'package:educonnect/repositories/chat_repository.dart';
import 'package:educonnect/modules/message.dart';
import 'package:educonnect/core/core.dart';

// Generate mocks
@GenerateMocks([ChatRepository])
import 'message_queue_service_test.mocks.dart';

void main() {
  group('MessageQueueService', () {
    late MessageQueueService service;
    late MockChatRepository mockChatRepository;
    late Message testMessage;

    setUp(() {
      mockChatRepository = MockChatRepository();
      service = MessageQueueService(chatRepository: mockChatRepository);
      
      testMessage = Message(
        id: 'msg_123',
        chatId: 'chat_456',
        senderId: 'user_789',
        content: 'Test message',
        type: MessageType.text,
        status: MessageStatus.sending,
        timestamp: DateTime.now(),
      );
    });

    group('queueMessage', () {
      test('should add message to queue', () async {
        await service.queueMessage(testMessage);

        expect(service.queuedMessages.length, 1);
        expect(service.queuedMessages.first.message.id, testMessage.id);
        expect(service.queuedMessages.first.attempts, 0);
      });

      test('should attempt to process queue immediately', () async {
        when(mockChatRepository.sendMessage(any))
            .thenAnswer((_) async => Result.success(testMessage));

        await service.queueMessage(testMessage);

        // Give some time for async processing
        await Future.delayed(const Duration(milliseconds: 100));

        verify(mockChatRepository.sendMessage(any)).called(1);
      });
    });

    group('message processing', () {
      test('should successfully send queued message', () async {
        when(mockChatRepository.sendMessage(any))
            .thenAnswer((_) async => Result.success(testMessage));

        await service.queueMessage(testMessage);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(service.queuedMessages.length, 0);
        expect(service.failedMessages.length, 0);
      });

      test('should retry failed message up to max attempts', () async {
        when(mockChatRepository.sendMessage(any))
            .thenAnswer((_) async => Result.error('Network error'));
        when(mockChatRepository.updateMessageStatus(
          messageId: any,
          status: any,
        )).thenAnswer((_) async => Result.success(null));

        await service.queueMessage(testMessage);
        
        // Wait for processing and retries
        await Future.delayed(const Duration(seconds: 1));

        expect(service.queuedMessages.length, 0);
        expect(service.failedMessages.length, 1);
        expect(service.failedMessages.first.attempts, 3);
      });

      test('should move message to failed queue after max attempts', () async {
        when(mockChatRepository.sendMessage(any))
            .thenAnswer((_) async => Result.error('Network error'));
        when(mockChatRepository.updateMessageStatus(
          messageId: any,
          status: any,
        )).thenAnswer((_) async => Result.success(null));

        await service.queueMessage(testMessage);
        await Future.delayed(const Duration(seconds: 1));

        expect(service.failedMessages.length, 1);
        expect(service.failedMessages.first.hasFailed, true);
        expect(service.failedMessages.first.lastError, 'Network error');
        
        verify(mockChatRepository.updateMessageStatus(
          messageId: testMessage.id,
          status: MessageStatus.failed,
        )).called(1);
      });
    });

    group('retry functionality', () {
      test('should retry specific failed message', () async {
        // First, create a failed message
        when(mockChatRepository.sendMessage(any))
            .thenAnswer((_) async => Result.error('Network error'));
        when(mockChatRepository.updateMessageStatus(
          messageId: any,
          status: any,
        )).thenAnswer((_) async => Result.success(null));

        await service.queueMessage(testMessage);
        await Future.delayed(const Duration(seconds: 1));

        expect(service.failedMessages.length, 1);

        // Now retry should succeed
        when(mockChatRepository.sendMessage(any))
            .thenAnswer((_) async => Result.success(testMessage));

        final result = await service.retryMessage(testMessage.id);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(result.isSuccess, true);
        expect(service.failedMessages.length, 0);
        expect(service.queuedMessages.length, 0);
      });

      test('should retry all failed messages', () async {
        final message2 = testMessage.copyWith(id: 'msg_456');
        
        // Create multiple failed messages
        when(mockChatRepository.sendMessage(any))
            .thenAnswer((_) async => Result.error('Network error'));
        when(mockChatRepository.updateMessageStatus(
          messageId: any,
          status: any,
        )).thenAnswer((_) async => Result.success(null));

        await service.queueMessage(testMessage);
        await service.queueMessage(message2);
        await Future.delayed(const Duration(seconds: 1));

        expect(service.failedMessages.length, 2);

        // Now retry all should succeed
        when(mockChatRepository.sendMessage(any))
            .thenAnswer((_) async => Result.success(testMessage));

        final result = await service.retryAllFailedMessages();
        await Future.delayed(const Duration(milliseconds: 200));

        expect(result.isSuccess, true);
        expect(service.failedMessages.length, 0);
        expect(service.queuedMessages.length, 0);
      });

      test('should remove failed message', () async {
        // Create a failed message
        when(mockChatRepository.sendMessage(any))
            .thenAnswer((_) async => Result.error('Network error'));
        when(mockChatRepository.updateMessageStatus(
          messageId: any,
          status: any,
        )).thenAnswer((_) async => Result.success(null));

        await service.queueMessage(testMessage);
        await Future.delayed(const Duration(seconds: 1));

        expect(service.failedMessages.length, 1);

        final result = await service.removeFailedMessage(testMessage.id);

        expect(result.isSuccess, true);
        expect(service.failedMessages.length, 0);
      });

      test('should clear all failed messages', () async {
        final message2 = testMessage.copyWith(id: 'msg_456');
        
        // Create multiple failed messages
        when(mockChatRepository.sendMessage(any))
            .thenAnswer((_) async => Result.error('Network error'));
        when(mockChatRepository.updateMessageStatus(
          messageId: any,
          status: any,
        )).thenAnswer((_) async => Result.success(null));

        await service.queueMessage(testMessage);
        await service.queueMessage(message2);
        await Future.delayed(const Duration(seconds: 1));

        expect(service.failedMessages.length, 2);

        final result = await service.clearFailedMessages();

        expect(result.isSuccess, true);
        expect(service.failedMessages.length, 0);
      });
    });

    group('queue status', () {
      test('should return correct queue status', () async {
        expect(service.queueStatus.queuedCount, 0);
        expect(service.queueStatus.failedCount, 0);
        expect(service.queueStatus.hasMessages, false);

        await service.queueMessage(testMessage);

        expect(service.queueStatus.queuedCount, 1);
        expect(service.queueStatus.totalCount, 1);
        expect(service.queueStatus.hasMessages, true);
      });
    });

    group('QueuedMessage', () {
      test('should serialize to and from JSON', () {
        final queuedMessage = QueuedMessage(
          message: testMessage,
          attempts: 2,
          queuedAt: DateTime.now(),
          failedAt: DateTime.now(),
          lastError: 'Test error',
        );

        final json = queuedMessage.toJson();
        final restored = QueuedMessage.fromJson(json);

        expect(restored.message.id, queuedMessage.message.id);
        expect(restored.attempts, queuedMessage.attempts);
        expect(restored.queuedAt, queuedMessage.queuedAt);
        expect(restored.failedAt, queuedMessage.failedAt);
        expect(restored.lastError, queuedMessage.lastError);
      });

      test('should calculate time since queued', () {
        final pastTime = DateTime.now().subtract(const Duration(minutes: 5));
        final queuedMessage = QueuedMessage(
          message: testMessage,
          attempts: 0,
          queuedAt: pastTime,
        );

        expect(queuedMessage.timeSinceQueued.inMinutes, 5);
      });

      test('should check if message has failed', () {
        final queuedMessage = QueuedMessage(
          message: testMessage,
          attempts: 0,
          queuedAt: DateTime.now(),
        );

        expect(queuedMessage.hasFailed, false);

        queuedMessage.failedAt = DateTime.now();
        expect(queuedMessage.hasFailed, true);
      });
    });

    tearDown(() {
      service.dispose();
    });
  });
}