import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/logger.dart';
import '../modules/comment.dart';
import '../repositories/post_repository.dart';
import '../services/navigation_service.dart';
import 'providers.dart';

class CommentsState {
  final Map<String, List<Comment>> commentsByPost;
  final Map<String, bool> loadingByPost;
  final Map<String, String?> errorByPost;

  const CommentsState({
    this.commentsByPost = const {},
    this.loadingByPost = const {},
    this.errorByPost = const {},
  });

  CommentsState copyWith({
    Map<String, List<Comment>>? commentsByPost,
    Map<String, bool>? loadingByPost,
    Map<String, String?>? errorByPost,
  }) {
    return CommentsState(
      commentsByPost: commentsByPost ?? this.commentsByPost,
      loadingByPost: loadingByPost ?? this.loadingByPost,
      errorByPost: errorByPost ?? this.errorByPost,
    );
  }

  List<Comment> getCommentsForPost(String postId) {
    return commentsByPost[postId] ?? [];
  }

  bool isLoadingForPost(String postId) {
    return loadingByPost[postId] ?? false;
  }

  String? getErrorForPost(String postId) {
    return errorByPost[postId];
  }

  bool hasErrorForPost(String postId) {
    return errorByPost[postId] != null;
  }
}

class CommentProvider extends StateNotifier<CommentsState> {
  final PostRepository _postRepository;
  final NavigationService _navigationService;
  final Logger _logger;

  CommentProvider({
    required PostRepository postRepository,
    required NavigationService navigationService,
    required Logger logger,
  }) : _postRepository = postRepository,
       _navigationService = navigationService,
       _logger = logger,
       super(const CommentsState());

  Future<void> loadComments(String postId) async {
    if (state.isLoadingForPost(postId)) return;

    _setLoadingForPost(postId, true);
    _clearErrorForPost(postId);

    try {
      _logger.info('Loading comments for post: $postId');
      
      final result = await _postRepository.getComments(postId);
      
      result.when(
        success: (comments) {
          _logger.info('Successfully loaded ${comments.length} comments for post: $postId');
          _setCommentsForPost(postId, comments);
          _setLoadingForPost(postId, false);
        },
        error: (message, exception) {
          _logger.error('Error loading comments for post $postId: $message', error: exception);
          _setErrorForPost(postId, message);
          _setLoadingForPost(postId, false);
        },
      );
    } catch (e) {
      _logger.error('Unexpected error loading comments for post $postId: $e');
      _setErrorForPost(postId, 'An unexpected error occurred');
      _setLoadingForPost(postId, false);
    }
  }

  Future<void> addComment(String postId, String userId, String content) async {
    if (content.trim().isEmpty) {
      _navigationService.showErrorSnackBar('Comment cannot be empty');
      return;
    }

    try {
      _logger.info('Adding comment to post: $postId by user: $userId');
      
      final comment = Comment(
        id: '', // Will be set by repository
        postId: postId,
        userId: userId,
        content: content.trim(),
        timestamp: DateTime.now(),
      );

      final result = await _postRepository.addComment(postId, comment);
      
      result.when(
        success: (createdComment) {
          _logger.info('Successfully added comment: ${createdComment.id}');
          _addCommentToPost(postId, createdComment);
          _navigationService.showSuccessSnackBar('Comment added successfully');
        },
        error: (message, exception) {
          _logger.error('Error adding comment: $message', error: exception);
          _navigationService.showErrorSnackBar('Failed to add comment: $message');
        },
      );
    } catch (e) {
      _logger.error('Unexpected error adding comment: $e');
      _navigationService.showErrorSnackBar('An unexpected error occurred');
    }
  }

  Future<void> deleteComment(String commentId, String postId, {String? reason}) async {
    try {
      _logger.info('Deleting comment: $commentId from post: $postId${reason != null ? ' (Reason: $reason)' : ''}');
      
      final result = await _postRepository.deleteComment(commentId, postId);
      
      result.when(
        success: (_) {
          _logger.info('Successfully deleted comment: $commentId');
          _removeCommentFromPost(postId, commentId);
          
          final message = reason != null 
              ? 'Comment removed: $reason'
              : 'Comment deleted successfully';
          _navigationService.showSuccessSnackBar(message);
        },
        error: (message, exception) {
          _logger.error('Error deleting comment: $message', error: exception);
          _navigationService.showErrorSnackBar('Failed to delete comment: $message');
        },
      );
    } catch (e) {
      _logger.error('Unexpected error deleting comment: $e');
      _navigationService.showErrorSnackBar('An unexpected error occurred');
    }
  }

  Future<void> moderateComment(String commentId, String postId, String action, {String? reason}) async {
    try {
      _logger.info('Moderating comment: $commentId with action: $action${reason != null ? ' (Reason: $reason)' : ''}');
      
      switch (action) {
        case 'delete':
          await deleteComment(commentId, postId, reason: reason);
          break;
        case 'hide':
          // For now, we'll delete hidden comments. In a full implementation,
          // you might want to add a 'hidden' field to the comment model
          await deleteComment(commentId, postId, reason: 'Comment hidden by moderator${reason != null ? ': $reason' : ''}');
          break;
        default:
          _logger.warning('Unknown moderation action: $action');
          _navigationService.showErrorSnackBar('Unknown moderation action');
      }
    } catch (e) {
      _logger.error('Unexpected error moderating comment: $e');
      _navigationService.showErrorSnackBar('An unexpected error occurred during moderation');
    }
  }

  Future<void> updateComment(Comment comment, String newContent) async {
    if (newContent.trim().isEmpty) {
      _navigationService.showErrorSnackBar('Comment cannot be empty');
      return;
    }

    try {
      _logger.info('Updating comment: ${comment.id}');
      
      final updatedComment = comment.edit(newContent.trim());
      final result = await _postRepository.updateComment(updatedComment);
      
      result.when(
        success: (savedComment) {
          _logger.info('Successfully updated comment: ${comment.id}');
          _updateCommentInPost(comment.postId, savedComment);
          _navigationService.showSuccessSnackBar('Comment updated successfully');
        },
        error: (message, exception) {
          _logger.error('Error updating comment: $message', error: exception);
          _navigationService.showErrorSnackBar('Failed to update comment: $message');
        },
      );
    } catch (e) {
      _logger.error('Unexpected error updating comment: $e');
      _navigationService.showErrorSnackBar('An unexpected error occurred');
    }
  }

  Stream<List<Comment>> getCommentsStream(String postId) {
    _logger.info('Creating comments stream for post: $postId');
    return _postRepository.getCommentsStream(postId);
  }

  void _setCommentsForPost(String postId, List<Comment> comments) {
    final updatedCommentsByPost = Map<String, List<Comment>>.from(state.commentsByPost);
    updatedCommentsByPost[postId] = comments;
    
    state = state.copyWith(commentsByPost: updatedCommentsByPost);
  }

  void _addCommentToPost(String postId, Comment comment) {
    final currentComments = state.getCommentsForPost(postId);
    final updatedComments = [...currentComments, comment];
    _setCommentsForPost(postId, updatedComments);
  }

  void _removeCommentFromPost(String postId, String commentId) {
    final currentComments = state.getCommentsForPost(postId);
    final updatedComments = currentComments.where((c) => c.id != commentId).toList();
    _setCommentsForPost(postId, updatedComments);
  }

  void _updateCommentInPost(String postId, Comment updatedComment) {
    final currentComments = state.getCommentsForPost(postId);
    final updatedComments = currentComments.map((c) {
      return c.id == updatedComment.id ? updatedComment : c;
    }).toList();
    _setCommentsForPost(postId, updatedComments);
  }

  void _setLoadingForPost(String postId, bool isLoading) {
    final updatedLoadingByPost = Map<String, bool>.from(state.loadingByPost);
    updatedLoadingByPost[postId] = isLoading;
    
    state = state.copyWith(loadingByPost: updatedLoadingByPost);
  }

  void _setErrorForPost(String postId, String error) {
    final updatedErrorByPost = Map<String, String?>.from(state.errorByPost);
    updatedErrorByPost[postId] = error;
    
    state = state.copyWith(errorByPost: updatedErrorByPost);
  }

  void _clearErrorForPost(String postId) {
    final updatedErrorByPost = Map<String, String?>.from(state.errorByPost);
    updatedErrorByPost.remove(postId);
    
    state = state.copyWith(errorByPost: updatedErrorByPost);
  }
}

final commentProvider = StateNotifierProvider<CommentProvider, CommentsState>((ref) {
  return CommentProvider(
    postRepository: ref.read(postRepositoryProvider),
    navigationService: ref.read(navigationServiceProvider),
    logger: ref.read(loggerProvider),
  );
});