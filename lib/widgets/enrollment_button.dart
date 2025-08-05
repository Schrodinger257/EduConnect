import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../modules/course.dart';
import '../modules/user.dart';
import '../providers/enrollment_provider.dart';
import '../services/enrollment_service.dart';

/// Widget for displaying enrollment button with status
class EnrollmentButton extends ConsumerStatefulWidget {
  final Course course;
  final User? currentUser;
  final VoidCallback? onEnrollmentChanged;
  final bool showProgress;

  const EnrollmentButton({
    super.key,
    required this.course,
    this.currentUser,
    this.onEnrollmentChanged,
    this.showProgress = true,
  });

  @override
  ConsumerState<EnrollmentButton> createState() => _EnrollmentButtonState();
}

class _EnrollmentButtonState extends ConsumerState<EnrollmentButton> {
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Load enrollment info when widget initializes
    if (widget.currentUser != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(enrollmentProvider.notifier).loadEnrollmentInfo(
          courseId: widget.course.id,
          userId: widget.currentUser!.id,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final enrollmentState = ref.watch(enrollmentProvider);
    final enrollmentInfo = enrollmentState.enrollmentInfoCache[widget.course.id];
    
    // Show loading state if enrollment info is not loaded yet
    if (enrollmentInfo == null && widget.currentUser != null) {
      return _buildLoadingButton();
    }

    return _buildEnrollmentButton(context, enrollmentInfo);
  }

  Widget _buildLoadingButton() {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[300],
          foregroundColor: Colors.grey[600],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: widget.showProgress
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Loading...'),
      ),
    );
  }

  Widget _buildEnrollmentButton(BuildContext context, EnrollmentInfo? enrollmentInfo) {
    final theme = Theme.of(context);
    final isEnrolled = enrollmentInfo?.status == EnrollmentStatus.enrolled;
    final canEnroll = enrollmentInfo?.canEnroll ?? false;
    final isFull = enrollmentInfo?.status == EnrollmentStatus.full;
    final isUnavailable = enrollmentInfo?.status == EnrollmentStatus.unavailable;

    // Determine button properties based on enrollment status
    Color backgroundColor;
    Color foregroundColor;
    String buttonText;
    IconData? icon;
    VoidCallback? onPressed;

    if (_isProcessing) {
      backgroundColor = Colors.grey[300]!;
      foregroundColor = Colors.grey[600]!;
      buttonText = isEnrolled ? 'Unenrolling...' : 'Enrolling...';
      icon = null;
      onPressed = null;
    } else if (isEnrolled) {
      backgroundColor = Colors.red[50]!;
      foregroundColor = Colors.red[700]!;
      buttonText = 'Unenroll';
      icon = Icons.remove_circle_outline;
      onPressed = widget.currentUser != null ? _handleUnenroll : null;
    } else if (canEnroll) {
      backgroundColor = theme.primaryColor;
      foregroundColor = Colors.white;
      buttonText = 'Enroll Now';
      icon = Icons.add_circle_outline;
      onPressed = widget.currentUser != null ? _handleEnroll : null;
    } else if (isFull) {
      backgroundColor = Colors.orange[50]!;
      foregroundColor = Colors.orange[700]!;
      buttonText = 'Join Waitlist';
      icon = Icons.schedule;
      onPressed = widget.currentUser != null ? _handleJoinWaitlist : null;
    } else if (isUnavailable) {
      backgroundColor = Colors.grey[200]!;
      foregroundColor = Colors.grey[600]!;
      buttonText = 'Unavailable';
      icon = Icons.block;
      onPressed = null;
    } else {
      backgroundColor = Colors.grey[200]!;
      foregroundColor = Colors.grey[600]!;
      buttonText = 'Login to Enroll';
      icon = Icons.login;
      onPressed = () => _showLoginPrompt(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor,
              foregroundColor: foregroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: onPressed != null ? 2 : 0,
            ),
            icon: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(icon, size: 20),
            label: Text(
              buttonText,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ),
        if (enrollmentInfo != null) ...[
          const SizedBox(height: 8),
          _buildEnrollmentStatus(context, enrollmentInfo),
        ],
      ],
    );
  }

  Widget _buildEnrollmentStatus(BuildContext context, EnrollmentInfo enrollmentInfo) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Enrolled: ${enrollmentInfo.enrolledCount}/${enrollmentInfo.maxEnrollment}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${enrollmentInfo.availableSpots} spots left',
                style: TextStyle(
                  fontSize: 12,
                  color: enrollmentInfo.availableSpots > 0 
                      ? Colors.green[600] 
                      : Colors.red[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: enrollmentInfo.enrollmentPercentage / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              enrollmentInfo.isNearlyFull 
                  ? Colors.orange 
                  : theme.primaryColor,
            ),
          ),
          if (enrollmentInfo.message != null) ...[
            const SizedBox(height: 4),
            Text(
              enrollmentInfo.message!,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleEnroll() async {
    if (widget.currentUser == null) return;

    setState(() => _isProcessing = true);

    try {
      final result = await ref.read(enrollmentProvider.notifier).enrollStudent(
        courseId: widget.course.id,
        studentId: widget.currentUser!.id,
      );

      if (result.isSuccess) {
        _showSuccessMessage('Successfully enrolled in ${widget.course.title}!');
        widget.onEnrollmentChanged?.call();
      } else {
        _showErrorMessage(result.error ?? 'Failed to enroll in course');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleUnenroll() async {
    if (widget.currentUser == null) return;

    // Show confirmation dialog
    final confirmed = await _showUnenrollConfirmation();
    if (!confirmed) return;

    setState(() => _isProcessing = true);

    try {
      final result = await ref.read(enrollmentProvider.notifier).unenrollStudent(
        courseId: widget.course.id,
        studentId: widget.currentUser!.id,
      );

      if (result.isSuccess) {
        _showSuccessMessage('Successfully unenrolled from ${widget.course.title}');
        widget.onEnrollmentChanged?.call();
      } else {
        _showErrorMessage(result.error ?? 'Failed to unenroll from course');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleJoinWaitlist() async {
    if (widget.currentUser == null) return;

    // TODO: Implement waitlist functionality
    _showInfoMessage('Waitlist functionality coming soon!');
  }

  Future<bool> _showUnenrollConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Unenrollment'),
        content: Text(
          'Are you sure you want to unenroll from "${widget.course.title}"? '
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
    ) ?? false;
  }

  void _showLoginPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text(
          'You need to be logged in to enroll in courses. '
          'Please log in or create an account to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Navigate to login screen
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () {
            // Retry the last action
            final enrollmentInfo = ref.read(enrollmentProvider)
                .enrollmentInfoCache[widget.course.id];
            if (enrollmentInfo?.status == EnrollmentStatus.enrolled) {
              _handleUnenroll();
            } else {
              _handleEnroll();
            }
          },
        ),
      ),
    );
  }

  void _showInfoMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}