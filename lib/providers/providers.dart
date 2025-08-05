import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/post_repository.dart';
import '../repositories/firebase_post_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/firebase_user_repository.dart';
import '../services/navigation_service.dart';
import '../core/logger.dart';

/// Shared provider instances used across the application

// Repository providers
final postRepositoryProvider = Provider<PostRepository>((ref) {
  return FirebasePostRepository();
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return FirebaseUserRepository();
});

// Service providers
final navigationServiceProvider = Provider<NavigationService>((ref) {
  return NavigationService.instance;
});

final loggerProvider = Provider<Logger>((ref) {
  return Logger();
});