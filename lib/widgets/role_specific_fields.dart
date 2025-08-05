import 'package:flutter/material.dart';
import '../modules/user.dart';
import 'profile_form_field.dart';

/// Widget that displays role-specific form fields based on user role
class RoleSpecificFields extends StatelessWidget {
  final User user;
  final TextEditingController departmentController;
  final TextEditingController fieldOfExpertiseController;
  final String? selectedGrade;
  final Function(String?) onGradeChanged;

  const RoleSpecificFields({
    super.key,
    required this.user,
    required this.departmentController,
    required this.fieldOfExpertiseController,
    required this.selectedGrade,
    required this.onGradeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Text(
          'Role-Specific Information',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.primaryColor,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Role-specific fields based on user role
        if (user.role == UserRole.student) ...[
          // Student-specific fields
          ProfileFormField(
            controller: departmentController,
            label: 'Department',
            icon: Icons.school,
            hintText: 'e.g., Computer Science, Mathematics',
            validator: (value) {
              if (value != null && value.trim().length > 100) {
                return 'Department name cannot exceed 100 characters';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          ProfileDropdownField<String>(
            value: selectedGrade,
            items: const [
              '1st Year',
              '2nd Year',
              '3rd Year',
              '4th Year',
              'Graduate',
              'PhD',
            ],
            label: 'Grade Level',
            icon: Icons.grade,
            itemLabel: (grade) => grade,
            onChanged: onGradeChanged,
            hintText: 'Select your current grade level',
            validator: (value) {
              if (user.role == UserRole.student && (value == null || value.isEmpty)) {
                return 'Grade level is required for students';
              }
              return null;
            },
          ),
          
        ] else if (user.role == UserRole.instructor) ...[
          // Instructor-specific fields
          ProfileFormField(
            controller: fieldOfExpertiseController,
            label: 'Field of Expertise',
            icon: Icons.psychology,
            hintText: 'e.g., Machine Learning, Web Development',
            maxLines: 2,
            validator: (value) {
              if (user.role == UserRole.instructor && 
                  (value == null || value.trim().isEmpty)) {
                return 'Field of expertise is required for instructors';
              }
              if (value != null && value.trim().length > 200) {
                return 'Field of expertise cannot exceed 200 characters';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          ProfileFormField(
            controller: departmentController,
            label: 'Department',
            icon: Icons.business,
            hintText: 'e.g., Computer Science Department',
            validator: (value) {
              if (value != null && value.trim().length > 100) {
                return 'Department name cannot exceed 100 characters';
              }
              return null;
            },
          ),
          
        ] else if (user.role == UserRole.admin) ...[
          // Admin-specific fields
          ProfileFormField(
            controller: departmentController,
            label: 'Department/Division',
            icon: Icons.admin_panel_settings,
            hintText: 'e.g., IT Administration, Academic Affairs',
            validator: (value) {
              if (value != null && value.trim().length > 100) {
                return 'Department name cannot exceed 100 characters';
              }
              return null;
            },
          ),
        ],
        
        // Role information display
        const SizedBox(height: 24),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.primaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.primaryColor.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Role Information',
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              Text(
                _getRoleDescription(user.role),
                style: TextStyle(
                  color: theme.shadowColor.withOpacity(0.8),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getRoleDescription(UserRole role) {
    switch (role) {
      case UserRole.student:
        return 'As a student, you can enroll in courses, participate in discussions, '
               'bookmark posts, and interact with educational content. Your department '
               'and grade level help instructors provide relevant content.';
      
      case UserRole.instructor:
        return 'As an instructor, you can create courses, post announcements, '
               'manage course materials, and interact with students. Your field of '
               'expertise helps students find relevant courses and content.';
      
      case UserRole.admin:
        return 'As an administrator, you have access to system management features, '
               'can oversee courses and users, and manage platform-wide settings. '
               'Your department information helps with organizational structure.';
    }
  }
}