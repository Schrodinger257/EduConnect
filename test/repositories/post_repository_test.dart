import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import '../../lib/repositories/firebase_post_repository.dart';
import '../../lib/core/result.dart';
import '../../lib/core/logger.dart';
import '../../lib/modules/post.dart';
import '../../lib/modules/comment.dart';

// Generate mocks
@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  Query,
  QuerySnapshot,
  DocumentSnapshot,
  Transaction,
  WriteBatch,
  Logger,
])
import 'post_repository_test.mocks.dart';

void main() {
  group('FirebasePostRepository', () {
    late FirebasePostRepository repository;
    late MockFirebaseFirestore mockFirestore;
    late MockLogger mockLogger;
    late MockCollectionReference<Map<String, dynamic>> mockCollection;
    late MockQuery<Map<String, dynamic>> mockQuery;
    late MockQuerySnapshot<Map<String, dynamic>> mockQuerySnapshot;
    late MockDocumentReference<Map<String, dynamic>> mockDocumentRef;
    late MockDocumentSnapshot<Map<String, dynamic>> mockDocumentSnapshot;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockLogger = MockLogger();
      mockCollection = MockCollectionReference<Map<String, dynamic>>();
      mockQuery = MockQuery<Map<String, dynamic>>();
      mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      mockDocumentRef = MockDocumentReference<Map<String, dynamic>>();
      mockDocumentSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();

      repository = FirebasePostRepository(
        firestore: mockFirestore,
        logger: mockLogger,
      );
    });

    group('getPosts', () {
      test('should return posts successfully', () async {
        // Arrange
        final testData = {
          'id': 'post1',
          'content': 'Test post content',
          'userid': 'user1',
          'timestamp': Timestamp.now(),
          'likes': ['user2'],
          'tags': ['test'],
          'commentIds': [],
        };

        when(mockFirestore.collection('posts')).thenReturn(mockCollection);
        when(mockCollection.orderBy('timestamp', descending: true))
            .thenReturn(mockQuery);
        when(mockQuery.limit(10)).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([mockDocumentSnapshot]);
        when(mockDocumentSnapshot.data()).thenReturn(testData);
        when(mockDocumentSnapshot.id).thenReturn('post1');

        // Act
        final result = await repository.getPosts();

        // Assert
        expect(result.isSuccess, true);
        expect(result.data?.length, 1);
        expect(result.data?.first.id, 'post1');
        expect(result.data?.first.content, 'Test post content');
        verify(mockLogger.info('Fetching posts with limit: 10')).called(1);
        verify(mockLogger.info('Successfully fetched 1 posts')).called(1);
      });

      test('should handle empty results', () async {
        // Arrange
        when(mockFirestore.collection('posts')).thenReturn(mockCollection);
        when(mockCollection.orderBy('timestamp', descending: true))
            .thenReturn(mockQuery);
        when(mockQuery.limit(10)).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([]);

        // Act
        final result = await repository.getPosts();

        // Assert
        expect(result.isSuccess, true);
        expect(result.data?.length, 0);
        verify(mockLogger.info('Successfully fetched 0 posts')).called(1);
      });

      test('should handle pagination with lastDocument', () async {
        // Arrange
        final lastDoc = MockDocumentSnapshot<Map<String, dynamic>>();
        
        when(mockFirestore.collection('posts')).thenReturn(mockCollection);
        when(mockCollection.orderBy('timestamp', descending: true))
            .thenReturn(mockQuery);
        when(mockQuery.limit(10)).thenReturn(mockQuery);
        when(mockQuery.startAfterDocument(lastDoc)).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([]);

        // Act
        final result = await repository.getPosts(lastDocument: lastDoc);

        // Assert
        expect(result.isSuccess, true);
        verify(mockQuery.startAfterDocument(lastDoc)).called(1);
      });

      test('should handle errors gracefully', () async {
        // Arrange
        when(mockFirestore.collection('posts')).thenReturn(mockCollection);
        when(mockCollection.orderBy('timestamp', descending: true))
            .thenReturn(mockQuery);
        when(mockQuery.limit(10)).thenReturn(mockQuery);
        when(mockQuery.get()).thenThrow(Exception('Network error'));

        // Act
        final result = await repository.getPosts();

        // Assert
        expect(result.isError, true);
        expect(result.errorMessage, contains('Failed to fetch posts'));
        verify(mockLogger.error(any)).called(1);
      });
    });

    group('createPost', () {
      test('should create post successfully', () async {
        // Arrange
        final post = Post(
          id: 'temp_id',
          content: 'New post content',
          userId: 'user1',
          timestamp: DateTime.now(),
        );

        final createdData = {
          'id': 'new_post_id',
          'content': 'New post content',
          'userid': 'user1',
          'timestamp': Timestamp.now(),
          'likes': [],
          'tags': [],
          'commentIds': [],
        };

        when(mockFirestore.collection('posts')).thenReturn(mockCollection);
        when(mockCollection.add(any)).thenAnswer((_) async => mockDocumentRef);
        when(mockDocumentRef.get()).thenAnswer((_) async => mockDocumentSnapshot);
        when(mockDocumentSnapshot.data()).thenReturn(createdData);
        when(mockDocumentSnapshot.id).thenReturn('new_post_id');

        // Act
        final result = await repository.createPost(post);

        // Assert
        expect(result.isSuccess, true);
        expect(result.data?.id, 'new_post_id');
        expect(result.data?.content, 'New post content');
        verify(mockLogger.info('Creating post for user: user1')).called(1);
        verify(mockLogger.info('Successfully created post with ID: new_post_id')).called(1);
      });

      test('should handle creation errors', () async {
        // Arrange
        final post = Post(
          id: 'temp_id',
          content: 'New post content',
          userId: 'user1',
          timestamp: DateTime.now(),
        );

        when(mockFirestore.collection('posts')).thenReturn(mockCollection);
        when(mockCollection.add(any)).thenThrow(Exception('Creation failed'));

        // Act
        final result = await repository.createPost(post);

        // Assert
        expect(result.isError, true);
        expect(result.errorMessage, contains('Failed to create post'));
        verify(mockLogger.error(any)).called(1);
      });
    });

    group('deletePost', () {
      test('should delete post and comments successfully', () async {
        // Arrange
        final mockBatch = MockWriteBatch();
        final mockCommentsCollection = MockCollectionReference<Map<String, dynamic>>();
        final mockCommentsQuery = MockQuery<Map<String, dynamic>>();
        final mockCommentsSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
        final mockCommentDoc = MockDocumentSnapshot<Map<String, dynamic>>();

        when(mockFirestore.collection('comments')).thenReturn(mockCommentsCollection);
        when(mockCommentsCollection.where('postId', isEqualTo: 'post1'))
            .thenReturn(mockCommentsQuery);
        when(mockCommentsQuery.get()).thenAnswer((_) async => mockCommentsSnapshot);
        when(mockCommentsSnapshot.docs).thenReturn([mockCommentDoc]);
        when(mockCommentDoc.reference).thenReturn(mockDocumentRef);
        
        when(mockFirestore.batch()).thenReturn(mockBatch);
        when(mockFirestore.collection('posts')).thenReturn(mockCollection);
        when(mockCollection.doc('post1')).thenReturn(mockDocumentRef);
        when(mockBatch.commit()).thenAnswer((_) async => []);

        // Act
        final result = await repository.deletePost('post1');

        // Assert
        expect(result.isSuccess, true);
        verify(mockBatch.delete(mockDocumentRef)).called(2); // One for comment, one for post
        verify(mockBatch.commit()).called(1);
        verify(mockLogger.info('Successfully deleted post: post1')).called(1);
      });

      test('should handle deletion errors', () async {
        // Arrange
        when(mockFirestore.collection('comments')).thenThrow(Exception('Delete failed'));

        // Act
        final result = await repository.deletePost('post1');

        // Assert
        expect(result.isError, true);
        expect(result.errorMessage, contains('Failed to delete post'));
        verify(mockLogger.error(any)).called(1);
      });
    });

    group('toggleLike', () {
      test('should add like successfully', () async {
        // Arrange
        final mockTransaction = MockTransaction();
        final mockPostDoc = MockDocumentSnapshot<Map<String, dynamic>>();
        final mockUserDoc = MockDocumentSnapshot<Map<String, dynamic>>();
        final mockUserRef = MockDocumentReference<Map<String, dynamic>>();

        when(mockFirestore.collection('posts')).thenReturn(mockCollection);
        when(mockCollection.doc('post1')).thenReturn(mockDocumentRef);
        when(mockFirestore.collection('users')).thenReturn(mockCollection);
        when(mockCollection.doc('user1')).thenReturn(mockUserRef);

        when(mockFirestore.runTransaction(any)).thenAnswer((invocation) async {
          final callback = invocation.positionalArguments[0] as Function;
          return await callback(mockTransaction);
        });

        when(mockTransaction.get(mockDocumentRef)).thenAnswer((_) async => mockPostDoc);
        when(mockTransaction.get(mockUserRef)).thenAnswer((_) async => mockUserDoc);
        when(mockPostDoc.exists).thenReturn(true);
        when(mockUserDoc.exists).thenReturn(true);
        when(mockPostDoc.data()).thenReturn({'likes': []});
        when(mockUserDoc.data()).thenReturn({'likedPosts': []});

        // Act
        final result = await repository.toggleLike('post1', 'user1');

        // Assert
        expect(result.isSuccess, true);
        verify(mockTransaction.update(mockDocumentRef, {'likes': ['user1']})).called(1);
        verify(mockTransaction.update(mockUserRef, {'likedPosts': ['post1']})).called(1);
        verify(mockLogger.info('Successfully toggled like for post: post1')).called(1);
      });

      test('should remove like successfully', () async {
        // Arrange
        final mockTransaction = MockTransaction();
        final mockPostDoc = MockDocumentSnapshot<Map<String, dynamic>>();
        final mockUserDoc = MockDocumentSnapshot<Map<String, dynamic>>();
        final mockUserRef = MockDocumentReference<Map<String, dynamic>>();

        when(mockFirestore.collection('posts')).thenReturn(mockCollection);
        when(mockCollection.doc('post1')).thenReturn(mockDocumentRef);
        when(mockFirestore.collection('users')).thenReturn(mockCollection);
        when(mockCollection.doc('user1')).thenReturn(mockUserRef);

        when(mockFirestore.runTransaction(any)).thenAnswer((invocation) async {
          final callback = invocation.positionalArguments[0] as Function;
          return await callback(mockTransaction);
        });

        when(mockTransaction.get(mockDocumentRef)).thenAnswer((_) async => mockPostDoc);
        when(mockTransaction.get(mockUserRef)).thenAnswer((_) async => mockUserDoc);
        when(mockPostDoc.exists).thenReturn(true);
        when(mockUserDoc.exists).thenReturn(true);
        when(mockPostDoc.data()).thenReturn({'likes': ['user1']});
        when(mockUserDoc.data()).thenReturn({'likedPosts': ['post1']});

        // Act
        final result = await repository.toggleLike('post1', 'user1');

        // Assert
        expect(result.isSuccess, true);
        verify(mockTransaction.update(mockDocumentRef, {'likes': <String>[]})).called(1);
        verify(mockTransaction.update(mockUserRef, {'likedPosts': <String>[]})).called(1);
      });

      test('should handle toggle like errors', () async {
        // Arrange
        when(mockFirestore.collection('posts')).thenReturn(mockCollection);
        when(mockCollection.doc('post1')).thenReturn(mockDocumentRef);
        when(mockFirestore.runTransaction(any)).thenThrow(Exception('Transaction failed'));

        // Act
        final result = await repository.toggleLike('post1', 'user1');

        // Assert
        expect(result.isError, true);
        expect(result.errorMessage, contains('Failed to toggle like'));
        verify(mockLogger.error(any)).called(1);
      });
    });

    group('getComments', () {
      test('should return comments successfully', () async {
        // Arrange
        final testCommentData = {
          'id': 'comment1',
          'postId': 'post1',
          'userId': 'user1',
          'content': 'Test comment',
          'timestamp': Timestamp.now(),
          'isEdited': false,
        };

        when(mockFirestore.collection('comments')).thenReturn(mockCollection);
        when(mockCollection.where('postId', isEqualTo: 'post1'))
            .thenReturn(mockQuery);
        when(mockQuery.orderBy('timestamp', descending: false))
            .thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([mockDocumentSnapshot]);
        when(mockDocumentSnapshot.data()).thenReturn(testCommentData);
        when(mockDocumentSnapshot.id).thenReturn('comment1');

        // Act
        final result = await repository.getComments('post1');

        // Assert
        expect(result.isSuccess, true);
        expect(result.data?.length, 1);
        expect(result.data?.first.id, 'comment1');
        expect(result.data?.first.content, 'Test comment');
        verify(mockLogger.info('Successfully fetched 1 comments for post: post1')).called(1);
      });

      test('should handle comment fetch errors', () async {
        // Arrange
        when(mockFirestore.collection('comments')).thenReturn(mockCollection);
        when(mockCollection.where('postId', isEqualTo: 'post1'))
            .thenReturn(mockQuery);
        when(mockQuery.orderBy('timestamp', descending: false))
            .thenReturn(mockQuery);
        when(mockQuery.get()).thenThrow(Exception('Fetch failed'));

        // Act
        final result = await repository.getComments('post1');

        // Assert
        expect(result.isError, true);
        expect(result.errorMessage, contains('Failed to fetch comments'));
        verify(mockLogger.error(any)).called(1);
      });
    });

    group('addComment', () {
      test('should add comment successfully', () async {
        // Arrange
        final comment = Comment(
          id: 'temp_id',
          postId: 'post1',
          userId: 'user1',
          content: 'New comment',
          timestamp: DateTime.now(),
        );

        final createdCommentData = {
          'id': 'new_comment_id',
          'postId': 'post1',
          'userId': 'user1',
          'content': 'New comment',
          'timestamp': Timestamp.now(),
          'isEdited': false,
        };

        when(mockFirestore.collection('comments')).thenReturn(mockCollection);
        when(mockCollection.add(any)).thenAnswer((_) async => mockDocumentRef);
        when(mockDocumentRef.get()).thenAnswer((_) async => mockDocumentSnapshot);
        when(mockDocumentRef.id).thenReturn('new_comment_id');
        when(mockDocumentSnapshot.data()).thenReturn(createdCommentData);
        when(mockDocumentSnapshot.id).thenReturn('new_comment_id');

        // Mock post update
        final mockPostCollection = MockCollectionReference<Map<String, dynamic>>();
        final mockPostDocRef = MockDocumentReference<Map<String, dynamic>>();
        when(mockFirestore.collection('posts')).thenReturn(mockPostCollection);
        when(mockPostCollection.doc('post1')).thenReturn(mockPostDocRef);
        when(mockPostDocRef.update(any)).thenAnswer((_) async => {});

        // Act
        final result = await repository.addComment('post1', comment);

        // Assert
        expect(result.isSuccess, true);
        expect(result.data?.id, 'new_comment_id');
        expect(result.data?.content, 'New comment');
        verify(mockLogger.info('Successfully added comment with ID: new_comment_id')).called(1);
      });

      test('should handle add comment errors', () async {
        // Arrange
        final comment = Comment(
          id: 'temp_id',
          postId: 'post1',
          userId: 'user1',
          content: 'New comment',
          timestamp: DateTime.now(),
        );

        when(mockFirestore.collection('comments')).thenReturn(mockCollection);
        when(mockCollection.add(any)).thenThrow(Exception('Add failed'));

        // Act
        final result = await repository.addComment('post1', comment);

        // Assert
        expect(result.isError, true);
        expect(result.errorMessage, contains('Failed to add comment'));
        verify(mockLogger.error(any)).called(1);
      });
    });

    group('searchPosts', () {
      test('should search posts successfully', () async {
        // Arrange
        final testData = {
          'id': 'post1',
          'content': 'Test post with search term',
          'userid': 'user1',
          'timestamp': Timestamp.now(),
          'likes': [],
          'tags': ['search'],
          'commentIds': [],
        };

        when(mockFirestore.collection('posts')).thenReturn(mockCollection);
        when(mockCollection.where('tags', arrayContainsAny: ['search']))
            .thenReturn(mockQuery);
        when(mockQuery.orderBy('timestamp', descending: true))
            .thenReturn(mockQuery);
        when(mockQuery.limit(50)).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([mockDocumentSnapshot]);
        when(mockDocumentSnapshot.data()).thenReturn(testData);
        when(mockDocumentSnapshot.id).thenReturn('post1');

        // Act
        final result = await repository.searchPosts('search');

        // Assert
        expect(result.isSuccess, true);
        expect(result.data?.length, 1);
        verify(mockLogger.info('Successfully found 1 posts matching query: search')).called(1);
      });

      test('should handle search errors', () async {
        // Arrange
        when(mockFirestore.collection('posts')).thenReturn(mockCollection);
        when(mockCollection.where('tags', arrayContainsAny: ['search']))
            .thenThrow(Exception('Search failed'));

        // Act
        final result = await repository.searchPosts('search');

        // Assert
        expect(result.isError, true);
        expect(result.errorMessage, contains('Failed to search posts'));
        verify(mockLogger.error(any)).called(1);
      });
    });
  });
}