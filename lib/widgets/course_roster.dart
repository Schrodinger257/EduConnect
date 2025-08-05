import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../modules/course.dart';
import '../modules/user.dart';
import '../providers/enrollment_provider.dart';

/// Widget for displaying course roster (enrolled students) for instructors
class CourseRoster extends ConsumerStatefulWidget {
  final Course course;
  final bool showStatistics;
  final VoidCallback? onStudentSelected;

  const CourseRoster({
    super.key,
    required this.course,
    this.showStatistics = true,
    this.onStudentSelected,
  });

  @override
  ConsumerState<CourseRoster> createState() => _CourseRosterState();
}

class _CourseRosterState extends ConsumerState<CourseRoster> {
  String _searchQuery = '';
  String _sortBy = 'name'; // 'name', 'enrollmentDate'
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    // Load enrolled students when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(enrollmentProvider.notifier).loadEnrolledStudents(widget.course.id);
      if (widget.showStatistics) {
        ref.read(enrollmentProvider.notifier).loadEnrollmentStatistics(widget.course.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final enrollmentState = ref.watch(enrollmentProvider);
    final enrolledStudents = enrollmentState.enrolledStudents;
    final isLoading = enrollmentState.isLoading;
    final error = enrollmentState.error;
    final statistics = enrollmentState.enrollmentStatistics[widget.course.id];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showStatistics && statistics != null)
          _buildStatisticsHeader(statistics),
        _buildSearchAndSort(),
        const SizedBox(height: 16),
        Expanded(
          child: _buildStudentsList(enrolledStudents, isLoading, error),
        ),
      ],
    );
  }

  Widget _buildStatisticsHeader(Map<String, dynamic> statistics) {
    final enrolledCount = statistics['enrolledCount'] as int;
    final maxEnrollment = statistics['maxEnrollment'] as int;
    final availableSpots = statistics['availableSpots'] as int;
    final enrollmentPercentage = statistics['enrollmentPercentage'] as int;
    final isNearlyFull = statistics['isNearlyFull'] as bool;
    final isFull = statistics['isFull'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.people,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Course Enrollment',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const Spacer(),
              _buildStatusBadge(isFull, isNearlyFull),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Enrolled',
                  '$enrolledCount',
                  Icons.person_add,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Available',
                  '$availableSpots',
                  Icons.event_seat,
                  availableSpots > 0 ? Colors.blue : Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Capacity',
                  '$maxEnrollment',
                  Icons.group,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Enrollment Progress',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    '$enrollmentPercentage%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: enrollmentPercentage / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  isNearlyFull ? Colors.orange : Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isFull, bool isNearlyFull) {
    Color color;
    String text;
    IconData icon;

    if (isFull) {
      color = Colors.red;
      text = 'Full';
      icon = Icons.block;
    } else if (isNearlyFull) {
      color = Colors.orange;
      text = 'Nearly Full';
      icon = Icons.warning;
    } else {
      color = Colors.green;
      text = 'Available';
      icon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndSort() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search students...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Sort by:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<String>(
                  value: _sortBy,
                  isExpanded: true,
                  underline: Container(),
                  items: const [
                    DropdownMenuItem(value: 'name', child: Text('Name')),
                    DropdownMenuItem(value: 'enrollmentDate', child: Text('Enrollment Date')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _sortBy = value;
                      });
                    }
                  },
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _sortAscending = !_sortAscending;
                  });
                },
                icon: Icon(
                  _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                ),
                tooltip: _sortAscending ? 'Sort Descending' : 'Sort Ascending',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsList(List<User> students, bool isLoading, String? error) {
    if (isLoading && students.isEmpty) {
      return _buildLoadingState();
    }

    if (error != null && students.isEmpty) {
      return _buildErrorState(error);
    }

    if (students.isEmpty) {
      return _buildEmptyState();
    }

    final filteredAndSortedStudents = _filterAndSortStudents(students);

    return RefreshIndicator(
      onRefresh: _refreshRoster,
      child: ListView.separated(
        itemCount: filteredAndSortedStudents.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final student = filteredAndSortedStudents[index];
          return _buildStudentTile(student);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading enrolled students...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          const Text(
            'Failed to load students',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _refreshRoster,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No Students Enrolled',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No students have enrolled in this course yet.',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStudentTile(User student) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
        backgroundImage: student.profileImage != null 
            ? NetworkImage(student.profileImage!) 
            : null,
        child: student.profileImage == null
            ? Text(
                student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              )
            : null,
      ),
      title: Text(
        student.name,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(student.email),
          const SizedBox(height: 2),
          Row(
            children: [
              if (student.grade != null) ...[
                Icon(Icons.school, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  student.grade!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
              if (student.department != null) ...[
                if (student.grade != null) const SizedBox(width: 12),
                Icon(Icons.business, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  student.department!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) => _handleStudentAction(value, student),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'view_profile',
            child: ListTile(
              leading: Icon(Icons.person),
              title: Text('View Profile'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const PopupMenuItem(
            value: 'send_message',
            child: ListTile(
              leading: Icon(Icons.message),
              title: Text('Send Message'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const PopupMenuItem(
            value: 'unenroll',
            child: ListTile(
              leading: Icon(Icons.remove_circle, color: Colors.red),
              title: Text('Unenroll Student', style: TextStyle(color: Colors.red)),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
      onTap: () => widget.onStudentSelected?.call(),
    );
  }

  List<User> _filterAndSortStudents(List<User> students) {
    var filtered = students;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = students.where((student) {
        return student.name.toLowerCase().contains(_searchQuery) ||
               student.email.toLowerCase().contains(_searchQuery) ||
               (student.grade?.toLowerCase().contains(_searchQuery) ?? false) ||
               (student.department?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'enrollmentDate':
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        default:
          comparison = 0;
      }
      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  Future<void> _refreshRoster() async {
    await ref.read(enrollmentProvider.notifier).loadEnrolledStudents(widget.course.id);
    if (widget.showStatistics) {
      await ref.read(enrollmentProvider.notifier).loadEnrollmentStatistics(widget.course.id);
    }
  }

  void _handleStudentAction(String action, User student) {
    switch (action) {
      case 'view_profile':
        _viewStudentProfile(student);
        break;
      case 'send_message':
        _sendMessageToStudent(student);
        break;
      case 'unenroll':
        _unenrollStudent(student);
        break;
    }
  }

  void _viewStudentProfile(User student) {
    // TODO: Navigate to student profile
    widget.onStudentSelected?.call();
  }

  void _sendMessageToStudent(User student) {
    // TODO: Navigate to chat with student
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening chat with ${student.name}...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _unenrollStudent(User student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unenroll Student'),
        content: Text(
          'Are you sure you want to unenroll ${student.name} from this course? '
          'This action cannot be undone.',
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
      final result = await ref.read(enrollmentProvider.notifier).unenrollStudent(
        courseId: widget.course.id,
        studentId: student.id,
      );

      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully unenrolled ${student.name}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Failed to unenroll student'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}