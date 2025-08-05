import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/result.dart';
import '../modules/post.dart';
import '../modules/comment.dart';

/// Abstract repository interface for post-related operations
abstract class PostRepository {
  /// Retrieves a paginated list of posts
  Future<Result<List<Post>>> getPosts({
    int limit = 10,
    DocumentSnapshot? lastDocument,
  });

  /// Retrieves posts for a specific user
  Future<Result<List<Post>>> getUserPosts({
    required String userId,
    int limit = 10,
    DocumentSnapshot? lastDocument,
  });

  /// Creates a new post
  Future<Result<Post>> createPost(Post post);

  /// Deletes a post by ID
  Future<Result<void>> deletePost(String postId);

  /// Toggles like status for a post
  Future<Result<void>> toggleLike(String postId, String userId);

  /// Retrieves comments for a specific post
  Future<Result<List<Comment>>> getComments(String postId);

  /// Adds a comment to a post
  Future<Result<Comment>> addComment(String postId, Comment comment);

  /// Deletes a comment
  Future<Result<void>> deleteComment(String commentId, String postId);

  /// Updates a comment
  Future<Result<Comment>> updateComment(Comment comment);

  /// Gets a stream of posts for real-time updates
  Stream<List<Post>> getPostsStream({int limit = 10});

  /// Gets a stream of comments for a post
  Stream<List<Comment>> getCommentsStream(String postId);

  /// Searches posts by content and tags
  Future<Result<List<Post>>> searchPosts(String query);

  /// Gets bookmarked posts for a user
  Stream<List<Post>> getBookmarkedPosts(String userId);
}