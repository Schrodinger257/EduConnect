import 'package:educonnect/providers/auth_provider.dart';
import 'package:educonnect/providers/post_provider.dart';
import 'package:educonnect/widgets/post.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MyPostsScreen extends ConsumerStatefulWidget {
  const MyPostsScreen({super.key});

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
        final authState = ref.read(authProvider);
        final userId = authState.userId;
        if (userId != null) {
          ref
              .read(ownPostProvider.notifier)
              .getOwnPosts(userId);
        }
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
    // 1. Use `ref.read` inside listeners to avoid rebuilding the widget on state change.
    final postState = ref.read(ownPostProvider);
    final authState = ref.read(authProvider);
    final userId = authState.userId;
    
    if (userId == null) return;
    
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.9 &&
        !postState.isLoading &&
        postState.hasMore) {
      ref
          .read(ownPostProvider.notifier)
          .getOwnPosts(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userId = authState.userId;
    
    if (userId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to access your posts'),
        ),
      );
    }
    
    final posts = ref.watch(ownPostProvider.select((state) => state.posts));
    final isLoading = ref.watch(
      ownPostProvider.select((state) => state.isLoading),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Posts',
          style: TextStyle(color: Theme.of(context).primaryColor),
        ),
      ),
      body: RefreshIndicator(
        // 3. Add the onRefresh callback.
        // This assumes you have a `refreshOwnPosts` method in your provider.
        onRefresh: () =>
            ref.read(ownPostProvider.notifier).refreshOwnPosts(userId),
        child: (posts.isEmpty && !isLoading)
            // 4. Handle the empty state correctly to allow pull-to-refresh.
            ? LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
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
            // 5. The ListView for when there are posts.
            : ListView.builder(
                controller: _scrollController,
                itemCount: posts.length + (isLoading ? 1 : 0),
                itemBuilder: (ctx, index) {
                  if (index >= posts.length) {
                    // This is the loading indicator at the bottom of the list.
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final post = posts[index];
                  // 6. Add a ValueKey for performance.
                  return PostWidget(
                    key: ValueKey(post.id),
                    post: post,
                    isMyPostScreen: true,
                  );
                },
              ),
      ),
    );
  }
}
