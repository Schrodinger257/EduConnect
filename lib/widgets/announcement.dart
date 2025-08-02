import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/providers/announce_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AnnouncementWidget extends ConsumerStatefulWidget {
  AnnouncementWidget({
    super.key,
    required this.post,
    required this.userId,
    required this.postID,
    this.isMyAnnouncementScreen = false,
  });

  final Map<String, dynamic> post;
  final String userId;
  final String postID;
  final bool isMyAnnouncementScreen;

  @override
  ConsumerState<AnnouncementWidget> createState() => _AnnouncementWidgetState();
}

class _AnnouncementWidgetState extends ConsumerState<AnnouncementWidget> {
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

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> userData = {};

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .snapshots(),
      builder: (ctx, snapShot) {
        return AnimatedSwitcher(
          duration: Duration(milliseconds: 500),
          child: _buildChild(ctx, snapShot, userData),
        );
      },
    );
  }

  Widget _buildChild(
    BuildContext ctx,
    AsyncSnapshot snapShot,
    Map<String, dynamic> userData,
  ) {
    if (snapShot.connectionState == ConnectionState.waiting) {
      return Center(
        child: SvgPicture.asset(
          'assets/vectors/announcement-Skeleton Loader.svg',
          height: 150,
        ),
      );
    }
    if (snapShot.hasError) {
      return Center(
        child: SvgPicture.asset(
          'assets/vectors/announcement-Skeleton Loader.svg',
          height: 150,
        ),
      );
    }
    if (!snapShot.hasData || !snapShot.data!.exists) {
      return Center(
        child: SvgPicture.asset(
          'assets/vectors/announcement-Skeleton Loader.svg',
          height: 150,
        ),
      );
    }

    userData.addAll(snapShot.data!.data() as Map<String, dynamic>);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 0,
      key: ValueKey(widget.postID),
      child: Padding(
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
                            image: userData['profileImage'] == 'default_avatar'
                                ? AssetImage('assets/images/default_avatar.png')
                                : FileImage(File(userData['profileImage'])),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          userData['name'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).shadowColor,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      PopupMenuButton(
                        itemBuilder: (context) {
                          return [
                            PopupMenuItem(
                              value: 'announce',
                              child: Text('Toggle Announcement'),
                            ),
                            if (widget.isMyAnnouncementScreen)
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete Announcement'),
                              ),
                          ];
                        },
                        onSelected: (value) {
                          if (value == 'announce') {
                            // Handle announce post
                            ref
                                .read(announceProvider.notifier)
                                .toggleAnnouncement(
                                  widget.userId,
                                  widget.postID,
                                  context,
                                );
                          } else if (value == 'delete') {
                            // Handle delete post
                            ref
                                .read(announceProvider.notifier)
                                .deleteAnnouncement(context, widget.postID);
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
          ],
        ),
      ),
    );
  }
}
