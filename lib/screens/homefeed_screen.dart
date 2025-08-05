import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:educonnect/providers/post_provider.dart';
import 'package:educonnect/widgets/post.dart';
import 'package:educonnect/screens/search_screen.dart';

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
    final postState = ref.read(postProvider); // Use read inside a listener
    // The logic here is correct. No changes needed.
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.9 &&
        !postState.isLoading &&
        postState.hasMore) {
      ref.read(postProvider.notifier).getPosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userID = authState.userId;
    
    if (userID == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to access this screen'),
        ),
      );
    }
    
    final Map<String, dynamic> userData = {};
    final postState = ref.watch(postProvider);
    final posts = ref.watch(postProvider.select((state) => state.posts));
    final isLoading = ref.watch(
      postProvider.select((state) => state.isLoading),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Home Feed',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SearchScreen(),
                ),
              );
            },
          ),
        ],
      ),
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
                                image: userData['profileImage'] != null &&
                                        userData['profileImage'] != 'default_avatar'
                                    ? DecorationImage(
                                        image: NetworkImage(userData['profileImage']),
                                        fit: BoxFit.cover,
                                      )
                                    : DecorationImage(
                                        image: AssetImage(
                                          'assets/images/default_avatar.png',
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
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
                                  Wrap(
                                    direction: Axis.horizontal,
                                    children: [
                                      _tag(context, userData['roleCode'] ?? 'user'),
                                      if (userData['roleCode'] == 'student' &&
                                          userData['grade'] != null &&
                                          userData['grade'] != 'None')
                                        _tag(context, userData['grade']),
                                      if (userData['roleCode'] == 'instructor' &&
                                          userData['fieldofexpertise'] != null &&
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
                                ref.read(postProvider.notifier).showCreatePostModal(context, userID);
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
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.read(postProvider.notifier).refreshPosts(),
                child: (posts.isEmpty && !isLoading)
                    ? LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            physics: AlwaysScrollableScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: Center(
                                child: SvgPicture.asset(
                                  'assets/vectors/No-data-amico.svg',
                                  height: 300,
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        // Use the `isLoading` variable we selected earlier
                        itemCount: posts.length + (isLoading ? 1 : 0),
                        itemBuilder: (ctx, index) {
                          if (index >= posts.length) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final post = posts[index];
                          // 2. THE FIX: Add a ValueKey using the unique post ID.
                          // This tells Flutter how to identify each PostWidget,
                          // preventing it from rebuilding existing ones when new posts are added.
                          return PostWidget(
                            key: ValueKey(post.id),
                            post: post,
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
