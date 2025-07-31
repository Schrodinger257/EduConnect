import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:educonnect/providers/post_provider.dart';
import 'package:educonnect/widgets/post.dart';
import 'package:educonnect/providers/profile_provider.dart';
import 'dart:io';

import 'package:flutter_svg/svg.dart';

class HomeFeedScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends ConsumerState<HomeFeedScreen> {
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
    final userID = ref.watch(authProvider);
    final Map<String, dynamic> userData = {};
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userID)
                  .snapshots(),
              builder: (ctx, snapShot) {
                if (snapShot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: SvgPicture.asset(
                      'assets/vectors/Loading-pana.svg',
                      height: 300,
                    ),
                  );
                }
                if (snapShot.hasError) {
                  return Center(
                    child: SvgPicture.asset(
                      'assets/vectors/400-Error-Bad-Request-pana.svg',
                      height: 300,
                    ),
                  );
                }
                if (!snapShot.hasData || !snapShot.data!.exists) {
                  return Center(
                    child: SvgPicture.asset(
                      'assets/vectors/404-Error-Page-not-Found-with-people-connecting-a-plug-pana.svg',
                      height: 300,
                    ),
                  );
                }

                userData.addAll(snapShot.data!.data() as Map<String, dynamic>);
                return Card(
                  elevation: 4,
                  shadowColor: Theme.of(context).primaryColor.withAlpha(50),
                  margin: EdgeInsets.all(0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(10),
                      bottomLeft: Radius.circular(10),
                    ),
                  ),
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Container(
                    padding: EdgeInsets.only(left: 10, right: 10, top: 5),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).shadowColor,
                                image: userData['profileImage'] == null
                                    ? null
                                    : DecorationImage(
                                        image: FileImage(
                                          File(userData['profileImage']),
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                            SizedBox(width: 10),
                            SizedBox(
                              child: Column(
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
                                  Wrap(
                                    direction: Axis.horizontal,
                                    children: [
                                      _tag(context, userData['roleCode']),
                                      if (userData['roleCode'] == 'student' &&
                                          userData['grade'] != 'None')
                                        _tag(context, userData['grade']),
                                      if (userData['roleCode'] ==
                                              'instructor' &&
                                          userData['fieldofexpertise'] !=
                                              'Not Assigned Yet')
                                        _tag(
                                          context,
                                          userData['fieldofexpertise'],
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).cardColor,
                                foregroundColor: Theme.of(context).primaryColor,
                                elevation: 0,
                              ),
                              onPressed: () {
                                ref.read(postProvider.notifier).tags.clear();
                                ref
                                    .read(postProvider.notifier)
                                    .createPost(
                                      context,
                                      user: userData,
                                      userId: userID,
                                    );
                              },
                              label: Text(
                                'Create Post',
                                style: TextStyle(fontSize: 12),
                              ),
                              icon: Icon(Icons.add, size: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 20),
            StreamBuilder(
              stream: ref.watch(postProvider.notifier).getPosts(),
              builder: (ctx, snapShot) {
                if (snapShot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapShot.hasError) {
                  return Center(
                    child: SvgPicture.asset(
                      'assets/vectors/400-Error-Bad-Request-pana.svg',
                      height: 300,
                    ),
                  );
                }
                final posts = snapShot.data ?? [];

                if (posts.isEmpty) {
                  return Center(
                    child: SvgPicture.asset(
                      'assets/vectors/No-data-amico.svg',
                      height: 300,
                    ),
                  );
                }
                print(snapShot.data![0]['id']);
                return Expanded(
                  child: ListView.builder(
                    itemCount: posts.length,
                    itemBuilder: (ctx, index) {
                      return PostWidget(
                        post: posts[index],
                        userId: posts[index]['userid'],
                        postID: snapShot.data![index]['id'],
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
