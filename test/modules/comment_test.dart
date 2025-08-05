import 'package:flutter_test/flutter_test.dart';
import 'package:educonnect/modules/comment.dart';

void main() {
  group('Comment', () {
    late DateTime testDate;
    late DateTime editDate;
    late Comment testComment;

    setUp(() {
      testDate = DateTime(2024, 1, 1, 12, 0, 0);
      editDate = DateTime(2024, 1, 1, 12, 30, 0);
      testComment = Comment(
        id: 'comment123',
        postId: 'post123',
        userId: 'user123',
        content: 'This is a test comment',
        timestamp: testDate,
      );
    });

    group('JSON serialization', () {
      test('should serialize to JSON correctly', () {
        final editedComment = testComment.copyWith(
          editedAt: editDate,
          isEdited: true,
        );
        final json = editedComment.toJson();

        expect(json['id'], equals('comment123'));
        expect(json['postId'], equals('post123'));
        expect(json['userId'], equals('user123'));
        expect(json['content'], equals('This is a test comment'));
        expect(json['timestamp'], equals(testDate.toIso8601String()));
        expect(json['editedAt'], equals(editDate.toIso8601String()));
        expect(json['isEdited'], equals(true));
      });

      test('should serialize to JSON with null editedAt', () {
        final json = testComment.toJson();

        expect(json['id'], equals('comment123'));
        expect(json['postId'], equals('post123'));
        expect(json['userId'], equals('user123'));
        expect(json['content'], equals('This is a test comment'));
        expect(json['timestamp'], equals(testDate.toIso8601String()));
        expect(json['editedAt'], isNull);
        expect(json['isEdited'], equals(false));
      });

      test('should deserialize from JSON correctly', () {
        final json = {
          'id': 'comment123',
          'postId': 'post123',
          'userId': 'user123',
          'content': 'This is a test comment',
          'timestamp': testDate.toIso8601String(),
          'editedAt': editDate.toIso8601String(),
          'isEdited': true,
        };

        final comment = Comment.fromJson(json);

        expect(comment.id, equals('comment123'));
        expect(comment.postId, equals('post123'));
        expect(comment.userId, equals('user123'));
        expect(comment.content, equals('This is a test comment'));
        expect(comment.timestamp, equals(testDate));
        expect(comment.editedAt, equals(editDate));
        expect(comment.isEdited, equals(true));
      });

      test('should handle null optional fields in JSON', () {
        final json = {
          'id': 'comment123',
          'postId': 'post123',
          'userId': 'user123',
          'content': 'This is a test comment',
          'timestamp': testDate.toIso8601String(),
        };

        final comment = Comment.fromJson(json);

        expect(comment.editedAt, isNull);
        expect(comment.isEdited, equals(false));
      });

      test('should throw FormatException for invalid JSON', () {
        final invalidJson = {
          'id': 'comment123',
          'postId': 'post123',
          // Missing required 'userId' field
          'content': 'This is a test comment',
          'timestamp': testDate.toIso8601String(),
        };

        expect(() => Comment.fromJson(invalidJson), throwsFormatException);
      });
    });

    group('validation', () {
      test('should validate correct comment data', () {
        final result = Comment.validate(
          id: 'comment123',
          postId: 'post123',
          userId: 'user123',
          content: 'This is a test comment',
          timestamp: testDate,
        );

        expect(result.isSuccess, isTrue);
        expect(result.data?.id, equals('comment123'));
        expect(result.data?.postId, equals('post123'));
        expect(result.data?.userId, equals('user123'));
        expect(result.data?.content, equals('This is a test comment'));
      });

      test('should trim whitespace from fields', () {
        final result = Comment.validate(
          id: '  comment123  ',
          postId: '  post123  ',
          userId: '  user123  ',
          content: '  This is a test comment  ',
          timestamp: testDate,
        );

        expect(result.isSuccess, isTrue);
        expect(result.data?.id, equals('comment123'));
        expect(result.data?.postId, equals('post123'));
        expect(result.data?.userId, equals('user123'));
        expect(result.data?.content, equals('This is a test comment'));
      });

      test('should fail validation for empty required fields', () {
        final result = Comment.validate(
          id: '',
          postId: '',
          userId: '',
          content: '',
          timestamp: testDate,
        );

        expect(result.isError, isTrue);
        expect(result.errorMessage, contains('Comment ID cannot be empty'));
        expect(result.errorMessage, contains('Post ID cannot be empty'));
        expect(result.errorMessage, contains('User ID cannot be empty'));
        expect(result.errorMessage, contains('Comment content cannot be empty'));
      });

      test('should fail validation for content too long', () {
        final result = Comment.validate(
          id: 'comment123',
          postId: 'post123',
          userId: 'user123',
          content: 'A' * 1001,
          timestamp: testDate,
        );

        expect(result.isError, isTrue);
        expect(result.errorMessage, contains('Comment content cannot exceed 1000 characters'));
      });

      test('should fail validation for future timestamp', () {
        final futureDate = DateTime.now().add(const Duration(hours: 1));
        final result = Comment.validate(
          id: 'comment123',
          postId: 'post123',
          userId: 'user123',
          content: 'Test content',
          timestamp: futureDate,
        );

        expect(result.isError, isTrue);
        expect(result.errorMessage, contains('Comment timestamp cannot be in the future'));
      });

      test('should fail validation for edit timestamp before original', () {
        final result = Comment.validate(
          id: 'comment123',
          postId: 'post123',
          userId: 'user123',
          content: 'Test content',
          timestamp: testDate,
          editedAt: testDate.subtract(const Duration(minutes: 30)),
          isEdited: true,
        );

        expect(result.isError, isTrue);
        expect(result.errorMessage, contains('Edit timestamp cannot be before original timestamp'));
      });

      test('should fail validation for future edit timestamp', () {
        final futureEditDate = DateTime.now().add(const Duration(hours: 1));
        final result = Comment.validate(
          id: 'comment123',
          postId: 'post123',
          userId: 'user123',
          content: 'Test content',
          timestamp: testDate,
          editedAt: futureEditDate,
          isEdited: true,
        );

        expect(result.isError, isTrue);
        expect(result.errorMessage, contains('Edit timestamp cannot be in the future'));
      });

      test('should fail validation for edited comment without edit timestamp', () {
        final result = Comment.validate(
          id: 'comment123',
          postId: 'post123',
          userId: 'user123',
          content: 'Test content',
          timestamp: testDate,
          isEdited: true,
        );

        expect(result.isError, isTrue);
        expect(result.errorMessage, contains('Edited comments must have an edit timestamp'));
      });

      test('should fail validation for non-edited comment with edit timestamp', () {
        final result = Comment.validate(
          id: 'comment123',
          postId: 'post123',
          userId: 'user123',
          content: 'Test content',
          timestamp: testDate,
          editedAt: editDate,
          isEdited: false,
        );

        expect(result.isError, isTrue);
        expect(result.errorMessage, contains('Non-edited comments cannot have an edit timestamp'));
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        final updatedComment = testComment.copyWith(
          content: 'Updated content',
          isEdited: true,
          editedAt: editDate,
        );

        expect(updatedComment.content, equals('Updated content'));
        expect(updatedComment.isEdited, equals(true));
        expect(updatedComment.editedAt, equals(editDate));
        expect(updatedComment.id, equals(testComment.id)); // Unchanged
        expect(updatedComment.userId, equals(testComment.userId)); // Unchanged
      });

      test('should preserve original values when no updates provided', () {
        final copiedComment = testComment.copyWith();

        expect(copiedComment.id, equals(testComment.id));
        expect(copiedComment.postId, equals(testComment.postId));
        expect(copiedComment.userId, equals(testComment.userId));
        expect(copiedComment.content, equals(testComment.content));
        expect(copiedComment.timestamp, equals(testComment.timestamp));
      });
    });

    group('edit functionality', () {
      test('should create edited comment', () {
        final editedComment = testComment.edit('Updated comment content');

        expect(editedComment.content, equals('Updated comment content'));
        expect(editedComment.isEdited, equals(true));
        expect(editedComment.editedAt, isNotNull);
        expect(editedComment.editedAt!.isAfter(testComment.timestamp), isTrue);
      });

      test('should trim content when editing', () {
        final editedComment = testComment.edit('  Updated comment content  ');

        expect(editedComment.content, equals('Updated comment content'));
      });
    });

    group('utility methods', () {
      test('should return formatted timestamp', () {
        final now = DateTime.now();
        
        // Test "Just now"
        final recentComment = testComment.copyWith(timestamp: now);
        expect(recentComment.formattedTimestamp, equals('Just now'));
        
        // Test minutes ago
        final minutesAgoComment = testComment.copyWith(timestamp: now.subtract(const Duration(minutes: 30)));
        expect(minutesAgoComment.formattedTimestamp, equals('30m ago'));
        
        // Test hours ago
        final hoursAgoComment = testComment.copyWith(timestamp: now.subtract(const Duration(hours: 2)));
        expect(hoursAgoComment.formattedTimestamp, equals('2h ago'));
        
        // Test days ago
        final daysAgoComment = testComment.copyWith(timestamp: now.subtract(const Duration(days: 3)));
        expect(daysAgoComment.formattedTimestamp, equals('3d ago'));
      });

      test('should return formatted edit timestamp', () {
        expect(testComment.formattedEditTimestamp, isNull);
        
        final now = DateTime.now();
        final editedComment = testComment.copyWith(
          editedAt: now.subtract(const Duration(minutes: 15)),
          isEdited: true,
        );
        expect(editedComment.formattedEditTimestamp, equals('edited 15m ago'));
      });

      test('should return content preview', () {
        expect(testComment.contentPreview, equals('This is a test comment'));
        
        final longContent = 'A' * 100;
        final longComment = testComment.copyWith(content: longContent);
        expect(longComment.contentPreview, equals('${'A' * 47}...'));
        expect(longComment.contentPreview.length, equals(50));
      });

      test('should match search query', () {
        expect(testComment.matchesSearch('test'), isTrue);
        expect(testComment.matchesSearch('TEST'), isTrue);
        expect(testComment.matchesSearch('comment'), isTrue);
        expect(testComment.matchesSearch('nonexistent'), isFalse);
      });

      test('should check if comment can be edited', () {
        final now = DateTime.now();
        
        // Recent comment should be editable
        final recentComment = testComment.copyWith(timestamp: now.subtract(const Duration(hours: 1)));
        expect(recentComment.canBeEdited(), isTrue);
        
        // Old comment should not be editable
        final oldComment = testComment.copyWith(timestamp: now.subtract(const Duration(days: 2)));
        expect(oldComment.canBeEdited(), isFalse);
        
        // Custom time limit
        expect(oldComment.canBeEdited(editTimeLimit: const Duration(days: 3)), isTrue);
      });

      test('should check if comment can be deleted by user', () {
        expect(testComment.canBeDeletedBy('user123'), isTrue); // Owner
        expect(testComment.canBeDeletedBy('user456'), isFalse); // Not owner
        expect(testComment.canBeDeletedBy('user456', isCurrentUserModerator: true), isTrue); // Moderator
      });

      test('should check if comment can be edited by user', () {
        final now = DateTime.now();
        final recentComment = testComment.copyWith(timestamp: now.subtract(const Duration(hours: 1)));
        final oldComment = testComment.copyWith(timestamp: now.subtract(const Duration(days: 2)));
        
        expect(recentComment.canBeEditedBy('user123'), isTrue); // Owner, recent
        expect(recentComment.canBeEditedBy('user456'), isFalse); // Not owner
        expect(oldComment.canBeEditedBy('user123'), isFalse); // Owner, but too old
      });

      test('should calculate age correctly', () {
        final now = DateTime.now();
        final comment = testComment.copyWith(timestamp: now.subtract(const Duration(hours: 2, minutes: 30)));
        
        expect(comment.ageInMinutes, equals(150));
        expect(comment.ageInHours, equals(2));
        expect(comment.ageInDays, equals(0));
      });

      test('should check if comment is recent or old', () {
        final now = DateTime.now();
        
        final recentComment = testComment.copyWith(timestamp: now.subtract(const Duration(minutes: 30)));
        expect(recentComment.isRecent, isTrue);
        expect(recentComment.isOld, isFalse);
        
        final oldComment = testComment.copyWith(timestamp: now.subtract(const Duration(days: 10)));
        expect(oldComment.isRecent, isFalse);
        expect(oldComment.isOld, isTrue);
      });

      test('should have correct string representation', () {
        final commentString = testComment.toString();
        expect(commentString, contains('comment123'));
        expect(commentString, contains('post123'));
        expect(commentString, contains('user123'));
        expect(commentString, contains('This is a test comment'));
        
        final editedComment = testComment.copyWith(isEdited: true);
        final editedString = editedComment.toString();
        expect(editedString, contains('(edited)'));
      });

      test('should implement equality correctly', () {
        final sameComment = Comment(
          id: 'comment123',
          postId: 'post123',
          userId: 'user123',
          content: 'This is a test comment',
          timestamp: testDate,
        );

        final differentComment = testComment.copyWith(id: 'comment456');

        expect(testComment == sameComment, isTrue);
        expect(testComment == differentComment, isFalse);
      });
    });
  });
}