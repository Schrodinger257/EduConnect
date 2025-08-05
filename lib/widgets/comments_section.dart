import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../modules/comment.dart';
import '../modules/user.dart';
import '../providers/comment_provider.dart';
import 'comment_widget.dart';
import 'comment_input.dart';

class CommentsSection extends ConsumerStatefulWidget {
  final String postId;
  final bool canModerate;
  final UserRole? currentUserRole;

  const CommentsSection({
    super.key,
    required this.postId,
    this.canModerate = false,
    this.currentUserRole,
  });

  @override
  ConsumerState<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends ConsumerState<CommentsSection> {
  @override
  void initState() {
    super.initState();
    // Load comments when the widget is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(commentProvider.notifier).loadComments(widget.postId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Comments list
        Expanded(
          child: StreamBuilder<List<Comment>>(
            stream: ref.read(commentProvider.notifier).getCommentsStream(widget.postId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading comments',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(commentProvider.notifier).loadComments(widget.postId);
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final comments = snapshot.data ?? [];

              if (comments.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.comment_outlined,
                        size: 48,
                        color: Theme.of(context).disabledColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No comments yet',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Be the first to comment!',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await ref.read(commentProvider.notifier).loadComments(widget.postId);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return CommentWidget(
                      key: ValueKey(comment.id),
                      comment: comment,
                      canModerate: widget.canModerate,
                      currentUserRole: widget.currentUserRole,
                    );
                  },
                ),
              );
            },
          ),
        ),
        
        // Comment input
        CommentInput(
          postId: widget.postId,
          onCommentAdded: () {
            // Optionally scroll to bottom or show feedback
          },
        ),
      ],
    );
  }
}

class CommentsBottomSheet extends ConsumerWidget {
  final String postId;
  final bool canModerate;
  final UserRole? currentUserRole;

  const CommentsBottomSheet({
    super.key,
    required this.postId,
    this.canModerate = false,
    this.currentUserRole,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16.0),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Text(
                      'Comments',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1),
              
              // Comments section
              Expanded(
                child: CommentsSection(
                  postId: postId,
                  canModerate: canModerate,
                  currentUserRole: currentUserRole,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static void show(BuildContext context, String postId, {bool canModerate = false, UserRole? currentUserRole}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsBottomSheet(
        postId: postId,
        canModerate: canModerate,
        currentUserRole: currentUserRole,
      ),
    );
  }
}