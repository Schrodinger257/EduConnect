import 'package:flutter_test/flutter_test.dart';
import 'package:educonnect/modules/post.dart';

void main() {
  group('Post', () {
    late DateTime testDate;
    late Post testPost;

    setUp(() {
      testDate = DateTime(2024, 1, 1, 12, 0, 0);
      testPost = Post(
        id: 'post123',
        content: 'This is a test post content',
        userId: 'user123',
        imageUrl: 'https://example.com/image.jpg',
        tags: ['education', 'flutter'],
        timestamp: testDate,
        likeCount: 2,
        likedBy: ['user1', 'user2'],
        commentCount: 1,
        commentIds: ['comment1'],
      );
    });

    group('JSON serialization', () {
      test('should serialize to JSON correctly', () {
        final json = testPost.toJson();

        expect(json['id'], equals('post123'));
        expect(json['content'], equals('This is a test post content'));
        expect(json['userId'], equals('user123'));
        expect(json['imageUrl'], equals('https://example.com/image.jpg'));
        expect(json['tags'], equals(['education', 'flutter']));
        expect(json['timestamp'], equals(testDate.toIso8601String()));
        expect(json['likeCount'], equals(2));
        expect(json['likedBy'], equals(['user1', 'user2']));
        expect(json['commentCount'], equals(1));
        expect(json['commentIds'], equals(['comment1']));
      });

      test('should deserialize from JSON correctly', () {
        final json = {
          'id': 'post123',
          'content': 'This is a test post content',
          'userId': 'user123',
          'imageUrl': 'https://example.com/image.jpg',
          'tags': ['education', 'flutter'],
          'timestamp': testDate.toIso8601String(),
          'likeCount': 2,
          'likedBy': ['user1', 'user2'],
          'commentCount': 1,
          'commentIds': ['comment1'],
        };

        final post = Post.fromJson(json);

        expect(post.id, equals('post123'));
        expect(post.content, equals('This is a test post content'));
        expect(post.userId, equals('user123'));
        expect(post.imageUrl, equals('https://example.com/image.jpg'));
        expect(post.tags, equals(['education', 'flutter']));
        expect(post.timestamp, equals(testDate));
        expect(post.likeCount, equals(2));
        expect(post.likedBy, equals(['user1', 'user2']));
        expect(post.commentCount, equals(1));
        expect(post.commentIds, equals(['comment1']));
      });

      test('should handle null optional fields in JSON', () {
        final json = {
          'id': 'post123',
          'content': 'This is a test post content',
          'userId': 'user123',
          'timestamp': testDate.toIso8601String(),
        };

        final post = Post.fromJson(json);

        expect(post.imageUrl, isNull);
        expect(post.tags, isEmpty);
        expect(post.likeCount, equals(0));
        expect(post.likedBy, isEmpty);
        expect(post.commentCount, equals(0));
        expect(post.commentIds, isEmpty);
      });

      test('should throw FormatException for invalid JSON', () {
        final invalidJson = {
          'id': 'post123',
          'content': 'This is a test post content',
          // Missing required 'userId' field
          'timestamp': testDate.toIso8601String(),
        };

        expect(() => Post.fromJson(invalidJson), throwsFormatException);
      });
    });

    group('validation', () {
      test('should validate correct post data', () {
        final result = Post.validate(
          id: 'post123',
          content: 'This is a test post',
          userId: 'user123',
          timestamp: testDate,
        );

        expect(result.isSuccess, isTrue);
        expect(result.data?.id, equals('post123'));
        expect(result.data?.content, equals('This is a test post'));
        expect(result.data?.userId, equals('user123'));
      });

      test('should trim whitespace from fields', () {
        final result = Post.validate(
          id: '  post123  ',
          content: '  This is a test post  ',
          userId: '  user123  ',
          timestamp: testDate,
        );

        expect(result.isSuccess, isTrue);
        expect(result.data?.id, equals('post123'));
        expect(result.data?.content, equals('This is a test post'));
        expect(result.data?.userId, equals('user123'));
      });

      test('should fail validation for empty required fields', () {
        final result = Post.validate(
          id: '',
          content: '',
          userId: '',
          timestamp: testDate,
        );

        expect(result.isError, isTrue);
        expect(result.errorMessage, contains('Post ID cannot be empty'));
        expect(result.errorMessage, contains('Post content cannot be empty'));
        expect(result.errorMessage, contains('User ID cannot be empty'));
      });

      test('should fail validation for content too long', () {
        final result = Post.validate(
          id: 'post123',
          content: 'A' * 5001,
          userId: 'user123',
          timestamp: testDate,
        );

        expect(result.isError, isTrue);
        expect(result.errorMessage, contains('Post content cannot exceed 5000 characters'));
      });

      test('should fail validation for empty image URL', () {
        final result = Post.validate(
          id: 'post123',
          content: 'Test content',
          userId: 'user123',
          imageUrl: '',
          timestamp: testDate,
        );

        expect(result.isError, isTrue);
        expect(result.errorMessage, contains('Image URL cannot be empty if provided'));
      });

      test('should fail validation for too many tags', () {
        final result = Post.validate(
          id: 'post123',
          content: 'Test content',
          userId: 'user123',
          tags: List.generate(11, (index) => 'tag$index'),
          timestamp: testDate,
        );

        expect(result.isError, isTrue);
        expect(result.errorMessage, contains('Cannot have more than 10 tags'));
      });

      test('should fail validation for empty tags', () {
        final result = Post.validate(
          id: 'post123',
          content: 'Test content',
          userId: 'user123',
          tags: ['valid', ''],
          timestamp: testDate,
        );

        expect(result.isError, isTrue);
        expect(result.errorMessage, contains('Tags cannot be empty'));
      });

      test('should fail validation for long tags', () {
        final result = Post.validate(
          id: 'post123',
          content: 'Test content',
          userId: 'user123',
          tags: ['A' * 51],
          timestamp: testDate,
        );

        expect(result.isError, isTrue);
        expect(result.errorMessage, contains('Tags cannot exceed 50 characters'));
      });

      test('should fail validation for negative counts', () {
        final result = Post.validate(
          id: 'post123',
          content: 'Test content',
          userId: 'user123',
          timestamp: testDate,
          likeCount: -1,
          commentCount: -1,
        );

        expect(result.isError, isTrue);
        expect(result.errorMessage, contains('Like count cannot be negative'));
        expect(result.errorMessage, contains('Comment count cannot be negative'));
      });

      test('should fail validation for inconsistent counts and arrays', () {
        final result = Post.validate(
          id: 'post123',
          content: 'Test content',
          userId: 'user123',
          timestamp: testDate,
          likeCount: 2,
          likedBy: ['user1'], // Should have 2 users
          commentCount: 1,
          commentIds: ['comment1', 'comment2'], // Should have 1 comment
        );

        expect(result.isError, isTrue);
        expect(result.errorMessage, contains('Like count must match likedBy array length'));
        expect(result.errorMessage, contains('Comment count must match commentIds array length'));
      });

      test('should fail validation for future timestamp', () {
        final futureDate = DateTime.now().add(const Duration(hours: 1));
        final result = Post.validate(
          id: 'post123',
          content: 'Test content',
          userId: 'user123',
          timestamp: futureDate,
        );

        expect(result.isError, isTrue);
        expect(result.errorMessage, contains('Post timestamp cannot be in the future'));
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        final updatedPost = testPost.copyWith(
          content: 'Updated content',
          likeCount: 5,
        );

        expect(updatedPost.content, equals('Updated content'));
        expect(updatedPost.likeCount, equals(5));
        expect(updatedPost.id, equals(testPost.id)); // Unchanged
        expect(updatedPost.userId, equals(testPost.userId)); // Unchanged
      });

      test('should preserve original values when no updates provided', () {
        final copiedPost = testPost.copyWith();

        expect(copiedPost.id, equals(testPost.id));
        expect(copiedPost.content, equals(testPost.content));
        expect(copiedPost.userId, equals(testPost.userId));
        expect(copiedPost.likeCount, equals(testPost.likeCount));
      });
    });

    group('like operations', () {
      test('should add like', () {
        final updatedPost = testPost.addLike('user3');

        expect(updatedPost.likedBy, contains('user3'));
        expect(updatedPost.likeCount, equals(3));
      });

      test('should not add duplicate like', () {
        final updatedPost = testPost.addLike('user1');

        expect(updatedPost.likeCount, equals(2));
        expect(updatedPost.likedBy, equals(testPost.likedBy));
      });

      test('should remove like', () {
        final updatedPost = testPost.removeLike('user1');

        expect(updatedPost.likedBy, isNot(contains('user1')));
        expect(updatedPost.likeCount, equals(1));
      });

      test('should not remove non-existent like', () {
        final updatedPost = testPost.removeLike('user3');

        expect(updatedPost.likeCount, equals(2));
        expect(updatedPost.likedBy, equals(testPost.likedBy));
      });

      test('should toggle like correctly', () {
        // Toggle off existing like
        final unlikedPost = testPost.toggleLike('user1');
        expect(unlikedPost.isLikedBy('user1'), isFalse);
        expect(unlikedPost.likeCount, equals(1));

        // Toggle on new like
        final likedPost = testPost.toggleLike('user3');
        expect(likedPost.isLikedBy('user3'), isTrue);
        expect(likedPost.likeCount, equals(3));
      });

      test('should check if post is liked by user', () {
        expect(testPost.isLikedBy('user1'), isTrue);
        expect(testPost.isLikedBy('user3'), isFalse);
      });
    });

    group('comment operations', () {
      test('should add comment', () {
        final updatedPost = testPost.addComment('comment2');

        expect(updatedPost.commentIds, contains('comment2'));
        expect(updatedPost.commentCount, equals(2));
      });

      test('should not add duplicate comment', () {
        final updatedPost = testPost.addComment('comment1');

        expect(updatedPost.commentCount, equals(1));
        expect(updatedPost.commentIds, equals(testPost.commentIds));
      });

      test('should remove comment', () {
        final updatedPost = testPost.removeComment('comment1');

        expect(updatedPost.commentIds, isNot(contains('comment1')));
        expect(updatedPost.commentCount, equals(0));
      });

      test('should not remove non-existent comment', () {
        final updatedPost = testPost.removeComment('comment2');

        expect(updatedPost.commentCount, equals(1));
        expect(updatedPost.commentIds, equals(testPost.commentIds));
      });
    });

    group('utility methods', () {
      test('should check if post has comments', () {
        expect(testPost.hasComments, isTrue);
        
        final noCommentsPost = testPost.copyWith(commentCount: 0, commentIds: []);
        expect(noCommentsPost.hasComments, isFalse);
      });

      test('should check if post has likes', () {
        expect(testPost.hasLikes, isTrue);
        
        final noLikesPost = testPost.copyWith(likeCount: 0, likedBy: []);
        expect(noLikesPost.hasLikes, isFalse);
      });

      test('should check if post has image', () {
        expect(testPost.hasImage, isTrue);
        
        final noImagePost = testPost.copyWith(imageUrl: null);
        expect(noImagePost.hasImage, isFalse);
        
        final emptyImagePost = testPost.copyWith(imageUrl: '');
        expect(emptyImagePost.hasImage, isFalse);
      });

      test('should check if post has tags', () {
        expect(testPost.hasTags, isTrue);
        
        final noTagsPost = testPost.copyWith(tags: []);
        expect(noTagsPost.hasTags, isFalse);
      });

      test('should return formatted timestamp', () {
        final now = DateTime.now();
        
        // Test "Just now"
        final recentPost = testPost.copyWith(timestamp: now);
        expect(recentPost.formattedTimestamp, equals('Just now'));
        
        // Test minutes ago
        final minutesAgoPost = testPost.copyWith(timestamp: now.subtract(const Duration(minutes: 30)));
        expect(minutesAgoPost.formattedTimestamp, equals('30m ago'));
        
        // Test hours ago
        final hoursAgoPost = testPost.copyWith(timestamp: now.subtract(const Duration(hours: 2)));
        expect(hoursAgoPost.formattedTimestamp, equals('2h ago'));
        
        // Test days ago
        final daysAgoPost = testPost.copyWith(timestamp: now.subtract(const Duration(days: 3)));
        expect(daysAgoPost.formattedTimestamp, equals('3d ago'));
      });

      test('should return content preview', () {
        expect(testPost.contentPreview, equals('This is a test post content'));
        
        final longContent = 'A' * 150;
        final longPost = testPost.copyWith(content: longContent);
        expect(longPost.contentPreview, equals('${'A' * 97}...'));
        expect(longPost.contentPreview.length, equals(100));
      });

      test('should match search query', () {
        expect(testPost.matchesSearch('test'), isTrue);
        expect(testPost.matchesSearch('TEST'), isTrue);
        expect(testPost.matchesSearch('education'), isTrue);
        expect(testPost.matchesSearch('flutter'), isTrue);
        expect(testPost.matchesSearch('nonexistent'), isFalse);
      });

      test('should calculate engagement score', () {
        expect(testPost.engagementScore, equals(3)); // 2 likes + 1 comment
        
        final noEngagementPost = testPost.copyWith(likeCount: 0, likedBy: [], commentCount: 0, commentIds: []);
        expect(noEngagementPost.engagementScore, equals(0));
      });

      test('should have correct string representation', () {
        final postString = testPost.toString();
        expect(postString, contains('post123'));
        expect(postString, contains('user123'));
        expect(postString, contains('This is a test post content'));
        expect(postString, contains('likes: 2'));
        expect(postString, contains('comments: 1'));
      });

      test('should implement equality correctly', () {
        final samePost = Post(
          id: 'post123',
          content: 'This is a test post content',
          userId: 'user123',
          imageUrl: 'https://example.com/image.jpg',
          timestamp: testDate,
        );

        final differentPost = testPost.copyWith(id: 'post456');

        expect(testPost == samePost, isTrue);
        expect(testPost == differentPost, isFalse);
      });
    });
  });
}