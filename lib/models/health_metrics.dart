import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HealthMetrics {
  final String metricId;
  final String userId;
  final int systolicBP;
  final int diastolicBP;
  final int heartRate;
  final double weight;
  final double height;
  final double bmi;
  final DateTime recordedAt;

  HealthMetrics({
    required this.metricId,
    required this.userId,
    required this.systolicBP,
    required this.diastolicBP,
    required this.heartRate,
    required this.weight,
    required this.height,
    required this.bmi,
    required this.recordedAt,
  });

  factory HealthMetrics.fromJson(Map<String, dynamic> json) {
    return HealthMetrics(
      metricId: json['metricId'] as String,
      userId: json['userId'] as String,
      systolicBP: json['systolicBP'] as int,
      diastolicBP: json['diastolicBP'] as int,
      heartRate: json['heartRate'] as int,
      weight: (json['weight'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      bmi: (json['bmi'] as num).toDouble(),
      recordedAt: _parseTimestamp(json['recordedAt']),
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
      'metricId': metricId,
      'userId': userId,
      'systolicBP': systolicBP,
      'diastolicBP': diastolicBP,
      'heartRate': heartRate,
      'weight': weight,
      'height': height,
      'bmi': bmi,
      'recordedAt': recordedAt,
    };
  }
}