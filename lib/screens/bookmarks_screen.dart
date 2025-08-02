import 'package:educonnect/providers/auth_provider.dart';
import 'package:educonnect/providers/post_provider.dart';
import 'package:educonnect/widgets/post.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BookmarksScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends ConsumerState<BookmarksScreen> {
  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Bookmarked Posts',
          style: TextStyle(color: Theme.of(context).primaryColor),
        ),
      ),
      // ...existing code...
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // Use the provider method which already returns the filtered list of posts.
        stream: ref
            .watch(postProvider.notifier)
            .getBookmarkedPosts(userId as String),
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
              // Ensure your PostWidget can handle the data structure
              return PostWidget(
                post:
                    bookmarkedPosts[index], // Assuming 'post' is a map with post data
                userId:
                    bookmarkedPosts[index]['userid'], // Assuming 'userId' is in the post map
                postID:
                    bookmarkedPosts[index]['id'], // Assuming 'id' is in the post map
              );
            },
          );
        },
      ),
    );
  }
}
