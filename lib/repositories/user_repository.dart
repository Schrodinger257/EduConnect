import 'dart:io';
import '../core/result.dart';
import '../modules/user.dart';

/// Abstract repository interface for user-related operations
abstract class UserRepository {
  /// Retrieves a user by their ID
  Future<Result<User>> getUserById(String userId);

  /// Updates user profile information
  Future<Result<User>> updateUser(User user);

  /// Uploads a profile image and returns the URL
  Future<Result<String>> uploadProfileImage(File image, String userId);

  /// Deletes a profile image
  Future<Result<void>> deleteProfileImage(String userId);

  /// Searches for users by name or email
  Future<Result<List<User>>> searchUsers(String query);

  /// Gets users by role
  Future<Result<List<User>>> getUsersByRole(UserRole role);

  /// Toggles bookmark status for a post
  Future<Result<void>> toggleBookmark(String userId, String postId);

  /// Gets all bookmarked posts for a user
  Future<Result<List<String>>> getBookmarks(String userId);

  /// Updates user's liked posts
  Future<Result<void>> updateLikedPosts(String userId, List<String> likedPosts);

  /// Enrolls user in a course
  Future<Result<void>> enrollInCourse(String userId, String courseId);

  /// Unenrolls user from a course
  Future<Result<void>> unenrollFromCourse(String userId, String courseId);

  /// Gets enrolled courses for a user
  Future<Result<List<String>>> getEnrolledCourses(String userId);

  /// Creates a new user profile
  Future<Result<User>> createUser(User user);

  /// Deletes a user profile
  Future<Result<void>> deleteUser(String userId);

  /// Checks if a user exists
  Future<Result<bool>> userExists(String userId);

  /// Gets user statistics (posts count, likes received, etc.)
  Future<Result<Map<String, int>>> getUserStatistics(String userId);
}