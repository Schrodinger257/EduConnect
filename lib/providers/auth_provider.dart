import 'dart:math';

import 'package:educonnect/modules/user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoleProvider extends StateNotifier {
  RoleProvider() : super(false);
  bool isStudent = false;
  bool isInstructor = false;
  bool isAdmin = false;

  void toggleStudentRole(value) {
    isAdmin = false;
    isInstructor = false;
    isStudent = value;
  }

  void toggleInstructorRole(value) {
    isAdmin = false;
    isStudent = false;
    isInstructor = value;
  }

  void toggleAdminRole(value) {
    isStudent = false;
    isInstructor = false;

    isAdmin = value;
  }
}

final roleProvider = StateNotifierProvider((ref) => RoleProvider());

class AuthScreenProvider extends StateNotifier {
  AuthScreenProvider() : super(true);

  // Add any additional state or methods needed for the AuthScreen
  void toggleAuthState() {
    state = !state;
  }
}

final authScreenProvider = StateNotifierProvider((ref) => AuthScreenProvider());

class AuthProvider extends StateNotifier {
  AuthProvider() : super('');

  String error = '';
  String statue = '';

  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      print('User logged out successfully');
    } catch (e) {
      print('Error logging out: $e');
      throw e; // Handle the error appropriately
    }
  }

  Future<void> login(String email, String password) async {
    try {
      statue = '';
      error = '';
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      statue = 'success';
      error = '';

      print('User logged in: ${userCredential.user?.uid}');
    } catch (e) {
      statue = 'error';
      error = e.toString();

      print('Error logging in: $e');
      throw e; // Handle the error appropriately
    }
  }

  Future<void> signup(UserClass user) async {
    try {
      statue = '';
      error = '';

      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: user.email!,
            password: user.password!,
          );
      statue = 'success';
      error = '';
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user?.uid)
          .set({
            'email': user.email,
            'name': user.name,
            'roleCode': user.roleCode,
            'createdAt': FieldValue.serverTimestamp(),
          });
      // Additional logic for user creation can be added here
      print('User signed up: ${userCredential.user?.uid}');
    } catch (e) {
      statue = 'error';
      error = e.toString();
      print('Error signing up: $e');
      throw e; // Handle the error appropriately
    }
  }
}

final authProvider = StateNotifierProvider((ref) => AuthProvider());
