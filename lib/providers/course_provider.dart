import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CourseState {
  final List<Map<String, dynamic>> courses;
  final bool isLoading;
  final bool hasMore;
  final DocumentSnapshot? lastDocument;

  CourseState({
    this.courses = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.lastDocument,
  });

  // Helper method to create a copy of the state with new values
  CourseState copyWith({
    List<Map<String, dynamic>>? courses,
    bool? isLoading,
    bool? hasMore,
    DocumentSnapshot? lastDocument,
    bool clearLastDocument = false, // Flag to handle resetting pagination
  }) {
    return CourseState(
      courses: courses ?? this.courses,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      lastDocument: clearLastDocument
          ? null
          : lastDocument ?? this.lastDocument,
    );
  }
}

class OwnCourseProvider extends StateNotifier<CourseState> {
  OwnCourseProvider() : super(CourseState());

  Future<void> getOwnCourses(String userId) async {
    if (state.isLoading || !state.hasMore) {
      return;
    }

    state = state.copyWith(isLoading: true);

    Query query = FirebaseFirestore.instance
        .collection('courses')
        .where('userid', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(8);

    if (state.lastDocument != null) {
      query = query.startAfterDocument(state.lastDocument!);
    }

    // FIX: Remove the redundant try/catch and the duplicate query.get() call
    try {
      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        final newcourses = snapshot.docs.map((doc) {
          return {...doc.data() as Map<String, dynamic>, 'id': doc.id};
        }).toList();

        state = state.copyWith(
          courses: [...state.courses, ...newcourses],
          lastDocument: snapshot.docs.last,
          isLoading: false,
          hasMore: snapshot.docs.length == 5,
        );
      } else {
        state = state.copyWith(isLoading: false, hasMore: false);
      }
    } catch (e) {
      print("Error fetching own courses: $e");
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refreshOwncourses(String userId) async {
    // Reset the state completely before fetching the first page
    state = CourseState();
    await getOwnCourses(userId);
  }
}

final ownCourseProvider = StateNotifierProvider((ref) {
  return OwnCourseProvider();
});

class CourseProvider extends StateNotifier<CourseState> {
  CourseProvider() : super(CourseState());

  void deleteCourse(BuildContext context, String courseId) async {
    try {
      await FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Course deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      print('Error deleting course: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not delete course, error: $error'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> getCourses() async {
    if (state.isLoading || !state.hasMore) {
      return; // Return an empty list if already loading or no more courses
    }

    state = state.copyWith(isLoading: true);

    Query query = FirebaseFirestore.instance
        .collection('courses')
        .orderBy('timestamp', descending: true)
        .limit(5);

    if (state.lastDocument != null) {
      query = query.startAfterDocument(state.lastDocument!);
    }

    QuerySnapshot snapshot = await query.get();

    try {
      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        final newcourses = snapshot.docs.map((doc) {
          return {...doc.data() as Map<String, dynamic>, 'id': doc.id};
        }).toList();

        // Create a new state with the combined list of old and new courses
        state = state.copyWith(
          courses: [...state.courses, ...newcourses],
          lastDocument: snapshot.docs.last,
          isLoading: false,
          hasMore: snapshot.docs.length == 5, // Check if there might be more
        );
      } else {
        // No more courses found
        state = state.copyWith(isLoading: false, hasMore: false);
      }
    } catch (e) {
      print("Error fetching courses: $e");
      // Handle error state if necessary
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refreshcourses() async {
    // Reset the state completely before fetching the first page
    state = CourseState();
    await getCourses();
  }

  Set<String> tags = {};

  void createCourse(
    BuildContext context, {
    required Map<String, dynamic> user,
    required String userId,
  }) {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    String title = '';
    String description = '';
    List<String> tagItems = [];
    final ImagePicker picker = ImagePicker();
    File? selectedImage;
    bool enableTag = false;

    Set<String> addTags({required Map<String, dynamic> user}) {
      if (user['roleCode'] == 'instructor' &&
          user['fieldofexpertise'] != 'Not Assigned Yet') {
        tags.add(user['fieldofexpertise']);
      }

      return tags;
    }

    void submitForm() async {
      formKey.currentState!.save();
      if (title.isEmpty && selectedImage == null && description.isEmpty) {
        formKey.currentState!.validate();
        return;
      }
      if (title.isNotEmpty && description.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('courses')
            .add({
              'title': title,
              'image':
                  selectedImage?.path, // Placeholder for image path
              'description': description,
              'userid': userId,
              'tags': tags.toList(),
              'timestamp': FieldValue.serverTimestamp(),
            })
            .then((_) {
              Navigator.of(context).pop();
              refreshcourses();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Course created successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            })
            .catchError((error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to create course: $error')),
              );
            });
      }
    }

    showModalBottomSheet(
      isScrollControlled: true,
      useSafeArea: true,
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (statefulContext, setState) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text('Create Course'),
                    Divider(),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Theme.of(context).shadowColor,
                                  image: user['profileImage'] == null
                                      ? null
                                      : DecorationImage(
                                          image: FileImage(
                                            File(user['profileImage']),
                                          ),
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                              SizedBox(width: 10),
                              SizedBox(
                                child: Text(
                                  user['name'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).shadowColor,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    Form(
                      key: formKey,
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: TextFormField(
                              maxLength: 50,
                              decoration: InputDecoration(
                                hintText: 'Course Title',
                                labelText: 'Title',
                                labelStyle: TextStyle(
                                  color: Theme.of(context).shadowColor,
                                  fontWeight: FontWeight.bold,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Theme.of(context).cardColor,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Theme.of(context).primaryColor,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'can\'t create course without a title. Please add a title.';
                                }
                                return null;
                              },
                              onSaved: (newValue) {
                                title = newValue!;
                              },
                            ),
                          ),
                          SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: TextFormField(
                              maxLength: 500,
                              decoration: InputDecoration(
                                hintText: 'Course Subtitle',
                                labelText: 'Subtitle',
                                labelStyle: TextStyle(
                                  color: Theme.of(context).shadowColor,
                                  fontWeight: FontWeight.bold,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Theme.of(context).cardColor,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Theme.of(context).primaryColor,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'can\'t create course without a subtitle. Please add a subtitle.';
                                }
                                return null;
                              },
                              onSaved: (newValue) {
                                description = newValue!;
                              },
                            ),
                          ),
                          SizedBox(height: 10),
                          if (selectedImage != null)
                            Image.file(
                              selectedImage!,
                              width: double.infinity,
                              height: 300,
                              fit: BoxFit.cover,
                            ),
                          SizedBox(height: 10),
                          // Add your post creation UI here
                          SizedBox(height: 10),
                          if (enableTag)
                            Column(
                              children: [
                                Wrap(
                                  children: tags.map((tag) {
                                    return Container(
                                      margin: EdgeInsets.only(
                                        right: 5,
                                        bottom: 5,
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).cardColor,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        tag,
                                        style: TextStyle(
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                SizedBox(height: 5),
                                TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'Course Tags (comma separated)',
                                    labelStyle: TextStyle(
                                      color: Theme.of(context).shadowColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Theme.of(context).cardColor,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Theme.of(context).primaryColor,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onSaved: (newValue) {
                                    if (newValue == null || newValue.isEmpty) {
                                      return;
                                    }
                                    tagItems.clear();
                                    newValue.split(',').toList().forEach((tag) {
                                      tagItems.add(tag.trim());
                                    });
                                  },
                                ),
                                SizedBox(height: 5),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        formKey.currentState!.save();
                                        tags.clear();
                                        print(tagItems);
                                        addTags(user: user);
                                        setState(() {
                                          // Update the state to reflect the new tags
                                          tags.addAll(tagItems);
                                        });
                                        print(tags);
                                      },
                                      child: Text(
                                        'Add Tag',
                                        style: TextStyle(
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  final XFile? image = await picker.pickImage(
                                    source: ImageSource.gallery,
                                    imageQuality: 80,
                                  );
                                  if (image != null) {
                                    setState(() {
                                      selectedImage = File(image.path);
                                    });
                                  }
                                },

                                child: Icon(
                                  Icons.photo_library,
                                  color: Colors.pinkAccent,
                                ),
                              ),
                              SizedBox(width: 20),
                              GestureDetector(
                                child: Icon(
                                  Icons.camera_alt,
                                  color: const Color.fromARGB(
                                    255,
                                    161,
                                    161,
                                    161,
                                  ),
                                ),
                                onTap: () async {
                                  final XFile? image = await picker.pickImage(
                                    source: ImageSource.camera,
                                    imageQuality: 80,
                                  );
                                  if (image != null) {
                                    setState(() {
                                      selectedImage = File(image.path);
                                    });
                                  }
                                },
                              ),
                              SizedBox(width: 20),
                              GestureDetector(
                                child: Icon(
                                  Icons.file_copy,
                                  color: const Color.fromARGB(
                                    255,
                                    158,
                                    149,
                                    18,
                                  ),
                                ),
                                onTap: () {},
                              ),
                              SizedBox(width: 20),
                              GestureDetector(
                                child: Icon(
                                  Icons.tag,
                                  color: const Color.fromARGB(
                                    255,
                                    11,
                                    123,
                                    143,
                                  ),
                                ),
                                onTap: () {
                                  setState(() {
                                    enableTag = !enableTag;
                                  });
                                },
                              ),
                            ],
                          ),

                          SizedBox(height: 50),

                          SizedBox(
                            width: double.infinity,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  style: TextButton.styleFrom(
                                    side: BorderSide(
                                      color: Theme.of(context).primaryColor,
                                      width: 2,
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.of(ctx).pop();
                                  },
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(
                                      context,
                                    ).cardColor,
                                    foregroundColor: Theme.of(
                                      context,
                                    ).primaryColor,
                                    elevation: 0,
                                  ),
                                  onPressed: () {
                                    // Handle post creation
                                    addTags(user: user);
                                    submitForm();
                                  },
                                  child: Text('Create Course'),
                                ),
                              ],
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
      },
    );
  }
}

final courseProvider = StateNotifierProvider((ref) {
  return CourseProvider();
});

class CourseItemProvider extends StateNotifier<Map<String, dynamic>?> {
  CourseItemProvider() : super(null);

  Future<void> getCourseById(String courseId) async {
    Map<String, dynamic>? courseData;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .get();

      if (doc.exists) {
        courseData = {...doc.data() as Map<String, dynamic>, 'id': doc.id};
        state = courseData;
      }
    } catch (e) {
      print("Error fetching course by ID: $e");
    }
    return;
  }
}

final courseItemProvider = StateNotifierProvider((ref) {
  return CourseItemProvider();
});
