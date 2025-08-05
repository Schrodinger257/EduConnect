import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import '../../lib/repositories/firebase_course_repository.dart';
import '../../lib/core/result.dart';
import '../../lib/core/logger.dart';
import '../../lib/modules/course.dart';
import '../../lib/modules/user.dart';

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
import 'course_repository_test.mocks.dart';

void main() {
  group('FirebaseCourseRepository', () {
    late FirebaseCourseRepository repository;
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

      repository = FirebaseCourseRepository(
        firestore: mockFirestore,
        logger: mockLogger,
      );
    });

    group('getCourses', () {
      test('should return courses successfully', () async {
        // Arrange
        final testData = {
          'id': 'course1',
          'title': 'Test Course',
          'description': 'Test course description',
          'instructorId': 'instructor1',
          'createdAt': Timestamp.now(),
          'enrolledStudents': ['student1'],
          'tags': ['test'],
          'maxEnrollment': 50,
          'status': 'published',
          'duration': 10,
        };

        when(mockFirestore.collection('courses')).thenReturn(mockCollection);
        when(mockCollection.orderBy('createdAt', descending: true))
            .thenReturn(mockQuery);
        when(mockQuery.limit(10)).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([mockDocumentSnapshot]);
        when(mockDocumentSnapshot.data()).thenReturn(testData);
        when(mockDocumentSnapshot.id).thenReturn('course1');

        // Act
        final result = await repository.getCourses();

        // Assert
        expect(result.isSuccess, true);
        expect(result.data?.length, 1);
        expect(result.data?.first.id, 'course1');
        expect(result.data?.first.title, 'Test Course');
        verify(mockLogger.info('Successfully fetched 1 courses')).called(1);
      });

      test('should filter courses by status', () async {
        // Arrange
        when(mockFirestore.collection('courses')).thenReturn(mockCollection);
        when(mockCollection.orderBy('createdAt', descending: true))
            .thenReturn(mockQuery);
        when(mockQuery.where('status', isEqualTo: 'published'))
            .thenReturn(mockQuery);
        when(mockQuery.limit(10)).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([]);

        // Act
        final result = await repository.getCourses(status: CourseStatus.published);

        // Assert
        expect(result.isSuccess, true);
        verify(mockQuery.where('status', isEqualTo: 'published')).called(1);
      });

      test('should handle errors gracefully', () async {
        // Arrange
        when(mockFirestore.collection('courses')).thenReturn(mockCollection);
        when(mockCollection.orderBy('createdAt', descending: true))
            .thenReturn(mockQuery);
        when(mockQuery.limit(10)).thenReturn(mockQuery);
        when(mockQuery.get()).thenThrow(Exception('Network error'));

        // Act
        final result = await repository.getCourses();

        // Assert
        expect(result.isError, true);
        expect(result.errorMessage, contains('Failed to fetch courses'));
        verify(mockLogger.error(any)).called(1);
      });
    });

    group('getCourseById', () {
      test('should return course successfully', () async {
        // Arrange
        final testData = {
          'id': 'course1',
          'title': 'Test Course',
          'description': 'Test course description',
          'instructorId': 'instructor1',
          'createdAt': Timestamp.now(),
          'enrolledStudents': <String>[],
          'tags': <String>[],
          'maxEnrollment': 50,
          'status': 'draft',
          'duration': 0,
        };

        when(mockFirestore.collection('courses')).thenReturn(mockCollection);
        when(mockCollection.doc('course1')).thenReturn(mockDocumentRef);
        when(mockDocumentRef.get()).thenAnswer((_) async => mockDocumentSnapshot);
        when(mockDocumentSnapshot.exists).thenReturn(true);
        when(mockDocumentSnapshot.data()).thenReturn(testData);
        when(mockDocumentSnapshot.id).thenReturn('course1');

        // Act
        final result = await repository.getCourseById('course1');

        // Assert
        expect(result.isSuccess, true);
        expect(result.data?.id, 'course1');
        expect(result.data?.title, 'Test Course');
        verify(mockLogger.info('Successfully fetched course: course1')).called(1);
      });

      test('should return error when course not found', () async {
        // Arrange
        when(mockFirestore.collection('courses')).thenReturn(mockCollection);
        when(mockCollection.doc('course1')).thenReturn(mockDocumentRef);
        when(mockDocumentRef.get()).thenAnswer((_) async => mockDocumentSnapshot);
        when(mockDocumentSnapshot.exists).thenReturn(false);

        // Act
        final result = await repository.getCourseById('course1');

        // Assert
        expect(result.isError, true);
        expect(result.errorMessage, 'Course not found');
        verify(mockLogger.warning('Course not found: course1')).called(1);
      });
    });

    group('createCourse', () {
      test('should create course successfully', () async {
        // Arrange
        final course = Course(
          id: 'temp_id',
          title: 'New Course',
          description: 'New course description',
          instructorId: 'instructor1',
          createdAt: DateTime.now(),
        );

        final createdData = {
          'id': 'new_course_id',
          'title': 'New Course',
          'description': 'New course description',
          'instructorId': 'instructor1',
          'createdAt': Timestamp.now(),
          'enrolledStudents': <String>[],
          'tags': <String>[],
          'maxEnrollment': 50,
          'status': 'draft',
          'duration': 0,
        };

        when(mockFirestore.collection('courses')).thenReturn(mockCollection);
        when(mockCollection.add(any)).thenAnswer((_) async => mockDocumentRef);
        when(mockDocumentRef.get()).thenAnswer((_) async => mockDocumentSnapshot);
        when(mockDocumentSnapshot.data()).thenReturn(createdData);
        when(mockDocumentSnapshot.id).thenReturn('new_course_id');

        // Act
        final result = await repository.createCourse(course);

        // Assert
        expect(result.isSuccess, true);
        expect(result.data?.id, 'new_course_id');
        expect(result.data?.title, 'New Course');
        verify(mockLogger.info('Successfully created course with ID: new_course_id')).called(1);
      });

      test('should handle creation errors', () async {
        // Arrange
        final course = Course(
          id: 'temp_id',
          title: 'New Course',
          description: 'New course description',
          instructorId: 'instructor1',
          createdAt: DateTime.now(),
        );

        when(mockFirestore.collection('courses')).thenReturn(mockCollection);
        when(mockCollection.add(any)).thenThrow(Exception('Creation failed'));

        // Act
        final result = await repository.createCourse(course);

        // Assert
        expect(result.isError, true);
        expect(result.errorMessage, contains('Failed to create course'));
        verify(mockLogger.error(any)).called(1);
      });
    });

    group('enrollStudent', () {
      test('should enroll student successfully', () async {
        // Arrange
        final mockTransaction = MockTransaction();
        final mockCourseDoc = MockDocumentSnapshot<Map<String, dynamic>>();
        final mockUserDoc = MockDocumentSnapshot<Map<String, dynamic>>();
        final mockUserRef = MockDocumentReference<Map<String, dynamic>>();

        when(mockFirestore.collection('courses')).thenReturn(mockCollection);
        when(mockCollection.doc('course1')).thenReturn(mockDocumentRef);
        when(mockFirestore.collection('users')).thenReturn(mockCollection);
        when(mockCollection.doc('student1')).thenReturn(mockUserRef);

        when(mockFirestore.runTransaction(any)).thenAnswer((invocation) async {
          final callback = invocation.positionalArguments[0] as Function;
          return await callback(mockTransaction);
        });

        when(mockTransaction.get(mockDocumentRef)).thenAnswer((_) async => mockCourseDoc);
        when(mockTransaction.get(mockUserRef)).thenAnswer((_) async => mockUserDoc);
        when(mockCourseDoc.exists).thenReturn(true);
        when(mockUserDoc.exists).thenReturn(true);
        when(mockCourseDoc.data()).thenReturn({
          'enrolledStudents': <String>[],
          'maxEnrollment': 50,
          'status': 'published',
        });
        when(mockUserDoc.data()).thenReturn({
          'enrolledCourses': <String>[],
        });

        // Act
        final result = await repository.enrollStudent('course1', 'student1');

        // Assert
        expect(result.isSuccess, true);
        verify(mockTransaction.update(mockDocumentRef, any)).called(1);
        verify(mockTransaction.update(mockUserRef, any)).called(1);
        verify(mockLogger.info('Successfully enrolled student: student1 in course: course1')).called(1);
      });

      test('should prevent enrollment when course is full', () async {
        // Arrange
        final mockTransaction = MockTransaction();
        final mockCourseDoc = MockDocumentSnapshot<Map<String, dynamic>>();
        final mockUserDoc = MockDocumentSnapshot<Map<String, dynamic>>();
        final mockUserRef = MockDocumentReference<Map<String, dynamic>>();

        when(mockFirestore.collection('courses')).thenReturn(mockCollection);
        when(mockCollection.doc('course1')).thenReturn(mockDocumentRef);
        when(mockFirestore.collection('users')).thenReturn(mockCollection);
        when(mockCollection.doc('student1')).thenReturn(mockUserRef);

        when(mockFirestore.runTransaction(any)).thenAnswer((invocation) async {
          final callback = invocation.positionalArguments[0] as Function;
          return await callback(mockTransaction);
        });

        when(mockTransaction.get(mockDocumentRef)).thenAnswer((_) async => mockCourseDoc);
        when(mockTransaction.get(mockUserRef)).thenAnswer((_) async => mockUserDoc);
        when(mockCourseDoc.exists).thenReturn(true);
        when(mockUserDoc.exists).thenReturn(true);
        when(mockCourseDoc.data()).thenReturn({
          'enrolledStudents': List.generate(50, (i) => 'student$i'),
          'maxEnrollment': 50,
          'status': 'published',
        });
        when(mockUserDoc.data()).thenReturn({
          'enrolledCourses': <String>[],
        });

        // Act
        final result = await repository.enrollStudent('course1', 'student1');

        // Assert
        expect(result.isError, true);
        expect(result.errorMessage, contains('Course is full'));
        verify(mockLogger.error(any)).called(1);
      });

      test('should prevent enrollment when course is not published', () async {
        // Arrange
        final mockTransaction = MockTransaction();
        final mockCourseDoc = MockDocumentSnapshot<Map<String, dynamic>>();
        final mockUserDoc = MockDocumentSnapshot<Map<String, dynamic>>();
        final mockUserRef = MockDocumentReference<Map<String, dynamic>>();

        when(mockFirestore.collection('courses')).thenReturn(mockCollection);
        when(mockCollection.doc('course1')).thenReturn(mockDocumentRef);
        when(mockFirestore.collection('users')).thenReturn(mockCollection);
        when(mockCollection.doc('student1')).thenReturn(mockUserRef);

        when(mockFirestore.runTransaction(any)).thenAnswer((invocation) async {
          final callback = invocation.positionalArguments[0] as Function;
          return await callback(mockTransaction);
        });

        when(mockTransaction.get(mockDocumentRef)).thenAnswer((_) async => mockCourseDoc);
        when(mockTransaction.get(mockUserRef)).thenAnswer((_) async => mockUserDoc);
        when(mockCourseDoc.exists).thenReturn(true);
        when(mockUserDoc.exists).thenReturn(true);
        when(mockCourseDoc.data()).thenReturn({
          'enrolledStudents': <String>[],
          'maxEnrollment': 50,
          'status': 'draft',
        });
        when(mockUserDoc.data()).thenReturn({
          'enrolledCourses': <String>[],
        });

        // Act
        final result = await repository.enrollStudent('course1', 'student1');

        // Assert
        expect(result.isError, true);
        expect(result.errorMessage, contains('Course is not available for enrollment'));
        verify(mockLogger.error(any)).called(1);
      });
    });

    group('unenrollStudent', () {
      test('should unenroll student successfully', () async {
        // Arrange
        final mockTransaction = MockTransaction();
        final mockCourseDoc = MockDocumentSnapshot<Map<String, dynamic>>();
        final mockUserDoc = MockDocumentSnapshot<Map<String, dynamic>>();
        final mockUserRef = MockDocumentReference<Map<String, dynamic>>();

        when(mockFirestore.collection('courses')).thenReturn(mockCollection);
        when(mockCollection.doc('course1')).thenReturn(mockDocumentRef);
        when(mockFirestore.collection('users')).thenReturn(mockCollection);
        when(mockCollection.doc('student1')).thenReturn(mockUserRef);

        when(mockFirestore.runTransaction(any)).thenAnswer((invocation) async {
          final callback = invocation.positionalArguments[0] as Function;
          return await callback(mockTransaction);
        });

        when(mockTransaction.get(mockDocumentRef)).thenAnswer((_) async => mockCourseDoc);
        when(mockTransaction.get(mockUserRef)).thenAnswer((_) async => mockUserDoc);
        when(mockCourseDoc.exists).thenReturn(true);
        when(mockUserDoc.exists).thenReturn(true);
        when(mockCourseDoc.data()).thenReturn({
          'enrolledStudents': ['student1'],
        });
        when(mockUserDoc.data()).thenReturn({
          'enrolledCourses': ['course1'],
        });

        // Act
        final result = await repository.unenrollStudent('course1', 'student1');

        // Assert
        expect(result.isSuccess, true);
        verify(mockTransaction.update(mockDocumentRef, any)).called(1);
        verify(mockTransaction.update(mockUserRef, any)).called(1);
        verify(mockLogger.info('Successfully unenrolled student: student1 from course: course1')).called(1);
      });

      test('should handle unenrollment errors', () async {
        // Arrange
        when(mockFirestore.collection('courses')).thenReturn(mockCollection);
        when(mockCollection.doc('course1')).thenReturn(mockDocumentRef);
        when(mockFirestore.runTransaction(any)).thenThrow(Exception('Transaction failed'));

        // Act
        final result = await repository.unenrollStudent('course1', 'student1');

        // Assert
        expect(result.isError, true);
        expect(result.errorMessage, contains('Failed to unenroll student'));
        verify(mockLogger.error(any)).called(1);
      });
    });

    group('isStudentEnrolled', () {
      test('should return true when student is enrolled', () async {
        // Arrange
        when(mockFirestore.collection('courses')).thenReturn(mockCollection);
        when(mockCollection.doc('course1')).thenReturn(mockDocumentRef);
        when(mockDocumentRef.get()).thenAnswer((_) async => mockDocumentSnapshot);
        when(mockDocumentSnapshot.exists).thenReturn(true);
        when(mockDocumentSnapshot.data()).thenReturn({
          'enrolledStudents': ['student1', 'student2'],
        });

        // Act
        final result = await repository.isStudentEnrolled('course1', 'student1');

        // Assert
        expect(result.isSuccess, true);
        expect(result.data, true);
        verify(mockLogger.info('Student enrollment check for student1 in course course1: true')).called(1);
      });

      test('should return false when student is not enrolled', () async {
        // Arrange
        when(mockFirestore.collection('courses')).thenReturn(mockCollection);
        when(mockCollection.doc('course1')).thenReturn(mockDocumentRef);
        when(mockDocumentRef.get()).thenAnswer((_) async => mockDocumentSnapshot);
        when(mockDocumentSnapshot.exists).thenReturn(true);
        when(mockDocumentSnapshot.data()).thenReturn({
          'enrolledStudents': ['student2'],
        });

        // Act
        final result = await repository.isStudentEnrolled('course1', 'student1');

        // Assert
        expect(result.isSuccess, true);
        expect(result.data, false);
        verify(mockLogger.info('Student enrollment check for student1 in course course1: false')).called(1);
      });

      test('should return error when course not found', () async {
        // Arrange
        when(mockFirestore.collection('courses')).thenReturn(mockCollection);
        when(mockCollection.doc('course1')).thenReturn(mockDocumentRef);
        when(mockDocumentRef.get()).thenAnswer((_) async => mockDocumentSnapshot);
        when(mockDocumentSnapshot.exists).thenReturn(false);

        // Act
        final result = await repository.isStudentEnrolled('course1', 'student1');

        // Assert
        expect(result.isError, true);
        expect(result.errorMessage, 'Course not found');
      });
    });

    group('getCourseStatistics', () {
      test('should return course statistics successfully', () async {
        // Arrange
        when(mockFirestore.collection('courses')).thenReturn(mockCollection);
        when(mockCollection.doc('course1')).thenReturn(mockDocumentRef);
        when(mockDocumentRef.get()).thenAnswer((_) async => mockDocumentSnapshot);
        when(mockDocumentSnapshot.exists).thenReturn(true);
        when(mockDocumentSnapshot.data()).thenReturn({
          'enrolledStudents': ['student1', 'student2'],
          'maxEnrollment': 50,
        });

        // Act
        final result = await repository.getCourseStatistics('course1');

        // Assert
        expect(result.isSuccess, true);
        expect(result.data?['enrolledCount'], 2);
        expect(result.data?['maxEnrollment'], 50);
        expect(result.data?['availableSpots'], 48);
        expect(result.data?['enrollmentPercentage'], 4);
        verify(mockLogger.info('Successfully fetched statistics for course: course1')).called(1);
      });

      test('should handle statistics fetch errors', () async {
        // Arrange
        when(mockFirestore.collection('courses')).thenReturn(mockCollection);
        when(mockCollection.doc('course1')).thenReturn(mockDocumentRef);
        when(mockDocumentRef.get()).thenThrow(Exception('Fetch failed'));

        // Act
        final result = await repository.getCourseStatistics('course1');

        // Assert
        expect(result.isError, true);
        expect(result.errorMessage, contains('Failed to fetch course statistics'));
        verify(mockLogger.error(any)).called(1);
      });
    });

    group('searchCourses', () {
      test('should search courses successfully', () async {
        // Arrange
        final testData = {
          'id': 'course1',
          'title': 'Programming Course',
          'description': 'Learn programming basics',
          'instructorId': 'instructor1',
          'createdAt': Timestamp.now(),
          'enrolledStudents': <String>[],
          'tags': ['programming'],
          'maxEnrollment': 50,
          'status': 'published',
          'duration': 0,
        };

        when(mockFirestore.collection('courses')).thenReturn(mockCollection);
        when(mockCollection.where('tags', arrayContainsAny: ['programming']))
            .thenReturn(mockQuery);
        when(mockQuery.where('status', isEqualTo: 'published'))
            .thenReturn(mockQuery);
        when(mockQuery.orderBy('createdAt', descending: true))
            .thenReturn(mockQuery);
        when(mockQuery.limit(50)).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([mockDocumentSnapshot]);
        when(mockDocumentSnapshot.data()).thenReturn(testData);
        when(mockDocumentSnapshot.id).thenReturn('course1');

        // Act
        final result = await repository.searchCourses('programming');

        // Assert
        expect(result.isSuccess, true);
        expect(result.data?.length, 1);
        expect(result.data?.first.title, 'Programming Course');
        verify(mockLogger.info('Successfully found 1 courses matching query: programming')).called(1);
      });

      test('should handle search errors', () async {
        // Arrange
        when(mockFirestore.collection('courses')).thenReturn(mockCollection);
        when(mockCollection.where('tags', arrayContainsAny: ['programming']))
            .thenThrow(Exception('Search failed'));

        // Act
        final result = await repository.searchCourses('programming');

        // Assert
        expect(result.isError, true);
        expect(result.errorMessage, contains('Failed to search courses'));
        verify(mockLogger.error(any)).called(1);
      });
    });

    group('isEnrollmentAvailable', () {
      test('should return true when enrollment is available', () async {
        // Arrange
        when(mockFirestore.collection('courses')).thenReturn(mockCollection);
        when(mockCollection.doc('course1')).thenReturn(mockDocumentRef);
        when(mockDocumentRef.get()).thenAnswer((_) async => mockDocumentSnapshot);
        when(mockDocumentSnapshot.exists).thenReturn(true);
        when(mockDocumentSnapshot.data()).thenReturn({
          'enrolledStudents': ['student1'],
          'maxEnrollment': 50,
          'status': 'published',
        });

        // Act
        final result = await repository.isEnrollmentAvailable('course1');

        // Assert
        expect(result.isSuccess, true);
        expect(result.data, true);
        verify(mockLogger.info('Enrollment availability for course course1: true')).called(1);
      });

      test('should return false when course is full', () async {
        // Arrange
        when(mockFirestore.collection('courses')).thenReturn(mockCollection);
        when(mockCollection.doc('course1')).thenReturn(mockDocumentRef);
        when(mockDocumentRef.get()).thenAnswer((_) async => mockDocumentSnapshot);
        when(mockDocumentSnapshot.exists).thenReturn(true);
        when(mockDocumentSnapshot.data()).thenReturn({
          'enrolledStudents': List.generate(50, (i) => 'student$i'),
          'maxEnrollment': 50,
          'status': 'published',
        });

        // Act
        final result = await repository.isEnrollmentAvailable('course1');

        // Assert
        expect(result.isSuccess, true);
        expect(result.data, false);
        verify(mockLogger.info('Enrollment availability for course course1: false')).called(1);
      });

      test('should return false when course is not published', () async {
        // Arrange
        when(mockFirestore.collection('courses')).thenReturn(mockCollection);
        when(mockCollection.doc('course1')).thenReturn(mockDocumentRef);
        when(mockDocumentRef.get()).thenAnswer((_) async => mockDocumentSnapshot);
        when(mockDocumentSnapshot.exists).thenReturn(true);
        when(mockDocumentSnapshot.data()).thenReturn({
          'enrolledStudents': ['student1'],
          'maxEnrollment': 50,
          'status': 'draft',
        });

        // Act
        final result = await repository.isEnrollmentAvailable('course1');

        // Assert
        expect(result.isSuccess, true);
        expect(result.data, false);
        verify(mockLogger.info('Enrollment availability for course course1: false')).called(1);
      });
    });
  });
}