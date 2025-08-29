import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:survey_app/services/auth_service.dart';
import 'package:survey_app/utils/colors.dart';
import 'package:survey_app/widgets/text_widget.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // Check authentication state and navigate appropriately
    _checkAuthState();
  }

  void _checkAuthState() {
    // Add a small delay for better UX
    Future.delayed(const Duration(seconds: 2), () {
      // Check if user is logged in
      if (_authService.currentUser != null) {
        // Check if user is admin
        _authService.isAdmin(_authService.currentUser!.uid).then((isAdmin) {
          if (isAdmin) {
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/admin/home');
            }
          } else {
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/user/home');
            }
          }
        }).catchError((error) {
          // If there's an error checking admin status, default to user home
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/user/home');
          }
        });
      } else {
        // No user logged in, go to user login
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/user/login');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo
            Image.asset(
              'assets/images/logo.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            TextWidget(
              text: 'BantayBP',
              fontSize: 24,
              color: textOnPrimary,
              fontFamily: 'Bold',
            ),
            const SizedBox(height: 16),
            TextWidget(
              text: 'Detecting and monitoring hypertension risk',
              fontSize: 16,
              color: textOnPrimary.withOpacity(0.8),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}