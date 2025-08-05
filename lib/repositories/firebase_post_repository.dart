import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/result.dart';
import '../core/logger.dart';
import '../modules/post.dart';
import '../modules/comment.dart';
import 'post_repository.dart';

/// Firebase implementation of PostRepository
class FirebasePostRepository implements PostRepository {
  final FirebaseFirestore _firestore;
  final Logger _logger;

  FirebasePostRepository({
    FirebaseFirestore? firestore,
    Logger? logger,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _logger = logger ?? Logger();

  /// Helper method to convert Firestore document data to Post model format
  Map<String, dynamic> _convertFirestoreDataToPost(Map<String, dynamic> data, String docId) {
    data['id'] = docId;
    
    // Convert Firestore Timestamp to DateTime
    if (data['timestamp'] is Timestamp) {
      data['timestamp'] = (data['timestamp'] as Timestamp).toDate().toIso8601String();
    }
    
    // Convert Firestore field names to Post model format
    data['userId'] = data['userid'] ?? '';
    
    // Handle image URL field name variations - check all possible field names
    if (data['imageUrl'] == null) {
      if (data['imageurl'] != null) {
        data['imageUrl'] = data['imageurl'];
      } else if (data['image_url'] != null) {
        data['imageUrl'] = data['image_url'];
      } else if (data['imageURL'] != null) {
        data['imageUrl'] = data['imageURL'];
      }
    }
    
    // Debug logging
    _logger.info('Post $docId imageUrl: ${data['imageUrl']}');
    _logger.info('Post $docId all fields: ${data.keys.toList()}');
    
    // Ensure required fields exist with defaults
    data['likeCount'] = data['likes']?.length ?? 0;
    data['likedBy'] = List<String>.from(data['likes'] ?? []);
    data['commentCount'] = data['commentIds']?.length ?? 0;
    data['commentIds'] = List<String>.from(data['commentIds'] ?? []);
    data['tags'] = List<String>.from(data['tags'] ?? []);
    
    return data;
  }

  @override
  Future<Result<List<Post>>> getPosts({
    int limit = 10,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      _logger.info('Fetching posts with limit: $limit');
      
      Query query = _firestore
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      final posts = <Post>[];

      for (final doc in snapshot.docs) {
        try {
          final data = _convertFirestoreDataToPost(doc.data() as Map<String, dynamic>, doc.id);
          final post = Post.fromJson(data);
          posts.add(post);
        } catch (e) {
          _logger.error('Error parsing post ${doc.id}: $e');
          // Continue processing other posts instead of failing completely
        }
      }

      _logger.info('Successfully fetched ${posts.length} posts');
      return Result.success(posts);
    } catch (e) {
      _logger.error('Error fetching posts: $e');
      return Result.error('Failed to fetch posts: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<List<Post>>> getUserPosts({
    required String userId,
    int limit = 10,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      _logger.info('Fetching posts for user: $userId with limit: $limit');
      
      Query query = _firestore
          .collection('posts')
          .where('userid', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      final posts = <Post>[];

      for (final doc in snapshot.docs) {
        try {
          final data = _convertFirestoreDataToPost(doc.data() as Map<String, dynamic>, doc.id);
          final post = Post.fromJson(data);
          posts.add(post);
        } catch (e) {
          _logger.error('Error parsing user post ${doc.id}: $e');
        }
      }

      _logger.info('Successfully fetched ${posts.length} posts for user $userId');
      return Result.success(posts);
    } catch (e) {
      _logger.error('Error fetching user posts: $e');
      return Result.error('Failed to fetch user posts: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<Post>> createPost(Post post) async {
    try {
      _logger.info('Creating post for user: ${post.userId}');
      
      final postData = post.toJson();
      // Remove the ID as Firestore will generate it
      postData.remove('id');
      
      // Convert DateTime to Firestore Timestamp
      postData['timestamp'] = FieldValue.serverTimestamp();
      
      // Convert Post model fields to Firestore format
      postData['userid'] = postData['userId'];
      postData.remove('userId');
      postData['likes'] = postData['likedBy'];
      postData.remove('likedBy');
      postData.remove('likeCount');
      postData.remove('commentCount');
      
      final docRef = await _firestore.collection('posts').add(postData);
      
      // Get the created document to return the complete post with ID
      final createdDoc = await docRef.get();
      final createdData = createdDoc.data() as Map<String, dynamic>;
      createdData['id'] = createdDoc.id;
      
      // Convert back to Post format
      if (createdData['timestamp'] is Timestamp) {
        createdData['timestamp'] = (createdData['timestamp'] as Timestamp).toDate().toIso8601String();
      }
      createdData['userId'] = createdData['userid'];
      createdData.remove('userid');
      createdData['likeCount'] = createdData['likes']?.length ?? 0;
      createdData['likedBy'] = List<String>.from(createdData['likes'] ?? []);
      createdData['commentCount'] = createdData['commentIds']?.length ?? 0;
      createdData['commentIds'] = List<String>.from(createdData['commentIds'] ?? []);
      
      final createdPost = Post.fromJson(createdData);
      
      _logger.info('Successfully created post with ID: ${createdPost.id}');
      return Result.success(createdPost);
    } catch (e) {
      _logger.error('Error creating post: $e');
      return Result.error('Failed to create post: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> deletePost(String postId) async {
    try {
      _logger.info('Deleting post: $postId');
      
      // Delete all comments for this post first
      final commentsSnapshot = await _firestore
          .collection('comments')
          .where('postId', isEqualTo: postId)
          .get();
      
      final batch = _firestore.batch();
      
      // Add comment deletions to batch
      for (final doc in commentsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Add post deletion to batch
      batch.delete(_firestore.collection('posts').doc(postId));
      
      await batch.commit();
      
      _logger.info('Successfully deleted post: $postId');
      return Result.success(null);
    } catch (e) {
      _logger.error('Error deleting post: $e');
      return Result.error('Failed to delete post: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> toggleLike(String postId, String userId) async {
    try {
      _logger.info('Toggling like for post: $postId by user: $userId');
      
      final postRef = _firestore.collection('posts').doc(postId);
      final userRef = _firestore.collection('users').doc(userId);
      
      await _firestore.runTransaction((transaction) async {
        final postDoc = await transaction.get(postRef);
        final userDoc = await transaction.get(userRef);
        
        if (!postDoc.exists) {
          throw Exception('Post not found');
        }
        
        if (!userDoc.exists) {
          throw Exception('User not found');
        }
        
        final postData = postDoc.data() as Map<String, dynamic>;
        final userData = userDoc.data() as Map<String, dynamic>;
        
        final likes = List<String>.from(postData['likes'] ?? []);
        final likedPosts = List<String>.from(userData['likedPosts'] ?? []);
        
        if (likes.contains(userId)) {
          // Remove like
          likes.remove(userId);
          likedPosts.remove(postId);
        } else {
          // Add like
          likes.add(userId);
          likedPosts.add(postId);
        }
        
        transaction.update(postRef, {'likes': likes});
        transaction.update(userRef, {'likedPosts': likedPosts});
      });
      
      _logger.info('Successfully toggled like for post: $postId');
      return Result.success(null);
    } catch (e) {
      _logger.error('Error toggling like: $e');
      return Result.error('Failed to toggle like: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<List<Comment>>> getComments(String postId) async {
    try {
      _logger.info('Fetching comments for post: $postId');
      
      final snapshot = await _firestore
          .collection('comments')
          .where('postId', isEqualTo: postId)
          .orderBy('timestamp', descending: false)
          .get();
      
      final comments = <Comment>[];
      
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          
          // Convert Firestore Timestamp to DateTime
          if (data['timestamp'] is Timestamp) {
            data['timestamp'] = (data['timestamp'] as Timestamp).toDate().toIso8601String();
          }
          if (data['editedAt'] is Timestamp) {
            data['editedAt'] = (data['editedAt'] as Timestamp).toDate().toIso8601String();
          }
          
          final comment = Comment.fromJson(data);
          comments.add(comment);
        } catch (e) {
          _logger.error('Error parsing comment ${doc.id}: $e');
        }
      }
      
      _logger.info('Successfully fetched ${comments.length} comments for post: $postId');
      return Result.success(comments);
    } catch (e) {
      _logger.error('Error fetching comments: $e');
      return Result.error('Failed to fetch comments: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<Comment>> addComment(String postId, Comment comment) async {
    try {
      _logger.info('Adding comment to post: $postId by user: ${comment.userId}');
      
      final commentData = comment.toJson();
      commentData.remove('id');
      commentData['timestamp'] = FieldValue.serverTimestamp();
      
      final docRef = await _firestore.collection('comments').add(commentData);
      
      // Update post comment count
      await _firestore.collection('posts').doc(postId).update({
        'commentIds': FieldValue.arrayUnion([docRef.id]),
      });
      
      // Get the created comment
      final createdDoc = await docRef.get();
      final createdData = createdDoc.data() as Map<String, dynamic>;
      createdData['id'] = createdDoc.id;
      
      if (createdData['timestamp'] is Timestamp) {
        createdData['timestamp'] = (createdData['timestamp'] as Timestamp).toDate().toIso8601String();
      }
      
      final createdComment = Comment.fromJson(createdData);
      
      _logger.info('Successfully added comment with ID: ${createdComment.id}');
      return Result.success(createdComment);
    } catch (e) {
      _logger.error('Error adding comment: $e');
      return Result.error('Failed to add comment: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteComment(String commentId, String postId) async {
    try {
      _logger.info('Deleting comment: $commentId from post: $postId');
      
      await _firestore.runTransaction((transaction) async {
        final commentRef = _firestore.collection('comments').doc(commentId);
        final postRef = _firestore.collection('posts').doc(postId);
        
        transaction.delete(commentRef);
        transaction.update(postRef, {
          'commentIds': FieldValue.arrayRemove([commentId]),
        });
      });
      
      _logger.info('Successfully deleted comment: $commentId');
      return Result.success(null);
    } catch (e) {
      _logger.error('Error deleting comment: $e');
      return Result.error('Failed to delete comment: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<Comment>> updateComment(Comment comment) async {
    try {
      _logger.info('Updating comment: ${comment.id}');
      
      final commentData = comment.toJson();
      commentData.remove('id');
      
      if (commentData['editedAt'] != null) {
        commentData['editedAt'] = FieldValue.serverTimestamp();
      }
      
      await _firestore.collection('comments').doc(comment.id).update(commentData);
      
      // Get the updated comment
      final updatedDoc = await _firestore.collection('comments').doc(comment.id).get();
      final updatedData = updatedDoc.data() as Map<String, dynamic>;
      updatedData['id'] = updatedDoc.id;
      
      if (updatedData['timestamp'] is Timestamp) {
        updatedData['timestamp'] = (updatedData['timestamp'] as Timestamp).toDate().toIso8601String();
      }
      if (updatedData['editedAt'] is Timestamp) {
        updatedData['editedAt'] = (updatedData['editedAt'] as Timestamp).toDate().toIso8601String();
      }
      
      final updatedComment = Comment.fromJson(updatedData);
      
      _logger.info('Successfully updated comment: ${comment.id}');
      return Result.success(updatedComment);
    } catch (e) {
      _logger.error('Error updating comment: $e');
      return Result.error('Failed to update comment: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Stream<List<Post>> getPostsStream({int limit = 10}) {
    _logger.info('Creating posts stream with limit: $limit');
    
    return _firestore
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final posts = <Post>[];
      
      for (final doc in snapshot.docs) {
        try {
          final data = _convertFirestoreDataToPost(doc.data(), doc.id);
          final post = Post.fromJson(data);
          posts.add(post);
        } catch (e) {
          _logger.error('Error parsing post ${doc.id} in stream: $e');
        }
      }
      
      return posts;
    });
  }

  @override
  Stream<List<Comment>> getCommentsStream(String postId) {
    _logger.info('Creating comments stream for post: $postId');
    
    return _firestore
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      final comments = <Comment>[];
      
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          
          // Convert Firestore Timestamp to DateTime
          if (data['timestamp'] is Timestamp) {
            data['timestamp'] = (data['timestamp'] as Timestamp).toDate().toIso8601String();
          }
          if (data['editedAt'] is Timestamp) {
            data['editedAt'] = (data['editedAt'] as Timestamp).toDate().toIso8601String();
          }
          
          final comment = Comment.fromJson(data);
          comments.add(comment);
        } catch (e) {
          _logger.error('Error parsing comment ${doc.id} in stream: $e');
        }
      }
      
      return comments;
    });
  }

  @override
  Future<Result<List<Post>>> searchPosts(String query) async {
    try {
      _logger.info('Searching posts with query: $query');
      
      // Note: Firestore doesn't support full-text search natively
      // This is a basic implementation that searches in tags
      // For production, consider using Algolia or similar service
      
      final snapshot = await _firestore
          .collection('posts')
          .where('tags', arrayContainsAny: [query.toLowerCase()])
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();
      
      final posts = <Post>[];
      
      for (final doc in snapshot.docs) {
        try {
          final data = _convertFirestoreDataToPost(doc.data(), doc.id);
          final post = Post.fromJson(data);
          
          // Additional client-side filtering for content search
          if (post.matchesSearch(query)) {
            posts.add(post);
          }
        } catch (e) {
          _logger.error('Error parsing search result ${doc.id}: $e');
        }
      }
      
      _logger.info('Successfully found ${posts.length} posts matching query: $query');
      return Result.success(posts);
    } catch (e) {
      _logger.error('Error searching posts: $e');
      return Result.error('Failed to search posts: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Stream<List<Post>> getBookmarkedPosts(String userId) {
    _logger.info('Creating bookmarked posts stream for user: $userId');
    
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .asyncMap((userDoc) async {
      if (!userDoc.exists || userDoc.data() == null) {
        return <Post>[];
      }

      final bookmarkIds = List<String>.from(userDoc.data()!['Bookmarks'] ?? []);
      
      if (bookmarkIds.isEmpty) {
        return <Post>[];
      }

      try {
        final postsSnapshot = await _firestore
            .collection('posts')
            .where(FieldPath.documentId, whereIn: bookmarkIds)
            .get();

        final posts = <Post>[];
        
        for (final doc in postsSnapshot.docs) {
          try {
            final data = _convertFirestoreDataToPost(doc.data(), doc.id);
            final post = Post.fromJson(data);
            posts.add(post);
          } catch (e) {
            _logger.error('Error parsing bookmarked post ${doc.id}: $e');
          }
        }

        // Sort by timestamp descending
        posts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        
        return posts;
      } catch (e) {
        _logger.error('Error fetching bookmarked posts: $e');
        return <Post>[];
      }
    });
  }
}