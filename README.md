# EduConnect

A comprehensive Flutter-based educational platform that facilitates communication and learning between students, instructors, and administrators.

## Overview

EduConnect is a cross-platform mobile application built with Flutter that provides a complete educational ecosystem. The app supports multiple user roles and offers features like announcements, course management, social feeds, real-time messaging, and user profiles.

## Features

### Core Functionality
- **Multi-role Authentication**: Support for students, instructors, and admin roles
- **Announcements**: System-wide notifications and educational updates
- **Course Management**: Browse, create, and manage educational courses
- **Social Feed**: Interactive home feed for educational content and discussions
- **Real-time Chat**: Messaging system for seamless communication
- **User Profiles**: Personal profiles with bookmarks and preferences
- **Content Sharing**: Create posts with images, tags, and interactions

### User Roles
- **Students**: Access courses, participate in discussions, receive announcements
- **Instructors**: Create content, manage courses, communicate with students  
- **Administrators**: System management and oversight

## Technology Stack

### Framework & Language
- **Flutter**: Cross-platform mobile development framework
- **Dart**: Programming language (SDK ^3.8.1)

### State Management
- **Riverpod**: Primary state management solution using `flutter_riverpod`
- **StateNotifier**: Pattern for managing complex state logic

### Backend Services
- **Firebase**: Primary backend infrastructure
  - Firebase Auth: User authentication and authorization
  - Cloud Firestore: NoSQL database for real-time data
  - Firebase Core: Base configuration and initialization
- **Supabase**: Secondary backend service for additional features and storage

### Key Dependencies
- `cupertino_icons`: iOS-style icons and design elements
- `flutter_svg`: SVG asset support for scalable graphics
- `salomon_bottom_bar`: Custom bottom navigation component
- `image_picker`: Image selection from gallery and camera
- `sqflite`: Local SQLite database for offline functionality
- `easy_image_viewer`: Enhanced image viewing component
- `intl`: Internationalization and localization support

## Project Structure

```
educonnect/
├── lib/                    # Main application code
│   ├── main.dart          # App entry point and configuration
│   ├── firebase_options.dart # Firebase platform configuration
│   ├── modules/           # Data models and business logic
│   │   └── user.dart     # User data model
│   ├── providers/         # Riverpod state management
│   │   ├── auth_provider.dart      # Authentication logic
│   │   ├── course_provider.dart    # Course management
│   │   ├── post_provider.dart      # Social feed posts
│   │   ├── announce_provider.dart  # Announcements
│   │   ├── profile_provider.dart   # User profiles
│   │   ├── database_provider.dart  # Database operations
│   │   └── screen_provider.dart    # UI navigation state
│   ├── screens/           # Full-screen UI components
│   │   ├── nav_screen.dart         # Authentication routing
│   │   ├── main_screen.dart        # Main app container
│   │   ├── auth_screen.dart        # Login/signup interface
│   │   ├── homefeed_screen.dart    # Social feed display
│   │   ├── courses_screen.dart     # Course listing and management
│   │   ├── chat_screen.dart        # Messaging interface
│   │   ├── profile_screen.dart     # User profile management
│   │   └── announcement_screen.dart # System announcements
│   └── widgets/           # Reusable UI components
│       ├── bottom_nav_bar.dart     # Navigation bar
│       ├── login.dart              # Login form component
│       ├── signup.dart             # Registration form
│       ├── post.dart               # Feed post component
│       ├── course.dart             # Course card display
│       └── announcement.dart       # Announcement card
├── assets/                # Static assets
│   ├── images/           # PNG/JPG images
│   └── vectors/          # SVG illustrations and icons
├── android/              # Android-specific configuration
├── ios/                  # iOS-specific configuration
├── test/                 # Unit and widget tests
├── pubspec.yaml          # Dependencies and project configuration
├── analysis_options.yaml # Dart analyzer configuration
└── firebase.json         # Firebase project configuration
```

## Getting Started

### Prerequisites
- Flutter SDK ^3.8.1
- Dart SDK
- Android Studio / Xcode for mobile development
- Firebase project setup
- Supabase project setup

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd educonnect
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com)
   - Enable Authentication, Firestore Database
   - Download and place configuration files:
     - `android/app/google-services.json` for Android
     - `ios/Runner/GoogleService-Info.plist` for iOS

4. **Configure Supabase**
   - Create a Supabase project at [Supabase Dashboard](https://supabase.com/dashboard)
   - Update the Supabase URL and anon key in `lib/main.dart`

5. **Run the application**
   ```bash
   flutter run
   ```

## Development Commands

### Running the App
```bash
# Run on default device
flutter run

# Run on specific device
flutter run -d <device-id>

# Run with hot reload (press 'r' in terminal)
# Run with hot restart (press 'R' in terminal)
```

### Code Quality
```bash
# Analyze code for issues
flutter analyze

# Format code according to Dart style
flutter format .

# Run unit and widget tests
flutter test
```

### Building for Production
```bash
# Build Android APK
flutter build apk --release

# Build iOS app
flutter build ios --release

# Build Android App Bundle (recommended for Play Store)
flutter build appbundle --release
```

## Architecture

### State Management Pattern
The app uses Riverpod for state management with the following pattern:
- **Providers**: Business logic and state management in `providers/`
- **StateNotifier**: Complex state management with immutable state
- **Consumer widgets**: UI components that react to state changes

### Navigation Flow
1. **Authentication Check**: `NavScreen` uses StreamBuilder to monitor auth state
2. **Role-based Routing**: Different interfaces based on user roles
3. **Bottom Navigation**: Tab-based navigation using Salomon Bottom Bar
4. **Screen Management**: Centralized screen state through `ScreenProvider`

### Data Flow
1. **UI Layer**: Screens and widgets consume providers
2. **State Layer**: Providers manage business logic and API calls  
3. **Data Layer**: Firebase/Supabase integration through providers
4. **Models**: Data structures defined in `modules/`

## Key Features Implementation

### Authentication System
- Firebase Auth integration with email/password
- Role-based user management (student, instructor, admin)
- Automatic navigation based on authentication state

### Course Management
- Create, read, update, delete courses
- Tag-based categorization
- Image upload support via Supabase storage
- Pagination for efficient loading

### Social Feed
- Create posts with text and images
- Like and bookmark functionality
- Tag-based content organization
- Real-time updates via Firestore

### Real-time Chat
- Messaging system between users
- Chat search functionality
- Message history and persistence

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Development Guidelines

- Follow Flutter/Dart style guidelines
- Use meaningful commit messages
- Write tests for new features
- Update documentation for significant changes
- Ensure code passes `flutter analyze` before committing

## License

This project is licensed under the MIT License - see the LICENSE file for details.
