import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../modules/user.dart';
import '../providers/profile_edit_provider.dart';
import '../widgets/profile_image_picker.dart';
import '../widgets/profile_form_field.dart';
import '../widgets/role_specific_fields.dart';

/// Screen for editing user profile information
class ProfileEditScreen extends ConsumerStatefulWidget {
  final User user;

  const ProfileEditScreen({
    super.key,
    required this.user,
  });

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _departmentController = TextEditingController();
  final _fieldOfExpertiseController = TextEditingController();
  final _gradeController = TextEditingController();
  
  File? _selectedImage;
  String? _selectedGrade;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController.text = widget.user.name;
    _departmentController.text = widget.user.department ?? '';
    _fieldOfExpertiseController.text = widget.user.fieldOfExpertise ?? '';
    _selectedGrade = widget.user.grade;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _departmentController.dispose();
    _fieldOfExpertiseController.dispose();
    _gradeController.dispose();
    super.dispose();
  }

  void _onImageSelected(File? image) {
    setState(() {
      _selectedImage = image;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final updatedUser = widget.user.copyWith(
      name: _nameController.text.trim(),
      department: _departmentController.text.trim().isEmpty 
          ? null 
          : _departmentController.text.trim(),
      fieldOfExpertise: _fieldOfExpertiseController.text.trim().isEmpty 
          ? null 
          : _fieldOfExpertiseController.text.trim(),
      grade: _selectedGrade?.isEmpty == true ? null : _selectedGrade,
    );

    await ref.read(profileEditProvider.notifier).updateProfile(
      updatedUser,
      profileImage: _selectedImage,
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileEditState = ref.watch(profileEditProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: theme.cardColor,
        foregroundColor: theme.primaryColor,
        elevation: 0,
        actions: [
          if (profileEditState.isProcessing)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: profileEditState.isUploadingImage 
                      ? profileEditState.uploadProgress 
                      : null,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: Text(
                'Save',
                style: TextStyle(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Image Section
              ProfileImagePicker(
                currentImageUrl: widget.user.profileImage,
                selectedImage: _selectedImage,
                onImageSelected: _onImageSelected,
                isLoading: profileEditState.isProcessing,
              ),
              
              const SizedBox(height: 32),
              
              // Basic Information Section
              _buildSectionHeader('Basic Information'),
              const SizedBox(height: 16),
              
              ProfileFormField(
                controller: _nameController,
                label: 'Full Name',
                icon: Icons.person,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  if (value.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  if (value.trim().length > 100) {
                    return 'Name cannot exceed 100 characters';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Role Display (non-editable)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.cardColor),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.badge,
                      color: theme.primaryColor,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Role',
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.user.roleDisplayName,
                          style: TextStyle(
                            color: theme.shadowColor,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Role-specific fields
              RoleSpecificFields(
                user: widget.user,
                departmentController: _departmentController,
                fieldOfExpertiseController: _fieldOfExpertiseController,
                selectedGrade: _selectedGrade,
                onGradeChanged: (grade) {
                  setState(() {
                    _selectedGrade = grade;
                  });
                },
              ),
              
              const SizedBox(height: 32),
              
              // Error Display
              if (profileEditState.hasError)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          profileEditState.error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Save Button (for mobile)
              if (MediaQuery.of(context).size.width < 600)
                ElevatedButton(
                  onPressed: profileEditState.isProcessing ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: profileEditState.isProcessing
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                value: profileEditState.isUploadingImage 
                                    ? profileEditState.uploadProgress 
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              profileEditState.isUploadingImage 
                                  ? 'Uploading Image...' 
                                  : 'Saving...',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).primaryColor,
      ),
    );
  }
}