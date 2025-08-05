import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../modules/message.dart';
import '../modules/user.dart';

/// Enhanced message bubble widget with status indicators and better design
class MessageBubble extends StatelessWidget {
  /// Create a message bubble which is meant to be the first in the sequence
  const MessageBubble.first({
    super.key,
    required this.message,
    required this.sender,
    required this.isMe,
    this.showAvatar = true,
    this.onLongPress,
    this.onTap,
  }) : isFirstInSequence = true;

  /// Create a message bubble that continues the sequence
  const MessageBubble.next({
    super.key,
    required this.message,
    required this.sender,
    required this.isMe,
    this.onLongPress,
    this.onTap,
  }) : isFirstInSequence = false,
       showAvatar = false;

  /// Whether this message bubble is the first in a sequence from the same user
  final bool isFirstInSequence;

  /// Whether to show the user avatar (only for first in sequence)
  final bool showAvatar;

  /// The message data
  final Message message;

  /// The sender user data
  final User sender;

  /// Whether this message is from the current user
  final bool isMe;

  /// Callback for long press actions (edit, delete, etc.)
  final VoidCallback? onLongPress;

  /// Callback for tap actions
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onLongPress: onLongPress,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Avatar for other users (left side)
            if (!isMe && showAvatar && isFirstInSequence) ...[
              _buildAvatar(context),
              const SizedBox(width: 8),
            ] else if (!isMe) ...[
              const SizedBox(width: 40), // Space for avatar alignment
            ],
            
            // Message content
            Flexible(
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // Username for first message in sequence (non-me messages)
                  if (!isMe && isFirstInSequence)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, bottom: 4),
                      child: Text(
                        sender.name,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                  
                  // Message bubble
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                      minWidth: 60,
                    ),
                    decoration: BoxDecoration(
                      color: _getBubbleColor(context),
                      borderRadius: _getBorderRadius(),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Reply indicator if this is a reply
                        if (message.isReply) _buildReplyIndicator(context),
                        
                        // Message content based on type
                        _buildMessageContent(context),
                        
                        const SizedBox(height: 4),
                        
                        // Timestamp and status row
                        _buildTimestampAndStatus(context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Avatar for current user (right side)
            if (isMe && showAvatar && isFirstInSequence) ...[
              const SizedBox(width: 8),
              _buildAvatar(context),
            ] else if (isMe) ...[
              const SizedBox(width: 40), // Space for avatar alignment
            ],
          ],
        ),
      ),
    );
  }

  /// Builds the user avatar
  Widget _buildAvatar(BuildContext context) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      backgroundImage: sender.profileImage != null && sender.profileImage!.isNotEmpty
          ? NetworkImage(sender.profileImage!)
          : null,
      child: sender.profileImage == null || sender.profileImage!.isEmpty
          ? Text(
              sender.name.isNotEmpty ? sender.name[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : null,
    );
  }

  /// Gets the bubble background color based on message type and sender
  Color _getBubbleColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    if (message.isSystemMessage) {
      return colorScheme.surfaceContainerHighest.withOpacity(0.5);
    }
    
    if (isMe) {
      return colorScheme.primary;
    } else {
      return colorScheme.surfaceContainerHighest;
    }
  }

  /// Gets the border radius for the message bubble
  BorderRadius _getBorderRadius() {
    const radius = Radius.circular(16);
    const smallRadius = Radius.circular(4);
    
    if (isFirstInSequence) {
      return BorderRadius.only(
        topLeft: isMe ? radius : smallRadius,
        topRight: isMe ? smallRadius : radius,
        bottomLeft: radius,
        bottomRight: radius,
      );
    } else {
      return BorderRadius.circular(16);
    }
  }

  /// Builds the reply indicator for reply messages
  Widget _buildReplyIndicator(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.reply,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          const SizedBox(width: 4),
          Text(
            'Replying to message',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the message content based on message type
  Widget _buildMessageContent(BuildContext context) {
    final textColor = isMe 
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.onSurface;

    switch (message.type) {
      case MessageType.text:
        return Text(
          message.content,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: textColor,
            height: 1.3,
          ),
        );
      
      case MessageType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.fileUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  message.fileUrl!,
                  width: 200,
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 200,
                    height: 150,
                    color: Colors.grey[300],
                    child: const Icon(Icons.error),
                  ),
                ),
              ),
            if (message.content.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                message.content,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: textColor,
                ),
              ),
            ],
          ],
        );
      
      case MessageType.file:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.attach_file,
              size: 20,
              color: textColor,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.fileName ?? 'File',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (message.formattedFileSize != null)
                    Text(
                      message.formattedFileSize!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      
      case MessageType.system:
        return Text(
          message.content,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        );
    }
  }

  /// Builds the timestamp and status indicators
  Widget _buildTimestampAndStatus(BuildContext context) {
    final textColor = isMe 
        ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.7)
        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          DateFormat('HH:mm').format(message.timestamp),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: textColor,
            fontSize: 11,
          ),
        ),
        
        // Status indicators for sent messages
        if (isMe) ...[
          const SizedBox(width: 4),
          _buildStatusIcon(context, textColor),
        ],
      ],
    );
  }

  /// Builds the status icon for message delivery status
  Widget _buildStatusIcon(BuildContext context, Color color) {
    switch (message.status) {
      case MessageStatus.sending:
        return SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        );
      
      case MessageStatus.sent:
        return Icon(
          Icons.check,
          size: 14,
          color: color,
        );
      
      case MessageStatus.delivered:
        return Icon(
          Icons.done_all,
          size: 14,
          color: color,
        );
      
      case MessageStatus.read:
        return Icon(
          Icons.done_all,
          size: 14,
          color: Theme.of(context).colorScheme.primary,
        );
      
      case MessageStatus.failed:
        return Icon(
          Icons.error_outline,
          size: 14,
          color: Theme.of(context).colorScheme.error,
        );
    }
  }
}
