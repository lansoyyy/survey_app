import 'package:flutter/material.dart';
import 'package:survey_app/screens/user/survey/survey_screen.dart';
import 'package:survey_app/screens/user/monitoring/monitoring_screen.dart';
import 'package:survey_app/screens/user/analysis/analysis_screen.dart';
import 'package:survey_app/widgets/custom_app_bar.dart';
import 'package:survey_app/widgets/custom_bottom_navigation_bar.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const SurveyScreen(),
    const MonitoringScreen(),
    const AnalysisScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Hypertension Survey';
      case 1:
        return 'Health Monitoring';
      case 2:
        return 'Risk Analysis';
      default:
        return 'Hypertension App';
    }
  }
}