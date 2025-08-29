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

  UserProfile({
    required this.userId,
    required this.name,
    required this.email,
    required this.age,
    required this.gender,
    required this.registrationDate,
    required this.lastLogin,
    required this.accountStatus,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      age: json['age'] as int,
      gender: json['gender'] as String,
      registrationDate: _parseTimestamp(json['registrationDate']),
      lastLogin: _parseTimestamp(json['lastLogin']),
      accountStatus: json['accountStatus'] as String,
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
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'age': age,
      'gender': gender,
      'registrationDate': registrationDate,
      'lastLogin': lastLogin,
      'accountStatus': accountStatus,
    };
  }
}