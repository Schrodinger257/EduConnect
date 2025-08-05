import 'package:educonnect/screens/course_item_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CourseWidget extends ConsumerStatefulWidget {
  const CourseWidget({
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
      margin: const EdgeInsets.all(4), // Reduced margin
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                    color: const Color.fromARGB(255, 196, 196, 196),
                    image: widget.course['image'] != null
                        ? DecorationImage(
                            image: NetworkImage(widget.course['image']),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 4,
                  left: 4,
                  child: Wrap(
                    children: [
                      ...widget.course['tags']
                          .take(2) // Limit to 2 tags to prevent overflow
                          .map(
                            (tag) => Container(
                              margin: const EdgeInsets.only(right: 4, bottom: 2),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Theme.of(context).cardColor.withOpacity(0.9),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w500,
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
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.course['title'] ?? 'Course Title',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).shadowColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Text(
                      widget.course['description'] ?? 'Course description',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 3,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).shadowColor.withAlpha(200),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                CourseItemScreen(courseId: widget.courseId),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).cardColor,
                        foregroundColor: Theme.of(context).primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: const Text(
                        'See Details',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
