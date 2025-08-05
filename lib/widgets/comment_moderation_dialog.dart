import 'package:flutter/material.dart';

class CommentModerationDialog extends StatefulWidget {
  final String commentId;
  final String postId;
  final String commentContent;
  final VoidCallback onDelete;
  final Function(String action, String? reason) onModerate;

  const CommentModerationDialog({
    super.key,
    required this.commentId,
    required this.postId,
    required this.commentContent,
    required this.onDelete,
    required this.onModerate,
  });

  @override
  State<CommentModerationDialog> createState() => _CommentModerationDialogState();
}

class _CommentModerationDialogState extends State<CommentModerationDialog> {
  final TextEditingController _reasonController = TextEditingController();
  String _selectedAction = 'delete';
  
  final List<Map<String, dynamic>> _moderationActions = [
    {
      'value': 'delete',
      'label': 'Delete Comment',
      'icon': Icons.delete,
      'color': Colors.red,
      'description': 'Permanently remove this comment',
    },
    {
      'value': 'hide',
      'label': 'Hide Comment',
      'icon': Icons.visibility_off,
      'color': Colors.orange,
      'description': 'Hide comment from public view',
    },
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Moderate Comment'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Comment preview
            Container(
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
                  Text(
                    'Comment:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.commentContent,
                    style: const TextStyle(fontSize: 14),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Moderation actions
            Text(
              'Select Action:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Theme.of(context).textTheme.titleMedium?.color,
              ),
            ),
            const SizedBox(height: 8),
            
            ..._moderationActions.map((action) {
              return RadioListTile<String>(
                value: action['value'],
                groupValue: _selectedAction,
                onChanged: (value) {
                  setState(() {
                    _selectedAction = value!;
                  });
                },
                title: Row(
                  children: [
                    Icon(
                      action['icon'],
                      color: action['color'],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(action['label']),
                  ],
                ),
                subtitle: Text(
                  action['description'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                contentPadding: EdgeInsets.zero,
              );
            }).toList(),
            
            const SizedBox(height: 16),
            
            // Reason field
            TextField(
              controller: _reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Reason (Optional)',
                hintText: 'Provide a reason for this moderation action...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                contentPadding: const EdgeInsets.all(12.0),
              ),
            ),
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
            final reason = _reasonController.text.trim();
            widget.onModerate(
              _selectedAction,
              reason.isEmpty ? null : reason,
            );
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _moderationActions
                .firstWhere((action) => action['value'] == _selectedAction)['color'],
            foregroundColor: Colors.white,
          ),
          child: Text(_moderationActions
              .firstWhere((action) => action['value'] == _selectedAction)['label']),
        ),
      ],
    );
  }
}

class CommentDeleteConfirmationDialog extends StatelessWidget {
  final String commentContent;
  final VoidCallback onConfirm;

  const CommentDeleteConfirmationDialog({
    super.key,
    required this.commentContent,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Comment'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Are you sure you want to delete this comment?'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.3),
              ),
            ),
            child: Text(
              commentContent,
              style: const TextStyle(fontSize: 14),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'This action cannot be undone.',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).errorColor,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            onConfirm();
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}