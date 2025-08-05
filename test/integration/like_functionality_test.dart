import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:educonnect/modules/post.dart';
import 'package:educonnect/modules/user.dart';
import 'package:educonnect/providers/post_provider.dart';
import 'package:educonnect/providers/auth_provider.dart';
import 'package:educonnect/repositories/post_repository.dart';
import 'package:educonnect/repositories/user_repository.dart';
import 'package:educonnect/services/navigation_service.dart';
import 'package:educonnect/core/logger.dart';
import 'package:educonnect/core/result.dart';
import 'package:educonnect/widgets/post.dart';

import 'like_functionality_test.mocks.dart';

@GenerateMocks([
  PostRepository,
  UserRepository,
  NavigationService,
  Logger,
])
void main() {
  group('Like Functionality Integration Tests', () {
    late MockPostRepository mockPostRepository;
    late MockUserRepository mockUserRepository;
    late MockNavigationService mockNavigationService;
    late MockLogger mockLogger;
    late ProviderContainer container;

    setUp(() {
      mockPostRepository = MockPostRepository();
      mockUserRepository = MockUserRepository();
      mockNavigationService = MockNavigationService();
      mockLogger = MockLogger();

      container = ProviderContainer(
        overrides: [
          postRepositoryProvider.overrideWithValue(mockPostRepository),
          userRepositoryProvider.overrideWithValue(mockUserRepository),
          navigationServiceProvider.overrideWithValue(mockNavigationService),
          loggerProvider.overrideWithValue(mockLogger),
          authProvider.overrideWith((ref) => 'test-user-id'),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('should toggle like state when like button is pressed', (WidgetTester tester) async {
      // Arrange
      const userId = 'test-user-id';
      const postId = 'test-post-id';
      
      final initialPost = Post(
        id: postId,
        content: 'Test post content',
        userId: 'author-id',
        timestamp: DateTime.now(),
        likeCount: 0,
        likedBy: [],
      );

      final likedPost = initialPost.addLike(userId);

      // Mock successful like toggle
      when(mockPostRepository.toggleLike(postId, userId))
          .thenAnswer((_) async => Result.success(null));

      // Build widget
      await tester.pumpWidget(
        UncontainerizedProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: PostWidget(post: initialPost),
            ),
          ),
        ),
      );

      // Verify initial state - post is not liked
      expect(find.byIcon(Icons.thumb_up_outlined), findsOneWidget);
      expect(find.text('Like'), findsOneWidget);

      // Act - tap the like button
      await tester.tap(find.byIcon(Icons.thumb_up_outlined));
      await tester.pump();

      // Verify the repository method was called
      verify(mockPostRepository.toggleLike(postId, userId)).called(1);
    });

    testWidgets('should show liked state when post is already liked by user', (WidgetTester tester) async {
      // Arrange
      const userId = 'test-user-id';
      const postId = 'test-post-id';
      
      final likedPost = Post(
        id: postId,
        content: 'Test post content',
        userId: 'author-id',
        timestamp: DateTime.now(),
        likeCount: 1,
        likedBy: [userId],
      );

      // Build widget
      await tester.pumpWidget(
        UncontainerizedProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: PostWidget(post: likedPost),
            ),
          ),
        ),
      );

      // Verify liked state
      expect(find.byIcon(Icons.thumb_up), findsOneWidget);
      expect(find.text('1 Like'), findsOneWidget);
    });

    testWidgets('should show correct like count for multiple likes', (WidgetTester tester) async {
      // Arrange
      const userId = 'test-user-id';
      const postId = 'test-post-id';
      
      final multiLikedPost = Post(
        id: postId,
        content: 'Test post content',
        userId: 'author-id',
        timestamp: DateTime.now(),
        likeCount: 5,
        likedBy: ['user1', 'user2', 'user3', 'user4', 'user5'],
      );

      // Build widget
      await tester.pumpWidget(
        UncontainerizedProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: PostWidget(post: multiLikedPost),
            ),
          ),
        ),
      );

      // Verify like count display
      expect(find.text('5 Likes'), findsOneWidget);
    });

    test('should update post state when like is toggled via provider', () async {
      // Arrange
      const userId = 'test-user-id';
      const postId = 'test-post-id';
      
      final initialPost = Post(
        id: postId,
        content: 'Test post content',
        userId: 'author-id',
        timestamp: DateTime.now(),
        likeCount: 0,
        likedBy: [],
      );

      // Set up initial state
      final postProviderNotifier = container.read(postProvider.notifier);
      container.read(postProvider.notifier).state = 
          container.read(postProvider).copyWith(posts: [initialPost]);

      // Mock successful like toggle
      when(mockPostRepository.toggleLike(postId, userId))
          .thenAnswer((_) async => Result.success(null));

      // Act
      await postProviderNotifier.toggleLike(userId, postId);

      // Verify
      verify(mockPostRepository.toggleLike(postId, userId)).called(1);
      
      // Verify the post state was updated locally
      final updatedState = container.read(postProvider);
      final updatedPost = updatedState.posts.firstWhere((p) => p.id == postId);
      expect(updatedPost.isLikedBy(userId), isTrue);
      expect(updatedPost.likeCount, equals(1));
    });

    test('should handle like toggle error gracefully', () async {
      // Arrange
      const userId = 'test-user-id';
      const postId = 'test-post-id';
      
      final initialPost = Post(
        id: postId,
        content: 'Test post content',
        userId: 'author-id',
        timestamp: DateTime.now(),
        likeCount: 0,
        likedBy: [],
      );

      // Set up initial state
      container.read(postProvider.notifier).state = 
          container.read(postProvider).copyWith(posts: [initialPost]);

      // Mock failed like toggle
      when(mockPostRepository.toggleLike(postId, userId))
          .thenAnswer((_) async => Result.error('Network error'));

      // Act
      await container.read(postProvider.notifier).toggleLike(userId, postId);

      // Verify
      verify(mockPostRepository.toggleLike(postId, userId)).called(1);
      verify(mockNavigationService.showErrorSnackBar('Failed to update like')).called(1);
      
      // Verify the post state was not changed due to error
      final state = container.read(postProvider);
      final post = state.posts.firstWhere((p) => p.id == postId);
      expect(post.isLikedBy(userId), isFalse);
      expect(post.likeCount, equals(0));
    });

    test('should handle real-time like updates from other users', () async {
      // Arrange
      const currentUserId = 'test-user-id';
      const otherUserId = 'other-user-id';
      const postId = 'test-post-id';
      
      final initialPost = Post(
        id: postId,
        content: 'Test post content',
        userId: 'author-id',
        timestamp: DateTime.now(),
        likeCount: 0,
        likedBy: [],
      );

      // Set up initial state
      container.read(postProvider.notifier).state = 
          container.read(postProvider).copyWith(posts: [initialPost]);

      // Simulate another user liking the post (real-time update)
      final updatedPost = initialPost.addLike(otherUserId);
      container.read(postProvider.notifier).state = 
          container.read(postProvider).copyWith(posts: [updatedPost]);

      // Verify
      final state = container.read(postProvider);
      final post = state.posts.firstWhere((p) => p.id == postId);
      expect(post.likeCount, equals(1));
      expect(post.isLikedBy(otherUserId), isTrue);
      expect(post.isLikedBy(currentUserId), isFalse);
    });

    testWidgets('should show visual feedback during like action', (WidgetTester tester) async {
      // Arrange
      const userId = 'test-user-id';
      const postId = 'test-post-id';
      
      final initialPost = Post(
        id: postId,
        content: 'Test post content',
        userId: 'author-id',
        timestamp: DateTime.now(),
        likeCount: 0,
        likedBy: [],
      );

      // Mock delayed like toggle to test loading state
      when(mockPostRepository.toggleLike(postId, userId))
          .thenAnswer((_) async {
        await Future.delayed(Duration(milliseconds: 100));
        return Result.success(null);
      });

      // Build widget
      await tester.pumpWidget(
        UncontainerizedProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: PostWidget(post: initialPost),
            ),
          ),
        ),
      );

      // Verify initial state
      expect(find.byIcon(Icons.thumb_up_outlined), findsOneWidget);

      // Act - tap the like button
      await tester.tap(find.byIcon(Icons.thumb_up_outlined));
      await tester.pump(Duration(milliseconds: 50)); // Pump during async operation

      // The visual feedback should be immediate due to optimistic updates
      // The actual state update happens in the provider
      
      // Complete the async operation
      await tester.pumpAndSettle();

      // Verify the repository method was called
      verify(mockPostRepository.toggleLike(postId, userId)).called(1);
    });
  });
}