import 'package:educonnect/screens/nav_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Supabase.initialize(
    url: 'https://cfqiasiclorneohrejlm.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNmcWlhc2ljbG9ybmVvaHJlamxtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQzMTU2NjUsImV4cCI6MjA2OTg5MTY2NX0.s6H2iF7AZoHDrVHsA3UGI4iSR5UEWbqcMMdJA6j3oUs',
  );
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
        cardTheme: CardThemeData(
          color: const Color.fromARGB(255, 255, 214, 209),
          shadowColor: const Color.fromARGB(255, 69, 90, 100),
        ),
      ),
      home: NavScreen(),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: const Color.fromARGB(255, 255, 114, 94),
        shadowColor: const Color.fromARGB(255, 255, 252, 248),
        cardColor: const Color.fromARGB(255, 104, 52, 45),
        scaffoldBackgroundColor: const Color.fromARGB(255, 23, 25, 32),
        cardTheme: CardThemeData(
          color: const Color.fromARGB(255, 34, 37, 48),
          shadowColor: const Color.fromARGB(255, 139, 37, 37),
        ),
      ),
      themeMode: ThemeMode.system,
    );
  }
}
