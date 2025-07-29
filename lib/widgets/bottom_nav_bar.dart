import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:educonnect/providers/screen_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GoogleBottomBar extends ConsumerStatefulWidget {
  const GoogleBottomBar({super.key});

  @override
  ConsumerState<GoogleBottomBar> createState() => _GoogleBottomBarState();
}

class _GoogleBottomBarState extends ConsumerState<GoogleBottomBar> {
  int _selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    return SalomonBottomBar(
      margin: const EdgeInsets.only(bottom: 20, top: 10),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      currentIndex: _selectedIndex,
      selectedItemColor: const Color(0xff6200ee),
      unselectedItemColor: Theme.of(context).shadowColor,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
          ref.read(screenProvider.notifier).setScreen(index);
        });
      },
      items: _navBarItems(context),
    );
  }
}

List<SalomonBottomBarItem> _navBarItems(BuildContext context) {
  return [
    SalomonBottomBarItem(
      icon: const Icon(Icons.mic_none),
      title: const Text("Announcements"),
      selectedColor: Theme.of(context).primaryColor,
    ),
    SalomonBottomBarItem(
      icon: const Icon(Icons.library_books),
      title: const Text("Courses"),
      selectedColor: Theme.of(context).primaryColor,
    ),
    SalomonBottomBarItem(
      icon: const Icon(Icons.feed),
      title: const Text("Home Feed"),
      selectedColor: Theme.of(context).primaryColor,
    ),
    SalomonBottomBarItem(
      icon: const Icon(Icons.chat_rounded),
      title: const Text("Chat"),
      selectedColor: Theme.of(context).primaryColor,
    ),
    SalomonBottomBarItem(
      icon: const Icon(Icons.person),
      title: const Text("Profile"),
      selectedColor: Theme.of(context).primaryColor,
    ),
  ];
}
