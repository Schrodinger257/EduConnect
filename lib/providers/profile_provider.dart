import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileProvider extends StateNotifier<Map<String, dynamic>> {
  ProfileProvider() : super({});
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
      print('User not found');
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
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 80,
                  );
                  if (image != null) {
                    selectedImage = File(image.path);
                    await Supabase.instance.client.storage
                        .from('avatars')
                        .remove(['${userid}.png']);
                    await Supabase.instance.client.storage
                        .from('avatars')
                        .upload(
                          '${userid}.png',
                          selectedImage!,
                          fileOptions: FileOptions(upsert: true),
                        );
                    final imageUrl = Supabase.instance.client.storage
                        .from('avatars')
                        .getPublicUrl('${userid}.png');
                    final uniqueImageUrl =
                        '$imageUrl?${DateTime.now().millisecondsSinceEpoch}';
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(userid)
                        .update({'profileImage': uniqueImageUrl});
                    print(
                      '####################################################################Image updated successfully',
                    );
                    state = {...state, 'profileImage': imageUrl};
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Take a Photo'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 80,
                  );
                  if (image != null) {
                    selectedImage = File(image.path);
                    await Supabase.instance.client.storage
                        .from('avatars')
                        .remove(['${userid}.png']);
                    await Supabase.instance.client.storage
                        .from('avatars')
                        .upload(
                          '${userid}.png',
                          selectedImage!,
                          fileOptions: FileOptions(upsert: true),
                        );
                    final imageUrl = Supabase.instance.client.storage
                        .from('avatars')
                        .getPublicUrl('${userid}.png');
                    final uniqueImageUrl =
                        '$imageUrl?${DateTime.now().millisecondsSinceEpoch}';
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(userid)
                        .update({'profileImage': imageUrl});
                    state = {...state, 'profileImage': uniqueImageUrl};
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void updateUserProfile(
    String userId,
    Map<String, dynamic> profileData,
    BuildContext context,
  ) {
    Map<String, dynamic> data = profileData;
    final _formKey = GlobalKey<FormState>();

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
                    key: _formKey,
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
                              Navigator.pop(context);
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
                        _formKey.currentState?.reset();
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
      return ProfileProvider();
    });
