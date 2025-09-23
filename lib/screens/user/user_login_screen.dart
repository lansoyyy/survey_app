import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:survey_app/services/auth_service.dart';
import 'package:survey_app/utils/colors.dart';
import 'package:survey_app/widgets/button_widget.dart';
import 'package:survey_app/widgets/text_widget.dart';
import 'package:survey_app/widgets/textfield_widget.dart';
import 'package:survey_app/widgets/forgot_password_dialog.dart';
import 'package:fluttertoast/fluttertoast.dart';

class UserLoginScreen extends StatefulWidget {
  const UserLoginScreen({super.key});

  @override
  State<UserLoginScreen> createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends State<UserLoginScreen> {
  final TextEditingController _identifierController =
      TextEditingController(); // Changed from _emailController
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _identifierController.dispose(); // Changed from _emailController
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final UserCredential userCredential = await _authService.login(
          _identifierController.text.trim(), // Changed from _emailController
          _passwordController.text,
        );

        if (userCredential.user != null) {
          // Navigate to user home screen
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/user/home');
          }
        }
      } on FirebaseAuthException catch (e) {
        String message = 'Authentication failed';
        if (e.code == 'user-not-found') {
          message = 'No user found with this email or username';
        } else if (e.code == 'wrong-password') {
          message = 'Incorrect password';
        } else if (e.code == 'invalid-email') {
          message = 'Invalid email address';
        } else if (e.code == 'user-disabled') {
          message = 'This account has been disabled';
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
            msg: 'Login failed. Please try again.',
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

  void _navigateToSignup() {
    Navigator.pushNamed(context, '/user/signup');
  }

  void _showForgotPasswordDialog() {
    showForgotPasswordDialog(context);
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
                const SizedBox(height: 40),
                // App logo
                Image.asset(
                  'assets/images/logo.png',
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 24),
                TextWidget(
                  text: 'Welcome Back',
                  fontSize: 24,
                  color: textPrimary,
                  fontFamily: 'Bold',
                ),
                const SizedBox(height: 8),
                TextWidget(
                  text: 'Sign in to continue',
                  fontSize: 16,
                  color: textLight,
                ),
                const SizedBox(height: 32),
                // Email or Username field
                TextFormField(
                  controller:
                      _identifierController, // Changed from _emailController
                  decoration: InputDecoration(
                    labelText: 'Email or Username', // Updated label
                    prefixIcon: const Icon(Icons.person_outline,
                        color: primary), // Changed icon
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  keyboardType: TextInputType
                      .text, // Changed from TextInputType.emailAddress
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email or username';
                    }
                    // Removed email validation since we now accept both email and username
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
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                // Login button
                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: primary))
                    : ButtonWidget(
                        label: 'Login',
                        onPressed: _login,
                        width: double.infinity,
                      ),
                const SizedBox(height: 16),
                // Forgot password button
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showForgotPasswordDialog,
                    child: TextWidget(
                      text: 'Forgot Password?',
                      fontSize: 14,
                      color: primary,
                      fontFamily: 'Medium',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Signup link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextWidget(
                      text: "Don't have an account?",
                      fontSize: 14,
                      color: textLight,
                    ),
                    TextButton(
                      onPressed: _navigateToSignup,
                      child: TextWidget(
                        text: 'Sign Up',
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
