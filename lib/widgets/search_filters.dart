import 'package:flutter/material.dart';
import '../services/search_service.dart';

class SearchFilters extends StatefulWidget {
  final SearchFilter currentFilter;
  final Function(SearchFilter) onFilterChanged;

  const SearchFilters({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  State<SearchFilters> createState() => _SearchFiltersState();
}

class _SearchFiltersState extends State<SearchFilters> {
  late SearchFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.currentFilter;
  }

  void _updateFilter(SearchFilter newFilter) {
    setState(() {
      _filter = newFilter;
    });
  }

  void _applyFilters() {
    widget.onFilterChanged(_filter);
    Navigator.of(context).pop();
  }

  void _resetFilters() {
    setState(() {
      _filter = const SearchFilter();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).shadowColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Text(
                  'Search Filters',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).shadowColor,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _resetFilters,
                  child: Text(
                    'Reset',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSortBySection(),
                  const SizedBox(height: 24),
                  _buildDateRangeSection(),
                  const SizedBox(height: 24),
                  _buildCategorySection(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Apply button
          Container(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortBySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sort By',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Theme.of(context).shadowColor,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: SearchSortBy.values.map((sortBy) {
            final isSelected = _filter.sortBy == sortBy;
            return FilterChip(
              label: Text(_getSortByLabel(sortBy)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  _updateFilter(_filter.copyWith(sortBy: sortBy));
                }
              },
              backgroundColor: Theme.of(context).cardColor,
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
              checkmarkColor: Theme.of(context).primaryColor,
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).shadowColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date Range',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Theme.of(context).shadowColor,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: SearchDateRange.values.map((dateRange) {
            final isSelected = _filter.dateRange == dateRange;
            return FilterChip(
              label: Text(_getDateRangeLabel(dateRange)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  _updateFilter(_filter.copyWith(dateRange: dateRange));
                }
              },
              backgroundColor: Theme.of(context).cardColor,
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
              checkmarkColor: Theme.of(context).primaryColor,
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).shadowColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    final categories = [
      'Programming',
      'Mathematics',
      'Science',
      'Literature',
      'History',
      'Art',
      'Music',
      'Sports',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Theme.of(context).shadowColor,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // All categories option
            FilterChip(
              label: const Text('All Categories'),
              selected: _filter.category == null,
              onSelected: (selected) {
                if (selected) {
                  _updateFilter(_filter.copyWith(category: null));
                }
              },
              backgroundColor: Theme.of(context).cardColor,
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
              checkmarkColor: Theme.of(context).primaryColor,
              labelStyle: TextStyle(
                color: _filter.category == null
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).shadowColor,
                fontWeight: _filter.category == null ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            // Individual categories
            ...categories.map((category) {
              final isSelected = _filter.category == category;
              return FilterChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    _updateFilter(_filter.copyWith(category: category));
                  }
                },
                backgroundColor: Theme.of(context).cardColor,
                selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                checkmarkColor: Theme.of(context).primaryColor,
                labelStyle: TextStyle(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).shadowColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  String _getSortByLabel(SearchSortBy sortBy) {
    return switch (sortBy) {
      SearchSortBy.relevance => 'Relevance',
      SearchSortBy.date => 'Date',
      SearchSortBy.popularity => 'Popularity',
      SearchSortBy.alphabetical => 'A-Z',
    };
  }

  String _getDateRangeLabel(SearchDateRange dateRange) {
    return switch (dateRange) {
      SearchDateRange.all => 'All Time',
      SearchDateRange.today => 'Today',
      SearchDateRange.thisWeek => 'This Week',
      SearchDateRange.thisMonth => 'This Month',
      SearchDateRange.thisYear => 'This Year',
    };
  }
}