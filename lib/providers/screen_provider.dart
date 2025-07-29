import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import 'package:educonnect/screens/Announcement_screen.dart';
import 'package:educonnect/screens/courses_screen.dart';
import 'package:educonnect/screens/homefeed_screen.dart';
import 'package:educonnect/screens/chat_screen.dart';
import 'package:educonnect/screens/profile_screen.dart';

class ScreenProvider extends StateNotifier<Widget> {
  ScreenProvider() : super(HomeFeedScreen());

  List<Widget> screens = [
    AnnouncementScreen(),
    CoursesScreen(),
    HomeFeedScreen(),
    ChatScreen(),
    ProfileScreen(),
  ];

  void setScreen(int index) {
    state = screens[index];
  }
}

final screenProvider = StateNotifierProvider<ScreenProvider, Widget>((ref) {
  return ScreenProvider();
});
