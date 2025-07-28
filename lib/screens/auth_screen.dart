import 'package:educonnect/widgets/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:educonnect/widgets/signup.dart';
import 'package:educonnect/providers/auth_provider.dart';

class AuthScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var isLogin = ref.watch(authScreenProvider);
    return Scaffold(body: isLogin ? LoginWidget() : SignupWidget());
  }
}
