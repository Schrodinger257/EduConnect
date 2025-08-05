import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/result.dart';
import '../core/logger.dart';
import '../modules/course.dart';
import '../modules/user.dart';
import 'course_repository.dart';

/// Firebase implementation of CourseRepository
class FirebaseCourseRepository implements CourseRepository {
  final FirebaseFirestore _firestore;
  final Logger _logger;

  FirebaseCourseRepository({
    FirebaseFirestore? firestore,
    Logger? logger,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _logger = logger ?? Logger();

  @override
  Future<Result<List<Course>>> getCourses({
    int limit = 10,
    DocumentSnapshot? lastDocument,
    CourseStatus? status,
  }) async {
    try {
      _logger.info('Fetching courses with limit: $limit, status: ${status?.value}');
      
      Query query = _firestore
          .collection('courses')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (status != null) {
        query = query.where('status', isEqualTo: status.value);
      }

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      final courses = <Course>[];

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          
          // Convert Firestore Timestamp to DateTime
          if (data['createdAt'] is Timestamp) {
            data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
          }
          if (data['updatedAt'] is Timestamp) {
            data['updatedAt'] = (data['updatedAt'] as Timestamp).toDate().toIso8601String();
          }
          
          // Ensure required fields exist with defaults
          data['enrolledStudents'] = List<String>.from(data['enrolledStudents'] ?? []);
          data['tags'] = List<String>.from(data['tags'] ?? []);
          data['maxEnrollment'] = data['maxEnrollment'] ?? 50;
          data['status'] = data['status'] ?? 'draft';
          data['duration'] = data['duration'] ?? 0;
          
          final course = Course.fromJson(data);
          courses.add(course);
        } catch (e) {
          _logger.error('Error parsing course ${doc.id}: $e');
          // Continue processing other courses instead of failing completely
        }
      }

      _logger.info('Successfully fetched ${courses.length} courses');
      return Result.success(courses);
    } catch (e) {
      _logger.error('Error fetching courses: $e');
      return Result.error('Failed to fetch courses: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<List<Course>>> getInstructorCourses({
    required String instructorId,
    int limit = 10,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      _logger.info('Fetching courses for instructor: $instructorId with limit: $limit');
      
      Query query = _firestore
          .collection('courses')
          .where('instructorId', isEqualTo: instructorId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      final courses = <Course>[];

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          
          // Convert Firestore Timestamp to DateTime
          if (data['createdAt'] is Timestamp) {
            data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
          }
          if (data['updatedAt'] is Timestamp) {
            data['updatedAt'] = (data['updatedAt'] as Timestamp).toDate().toIso8601String();
          }
          
          // Ensure required fields exist with defaults
          data['enrolledStudents'] = List<String>.from(data['enrolledStudents'] ?? []);
          data['tags'] = List<String>.from(data['tags'] ?? []);
          data['maxEnrollment'] = data['maxEnrollment'] ?? 50;
          data['status'] = data['status'] ?? 'draft';
          data['duration'] = data['duration'] ?? 0;
          
          final course = Course.fromJson(data);
          courses.add(course);
        } catch (e) {
          _logger.error('Error parsing instructor course ${doc.id}: $e');
        }
      }

      _logger.info('Successfully fetched ${courses.length} courses for instructor $instructorId');
      return Result.success(courses);
    } catch (e) {
      _logger.error('Error fetching instructor courses: $e');
      return Result.error('Failed to fetch instructor courses: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<List<Course>>> getEnrolledCourses({
    required String studentId,
    int limit = 10,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      _logger.info('Fetching enrolled courses for student: $studentId with limit: $limit');
      
      Query query = _firestore
          .collection('courses')
          .where('enrolledStudents', arrayContains: studentId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      final courses = <Course>[];

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          
          // Convert Firestore Timestamp to DateTime
          if (data['createdAt'] is Timestamp) {
            data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
          }
          if (data['updatedAt'] is Timestamp) {
            data['updatedAt'] = (data['updatedAt'] as Timestamp).toDate().toIso8601String();
          }
          
          // Ensure required fields exist with defaults
          data['enrolledStudents'] = List<String>.from(data['enrolledStudents'] ?? []);
          data['tags'] = List<String>.from(data['tags'] ?? []);
          data['maxEnrollment'] = data['maxEnrollment'] ?? 50;
          data['status'] = data['status'] ?? 'draft';
          data['duration'] = data['duration'] ?? 0;
          
          final course = Course.fromJson(data);
          courses.add(course);
        } catch (e) {
          _logger.error('Error parsing enrolled course ${doc.id}: $e');
        }
      }

      _logger.info('Successfully fetched ${courses.length} enrolled courses for student $studentId');
      return Result.success(courses);
    } catch (e) {
      _logger.error('Error fetching enrolled courses: $e');
      return Result.error('Failed to fetch enrolled courses: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<Course>> getCourseById(String courseId) async {
    try {
      _logger.info('Fetching course with ID: $courseId');
      
      final doc = await _firestore.collection('courses').doc(courseId).get();
      
      if (!doc.exists) {
        _logger.warning('Course not found: $courseId');
        return Result.error('Course not found');
      }

      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      
      // Convert Firestore Timestamp to DateTime
      if (data['createdAt'] is Timestamp) {
        data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
      }
      if (data['updatedAt'] is Timestamp) {
        data['updatedAt'] = (data['updatedAt'] as Timestamp).toDate().toIso8601String();
      }
      
      // Ensure required fields exist with defaults
      data['enrolledStudents'] = List<String>.from(data['enrolledStudents'] ?? []);
      data['tags'] = List<String>.from(data['tags'] ?? []);
      data['maxEnrollment'] = data['maxEnrollment'] ?? 50;
      data['status'] = data['status'] ?? 'draft';
      data['duration'] = data['duration'] ?? 0;
      
      final course = Course.fromJson(data);
      
      _logger.info('Successfully fetched course: $courseId');
      return Result.success(course);
    } catch (e) {
      _logger.error('Error fetching course: $e');
      return Result.error('Failed to fetch course: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<Course>> createCourse(Course course) async {
    try {
      _logger.info('Creating course: ${course.title} by instructor: ${course.instructorId}');
      
      final courseData = course.toJson();
      // Remove the ID as Firestore will generate it
      courseData.remove('id');
      
      // Convert DateTime to Firestore Timestamp
      courseData['createdAt'] = FieldValue.serverTimestamp();
      if (courseData['updatedAt'] != null) {
        courseData['updatedAt'] = FieldValue.serverTimestamp();
      }
      
      final docRef = await _firestore.collection('courses').add(courseData);
      
      // Get the created document to return the complete course with ID
      final createdDoc = await docRef.get();
      final createdData = createdDoc.data() as Map<String, dynamic>;
      createdData['id'] = createdDoc.id;
      
      // Convert back to Course format
      if (createdData['createdAt'] is Timestamp) {
        createdData['createdAt'] = (createdData['createdAt'] as Timestamp).toDate().toIso8601String();
      }
      if (createdData['updatedAt'] is Timestamp) {
        createdData['updatedAt'] = (createdData['updatedAt'] as Timestamp).toDate().toIso8601String();
      }
      
      // Ensure required fields exist with defaults
      createdData['enrolledStudents'] = List<String>.from(createdData['enrolledStudents'] ?? []);
      createdData['tags'] = List<String>.from(createdData['tags'] ?? []);
      createdData['maxEnrollment'] = createdData['maxEnrollment'] ?? 50;
      createdData['status'] = createdData['status'] ?? 'draft';
      createdData['duration'] = createdData['duration'] ?? 0;
      
      final createdCourse = Course.fromJson(createdData);
      
      _logger.info('Successfully created course with ID: ${createdCourse.id}');
      return Result.success(createdCourse);
    } catch (e) {
      _logger.error('Error creating course: $e');
      return Result.error('Failed to create course: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<Course>> updateCourse(Course course) async {
    try {
      _logger.info('Updating course: ${course.id}');
      
      final courseData = course.toJson();
      courseData.remove('id');
      
      // Convert DateTime to Firestore Timestamp for updatedAt
      courseData['updatedAt'] = FieldValue.serverTimestamp();
      
      // Keep createdAt as is if it's already a Timestamp
      if (courseData['createdAt'] is String) {
        courseData['createdAt'] = Timestamp.fromDate(DateTime.parse(courseData['createdAt']));
      }
      
      await _firestore.collection('courses').doc(course.id).update(courseData);
      
      // Return the updated course
      final updatedCourseResult = await getCourseById(course.id);
      if (updatedCourseResult.isError) {
        return updatedCourseResult;
      }
      
      _logger.info('Successfully updated course: ${course.id}');
      return Result.success(updatedCourseResult.data!);
    } catch (e) {
      _logger.error('Error updating course: $e');
      return Result.error('Failed to update course: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteCourse(String courseId) async {
    try {
      _logger.info('Deleting course: $courseId');
      
      // Remove course from all enrolled students' enrolledCourses list
      final courseDoc = await _firestore.collection('courses').doc(courseId).get();
      if (courseDoc.exists) {
        final courseData = courseDoc.data() as Map<String, dynamic>;
        final enrolledStudents = List<String>.from(courseData['enrolledStudents'] ?? []);
        
        final batch = _firestore.batch();
        
        // Remove course from each student's enrolled courses
        for (final studentId in enrolledStudents) {
          final studentRef = _firestore.collection('users').doc(studentId);
          batch.update(studentRef, {
            'enrolledCourses': FieldValue.arrayRemove([courseId]),
          });
        }
        
        // Delete the course document
        batch.delete(_firestore.collection('courses').doc(courseId));
        
        await batch.commit();
      } else {
        // Course doesn't exist, just try to delete it
        await _firestore.collection('courses').doc(courseId).delete();
      }
      
      _logger.info('Successfully deleted course: $courseId');
      return Result.success(null);
    } catch (e) {
      _logger.error('Error deleting course: $e');
      return Result.error('Failed to delete course: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> enrollStudent(String courseId, String studentId) async {
    try {
      _logger.info('Enrolling student: $studentId in course: $courseId');
      
      final courseRef = _firestore.collection('courses').doc(courseId);
      final userRef = _firestore.collection('users').doc(studentId);
      
      await _firestore.runTransaction((transaction) async {
        final courseDoc = await transaction.get(courseRef);
        final userDoc = await transaction.get(userRef);
        
        if (!courseDoc.exists) {
          throw Exception('Course not found');
        }
        
        if (!userDoc.exists) {
          throw Exception('User not found');
        }
        
        final courseData = courseDoc.data() as Map<String, dynamic>;
        final userData = userDoc.data() as Map<String, dynamic>;
        
        final enrolledStudents = List<String>.from(courseData['enrolledStudents'] ?? []);
        final enrolledCourses = List<String>.from(userData['enrolledCourses'] ?? []);
        final maxEnrollment = courseData['maxEnrollment'] as int? ?? 50;
        
        // Check if student is already enrolled
        if (enrolledStudents.contains(studentId)) {
          throw Exception('Student is already enrolled in this course');
        }
        
        // Check if course is full
        if (enrolledStudents.length >= maxEnrollment) {
          throw Exception('Course is full');
        }
        
        // Check if course is published
        final status = courseData['status'] as String? ?? 'draft';
        if (status != 'published') {
          throw Exception('Course is not available for enrollment');
        }
        
        // Add student to course and course to student
        enrolledStudents.add(studentId);
        enrolledCourses.add(courseId);
        
        transaction.update(courseRef, {
          'enrolledStudents': enrolledStudents,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        transaction.update(userRef, {'enrolledCourses': enrolledCourses});
      });
      
      _logger.info('Successfully enrolled student: $studentId in course: $courseId');
      return Result.success(null);
    } catch (e) {
      _logger.error('Error enrolling student: $e');
      return Result.error('Failed to enroll student: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> unenrollStudent(String courseId, String studentId) async {
    try {
      _logger.info('Unenrolling student: $studentId from course: $courseId');
      
      final courseRef = _firestore.collection('courses').doc(courseId);
      final userRef = _firestore.collection('users').doc(studentId);
      
      await _firestore.runTransaction((transaction) async {
        final courseDoc = await transaction.get(courseRef);
        final userDoc = await transaction.get(userRef);
        
        if (!courseDoc.exists) {
          throw Exception('Course not found');
        }
        
        if (!userDoc.exists) {
          throw Exception('User not found');
        }
        
        final courseData = courseDoc.data() as Map<String, dynamic>;
        final userData = userDoc.data() as Map<String, dynamic>;
        
        final enrolledStudents = List<String>.from(courseData['enrolledStudents'] ?? []);
        final enrolledCourses = List<String>.from(userData['enrolledCourses'] ?? []);
        
        // Remove student from course and course from student
        enrolledStudents.remove(studentId);
        enrolledCourses.remove(courseId);
        
        transaction.update(courseRef, {
          'enrolledStudents': enrolledStudents,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        transaction.update(userRef, {'enrolledCourses': enrolledCourses});
      });
      
      _logger.info('Successfully unenrolled student: $studentId from course: $courseId');
      return Result.success(null);
    } catch (e) {
      _logger.error('Error unenrolling student: $e');
      return Result.error('Failed to unenroll student: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<List<User>>> getEnrolledStudents(String courseId) async {
    try {
      _logger.info('Fetching enrolled students for course: $courseId');
      
      final courseDoc = await _firestore.collection('courses').doc(courseId).get();
      
      if (!courseDoc.exists) {
        return Result.error('Course not found');
      }
      
      final courseData = courseDoc.data() as Map<String, dynamic>;
      final enrolledStudentIds = List<String>.from(courseData['enrolledStudents'] ?? []);
      
      if (enrolledStudentIds.isEmpty) {
        _logger.info('No students enrolled in course: $courseId');
        return Result.success(<User>[]);
      }
      
      // Fetch user documents for enrolled students
      final usersSnapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: enrolledStudentIds)
          .get();
      
      final students = <User>[];
      
      for (final doc in usersSnapshot.docs) {
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
          students.add(user);
        } catch (e) {
          _logger.error('Error parsing enrolled student ${doc.id}: $e');
        }
      }
      
      _logger.info('Successfully fetched ${students.length} enrolled students for course: $courseId');
      return Result.success(students);
    } catch (e) {
      _logger.error('Error fetching enrolled students: $e');
      return Result.error('Failed to fetch enrolled students: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<bool>> isStudentEnrolled(String courseId, String studentId) async {
    try {
      _logger.info('Checking if student: $studentId is enrolled in course: $courseId');
      
      final courseDoc = await _firestore.collection('courses').doc(courseId).get();
      
      if (!courseDoc.exists) {
        return Result.error('Course not found');
      }
      
      final courseData = courseDoc.data() as Map<String, dynamic>;
      final enrolledStudents = List<String>.from(courseData['enrolledStudents'] ?? []);
      final isEnrolled = enrolledStudents.contains(studentId);
      
      _logger.info('Student enrollment check for $studentId in course $courseId: $isEnrolled');
      return Result.success(isEnrolled);
    } catch (e) {
      _logger.error('Error checking student enrollment: $e');
      return Result.error('Failed to check student enrollment: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<Map<String, int>>> getCourseStatistics(String courseId) async {
    try {
      _logger.info('Fetching statistics for course: $courseId');
      
      final courseDoc = await _firestore.collection('courses').doc(courseId).get();
      
      if (!courseDoc.exists) {
        return Result.error('Course not found');
      }
      
      final courseData = courseDoc.data() as Map<String, dynamic>;
      final enrolledStudents = List<String>.from(courseData['enrolledStudents'] ?? []);
      final maxEnrollment = courseData['maxEnrollment'] as int? ?? 50;
      
      final statistics = {
        'enrolledCount': enrolledStudents.length,
        'maxEnrollment': maxEnrollment,
        'availableSpots': maxEnrollment - enrolledStudents.length,
        'enrollmentPercentage': ((enrolledStudents.length / maxEnrollment) * 100).round(),
      };
      
      _logger.info('Successfully fetched statistics for course: $courseId');
      return Result.success(statistics);
    } catch (e) {
      _logger.error('Error fetching course statistics: $e');
      return Result.error('Failed to fetch course statistics: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<List<Course>>> searchCourses(String query) async {
    try {
      _logger.info('Searching courses with query: $query');
      
      // Note: Firestore doesn't support full-text search natively
      // This is a basic implementation that searches in tags
      // For production, consider using Algolia or similar service
      
      final snapshot = await _firestore
          .collection('courses')
          .where('tags', arrayContainsAny: [query.toLowerCase()])
          .where('status', isEqualTo: 'published')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      
      final courses = <Course>[];
      
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          
          // Convert Firestore Timestamp to DateTime
          if (data['createdAt'] is Timestamp) {
            data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
          }
          if (data['updatedAt'] is Timestamp) {
            data['updatedAt'] = (data['updatedAt'] as Timestamp).toDate().toIso8601String();
          }
          
          // Ensure required fields exist with defaults
          data['enrolledStudents'] = List<String>.from(data['enrolledStudents'] ?? []);
          data['tags'] = List<String>.from(data['tags'] ?? []);
          data['maxEnrollment'] = data['maxEnrollment'] ?? 50;
          data['status'] = data['status'] ?? 'draft';
          data['duration'] = data['duration'] ?? 0;
          
          final course = Course.fromJson(data);
          
          // Additional client-side filtering for title and description search
          if (course.matchesSearch(query)) {
            courses.add(course);
          }
        } catch (e) {
          _logger.error('Error parsing search result ${doc.id}: $e');
        }
      }
      
      _logger.info('Successfully found ${courses.length} courses matching query: $query');
      return Result.success(courses);
    } catch (e) {
      _logger.error('Error searching courses: $e');
      return Result.error('Failed to search courses: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<List<Course>>> getCoursesByCategory(String category) async {
    try {
      _logger.info('Fetching courses by category: $category');
      
      final snapshot = await _firestore
          .collection('courses')
          .where('category', isEqualTo: category)
          .where('status', isEqualTo: 'published')
          .orderBy('createdAt', descending: true)
          .get();
      
      final courses = <Course>[];
      
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          
          // Convert Firestore Timestamp to DateTime
          if (data['createdAt'] is Timestamp) {
            data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
          }
          if (data['updatedAt'] is Timestamp) {
            data['updatedAt'] = (data['updatedAt'] as Timestamp).toDate().toIso8601String();
          }
          
          // Ensure required fields exist with defaults
          data['enrolledStudents'] = List<String>.from(data['enrolledStudents'] ?? []);
          data['tags'] = List<String>.from(data['tags'] ?? []);
          data['maxEnrollment'] = data['maxEnrollment'] ?? 50;
          data['status'] = data['status'] ?? 'draft';
          data['duration'] = data['duration'] ?? 0;
          
          final course = Course.fromJson(data);
          courses.add(course);
        } catch (e) {
          _logger.error('Error parsing course by category ${doc.id}: $e');
        }
      }
      
      _logger.info('Successfully fetched ${courses.length} courses in category: $category');
      return Result.success(courses);
    } catch (e) {
      _logger.error('Error fetching courses by category: $e');
      return Result.error('Failed to fetch courses by category: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<List<Course>>> getCoursesByStatus(CourseStatus status) async {
    try {
      _logger.info('Fetching courses by status: ${status.value}');
      
      final snapshot = await _firestore
          .collection('courses')
          .where('status', isEqualTo: status.value)
          .orderBy('createdAt', descending: true)
          .get();
      
      final courses = <Course>[];
      
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          
          // Convert Firestore Timestamp to DateTime
          if (data['createdAt'] is Timestamp) {
            data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
          }
          if (data['updatedAt'] is Timestamp) {
            data['updatedAt'] = (data['updatedAt'] as Timestamp).toDate().toIso8601String();
          }
          
          // Ensure required fields exist with defaults
          data['enrolledStudents'] = List<String>.from(data['enrolledStudents'] ?? []);
          data['tags'] = List<String>.from(data['tags'] ?? []);
          data['maxEnrollment'] = data['maxEnrollment'] ?? 50;
          data['status'] = data['status'] ?? 'draft';
          data['duration'] = data['duration'] ?? 0;
          
          final course = Course.fromJson(data);
          courses.add(course);
        } catch (e) {
          _logger.error('Error parsing course by status ${doc.id}: $e');
        }
      }
      
      _logger.info('Successfully fetched ${courses.length} courses with status: ${status.value}');
      return Result.success(courses);
    } catch (e) {
      _logger.error('Error fetching courses by status: $e');
      return Result.error('Failed to fetch courses by status: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<List<Course>>> getPopularCourses({int limit = 10}) async {
    try {
      _logger.info('Fetching popular courses with limit: $limit');
      
      final snapshot = await _firestore
          .collection('courses')
          .where('status', isEqualTo: 'published')
          .orderBy('createdAt', descending: true)
          .get();
      
      final courses = <Course>[];
      
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          
          // Convert Firestore Timestamp to DateTime
          if (data['createdAt'] is Timestamp) {
            data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
          }
          if (data['updatedAt'] is Timestamp) {
            data['updatedAt'] = (data['updatedAt'] as Timestamp).toDate().toIso8601String();
          }
          
          // Ensure required fields exist with defaults
          data['enrolledStudents'] = List<String>.from(data['enrolledStudents'] ?? []);
          data['tags'] = List<String>.from(data['tags'] ?? []);
          data['maxEnrollment'] = data['maxEnrollment'] ?? 50;
          data['status'] = data['status'] ?? 'draft';
          data['duration'] = data['duration'] ?? 0;
          
          final course = Course.fromJson(data);
          courses.add(course);
        } catch (e) {
          _logger.error('Error parsing popular course ${doc.id}: $e');
        }
      }
      
      // Sort by enrollment percentage (popularity)
      courses.sort((a, b) => b.enrollmentPercentage.compareTo(a.enrollmentPercentage));
      
      // Take only the requested limit
      final popularCourses = courses.take(limit).toList();
      
      _logger.info('Successfully fetched ${popularCourses.length} popular courses');
      return Result.success(popularCourses);
    } catch (e) {
      _logger.error('Error fetching popular courses: $e');
      return Result.error('Failed to fetch popular courses: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<List<Course>>> getRecentCourses({int limit = 10}) async {
    try {
      _logger.info('Fetching recent courses with limit: $limit');
      
      final snapshot = await _firestore
          .collection('courses')
          .where('status', isEqualTo: 'published')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      final courses = <Course>[];
      
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          
          // Convert Firestore Timestamp to DateTime
          if (data['createdAt'] is Timestamp) {
            data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
          }
          if (data['updatedAt'] is Timestamp) {
            data['updatedAt'] = (data['updatedAt'] as Timestamp).toDate().toIso8601String();
          }
          
          // Ensure required fields exist with defaults
          data['enrolledStudents'] = List<String>.from(data['enrolledStudents'] ?? []);
          data['tags'] = List<String>.from(data['tags'] ?? []);
          data['maxEnrollment'] = data['maxEnrollment'] ?? 50;
          data['status'] = data['status'] ?? 'draft';
          data['duration'] = data['duration'] ?? 0;
          
          final course = Course.fromJson(data);
          courses.add(course);
        } catch (e) {
          _logger.error('Error parsing recent course ${doc.id}: $e');
        }
      }
      
      _logger.info('Successfully fetched ${courses.length} recent courses');
      return Result.success(courses);
    } catch (e) {
      _logger.error('Error fetching recent courses: $e');
      return Result.error('Failed to fetch recent courses: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<Course>> updateCourseStatus(String courseId, CourseStatus status) async {
    try {
      _logger.info('Updating course status: $courseId to ${status.value}');
      
      await _firestore.collection('courses').doc(courseId).update({
        'status': status.value,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Return the updated course
      final updatedCourseResult = await getCourseById(courseId);
      if (updatedCourseResult.isError) {
        return updatedCourseResult;
      }
      
      _logger.info('Successfully updated course status: $courseId to ${status.value}');
      return Result.success(updatedCourseResult.data!);
    } catch (e) {
      _logger.error('Error updating course status: $e');
      return Result.error('Failed to update course status: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Stream<List<Course>> getCoursesStream({int limit = 10}) {
    _logger.info('Creating courses stream with limit: $limit');
    
    return _firestore
        .collection('courses')
        .where('status', isEqualTo: 'published')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final courses = <Course>[];
      
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          
          // Convert Firestore Timestamp to DateTime
          if (data['createdAt'] is Timestamp) {
            data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
          }
          if (data['updatedAt'] is Timestamp) {
            data['updatedAt'] = (data['updatedAt'] as Timestamp).toDate().toIso8601String();
          }
          
          // Ensure required fields exist with defaults
          data['enrolledStudents'] = List<String>.from(data['enrolledStudents'] ?? []);
          data['tags'] = List<String>.from(data['tags'] ?? []);
          data['maxEnrollment'] = data['maxEnrollment'] ?? 50;
          data['status'] = data['status'] ?? 'draft';
          data['duration'] = data['duration'] ?? 0;
          
          final course = Course.fromJson(data);
          courses.add(course);
        } catch (e) {
          _logger.error('Error parsing course ${doc.id} in stream: $e');
        }
      }
      
      return courses;
    });
  }

  @override
  Stream<List<User>> getEnrolledStudentsStream(String courseId) {
    _logger.info('Creating enrolled students stream for course: $courseId');
    
    return _firestore
        .collection('courses')
        .doc(courseId)
        .snapshots()
        .asyncMap((courseDoc) async {
      if (!courseDoc.exists) {
        return <User>[];
      }

      final courseData = courseDoc.data() as Map<String, dynamic>;
      final enrolledStudentIds = List<String>.from(courseData['enrolledStudents'] ?? []);
      
      if (enrolledStudentIds.isEmpty) {
        return <User>[];
      }

      try {
        final usersSnapshot = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: enrolledStudentIds)
            .get();

        final students = <User>[];
        
        for (final doc in usersSnapshot.docs) {
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
            students.add(user);
          } catch (e) {
            _logger.error('Error parsing enrolled student ${doc.id} in stream: $e');
          }
        }
        
        return students;
      } catch (e) {
        _logger.error('Error fetching enrolled students in stream: $e');
        return <User>[];
      }
    });
  }

  @override
  Future<Result<bool>> isEnrollmentAvailable(String courseId) async {
    try {
      _logger.info('Checking enrollment availability for course: $courseId');
      
      final courseDoc = await _firestore.collection('courses').doc(courseId).get();
      
      if (!courseDoc.exists) {
        return Result.error('Course not found');
      }
      
      final courseData = courseDoc.data() as Map<String, dynamic>;
      final enrolledStudents = List<String>.from(courseData['enrolledStudents'] ?? []);
      final maxEnrollment = courseData['maxEnrollment'] as int? ?? 50;
      final status = courseData['status'] as String? ?? 'draft';
      
      final isAvailable = status == 'published' && enrolledStudents.length < maxEnrollment;
      
      _logger.info('Enrollment availability for course $courseId: $isAvailable');
      return Result.success(isAvailable);
    } catch (e) {
      _logger.error('Error checking enrollment availability: $e');
      return Result.error('Failed to check enrollment availability: ${e.toString()}', Exception(e.toString()));
    }
  }

  @override
  Future<Result<List<String>>> getCourseCategories() async {
    try {
      _logger.info('Fetching course categories');
      
      final snapshot = await _firestore
          .collection('courses')
          .where('status', isEqualTo: 'published')
          .get();
      
      final categories = <String>{};
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final category = data['category'] as String?;
        if (category != null && category.isNotEmpty) {
          categories.add(category);
        }
      }
      
      final categoryList = categories.toList()..sort();
      
      _logger.info('Successfully fetched ${categoryList.length} course categories');
      return Result.success(categoryList);
    } catch (e) {
      _logger.error('Error fetching course categories: $e');
      return Result.error('Failed to fetch course categories: ${e.toString()}', Exception(e.toString()));
    }
  }
}