import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:educonnect/providers/auth_provider.dart';
import 'package:educonnect/modules/user.dart';

class SignupWidget extends ConsumerStatefulWidget {
  const SignupWidget({super.key});
  @override
  ConsumerState<SignupWidget> createState() => _SignupWidgetState();
}

class _SignupWidgetState extends ConsumerState<SignupWidget> {
  final _formKey = GlobalKey<FormState>();
  String _password = '';
  String _email = '';
  String _name = '';
  String? _roleCode = '';

  String _defineRoleCode(String? roleCode) {
    if (roleCode == null || roleCode.isEmpty) {
      return 'student';
    } else if (roleCode == 'instructor') {
      return 'instructor';
    } else if (roleCode == 'admin') {
      return 'admin';
    } else {
      return 'unknown';
    }
  }

  InputDecoration decoration(String inputname) {
    return InputDecoration(
      labelText: inputname,
      labelStyle: TextStyle(
        color: Theme.of(context).primaryColor,
        fontWeight: FontWeight.bold,
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Theme.of(context).cardColor, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  void _submitForm() async {
    _formKey.currentState!.save();
    _formKey.currentState!.validate();
    if (_formKey.currentState!.validate()) {
      UserClass user = UserClass(
        email: _email,
        password: _password,
        name: _name,
        roleCode: _defineRoleCode(_roleCode),
      );
      await ref.read(authProvider.notifier).signup(user, context);
    }
    if (ref.watch(authProvider.notifier).statue == 'success') {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Signup Successful!'),
          backgroundColor: Colors.green,
        ),
      );
    }
    if (ref.watch(authProvider.notifier).error != '') {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.watch(authProvider.notifier).error),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 30),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                children: [
                  Container(
                    child: SvgPicture.asset('assets/vectors/pana.svg'),
                    height: 200,
                  ),
                  Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          margin: EdgeInsets.only(bottom: 10),
                          child: TextFormField(
                            autocorrect: false,
                            textCapitalization: TextCapitalization.none,
                            decoration: decoration('Name'),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                            onSaved: (newValue) {
                              _name = newValue!;
                            },
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(bottom: 10),
                          child: TextFormField(
                            autocorrect: false,
                            textCapitalization: TextCapitalization.none,
                            decoration: decoration('Email'),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              final emailRegex = RegExp(
                                r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                              );
                              if (!emailRegex.hasMatch(value)) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                            onSaved: (newValue) {
                              _email = newValue!;
                            },
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(bottom: 10),
                          child: TextFormField(
                            autocorrect: false,
                            enableSuggestions: false,
                            textCapitalization: TextCapitalization.none,
                            decoration: decoration('Password'),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 8) {
                                return 'Password must be at least 8 characters long';
                              }
                              return null;
                            },
                            onSaved: (newValue) {
                              _password = newValue!;
                            },
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(bottom: 10),
                          child: TextFormField(
                            autocorrect: false,
                            enableSuggestions: false,
                            textCapitalization: TextCapitalization.none,

                            decoration: decoration('Confirm Password'),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              // Assuming you have a way to access the original password
                              // For example, you can store it in a variable when the user enters it
                              if (value != _password) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(bottom: 0),
                          child: TextFormField(
                            autocorrect: false,
                            enableSuggestions: false,
                            textCapitalization: TextCapitalization.none,

                            decoration: decoration('Role Code'),
                            validator: (value) {
                              if (value == null ||
                                  value == '' ||
                                  value == 'instructor' ||
                                  value == 'admin') {
                                return null;
                              }
                              return 'Please enter a valid role code';
                            },
                            onSaved: (newValue) {
                              _roleCode = newValue!;
                            },
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            '*Leave Role Code empty if you are a student',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.redAccent,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                        SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                      backgroundColor: Theme.of(context).cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Sign Up',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      ref.watch(authScreenProvider.notifier).toggleAuthState();
                    },
                    style: TextButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: Theme.of(context).primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      'Already have an account? Login',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
