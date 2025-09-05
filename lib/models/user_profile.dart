import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String userId;
  final String name;
  final String email;
  final int age;
  final String gender;
  final DateTime registrationDate;
  final DateTime lastLogin;
  final String accountStatus; // active/inactive
  final String? username; // Optional username field

  UserProfile({
    required this.userId,
    required this.name,
    required this.email,
    required this.age,
    required this.gender,
    required this.registrationDate,
    required this.lastLogin,
    required this.accountStatus,
    this.username, // Optional username parameter
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      email: json['email'] as String? ?? '',
      age: json['age'] as int? ?? 0,
      gender: json['gender'] as String? ?? 'Unknown',
      registrationDate: _parseTimestamp(json['registrationDate']),
      lastLogin: _parseTimestamp(json['lastLogin']),
      accountStatus: json['accountStatus'] as String? ?? 'inactive',
      username: json['username'] as String?, // Optional username field
    );
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) {
      return DateTime.now();
    }

    // If it's already a DateTime, return it
    if (timestamp is DateTime) {
      return timestamp;
    }

    // If it's a Timestamp object from Firebase
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }

    // If it's a string, parse it
    if (timestamp is String) {
      return DateTime.parse(timestamp);
    }

    // Default fallback
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'userId': userId,
      'name': name,
      'age': age,
      'gender': gender,
      'registrationDate': registrationDate,
      'lastLogin': lastLogin,
      'accountStatus': accountStatus,
    };

    // Only include email if it's not empty
    if (email.isNotEmpty) {
      json['email'] = email;
    }

    // Only include username if it exists
    if (username != null) {
      json['username'] = username;
    }

    return json;
  }
}
