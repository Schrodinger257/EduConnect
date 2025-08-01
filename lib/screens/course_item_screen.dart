import 'package:educonnect/providers/course_provider.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CourseItemScreen extends ConsumerStatefulWidget {
  CourseItemScreen({
    super.key,
    required this.courseId,
    required this.courseCreator,
  });
  final String courseId;
  final Map<String, dynamic> courseCreator;

  @override
  ConsumerState<CourseItemScreen> createState() => _CourseItemScreenState();
}

class _CourseItemScreenState extends ConsumerState<CourseItemScreen> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Fetch course data when the widget is first built
      ref.read(courseItemProvider.notifier).getCourseById(widget.courseId);
    });
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> courseData =
        ref.watch(courseItemProvider) as Map<String, dynamic>;
    // Here you would typically fetch the post data using the postId
    // and display it in a suitable widget.
    return Scaffold(
      appBar: AppBar(title: Text(courseData['title'] ?? 'Course Details')),
      body: RefreshIndicator(
        onRefresh: () async {
          // Implement your refresh logic here
          courseData =
              await ref
                      .read(courseItemProvider.notifier)
                      .getCourseById(widget.courseId)
                  as Map<String, dynamic>;
          print(courseData);
        },
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 350,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 300,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 196, 196, 196),
                        image: courseData['image'] != null
                            ? DecorationImage(
                                image: FileImage(File(courseData['image'])),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 25,
                      width: MediaQuery.of(context).size.width,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).shadowColor,
                              image:
                                  widget.courseCreator['profileImage'] != null
                                  ? DecorationImage(
                                      image: FileImage(
                                        File(
                                          widget.courseCreator['profileImage'],
                                        ),
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ), // Add more course details here
              SizedBox(
                height: 100,
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        courseData['title'] ?? 'Course Title',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).shadowColor,
                          fontSize: 35,
                        ),
                      ),
                    ),
                    SizedBox(height: 5),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'Istructor: ${widget.courseCreator['name'] ?? 'Unknown'}',
                        style: TextStyle(
                          color: Theme.of(context).shadowColor.withAlpha(200),
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'created on: ${DateFormat('dd MMMM yyyy').format(DateTime.fromMillisecondsSinceEpoch(courseData['timestamp'].millisecondsSinceEpoch))}',
                        style: TextStyle(
                          color: Theme.of(context).shadowColor.withAlpha(200),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Wrap(
                  direction: Axis.horizontal,
                  children: [
                    ...courseData['tags']
                        .map(
                          (tag) => Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 5,
                            ),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                                color: Theme.of(context).cardColor,
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  courseData['description'] ?? 'Course Description',
                  style: TextStyle(
                    color: Theme.of(context).shadowColor.withAlpha(200),
                    fontSize: 16,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    alignment: Alignment.center,
                    backgroundColor: Theme.of(context).cardColor,
                    foregroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {},
                  label: Container(
                    alignment: Alignment.center,
                    width: double.infinity,
                    height: 50,
                    child: Text('Enroll Now'),
                  ),
                  icon: Icon(Icons.keyboard_double_arrow_right_rounded),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
