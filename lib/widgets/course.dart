import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/providers/auth_provider.dart';
import 'package:educonnect/screens/course_item_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

class CourseWidget extends ConsumerStatefulWidget {
  CourseWidget({
    super.key,
    required this.course,
    required this.userId,
    required this.courseId,
  });

  final Map<String, dynamic> course;
  final String userId;
  final String courseId;

  @override
  ConsumerState<CourseWidget> createState() => _CourseWidgetState();
}

class _CourseWidgetState extends ConsumerState<CourseWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: const Color.fromARGB(255, 196, 196, 196),
                  image: widget.course['image'] != null
                      ? DecorationImage(
                          image: FileImage(File(widget.course['image'])),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
              ),
              Positioned(
                bottom: 5,
                left: 5,
                child: Wrap(
                  direction: Axis.horizontal,
                  children: [
                    ...widget.course['tags']
                        .map(
                          (tag) => Padding(
                            padding: EdgeInsets.only(right: 5),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                                color: Theme.of(context).cardColor,
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4),
            width: double.infinity,
            child: Text(
              widget.course['title'] ?? 'Course Title',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).shadowColor,
              ),
            ),
          ),
          SizedBox(height: 5),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              widget.course['description'] ?? 'Course description',
              overflow: TextOverflow.ellipsis,
              maxLines: 5,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).shadowColor.withAlpha(200),
              ),
            ),
          ),
          Spacer(),
          ElevatedButton.icon(
            onPressed: () async {
              Map<String, dynamic> courseCreator = await ref
                  .read(authProvider.notifier)
                  .getUserData(widget.userId);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CourseItemScreen(
                    courseId: widget.courseId,
                    courseCreator: courseCreator,
                  ),
                ),
              );
            },
            label: Text(
              'See Details',
              style: TextStyle(fontWeight: FontWeight.w200, fontSize: 12),
            ),
            icon: Icon(Icons.manage_search_rounded),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).cardColor,
              foregroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }
}
