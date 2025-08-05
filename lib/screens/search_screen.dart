import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/search_provider.dart';
import '../services/search_service.dart';
import '../widgets/search_input.dart';
import '../widgets/search_results.dart';
import '../widgets/search_filters.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Load recent searches and popular searches on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchProvider.notifier).loadRecentSearches();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;
    
    final currentFilter = ref.read(searchProvider).filter;
    ref.read(searchProvider.notifier).search(query, filter: currentFilter);
    _searchFocusNode.unfocus();
  }

  void _onFilterChanged(SearchFilter filter) {
    ref.read(searchProvider.notifier).updateFilter(filter);
    
    // Re-search with new filter if there's an active query
    final currentQuery = ref.read(searchProvider).query;
    if (currentQuery.isNotEmpty) {
      ref.read(searchProvider.notifier).search(currentQuery, filter: filter);
    }
  }

  void _onTabChanged() {
    final contentType = switch (_tabController.index) {
      0 => SearchContentType.all,
      1 => SearchContentType.posts,
      2 => SearchContentType.courses,
      3 => SearchContentType.users,
      _ => SearchContentType.all,
    };
    
    final currentFilter = ref.read(searchProvider).filter;
    final newFilter = currentFilter.copyWith(contentType: contentType);
    _onFilterChanged(newFilter);
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Search',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SearchInput(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onSearch: _performSearch,
                  onSuggestionTap: (suggestion) {
                    _searchController.text = suggestion;
                    _performSearch(suggestion);
                  },
                ),
              ),
              TabBar(
                controller: _tabController,
                onTap: (_) => _onTabChanged(),
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Theme.of(context).shadowColor.withOpacity(0.6),
                indicatorColor: Theme.of(context).primaryColor,
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Posts'),
                  Tab(text: 'Courses'),
                  Tab(text: 'Users'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSearchContent(searchState, SearchContentType.all),
          _buildSearchContent(searchState, SearchContentType.posts),
          _buildSearchContent(searchState, SearchContentType.courses),
          _buildSearchContent(searchState, SearchContentType.users),
        ],
      ),
    );
  }

  Widget _buildSearchContent(SearchState searchState, SearchContentType contentType) {
    if (searchState.query.isEmpty) {
      return _buildEmptyState();
    }

    if (searchState.isLoading) {
      return _buildLoadingState();
    }

    if (searchState.error != null) {
      return _buildErrorState(searchState.error!);
    }

    if (searchState.results == null || searchState.results!.isEmpty) {
      return _buildNoResultsState(searchState.query);
    }

    return SearchResultsWidget(
      results: searchState.results!.filterByType(contentType),
      onRetry: () => _performSearch(searchState.query),
    );
  }

  Widget _buildEmptyState() {
    final recentSearches = ref.watch(searchProvider).recentSearches;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recentSearches.isNotEmpty) ...[
            Text(
              'Recent Searches',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).shadowColor,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: recentSearches.map((search) => _buildSearchChip(search)).toList(),
            ),
            const SizedBox(height: 24),
          ],
          Text(
            'Search Tips',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).shadowColor,
            ),
          ),
          const SizedBox(height: 12),
          _buildSearchTip(
            icon: Icons.search,
            title: 'Search Everything',
            description: 'Find posts, courses, and users all in one place',
          ),
          _buildSearchTip(
            icon: Icons.filter_list,
            title: 'Use Filters',
            description: 'Narrow down results by type, date, or category',
          ),
          _buildSearchTip(
            icon: Icons.tag,
            title: 'Search by Tags',
            description: 'Use hashtags to find specific topics',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchChip(String search) {
    return Chip(
      label: Text(search),
      backgroundColor: Theme.of(context).cardColor,
      labelStyle: TextStyle(
        color: Theme.of(context).primaryColor,
        fontSize: 12,
      ),
      onDeleted: () {
        ref.read(searchProvider.notifier).removeRecentSearch(search);
      },
    );
  }

  Widget _buildSearchTip({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).shadowColor,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).shadowColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Searching...',
            style: TextStyle(
              color: Theme.of(context).shadowColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/vectors/400-Error-Bad-Request-pana.svg',
              height: 200,
            ),
            const SizedBox(height: 16),
            Text(
              'Search Error',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).shadowColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).shadowColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _performSearch(ref.read(searchProvider).query),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState(String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/vectors/No-data-amico.svg',
              height: 200,
            ),
            const SizedBox(height: 16),
            Text(
              'No Results Found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).shadowColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No results found for "$query"',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).shadowColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Try adjusting your search or filters',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).shadowColor.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SearchFilters(
        currentFilter: ref.read(searchProvider).filter,
        onFilterChanged: _onFilterChanged,
      ),
    );
  }
}