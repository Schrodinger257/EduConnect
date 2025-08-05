import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/core.dart';
import '../services/search_service.dart';

/// Search state class
class SearchState {
  final String query;
  final SearchResults? results;
  final SearchFilter filter;
  final bool isLoading;
  final String? error;
  final List<String> recentSearches;

  const SearchState({
    this.query = '',
    this.results,
    this.filter = const SearchFilter(),
    this.isLoading = false,
    this.error,
    this.recentSearches = const [],
  });

  SearchState copyWith({
    String? query,
    SearchResults? results,
    SearchFilter? filter,
    bool? isLoading,
    String? error,
    List<String>? recentSearches,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      recentSearches: recentSearches ?? this.recentSearches,
    );
  }
}

/// Search provider for managing search state and operations
class SearchNotifier extends StateNotifier<SearchState> {
  final SearchService _searchService;
  static const String _recentSearchesKey = 'recent_searches';
  static const int _maxRecentSearches = 10;

  SearchNotifier(this._searchService) : super(const SearchState());

  /// Performs a search with the given query and filter
  Future<void> search(String query, {SearchFilter? filter}) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(
        query: '',
        results: null,
        error: null,
      );
      return;
    }

    final searchFilter = filter ?? state.filter;
    
    state = state.copyWith(
      query: query,
      isLoading: true,
      error: null,
    );

    final result = await _searchService.search(query, filter: searchFilter);
    
    result.when(
      success: (searchResults) {
        state = state.copyWith(
          results: searchResults,
          isLoading: false,
          error: null,
        );
        _addToRecentSearches(query);
      },
      error: (message, exception) {
        state = state.copyWith(
          isLoading: false,
          error: message,
        );
      },
    );
  }

  /// Updates the search filter
  void updateFilter(SearchFilter filter) {
    state = state.copyWith(filter: filter);
  }

  /// Clears the current search
  void clearSearch() {
    state = state.copyWith(
      query: '',
      results: null,
      error: null,
    );
  }

  /// Loads recent searches from local storage
  Future<void> loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentSearches = prefs.getStringList(_recentSearchesKey) ?? [];
      state = state.copyWith(recentSearches: recentSearches);
    } catch (e) {
      // Handle error silently for non-critical functionality
    }
  }

  /// Adds a search query to recent searches
  Future<void> _addToRecentSearches(String query) async {
    try {
      final trimmedQuery = query.trim();
      if (trimmedQuery.isEmpty) return;

      final currentSearches = List<String>.from(state.recentSearches);
      
      // Remove if already exists
      currentSearches.remove(trimmedQuery);
      
      // Add to beginning
      currentSearches.insert(0, trimmedQuery);
      
      // Keep only the most recent searches
      if (currentSearches.length > _maxRecentSearches) {
        currentSearches.removeRange(_maxRecentSearches, currentSearches.length);
      }

      // Update state
      state = state.copyWith(recentSearches: currentSearches);

      // Save to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_recentSearchesKey, currentSearches);
    } catch (e) {
      // Handle error silently for non-critical functionality
    }
  }

  /// Removes a search from recent searches
  Future<void> removeRecentSearch(String query) async {
    try {
      final currentSearches = List<String>.from(state.recentSearches);
      currentSearches.remove(query);
      
      state = state.copyWith(recentSearches: currentSearches);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_recentSearchesKey, currentSearches);
    } catch (e) {
      // Handle error silently for non-critical functionality
    }
  }

  /// Clears all recent searches
  Future<void> clearRecentSearches() async {
    try {
      state = state.copyWith(recentSearches: []);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentSearchesKey);
    } catch (e) {
      // Handle error silently for non-critical functionality
    }
  }

  /// Gets popular searches from the search service
  List<String> getPopularSearches() {
    return _searchService.getFrequentSearches();
  }

  /// Gets search statistics
  Map<String, dynamic> getSearchStats() {
    return _searchService.getCacheStats();
  }

  /// Preloads popular searches for better performance
  Future<void> preloadPopularSearches() async {
    await _searchService.preloadPopularSearches();
  }
}

/// Provider for the search service
final searchServiceProvider = Provider<SearchService>((ref) {
  return SearchService();
});

/// Provider for the search state and operations
final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  final searchService = ref.watch(searchServiceProvider);
  return SearchNotifier(searchService);
});