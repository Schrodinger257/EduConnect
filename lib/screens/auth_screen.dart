import 'package:educonnect/widgets/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:educonnect/widgets/signup.dart';
import 'package:educonnect/providers/auth_provider.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var authScreenState = ref.watch(authScreenProvider);
    return Scaffold(body: authScreenState.isLoginMode ? LoginWidget() : SignupWidget());
  }
}
