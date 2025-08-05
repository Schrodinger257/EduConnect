import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../modules/course.dart';
import '../providers/enrollment_provider.dart';

/// Widget for displaying enrollment progress and statistics
class EnrollmentProgress extends ConsumerStatefulWidget {
  final Course course;
  final bool showDetailedStats;
  final bool showProgressBar;
  final VoidCallback? onTap;

  const EnrollmentProgress({
    super.key,
    required this.course,
    this.showDetailedStats = true,
    this.showProgressBar = true,
    this.onTap,
  });

  @override
  ConsumerState<EnrollmentProgress> createState() => _EnrollmentProgressState();
}

class _EnrollmentProgressState extends ConsumerState<EnrollmentProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.course.enrollmentPercentage / 100,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Load enrollment statistics
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(enrollmentProvider.notifier).loadEnrollmentStatistics(widget.course.id);
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enrollmentState = ref.watch(enrollmentProvider);
    final statistics = enrollmentState.enrollmentStatistics[widget.course.id];

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            if (widget.showProgressBar) ...[
              _buildProgressBar(),
              const SizedBox(height: 12),
            ],
            _buildEnrollmentStats(),
            if (widget.showDetailedStats && statistics != null) ...[
              const SizedBox(height: 12),
              _buildDetailedStats(statistics),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.people,
          color: Theme.of(context).primaryColor,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          'Enrollment Status',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const Spacer(),
        _buildStatusIndicator(),
      ],
    );
  }

  Widget _buildStatusIndicator() {
    Color color;
    IconData icon;
    String tooltip;

    if (widget.course.isFull) {
      color = Colors.red;
      icon = Icons.block;
      tooltip = 'Course is full';
    } else if (widget.course.isNearlyFull) {
      color = Colors.orange;
      icon = Icons.warning;
      tooltip = 'Course is nearly full';
    } else {
      color = Colors.green;
      icon = Icons.check_circle;
      tooltip = 'Spots available';
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 16,
          color: color,
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            Text(
              '${widget.course.enrollmentPercentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return LinearProgressIndicator(
              value: _progressAnimation.value,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.course.isNearlyFull 
                    ? Colors.orange 
                    : Theme.of(context).primaryColor,
              ),
              minHeight: 6,
            );
          },
        ),
      ],
    );
  }

  Widget _buildEnrollmentStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            'Enrolled',
            '${widget.course.enrolledStudents.length}',
            Icons.person_add,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatItem(
            'Available',
            '${widget.course.availableSpots}',
            Icons.event_seat,
            widget.course.availableSpots > 0 ? Colors.blue : Colors.red,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatItem(
            'Capacity',
            '${widget.course.maxEnrollment}',
            Icons.group,
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStats(Map<String, dynamic> statistics) {
    final isNearlyFull = statistics['isNearlyFull'] as bool;
    final isFull = statistics['isFull'] as bool;
    final enrollmentRate = statistics['enrollmentRate'] as double;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detailed Statistics',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          _buildDetailRow('Enrollment Rate', '${(enrollmentRate * 100).toStringAsFixed(1)}%'),
          _buildDetailRow('Status', _getEnrollmentStatusText(isFull, isNearlyFull)),
          _buildDetailRow('Course Type', widget.course.statusDisplayName),
          if (widget.course.duration > 0)
            _buildDetailRow('Duration', widget.course.formattedDuration),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  String _getEnrollmentStatusText(bool isFull, bool isNearlyFull) {
    if (isFull) {
      return 'Full';
    } else if (isNearlyFull) {
      return 'Nearly Full';
    } else {
      return 'Available';
    }
  }
}

/// Compact version of enrollment progress for use in lists
class CompactEnrollmentProgress extends StatelessWidget {
  final Course course;
  final bool showPercentage;

  const CompactEnrollmentProgress({
    super.key,
    required this.course,
    this.showPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.people,
            size: 14,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Text(
            '${course.enrolledStudents.length}/${course.maxEnrollment}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          if (showPercentage) ...[
            const SizedBox(width: 4),
            Text(
              '(${course.enrollmentPercentage.toStringAsFixed(0)}%)',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
          const SizedBox(width: 4),
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: Colors.grey[200],
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: course.enrollmentPercentage / 100,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: course.isNearlyFull 
                      ? Colors.orange 
                      : Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Enrollment progress card for dashboard use
class EnrollmentProgressCard extends StatelessWidget {
  final Course course;
  final VoidCallback? onTap;

  const EnrollmentProgressCard({
    super.key,
    required this.course,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      course.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(context),
                ],
              ),
              const SizedBox(height: 12),
              EnrollmentProgress(
                course: course,
                showDetailedStats: false,
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    Color color;
    String text;

    if (course.isFull) {
      color = Colors.red;
      text = 'Full';
    } else if (course.isNearlyFull) {
      color = Colors.orange;
      text = 'Nearly Full';
    } else {
      color = Colors.green;
      text = 'Available';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}