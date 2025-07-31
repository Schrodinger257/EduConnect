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
  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Posts',
          style: TextStyle(color: Theme.of(context).primaryColor),
        ),
      ),
      body: StreamBuilder(
        stream: ref.read(postProvider.notifier).getOwnPosts(userId),
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
              child: Center(
                child: SvgPicture.asset(
                  'assets/vectors/400-Error-Bad-Request-pana.svg',
                  height: 300,
                ),
              ),
            );
          }
          if (!snapShot.hasData || snapShot.data!.isEmpty) {
            return Center(
              child: Center(
                child: SvgPicture.asset(
                  'assets/vectors/404-Error-Page-not-Found-with-people-connecting-a-plug-pana.svg',
                  height: 300,
                ),
              ),
            );
          }

          final posts = snapShot.data ?? [];

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (ctx, index) {
              return PostWidget(
                post: posts[index],
                userId: posts[index]['userid'],
                postID: snapShot.data![index]['id'],
                isMyPostScreen: true,
              );
            },
          );
        },
      ),
    );
  }
}
