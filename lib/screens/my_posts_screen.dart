import 'package:educonnect/providers/auth_provider.dart';
import 'package:educonnect/providers/post_provider.dart';
import 'package:educonnect/widgets/post.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MyPostsScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends ConsumerState<MyPostsScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // It's now safe to use ref here.
      // Also, check if the posts list inside the state is empty.
      if (ref.read(ownPostProvider).posts.isEmpty) {
        ref
            .read(ownPostProvider.notifier)
            .getOwnPosts(ref.read(authProvider) as String);
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
    final postState = ref.watch(ownPostProvider);
    final postNotifier = ref.watch(ownPostProvider.notifier);
    final userId = ref.watch(authProvider);
    // 3. The core logic for fetching more posts
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent *
                0.9 && // Trigger slightly before the end
        !postState.isLoading &&
        postState.hasMore) {
      // Use ref.read to trigger the fetch action
      postNotifier.getOwnPosts(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final postState = ref.watch(ownPostProvider);
    final postNotifier = ref.watch(ownPostProvider.notifier);
    final userId = ref.watch(authProvider);
    final posts = postState.posts;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Posts',
          style: TextStyle(color: Theme.of(context).primaryColor),
        ),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollinfo) {
          if (!postState.isLoading &&
              postState.hasMore &&
              scrollinfo.metrics.pixels == scrollinfo.metrics.maxScrollExtent) {
            postNotifier.getOwnPosts(userId);
          }
          return false;
        },
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
    );
  }
}
