import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/screens/bookmarks_screen.dart';
import 'package:educonnect/screens/my_announcement_screen.dart';
import 'package:educonnect/screens/my_posts_screen.dart';
import 'package:educonnect/screens/profile_edit_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:educonnect/providers/auth_provider.dart';
import 'package:educonnect/providers/profile_provider.dart';
import 'package:educonnect/modules/user.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

  Widget _buttonCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Function onPressed,
  }) {
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
        onPressed: () {
          onPressed();
        },
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
          return Center(
            child: SvgPicture.asset(
              'assets/vectors/Loading-pana.svg',
              height: 300,
            ),
          );
        }

        // 2. Then, handle errors.
        if (snapshot.hasError) {
          return Center(
            child: SvgPicture.asset(
              'assets/vectors/400-Error-Bad-Request-pana.svg',
              height: 300,
            ),
          );
        }

        // 3. After checks, handle the case where there's no data.
        if (!snapshot.hasData || !snapshot.data!.exists) {
          print('User not found');
          return Center(
            child: SvgPicture.asset(
              'assets/vectors/404-Error-Page-not-Found-with-people-connecting-a-plug-pana.svg',
              height: 300,
            ),
          );
        }

        // 4. Now it's safe to access the data.
        final userData = snapshot.data!.data() as Map<String, dynamic>;
        ref.read(profileProvider.notifier).user =
            userData; // Assign to the state variable

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
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Profile image updated successfully!',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
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
                                  image: DecorationImage(
                                    image:
                                        userData['profileImage'] ==
                                            'default_avatar'
                                        ? AssetImage(
                                            'assets/images/default_avatar.png',
                                          )
                                        : NetworkImage(
                                            userData['profileImage'],
                                          ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  // Convert userData to User object
                                  try {
                                    final user = User(
                                      id: userID,
                                      email: userData['email'] ?? '',
                                      name: userData['name'] ?? '',
                                      role: UserRole.fromString(userData['roleCode'] ?? 'student'),
                                      profileImage: userData['profileImage'],
                                      department: userData['department'],
                                      fieldOfExpertise: userData['fieldofexpertise'],
                                      grade: userData['grade'],
                                      createdAt: userData['createdAt'] is Timestamp 
                                          ? (userData['createdAt'] as Timestamp).toDate()
                                          : DateTime.now(),
                                      bookmarks: List<String>.from(userData['Bookmarks'] ?? []),
                                      likedPosts: List<String>.from(userData['likedPosts'] ?? []),
                                      enrolledCourses: List<String>.from(userData['enrolledCourses'] ?? []),
                                    );
                                    
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => ProfileEditScreen(user: user),
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error loading profile data: ${e.toString()}'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
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
                      if (userData['roleCode'] == 'student')
                        _infoCard(
                          context,
                          width,
                          title: 'Grade',
                          value: userData['grade'],
                        ),
                      if (userData['roleCode'] == 'student')
                        _infoCard(
                          context,
                          width,
                          title: 'Department',
                          value: userData['department'],
                        ),
                      if (userData['roleCode'] == 'instructor')
                        _infoCard(
                          context,
                          width,
                          title: 'Field of expertise',
                          value: userData['fieldofexpertise'],
                        ),
                      _decorLine(context),
                      SizedBox(height: 10),
                      _buttonCard(
                        context,
                        title: 'Bookmarked Posts',
                        icon: Icons.bookmark,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (ctx) => BookmarksScreen(),
                            ),
                          );
                        },
                      ),
                      _buttonCard(
                        context,
                        title: 'My Posts',
                        icon: Icons.article,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (ctx) => MyPostsScreen(),
                            ),
                          );
                        },
                      ),
                      if (userData['roleCode'] == 'student')
                        _buttonCard(
                          context,
                          title: 'Registered Courses',
                          icon: Icons.book,
                          onPressed: () {},
                        ),
                      if (userData['roleCode'] == 'instructor' ||
                          userData['roleCode'] == 'admin')
                        _buttonCard(
                          context,
                          title: 'Announcements',
                          icon: Icons.notifications,
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (ctx) => MyAnnouncementScreen(),
                              ),
                            );
                          },
                        ),
                      if (userData['roleCode'] == 'instructor')
                        _buttonCard(
                          context,
                          title: 'Course Materials',
                          icon: Icons.folder,
                          onPressed: () {},
                        ),
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
