import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/core.dart';
import '../modules/post.dart';
import '../modules/course.dart';
import '../modules/user.dart';

/// Enum for different search content types
enum SearchContentType {
  all,
  posts,
  courses,
  users,
}

/// Enum for search sorting options
enum SearchSortBy {
  relevance,
  date,
  popularity,
  alphabetical,
}

/// Enum for search date ranges
enum SearchDateRange {
  all,
  today,
  thisWeek,
  thisMonth,
  thisYear,
}

/// Search filter configuration
class SearchFilter {
  final SearchContentType contentType;
  final SearchSortBy sortBy;
  final SearchDateRange dateRange;
  final List<String> tags;
  final String? category;

  const SearchFilter({
    this.contentType = SearchContentType.all,
    this.sortBy = SearchSortBy.relevance,
    this.dateRange = SearchDateRange.all,
    this.tags = const [],
    this.category,
  });

  SearchFilter copyWith({
    SearchContentType? contentType,
    SearchSortBy? sortBy,
    SearchDateRange? dateRange,
    List<String>? tags,
    String? category,
  }) {
    return SearchFilter(
      contentType: contentType ?? this.contentType,
      sortBy: sortBy ?? this.sortBy,
      dateRange: dateRange ?? this.dateRange,
      tags: tags ?? this.tags,
      category: category ?? this.category,
    );
  }
}

/// Combined search results from all collections
class SearchResults {
  final List<Post> posts;
  final List<Course> courses;
  final List<User> users;
  final int totalCount;
  final String query;
  final SearchFilter filter;

  const SearchResults({
    this.posts = const [],
    this.courses = const [],
    this.users = const [],
    required this.query,
    required this.filter,
  }) : totalCount = posts.length + courses.length + users.length;

  bool get isEmpty => totalCount == 0;
  bool get isNotEmpty => totalCount > 0;

  /// Returns results filtered by content type
  SearchResults filterByType(SearchContentType type) {
    return switch (type) {
      SearchContentType.all => this,
      SearchContentType.posts => SearchResults(
          posts: posts,
          query: query,
          filter: filter,
        ),
      SearchContentType.courses => SearchResults(
          courses: courses,
          query: query,
          filter: filter,
        ),
      SearchContentType.users => SearchResults(
          users: users,
          query: query,
          filter: filter,
        ),
    };
  }
}

/// Cached search result with timestamp
class CachedSearchResult {
  final SearchResults results;
  final DateTime timestamp;
  final Duration ttl;

  const CachedSearchResult({
    required this.results,
    required this.timestamp,
    this.ttl = const Duration(minutes: 5),
  });

  bool get isExpired => DateTime.now().difference(timestamp) > ttl;
}

/// Service for comprehensive search functionality across multiple collections
class SearchService {
  final FirebaseFirestore _firestore;
  final Map<String, CachedSearchResult> _cache = {};
  final Map<String, int> _searchFrequency = {};
  
  SearchService({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Performs a comprehensive search across all collections
  Future<Result<SearchResults>> search(
    String query, {
    SearchFilter filter = const SearchFilter(),
    int limit = 20,
  }) async {
    try {
      // Validate query
      if (query.trim().isEmpty) {
        return Result.error('Search query cannot be empty');
      }

      final trimmedQuery = query.trim().toLowerCase();
      
      // Check cache first
      final cacheKey = _generateCacheKey(trimmedQuery, filter, limit);
      final cachedResult = _cache[cacheKey];
      if (cachedResult != null && !cachedResult.isExpired) {
        _updateSearchFrequency(trimmedQuery);
        return Result.success(cachedResult.results);
      }

      // Perform search based on content type filter
      final List<Post> posts;
      final List<Course> courses;
      final List<User> users;

      switch (filter.contentType) {
        case SearchContentType.all:
          final results = await Future.wait([
            _searchPosts(trimmedQuery, filter, limit ~/ 3),
            _searchCourses(trimmedQuery, filter, limit ~/ 3),
            _searchUsers(trimmedQuery, filter, limit ~/ 3),
          ]);
          posts = results[0].data ?? [];
          courses = results[1].data ?? [];
          users = results[2].data ?? [];
          break;
        case SearchContentType.posts:
          final result = await _searchPosts(trimmedQuery, filter, limit);
          posts = result.data ?? [];
          courses = [];
          users = [];
          break;
        case SearchContentType.courses:
          final result = await _searchCourses(trimmedQuery, filter, limit);
          posts = [];
          courses = result.data ?? [];
          users = [];
          break;
        case SearchContentType.users:
          final result = await _searchUsers(trimmedQuery, filter, limit);
          posts = [];
          courses = [];
          users = result.data ?? [];
          break;
      }

      // Create search results
      final searchResults = SearchResults(
        posts: posts,
        courses: courses,
        users: users,
        query: query,
        filter: filter,
      );

      // Apply sorting
      final sortedResults = _applySorting(searchResults, filter.sortBy);

      // Cache the results
      _cacheResults(cacheKey, sortedResults);
      
      // Update search frequency
      _updateSearchFrequency(trimmedQuery);

      return Result.success(sortedResults);
    } catch (e) {
      return Result.error('Search failed: ${e.toString()}', Exception(e.toString()));
    }
  }

  /// Searches posts collection
  Future<Result<List<Post>>> _searchPosts(
    String query,
    SearchFilter filter,
    int limit,
  ) async {
    try {
      Query<Map<String, dynamic>> postsQuery = _firestore.collection('posts');

      // Apply date range filter
      final dateRange = _getDateRange(filter.dateRange);
      if (dateRange != null) {
        postsQuery = postsQuery.where('timestamp', isGreaterThan: dateRange);
      }

      // Apply tag filter
      if (filter.tags.isNotEmpty) {
        postsQuery = postsQuery.where('tags', arrayContainsAny: filter.tags);
      }

      postsQuery = postsQuery.limit(limit * 2); // Get more for filtering

      final snapshot = await postsQuery.get();
      final posts = snapshot.docs
          .map((doc) => Post.fromJson({...doc.data(), 'id': doc.id}))
          .where((post) => _matchesQuery(post, query))
          .take(limit)
          .toList();

      return Result.success(posts);
    } catch (e) {
      return Result.error('Failed to search posts: ${e.toString()}');
    }
  }

  /// Searches courses collection
  Future<Result<List<Course>>> _searchCourses(
    String query,
    SearchFilter filter,
    int limit,
  ) async {
    try {
      Query<Map<String, dynamic>> coursesQuery = _firestore.collection('courses');

      // Apply date range filter
      final dateRange = _getDateRange(filter.dateRange);
      if (dateRange != null) {
        coursesQuery = coursesQuery.where('createdAt', isGreaterThan: dateRange);
      }

      // Apply category filter
      if (filter.category != null) {
        coursesQuery = coursesQuery.where('category', isEqualTo: filter.category);
      }

      // Apply tag filter
      if (filter.tags.isNotEmpty) {
        coursesQuery = coursesQuery.where('tags', arrayContainsAny: filter.tags);
      }

      // Only search published courses
      coursesQuery = coursesQuery.where('status', isEqualTo: 'published');

      coursesQuery = coursesQuery.limit(limit * 2); // Get more for filtering

      final snapshot = await coursesQuery.get();
      final courses = snapshot.docs
          .map((doc) => Course.fromJson({...doc.data(), 'id': doc.id}))
          .where((course) => _matchesQuery(course, query))
          .take(limit)
          .toList();

      return Result.success(courses);
    } catch (e) {
      return Result.error('Failed to search courses: ${e.toString()}');
    }
  }

  /// Searches users collection
  Future<Result<List<User>>> _searchUsers(
    String query,
    SearchFilter filter,
    int limit,
  ) async {
    try {
      Query<Map<String, dynamic>> usersQuery = _firestore.collection('users');

      usersQuery = usersQuery.limit(limit * 2); // Get more for filtering

      final snapshot = await usersQuery.get();
      final users = snapshot.docs
          .map((doc) => User.fromJson({...doc.data(), 'id': doc.id}))
          .where((user) => _matchesQuery(user, query))
          .take(limit)
          .toList();

      return Result.success(users);
    } catch (e) {
      return Result.error('Failed to search users: ${e.toString()}');
    }
  }

  /// Checks if a post matches the search query
  bool _matchesQuery(Post post, String query) {
    final lowerQuery = query.toLowerCase();
    return post.content.toLowerCase().contains(lowerQuery) ||
           post.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
  }

  /// Checks if a course matches the search query
  bool _matchesQuery(Course course, String query) {
    final lowerQuery = query.toLowerCase();
    return course.title.toLowerCase().contains(lowerQuery) ||
           course.description.toLowerCase().contains(lowerQuery) ||
           course.tags.any((tag) => tag.toLowerCase().contains(lowerQuery)) ||
           (course.category?.toLowerCase().contains(lowerQuery) ?? false);
  }

  /// Checks if a user matches the search query
  bool _matchesQuery(User user, String query) {
    final lowerQuery = query.toLowerCase();
    return user.name.toLowerCase().contains(lowerQuery) ||
           user.email.toLowerCase().contains(lowerQuery) ||
           (user.department?.toLowerCase().contains(lowerQuery) ?? false) ||
           (user.fieldOfExpertise?.toLowerCase().contains(lowerQuery) ?? false);
  }

  /// Applies sorting to search results
  SearchResults _applySorting(SearchResults results, SearchSortBy sortBy) {
    switch (sortBy) {
      case SearchSortBy.relevance:
        return _sortByRelevance(results);
      case SearchSortBy.date:
        return _sortByDate(results);
      case SearchSortBy.popularity:
        return _sortByPopularity(results);
      case SearchSortBy.alphabetical:
        return _sortAlphabetically(results);
    }
  }

  /// Sorts results by relevance (engagement score for posts/courses, name for users)
  SearchResults _sortByRelevance(SearchResults results) {
    final sortedPosts = [...results.posts]
      ..sort((a, b) => b.engagementScore.compareTo(a.engagementScore));
    
    final sortedCourses = [...results.courses]
      ..sort((a, b) => b.enrolledStudents.length.compareTo(a.enrolledStudents.length));
    
    final sortedUsers = [...results.users]
      ..sort((a, b) => a.name.compareTo(b.name));

    return SearchResults(
      posts: sortedPosts,
      courses: sortedCourses,
      users: sortedUsers,
      query: results.query,
      filter: results.filter,
    );
  }

  /// Sorts results by date (newest first)
  SearchResults _sortByDate(SearchResults results) {
    final sortedPosts = [...results.posts]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    final sortedCourses = [...results.courses]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    final sortedUsers = [...results.users]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return SearchResults(
      posts: sortedPosts,
      courses: sortedCourses,
      users: sortedUsers,
      query: results.query,
      filter: results.filter,
    );
  }

  /// Sorts results by popularity
  SearchResults _sortByPopularity(SearchResults results) {
    final sortedPosts = [...results.posts]
      ..sort((a, b) => b.likeCount.compareTo(a.likeCount));
    
    final sortedCourses = [...results.courses]
      ..sort((a, b) => b.enrollmentPercentage.compareTo(a.enrollmentPercentage));
    
    final sortedUsers = [...results.users]
      ..sort((a, b) => b.likedPosts.length.compareTo(a.likedPosts.length));

    return SearchResults(
      posts: sortedPosts,
      courses: sortedCourses,
      users: sortedUsers,
      query: results.query,
      filter: results.filter,
    );
  }

  /// Sorts results alphabetically
  SearchResults _sortAlphabetically(SearchResults results) {
    final sortedPosts = [...results.posts]
      ..sort((a, b) => a.content.compareTo(b.content));
    
    final sortedCourses = [...results.courses]
      ..sort((a, b) => a.title.compareTo(b.title));
    
    final sortedUsers = [...results.users]
      ..sort((a, b) => a.name.compareTo(b.name));

    return SearchResults(
      posts: sortedPosts,
      courses: sortedCourses,
      users: sortedUsers,
      query: results.query,
      filter: results.filter,
    );
  }

  /// Gets date range for filtering based on SearchDateRange
  DateTime? _getDateRange(SearchDateRange dateRange) {
    final now = DateTime.now();
    return switch (dateRange) {
      SearchDateRange.all => null,
      SearchDateRange.today => DateTime(now.year, now.month, now.day),
      SearchDateRange.thisWeek => now.subtract(const Duration(days: 7)),
      SearchDateRange.thisMonth => DateTime(now.year, now.month, 1),
      SearchDateRange.thisYear => DateTime(now.year, 1, 1),
    };
  }

  /// Generates cache key for search results
  String _generateCacheKey(String query, SearchFilter filter, int limit) {
    return '${query}_${filter.contentType.name}_${filter.sortBy.name}_${filter.dateRange.name}_${filter.tags.join(',')}_${filter.category ?? ''}_$limit';
  }

  /// Caches search results
  void _cacheResults(String key, SearchResults results) {
    _cache[key] = CachedSearchResult(
      results: results,
      timestamp: DateTime.now(),
    );

    // Clean up old cache entries (keep only 50 most recent)
    if (_cache.length > 50) {
      final sortedEntries = _cache.entries.toList()
        ..sort((a, b) => b.value.timestamp.compareTo(a.value.timestamp));
      
      _cache.clear();
      for (int i = 0; i < 50; i++) {
        _cache[sortedEntries[i].key] = sortedEntries[i].value;
      }
    }
  }

  /// Updates search frequency for analytics
  void _updateSearchFrequency(String query) {
    _searchFrequency[query] = (_searchFrequency[query] ?? 0) + 1;
  }

  /// Gets frequently searched terms
  List<String> getFrequentSearches({int limit = 10}) {
    final sortedEntries = _searchFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedEntries
        .take(limit)
        .map((entry) => entry.key)
        .toList();
  }

  /// Clears search cache
  void clearCache() {
    _cache.clear();
  }

  /// Gets cache statistics
  Map<String, dynamic> getCacheStats() {
    final now = DateTime.now();
    final validEntries = _cache.values.where((entry) => !entry.isExpired).length;
    final expiredEntries = _cache.length - validEntries;

    return {
      'totalEntries': _cache.length,
      'validEntries': validEntries,
      'expiredEntries': expiredEntries,
      'totalSearches': _searchFrequency.values.fold(0, (sum, count) => sum + count),
      'uniqueQueries': _searchFrequency.length,
    };
  }

  /// Preloads popular searches for better performance
  Future<void> preloadPopularSearches() async {
    final popularQueries = getFrequentSearches(limit: 5);
    
    for (final query in popularQueries) {
      if (query.isNotEmpty) {
        await search(query, limit: 10);
      }
    }
  }
}