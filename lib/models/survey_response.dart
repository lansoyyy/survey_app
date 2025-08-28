import 'package:flutter/material.dart';

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
      submittedAt: DateTime.parse(json['submittedAt'] as String),
      riskScore: (json['riskScore'] as num).toDouble(),
      completionStatus: json['completionStatus'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'responseId': responseId,
      'userId': userId,
      'surveyId': surveyId,
      'answers': answers,
      'submittedAt': submittedAt.toIso8601String(),
      'riskScore': riskScore,
      'completionStatus': completionStatus,
    };
  }
}