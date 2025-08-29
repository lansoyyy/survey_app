import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:survey_app/services/auth_service.dart';
import 'package:survey_app/services/user_service.dart';
import 'package:survey_app/models/survey_response.dart';
import 'package:survey_app/utils/colors.dart';
import 'package:survey_app/widgets/button_widget.dart';
import 'package:survey_app/widgets/text_widget.dart';
import 'package:survey_app/widgets/survey/survey_progress_indicator.dart';
import 'package:survey_app/widgets/survey/survey_question_card.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  int _currentQuestionIndex = 0;
  final Map<String, dynamic> _answers = {};
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  bool _isSubmitting = false;

  // Sample survey questions for hypertension risk assessment
  final List<Map<String, dynamic>> _questions = [
    {
      'id': 'age',
      'text': 'What is your age?',
      'type': 'number',
      'required': true,
    },
    {
      'id': 'gender',
      'text': 'What is your gender?',
      'type': 'single_choice',
      'options': ['Male', 'Female', 'Other'],
      'required': true,
    },
    {
      'id': 'height',
      'text': 'What is your height? (cm)',
      'type': 'number',
      'required': true,
    },
    {
      'id': 'weight',
      'text': 'What is your weight? (kg)',
      'type': 'number',
      'required': true,
    },
    {
      'id': 'family_history',
      'text': 'Do you have a family history of hypertension?',
      'type': 'boolean',
      'required': true,
    },
    {
      'id': 'smoking',
      'text': 'Do you smoke?',
      'type': 'boolean',
      'required': true,
    },
    {
      'id': 'exercise_frequency',
      'text': 'How often do you exercise?',
      'type': 'single_choice',
      'options': ['Never', 'Rarely', 'Occasionally', 'Regularly', 'Daily'],
      'required': true,
    },
    {
      'id': 'stress_level',
      'text': 'How would you rate your stress level? (0-10)',
      'type': 'scale_rating',
      'required': true,
    },
    {
      'id': 'medications',
      'text': 'Are you currently taking any medications for blood pressure?',
      'type': 'boolean',
      'required': true,
    },
    {
      'id': 'conditions',
      'text': 'Do you have any of the following conditions?',
      'type': 'multiple_choice',
      'options': ['Diabetes', 'Heart Disease', 'Kidney Disease', 'None'],
      'required': true,
    },
  ];

  void _onAnswerChanged(String questionId, dynamic value) {
    setState(() {
      if (value == null) {
        _answers.remove(questionId);
      } else {
        _answers[questionId] = value;
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  bool _isCurrentQuestionAnswered() {
    final currentQuestion = _questions[_currentQuestionIndex];
    return _answers.containsKey(currentQuestion['id']);
  }

  double _calculateRiskScore() {
    // Simple risk calculation based on answers
    double score = 0;

    // Age factor
    if (_answers['age'] != null) {
      // Convert to int properly to avoid type errors
      int age = (_answers['age'] as num).toInt();
      if (age >= 60)
        score += 30;
      else if (age >= 40)
        score += 20;
      else if (age >= 30) score += 10;
    }

    // Family history factor
    if (_answers['family_history'] == true) score += 20;

    // Smoking factor
    if (_answers['smoking'] == true) score += 15;

    // Exercise factor
    String? exerciseFreq = _answers['exercise_frequency'];
    if (exerciseFreq == 'Never' || exerciseFreq == 'Rarely')
      score += 15;
    else if (exerciseFreq == 'Occasionally') score += 10;

    // Stress factor
    if (_answers['stress_level'] != null) {
      // Convert to int properly to avoid type errors
      int stress = (_answers['stress_level'] as num).toInt();
      if (stress >= 8)
        score += 20;
      else if (stress >= 5) score += 10;
    }

    // Medications factor
    if (_answers['medications'] == true) score += 25;

    // Conditions factor
    List<String>? conditions = _answers['conditions'] is List
        ? _answers['conditions'].cast<String>()
        : null;
    if (conditions != null &&
        conditions.isNotEmpty &&
        !conditions.contains('None')) {
      score += conditions.length * 15;
    }

    // BMI calculation if height and weight are provided
    if (_answers['height'] != null && _answers['weight'] != null) {
      // Convert to double properly to avoid type errors
      double height =
          (_answers['height'] as num).toDouble() / 100; // Convert cm to meters
      double weight = (_answers['weight'] as num).toDouble();
      double bmi = weight / (height * height);

      if (bmi >= 30)
        score += 25; // Obese
      else if (bmi >= 25)
        score += 15; // Overweight
      else if (bmi < 18.5) score += 10; // Underweight
    }

    // Cap the score at 100
    return score > 100 ? 100 : score;
  }

  void _submitSurvey() async {
    if (_authService.currentUser == null) {
      Fluttertoast.showToast(
        msg: 'You must be logged in to submit the survey',
        backgroundColor: healthRed,
        textColor: Colors.white,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final riskScore = _calculateRiskScore();

      final surveyResponse = SurveyResponse(
        responseId: '', // Will be generated by Firebase
        userId: _authService.currentUser!.uid,
        surveyId: 'hypertension_risk_assessment',
        answers: _answers,
        submittedAt: DateTime.now(),
        riskScore: riskScore, // riskScore is already a double
        completionStatus: 'completed',
      );

      await _userService.submitSurveyResponse(surveyResponse);

      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Survey submitted successfully!',
          backgroundColor: healthGreen,
          textColor: Colors.white,
        );

        // Reset the survey
        setState(() {
          _currentQuestionIndex = 0;
          _answers.clear();
          _isSubmitting = false;
        });
      }
    } catch (e) {
      print('Error submitting survey: $e');
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Failed to submit survey. Please try again.',
          backgroundColor: healthRed,
          textColor: Colors.white,
        );
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = _questions[_currentQuestionIndex];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SurveyProgressIndicator(
            currentQuestion: _currentQuestionIndex + 1,
            totalQuestions: _questions.length,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SurveyQuestionCard(
              questionId: currentQuestion['id'],
              questionText: currentQuestion['text'],
              questionType: currentQuestion['type'],
              options: currentQuestion['options'],
              isRequired: currentQuestion['required'],
              currentValue: _answers[currentQuestion['id']],
              onAnswerChanged: (value) {
                _onAnswerChanged(currentQuestion['id'], value);
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (_currentQuestionIndex > 0)
                Expanded(
                  child: ButtonWidget(
                    label: 'Previous',
                    onPressed: _previousQuestion,
                    color: surface,
                    textColor: primary,
                    isOutlined: true,
                  ),
                ),
              if (_currentQuestionIndex > 0) const SizedBox(width: 16),
              Expanded(
                child: _isSubmitting
                    ? const Center(
                        child: CircularProgressIndicator(color: primary))
                    : ButtonWidget(
                        label: _currentQuestionIndex == _questions.length - 1
                            ? 'Submit'
                            : 'Next',
                        onPressed: () {
                          if (_currentQuestionIndex == _questions.length - 1) {
                            _submitSurvey();
                          } else {
                            _nextQuestion();
                          }
                        },
                        color: _isCurrentQuestionAnswered() ||
                                !_questions[_currentQuestionIndex]['required']
                            ? primary
                            : grey,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
