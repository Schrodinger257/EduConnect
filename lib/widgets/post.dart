import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/providers/auth_provider.dart';
import 'package:educonnect/providers/post_provider.dart';
import 'package:educonnect/modules/post.dart';
import 'package:educonnect/screens/comments_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

class PostWidget extends ConsumerStatefulWidget {
  PostWidget({
    super.key,
    required this.post,
    this.isMyPostScreen = false,
  });

  final Post post;
  final bool isMyPostScreen;

  @override
  ConsumerState<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends ConsumerState<PostWidget> {
  Widget _tag(BuildContext context, String tag) {
    return Container(
      margin: EdgeInsets.only(right: 5, bottom: 5),
      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 1),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        tag,
        style: TextStyle(
          color: Theme.of(context).scaffoldBackgroundColor,
          fontSize: 10,
        ),
      ),
    );
  }

  void _toggleLike() async {
    final currentUserId = ref.read(authProvider) as String?;
    if (currentUserId == null) return;
    
    // Call the provider's toggleLike method
    await ref.read(postProvider.notifier).toggleLike(currentUserId, widget.post.id);
  }

  void _showComments() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StreamCommentsScreen(post: widget.post),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(authProvider) as String?;
    final isLiked = currentUserId != null && widget.post.isLikedBy(currentUserId);
    
    Color likeColor = Theme.of(context).primaryColor;
    Color bookmarkColor = Theme.of(context).primaryColor;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.post.userId)
          .snapshots(),
      builder: (ctx, snapShot) {
        return AnimatedSwitcher(
          duration: Duration(seconds: 1),
          child: _buildChild(
            ctx: ctx,
            snapShot: snapShot,
            likeColor: likeColor,
            bookmarkColor: bookmarkColor,
            isLiked: isLiked,
          ),
        );
      },
    );
  }

  Widget _buildChild({
    required BuildContext ctx,
    required AsyncSnapshot snapShot,
    required Color likeColor,
    required Color bookmarkColor,
    required bool isLiked,
  }) {
    if (snapShot.hasError) {
      return SvgPicture.asset('assets/vectors/post-Skeleton Loader.svg');
    }
    if (!snapShot.hasData || !snapShot.data!.exists) {
      return SvgPicture.asset(
        'assets/vectors/post-Skeleton Loader.svg',
        height: 250,
      );
    }

    final userData = snapShot.data!.data() as Map<String, dynamic>;

    return Container(
      key: ValueKey(widget.post.id),
      width: double.infinity,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).shadowColor,
                              image: DecorationImage(
                                image:
                                    userData['profileImage'] == 'default_avatar'
                                    ? AssetImage(
                                        'assets/images/default_avatar.png',
                                      )
                                    : NetworkImage(userData['profileImage']),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userData['name'] ?? 'Unknown User',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).shadowColor,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  DateFormat('dd MMMM yyyy HH:mm')
                                      .format(widget.post.timestamp)
                                      .toString(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).shadowColor.withAlpha(200),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton(
                            itemBuilder: (context) {
                              return [
                                PopupMenuItem(
                                  value: 'Bookmark',
                                  child: Text('Toggle Bookmark'),
                                ),
                                if (widget.isMyPostScreen)
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete Post'),
                                  ),
                              ];
                            },
                            onSelected: (value) async {
                              final currentUserId = ref.read(authProvider) as String?;
                              if (currentUserId == null) return;
                              
                              if (value == 'Bookmark') {
                                await ref
                                    .read(postProvider.notifier)
                                    .toggleBookmark(currentUserId, widget.post.id);
                              } else if (value == 'delete') {
                                await ref
                                    .read(postProvider.notifier)
                                    .deletePost(widget.post.id, widget.post.userId);
                              }
                            },
                          ),
                        ],
                      ),
                      if (widget.post.hasTags)
                        Wrap(
                          direction: Axis.horizontal,
                          children: widget.post.tags
                              .map((tag) => _tag(context, tag))
                              .toList(),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  widget.post.content,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).shadowColor,
                  ),
                ),
                SizedBox(height: 5),
                if (widget.post.hasImage)
                  GestureDetector(
                    onTap: () {
                      showImageViewer(
                        context,
                        Image.network(widget.post.imageUrl!).image,
                        useSafeArea: true,
                        doubleTapZoomable: true,
                        closeButtonColor: Theme.of(context).primaryColor,
                        swipeDismissible: true,
                      );
                    },
                    child: Image.network(
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return SizedBox(
                          height: 250,
                          child: CircularProgressIndicator(
                            color: Theme.of(context).primaryColor,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      (loadingProgress.expectedTotalBytes ?? 1)
                                : null,
                          ),
                        );
                      },
                      widget.post.imageUrl!,
                      fit: BoxFit.cover,
                    ),
                  ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: _toggleLike,
                        label: Text(
                          '${widget.post.likeCount > 0 ? widget.post.likeCount : ''} Like${widget.post.likeCount == 1 ? '' : 's'}',
                          style: TextStyle(
                            color: isLiked
                                ? likeColor
                                : Theme.of(context).shadowColor,
                            fontWeight: isLiked ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        icon: Icon(
                          isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                          color: isLiked
                              ? likeColor
                              : Theme.of(context).shadowColor,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _showComments,
                        label: Text(
                          '${widget.post.commentCount > 0 ? widget.post.commentCount : ''} Comment${widget.post.commentCount == 1 ? '' : 's'}',
                          style: TextStyle(
                            color: Theme.of(context).shadowColor,
                          ),
                        ),
                        icon: Icon(
                          Icons.comment_outlined,
                          color: Theme.of(context).shadowColor,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
          Divider(),
        ],
      ),
    );
  }
}
