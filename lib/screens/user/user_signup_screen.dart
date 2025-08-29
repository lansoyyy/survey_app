import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:survey_app/services/auth_service.dart';
import 'package:survey_app/utils/colors.dart';
import 'package:survey_app/widgets/button_widget.dart';
import 'package:survey_app/widgets/text_widget.dart';
import 'package:fluttertoast/fluttertoast.dart';

class UserSignupScreen extends StatefulWidget {
  const UserSignupScreen({super.key});

  @override
  State<UserSignupScreen> createState() => _UserSignupScreenState();
}

class _UserSignupScreenState extends State<UserSignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String _gender = 'Male';
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }

  void _signup() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final UserCredential userCredential = await _authService.signup(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          age: int.parse(_ageController.text),
          gender: _gender,
        );

        if (userCredential.user != null) {
          if (mounted) {
            Fluttertoast.showToast(
              msg: 'Account created successfully!',
              backgroundColor: healthGreen,
              textColor: Colors.white,
            );
            
            // Navigate back to login screen
            Navigator.pushReplacementNamed(context, '/user/login');
          }
        }
      } on FirebaseAuthException catch (e) {
        String message = 'Sign up failed';
        if (e.code == 'email-already-in-use') {
          message = 'An account already exists for this email';
        } else if (e.code == 'invalid-email') {
          message = 'Invalid email address';
        } else if (e.code == 'operation-not-allowed') {
          message = 'Email/password accounts are not enabled';
        } else if (e.code == 'weak-password') {
          message = 'Password is too weak';
        }

        if (mounted) {
          Fluttertoast.showToast(
            msg: message,
            backgroundColor: healthRed,
            textColor: Colors.white,
          );
        }
      } catch (e) {
        if (mounted) {
          Fluttertoast.showToast(
            msg: 'Sign up failed. Please try again.',
            backgroundColor: healthRed,
            textColor: Colors.white,
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _navigateToLogin() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: primary),
                    onPressed: _navigateToLogin,
                  ),
                ),
                const SizedBox(height: 20),
                // App logo
                Image.asset(
                  'assets/images/logo.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 16),
                TextWidget(
                  text: 'Create Account',
                  fontSize: 24,
                  color: textPrimary,
                  fontFamily: 'Bold',
                ),
                const SizedBox(height: 8),
                TextWidget(
                  text: 'Sign up to get started',
                  fontSize: 16,
                  color: textLight,
                ),
                const SizedBox(height: 24),
                // Name field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon:
                        const Icon(Icons.person_outline, color: primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your full name';
                    }
                    if (value.trim().split(' ').length < 2) {
                      return 'Please enter your full name (first and last name)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon:
                        const Icon(Icons.email_outlined, color: primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline, color: primary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: textLight,
                      ),
                      onPressed: _togglePasswordVisibility,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Confirm Password field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outline, color: primary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: textLight,
                      ),
                      onPressed: _toggleConfirmPasswordVisibility,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Age field
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Age',
                    prefixIcon:
                        const Icon(Icons.calendar_today, color: primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your age';
                    }
                    final age = int.tryParse(value);
                    if (age == null) {
                      return 'Please enter a valid age';
                    }
                    if (age < 1 || age > 120) {
                      return 'Please enter a valid age between 1 and 120';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Gender selection
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text: 'Gender',
                      fontSize: 16,
                      color: textPrimary,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            title: TextWidget(
                              text: 'Male',
                              fontSize: 16,
                              color: textPrimary,
                            ),
                            leading: Radio<String>(
                              value: 'Male',
                              groupValue: _gender,
                              onChanged: (value) {
                                setState(() {
                                  _gender = value!;
                                });
                              },
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            title: TextWidget(
                              text: 'Female',
                              fontSize: 16,
                              color: textPrimary,
                            ),
                            leading: Radio<String>(
                              value: 'Female',
                              groupValue: _gender,
                              onChanged: (value) {
                                setState(() {
                                  _gender = value!;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Signup button
                _isLoading
                    ? const Center(child: CircularProgressIndicator(color: primary))
                    : ButtonWidget(
                        label: 'Sign Up',
                        onPressed: _signup,
                        width: double.infinity,
                      ),
                const SizedBox(height: 24),
                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextWidget(
                      text: 'Already have an account?',
                      fontSize: 14,
                      color: textLight,
                    ),
                    TextButton(
                      onPressed: _navigateToLogin,
                      child: TextWidget(
                        text: 'Login',
                        fontSize: 14,
                        color: primary,
                        fontFamily: 'Bold',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}