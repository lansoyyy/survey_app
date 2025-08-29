import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:survey_app/screens/admin/accounts/account_management_screen.dart';
import 'package:survey_app/screens/admin/answers/answers_management_screen.dart';
import 'package:survey_app/screens/admin/analytics/analytics_screen.dart';
import 'package:survey_app/services/auth_service.dart';
import 'package:survey_app/widgets/custom_app_bar.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;
  final AuthService _authService = AuthService();

  final List<Widget> _screens = [
    const AccountManagementScreen(),
    const AnswersManagementScreen(),
    const AnalyticsScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/admin/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Instead of using StreamBuilder, we'll check if user is authenticated directly
    final user = _authService.currentUser;
    
    // If user is not authenticated, redirect to login
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/admin/login');
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Check if user is admin
    return FutureBuilder<bool>(
      future: _authService.isAdmin(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (!snapshot.hasData || !snapshot.data!) {
          // User is not admin, redirect to user login
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/user/login');
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Scaffold(
          appBar: CustomAppBar(
            title: _getAppBarTitle(),
            showBackButton: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: _logout,
              ),
            ],
          ),
          body: _screens[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.grey,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.people_outline),
                activeIcon: Icon(Icons.people),
                label: 'Accounts',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.question_answer_outlined),
                activeIcon: Icon(Icons.question_answer),
                label: 'Answers',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.analytics_outlined),
                activeIcon: Icon(Icons.analytics),
                label: 'Analytics',
              ),
            ],
          ),
        );
      },
    );
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Account Management';
      case 1:
        return 'Survey Responses';
      case 2:
        return 'Data Analytics';
      default:
        return 'Admin Dashboard';
    }
  }
}