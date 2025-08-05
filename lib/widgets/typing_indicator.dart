import 'package:flutter/material.dart';

/// Widget that displays typing indicators for active users
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({
    super.key,
    required this.typingUsers,
    this.maxDisplayUsers = 3,
  });

  /// List of users currently typing
  final List<String> typingUsers;

  /// Maximum number of users to display by name
  final int maxDisplayUsers;

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.typingUsers.isNotEmpty) {
      _animationController.repeat();
    }
  }

  @override
  void didUpdateWidget(TypingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.typingUsers.isNotEmpty && oldWidget.typingUsers.isEmpty) {
      _animationController.repeat();
    } else if (widget.typingUsers.isEmpty && oldWidget.typingUsers.isNotEmpty) {
      _animationController.stop();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getTypingText() {
    final count = widget.typingUsers.length;
    
    if (count == 0) return '';
    
    if (count == 1) {
      return '${widget.typingUsers.first} is typing...';
    } else if (count <= widget.maxDisplayUsers) {
      final names = widget.typingUsers.take(count - 1).join(', ');
      return '$names and ${widget.typingUsers.last} are typing...';
    } else {
      final names = widget.typingUsers.take(widget.maxDisplayUsers - 1).join(', ');
      final remaining = count - (widget.maxDisplayUsers - 1);
      return '$names and $remaining others are typing...';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.typingUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Animated typing dots
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDot(0),
                    const SizedBox(width: 3),
                    _buildDot(1),
                    const SizedBox(width: 3),
                    _buildDot(2),
                  ],
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Typing text
              Expanded(
                child: Text(
                  _getTypingText(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDot(int index) {
    final delay = index * 0.2;
    final animationValue = (_animation.value + delay) % 1.0;
    
    double opacity;
    if (animationValue < 0.4) {
      opacity = (animationValue / 0.4).clamp(0.3, 1.0);
    } else if (animationValue < 0.6) {
      opacity = 1.0;
    } else {
      opacity = (1.0 - (animationValue - 0.6) / 0.4).clamp(0.3, 1.0);
    }

    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Simple typing indicator for single user
class SimpleTypingIndicator extends StatelessWidget {
  const SimpleTypingIndicator({
    super.key,
    this.size = 16,
    this.color,
  });

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final indicatorColor = color ?? Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: size * 3,
      height: size,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          return _AnimatedDot(
            size: size * 0.3,
            color: indicatorColor,
            delay: Duration(milliseconds: index * 200),
          );
        }),
      ),
    );
  }
}

class _AnimatedDot extends StatefulWidget {
  const _AnimatedDot({
    required this.size,
    required this.color,
    required this.delay,
  });

  final double size;
  final Color color;
  final Duration delay;

  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color.withOpacity(_animation.value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}