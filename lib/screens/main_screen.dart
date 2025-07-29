import 'package:educonnect/widgets/bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:educonnect/providers/screen_provider.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget currentScreen = ref.watch(screenProvider);
    return Scaffold(
      bottomNavigationBar: GoogleBottomBar(),
      body: currentScreen,
    );
  }
}
