import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:survey_app/services/auth_service.dart';
import 'package:survey_app/utils/colors.dart';
import 'package:survey_app/widgets/app_text_form_field.dart';
import 'package:survey_app/widgets/button_widget.dart';
import 'package:survey_app/widgets/text_widget.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final UserCredential userCredential = await _authService.adminLogin(
          _emailController.text.trim(),
          _passwordController.text,
        );

        if (userCredential.user != null) {
          // Navigate to admin home screen
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/admin/home');
          }
        }
      } on FirebaseAuthException catch (e) {
        String message = 'Authentication failed';
        if (e.code == 'user-not-found') {
          message = 'No admin found with this email';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo
                Image.asset(
                  'assets/images/logo.png',
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 24),
                TextWidget(
                  text: 'Admin Login',
                  fontSize: 28,
                  color: primary,
                  fontFamily: 'Bold',
                ),
                const SizedBox(height: 8),
                TextWidget(
                  text: 'Access the administration panel',
                  fontSize: 16,
                  color: textLight,
                ),
                const SizedBox(height: 32),
                AppTextFormField(
                  controller: _emailController,
                  labelText: 'Email Address',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                AppTextFormField(
                  controller: _passwordController,
                  labelText: 'Password',
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                  onEditingComplete: _login,
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(child: CircularProgressIndicator(color: primary))
                    : ButtonWidget(
                        label: 'Login',
                        onPressed: _login,
                        width: double.infinity,
                      ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}