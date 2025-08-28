import 'package:flutter/material.dart';

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
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      totalUsers: json['totalUsers'] as int,
      activeUsers: json['activeUsers'] as int,
      averageRiskScore: (json['averageRiskScore'] as num).toDouble(),
      completionRate: (json['completionRate'] as num).toDouble(),
      demographicData: json['demographicData'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'analyticsId': analyticsId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'totalUsers': totalUsers,
      'activeUsers': activeUsers,
      'averageRiskScore': averageRiskScore,
      'completionRate': completionRate,
      'demographicData': demographicData,
    };
  }
}