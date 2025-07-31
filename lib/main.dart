import 'package:educonnect/screens/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData().copyWith(
        primaryColor: const Color.fromARGB(255, 255, 114, 94),
        shadowColor: const Color.fromARGB(255, 69, 90, 100),
        cardColor: const Color.fromARGB(255, 255, 214, 209),
        scaffoldBackgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      home: AuthScreen(),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: const Color.fromARGB(255, 0, 135, 139),
        shadowColor: const Color.fromARGB(255, 255, 252, 248),
        cardColor: const Color.fromARGB(255, 153, 219, 221),
        scaffoldBackgroundColor: const Color.fromARGB(255, 34, 44, 49),
      ),
      themeMode: ThemeMode.system,
    );
  }
}
