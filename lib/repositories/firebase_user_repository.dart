import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/result.dart';
import '../core/logger.dart';
import '../modules/user.dart';
import 'user_repository.dart';

/// Firebase implementation of UserRepository with Supabase for file storage
class FirebaseUserRepository implements UserRepository {
  final FirebaseFirestore _firestore;
  final SupabaseClient _supabase;
  final Logger _logger;

  FirebaseUserRepository({
    FirebaseFirestore? firestore,
    SupabaseClient? supabase,
    Logger? logger,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _supabase = supabase ?? Supabase.instance.client,
       _logger = logger ?? Logger();

  @override
  Future<Result<User>> getUserById(String userId) async {
    try {
      _logger.info('Fetching user with ID: $userId');
      
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (!doc.exists) {
        _logger.warning('User not found: $userId');
        return Result.error('User not found');
      }

      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      
      // Convert Firestore Timestamp to DateTime
      if (data['createdAt'] is Timestamp) {
        data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
      }
      
      // Map Firestore field names to User model field names
      data['bookmarks'] = List<String>.from(data['Bookmarks'] ?? []);
      data['likedPosts'] = List<String>.from(data['likedPosts'] ?? []);
      data['enrolledCourses'] = List<String>.from(data['enrolledCourses'] ?? []);
      data['role'] = data['roleCode'] ?? data['role'];
      data['profileImage'] = data['profileImage'];
      
      final user = User.fromJson(data);
      
      _logger.info('Successfully fetched user: $userId');
      return Result.success(user);
    } catch (e) {
      _logger.error('Error fetching user: $e');
      return Result.error('Failed to fetch user: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<User>> updateUser(User user) async {
    try {
      _logger.info('Updating user: ${user.id}');
      
      final userData = user.toJson();
      userData.remove('id');
      
      // Map User model field names to Firestore field names
      userData['roleCode'] = userData['role'];
      userData['Bookmarks'] = userData['bookmarks'];
      userData.remove('role');
      userData.remove('bookmarks');
      
      // Convert DateTime to Firestore Timestamp for createdAt
      if (userData['createdAt'] is String) {
        userData['createdAt'] = Timestamp.fromDate(DateTime.parse(userData['createdAt']));
      }
      
      await _firestore.collection('users').doc(user.id).update(userData);
      
      // Return the updated user
      final updatedUserResult = await getUserById(user.id);
      if (updatedUserResult.isError) {
        return updatedUserResult;
      }
      
      _logger.info('Successfully updated user: ${user.id}');
      return Result.success(updatedUserResult.data!);
    } catch (e) {
      _logger.error('Error updating user: $e');
      return Result.error('Failed to update user: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<String>> uploadProfileImage(File image, String userId) async {
    try {
      _logger.info('Uploading profile image for user: $userId');
      
      // Validate file size (max 5MB)
      final fileSize = await image.length();
      if (fileSize > 5 * 1024 * 1024) {
        return Result.error('Image file size cannot exceed 5MB');
      }
      
      // Validate file type
      final fileName = image.path.toLowerCase();
      if (!fileName.endsWith('.jpg') && 
          !fileName.endsWith('.jpeg') && 
          !fileName.endsWith('.png')) {
        return Result.error('Only JPG, JPEG, and PNG files are allowed');
      }
      
      // Remove existing profile image if it exists
      try {
        await _supabase.storage.from('profiles').remove(['$userId.png']);
        await _supabase.storage.from('profiles').remove(['$userId.jpg']);
        await _supabase.storage.from('profiles').remove(['$userId.jpeg']);
      } catch (e) {
        // Ignore errors when removing non-existent files
        _logger.info('No existing profile image to remove for user: $userId');
      }
      
      // Upload new image
      final fileExtension = fileName.split('.').last;
      final uploadPath = '$userId.$fileExtension';
      
      await _supabase.storage.from('profiles').upload(
        uploadPath,
        image,
        fileOptions: const FileOptions(
          upsert: true,
        ),
      );
      
      // Get public URL
      final publicUrl = _supabase.storage.from('profiles').getPublicUrl(uploadPath);
      
      // Update user document with new profile image URL
      await _firestore.collection('users').doc(userId).update({
        'profileImage': publicUrl,
      });
      
      _logger.info('Successfully uploaded profile image for user: $userId');
      return Result.success(publicUrl);
    } catch (e) {
      _logger.error('Error uploading profile image: $e');
      return Result.error('Failed to upload profile image: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteProfileImage(String userId) async {
    try {
      _logger.info('Deleting profile image for user: $userId');
      
      // Try to remove all possible image formats
      final extensions = ['png', 'jpg', 'jpeg'];
      for (final ext in extensions) {
        try {
          await _supabase.storage.from('profiles').remove(['$userId.$ext']);
        } catch (e) {
          // Ignore errors for non-existent files
        }
      }
      
      // Update user document to remove profile image URL
      await _firestore.collection('users').doc(userId).update({
        'profileImage': FieldValue.delete(),
      });
      
      _logger.info('Successfully deleted profile image for user: $userId');
      return Result.success(null);
    } catch (e) {
      _logger.error('Error deleting profile image: $e');
      return Result.error('Failed to delete profile image: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<List<User>>> searchUsers(String query) async {
    try {
      _logger.info('Searching users with query: $query');
      
      final lowerQuery = query.toLowerCase();
      
      // Search by name (case-insensitive)
      final nameQuery = await _firestore
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(20)
          .get();
      
      // Search by email (case-insensitive)
      final emailQuery = await _firestore
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: lowerQuery)
          .where('email', isLessThanOrEqualTo: '$lowerQuery\uf8ff')
          .limit(20)
          .get();
      
      final users = <User>[];
      final seenIds = <String>{};
      
      // Process name search results
      for (final doc in nameQuery.docs) {
        if (!seenIds.contains(doc.id)) {
          try {
            final data = doc.data();
            data['id'] = doc.id;
            
            // Convert Firestore data to User model format
            if (data['createdAt'] is Timestamp) {
              data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
            }
            
            data['bookmarks'] = List<String>.from(data['Bookmarks'] ?? []);
            data['likedPosts'] = List<String>.from(data['likedPosts'] ?? []);
            data['enrolledCourses'] = List<String>.from(data['enrolledCourses'] ?? []);
            data['role'] = data['roleCode'] ?? data['role'];
            
            final user = User.fromJson(data);
            users.add(user);
            seenIds.add(doc.id);
          } catch (e) {
            _logger.error('Error parsing user ${doc.id} in search: $e');
          }
        }
      }
      
      // Process email search results
      for (final doc in emailQuery.docs) {
        if (!seenIds.contains(doc.id)) {
          try {
            final data = doc.data();
            data['id'] = doc.id;
            
            // Convert Firestore data to User model format
            if (data['createdAt'] is Timestamp) {
              data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
            }
            
            data['bookmarks'] = List<String>.from(data['Bookmarks'] ?? []);
            data['likedPosts'] = List<String>.from(data['likedPosts'] ?? []);
            data['enrolledCourses'] = List<String>.from(data['enrolledCourses'] ?? []);
            data['role'] = data['roleCode'] ?? data['role'];
            
            final user = User.fromJson(data);
            users.add(user);
            seenIds.add(doc.id);
          } catch (e) {
            _logger.error('Error parsing user ${doc.id} in search: $e');
          }
        }
      }
      
      _logger.info('Successfully found ${users.length} users matching query: $query');
      return Result.success(users);
    } catch (e) {
      _logger.error('Error searching users: $e');
      return Result.error('Failed to search users: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<List<User>>> getUsersByRole(UserRole role) async {
    try {
      _logger.info('Fetching users with role: ${role.value}');
      
      final snapshot = await _firestore
          .collection('users')
          .where('roleCode', isEqualTo: role.value)
          .get();
      
      final users = <User>[];
      
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          
          // Convert Firestore data to User model format
          if (data['createdAt'] is Timestamp) {
            data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
          }
          
          data['bookmarks'] = List<String>.from(data['Bookmarks'] ?? []);
          data['likedPosts'] = List<String>.from(data['likedPosts'] ?? []);
          data['enrolledCourses'] = List<String>.from(data['enrolledCourses'] ?? []);
          data['role'] = data['roleCode'] ?? data['role'];
          
          final user = User.fromJson(data);
          users.add(user);
        } catch (e) {
          _logger.error('Error parsing user ${doc.id} by role: $e');
        }
      }
      
      _logger.info('Successfully fetched ${users.length} users with role: ${role.value}');
      return Result.success(users);
    } catch (e) {
      _logger.error('Error fetching users by role: $e');
      return Result.error('Failed to fetch users by role: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> toggleBookmark(String userId, String postId) async {
    try {
      _logger.info('Toggling bookmark for user: $userId, post: $postId');
      
      final userRef = _firestore.collection('users').doc(userId);
      
      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);
        
        if (!userDoc.exists) {
          throw Exception('User not found');
        }
        
        final userData = userDoc.data() as Map<String, dynamic>;
        final bookmarks = List<String>.from(userData['Bookmarks'] ?? []);
        
        if (bookmarks.contains(postId)) {
          // Remove bookmark
          bookmarks.remove(postId);
        } else {
          // Add bookmark
          bookmarks.add(postId);
        }
        
        transaction.update(userRef, {'Bookmarks': bookmarks});
      });
      
      _logger.info('Successfully toggled bookmark for user: $userId, post: $postId');
      return Result.success(null);
    } catch (e) {
      _logger.error('Error toggling bookmark: $e');
      return Result.error('Failed to toggle bookmark: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<List<String>>> getBookmarks(String userId) async {
    try {
      _logger.info('Fetching bookmarks for user: $userId');
      
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (!doc.exists) {
        return Result.error('User not found');
      }
      
      final data = doc.data() as Map<String, dynamic>;
      final bookmarks = List<String>.from(data['Bookmarks'] ?? []);
      
      _logger.info('Successfully fetched ${bookmarks.length} bookmarks for user: $userId');
      return Result.success(bookmarks);
    } catch (e) {
      _logger.error('Error fetching bookmarks: $e');
      return Result.error('Failed to fetch bookmarks: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> updateLikedPosts(String userId, List<String> likedPosts) async {
    try {
      _logger.info('Updating liked posts for user: $userId');
      
      await _firestore.collection('users').doc(userId).update({
        'likedPosts': likedPosts,
      });
      
      _logger.info('Successfully updated liked posts for user: $userId');
      return Result.success(null);
    } catch (e) {
      _logger.error('Error updating liked posts: $e');
      return Result.error('Failed to update liked posts: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> enrollInCourse(String userId, String courseId) async {
    try {
      _logger.info('Enrolling user: $userId in course: $courseId');
      
      await _firestore.collection('users').doc(userId).update({
        'enrolledCourses': FieldValue.arrayUnion([courseId]),
      });
      
      _logger.info('Successfully enrolled user: $userId in course: $courseId');
      return Result.success(null);
    } catch (e) {
      _logger.error('Error enrolling in course: $e');
      return Result.error('Failed to enroll in course: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> unenrollFromCourse(String userId, String courseId) async {
    try {
      _logger.info('Unenrolling user: $userId from course: $courseId');
      
      await _firestore.collection('users').doc(userId).update({
        'enrolledCourses': FieldValue.arrayRemove([courseId]),
      });
      
      _logger.info('Successfully unenrolled user: $userId from course: $courseId');
      return Result.success(null);
    } catch (e) {
      _logger.error('Error unenrolling from course: $e');
      return Result.error('Failed to unenroll from course: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<List<String>>> getEnrolledCourses(String userId) async {
    try {
      _logger.info('Fetching enrolled courses for user: $userId');
      
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (!doc.exists) {
        return Result.error('User not found');
      }
      
      final data = doc.data() as Map<String, dynamic>;
      final enrolledCourses = List<String>.from(data['enrolledCourses'] ?? []);
      
      _logger.info('Successfully fetched ${enrolledCourses.length} enrolled courses for user: $userId');
      return Result.success(enrolledCourses);
    } catch (e) {
      _logger.error('Error fetching enrolled courses: $e');
      return Result.error('Failed to fetch enrolled courses: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<User>> createUser(User user) async {
    try {
      _logger.info('Creating user: ${user.email}');
      
      final userData = user.toJson();
      userData.remove('id');
      
      // Map User model field names to Firestore field names
      userData['roleCode'] = userData['role'];
      userData['Bookmarks'] = userData['bookmarks'];
      userData.remove('role');
      userData.remove('bookmarks');
      
      // Convert DateTime to Firestore Timestamp
      userData['createdAt'] = FieldValue.serverTimestamp();
      
      final docRef = await _firestore.collection('users').doc(user.id).set(userData);
      
      // Return the created user
      final createdUserResult = await getUserById(user.id);
      if (createdUserResult.isError) {
        return createdUserResult;
      }
      
      _logger.info('Successfully created user: ${user.id}');
      return Result.success(createdUserResult.data!);
    } catch (e) {
      _logger.error('Error creating user: $e');
      return Result.error('Failed to create user: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteUser(String userId) async {
    try {
      _logger.info('Deleting user: $userId');
      
      // Delete profile image if exists
      await deleteProfileImage(userId);
      
      // Delete user document
      await _firestore.collection('users').doc(userId).delete();
      
      _logger.info('Successfully deleted user: $userId');
      return Result.success(null);
    } catch (e) {
      _logger.error('Error deleting user: $e');
      return Result.error('Failed to delete user: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<bool>> userExists(String userId) async {
    try {
      _logger.info('Checking if user exists: $userId');
      
      final doc = await _firestore.collection('users').doc(userId).get();
      final exists = doc.exists;
      
      _logger.info('User exists check for $userId: $exists');
      return Result.success(exists);
    } catch (e) {
      _logger.error('Error checking user existence: $e');
      return Result.error('Failed to check user existence: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<Map<String, int>>> getUserStatistics(String userId) async {
    try {
      _logger.info('Fetching statistics for user: $userId');
      
      // Get user's posts count
      final postsSnapshot = await _firestore
          .collection('posts')
          .where('userid', isEqualTo: userId)
          .get();
      
      // Get user's comments count
      final commentsSnapshot = await _firestore
          .collection('comments')
          .where('userId', isEqualTo: userId)
          .get();
      
      // Get likes received on user's posts
      int likesReceived = 0;
      for (final doc in postsSnapshot.docs) {
        final data = doc.data();
        final likes = List<String>.from(data['likes'] ?? []);
        likesReceived += likes.length;
      }
      
      // Get user data for additional stats
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data() as Map<String, dynamic>? ?? {};
      
      final statistics = {
        'postsCount': postsSnapshot.docs.length,
        'commentsCount': commentsSnapshot.docs.length,
        'likesReceived': likesReceived,
        'bookmarksCount': (userData['Bookmarks'] as List?)?.length ?? 0,
        'enrolledCoursesCount': (userData['enrolledCourses'] as List?)?.length ?? 0,
      };
      
      _logger.info('Successfully fetched statistics for user: $userId');
      return Result.success(statistics);
    } catch (e) {
      _logger.error('Error fetching user statistics: $e');
      return Result.error('Failed to fetch user statistics: ${e.toString()}', Exception(e.toString()));
    }
  }
}