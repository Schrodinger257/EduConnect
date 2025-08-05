# EduConnect AI Coding Instructions

## Project Architecture

**Flutter + Riverpod + Firebase + Supabase**: Educational platform with role-based authentication (student/instructor/admin), real-time chat, course management, and social feeds.

### Core State Management Pattern
- **Riverpod StateNotifier**: All providers use `StateNotifier<SomeState>` pattern
- **Immutable State**: State classes with `copyWith()` methods and explicit flags like `clearError`, `clearLastDocument`
- **Result<T> Pattern**: All async operations return `Result.success(data)` or `Result.error(message, exception)`
- **Provider Dependencies**: Inject via `ref.read(providerName)` in constructors, defined in `lib/providers/providers.dart`

### Authentication Flow
Authentication state flows through `authProvider` using Firebase Auth:
```dart
// Always check auth first in screens
final authState = ref.watch(authProvider);
final userId = authState.userId;
if (userId == null) {
  return Scaffold(body: Center(child: Text('Please log in...')));
}
```

### Data Layer Conventions
**Firebase/Supabase Mapping**: Firestore field names differ from model properties:
- `roleCode` ↔ `role` 
- `Bookmarks` ↔ `bookmarks`
- `createdAt` requires Timestamp ↔ DateTime conversion

**Repository Pattern**: Abstract repositories in `repositories/` with Firebase implementations
- Use `Result<T>` return types for all operations
- Comprehensive logging via `Logger()` 
- Convert Firestore data to model format in repositories

### Error Handling
- **Structured Logging**: Use `Logger()` for all operations with context
- **User-Friendly Messages**: Convert technical errors via `NavigationService.showErrorSnackBar()`
- **Graceful Degradation**: Always provide fallback UI states for loading/error/empty

### UI Patterns
**Consumer Widgets**: Use `ConsumerStatefulWidget` and watch providers:
```dart
final posts = ref.watch(postProvider.select((state) => state.posts));
final isLoading = ref.watch(postProvider.select((state) => state.isLoading));
```

**Pagination**: Use `lastDocument` for Firestore pagination and `hasMore` flag
**SVG Assets**: Loading/error states use vector assets from `assets/vectors/`

### Role-Based Features
User roles affect UI rendering and permissions:
- Check `userData['roleCode']` for conditional features
- Instructors can create courses/content
- Students can enroll and participate
- Admin has system management access

### Development Commands
```bash
# Development
flutter run                    # Hot reload development
flutter analyze               # Code quality check
flutter test                  # Run tests
flutter build apk --release   # Production build

# Firebase/Supabase integration
# Credentials in lib/firebase_options.dart and main.dart
```

### Testing Patterns
- **Provider Testing**: Use `ProviderContainer` with mock overrides
- **Widget Testing**: Mock providers and test UI states
- **Repository Testing**: Mock Firestore/Supabase clients

### Key Files to Understand
- `lib/providers/auth_provider.dart` - Authentication state management
- `lib/core/result.dart` - Error handling pattern
- `lib/repositories/firebase_user_repository.dart` - Data layer example
- `lib/modules/user.dart` - Enhanced model with validation
- `lib/core/logger.dart` - Comprehensive logging system

### Common Patterns
**Provider Creation**:
```dart
final someProvider = StateNotifierProvider<SomeNotifier, SomeState>((ref) {
  return SomeNotifier(
    repository: ref.read(repositoryProvider),
    navigationService: ref.read(navigationServiceProvider),
    logger: ref.read(loggerProvider),
  );
});
```

**State Updates**:
```dart
state = state.copyWith(
  isLoading: false,
  data: newData,
  clearError: true,
);
```

When implementing new features, follow the established provider → repository → Firebase/Supabase pattern with comprehensive logging and proper error handling.
