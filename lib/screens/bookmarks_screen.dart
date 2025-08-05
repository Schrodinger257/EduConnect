import 'package:educonnect/providers/auth_provider.dart';
import 'package:educonnect/providers/post_provider.dart';
import 'package:educonnect/modules/post.dart';
import 'package:educonnect/widgets/post.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BookmarksScreen extends ConsumerStatefulWidget {
  const BookmarksScreen({super.key});

  @override
  ConsumerState<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends ConsumerState<BookmarksScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userId = authState.userId;
    
    if (userId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to access bookmarks'),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Bookmarked Posts',
          style: TextStyle(color: Theme.of(context).primaryColor),
        ),
      ),
      // ...existing code...
      body: StreamBuilder<List<Post>>(
        // Use the provider method which already returns the filtered list of posts.
        stream: ref
            .watch(postProvider.notifier)
            .getBookmarkedPosts(userId),
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
            print('Bookmark Screen Error: ${snapShot.error}');
            return Center(
              child: SvgPicture.asset(
                'assets/vectors/400-Error-Bad-Request-pana.svg',
                height: 300,
              ),
            );
          }
          if (!snapShot.hasData || snapShot.data!.isEmpty) {
            return Center(
              child: SvgPicture.asset(
                'assets/vectors/No-data-amico.svg', // More appropriate image
                height: 300,
                semanticsLabel: 'No Bookmarks Found',
              ),
            );
          }

          // The snapshot data IS the final list of bookmarked posts.
          // No extra fetching or filtering is needed here.
          final bookmarkedPosts = snapShot.data!;

          return ListView.builder(
            itemCount: bookmarkedPosts.length,
            itemBuilder: (ctx, index) {
              // PostWidget now uses the Post model directly
              return PostWidget(
                key: ValueKey(bookmarkedPosts[index].id),
                post: bookmarkedPosts[index],
              );
            },
          );
        },
      ),
    );
  }
}
