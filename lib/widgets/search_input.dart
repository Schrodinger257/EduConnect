import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/search_provider.dart';

class SearchInput extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Function(String) onSearch;
  final Function(String) onSuggestionTap;

  const SearchInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSearch,
    required this.onSuggestionTap,
  });

  @override
  ConsumerState<SearchInput> createState() => _SearchInputState();
}

class _SearchInputState extends ConsumerState<SearchInput> {
  bool _showSuggestions = false;
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    widget.focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    widget.focusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final query = widget.controller.text;
    if (query.isEmpty) {
      setState(() {
        _showSuggestions = false;
        _suggestions = [];
      });
      return;
    }

    // Get suggestions from recent searches and popular searches
    final searchState = ref.read(searchProvider);
    final recentSearches = searchState.recentSearches;
    final popularSearches = ref.read(searchProvider.notifier).getPopularSearches();
    
    final allSuggestions = [...recentSearches, ...popularSearches];
    final filteredSuggestions = allSuggestions
        .where((suggestion) => 
            suggestion.toLowerCase().contains(query.toLowerCase()) &&
            suggestion.toLowerCase() != query.toLowerCase())
        .take(5)
        .toList();

    setState(() {
      _suggestions = filteredSuggestions;
      _showSuggestions = filteredSuggestions.isNotEmpty && widget.focusNode.hasFocus;
    });
  }

  void _onFocusChanged() {
    if (!widget.focusNode.hasFocus) {
      // Delay hiding suggestions to allow for tap events
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) {
          setState(() {
            _showSuggestions = false;
          });
        }
      });
    } else {
      _onTextChanged(); // Refresh suggestions when focused
    }
  }

  void _onSuggestionSelected(String suggestion) {
    widget.onSuggestionTap(suggestion);
    setState(() {
      _showSuggestions = false;
    });
  }

  void _clearSearch() {
    widget.controller.clear();
    setState(() {
      _showSuggestions = false;
      _suggestions = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.focusNode.hasFocus
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).shadowColor.withOpacity(0.2),
              width: widget.focusNode.hasFocus ? 2 : 1,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            decoration: InputDecoration(
              hintText: 'Search posts, courses, users...',
              hintStyle: TextStyle(
                color: Theme.of(context).shadowColor.withOpacity(0.5),
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: Theme.of(context).shadowColor.withOpacity(0.7),
              ),
              suffixIcon: widget.controller.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: Theme.of(context).shadowColor.withOpacity(0.7),
                      ),
                      onPressed: _clearSearch,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            style: TextStyle(
              color: Theme.of(context).shadowColor,
              fontSize: 14,
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: widget.onSearch,
            onChanged: (_) => setState(() {}), // Trigger rebuild for suffix icon
          ),
        ),
        if (_showSuggestions && _suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: _suggestions.map((suggestion) => _buildSuggestionItem(suggestion)).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildSuggestionItem(String suggestion) {
    final query = widget.controller.text.toLowerCase();
    final suggestionLower = suggestion.toLowerCase();
    final startIndex = suggestionLower.indexOf(query);
    
    return InkWell(
      onTap: () => _onSuggestionSelected(suggestion),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.history,
              size: 16,
              color: Theme.of(context).shadowColor.withOpacity(0.5),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: startIndex != -1
                  ? _buildHighlightedText(suggestion, query, startIndex)
                  : Text(
                      suggestion,
                      style: TextStyle(
                        color: Theme.of(context).shadowColor,
                        fontSize: 14,
                      ),
                    ),
            ),
            Icon(
              Icons.north_west,
              size: 16,
              color: Theme.of(context).shadowColor.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightedText(String text, String query, int startIndex) {
    final beforeMatch = text.substring(0, startIndex);
    final match = text.substring(startIndex, startIndex + query.length);
    final afterMatch = text.substring(startIndex + query.length);

    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: Theme.of(context).shadowColor,
          fontSize: 14,
        ),
        children: [
          TextSpan(text: beforeMatch),
          TextSpan(
            text: match,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          TextSpan(text: afterMatch),
        ],
      ),
    );
  }
}