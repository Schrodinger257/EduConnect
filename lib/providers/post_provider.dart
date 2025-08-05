import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/result.dart';
import '../core/logger.dart';
import '../modules/post.dart';
import '../repositories/post_repository.dart';
import '../repositories/user_repository.dart';
import '../services/navigation_service.dart';
import 'providers.dart';

class PostsState {
  final List<Post> posts;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final DocumentSnapshot? lastDocument;

  const PostsState({
    this.posts = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.lastDocument,
  });

  // Helper method to create a copy of the state with new values
  PostsState copyWith({
    List<Post>? posts,
    bool? isLoading,
    bool? hasMore,
    String? error,
    DocumentSnapshot? lastDocument,
    bool clearLastDocument = false,
    bool clearError = false,
  }) {
    return PostsState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
      lastDocument: clearLastDocument
          ? null
          : lastDocument ?? this.lastDocument,
    );
  }

  bool get hasError => error != null;
  bool get isEmpty => posts.isEmpty && !isLoading;
}

class PostProvider extends StateNotifier<PostsState> {
  final PostRepository _postRepository;
  final UserRepository _userRepository;
  final NavigationService _navigationService;
  final Logger _logger;
  final Ref ref;

  PostProvider({
    required PostRepository postRepository,
    required UserRepository userRepository,
    required NavigationService navigationService,
    required Logger logger,
    required this.ref,
  }) : _postRepository = postRepository,
       _userRepository = userRepository,
       _navigationService = navigationService,
       _logger = logger,
       super(const PostsState());

  Future<void> toggleBookmark(String userId, String postId) async {
    try {
      _logger.info('Toggling bookmark for user: $userId, post: $postId');
      
      final result = await _userRepository.toggleBookmark(userId, postId);
      
      result.when(
        success: (_) {
          // Get current bookmarks to determine if it was added or removed
          _userRepository.getBookmarks(userId).then((bookmarksResult) {
            bookmarksResult.when(
              success: (bookmarks) {
                final isBookmarked = bookmarks.contains(postId);
                if (isBookmarked) {
                  _navigationService.showSuccessSnackBar('Post added to bookmarks');
                } else {
                  _navigationService.showInfoSnackBar('Post removed from bookmarks');
                }
              },
              error: (message, _) {
                _logger.warning('Could not check bookmark status: $message');
              },
            );
          });
        },
        error: (message, exception) {
          _logger.error('Error toggling bookmark: $message', error: exception);
          _navigationService.showErrorSnackBar('Failed to update bookmark');
        },
      );
    } catch (e) {
      _logger.error('Unexpected error toggling bookmark: $e');
      _navigationService.showErrorSnackBar('An unexpected error occurred');
    }
  }

  Future<void> toggleLike(String userId, String postId) async {
    try {
      _logger.info('Toggling like for user: $userId, post: $postId');
      
      final result = await _postRepository.toggleLike(postId, userId);
      
      result.when(
        success: (_) {
          _logger.info('Successfully toggled like');
          // Update the local state to reflect the change immediately
          _updatePostLikeInState(postId, userId);
        },
        error: (message, exception) {
          _logger.error('Error toggling like: $message', error: exception);
          _navigationService.showErrorSnackBar('Failed to update like');
        },
      );
    } catch (e) {
      _logger.error('Unexpected error toggling like: $e');
      _navigationService.showErrorSnackBar('An unexpected error occurred');
    }
  }

  void _updatePostLikeInState(String postId, String userId) {
    final updatedPosts = state.posts.map((post) {
      if (post.id == postId) {
        return post.toggleLike(userId);
      }
      return post;
    }).toList();
    
    state = state.copyWith(posts: updatedPosts);
  }

  Future<void> deletePost(String postId, String userId) async {
    try {
      _logger.info('Deleting post: $postId by user: $userId');
      
      final result = await _postRepository.deletePost(postId);
      
      result.when(
        success: (_) {
          _logger.info('Successfully deleted post: $postId');
          _navigationService.showSuccessSnackBar('Post deleted successfully');
          
          // Remove the post from local state
          final updatedPosts = state.posts.where((post) => post.id != postId).toList();
          state = state.copyWith(posts: updatedPosts);
          
          // Refresh own posts provider
          ref.read(ownPostProvider.notifier).refreshOwnPosts(userId);
        },
        error: (message, exception) {
          _logger.error('Error deleting post: $message', error: exception);
          _navigationService.showErrorSnackBar('Could not delete post: $message');
        },
      );
    } catch (e) {
      _logger.error('Unexpected error deleting post: $e');
      _navigationService.showErrorSnackBar('An unexpected error occurred');
    }
  }

  Future<void> getPosts() async {
    if (state.isLoading || !state.hasMore) {
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      _logger.info('Fetching posts with pagination');
      
      final result = await _postRepository.getPosts(
        limit: 5,
        lastDocument: state.lastDocument,
      );

      result.when(
        success: (newPosts) {
          _logger.info('Successfully fetched ${newPosts.length} posts');
          
          // Get the last document for pagination
          DocumentSnapshot? lastDoc;
          if (newPosts.isNotEmpty) {
            // We need to get the actual Firestore document for pagination
            lastDoc = state.lastDocument; // Keep existing for now
          }
          
          state = state.copyWith(
            posts: [...state.posts, ...newPosts],
            lastDocument: lastDoc,
            isLoading: false,
            hasMore: newPosts.length == 5,
          );
        },
        error: (message, exception) {
          _logger.error('Error fetching posts: $message', error: exception);
          state = state.copyWith(
            isLoading: false,
            error: message,
          );
        },
      );
    } catch (e) {
      _logger.error('Unexpected error fetching posts: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  Future<void> refreshPosts() async {
    _logger.info('Refreshing posts');
    // Reset the state completely before fetching the first page
    state = const PostsState();
    await getPosts();
  }

  Stream<List<Post>> getBookmarkedPosts(String userId) {
    _logger.info('Getting bookmarked posts stream for user: $userId');
    return _postRepository.getBookmarkedPosts(userId);
  }

  Future<void> createPost({
    required String userId,
    required String content,
    File? imageFile,
    List<String> additionalTags = const [],
  }) async {
    try {
      _logger.info('Creating post for user: $userId');
      
      // Validate input
      if (content.trim().isEmpty && imageFile == null) {
        _navigationService.showErrorSnackBar('Post cannot be empty. Please add some text or an image.');
        return;
      }

      state = state.copyWith(isLoading: true, clearError: true);

      // Get user data to generate tags
      final userResult = await _userRepository.getUserById(userId);
      if (userResult.isError) {
        state = state.copyWith(isLoading: false, error: userResult.errorMessage);
        _navigationService.showErrorSnackBar('Failed to get user information');
        return;
      }

      final user = userResult.data!;
      
      // Upload image if provided
      String? imageUrl;
      if (imageFile != null) {
        final uploadResult = await _uploadPostImage(imageFile, userId);
        if (uploadResult.isError) {
          state = state.copyWith(isLoading: false, error: uploadResult.errorMessage);
          _navigationService.showErrorSnackBar('Failed to upload image');
          return;
        }
        imageUrl = uploadResult.data;
      }

      // Generate tags based on user role and additional tags
      final tags = _generatePostTags(user, additionalTags);

      // Create post object
      final post = Post(
        id: '', // Will be set by repository
        content: content.trim(),
        userId: userId,
        imageUrl: imageUrl,
        tags: tags,
        timestamp: DateTime.now(),
      );

      // Create post via repository
      final result = await _postRepository.createPost(post);
      
      result.when(
        success: (createdPost) {
          _logger.info('Successfully created post: ${createdPost.id}');
          
          // Add the new post to the beginning of the list
          final updatedPosts = [createdPost, ...state.posts];
          state = state.copyWith(
            posts: updatedPosts,
            isLoading: false,
          );
          
          _navigationService.showSuccessSnackBar('Post created successfully');
          _navigationService.goBack();
        },
        error: (message, exception) {
          _logger.error('Error creating post: $message', error: exception);
          state = state.copyWith(isLoading: false, error: message);
          _navigationService.showErrorSnackBar('Failed to create post: $message');
        },
      );
    } catch (e) {
      _logger.error('Unexpected error creating post: $e');
      state = state.copyWith(isLoading: false, error: 'An unexpected error occurred');
      _navigationService.showErrorSnackBar('An unexpected error occurred');
    }
  }

  List<String> _generatePostTags(dynamic user, List<String> additionalTags) {
    final tags = <String>{};
    
    // Add role-based tags
    if (user.role != null) {
      tags.add(user.role.value);
    }
    
    // Add grade for students
    if (user.role?.value == 'student' && user.grade != null && user.grade != 'None') {
      tags.add(user.grade!);
    }
    
    // Add field of expertise for instructors
    if (user.role?.value == 'instructor' && 
        user.fieldOfExpertise != null && 
        user.fieldOfExpertise != 'Not Assigned Yet') {
      tags.add(user.fieldOfExpertise!);
    }
    
    // Add additional tags
    tags.addAll(additionalTags.where((tag) => tag.trim().isNotEmpty));
    
    return tags.toList();
  }

  Future<Result<String>> _uploadPostImage(File imageFile, String userId) async {
    try {
      _logger.info('Uploading post image for user: $userId');
      
      // Validate file size (max 5MB)
      final fileSize = await imageFile.length();
      if (fileSize > 5 * 1024 * 1024) {
        return Result.error('Image file size cannot exceed 5MB');
      }
      
      // Remove existing image if it exists
      try {
        await Supabase.instance.client.storage
            .from('posts')
            .remove(['$userId.png']);
      } catch (e) {
        // Ignore errors when removing non-existent files
      }
      
      // Upload new image
      final url = '$userId${DateTime.now().millisecondsSinceEpoch}.png';
      await Supabase.instance.client.storage
          .from('posts')
          .upload(
            url,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );
      
      final publicUrl = Supabase.instance.client.storage
          .from('posts')
          .getPublicUrl(url);
      
      return Result.success(publicUrl);
    } catch (e) {
      _logger.error('Error uploading post image: $e');
      return Result.error('Failed to upload image: ${e.toString()}');
    }
  }

  /// Shows a modal for creating a new post
  void showCreatePostModal(BuildContext context, String userId) {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    String postContent = '';
    File? selectedImage;
    final Set<String> tags = {};

    void submitForm() async {
      formKey.currentState!.save();
      if (postContent.trim().isEmpty && selectedImage == null) {
        _navigationService.showErrorSnackBar('Post cannot be empty. Please add some text or an image.');
        return;
      }

      await createPost(
        userId: userId,
        content: postContent,
        imageFile: selectedImage,
        additionalTags: tags.toList(),
      );
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
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'Create Post',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Divider(),
                      SizedBox(height: 16),
                      TextFormField(
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: 'What\'s on your mind?',
                          border: OutlineInputBorder(),
                        ),
                        onSaved: (value) {
                          postContent = value ?? '';
                        },
                        validator: (value) {
                          if ((value == null || value.trim().isEmpty) && selectedImage == null) {
                            return 'Please add some text or an image';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      if (selectedImage != null)
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  selectedImage!,
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedImage = null;
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          GestureDetector(
                            child: Icon(
                              Icons.image,
                              color: Colors.green,
                              size: 30,
                            ),
                            onTap: () async {
                              final picker = ImagePicker();
                              final pickedFile = await picker.pickImage(
                                source: ImageSource.gallery,
                              );
                              if (pickedFile != null) {
                                setState(() {
                                  selectedImage = File(pickedFile.path);
                                });
                              }
                            },
                          ),
                          SizedBox(width: 20),
                          GestureDetector(
                            child: Icon(
                              Icons.camera_alt,
                              color: Colors.blue,
                              size: 30,
                            ),
                            onTap: () async {
                              final picker = ImagePicker();
                              final pickedFile = await picker.pickImage(
                                source: ImageSource.camera,
                              );
                              if (pickedFile != null) {
                                setState(() {
                                  selectedImage = File(pickedFile.path);
                                });
                              }
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
                                backgroundColor: Theme.of(context).cardColor,
                                foregroundColor: Theme.of(context).primaryColor,
                                elevation: 0,
                              ),
                              onPressed: () {
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
              ),
            );
          },
        );
      },
    );
  }
}

final postProvider = StateNotifierProvider<PostProvider, PostsState>((ref) {
  return PostProvider(
    postRepository: ref.read(postRepositoryProvider),
    userRepository: ref.read(userRepositoryProvider),
    navigationService: ref.read(navigationServiceProvider),
    logger: ref.read(loggerProvider),
    ref: ref,
  );
});

class OwnPostProvider extends StateNotifier<PostsState> {
  final PostRepository _postRepository;
  final Logger _logger;

  OwnPostProvider({
    required PostRepository postRepository,
    required Logger logger,
  }) : _postRepository = postRepository,
       _logger = logger,
       super(const PostsState());

  Future<void> getOwnPosts(String userId) async {
    if (state.isLoading || !state.hasMore) {
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      _logger.info('Fetching own posts for user: $userId');
      
      final result = await _postRepository.getUserPosts(
        userId: userId,
        limit: 5,
        lastDocument: state.lastDocument,
      );

      result.when(
        success: (newPosts) {
          _logger.info('Successfully fetched ${newPosts.length} own posts');
          
          state = state.copyWith(
            posts: [...state.posts, ...newPosts],
            isLoading: false,
            hasMore: newPosts.length == 5,
          );
        },
        error: (message, exception) {
          _logger.error('Error fetching own posts: $message', error: exception);
          state = state.copyWith(
            isLoading: false,
            error: message,
          );
        },
      );
    } catch (e) {
      _logger.error('Unexpected error fetching own posts: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  Future<void> refreshOwnPosts(String userId) async {
    _logger.info('Refreshing own posts for user: $userId');
    // Reset the state completely before fetching the first page
    state = const PostsState();
    await getOwnPosts(userId);
  }
}

final ownPostProvider = StateNotifierProvider<OwnPostProvider, PostsState>((ref) {
  return OwnPostProvider(
    postRepository: ref.read(postRepositoryProvider),
    logger: ref.read(loggerProvider),
  );
});
