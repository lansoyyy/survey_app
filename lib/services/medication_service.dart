import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/medication.dart';

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
        return Medication.fromMap(jsonDecode(json));
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
}
