import 'package:flutter/material.dart';
import '../modules/chat.dart';
import '../modules/user.dart';
import 'chat_list_tile.dart';

/// Enhanced chat list view with search and filtering capabilities
class ChatListView extends StatefulWidget {
  const ChatListView({
    super.key,
    required this.chats,
    required this.currentUserId,
    required this.onChatTap,
    this.onChatLongPress,
    this.users = const {},
    this.showSearch = true,
    this.showUnreadBadges = true,
    this.emptyMessage = 'No chats found',
    this.searchHint = 'Search chats...',
  });

  /// List of chats to display
  final List<Chat> chats;

  /// Current user's ID
  final String currentUserId;

  /// Callback when a chat is tapped
  final Function(Chat chat) onChatTap;

  /// Callback when a chat is long pressed
  final Function(Chat chat)? onChatLongPress;

  /// Map of user IDs to User objects for displaying user info
  final Map<String, User> users;

  /// Whether to show search functionality
  final bool showSearch;

  /// Whether to show unread message badges
  final bool showUnreadBadges;

  /// Message to show when no chats are found
  final String emptyMessage;

  /// Hint text for search field
  final String searchHint;

  @override
  State<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView> {
  final TextEditingController _searchController = TextEditingController();
  List<Chat> _filteredChats = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _filteredChats = widget.chats;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(ChatListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chats != widget.chats) {
      _filterChats();
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterChats();
    });
  }

  void _filterChats() {
    if (_searchQuery.isEmpty) {
      _filteredChats = widget.chats;
    } else {
      _filteredChats = widget.chats.where((chat) {
        // Search in chat title
        if (chat.title.toLowerCase().contains(_searchQuery)) {
          return true;
        }
        
        // Search in last message content
        if (chat.lastMessageContent?.toLowerCase().contains(_searchQuery) == true) {
          return true;
        }
        
        // Search in participant names for direct messages
        if (chat.isDirectMessage) {
          final otherUserId = chat.getOtherParticipantId(widget.currentUserId);
          if (otherUserId != null) {
            final otherUser = widget.users[otherUserId];
            if (otherUser?.name.toLowerCase().contains(_searchQuery) == true) {
              return true;
            }
          }
        }
        
        return false;
      }).toList();
    }
  }

  void _clearSearch() {
    _searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        if (widget.showSearch) _buildSearchBar(),
        
        // Chat list
        Expanded(
          child: _filteredChats.isEmpty
              ? _buildEmptyState()
              : _buildChatList(),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: widget.searchHint,
          prefixIcon: Icon(
            Icons.search,
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: _clearSearch,
                  icon: Icon(
                    Icons.clear,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(
              color: colorScheme.outline.withOpacity(0.3),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(
              color: colorScheme.outline.withOpacity(0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(
              color: colorScheme.primary,
            ),
          ),
          filled: true,
          fillColor: colorScheme.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.separated(
      itemCount: _filteredChats.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        indent: 68, // Align with chat content
      ),
      itemBuilder: (context, index) {
        final chat = _filteredChats[index];
        User? otherUser;
        
        // Get other user for direct messages
        if (chat.isDirectMessage) {
          final otherUserId = chat.getOtherParticipantId(widget.currentUserId);
          if (otherUserId != null) {
            otherUser = widget.users[otherUserId];
          }
        }

        return ChatListTile(
          chat: chat,
          currentUserId: widget.currentUserId,
          otherUser: otherUser,
          onTap: () => widget.onChatTap(chat),
          onLongPress: widget.onChatLongPress != null
              ? () => widget.onChatLongPress!(chat)
              : null,
          showUnreadBadge: widget.showUnreadBadges,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isNotEmpty ? Icons.search_off : Icons.chat_bubble_outline,
            size: 64,
            color: colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty 
                ? 'No chats found for "$_searchQuery"'
                : widget.emptyMessage,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _clearSearch,
              child: const Text('Clear search'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget for displaying chat list with pull-to-refresh
class RefreshableChatListView extends StatelessWidget {
  const RefreshableChatListView({
    super.key,
    required this.chats,
    required this.currentUserId,
    required this.onChatTap,
    required this.onRefresh,
    this.onChatLongPress,
    this.users = const {},
    this.showSearch = true,
    this.showUnreadBadges = true,
    this.emptyMessage = 'No chats found',
    this.searchHint = 'Search chats...',
    this.isLoading = false,
  });

  /// List of chats to display
  final List<Chat> chats;

  /// Current user's ID
  final String currentUserId;

  /// Callback when a chat is tapped
  final Function(Chat chat) onChatTap;

  /// Callback for pull-to-refresh
  final Future<void> Function() onRefresh;

  /// Callback when a chat is long pressed
  final Function(Chat chat)? onChatLongPress;

  /// Map of user IDs to User objects
  final Map<String, User> users;

  /// Whether to show search functionality
  final bool showSearch;

  /// Whether to show unread message badges
  final bool showUnreadBadges;

  /// Message to show when no chats are found
  final String emptyMessage;

  /// Hint text for search field
  final String searchHint;

  /// Whether the list is currently loading
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading && chats.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ChatListView(
        chats: chats,
        currentUserId: currentUserId,
        onChatTap: onChatTap,
        onChatLongPress: onChatLongPress,
        users: users,
        showSearch: showSearch,
        showUnreadBadges: showUnreadBadges,
        emptyMessage: emptyMessage,
        searchHint: searchHint,
      ),
    );
  }
}