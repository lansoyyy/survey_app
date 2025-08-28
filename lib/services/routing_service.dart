import 'package:flutter/material.dart';
import 'package:survey_app/screens/splash_screen.dart';
import 'package:survey_app/screens/user/user_home_screen.dart';
import 'package:survey_app/screens/admin/admin_home_screen.dart';

class RoutingService {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      
      case '/user/home':
        return MaterialPageRoute(builder: (_) => const UserHomeScreen());
      
      case '/admin/home':
        return MaterialPageRoute(builder: (_) => const AdminHomeScreen());
      
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }

  static void navigateToUserHome(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/user/home');
  }

  static void navigateToAdminHome(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/admin/home');
  }

  static void navigateToLogin(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/');
  }
}