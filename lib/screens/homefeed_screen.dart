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
  const HomeFeedScreen({super.key});
  @override
  ConsumerState<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends ConsumerState<HomeFeedScreen> {
  final _scrollController = ScrollController();

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
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // It's now safe to use ref here.
      // Also, check if the posts list inside the state is empty.
      if (ref.read(postProvider).posts.isEmpty) {
        ref.read(postProvider.notifier).getPosts();
      }
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final postState = ref.watch(postProvider);
    final postNotifier = ref.watch(postProvider.notifier);

    // 3. The core logic for fetching more posts
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent *
                0.9 && // Trigger slightly before the end
        !postState.isLoading &&
        postState.hasMore) {
      // Use ref.read to trigger the fetch action
      postNotifier.getPosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userID = ref.watch(authProvider);
    final Map<String, dynamic> userData = {};
    final postState = ref.watch(postProvider);
    final postNotifier = ref.watch(postProvider.notifier);
    final posts = postState.posts;
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
                  return Center(child: Text('loading...'));
                }
                if (snapShot.hasError) {
                  return Center(child: Text('Error loading user data'));
                }
                if (!snapShot.hasData || !snapShot.data!.exists) {
                  return Center(child: Text('No user data available'));
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
                                postNotifier.tags.clear();
                                postNotifier.createPost(
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
            NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollinfo) {
                if (!postState.isLoading &&
                    postState.hasMore &&
                    scrollinfo.metrics.pixels ==
                        scrollinfo.metrics.maxScrollExtent) {
                  postNotifier.getPosts();
                }
                return false;
              },
              child: Expanded(
                child: Column(
                  children: [
                    if (posts.isEmpty && !postState.isLoading)
                      Center(
                        child: SvgPicture.asset(
                          'assets/vectors/No-data-amico.svg',
                          height: 300,
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: posts.length + (postState.isLoading ? 1 : 0),
                        itemBuilder: (ctx, index) {
                          if (index == posts.length && postState.isLoading) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final post = posts[index];
                          return PostWidget(
                            post: post,
                            userId: post['userid'],
                            postID: post['id'],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
