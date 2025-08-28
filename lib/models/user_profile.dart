import 'package:flutter/material.dart';

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
      registrationDate: DateTime.parse(json['registrationDate'] as String),
      lastLogin: DateTime.parse(json['lastLogin'] as String),
      accountStatus: json['accountStatus'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'age': age,
      'gender': gender,
      'registrationDate': registrationDate.toIso8601String(),
      'lastLogin': lastLogin.toIso8601String(),
      'accountStatus': accountStatus,
    };
  }
}