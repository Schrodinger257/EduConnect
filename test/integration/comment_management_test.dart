import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:educonnect/modules/comment.dart';
import 'package:educonnect/modules/user.dart';
import 'package:educonnect/providers/comment_provider.dart';
import 'package:educonnect/providers/auth_provider.dart';
import 'package:educonnect/repositories/post_repository.dart';
import 'package:educonnect/services/navigation_service.dart';
import 'package:educonnect/core/logger.dart';
import 'package:educonnect/core/result.dart';
import 'package:educonnect/widgets/comment_widget.dart';
import 'package:educonnect/widgets/comment_moderation_dialog.dart';

import 'comment_management_test.mocks.dart';

@GenerateMocks([
  PostRepository,
  NavigationService,
  Logger,
])
void main() {
  group('Comment Management Tests', () {
    late MockPostRepository mockPostRepository;
    late MockNavigationService mockNavigationService;
    late MockLogger mockLogger;
    late ProviderContainer container;

    setUp(() {
      mockPostRepository = MockPostRepository();
      mockNavigationService = MockNavigationService();
      mockLogger = MockLogger();

      container = ProviderContainer(
        overrides: [
          postRepositoryProvider.overrideWithValue(mockPostRepository),
          navigationServiceProvider.overrideWithValue(mockNavigationService),
          loggerProvider.overrideWithValue(mockLogger),
          authProvider.overrideWith((ref) => 'test-user-id'),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('Comment Deletion', () {
      test('should allow comment owner to delete their comment', () async {
        // Arrange
        const userId = 'test-user-id';
        const commentId = 'test-comment-id';
        const postId = 'test-post-id';
        
        final comment = Comment(
          id: commentId,
          postId: postId,
          userId: userId,
          content: 'Test comment',
          timestamp: DateTime.now(),
        );

        // Mock successful deletion
        when(mockPostRepository.deleteComment(commentId, postId))
            .thenAnswer((_) async => Result.success(null));

        // Act
        await container.read(commentProvider.notifier).deleteComment(commentId, postId);

        // Verify
        verify(mockPostRepository.deleteComment(commentId, postId)).called(1);
        verify(mockNavigationService.showSuccessSnackBar('Comment deleted successfully')).called(1);
      });

      test('should allow moderator to delete any comment with reason', () async {
        // Arrange
        const moderatorId = 'moderator-id';
        const commentId = 'test-comment-id';
        const postId = 'test-post-id';
        const reason = 'Inappropriate content';
        
        container = ProviderContainer(
          overrides: [
            postRepositoryProvider.overrideWithValue(mockPostRepository),
            navigationServiceProvider.overrideWithValue(mockNavigationService),
            loggerProvider.overrideWithValue(mockLogger),
            authProvider.overrideWith((ref) => moderatorId),
          ],
        );

        // Mock successful deletion
        when(mockPostRepository.deleteComment(commentId, postId))
            .thenAnswer((_) async => Result.success(null));

        // Act
        await container.read(commentProvider.notifier).deleteComment(commentId, postId, reason: reason);

        // Verify
        verify(mockPostRepository.deleteComment(commentId, postId)).called(1);
        verify(mockNavigationService.showSuccessSnackBar('Comment removed: $reason')).called(1);
      });

      test('should handle comment deletion error gracefully', () async {
        // Arrange
        const userId = 'test-user-id';
        const commentId = 'test-comment-id';
        const postId = 'test-post-id';

        // Mock failed deletion
        when(mockPostRepository.deleteComment(commentId, postId))
            .thenAnswer((_) async => Result.error('Network error'));

        // Act
        await container.read(commentProvider.notifier).deleteComment(commentId, postId);

        // Verify
        verify(mockPostRepository.deleteComment(commentId, postId)).called(1);
        verify(mockNavigationService.showErrorSnackBar('Failed to delete comment: Network error')).called(1);
      });
    });

    group('Comment Editing', () {
      test('should allow comment owner to edit their comment within time limit', () async {
        // Arrange
        const userId = 'test-user-id';
        const commentId = 'test-comment-id';
        const postId = 'test-post-id';
        const newContent = 'Updated comment content';
        
        final originalComment = Comment(
          id: commentId,
          postId: postId,
          userId: userId,
          content: 'Original comment',
          timestamp: DateTime.now().subtract(const Duration(minutes: 30)), // Within edit limit
        );

        final updatedComment = originalComment.edit(newContent);

        // Mock successful update
        when(mockPostRepository.updateComment(any))
            .thenAnswer((_) async => Result.success(updatedComment));

        // Act
        await container.read(commentProvider.notifier).updateComment(originalComment, newContent);

        // Verify
        verify(mockPostRepository.updateComment(any)).called(1);
        verify(mockNavigationService.showSuccessSnackBar('Comment updated successfully')).called(1);
      });

      test('should reject empty comment content', () async {
        // Arrange
        const userId = 'test-user-id';
        const commentId = 'test-comment-id';
        const postId = 'test-post-id';
        const emptyContent = '   '; // Whitespace only
        
        final comment = Comment(
          id: commentId,
          postId: postId,
          userId: userId,
          content: 'Original comment',
          timestamp: DateTime.now(),
        );

        // Act
        await container.read(commentProvider.notifier).updateComment(comment, emptyContent);

        // Verify
        verifyNever(mockPostRepository.updateComment(any));
        verify(mockNavigationService.showErrorSnackBar('Comment cannot be empty')).called(1);
      });
    });

    group('Comment Moderation', () {
      test('should allow moderator to moderate comments', () async {
        // Arrange
        const moderatorId = 'moderator-id';
        const commentId = 'test-comment-id';
        const postId = 'test-post-id';
        const action = 'delete';
        const reason = 'Spam content';

        container = ProviderContainer(
          overrides: [
            postRepositoryProvider.overrideWithValue(mockPostRepository),
            navigationServiceProvider.overrideWithValue(mockNavigationService),
            loggerProvider.overrideWithValue(mockLogger),
            authProvider.overrideWith((ref) => moderatorId),
          ],
        );

        // Mock successful moderation
        when(mockPostRepository.deleteComment(commentId, postId))
            .thenAnswer((_) async => Result.success(null));

        // Act
        await container.read(commentProvider.notifier).moderateComment(commentId, postId, action, reason: reason);

        // Verify
        verify(mockPostRepository.deleteComment(commentId, postId)).called(1);
        verify(mockNavigationService.showSuccessSnackBar('Comment removed: $reason')).called(1);
      });

      test('should handle hide action as deletion with appropriate message', () async {
        // Arrange
        const moderatorId = 'moderator-id';
        const commentId = 'test-comment-id';
        const postId = 'test-post-id';
        const action = 'hide';
        const reason = 'Inappropriate language';

        container = ProviderContainer(
          overrides: [
            postRepositoryProvider.overrideWithValue(mockPostRepository),
            navigationServiceProvider.overrideWithValue(mockNavigationService),
            loggerProvider.overrideWithValue(mockLogger),
            authProvider.overrideWith((ref) => moderatorId),
          ],
        );

        // Mock successful hiding (implemented as deletion)
        when(mockPostRepository.deleteComment(commentId, postId))
            .thenAnswer((_) async => Result.success(null));

        // Act
        await container.read(commentProvider.notifier).moderateComment(commentId, postId, action, reason: reason);

        // Verify
        verify(mockPostRepository.deleteComment(commentId, postId)).called(1);
        verify(mockNavigationService.showSuccessSnackBar('Comment hidden by moderator: $reason')).called(1);
      });

      test('should handle unknown moderation action', () async {
        // Arrange
        const moderatorId = 'moderator-id';
        const commentId = 'test-comment-id';
        const postId = 'test-post-id';
        const unknownAction = 'unknown';

        container = ProviderContainer(
          overrides: [
            postRepositoryProvider.overrideWithValue(mockPostRepository),
            navigationServiceProvider.overrideWithValue(mockNavigationService),
            loggerProvider.overrideWithValue(mockLogger),
            authProvider.overrideWith((ref) => moderatorId),
          ],
        );

        // Act
        await container.read(commentProvider.notifier).moderateComment(commentId, postId, unknownAction);

        // Verify
        verifyNever(mockPostRepository.deleteComment(any, any));
        verify(mockNavigationService.showErrorSnackBar('Unknown moderation action')).called(1);
      });
    });

    testWidgets('should show different menu options based on user permissions', (WidgetTester tester) async {
      // Arrange
      const currentUserId = 'test-user-id';
      const commentOwnerId = 'comment-owner-id';
      
      final comment = Comment(
        id: 'test-comment-id',
        postId: 'test-post-id',
        userId: commentOwnerId,
        content: 'Test comment',
        timestamp: DateTime.now(),
      );

      // Test as regular user (not owner, not moderator)
      await tester.pumpWidget(
        UncontainerizedProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: CommentWidget(
                comment: comment,
                canModerate: false,
                currentUserRole: UserRole.student,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show report option for non-owners
      expect(find.byType(PopupMenuButton<String>), findsNothing); // No menu for non-owners without moderation rights
    });

    testWidgets('should show moderation dialog for moderators', (WidgetTester tester) async {
      // Arrange
      const commentId = 'test-comment-id';
      const postId = 'test-post-id';
      const commentContent = 'Test comment content';

      bool deleteCallbackCalled = false;
      String? moderationAction;
      String? moderationReason;

      // Build the moderation dialog
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => CommentModerationDialog(
                        commentId: commentId,
                        postId: postId,
                        commentContent: commentContent,
                        onDelete: () {
                          deleteCallbackCalled = true;
                        },
                        onModerate: (action, reason) {
                          moderationAction = action;
                          moderationReason = reason;
                        },
                      ),
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Act - tap to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.text('Moderate Comment'), findsOneWidget);
      expect(find.text('Comment:'), findsOneWidget);
      expect(find.text(commentContent), findsOneWidget);

      // Verify moderation options are available
      expect(find.text('Delete Comment'), findsOneWidget);
      expect(find.text('Hide Comment'), findsOneWidget);

      // Test selecting hide action
      await tester.tap(find.text('Hide Comment'));
      await tester.pumpAndSettle();

      // Add a reason
      await tester.enterText(find.byType(TextField), 'Inappropriate content');
      await tester.pumpAndSettle();

      // Confirm moderation
      await tester.tap(find.text('Hide Comment').last); // The button text
      await tester.pumpAndSettle();

      // Verify callback was called with correct parameters
      expect(moderationAction, equals('hide'));
      expect(moderationReason, equals('Inappropriate content'));
    });

    group('Comment Permissions', () {
      test('should correctly identify comment owner permissions', () {
        // Arrange
        const userId = 'test-user-id';
        final comment = Comment(
          id: 'test-comment-id',
          postId: 'test-post-id',
          userId: userId,
          content: 'Test comment',
          timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        );

        // Act & Verify
        expect(comment.canBeEditedBy(userId), isTrue);
        expect(comment.canBeDeletedBy(userId), isTrue);
      });

      test('should correctly identify moderator permissions', () {
        // Arrange
        const userId = 'test-user-id';
        const moderatorId = 'moderator-id';
        final comment = Comment(
          id: 'test-comment-id',
          postId: 'test-post-id',
          userId: userId,
          content: 'Test comment',
          timestamp: DateTime.now(),
        );

        // Act & Verify
        expect(comment.canBeEditedBy(moderatorId), isFalse); // Only owner can edit
        expect(comment.canBeDeletedBy(moderatorId, isCurrentUserModerator: true), isTrue); // Moderator can delete
      });

      test('should respect edit time limit', () {
        // Arrange
        const userId = 'test-user-id';
        final oldComment = Comment(
          id: 'test-comment-id',
          postId: 'test-post-id',
          userId: userId,
          content: 'Test comment',
          timestamp: DateTime.now().subtract(const Duration(hours: 25)), // Beyond 24h limit
        );

        // Act & Verify
        expect(oldComment.canBeEditedBy(userId), isFalse);
        expect(oldComment.canBeDeletedBy(userId), isTrue); // Can still delete
      });
    });
  });
}