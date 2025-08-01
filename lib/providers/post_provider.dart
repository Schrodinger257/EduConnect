import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class PostsState {
  final List<Map<String, dynamic>> posts;
  final bool isLoading;
  final bool hasMore;
  final DocumentSnapshot? lastDocument;

  PostsState({
    this.posts = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.lastDocument,
  });

  // Helper method to create a copy of the state with new values
  PostsState copyWith({
    List<Map<String, dynamic>>? posts,
    bool? isLoading,
    bool? hasMore,
    DocumentSnapshot? lastDocument,
    bool clearLastDocument = false, // Flag to handle resetting pagination
  }) {
    return PostsState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      lastDocument: clearLastDocument
          ? null
          : lastDocument ?? this.lastDocument,
    );
  }
}

class PostProvider extends StateNotifier<PostsState> {
  PostProvider() : super(PostsState());
  Map<String, dynamic> mainUser = {};

  Future<void> toggleBookmark(
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
        final List<dynamic> bookmarks = doc.data()?['Bookmarks'] ?? [];
        if (bookmarks.contains(postId)) {
          // If it's already bookmarked, remove it.
          await userDocRef.update({
            'Bookmarks': FieldValue.arrayRemove([postId]),
          });
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [Text('Post removed from bookmarks')],
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        } else {
          // If it's not bookmarked, add it.
          await userDocRef.update({
            'Bookmarks': FieldValue.arrayUnion([postId]),
          });
          ScaffoldMessenger.of(context).clearSnackBars();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Post added to bookmarks'),
              backgroundColor: Theme.of(context).primaryColor,
            ),
          );
        }
      }
    } catch (e) {
      print("Error toggling bookmark: $e");
      // Optionally, re-throw the error or show a snackbar
    }
  }

  // NEW: A clear function to handle only liking.
  Future<void> toggleLike(String userId, String postId) async {
    final userDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId);
    final postDocRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(postId);
    try {
      final userDoc = await userDocRef.get();
      if (userDoc.exists) {
        final List<dynamic> likedPosts = userDoc.data()?['likedPosts'] ?? [];
        if (likedPosts.contains(postId)) {
          // If already liked, unlike it.
          await userDocRef.update({
            'likedPosts': FieldValue.arrayRemove([postId]),
          });
          // Also decrement the like count on the post document.
          await postDocRef.update({'likes': FieldValue.increment(-1)});
        } else {
          // If not liked, like it.
          await userDocRef.update({
            'likedPosts': FieldValue.arrayUnion([postId]),
          });
          // Also increment the like count on the post document.
          await postDocRef.update({'likes': FieldValue.increment(1)});
        }
      }
    } catch (e) {
      print("Error toggling like: $e");
    }
  }

  void deletePost(BuildContext context, String postId) async {
    try {
      await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Post deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      print('Error deleting post: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not delete post, error: $error'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> getPosts() async {
    if (state.isLoading || !state.hasMore) {
      return; // Return an empty list if already loading or no more posts
    }

    state = state.copyWith(isLoading: true);

    Query query = FirebaseFirestore.instance
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .limit(5);

    if (state.lastDocument != null) {
      query = query.startAfterDocument(state.lastDocument!);
    }

    QuerySnapshot snapshot = await query.get();

    try {
      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        final newPosts = snapshot.docs.map((doc) {
          return {...doc.data() as Map<String, dynamic>, 'id': doc.id};
        }).toList();

        // Create a new state with the combined list of old and new posts
        state = state.copyWith(
          posts: [...state.posts, ...newPosts],
          lastDocument: snapshot.docs.last,
          isLoading: false,
          hasMore: snapshot.docs.length == 5, // Check if there might be more
        );
      } else {
        // No more posts found
        state = state.copyWith(isLoading: false, hasMore: false);
      }
    } catch (e) {
      print("Error fetching posts: $e");
      // Handle error state if necessary
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refreshPosts() async {
    // Reset the state completely before fetching the first page
    state = PostsState();
    await getPosts();
  }

  Stream<List<Map<String, dynamic>>> getBookmarkedPosts(String userId) {
    // First, get the stream of the user's document to react to bookmark changes.
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .asyncMap((userDoc) async {
          if (!userDoc.exists || userDoc.data() == null) {
            return []; // Return an empty list if the user doesn't exist
          }

          // Get the list of bookmarked post IDs from the user's document.
          final List<String> bookmarkIds = List<String>.from(
            userDoc.data()!['Bookmarks'] ?? [],
          );

          if (bookmarkIds.isEmpty) {
            return []; // Return an empty list if there are no bookmarks.
          }

          // Fetch all posts where the document ID is in our list of bookmark IDs.
          final postsSnapshot = await FirebaseFirestore.instance
              .collection('posts')
              .where(FieldPath.documentId, whereIn: bookmarkIds)
              .get();

          // Map the documents to a list of post data.
          final posts = postsSnapshot.docs.map((doc) {
            return {...doc.data(), 'id': doc.id};
          }).toList();

          // Because a 'whereIn' query can't be combined with 'orderBy' on a different field,
          // we sort the posts by timestamp here in the app.
          posts.sort((a, b) {
            final Timestamp timeA = a['timestamp'] ?? Timestamp.now();
            final Timestamp timeB = b['timestamp'] ?? Timestamp.now();
            return timeB.compareTo(timeA); // Sort descending (newest first)
          });

          return posts;
        });
  }

  Set<String> tags = {};

  Set<String> _addTags({required Map<String, dynamic> user}) {
    tags.add(user['roleCode']);
    if (user['roleCode'] == 'student' && user['grade'] != 'None') {
      tags.add(user['grade']);
    }
    if (user['roleCode'] == 'instructor' &&
        user['fieldofexpertise'] != 'Not Assigned Yet') {
      tags.add(user['fieldofexpertise']);
    }

    return tags;
  }

  createPost(
    BuildContext context, {
    required Map<String, dynamic> user,
    required String userId,
  }) {
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
    String postContent = '';
    List<String> tagItems = [];
    final ImagePicker _picker = ImagePicker();
    File? selectedImage;
    bool enableTag = false;

    void _submitForm() async {
      _formKey.currentState!.save();
      if (postContent.isEmpty && selectedImage == null) {
        _formKey.currentState!.validate();
        return;
      }
      if (postContent.isNotEmpty || selectedImage != null) {
        await FirebaseFirestore.instance
            .collection('posts')
            .add({
              'content': postContent,
              'image':
                  selectedImage?.path ?? null, // Placeholder for image path
              'likes': [],
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
                    Text('Create Post'),
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
                      key: _formKey,
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: TextFormField(
                              maxLines: null,
                              decoration: InputDecoration(
                                hintText: 'What\'s on your mind?',
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
                                        _formKey.currentState!.save();
                                        tags.clear();
                                        print(tagItems);
                                        _addTags(user: user);
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
                                  final XFile? image = await _picker.pickImage(
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
                                  final XFile? image = await _picker.pickImage(
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
                                    _addTags(user: user);
                                    _submitForm();
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

final postProvider = StateNotifierProvider<PostProvider, PostsState>((ref) {
  return PostProvider();
});

class OwnPostProvider extends StateNotifier<PostsState> {
  OwnPostProvider() : super(PostsState());

  Future<void> getOwnPosts(String userId) async {
    if (state.isLoading || !state.hasMore) {
      return;
    }

    state = state.copyWith(isLoading: true);

    Query query = FirebaseFirestore.instance
        .collection('posts')
        .where('userid', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(5);

    if (state.lastDocument != null) {
      query = query.startAfterDocument(state.lastDocument!);
    }

    // FIX: Remove the redundant try/catch and the duplicate query.get() call
    try {
      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        final newPosts = snapshot.docs.map((doc) {
          return {...doc.data() as Map<String, dynamic>, 'id': doc.id};
        }).toList();

        state = state.copyWith(
          posts: [...state.posts, ...newPosts],
          lastDocument: snapshot.docs.last,
          isLoading: false,
          hasMore: snapshot.docs.length == 5,
        );
      } else {
        state = state.copyWith(isLoading: false, hasMore: false);
      }
    } catch (e) {
      print("Error fetching own posts: $e");
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refreshOwnPosts(String userId) async {
    // Reset the state completely before fetching the first page
    state = PostsState();
    await getOwnPosts(userId);
  }
}

final ownPostProvider = StateNotifierProvider((ref) {
  return OwnPostProvider();
});
