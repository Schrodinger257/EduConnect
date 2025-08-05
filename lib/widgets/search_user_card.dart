import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../modules/user.dart';
import '../widgets/highlighted_text.dart';

class SearchUserCard extends ConsumerWidget {
  final User user;
  final String query;

  const SearchUserCard({
    super.key,
    required this.user,
    this.query = '',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Navigate to user profile
          // Navigate to user profile - would need to be implemented
          // For now, just show a placeholder
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Navigate to ${user.name}\'s profile')),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              _buildProfileImage(context),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HighlightedText(
                      text: user.name,
                      query: query,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).shadowColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildRoleBadge(context),
                    const SizedBox(height: 8),
                    if (user.department != null) ...[
                      _buildInfoRow(
                        context,
                        Icons.business,
                        user.department!,
                        query,
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (user.fieldOfExpertise != null) ...[
                      _buildInfoRow(
                        context,
                        Icons.school,
                        user.fieldOfExpertise!,
                        query,
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (user.grade != null) ...[
                      _buildInfoRow(
                        context,
                        Icons.grade,
                        'Grade ${user.grade}',
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).shadowColor.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).shadowColor.withOpacity(0.1),
        image: user.profileImage != null && user.profileImage != 'default_avatar'
            ? DecorationImage(
                image: NetworkImage(user.profileImage!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: user.profileImage == null || user.profileImage == 'default_avatar'
          ? Icon(
              Icons.person,
              size: 30,
              color: Theme.of(context).shadowColor.withOpacity(0.5),
            )
          : null,
    );
  }

  Widget _buildRoleBadge(BuildContext context) {
    Color roleColor;
    IconData roleIcon;
    
    switch (user.role) {
      case UserRole.instructor:
        roleColor = Colors.blue;
        roleIcon = Icons.school;
        break;
      case UserRole.student:
        roleColor = Colors.green;
        roleIcon = Icons.person;
        break;
      case UserRole.admin:
        roleColor = Colors.orange;
        roleIcon = Icons.admin_panel_settings;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: roleColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: roleColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            roleIcon,
            size: 12,
            color: roleColor,
          ),
          const SizedBox(width: 4),
          Text(
            user.roleDisplayName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: roleColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text, String query) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: Theme.of(context).shadowColor.withOpacity(0.6),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: HighlightedText(
            text: text,
            query: query,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).shadowColor.withOpacity(0.8),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}