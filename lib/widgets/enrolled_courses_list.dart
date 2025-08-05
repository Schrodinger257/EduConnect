import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../modules/course.dart';
import '../providers/enrollment_provider.dart';

/// Widget for displaying a student's enrolled courses
class EnrolledCoursesList extends ConsumerStatefulWidget {
  final String studentId;
  final bool showProgress;
  final VoidCallback? onCourseSelected;

  const EnrolledCoursesList({
    super.key,
    required this.studentId,
    this.showProgress = true,
    this.onCourseSelected,
  });

  @override
  ConsumerState<EnrolledCoursesList> createState() => _EnrolledCoursesListState();
}

class _EnrolledCoursesListState extends ConsumerState<EnrolledCoursesList> {
  @override
  void initState() {
    super.initState();
    // Load enrolled courses when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(enrollmentProvider.notifier).loadStudentEnrolledCourses(widget.studentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final enrollmentState = ref.watch(enrollmentProvider);
    final enrolledCourses = enrollmentState.enrolledCourses;
    final isLoading = enrollmentState.isLoading;
    final error = enrollmentState.error;

    if (isLoading && enrolledCourses.isEmpty) {
      return _buildLoadingState();
    }

    if (error != null && enrolledCourses.isEmpty) {
      return _buildErrorState(error);
    }

    if (enrolledCourses.isEmpty) {
      return _buildEmptyState();
    }

    return _buildCoursesList(enrolledCourses, isLoading);
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.showProgress) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
          ],
          Text(
            'Loading enrolled courses...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load enrolled courses',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _refreshCourses,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Enrolled Courses',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You haven\'t enrolled in any courses yet. '
            'Browse available courses to get started!',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Navigate to courses screen
              widget.onCourseSelected?.call();
            },
            icon: const Icon(Icons.explore),
            label: const Text('Browse Courses'),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesList(List<Course> courses, bool isLoading) {
    return RefreshIndicator(
      onRefresh: _refreshCourses,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(courses.length, isLoading),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: courses.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final course = courses[index];
                return _buildCourseCard(course);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int courseCount, bool isLoading) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.school,
            color: Theme.of(context).primaryColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Enrolled Courses',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                Text(
                  '$courseCount course${courseCount != 1 ? 's' : ''} enrolled',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            IconButton(
              onPressed: _refreshCourses,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh courses',
            ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(Course course) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToCourse(course),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          course.descriptionPreview,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildCourseStatus(course),
                ],
              ),
              const SizedBox(height: 12),
              _buildCourseInfo(course),
              const SizedBox(height: 12),
              _buildCourseActions(course),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseStatus(Course course) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (course.status) {
      case CourseStatus.published:
        statusColor = Colors.green;
        statusText = 'Active';
        statusIcon = Icons.check_circle;
        break;
      case CourseStatus.draft:
        statusColor = Colors.orange;
        statusText = 'Draft';
        statusIcon = Icons.edit;
        break;
      case CourseStatus.suspended:
        statusColor = Colors.red;
        statusText = 'Suspended';
        statusIcon = Icons.pause_circle;
        break;
      case CourseStatus.archived:
        statusColor = Colors.grey;
        statusText = 'Archived';
        statusIcon = Icons.archive;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 14, color: statusColor),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseInfo(Course course) {
    return Row(
      children: [
        _buildInfoChip(
          icon: Icons.people,
          label: '${course.enrolledStudents.length}/${course.maxEnrollment}',
          color: Colors.blue,
        ),
        const SizedBox(width: 8),
        if (course.duration > 0)
          _buildInfoChip(
            icon: Icons.schedule,
            label: course.formattedDuration,
            color: Colors.purple,
          ),
        const SizedBox(width: 8),
        if (course.hasTags)
          _buildInfoChip(
            icon: Icons.tag,
            label: '${course.tags.length} tag${course.tags.length != 1 ? 's' : ''}',
            color: Colors.orange,
          ),
      ],
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseActions(Course course) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _navigateToCourse(course),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('View Course'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: () => _showUnenrollDialog(course),
          icon: const Icon(Icons.exit_to_app, size: 16),
          label: const Text('Unenroll'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          ),
        ),
      ],
    );
  }

  Future<void> _refreshCourses() async {
    await ref.read(enrollmentProvider.notifier).loadStudentEnrolledCourses(widget.studentId);
  }

  void _navigateToCourse(Course course) {
    // TODO: Navigate to course details screen
    widget.onCourseSelected?.call();
  }

  Future<void> _showUnenrollDialog(Course course) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Unenrollment'),
        content: Text(
          'Are you sure you want to unenroll from "${course.title}"? '
          'You may lose your spot if the course becomes full.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Unenroll'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _unenrollFromCourse(course);
    }
  }

  Future<void> _unenrollFromCourse(Course course) async {
    final result = await ref.read(enrollmentProvider.notifier).unenrollStudent(
      courseId: course.id,
      studentId: widget.studentId,
    );

    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully unenrolled from ${course.title}'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Failed to unenroll from course'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}