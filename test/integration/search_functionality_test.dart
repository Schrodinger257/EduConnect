import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/services/search_service.dart';
import 'package:educonnect/modules/post.dart';
import 'package:educonnect/modules/course.dart';

// Generate mocks
@GenerateMocks([FirebaseFirestore, CollectionReference, Query, QuerySnapshot, QueryDocumentSnapshot])
import 'search_functionality_test.mocks.dart';

void main() {
  group('Search Functionality Integration Tests', () {
    late SearchService searchService;
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockCollection;
    late MockQuery<Map<String, dynamic>> mockQuery;
    late MockQuerySnapshot<Map<String, dynamic>> mockSnapshot;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference<Map<String, dynamic>>();
      mockQuery = MockQuery<Map<String, dynamic>>();
      mockSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      
      searchService = SearchService(firestore: mockFirestore);
    });

    group('Search Service Tests', () {
      test('should return error for empty query', () async {
        final result = await searchService.search('');
        
        expect(result.isError, true);
        expect(result.errorMessage, 'Search query cannot be empty');
      });

      test('should search across all collections when filter is all', () async {
        // Mock Firestore collections
        when(mockFirestore.collection('posts')).thenReturn(mockCollection);
        when(mockFirestore.collection('courses')).thenReturn(mockCollection);
        when(mockFirestore.collection('users')).thenReturn(mockCollection);
        
        when(mockCollection.limit(any)).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);
        when(mockSnapshot.docs).thenReturn([]);

        final result = await searchService.search(
          'test query',
          filter: const SearchFilter(contentType: SearchContentType.all),
        );

        expect(result.isSuccess, true);
        expect(result.data?.query, 'test query');
        
        // Verify all collections were queried
        verify(mockFirestore.collection('posts')).called(1);
        verify(mockFirestore.collection('courses')).called(1);
        verify(mockFirestore.collection('users')).called(1);
      });

      test('should apply date range filter correctly', () async {
        when(mockFirestore.collection('posts')).thenReturn(mockCollection);
        when(mockCollection.where('timestamp', isGreaterThan: any)).thenReturn(mockQuery);
        when(mockQuery.limit(any)).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);
        when(mockSnapshot.docs).thenReturn([]);

        await searchService.search(
          'test',
          filter: const SearchFilter(
            contentType: SearchContentType.posts,
            dateRange: SearchDateRange.thisWeek,
          ),
        );

        verify(mockCollection.where('timestamp', isGreaterThan: any)).called(1);
      });

      test('should cache search results', () async {
        when(mockFirestore.collection('posts')).thenReturn(mockCollection);
        when(mockCollection.limit(any)).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);
        when(mockSnapshot.docs).thenReturn([]);

        // First search
        await searchService.search('test query');
        
        // Second search with same query should use cache
        await searchService.search('test query');

        // Firestore should only be called once due to caching
        verify(mockFirestore.collection('posts')).called(1);
      });

      test('should track search frequency', () async {
        when(mockFirestore.collection('posts')).thenReturn(mockCollection);
        when(mockCollection.limit(any)).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);
        when(mockSnapshot.docs).thenReturn([]);

        await searchService.search('popular query');
        await searchService.search('popular query');
        await searchService.search('another query');

        final frequentSearches = searchService.getFrequentSearches();
        expect(frequentSearches.first, 'popular query');
      });
    });

    group('Search Filter Tests', () {
      test('should create filter with default values', () {
        const filter = SearchFilter();
        
        expect(filter.contentType, SearchContentType.all);
        expect(filter.sortBy, SearchSortBy.relevance);
        expect(filter.dateRange, SearchDateRange.all);
        expect(filter.tags, isEmpty);
        expect(filter.category, isNull);
      });

      test('should copy filter with updated values', () {
        const originalFilter = SearchFilter(
          contentType: SearchContentType.posts,
          sortBy: SearchSortBy.date,
        );
        
        final updatedFilter = originalFilter.copyWith(
          contentType: SearchContentType.courses,
        );
        
        expect(updatedFilter.contentType, SearchContentType.courses);
        expect(updatedFilter.sortBy, SearchSortBy.date); // Should remain unchanged
      });
    });

    group('Search Results Tests', () {
      test('should calculate total count correctly', () {
        final posts = [
          Post(
            id: '1',
            content: 'Test post',
            userId: 'user1',
            timestamp: DateTime.now(),
          ),
        ];
        
        final courses = [
          Course(
            id: '1',
            title: 'Test course',
            description: 'Test description',
            instructorId: 'instructor1',
            createdAt: DateTime.now(),
          ),
        ];
        
        final results = SearchResults(
          posts: posts,
          courses: courses,
          users: [],
          query: 'test',
          filter: const SearchFilter(),
        );
        
        expect(results.totalCount, 2);
        expect(results.isNotEmpty, true);
      });

      test('should filter results by content type', () {
        final posts = [
          Post(
            id: '1',
            content: 'Test post',
            userId: 'user1',
            timestamp: DateTime.now(),
          ),
        ];
        
        final courses = [
          Course(
            id: '1',
            title: 'Test course',
            description: 'Test description',
            instructorId: 'instructor1',
            createdAt: DateTime.now(),
          ),
        ];
        
        final results = SearchResults(
          posts: posts,
          courses: courses,
          users: [],
          query: 'test',
          filter: const SearchFilter(),
        );
        
        final postsOnly = results.filterByType(SearchContentType.posts);
        expect(postsOnly.posts.length, 1);
        expect(postsOnly.courses.length, 0);
        expect(postsOnly.users.length, 0);
      });
    });

    group('Search Workflow Tests', () {
      test('should handle complete search workflow', () async {
        // This would test the complete workflow from search input to results display
        // In a real integration test, this would involve widget testing
        
        const query = 'flutter development';
        const filter = SearchFilter(
          contentType: SearchContentType.all,
          sortBy: SearchSortBy.relevance,
          dateRange: SearchDateRange.thisMonth,
        );
        
        // Mock successful search
        when(mockFirestore.collection(any)).thenReturn(mockCollection);
        when(mockCollection.where(any, isGreaterThan: any)).thenReturn(mockQuery);
        when(mockCollection.limit(any)).thenReturn(mockQuery);
        when(mockQuery.limit(any)).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);
        when(mockSnapshot.docs).thenReturn([]);
        
        final result = await searchService.search(query, filter: filter);
        
        expect(result.isSuccess, true);
        expect(result.data?.query, query);
        expect(result.data?.filter.contentType, SearchContentType.all);
      });
    });
  });
}