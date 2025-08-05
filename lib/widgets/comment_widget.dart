import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../modules/comment.dart';
import '../modules/user.dart';
import '../providers/auth_provider.dart';
import '../providers/comment_provider.dart';
import 'comment_moderation_dialog.dart';

class CommentWidget extends ConsumerStatefulWidget {
  final Comment comment;
  final bool canModerate;
  final UserRole? currentUserRole;

  const CommentWidget({
    super.key,
    required this.comment,
    this.canModerate = false,
    this.currentUserRole,
  });

  @override
  ConsumerState<CommentWidget> createState() => _CommentWidgetState();
}

class _CommentWidgetState extends ConsumerState<CommentWidget> {
  bool _isEditing = false;
  late TextEditingController _editController;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.comment.content);
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _editController.text = widget.comment.content;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _editController.text = widget.comment.content;
    });
  }

  void _saveEdit() async {
    final newContent = _editController.text.trim();
    if (newContent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment cannot be empty')),
      );
      return;
    }

    await ref.read(commentProvider.notifier).updateComment(widget.comment, newContent);
    setState(() {
      _isEditing = false;
    });
  }

  void _reportComment() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _ReportCommentDialog(),
    );

    if (reason != null) {
      // In a real implementation, you would send this to a moderation queue
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Comment reported: $reason'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _deleteComment() async {
    final authState = ref.read(authProvider);
    final currentUserId = authState.userId;
    final isOwner = currentUserId == widget.comment.userId;
    final isModerator = widget.canModerate || 
                       widget.currentUserRole == UserRole.instructor || 
                       widget.currentUserRole == UserRole.admin;

    if (isModerator && !isOwner) {
      // Show moderation dialog for moderators
      await showDialog(
        context: context,
        builder: (context) => CommentModerationDialog(
          commentId: widget.comment.id,
          postId: widget.comment.postId,
          commentContent: widget.comment.content,
          onDelete: () {
            ref.read(commentProvider.notifier).deleteComment(
              widget.comment.id,
              widget.comment.postId,
            );
          },
          onModerate: (action, reason) {
            ref.read(commentProvider.notifier).moderateComment(
              widget.comment.id,
              widget.comment.postId,
              action,
              reason: reason,
            );
          },
        ),
      );
    } else {
      // Show simple confirmation for comment owners
      await showDialog(
        context: context,
        builder: (context) => CommentDeleteConfirmationDialog(
          commentContent: widget.comment.content,
          onConfirm: () {
            ref.read(commentProvider.notifier).deleteComment(
              widget.comment.id,
              widget.comment.postId,
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(authProvider) as String?;
    final isOwner = currentUserId == widget.comment.userId;
    final canEdit = isOwner && currentUserId != null && widget.comment.canBeEditedBy(currentUserId);
    final isModerator = widget.canModerate || 
                       widget.currentUserRole == UserRole.instructor || 
                       widget.currentUserRole == UserRole.admin;
    final canDelete = isOwner || isModerator;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.comment.userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return _buildCommentSkeleton();
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User info and timestamp
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: userData['profileImage'] == 'default_avatar'
                        ? const AssetImage('assets/images/default_avatar.png')
                        : NetworkImage(userData['profileImage']) as ImageProvider,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userData['name'] ?? 'Unknown User',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              widget.comment.formattedTimestamp,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                            if (widget.comment.isEdited) ...[
                              const SizedBox(width: 4),
                              Text(
                                '(${widget.comment.formattedEditTimestamp})',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (canEdit || canDelete)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _startEditing();
                            break;
                          case 'delete':
                            _deleteComment();
                            break;
                          case 'report':
                            _reportComment();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        if (canEdit)
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 16),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                        if (canDelete)
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 16, color: Colors.red),
                                const SizedBox(width: 8),
                                Text(
                                  isModerator && !isOwner ? 'Moderate' : 'Delete',
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        if (!isOwner && !isModerator)
                          const PopupMenuItem(
                            value: 'report',
                            child: Row(
                              children: [
                                Icon(Icons.flag, size: 16, color: Colors.orange),
                                SizedBox(width: 8),
                                Text('Report', style: TextStyle(color: Colors.orange)),
                              ],
                            ),
                          ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Comment content
              if (_isEditing)
                Column(
                  children: [
                    TextField(
                      controller: _editController,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Edit your comment...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        contentPadding: const EdgeInsets.all(12.0),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _cancelEditing,
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _saveEdit,
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  ],
                )
              else
                Text(
                  widget.comment.content,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentSkeleton() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).dividerColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 12,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 14,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportCommentDialog extends StatefulWidget {
  @override
  State<_ReportCommentDialog> createState() => _ReportCommentDialogState();
}

class _ReportCommentDialogState extends State<_ReportCommentDialog> {
  String _selectedReason = 'inappropriate';
  final TextEditingController _customReasonController = TextEditingController();

  final List<Map<String, String>> _reportReasons = [
    {'value': 'inappropriate', 'label': 'Inappropriate content'},
    {'value': 'spam', 'label': 'Spam or repetitive'},
    {'value': 'harassment', 'label': 'Harassment or bullying'},
    {'value': 'misinformation', 'label': 'False information'},
    {'value': 'off_topic', 'label': 'Off-topic or irrelevant'},
    {'value': 'other', 'label': 'Other (please specify)'},
  ];

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Report Comment'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Why are you reporting this comment?'),
            const SizedBox(height: 16),
            ..._reportReasons.map((reason) {
              return RadioListTile<String>(
                value: reason['value']!,
                groupValue: _selectedReason,
                onChanged: (value) {
                  setState(() {
                    _selectedReason = value!;
                  });
                },
                title: Text(reason['label']!),
                contentPadding: EdgeInsets.zero,
              );
            }),
            if (_selectedReason == 'other') ...[
              const SizedBox(height: 8),
              TextField(
                controller: _customReasonController,
                decoration: const InputDecoration(
                  labelText: 'Please specify',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            String reason = _reportReasons
                .firstWhere((r) => r['value'] == _selectedReason)['label']!;
            
            if (_selectedReason == 'other' && _customReasonController.text.trim().isNotEmpty) {
              reason = _customReasonController.text.trim();
            }
            
            Navigator.of(context).pop(reason);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: const Text('Report'),
        ),
      ],
    );
  }
}