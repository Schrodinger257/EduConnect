import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/providers/auth_provider.dart';
import 'package:educonnect/providers/post_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

class PostWidget extends ConsumerStatefulWidget {
  PostWidget({
    super.key,
    required this.post,
    required this.userId,
    required this.postID,
    this.isMyPostScreen = false,
  });

  final Map<String, dynamic> post;
  final String userId;
  final String postID;
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

  bool isLiked = false;

  void _toggleLike() {
    setState(() {
      isLiked = !isLiked;
    });
  }

  @override
  Widget build(BuildContext context) {
    Color likeColor = Theme.of(context).primaryColor;
    Color bookmarkColor = Theme.of(context).primaryColor;
    final Map<String, dynamic> userData = {};
    Map<String, dynamic> mainUser = {};

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .snapshots(),
      builder: (ctx, snapShot) {
        return AnimatedSwitcher(
          duration: Duration(milliseconds: 500),
          child: _buildChild(
            ctx: ctx,
            snapShot: snapShot,
            userData: userData,
            mainUser: mainUser,
            likeColor: likeColor,
            bookmarkColor: bookmarkColor,
          ),
        );
      },
    );
  }

  Widget _buildChild({
    required BuildContext ctx,
    required AsyncSnapshot snapShot,
    required Map<String, dynamic> userData,
    required Map<String, dynamic> mainUser,
    required Color likeColor,
    required Color bookmarkColor,
  }) {
    if (snapShot.hasError) {
      return Center(
        child: SvgPicture.asset(
          'assets/vectors/post-Skeleton Loader.svg',
          height: 300,
        ),
      );
    }
    if (!snapShot.hasData || !snapShot.data!.exists) {
      return Center(
        child: SvgPicture.asset(
          'assets/vectors/post-Skeleton Loader.svg',
          height: 300,
        ),
      );
    }

    userData.addAll(snapShot.data!.data() as Map<String, dynamic>);
    print(mainUser);

    return AnimatedOpacity(
      duration: Duration(milliseconds: 500),
      opacity: 1.0,
      child: Container(
        key: ValueKey(widget.postID),
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
                                      userData['profileImage'] ==
                                          'default_avatar'
                                      ? AssetImage(
                                          'assets/images/default_avatar.png',
                                        )
                                      : FileImage(
                                          File(userData['profileImage']),
                                        ),

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
                                    userData['name'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).shadowColor,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('dd MMMM yyyy HH:mm')
                                        .format(
                                          DateTime.fromMillisecondsSinceEpoch(
                                            widget
                                                .post['timestamp']
                                                .millisecondsSinceEpoch,
                                          ),
                                        )
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
                              onSelected: (value) {
                                if (value == 'Bookmark') {
                                  // Handle Bookmark post
                                  ref
                                      .read(postProvider.notifier)
                                      .toggleBookmark(
                                        ref.read(authProvider) as String,
                                        widget.postID,
                                        context,
                                      );
                                } else if (value == 'delete') {
                                  // Handle delete post
                                  ref
                                      .read(postProvider.notifier)
                                      .deletePost(context, widget.postID);
                                }
                              },
                            ),
                          ],
                        ),
                        Wrap(
                          direction: Axis.horizontal,
                          children: (widget.post['tags'] as List)
                              .map((tag) => _tag(context, tag))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    widget.post['content'],
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).shadowColor,
                    ),
                  ),
                  SizedBox(height: 5),
                  if (widget.post['image'] != null)
                    GestureDetector(
                      onTap: () {
                        showImageViewer(
                          context,
                          Image.file(File(widget.post['image'])).image,
                          useSafeArea: true,
                          doubleTapZoomable: true,
                          closeButtonColor: Theme.of(context).primaryColor,
                          swipeDismissible: true,
                        );
                      },
                      child: Image.file(
                        File(widget.post['image']),
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
                          onPressed: () {
                            _toggleLike();
                          },
                          label: Text(
                            'Like',
                            style: TextStyle(
                              color: isLiked
                                  ? likeColor
                                  : Theme.of(context).shadowColor,
                            ),
                          ),
                          icon: Icon(
                            Icons.thumb_up,
                            color: isLiked
                                ? likeColor
                                : Theme.of(context).shadowColor,
                          ),
                        ),

                        TextButton.icon(
                          onPressed: () {
                            _toggleLike();
                          },
                          label: Text(
                            'Comments',
                            style: TextStyle(
                              color: Theme.of(context).shadowColor,
                            ),
                          ),
                          icon: Icon(
                            Icons.comment,
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
      ),
    );
  }
}
