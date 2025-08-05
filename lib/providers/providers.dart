import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/logger.dart';
import '../repositories/user_repository.dart';
import '../repositories/firebase_user_repository.dart';
import '../repositories/post_repository.dart';
import '../repositories/firebase_post_repository.dart';
import '../services/navigation_service.dart';
import '../services/image_service.dart';

/// Core providers for dependency injection

/// Logger provider
final loggerProvider = Provider<Logger>((ref) {
  return Logger();
});

/// Navigation service provider
final navigationServiceProvider = Provider<NavigationService>((ref) {
  return NavigationService();
});

/// User repository provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return FirebaseUserRepository();
});

/// Post repository provider
final postRepositoryProvider = Provider<PostRepository>((ref) {
  return FirebasePostRepository();
});

/// Image service provider
final imageServiceProvider = Provider<ImageService>((ref) {
  return ImageService();
});