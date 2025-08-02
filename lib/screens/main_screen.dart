import 'package:educonnect/providers/auth_provider.dart';
import 'package:educonnect/providers/profile_provider.dart';
import 'package:educonnect/screens/Announcement_screen.dart';
import 'package:educonnect/screens/chat_screen.dart';
import 'package:educonnect/screens/courses_screen.dart';
import 'package:educonnect/screens/homefeed_screen.dart';
import 'package:educonnect/screens/profile_screen.dart';
import 'package:educonnect/widgets/bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:educonnect/providers/screen_provider.dart';

class MainScreen extends ConsumerStatefulWidget {
  MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  List<Widget> screens = [
    AnnouncementScreen(),
    CoursesScreen(),
    HomeFeedScreen(),
    ChatScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    // TODO: implement initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(profileProvider.notifier)
          .getUserData(ref.read(authProvider) as String);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget currentScreen = ref.watch(screenProvider);
    return Scaffold(
      bottomNavigationBar: GoogleBottomBar(
        ref.watch(screenProvider.notifier).index,
      ),
      body: currentScreen,
    );
  }
}
