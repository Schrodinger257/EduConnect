import 'package:educonnect/modules/user.dart';
import 'package:educonnect/screens/auth_screen.dart';
import 'package:educonnect/screens/main_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  void setAuthState(bool value) {
    state = value;
  }
}

final authScreenProvider = StateNotifierProvider((ref) => AuthScreenProvider());

class AuthProvider extends StateNotifier {
  AuthProvider() : super(FirebaseAuth.instance.currentUser?.uid);

  String error = '';
  String statue = '';
  Map<String, dynamic> userData = {};

  Future<Map<String, dynamic>> getUserData(String userId) async {
    Map<String, dynamic> data = {};
    await FirebaseFirestore.instance.collection('users').doc(userId).get().then(
      (doc) {
        data = doc.data() as Map<String, dynamic>;
      },
    );

    return data;
  }

  Future<void> logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (context) => AuthScreen()));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logged out successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      print('User logged out successfully');
    } catch (e) {
      print('Error logging out: $e');
      throw e; // Handle the error appropriately
    }
  }

  Future<void> login(
    String email,
    String password,
    BuildContext context,
  ) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logging in...'),
          backgroundColor: Colors.lightBlueAccent,
        ),
      );

      statue = '';
      error = '';
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      statue = 'success';
      error = '';
      state = userCredential.user!.uid;
      userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get()
          .then((doc) => doc.data() as Map<String, dynamic>);
      ScaffoldMessenger.of(context).clearSnackBars();
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login Successful!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (context) => MainScreen()));

      print('User logged in: ${userCredential.user?.uid}');
    } catch (e) {
      ScaffoldMessenger.of(context).clearSnackBars();
      statue = 'error';
      error = e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
      );
      print('Error logging in: $e');
      throw e; // Handle the error appropriately
    }
  }

  Future<void> signup(UserClass user, BuildContext context) async {
    try {
      statue = '';
      error = '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Signing up...'),
          backgroundColor: Colors.lightBlueAccent,
        ),
      );

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
            'fieldofexpertise': 'Not Assigned Yet',
            'profileImage': 'default_avatar',
            'phone': 'None',
            'department': 'Not Assigned Yet',
            'grade': 'None',
            'createdAt': FieldValue.serverTimestamp(),
            'Bookmarks': [],
            'likedPosts': [],
          });
      state = userCredential.user!.uid;
      userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get()
          .then((doc) => doc.data() as Map<String, dynamic>);

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Signup Successful!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (context) => MainScreen()));

      // Additional logic for user creation can be added here
      print('User signed up: ${userCredential.user?.uid}');
    } catch (e) {
      FirebaseAuth.instance.currentUser!.delete();
      ScaffoldMessenger.of(context).clearSnackBars();
      statue = 'error';
      error = e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
      );

      print('Error signing up: $e');
      throw e; // Handle the error appropriately
    }
  }
}

final authProvider = StateNotifierProvider((ref) => AuthProvider());
