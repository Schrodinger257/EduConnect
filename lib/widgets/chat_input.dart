import 'package:flutter/material.dart';

/// Chat input widget with send functionality and typing indicators
class ChatInput extends StatefulWidget {
  const ChatInput({
    super.key,
    required this.onSendMessage,
    this.onTypingChanged,
    this.onAttachFile,
    this.onAttachImage,
    this.enabled = true,
    this.hintText = 'Type a message...',
    this.maxLines = 5,
    this.replyToMessage,
    this.onCancelReply,
  });

  /// Callback when a message is sent
  final Function(String message) onSendMessage;

  /// Callback when typing status changes
  final Function(bool isTyping)? onTypingChanged;

  /// Callback when file attachment is requested
  final VoidCallback? onAttachFile;

  /// Callback when image attachment is requested
  final VoidCallback? onAttachImage;

  /// Whether the input is enabled
  final bool enabled;

  /// Hint text for the input field
  final String hintText;

  /// Maximum number of lines for the input
  final int maxLines;

  /// Message being replied to (if any)
  final String? replyToMessage;

  /// Callback to cancel reply
  final VoidCallback? onCancelReply;

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isTyping = false;
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text.trim();
    final canSend = text.isNotEmpty;
    final isTyping = text.isNotEmpty;

    if (_canSend != canSend) {
      setState(() {
        _canSend = canSend;
      });
    }

    if (_isTyping != isTyping) {
      _isTyping = isTyping;
      widget.onTypingChanged?.call(isTyping);
    }
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus && _isTyping) {
      _isTyping = false;
      widget.onTypingChanged?.call(false);
    }
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isNotEmpty && widget.enabled) {
      widget.onSendMessage(text);
      _controller.clear();
      _isTyping = false;
      widget.onTypingChanged?.call(false);
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _buildAttachmentOptions(),
    );
  }

  Widget _buildAttachmentOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Attach',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAttachmentOption(
                icon: Icons.photo,
                label: 'Photo',
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(context);
                  widget.onAttachImage?.call();
                },
              ),
              _buildAttachmentOption(
                icon: Icons.attach_file,
                label: 'File',
                color: Colors.orange,
                onTap: () {
                  Navigator.pop(context);
                  widget.onAttachFile?.call();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reply indicator
          if (widget.replyToMessage != null) _buildReplyIndicator(),
          
          // Input area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Attachment button
                if (widget.onAttachFile != null || widget.onAttachImage != null)
                  IconButton(
                    onPressed: widget.enabled ? _showAttachmentOptions : null,
                    icon: Icon(
                      Icons.add,
                      color: widget.enabled 
                          ? colorScheme.primary 
                          : colorScheme.onSurface.withOpacity(0.4),
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.primary.withOpacity(0.1),
                      shape: const CircleBorder(),
                    ),
                  ),
                
                const SizedBox(width: 8),
                
                // Text input
                Expanded(
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: widget.maxLines * 24.0,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      enabled: widget.enabled,
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.newline,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        hintStyle: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.5),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Send button
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: IconButton(
                    onPressed: _canSend && widget.enabled ? _sendMessage : null,
                    icon: Icon(
                      Icons.send,
                      color: _canSend && widget.enabled
                          ? colorScheme.primary
                          : colorScheme.onSurface.withOpacity(0.4),
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: _canSend && widget.enabled
                          ? colorScheme.primary.withOpacity(0.1)
                          : Colors.transparent,
                      shape: const CircleBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyIndicator() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        border: Border(
          left: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.reply,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  widget.replyToMessage!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onCancelReply,
            icon: Icon(
              Icons.close,
              size: 18,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
        ],
      ),
    );
  }
}