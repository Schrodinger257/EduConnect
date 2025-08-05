import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../modules/post.dart';
import '../modules/user.dart';
import '../providers/auth_provider.dart';
import '../widgets/comments_section.dart';

class StreamCommentsScreen extends ConsumerWidget {
  final Post post;

  const StreamCommentsScreen({
    super.key,
    required this.post,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(authProvider) as String?;
    
    if (currentUserId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Comments'),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
        ),
        body: const Center(
          child: Text('Please log in to view comments'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comments'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          UserRole? currentUserRole;
          bool canModerate = currentUserId == post.userId; // Post author can moderate

          if (snapshot.hasData && snapshot.data!.exists) {
            final userData = snapshot.data!.data() as Map<String, dynamic>;
            final roleString = userData['role'] as String?;
            
            if (roleString != null) {
              try {
                currentUserRole = UserRole.fromString(roleString);
                // Instructors and admins can moderate all comments
                canModerate = canModerate || 
                             currentUserRole == UserRole.instructor || 
                             currentUserRole == UserRole.admin;
              } catch (e) {
                // Handle invalid role gracefully
                currentUserRole = null;
              }
            }
          }

          return CommentsSection(
            postId: post.id,
            canModerate: canModerate,
            currentUserRole: currentUserRole,
          );
        },
      ),
    );
  }
}