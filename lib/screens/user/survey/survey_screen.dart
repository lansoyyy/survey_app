import 'package:flutter/material.dart';
import 'package:survey_app/utils/colors.dart';
import 'package:survey_app/widgets/button_widget.dart';
import 'package:survey_app/widgets/text_widget.dart';
import 'package:survey_app/widgets/survey/survey_progress_indicator.dart';
import 'package:survey_app/widgets/survey/survey_question_card.dart';

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  int _currentQuestionIndex = 0;
  final Map<String, dynamic> _answers = {};

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

  void _submitSurvey() {
    // In a real app, this would submit the survey to a backend
    // For now, we'll just show a confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: TextWidget(
            text: 'Survey Submitted',
            fontSize: 20,
            color: primary,
            fontFamily: 'Bold',
          ),
          content: TextWidget(
            text: 'Thank you for completing the hypertension risk assessment survey.',
            fontSize: 16,
            color: textPrimary,
          ),
          actions: [
            ButtonWidget(
              label: 'OK',
              onPressed: () {
                Navigator.of(context).pop();
                // Reset the survey
                setState(() {
                  _currentQuestionIndex = 0;
                  _answers.clear();
                });
              },
              width: 100,
              height: 40,
            ),
          ],
        );
      },
    );
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
              if (_currentQuestionIndex > 0)
                const SizedBox(width: 16),
              Expanded(
                child: ButtonWidget(
                  label: _currentQuestionIndex == _questions.length - 1 ? 'Submit' : 'Next',
                  onPressed: () {
                    if (_currentQuestionIndex == _questions.length - 1) {
                      _submitSurvey();
                    } else {
                      _nextQuestion();
                    }
                  },
                  color: _isCurrentQuestionAnswered() || !_questions[_currentQuestionIndex]['required'] 
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