import 'package:educonnect/providers/auth_provider.dart';
import 'package:educonnect/providers/announce_provider.dart';
import 'package:educonnect/widgets/announcement.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MyAnnouncementScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyAnnouncementScreen> createState() =>
      _MyAnnouncementScreenState();
}

class _MyAnnouncementScreenState extends ConsumerState<MyAnnouncementScreen> {
  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Announcements',
          style: TextStyle(color: Theme.of(context).primaryColor),
        ),
      ),
      body: StreamBuilder(
        stream: ref.read(announceProvider.notifier).getOwnAnnouncements(userId),
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

          final announcements = snapShot.data ?? [];

          return ListView.builder(
            itemCount: announcements.length,
            itemBuilder: (ctx, index) {
              return AnnouncementWidget(
                post: announcements[index],
                userId: announcements[index]['userid'],
                postID: snapShot.data![index]['id'],
                isMyAnnouncementScreen: true,
              );
            },
          );
        },
      ),
    );
  }
}
