import 'package:flutter/material.dart';
import 'package:survey_app/utils/colors.dart';
import 'package:survey_app/widgets/app_text_form_field.dart';
import 'package:survey_app/widgets/button_widget.dart';
import 'package:survey_app/widgets/text_widget.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      // In a real app, this would authenticate with a backend
      // For now, we'll just navigate to the admin home screen
      Navigator.pushReplacementNamed(context, '/admin/home');
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
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
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
                ButtonWidget(
                  label: 'Login',
                  onPressed: _login,
                  width: double.infinity,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    // In a real app, this would navigate to a forgot password screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: TextWidget(
                          text: 'Forgot password functionality would be implemented here',
                          fontSize: 14,
                          color: textOnPrimary,
                        ),
                        backgroundColor: primary,
                      ),
                    );
                  },
                  child: TextWidget(
                    text: 'Forgot Password?',
                    fontSize: 14,
                    color: primary,
                    fontFamily: 'Medium',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}