import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:educonnect/providers/auth_provider.dart';
import 'package:educonnect/providers/profile_provider.dart';
import 'package:educonnect/providers/screen_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Widget _decorLine(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: double.infinity,
          height: 3,
          decoration: BoxDecoration(
            color: Theme.of(context).shadowColor,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        Positioned(
          left: 0,
          top: 7.5,
          child: Container(
            width: 15, // Example width for the progress bar
            height: 15,
            decoration: BoxDecoration(
              color: Theme.of(context).shadowColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
        SizedBox(width: double.infinity, height: 30),
      ],
    );
  }

  Widget _infoCard(
    BuildContext context,
    double width, {
    String title = 'Title',
    String value = 'Value',
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      width: double.infinity,
      child: Row(
        children: [
          Container(
            alignment: Alignment.center,
            width: width * 0.3,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(50),
            ),
            padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
                fontSize: 16,
              ),
            ),
          ),
          SizedBox(width: 30),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).shadowColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buttonCard(BuildContext context, String title, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        ),
        onPressed: () {},
        child: SizedBox(
          height: 50,
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).primaryColor, size: 30),
              SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> user = {};

  // Future<Map<String, dynamic>> _getUser(String userID) async {
  //   DocumentSnapshot doc = await FirebaseFirestore.instance
  //       .collection('users')
  //       .doc(userID)
  //       .get();
  //   final data = doc.data();
  //   Map<String, dynamic> userData = Map<String, dynamic>.from(data as Map);
  //   user = userData;
  //   print(userData);
  //   return userData;
  // }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    String userID = ref.watch(authProvider) as String;
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userID)
          .snapshots(),
      builder: (ctx, snapshot) {
        // 1. First, handle the loading state.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // 2. Then, handle errors.
        if (snapshot.hasError) {
          return Center(child: Text('Something went wrong: ${snapshot.error}'));
        }

        // 3. After checks, handle the case where there's no data.
        if (!snapshot.hasData || !snapshot.data!.exists) {
          print('User not found');
          return const Center(child: Text('User not found'));
        }

        // 4. Now it's safe to access the data.
        final userData = snapshot.data!.data() as Map<String, dynamic>;
        user = userData; // Assign to the state variable

        print(userData);
        return Scaffold(
          body: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                Stack(
                  children: [
                    Positioned(
                      top: -height * 0.3,
                      left: -width * 0.1,
                      child: Container(
                        width: width * 1.5,
                        height: width * 1.5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).cardColor,
                        ),
                      ),
                    ),
                    Positioned(
                      top: height * 0.25,
                      left: width * 0.05,
                      child: InkWell(
                        onTap: () {
                          ref
                              .watch(profileProvider.notifier)
                              .setProfileImage(context, userID);
                        },
                        child: Container(
                          width: width * 0.95,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                width: width * 0.3,
                                height: width * 0.3,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Theme.of(context).cardColor,
                                    width: 5,
                                    strokeAlign: BorderSide.strokeAlignOutside,
                                  ),
                                  shape: BoxShape.circle,
                                  color: Theme.of(context).shadowColor,
                                  image: userData['profileImage'] == null
                                      ? null
                                      : DecorationImage(
                                          image: FileImage(
                                            File(userData['profileImage']),
                                          ),
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  ref
                                      .read(profileProvider.notifier)
                                      .updateUserProfile(userID, user, context);
                                },
                                icon: Icon(
                                  Icons.edit,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(width: width, height: height / 2.5),
                  ],
                ),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 15),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          userData['name'],
                          textAlign: TextAlign.left,
                          style: Theme.of(context).textTheme.titleLarge!
                              .copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).shadowColor,
                                fontSize: 32,
                              ),
                          softWrap: true,
                        ),
                      ),
                      SizedBox(height: 10),
                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.center,
                      //   children: [
                      //     TextButton(
                      //       style: TextButton.styleFrom(
                      //         elevation: 0,
                      //         shape: RoundedRectangleBorder(
                      //           borderRadius: BorderRadius.circular(10),
                      //         ),
                      //         side: BorderSide(
                      //           color: Theme.of(context).primaryColor,
                      //           width: 2,
                      //         ),
                      //       ),
                      //       onPressed: () {
                      //         ref
                      //             .read(profileProvider.notifier)
                      //             .updateUserProfile(userID, user, context);
                      //       },
                      //       child: Container(
                      //         width: width * 0.3,
                      //         alignment: Alignment.center,
                      //         child: Text(
                      //           'Edit Profile',
                      //           style: TextStyle(
                      //             color: Theme.of(context).primaryColor,
                      //           ),
                      //         ),
                      //       ),
                      //     ),
                      //     SizedBox(width: 20),
                      //     ElevatedButton(
                      //       style: ElevatedButton.styleFrom(
                      //         elevation: 0,
                      //         backgroundColor: Theme.of(context).cardColor,
                      //         shape: RoundedRectangleBorder(
                      //           borderRadius: BorderRadius.circular(10),
                      //         ),
                      //       ),
                      //       onPressed: () {},
                      //       child: Container(
                      //         width: width * 0.3,
                      //         alignment: Alignment.center,
                      //         child: Text(
                      //           'Message',
                      //           style: TextStyle(
                      //             color: Theme.of(context).primaryColor,
                      //           ),
                      //         ),
                      //       ),
                      //     ),
                      //   ],
                      // ),
                      // SizedBox(height: 10),
                      _decorLine(context),
                      SizedBox(height: 10),
                      _infoCard(
                        context,
                        width,
                        title: 'Role',
                        value: userData['roleCode'],
                      ),
                      _infoCard(
                        context,
                        width,
                        title: 'Phone',
                        value: userData['phone'],
                      ),
                      _infoCard(
                        context,
                        width,
                        title: 'Email',
                        value: userData['email'],
                      ),
                      if (user['roleCode'] == 'student')
                        _infoCard(
                          context,
                          width,
                          title: 'Grade',
                          value: userData['grade'],
                        ),
                      if (user['roleCode'] == 'student')
                        _infoCard(
                          context,
                          width,
                          title: 'Department',
                          value: userData['department'],
                        ),
                      if (user['roleCode'] == 'instructor')
                        _infoCard(
                          context,
                          width,
                          title: 'Field of expertise',
                          value: userData['fieldofexpertise'],
                        ),
                      _decorLine(context),
                      SizedBox(height: 10),
                      _buttonCard(context, 'Bookmarked Posts', Icons.bookmark),
                      if (userData['roleCode'] == 'student')
                        _buttonCard(context, 'My Posts', Icons.article),
                      if (userData['roleCode'] == 'student')
                        _buttonCard(context, 'Registered Courses', Icons.book),
                      if (userData['roleCode'] == 'instructor' ||
                          userData['roleCode'] == 'admin')
                        _buttonCard(
                          context,
                          'Announcements',
                          Icons.notifications,
                        ),
                      if (userData['roleCode'] == 'instructor')
                        _buttonCard(context, 'Course Materials', Icons.folder),
                      SizedBox(height: 100),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: Theme.of(context).cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 20,
                          ),
                        ),
                        onPressed: () {
                          ref.watch(authProvider.notifier).logout(context);
                          ref
                              .watch(authScreenProvider.notifier)
                              .setAuthState(true);
                        },
                        child: SizedBox(
                          height: 30,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.logout,
                                color: Theme.of(context).primaryColor,
                                size: 30,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Log out',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
