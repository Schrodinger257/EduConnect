import 'package:educonnect/screens/auth_screen.dart';
import 'package:educonnect/screens/main_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class NavScreen extends StatelessWidget {
  const NavScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: SvgPicture.asset(
              'assets/vectors/Loading-pana.svg',
              height: 300,
            ),
          );
        }
        if (snapshot.hasData) {
          return MainScreen();
        }
        return AuthScreen();
      },
    );
  }
}
