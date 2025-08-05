import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import '../../lib/repositories/firebase_user_repository.dart';
import '../../lib/core/result.dart';
import '../../lib/core/logger.dart';
import '../../lib/modules/user.dart';

// Generate mocks
@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
  QuerySnapshot,
  Query,
  Transaction,
  SupabaseClient,
  SupabaseStorageClient,
  StorageFileApi,
  Logger,
  File,
])
import 'user_repository_test.mocks.dart';

void main() {
  group('FirebaseUserRepository', () {
    late FirebaseUserRepository repository;
    late MockFirebaseFirestore mockFirestore;
    late MockSupabaseClient mockSupabase;
    late MockLogger mockLogger;
    late MockCollectionReference<Map<String, dynamic>> mockCollection;
    late MockDocumentReference<Map<String, dynamic>> mockDocumentRef;
    late MockDocumentSnapshot<Map<String, dynamic>> mockDocumentSnapshot;
    late MockQuerySnapshot<Map<String, dynamic>> mockQuerySnapshot;
    late MockQuery<Map<String, dynamic>> mockQuery;
    late MockSupabaseStorageClient mockStorage;
    late MockStorageFileApi mockStorageFileApi;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockSupabase = MockSupabaseClient();
      mockLogger = MockLogger();
      mockCollection = MockCollectionReference<Map<String, dynamic>>();
      mockDocumentRef = MockDocumentReference<Map<String, dynamic>>();
      mockDocumentSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
      mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      mockQuery = MockQuery<Map<String, dynamic>>();
      mockStorage = MockSupabaseStorageClient();
      mockStorageFileApi = MockStorageFileApi();

      repository = FirebaseUserRepository(
        firestore: mockFirestore,
        supabase: mockSupabase,
        logger: mockLogger,
      );
    });

    group('getUserById', () {
      test('should return user successfully', () async {
        // Arrange
        final testUserData = {
          'id': 'user1',
          'email': 'test@example.com',
          'name': 'Test User',
          'roleCode': 'student',
          'profileImage': 'https://example.com/image.jpg',
          'department': 'Computer Science',
          'grade': '10th',
          'createdAt': Timestamp.now(),
          'Bookmarks': ['post1', 'post2'],
          'likedPosts': ['post3'],
          'enrolledCourses': ['course1'],
        };

        when(mockFirestore.collection('users')).thenReturn(mockCollection);
        when(mockCollection.doc('user1')).thenReturn(mockDocumentRef);
        when(mockDocumentRef.get()).thenAnswer((_) async => mockDocumentSnapshot);
        when(mockDocumentSnapshot.exists).thenReturn(true);
        when(mockDocumentSnapshot.data()).thenReturn(testUserData);
        when(mockDocumentSnapshot.id).thenReturn('user1');

        // Act
        final result = await repository.getUserById('user1');

        // Assert
        expect(result.isSuccess, true);
        expect(result.data?.id, 'user1');
        expect(result.data?.email, 'test@example.com');
        expect(result.data?.name, 'Test User');
        expect(result.data?.role, UserRole.student);
        verify(mockLogger.info('Successfully fetched user: user1')).called(1);
      });

      test('should return error when user not found', () async {
        // Arrange
        when(mockFirestore.collection('users')).thenReturn(mockCollection);
        when(mockCollection.doc('user1')).thenReturn(mockDocumentRef);
        when(mockDocumentRef.get()).thenAnswer((_) async => mockDocumentSnapshot);
        when(mockDocumentSnapshot.exists).thenReturn(false);

        // Act
        final result = await repository.getUserById('user1');

        // Assert
        expect(result.isError, true);
        expect(result.errorMessage, 'User not found');
        verify(mockLogger.warning('User not found: user1')).called(1);
      });

      test('should handle errors gracefully', () async {
        // Arrange
        when(mockFirestore.collection('users')).thenReturn(mockCollection);
        when(mockCollection.doc('user1')).thenReturn(mockDocumentRef);
        when(mockDocumentRef.get()).thenThrow(Exception('Network error'));

        // Act
        final result = await repository.getUserById('user1');

        // Assert
        expect(result.isError, true);
        expect(result.errorMessage, contains('Failed to fetch user'));
        verify(mockLogger.error(any)).called(1);
      });
    });

    group('updateUser', () {
      test('should update user successfully', () async {
        // Arrange
        final user = User(
          id: 'user1',
          email: 'updated@example.com',
          name: 'Updated User',
          role: UserRole.instructor,
          createdAt: DateTime.now(),
        );

        final updatedUserData = {
          'id': 'user1',
          'email': 'updated@example.com',
          'name': 'Updated User',
          'roleCode': 'instructor',
          'createdAt': Timestamp.now(),
          'Bookmarks': <String>[],
          'likedPosts': <String>[],
          'enrolledCourses': <String>[],
        };

        when(mockFirestore.collection('users')).thenReturn(mockCollection);
        when(mockCollection.doc('user1')).thenReturn(mockDocumentRef);
        when(mockDocumentRef.update(any)).thenAnswer((_) async => {});
        when(mockDocumentRef.get()).thenAnswer((_) async => mockDocumentSnapshot);
        when(mockDocumentSnapshot.exists).thenReturn(true);
        when(mockDocumentSnapshot.data()).thenReturn(updatedUserData);
        when(mockDocumentSnapshot.id).thenReturn('user1');

        // Act
        final result = await repository.updateUser(user);

        // Assert
        expect(result.isSuccess, true);
        expect(result.data?.email, 'updated@example.com');
        verify(mockDocumentRef.update(any)).called(1);
        verify(mockLogger.info('Successfully updated user: user1')).called(1);
      });

      test('should handle update errors', () async {
        // Arrange
        final user = User(
          id: 'user1',
          email: 'test@example.com',
          name: 'Test User',
          role: UserRole.student,
          createdAt: DateTime.now(),
        );

        when(mockFirestore.collection('users')).thenReturn(mockCollection);
        when(mockCollection.doc('user1')).thenReturn(mockDocumentRef);
        when(mockDocumentRef.update(any)).thenThrow(Exception('Update failed'));

        // Act
        final result = await repository.updateUser(user);

        // Assert
        expect(result.isError, true);
        expect(result.errorMessage, contains('Failed to update user'));
        verify(mockLogger.error(any)).called(1);
      });
    });

    group('uploadProfileImage', () {
      test('should upload image successfully', () async {
        // Arrange
        final mockFile = MockFile();
        const userId = 'user1';
        const publicUrl = 'https://supabase.com/storage/profiles/user1.jpg';

        when(mockFile.path).thenReturn('/path/to/image.jpg');
        when(mockFile.length()).thenAnswer((_) async => 1024 * 1024); // 1MB
        when(mockSupabase.storage).thenReturn(mockStorage);
        when(mockStorage.from('profiles')).thenReturn(mockStorageFileApi);
        when(mockStorageFileApi.remove(any)).thenAnswer((_) async => []);
        when(mockStorageFileApi.upload(any, any, fileOptions: anyNamed('fileOptions')))
            .thenAnswer((_) async => '');
        when(mockStorageFileApi.getPublicUrl(any)).thenReturn(publicUrl);

        when(mockFirestore.collection('users')).thenReturn(mockCollection);
        when(mockCollection.doc(userId)).thenReturn(mockDocumentRef);
        when(mockDocumentRef.update(any)).thenAnswer((_) async => {});

        // Act
        final result = await repository.uploadProfileImage(mockFile, userId);

        // Assert
        expect(result.isSuccess, true);
        expect(result.data, publicUrl);
        verify(mockStorageFileApi.upload('user1.jpg', mockFile, fileOptions: anyNamed('fileOptions'))).called(1);
        verify(mockDocumentRef.update({'profileImage': publicUrl})).called(1);
        verify(mockLogger.info('Successfully uploaded profile image for user: user1')).called(1);
      });

      test('should reject files that are too large', () async {
        // Arrange
        final mockFile = MockFile();
        const userId = 'user1';

        when(mockFile.length()).thenAnswer((_) async => 6 * 1024 * 1024); // 6MB

        // Act
        final result = await repository.uploadProfileImage(mockFile, userId);

        // Assert
        expect(result.isError, true);
        expect(result.errorMessage, 'Image file size cannot exceed 5MB');
      });

      test('should reject invalid file types', () async {
        // Arrange
        final mockFile = MockFile();
        const userId = 'user1';

        when(mockFile.path).thenReturn('/path/to/document.pdf');
        when(mockFile.length()).thenAnswer((_) async => 1024 * 1024); // 1MB

        // Act
        final result = await repository.uploadProfileImage(mockFile, userId);

        // Assert
        expect(result.isError, true);
        expect(result.errorMessage, 'Only JPG, JPEG, and PNG files are allowed');
      });

      test('should handle upload errors', () async {
        // Arrange
        final mockFile = MockFile();
        const userId = 'user1';

        when(mockFile.path).thenReturn('/path/to/image.jpg');
        when(mockFile.length()).thenAnswer((_) async => 1024 * 1024); // 1MB
        when(mockSupabase.storage).thenReturn(mockStorage);
        when(mockStorage.from('profiles')).thenReturn(mockStorageFileApi);
        when(mockStorageFileApi.remove(any)).thenAnswer((_) async => []);
        when(mockStorageFileApi.upload(any, any, fileOptions: anyNamed('fileOptions')))
            .thenThrow(Exception('Upload failed'));

        // Act
        final result = await repository.uploadProfileImage(mockFile, userId);

        // Assert
        expect(result.isError, true);
        expect(result.errorMessage, contains('Failed to upload profile image'));
        verify(mockLogger.error(any)).called(1);
      });
    });

    group('searchUsers', () {
      test('should search users successfully', () async {
        // Arrange
        final testUserData = {
          'id': 'user1',
          'email': 'test@example.com',
          'name': 'Test User',
          'roleCode': 'student',
          'createdAt': Timestamp.now(),
          'Bookmarks': <String>[],
          'likedPosts': <String>[],
          'enrolledCourses': <String>[],
        };

        when(mockFirestore.collection('users')).thenReturn(mockCollection);
        when(mockCollection.where('name', isGreaterThanOrEqualTo: 'Test'))
            .thenReturn(mockQuery);
        when(mockCollection.where('email', isGreaterThanOrEqualTo: 'test'))
            .thenReturn(mockQuery);
        when(mockQuery.where('name', isLessThanOrEqualTo: 'Test\uf8ff'))
            .thenReturn(mockQuery);
        when(mockQuery.where('email', isLessThanOrEqualTo: 'test\uf8ff'))
            .thenReturn(mockQuery);
        when(mockQuery.limit(20)).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([mockDocumentSnapshot]);
        when(mockDocumentSnapshot.data()).thenReturn(testUserData);
        when(mockDocumentSnapshot.id).thenReturn('user1');

        // Act
        final result = await repository.searchUsers('Test');

        // Assert
        expect(result.isSuccess, true);
        expect(result.data?.length, 1);
        expect(result.data?.first.name, 'Test User');
        verify(mockLogger.info('Successfully found 1 users matching query: Test')).called(1);
      });

      test('should handle search errors', () async {
        // Arrange
        when(mockFirestore.collection('users')).thenReturn(mockCollection);
        when(mockCollection.where('name', isGreaterThanOrEqualTo: 'Test'))
            .thenThrow(Exception('Search failed'));

        // Act
        final result = await repository.searchUsers('Test');

        // Assert
        expect(result.isError, true);
        expect(result.errorMessage, contains('Failed to search users'));
        verify(mockLogger.error(any)).called(1);
      });
    });

    group('toggleBookmark', () {
      test('should add bookmark successfully', () async {
        // Arrange
        final mockTransaction = MockTransaction();
        final userData = {
          'Bookmarks': <String>[],
        };

        when(mockFirestore.collection('users')).thenReturn(mockCollection);
        when(mockCollection.doc('user1')).thenReturn(mockDocumentRef);
        when(mockFirestore.runTransaction(any)).thenAnswer((invocation) async {
          final callback = invocation.positionalArguments[0] as Function;
          return await callback(mockTransaction);
        });
        when(mockTransaction.get(mockDocumentRef)).thenAnswer((_) async => mockDocumentSnapshot);
        when(mockDocumentSnapshot.exists).thenReturn(true);
        when(mockDocumentSnapshot.data()).thenReturn(userData);

        // Act
        final result = await repository.toggleBookmark('user1', 'post1');

        // Assert
        expect(result.isSuccess, true);
        verify(mockTransaction.update(mockDocumentRef, {'Bookmarks': ['post1']})).called(1);
        verify(mockLogger.info('Successfully toggled bookmark for user: user1, post: post1')).called(1);
      });

      test('should remove bookmark successfully', () async {
        // Arrange
        final mockTransaction = MockTransaction();
        final userData = {
          'Bookmarks': ['post1'],
        };

        when(mockFirestore.collection('users')).thenReturn(mockCollection);
        when(mockCollection.doc('user1')).thenReturn(mockDocumentRef);
        when(mockFirestore.runTransaction(any)).thenAnswer((invocation) async {
          final callback = invocation.positionalArguments[0] as Function;
          return await callback(mockTransaction);
        });
        when(mockTransaction.get(mockDocumentRef)).thenAnswer((_) async => mockDocumentSnapshot);
        when(mockDocumentSnapshot.exists).thenReturn(true);
        when(mockDocumentSnapshot.data()).thenReturn(userData);

        // Act
        final result = await repository.toggleBookmark('user1', 'post1');

        // Assert
        expect(result.isSuccess, true);
        verify(mockTransaction.update(mockDocumentRef, {'Bookmarks': <String>[]})).called(1);
      });

      test('should handle toggle bookmark errors', () async {
        // Arrange
        when(mockFirestore.collection('users')).thenReturn(mockCollection);
        when(mockCollection.doc('user1')).thenReturn(mockDocumentRef);
        when(mockFirestore.runTransaction(any)).thenThrow(Exception('Transaction failed'));

        // Act
        final result = await repository.toggleBookmark('user1', 'post1');

        // Assert
        expect(result.isError, true);
        expect(result.errorMessage, contains('Failed to toggle bookmark'));
        verify(mockLogger.error(any)).called(1);
      });
    });

    group('getUsersByRole', () {
      test('should return users by role successfully', () async {
        // Arrange
        final testUserData = {
          'id': 'user1',
          'email': 'instructor@example.com',
          'name': 'Instructor User',
          'roleCode': 'instructor',
          'createdAt': Timestamp.now(),
          'Bookmarks': <String>[],
          'likedPosts': <String>[],
          'enrolledCourses': <String>[],
        };

        when(mockFirestore.collection('users')).thenReturn(mockCollection);
        when(mockCollection.where('roleCode', isEqualTo: 'instructor'))
            .thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([mockDocumentSnapshot]);
        when(mockDocumentSnapshot.data()).thenReturn(testUserData);
        when(mockDocumentSnapshot.id).thenReturn('user1');

        // Act
        final result = await repository.getUsersByRole(UserRole.instructor);

        // Assert
        expect(result.isSuccess, true);
        expect(result.data?.length, 1);
        expect(result.data?.first.role, UserRole.instructor);
        verify(mockLogger.info('Successfully fetched 1 users with role: instructor')).called(1);
      });

      test('should handle role query errors', () async {
        // Arrange
        when(mockFirestore.collection('users')).thenReturn(mockCollection);
        when(mockCollection.where('roleCode', isEqualTo: 'instructor'))
            .thenThrow(Exception('Query failed'));

        // Act
        final result = await repository.getUsersByRole(UserRole.instructor);

        // Assert
        expect(result.isError, true);
        expect(result.errorMessage, contains('Failed to fetch users by role'));
        verify(mockLogger.error(any)).called(1);
      });
    });

    group('userExists', () {
      test('should return true when user exists', () async {
        // Arrange
        when(mockFirestore.collection('users')).thenReturn(mockCollection);
        when(mockCollection.doc('user1')).thenReturn(mockDocumentRef);
        when(mockDocumentRef.get()).thenAnswer((_) async => mockDocumentSnapshot);
        when(mockDocumentSnapshot.exists).thenReturn(true);

        // Act
        final result = await repository.userExists('user1');

        // Assert
        expect(result.isSuccess, true);
        expect(result.data, true);
        verify(mockLogger.info('User exists check for user1: true')).called(1);
      });

      test('should return false when user does not exist', () async {
        // Arrange
        when(mockFirestore.collection('users')).thenReturn(mockCollection);
        when(mockCollection.doc('user1')).thenReturn(mockDocumentRef);
        when(mockDocumentRef.get()).thenAnswer((_) async => mockDocumentSnapshot);
        when(mockDocumentSnapshot.exists).thenReturn(false);

        // Act
        final result = await repository.userExists('user1');

        // Assert
        expect(result.isSuccess, true);
        expect(result.data, false);
        verify(mockLogger.info('User exists check for user1: false')).called(1);
      });
    });
  });
}