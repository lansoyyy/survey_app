import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notification_service.dart';

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false, // Don't auto-start to avoid issues
      isForegroundMode: false, // Don't use foreground mode initially
      notificationChannelId: 'survey_app_background_channel',
      initialNotificationTitle: 'BantayBP Service',
      initialNotificationContent: 'Managing your health reminders',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  // Don't start the service automatically
  // service.startService();
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Initialize notifications for background service
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Set up the background service timer
  Timer.periodic(const Duration(minutes: 1), (timer) async {
    // Check if there are any notifications that need to be triggered
    // This is a simple check that runs every minute
    // In a real app, you might want to implement a more sophisticated scheduling system

    // You can add logic here to check for pending notifications
    // and trigger them if needed

    // Update the foreground service notification
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: "BantayBP Service",
        content:
            "Managing your health reminders - Last check: ${DateTime.now().toString().substring(11, 16)}",
      );
    }
  });
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  // This is required for iOS background execution
  return true;
}

// Function to stop the background service
Future<void> stopBackgroundService() async {
  final service = FlutterBackgroundService();
  service.invoke('stopService');
}
