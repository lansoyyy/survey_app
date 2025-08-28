import 'package:flutter/material.dart';
import 'package:survey_app/screens/splash_screen.dart';
import 'package:survey_app/screens/user/user_home_screen.dart';
import 'package:survey_app/screens/admin/admin_home_screen.dart';
import 'package:survey_app/screens/admin/admin_login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BantayBP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Regular',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/user/home': (context) => const UserHomeScreen(),
        '/admin/login': (context) => const AdminLoginScreen(),
        '/admin/home': (context) => const AdminHomeScreen(),
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
      },
    );
  }
}
