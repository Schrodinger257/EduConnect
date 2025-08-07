import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import '../repositories/user_repository.dart';

import '../core/logger.dart';
import 'providers.dart';

class ProfileProvider extends StateNotifier<Map<String, dynamic>> {
  final UserRepository _userRepository;
  final Logger _logger;
  
  ProfileProvider({
    required UserRepository userRepository,
    required Logger logger,
  }) : _userRepository = userRepository,
       _logger = logger,
       super({});
       
  final ImagePicker _picker = ImagePicker();
  File? selectedImage;
  Map<String, dynamic> user = {};
  Map<String, dynamic> userData = {};

  // void updateProfile(Map<String, dynamic> profileData) {
  //   state = profileData;
  // }

  void getUserData(String userId) async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    if (snapshot.exists) {
      userData = snapshot.data() as Map<String, dynamic>;
      state = userData;
    } else {
      _logger.warning('User not found');
    }
  }

  void setProfileImage(BuildContext context, String userid) async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  await _handleImageSelection(context, ImageSource.gallery, userid);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Take a Photo'),
                onTap: () async {
                  Navigator.pop(context);
                  await _handleImageSelection(context, ImageSource.camera, userid);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleImageSelection(BuildContext context, ImageSource source, String userid) async {
    try {
      _logger.info('Selecting image from $source for user: $userid');
      
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (image != null) {
        selectedImage = File(image.path);
        
        // Validate file size (max 5MB)
        final fileSize = await selectedImage!.length();
        if (fileSize > 5 * 1024 * 1024) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image file size cannot exceed 5MB'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        
        // Show loading indicator
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 16),
                  Text('Uploading profile image...'),
                ],
              ),
              duration: Duration(seconds: 10),
            ),
          );
        }
        
        // Upload using repository
        final result = await _userRepository.uploadProfileImage(selectedImage!, userid);
        
        result.when(
          success: (imageUrl) {
            _logger.info('Profile image uploaded successfully: $imageUrl');
            
            // Add timestamp to force refresh
            final uniqueImageUrl = '$imageUrl?${DateTime.now().millisecondsSinceEpoch}';
            state = {...state, 'profileImage': uniqueImageUrl};
            
            if (context.mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile image updated successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          error: (message, exception) {
            _logger.error('Failed to upload profile image: $message', error: exception);
            
            if (context.mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to upload image: $message'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        );
      }
    } catch (e) {
      _logger.error('Error selecting/uploading image: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void updateUserProfile(
    String userId,
    Map<String, dynamic> profileData,
    BuildContext context,
  ) {
    Map<String, dynamic> data = profileData;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      isScrollControlled: true,
      useSafeArea: true,
      context: context,
      builder: (BuildContext context) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 20),
          padding: EdgeInsets.only(
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 40,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Add your form fields here
              Column(
                children: [
                  Text(
                    'Update Profile',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  SizedBox(height: 16),

                  Form(
                    key: formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          initialValue: data['name'],
                          decoration: InputDecoration(
                            labelText: 'name',
                            labelStyle: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Theme.of(context).cardColor,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Theme.of(context).primaryColor,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onChanged: (value) {
                            data['name'] = value;
                          },
                        ),
                        SizedBox(height: 20),
                        TextFormField(
                          maxLength: 12,
                          initialValue: data['phone'],
                          decoration: InputDecoration(
                            labelText: 'phone',
                            labelStyle: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Theme.of(context).cardColor,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Theme.of(context).primaryColor,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onChanged: (value) {
                            data['phone'] = value;
                          },
                        ),
                        SizedBox(height: 20),
                        if (data['roleCode'] == 'instructor')
                          TextFormField(
                            initialValue: data['fieldofexpertise'],
                            decoration: InputDecoration(
                              labelText: 'Field of Expertise',
                              labelStyle: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Theme.of(context).cardColor,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Theme.of(context).primaryColor,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onChanged: (value) {
                              data['fieldofexpertise'] = value;
                            },
                          ),
                        SizedBox(height: 20),

                        if (data['roleCode'] == 'student')
                          TextFormField(
                            initialValue: data['department'],
                            decoration: InputDecoration(
                              labelText: 'Department',
                              labelStyle: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Theme.of(context).cardColor,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Theme.of(context).primaryColor,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onChanged: (value) {
                              data['department'] = value;
                            },
                          ),
                        SizedBox(height: 20),

                        if (data['roleCode'] == 'student')
                          DropdownButtonFormField(
                            value: data['grade'],
                            items:
                                [
                                  '1st Year',
                                  '2nd Year',
                                  '3rd Year',
                                  '4th Year',
                                  'None',
                                ].map((String grade) {
                                  return DropdownMenuItem(
                                    value: grade,
                                    child: Text(grade),
                                  );
                                }).toList(),
                            decoration: InputDecoration(
                              labelText: 'Grade',
                              labelStyle: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Theme.of(context).cardColor,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Theme.of(context).primaryColor,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onChanged: (value) {
                              data['grade'] = value;
                            },
                          ),
                        // Add more fields as needed
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).cardColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .update(data)
                            .then((_) {
                              state = data;
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            });
                      },
                      child: Text(
                        'Save Changes',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        formKey.currentState?.reset();
                      },
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void clearProfile() {
    state = {};
  }
}

final profileProvider =
    StateNotifierProvider<ProfileProvider, Map<String, dynamic>>((ref) {
      return ProfileProvider(
        userRepository: ref.read(userRepositoryProvider),
        logger: ref.read(loggerProvider),
      );
    });
