import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../modules/chat.dart';
import '../modules/user.dart';

/// Enhanced chat list tile for displaying recent conversations
class ChatListTile extends StatelessWidget {
  const ChatListTile({
    super.key,
    required this.chat,
    required this.currentUserId,
    this.otherUser,
    required this.onTap,
    this.onLongPress,
    this.showUnreadBadge = true,
  });

  /// The chat data
  final Chat chat;

  /// Current user's ID
  final String currentUserId;

  /// Other user data (for direct messages)
  final User? otherUser;

  /// Callback when tile is tapped
  final VoidCallback onTap;

  /// Callback when tile is long pressed
  final VoidCallback? onLongPress;

  /// Whether to show unread message badge
  final bool showUnreadBadge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final unreadCount = chat.getUnreadCount(currentUserId);
    final hasUnread = unreadCount > 0;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            _buildAvatar(context),
            
            const SizedBox(width: 12),
            
            // Chat info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and timestamp row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _getChatTitle(),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w500,
                            color: hasUnread 
                                ? colorScheme.onSurface 
                                : colorScheme.onSurface.withOpacity(0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      if (chat.lastMessageTimestamp != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          _formatTimestamp(chat.lastMessageTimestamp!),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: hasUnread 
                                ? colorScheme.primary 
                                : colorScheme.onSurface.withOpacity(0.6),
                            fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Last message and unread badge row
                  Row(
                    children: [
                      Expanded(
                        child: _buildLastMessage(context, hasUnread),
                      ),
                      
                      // Unread badge
                      if (showUnreadBadge && hasUnread) ...[
                        const SizedBox(width: 8),
                        _buildUnreadBadge(context, unreadCount),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the chat avatar
  Widget _buildAvatar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    if (chat.isDirectMessage && otherUser != null) {
      // Direct message - show other user's avatar
      return CircleAvatar(
        radius: 24,
        backgroundColor: colorScheme.primary.withOpacity(0.1),
        backgroundImage: otherUser!.profileImage != null && otherUser!.profileImage!.isNotEmpty
            ? NetworkImage(otherUser!.profileImage!)
            : null,
        child: otherUser!.profileImage == null || otherUser!.profileImage!.isEmpty
            ? Text(
                otherUser!.name.isNotEmpty ? otherUser!.name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              )
            : null,
      );
    } else {
      // Group or course chat - show group avatar
      return CircleAvatar(
        radius: 24,
        backgroundColor: colorScheme.primary.withOpacity(0.1),
        backgroundImage: chat.imageUrl != null && chat.imageUrl!.isNotEmpty
            ? NetworkImage(chat.imageUrl!)
            : null,
        child: chat.imageUrl == null || chat.imageUrl!.isEmpty
            ? Icon(
                chat.isGroupChat ? Icons.group : Icons.school,
                color: colorScheme.primary,
                size: 24,
              )
            : null,
      );
    }
  }

  /// Gets the chat title to display
  String _getChatTitle() {
    if (chat.isDirectMessage && otherUser != null) {
      return otherUser!.name;
    } else {
      return chat.title;
    }
  }

  /// Builds the last message preview
  Widget _buildLastMessage(BuildContext context, bool hasUnread) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    if (chat.lastMessageContent == null) {
      return Text(
        'No messages yet',
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurface.withOpacity(0.5),
          fontStyle: FontStyle.italic,
        ),
      );
    }

    final isMyMessage = chat.lastMessageSenderId == currentUserId;
    final prefix = isMyMessage ? 'You: ' : '';
    final content = chat.lastMessagePreview ?? '';

    return Text(
      '$prefix$content',
      style: theme.textTheme.bodySmall?.copyWith(
        color: hasUnread 
            ? colorScheme.onSurface.withOpacity(0.8)
            : colorScheme.onSurface.withOpacity(0.6),
        fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Builds the unread message badge
  Widget _buildUnreadBadge(BuildContext context, int count) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      constraints: const BoxConstraints(
        minWidth: 20,
        minHeight: 20,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: TextStyle(
          color: colorScheme.onPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Formats the timestamp for display
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      // Today - show time
      return DateFormat('HH:mm').format(timestamp);
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      // This week - show day name
      return DateFormat('EEE').format(timestamp);
    } else if (difference.inDays < 365) {
      // This year - show month and day
      return DateFormat('MMM d').format(timestamp);
    } else {
      // Older - show year
      return DateFormat('MMM d, y').format(timestamp);
    }
  }
}

/// Widget for displaying online status indicator
class OnlineStatusIndicator extends StatelessWidget {
  const OnlineStatusIndicator({
    super.key,
    required this.isOnline,
    this.size = 12,
  });

  final bool isOnline;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isOnline ? Colors.green : Colors.grey,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).scaffoldBackgroundColor,
          width: 2,
        ),
      ),
    );
  }
}

/// Widget for displaying chat type icon
class ChatTypeIcon extends StatelessWidget {
  const ChatTypeIcon({
    super.key,
    required this.chatType,
    this.size = 16,
    this.color,
  });

  final ChatType chatType;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
    
    IconData iconData;
    switch (chatType) {
      case ChatType.direct:
        iconData = Icons.person;
        break;
      case ChatType.group:
        iconData = Icons.group;
        break;
      case ChatType.course:
        iconData = Icons.school;
        break;
    }

    return Icon(
      iconData,
      size: size,
      color: iconColor,
    );
  }
}