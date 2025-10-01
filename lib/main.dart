import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:survey_app/firebase_options.dart';
import 'package:survey_app/screens/splash_screen.dart';
import 'package:survey_app/screens/user/user_home_screen.dart';
import 'package:survey_app/screens/user/user_login_screen.dart';
import 'package:survey_app/screens/user/user_signup_screen.dart';
import 'package:survey_app/screens/admin/admin_home_screen.dart';
import 'package:survey_app/screens/admin/admin_login_screen.dart';
import 'package:survey_app/services/notification_service.dart';
import 'package:survey_app/services/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    name: 'bantaybp-bc1ae',
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize notification service
  await NotificationService().initialize();

  // Initialize background service
  await initializeBackgroundService();

  runApp(const MyApp());
}

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//       options: const FirebaseOptions(
//           apiKey: "AIzaSyBPIYY_xN5UXs8P5vbE9uouD3zpqrVZUWw",
//           authDomain: "bantaybp-bc1ae.firebaseapp.com",
//           projectId: "bantaybp-bc1ae",
//           storageBucket: "bantaybp-bc1ae.firebasestorage.app",
//           messagingSenderId: "524819277974",
//           appId: "1:524819277974:web:f9363079dce61ac104fab7"));
//   runApp(const MyApp());
// }

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
        '/user/login': (context) => const UserLoginScreen(),
        '/user/signup': (context) => const UserSignupScreen(),
        '/user/home': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          return UserHomeScreen(tabIndex: args as int?);
        },
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
