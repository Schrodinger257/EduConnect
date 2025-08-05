
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
  const PostWidget({
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
    final authState = ref.read(authProvider);
    final currentUserId = authState.userId;
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

  /// Helper method to get the appropriate image provider for post images
  ImageProvider _getPostImageProvider(String imageUrl) {
    print('Post image URL: $imageUrl'); // Debug log
    
    // Check if it's a local file path (starts with /data/ or file://)
    if (imageUrl.startsWith('/data/') || imageUrl.startsWith('file://')) {
      print('Using FileImage for local path'); // Debug log
      // For local files, use FileImage
      return FileImage(File(imageUrl.replaceFirst('file://', '')));
    }
    
    // Check if it's a valid URL (starts with http:// or https://)
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      print('Using NetworkImage for URL'); // Debug log
      return NetworkImage(imageUrl);
    }
    
    print('Using NetworkImage as fallback'); // Debug log
    // If it's neither, treat it as a network image (fallback)
    return NetworkImage(imageUrl);
  }

  /// Helper method to get the appropriate image provider for profile images
  ImageProvider _getProfileImageProvider(dynamic profileImage) {
    // Handle null or empty profile image
    if (profileImage == null || 
        profileImage == '' || 
        profileImage == 'default_avatar') {
      return AssetImage('assets/images/default_avatar.png');
    }
    
    // Convert to string safely
    String imageUrl = profileImage.toString();
    
    // Check if it's a local file path (starts with /data/ or file://)
    if (imageUrl.startsWith('/data/') || imageUrl.startsWith('file://')) {
      // For local files, use FileImage
      return FileImage(File(imageUrl.replaceFirst('file://', '')));
    }
    
    // Check if it's a valid URL (starts with http:// or https://)
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return NetworkImage(imageUrl);
    }
    
    // Default fallback
    return AssetImage('assets/images/default_avatar.png');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final currentUserId = authState.userId;
    final isLiked = currentUserId != null && widget.post.isLikedBy(currentUserId);
    
    Color likeColor = Theme.of(context).primaryColor;
    Color bookmarkColor = Theme.of(context).primaryColor;

    // Check if userId is valid before using it
    if (widget.post.userId.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Error: Invalid post data - missing user ID',
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }

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

    return SizedBox(
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
                                image: _getProfileImageProvider(userData['profileImage']),
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
                              final authState = ref.read(authProvider);
                              final currentUserId = authState.userId;
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
                // Debug logging
                Builder(
                  builder: (context) {
                    print('Post ${widget.post.id} hasImage: ${widget.post.hasImage}');
                    print('Post ${widget.post.id} imageUrl: ${widget.post.imageUrl}');
                    return SizedBox.shrink();
                  },
                ),
                if (widget.post.hasImage)
                  GestureDetector(
                    onTap: () {
                      showImageViewer(
                        context,
                        _getPostImageProvider(widget.post.imageUrl!),
                        useSafeArea: true,
                        doubleTapZoomable: true,
                        closeButtonColor: Theme.of(context).primaryColor,
                        swipeDismissible: true,
                      );
                    },
                    child: Image(
                      image: _getPostImageProvider(widget.post.imageUrl!),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return SizedBox(
                          height: 250,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Theme.of(context).primaryColor,
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        (loadingProgress.expectedTotalBytes ?? 1)
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.grey[300],
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image, size: 50, color: Colors.grey[600]),
                                SizedBox(height: 8),
                                Text(
                                  'Failed to load image',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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
