import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/providers/auth_provider.dart';
import 'package:educonnect/providers/course_provider.dart';
import 'package:educonnect/widgets/course.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_svg/svg.dart';

class CoursesScreen extends ConsumerStatefulWidget {
  const CoursesScreen({super.key});
  @override
  ConsumerState<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends ConsumerState<CoursesScreen> {
  final _scrollController = ScrollController();

  Widget _tag(BuildContext context, String tag) {
    return Container(
      margin: const EdgeInsets.only(right: 5, bottom: 5),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 1),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        tag,
        style: TextStyle(
          color: Theme.of(context).scaffoldBackgroundColor,
          fontSize: 10,
        ),
      ),
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // It's now safe to use ref here.
      // Also, check if the courses list inside the state is empty.
      if (ref.read(courseProvider).courses.isEmpty) {
        ref.read(courseProvider.notifier).getCourses();
      }
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final courseState = ref.read(courseProvider);
    final courseNotifier = ref.read(courseProvider.notifier);

    // 3. The core logic for fetching more courses
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent *
                0.9 && // Trigger slightly before the end
        !courseState.isLoading &&
        courseState.hasMore) {
      // Use ref.read to trigger the fetch action
      courseNotifier.getCourses();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userID = authState.userId;
    
    if (userID == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to access this screen'),
        ),
      );
    }
    
    final courseState = ref.watch(courseProvider);
    final courseNotifier = ref.watch(courseProvider.notifier);
    final courses = courseState.courses;
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Use StreamBuilder to check user role and conditionally show the header
            StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userID)
                  .snapshots(),
              builder: (ctx, snapShot) {
                if (snapShot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 60,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (snapShot.hasError) {
                  return const SizedBox.shrink();
                }
                if (!snapShot.hasData || !snapShot.data!.exists) {
                  return const SizedBox.shrink();
                }

                final userData = snapShot.data!.data() as Map<String, dynamic>;
                
                // Only show the header if user is not a student
                if (userData['roleCode'] == 'student') {
                  return const SizedBox.shrink();
                }
                
                return Card(
                  elevation: 4,
                  shadowColor: Theme.of(context).primaryColor.withAlpha(50),
                  margin: const EdgeInsets.all(0),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(10),
                      bottomLeft: Radius.circular(10),
                    ),
                  ),
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Container(
                    padding: const EdgeInsets.only(left: 10, right: 10, top: 5),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).shadowColor,
                                image: userData['profileImage'] == null
                                    ? null
                                    : DecorationImage(
                                        image: NetworkImage(
                                          userData['profileImage'],
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    userData['name'] ?? 'Unknown',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).shadowColor,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Wrap(
                                    children: [
                                      _tag(context, userData['roleCode'] ?? 'user'),
                                      if (userData['fieldofexpertise'] != null &&
                                          userData['fieldofexpertise'] != 'Not Assigned Yet')
                                        _tag(
                                          context,
                                          userData['fieldofexpertise'],
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).cardColor,
                                foregroundColor: Theme.of(context).primaryColor,
                                elevation: 0,
                              ),
                              onPressed: () {
                                courseNotifier.tags.clear();
                                courseNotifier.createCourse(
                                  context,
                                  user: userData,
                                  userId: userID,
                                );
                              },
                              label: const Text(
                                'Create Course',
                                style: TextStyle(fontSize: 12),
                              ),
                              icon: const Icon(Icons.add, size: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    ref.read(courseProvider.notifier).refreshcourses(),
                child: courses.isEmpty && !courseState.isLoading
                    ? Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: SvgPicture.asset(
                            'assets/vectors/No-data-amico.svg',
                            fit: BoxFit.contain,
                          ),
                        ),
                      )
                    : GridView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(10),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          childAspectRatio: 0.5, // Changed from 1/2 to 0.5 for better proportion
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount:
                            courses.length + (courseState.isLoading ? 1 : 0),
                        itemBuilder: (ctx, index) {
                          if (index == courses.length &&
                              courseState.isLoading) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          final course = courses[index];
                          return CourseWidget(
                            course: course,
                            userId: userID,
                            courseId: course['id'],
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
