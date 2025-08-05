import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AnnounceProvider extends StateNotifier {
  AnnounceProvider() : super([]);
  Map<String, dynamic> mainUser = {};

  Future<void> toggleAnnouncement(
    String userId,
    String postId,
    BuildContext context,
  ) async {
    final userDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId);
    try {
      final doc = await userDocRef.get();
      if (doc.exists) {
        final List<dynamic> announcements = doc.data()?['Announcements'] ?? [];
        if (announcements.contains(postId)) {
          // If it's already announced, remove it.
          await userDocRef.update({
            'Announcements': FieldValue.arrayRemove([postId]),
          });
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Post removed from announcements'),
                  TextButton(
                    onPressed: () {
                      // Handle undo action
                      ScaffoldMessenger.of(context).clearSnackBars();

                      userDocRef.update({
                        'Announcements': FieldValue.arrayUnion([postId]),
                      });
                    },
                    child: Text(
                      'Undo',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        } else {
          // If it's not announced, add it.
          await userDocRef.update({
            'Announcements': FieldValue.arrayUnion([postId]),
          });
          ScaffoldMessenger.of(context).clearSnackBars();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Post added to announcements'),
              backgroundColor: Theme.of(context).primaryColor,
            ),
          );
        }
      }
    } catch (e) {
      print("Error toggling announcement: $e");
      // Optionally, re-throw the error or show a snackbar
    }
  }

  // NEW: A clear function to handle only liking.

  void deleteAnnouncement(BuildContext context, String postId) async {
    try {
      await FirebaseFirestore.instance
          .collection('announcements')
          .doc(postId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Announcement deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      print('Error deleting announcement: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not delete announcement, error: $error'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Stream<List<Map<String, dynamic>>> getAnnouncements() {
    return FirebaseFirestore.instance
        .collection('announcements')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapShot) {
          return snapShot.docs.map((doc) {
            return {...doc.data(), 'id': doc.id};
          }).toList();
        });
  }

  Stream<List<Map<String, dynamic>>> getOwnAnnouncements(String userId) {
    return FirebaseFirestore.instance
        .collection('announcements')
        .where('userid', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapShot) {
          return snapShot.docs.map((doc) {
            return {...doc.data(), 'id': doc.id};
          }).toList();
        });
  }

  Set<String> tags = {};

  void createPost(
    BuildContext context, {
    required Map<String, dynamic> user,
    required String userId,
  }) {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    String postContent = '';
    List<String> tagItems = [];
    final ImagePicker picker = ImagePicker();
    File? selectedImage;
    bool enableTag = false;

    void submitForm() async {
      formKey.currentState!.save();
      if (postContent.isEmpty && selectedImage == null) {
        formKey.currentState!.validate();
        return;
      }
      if (postContent.isNotEmpty || selectedImage != null) {
        await FirebaseFirestore.instance
            .collection('announcements')
            .add({
              'content': postContent,
              'image':
                  selectedImage?.path, // Placeholder for image path
              'userid': userId,
              'tags': tags.toList(),
              'timestamp': FieldValue.serverTimestamp(),
            })
            .then((_) {
              Navigator.of(context).pop();
            })
            .catchError((error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to create post: $error')),
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
                    Text('Share Announcement'),
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
                              maxLines: null,
                              decoration: InputDecoration(
                                hintText: 'What do you want to announce?',
                                labelStyle: TextStyle(
                                  color: Theme.of(context).shadowColor,
                                  fontWeight: FontWeight.bold,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'can\'t post empty content. Please add some text or an image.';
                                }
                                return null;
                              },
                              onSaved: (newValue) {
                                postContent = newValue!;
                              },
                            ),
                          ),
                          SizedBox(height: 10),
                          if (selectedImage != null)
                            Image.file(
                              selectedImage!,
                              width: double.infinity,
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
                                    labelText: 'Tags (comma separated)',
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
                                  Icons.location_pin,
                                  color: const Color.fromARGB(255, 22, 158, 18),
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
                                    submitForm();
                                  },
                                  child: Text('Create Post'),
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

final announceProvider = StateNotifierProvider((ref) {
  return AnnounceProvider();
});
