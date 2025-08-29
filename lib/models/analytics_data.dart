import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsData {
  final String analyticsId;
  final DateTime startDate;
  final DateTime endDate;
  final int totalUsers;
  final int activeUsers;
  final double averageRiskScore;
  final double completionRate;
  final Map<String, dynamic> demographicData;

  AnalyticsData({
    required this.analyticsId,
    required this.startDate,
    required this.endDate,
    required this.totalUsers,
    required this.activeUsers,
    required this.averageRiskScore,
    required this.completionRate,
    required this.demographicData,
  });

  factory AnalyticsData.fromJson(Map<String, dynamic> json) {
    return AnalyticsData(
      analyticsId: json['analyticsId'] as String,
      startDate: _parseTimestamp(json['startDate']),
      endDate: _parseTimestamp(json['endDate']),
      totalUsers: json['totalUsers'] as int,
      activeUsers: json['activeUsers'] as int,
      averageRiskScore: (json['averageRiskScore'] as num).toDouble(),
      completionRate: (json['completionRate'] as num).toDouble(),
      demographicData: json['demographicData'] as Map<String, dynamic>,
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
      'analyticsId': analyticsId,
      'startDate': startDate,
      'endDate': endDate,
      'totalUsers': totalUsers,
      'activeUsers': activeUsers,
      'averageRiskScore': averageRiskScore,
      'completionRate': completionRate,
      'demographicData': demographicData,
    };
  }
}