import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:survey_app/screens/user/survey/survey_screen.dart';
import 'package:survey_app/screens/user/monitoring/monitoring_screen.dart';
import 'package:survey_app/screens/user/analysis/analysis_screen.dart';
import 'package:survey_app/screens/user/medication/medication_screen.dart';
import 'package:survey_app/services/auth_service.dart';
import 'package:survey_app/widgets/custom_app_bar.dart';
import 'package:survey_app/widgets/custom_bottom_navigation_bar.dart';

class UserHomeScreen extends StatefulWidget {
  final int? tabIndex;

  const UserHomeScreen({super.key, this.tabIndex});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _currentIndex = 0;
  final AuthService _authService = AuthService();

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    // Set the initial tab index if provided
    _currentIndex = widget.tabIndex ?? 0;
    _screens = [
      SurveyScreen(),
      const MonitoringScreen(),
      const MedicationScreen(),
      const AnalysisScreen(),
    ];
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;

      // If we're going back to the survey screen, recreate it to ensure proper state
      if (index == 0) {
        _screens[0] = SurveyScreen();
      }
    });
  }

  void _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/user/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Instead of using StreamBuilder, we'll check if user is authenticated directly
    final user = _authService.currentUser;

    // If user is not authenticated, redirect to login
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/user/login');
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        // Prevent the user from leaving the screen when back button is pressed
        return false;
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: _getAppBarTitle(),
          showBackButton: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
              onPressed: () {
                // Navigate to admin login
                Navigator.pushNamed(context, '/admin/login');
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: _logout,
            ),
          ],
        ),
        body: _screens[_currentIndex],
        bottomNavigationBar: CustomBottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
        ),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Assessment';
      case 1:
        return 'Monitoring';
      case 2:
        return 'Medication';
      case 3:
        return 'Management';
      default:
        return 'Hypertension App';
    }
  }
}
