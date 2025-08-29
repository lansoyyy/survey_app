import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SurveyResponse {
  final String responseId;
  final String userId;
  final String surveyId;
  final Map<String, dynamic> answers;
  final DateTime submittedAt;
  final double riskScore;
  final String completionStatus; // complete/incomplete

  SurveyResponse({
    required this.responseId,
    required this.userId,
    required this.surveyId,
    required this.answers,
    required this.submittedAt,
    required this.riskScore,
    required this.completionStatus,
  });

  factory SurveyResponse.fromJson(Map<String, dynamic> json) {
    return SurveyResponse(
      responseId: json['responseId'] as String,
      userId: json['userId'] as String,
      surveyId: json['surveyId'] as String,
      answers: json['answers'] as Map<String, dynamic>,
      submittedAt: _parseTimestamp(json['submittedAt']),
      riskScore: (json['riskScore'] as num).toDouble(),
      completionStatus: json['completionStatus'] as String,
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
      'responseId': responseId,
      'userId': userId,
      'surveyId': surveyId,
      'answers': answers,
      'submittedAt': submittedAt,
      'riskScore': riskScore, // This is already a double
      'completionStatus': completionStatus,
    };
  }
}