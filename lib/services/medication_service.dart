import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/medication.dart';
import 'notification_service.dart';

class MedicationService {
  static const String _medicationsKey = 'medications';
  static const String _consultationKey = 'consultation';
  static const String _notificationsKey = 'notifications';

  Future<void> saveMedication(Medication medication) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final medications = await getMedications();
      medications.add(medication);

      final medicationsJson =
          medications.map((m) => jsonEncode(m.toMap())).toList();
      await prefs.setStringList(_medicationsKey, medicationsJson);
    } catch (e) {
      print('Error saving medication: $e');
      // Handle error appropriately
    }
  }

  Future<void> updateMedication(Medication medication) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final medications = await getMedications();

      final index = medications.indexWhere((m) => m.id == medication.id);
      if (index != -1) {
        medications[index] = medication;
        final medicationsJson =
            medications.map((m) => jsonEncode(m.toMap())).toList();
        await prefs.setStringList(_medicationsKey, medicationsJson);
      }
    } catch (e) {
      print('Error updating medication: $e');
      // Handle error appropriately
    }
  }

  Future<void> deleteMedication(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final medications = await getMedications();
      medications.removeWhere((m) => m.id == id);

      final medicationsJson =
          medications.map((m) => jsonEncode(m.toMap())).toList();
      await prefs.setStringList(_medicationsKey, medicationsJson);
    } catch (e) {
      print('Error deleting medication: $e');
      // Handle error appropriately
    }
  }

  Future<List<Medication>> getMedications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final medicationsJson = prefs.getStringList(_medicationsKey) ?? [];

      return medicationsJson.map((json) {
        try {
          return Medication.fromMap(jsonDecode(json));
        } catch (e) {
          print('Error parsing medication JSON: $e');
          // Return a default medication if parsing fails
          return Medication(
            id: '',
            drugName: 'Unknown Medication',
            dose: 'Unknown Dose',
            time: '',
          );
        }
      }).toList();
    } catch (e) {
      print('Error getting medications: $e');
      return [];
    }
  }

  Future<void> saveConsultation(DateTime date,
      {String? physicianName, String? clinicAddress}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final consultationData = {
        'date': date.toIso8601String(),
        'physicianName': physicianName,
        'clinicAddress': clinicAddress,
      };
      await prefs.setString(_consultationKey, jsonEncode(consultationData));
    } catch (e) {
      print('Error saving consultation: $e');
      // Handle error appropriately
    }
  }

  Future<Map<String, dynamic>?> getConsultation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final consultationJson = prefs.getString(_consultationKey);

      if (consultationJson != null) {
        return jsonDecode(consultationJson);
      }
      return null;
    } catch (e) {
      print('Error getting consultation: $e');
      return null;
    }
  }

  Future<void> saveNotification(Map<String, dynamic> notification) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notifications = await getNotifications();
      notifications.add(notification);

      await prefs.setStringList(
          _notificationsKey, notifications.map((n) => jsonEncode(n)).toList());

      // Schedule the actual notification
      await _scheduleNotification(notification);
    } catch (e) {
      print('Error saving notification: $e');
      // Handle error appropriately
    }
  }

  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList(_notificationsKey) ?? [];

      return notificationsJson
          .map((json) => jsonDecode(json) as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Error getting notifications: $e');
      return [];
    }
  }

  Future<void> clearNotification(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notifications = await getNotifications();
      notifications.removeWhere((n) => n['id'] == id);

      await prefs.setStringList(
          _notificationsKey, notifications.map((n) => jsonEncode(n)).toList());
    } catch (e) {
      print('Error clearing notification: $e');
      // Handle error appropriately
    }
  }

  Future<void> clearAllNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_notificationsKey);
    } catch (e) {
      print('Error clearing all notifications: $e');
      // Handle error appropriately
    }
  }

  // Schedule a notification based on the notification data
  Future<void> _scheduleNotification(Map<String, dynamic> notification) async {
    try {
      final notificationService = NotificationService();
      final String type = notification['type'] ?? '';
      final String title = notification['title'] ?? '';
      final String message = notification['message'] ?? '';
      final String id = notification['id'] ?? '';

      // Generate a unique notification ID
      final int notificationId = id.hashCode.abs() % 100000;

      switch (type) {
        case 'medication':
          // Schedule medication reminder
          if (notification.containsKey('time')) {
            final String timeString = notification['time'];
            final List<String> timeParts = timeString.split(RegExp(r'[:\s]'));
            if (timeParts.length >= 2) {
              final int hour = int.parse(timeParts[0]);
              final int minute = timeParts.length > 2 &&
                      timeParts[1].length == 2
                  ? int.parse(timeParts[1])
                  : (timeParts[1].contains('AM')
                      ? int.parse(timeParts[1].replaceAll('AM', '').trim())
                      : int.parse(timeParts[1].replaceAll('PM', '').trim()) +
                          12);

              final TimeOfDay timeOfDay =
                  TimeOfDay(hour: hour % 24, minute: minute);
              await notificationService.scheduleRecurringNotification(
                id: notificationId,
                title: title,
                body: message,
                timeOfDay: timeOfDay,
                repeatInterval: RepeatInterval.daily,
              );
            }
          }
          break;

        case 'bp_reading':
          // Schedule BP reading reminder
          if (notification.containsKey('time')) {
            final String timeString = notification['time'];
            final List<String> timeParts = timeString.split(RegExp(r'[:\s]'));
            if (timeParts.length >= 2) {
              final int hour = int.parse(timeParts[0]);
              final int minute = timeParts.length > 2 &&
                      timeParts[1].length == 2
                  ? int.parse(timeParts[1])
                  : (timeParts[1].contains('AM')
                      ? int.parse(timeParts[1].replaceAll('AM', '').trim())
                      : int.parse(timeParts[1].replaceAll('PM', '').trim()) +
                          12);

              final TimeOfDay timeOfDay =
                  TimeOfDay(hour: hour % 24, minute: minute);
              await notificationService.scheduleRecurringNotification(
                id: notificationId,
                title: title,
                body: message,
                timeOfDay: timeOfDay,
                repeatInterval: RepeatInterval.daily,
              );
            }
          }
          break;

        case 'consultation':
          // Schedule consultation reminder
          if (notification.containsKey('timestamp')) {
            final DateTime scheduledTime =
                DateTime.fromMillisecondsSinceEpoch(notification['timestamp']);
            await notificationService.scheduleNotification(
              id: notificationId,
              title: title,
              body: message,
              scheduledTime: scheduledTime,
            );
          }
          break;

        case 'frequency_setting':
          // Schedule recurring notification based on frequency
          if (notification.containsKey('frequency') &&
              notification.containsKey('time')) {
            final String frequency = notification['frequency'];
            final String timeString = notification['time'];
            final List<String> timeParts = timeString.split(RegExp(r'[:\s]'));

            if (timeParts.length >= 2) {
              final int hour = int.parse(timeParts[0]);
              final int minute = timeParts.length > 2 &&
                      timeParts[1].length == 2
                  ? int.parse(timeParts[1])
                  : (timeParts[1].contains('AM')
                      ? int.parse(timeParts[1].replaceAll('AM', '').trim())
                      : int.parse(timeParts[1].replaceAll('PM', '').trim()) +
                          12);

              final TimeOfDay timeOfDay =
                  TimeOfDay(hour: hour % 24, minute: minute);

              RepeatInterval repeatInterval;
              switch (frequency.toLowerCase()) {
                case 'daily':
                  repeatInterval = RepeatInterval.daily;
                  break;
                case 'weekly':
                  repeatInterval = RepeatInterval.weekly;
                  break;
                case 'monthly':
                  repeatInterval = RepeatInterval.monthly;
                  break;
                default:
                  repeatInterval = RepeatInterval.daily;
              }

              await notificationService.scheduleRecurringNotification(
                id: notificationId,
                title: title,
                body: message,
                timeOfDay: timeOfDay,
                repeatInterval: repeatInterval,
              );
            }
          }
          break;
      }
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  // Cancel a scheduled notification
  Future<void> cancelScheduledNotification(String id) async {
    try {
      final notificationService = NotificationService();
      final int notificationId = id.hashCode.abs() % 100000;
      await notificationService.cancelNotification(notificationId);
    } catch (e) {
      print('Error canceling scheduled notification: $e');
    }
  }
}
