import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
  String _selectedCategory = 'hypertension';
  bool _hasSelectedCategory = false;
  String? _clearTrigger; // Used to trigger text field clearing

  // Survey questions organized by category
  final Map<String, List<Map<String, dynamic>>> _questionsByCategory = {
    'hypertension': [
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
    ],
    'diabetes': [
      {
        'id': 'diabetes_age',
        'text': 'What is your age?',
        'type': 'number',
        'required': true,
      },
      {
        'id': 'diabetes_gender',
        'text': 'What is your gender?',
        'type': 'single_choice',
        'options': ['Male', 'Female', 'Other'],
        'required': true,
      },
      {
        'id': 'diabetes_bmi',
        'text': 'What is your BMI?',
        'type': 'number',
        'required': true,
      },
      {
        'id': 'diabetes_family_history',
        'text': 'Do you have a family history of diabetes?',
        'type': 'boolean',
        'required': true,
      },
      {
        'id': 'diabetes_physical_activity',
        'text': 'How often do you engage in physical activity?',
        'type': 'single_choice',
        'options': ['Never', 'Rarely', 'Occasionally', 'Regularly', 'Daily'],
        'required': true,
      },
      {
        'id': 'diabetes_diet',
        'text': 'How would you describe your diet?',
        'type': 'single_choice',
        'options': ['Poor', 'Fair', 'Good', 'Excellent'],
        'required': true,
      },
      {
        'id': 'diabetes_high_bp',
        'text': 'Do you have high blood pressure?',
        'type': 'boolean',
        'required': true,
      },
      {
        'id': 'diabetes_high_cholesterol',
        'text': 'Do you have high cholesterol?',
        'type': 'boolean',
        'required': true,
      },
      {
        'id': 'diabetes_smoking',
        'text': 'Do you smoke?',
        'type': 'boolean',
        'required': true,
      },
      {
        'id': 'diabetes_alcohol',
        'text': 'Do you consume alcohol regularly?',
        'type': 'boolean',
        'required': true,
      },
    ],
    'heart_disease': [
      {
        'id': 'heart_age',
        'text': 'What is your age?',
        'type': 'number',
        'required': true,
      },
      {
        'id': 'heart_gender',
        'text': 'What is your gender?',
        'type': 'single_choice',
        'options': ['Male', 'Female', 'Other'],
        'required': true,
      },
      {
        'id': 'heart_chest_pain',
        'text': 'Do you experience chest pain?',
        'type': 'boolean',
        'required': true,
      },
      {
        'id': 'heart_breathlessness',
        'text': 'Do you experience breathlessness?',
        'type': 'boolean',
        'required': true,
      },
      {
        'id': 'heart_palpitations',
        'text': 'Do you experience palpitations?',
        'type': 'boolean',
        'required': true,
      },
      {
        'id': 'heart_fatigue',
        'text': 'Do you experience unusual fatigue?',
        'type': 'boolean',
        'required': true,
      },
      {
        'id': 'heart_family_history',
        'text': 'Do you have a family history of heart disease?',
        'type': 'boolean',
        'required': true,
      },
      {
        'id': 'heart_smoking',
        'text': 'Do you smoke?',
        'type': 'boolean',
        'required': true,
      },
      {
        'id': 'heart_high_bp',
        'text': 'Do you have high blood pressure?',
        'type': 'boolean',
        'required': true,
      },
      {
        'id': 'heart_diabetes',
        'text': 'Do you have diabetes?',
        'type': 'boolean',
        'required': true,
      },
    ],
  };

  List<Map<String, dynamic>> get _currentQuestions =>
      _questionsByCategory[_selectedCategory] ??
      _questionsByCategory['hypertension']!;

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
    debugPrint(
        'Next question requested: currentIndex=$_currentQuestionIndex, total=${_currentQuestions.length}');

    if (_currentQuestionIndex < _currentQuestions.length - 1) {
      setState(() {
        _clearTrigger = DateTime.now().toString(); // Trigger clearing
        _currentQuestionIndex++;
        debugPrint('Moved to next question: $_currentQuestionIndex');
      });
    }
  }

  void _previousQuestion() {
    debugPrint(
        'Previous question requested: currentIndex=$_currentQuestionIndex');

    if (_currentQuestionIndex > 0) {
      setState(() {
        _clearTrigger = DateTime.now().toString(); // Trigger clearing
        _currentQuestionIndex--;
        debugPrint('Moved to previous question: $_currentQuestionIndex');
      });
    }
  }

  bool _isCurrentQuestionAnswered() {
    final currentQuestion = _currentQuestions[_currentQuestionIndex];
    return _answers.containsKey(currentQuestion['id']);
  }

  double _calculateRiskScore() {
    // Simple risk calculation based on answers
    double score = 0;

    if (_selectedCategory == 'hypertension') {
      // Hypertension risk calculation
      // Age factor
      if (_answers['age'] != null) {
        // Convert to int properly to avoid type errors
        int age = (_answers['age'] as num).toInt();
        if (age >= 60) {
          score += 30;
        } else if (age >= 40) {
          score += 20;
        } else if (age >= 30) {
          score += 10;
        }
      }

      // Family history factor
      if (_answers['family_history'] == true) {
        score += 20;
      }

      // Smoking factor
      if (_answers['smoking'] == true) {
        score += 15;
      }

      // Exercise factor
      String? exerciseFreq = _answers['exercise_frequency'];
      if (exerciseFreq == 'Never' || exerciseFreq == 'Rarely') {
        score += 15;
      } else if (exerciseFreq == 'Occasionally') {
        score += 10;
      }

      // Stress factor
      if (_answers['stress_level'] != null) {
        // Convert to int properly to avoid type errors
        int stress = (_answers['stress_level'] as num).toInt();
        if (stress >= 8) {
          score += 20;
        } else if (stress >= 5) {
          score += 10;
        }
      }

      // Medications factor
      if (_answers['medications'] == true) {
        score += 25;
      }

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
        double height = (_answers['height'] as num).toDouble() /
            100; // Convert cm to meters
        double weight = (_answers['weight'] as num).toDouble();
        double bmi = weight / (height * height);

        if (bmi >= 30) {
          score += 25; // Obese
        } else if (bmi >= 25) {
          score += 15; // Overweight
        } else if (bmi < 18.5) {
          score += 10; // Underweight
        }
      }
    } else if (_selectedCategory == 'diabetes') {
      // Diabetes risk calculation
      if (_answers['diabetes_age'] != null) {
        int age = (_answers['diabetes_age'] as num).toInt();
        if (age >= 45) {
          score += 25;
        } else if (age >= 35) {
          score += 15;
        }
      }

      if (_answers['diabetes_family_history'] == true) {
        score += 20;
      }
      if (_answers['diabetes_high_bp'] == true) {
        score += 15;
      }
      if (_answers['diabetes_high_cholesterol'] == true) {
        score += 15;
      }
      if (_answers['diabetes_smoking'] == true) {
        score += 10;
      }

      String? diet = _answers['diabetes_diet'];
      if (diet == 'Poor') {
        score += 20;
      } else if (diet == 'Fair') {
        score += 10;
      }

      String? activity = _answers['diabetes_physical_activity'];
      if (activity == 'Never' || activity == 'Rarely') {
        score += 20;
      } else if (activity == 'Occasionally') {
        score += 10;
      }
    } else if (_selectedCategory == 'heart_disease') {
      // Heart disease risk calculation
      if (_answers['heart_age'] != null) {
        int age = (_answers['heart_age'] as num).toInt();
        if (age >= 55) {
          score += 30;
        } else if (age >= 45) {
          score += 20;
        }
      }

      if (_answers['heart_family_history'] == true) {
        score += 25;
      }
      if (_answers['heart_smoking'] == true) {
        score += 20;
      }
      if (_answers['heart_high_bp'] == true) {
        score += 15;
      }
      if (_answers['heart_diabetes'] == true) {
        score += 15;
      }

      if (_answers['heart_chest_pain'] == true ||
          _answers['heart_breathlessness'] == true ||
          _answers['heart_palpitations'] == true ||
          _answers['heart_fatigue'] == true) {
        score += 25;
      }
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
      _clearTrigger = DateTime.now().toString(); // Trigger clearing
      _isSubmitting = true;
    });

    try {
      final riskScore = _calculateRiskScore();

      final surveyResponse = SurveyResponse(
        responseId: '', // Will be generated by Firebase
        userId: _authService.currentUser!.uid,
        surveyId: _selectedCategory,
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
          _hasSelectedCategory = false; // Reset the category selection flag
          _clearTrigger = DateTime.now().toString(); // Trigger clearing
        });
      }
    } catch (e) {
      // Use debugPrint instead of print for production code
      debugPrint('Error submitting survey: $e');
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

  void _selectCategory(String category) {
    debugPrint('Selecting category: $category');
    debugPrint(
        'Before state update: selectedCategory=$_selectedCategory, currentIndex=$_currentQuestionIndex, answersCount=${_answers.length}, hasSelectedCategory=$_hasSelectedCategory');

    setState(() {
      _selectedCategory = category;
      _currentQuestionIndex = 0;
      _answers.clear();
      _hasSelectedCategory = true; // Set the flag when category is selected
      _clearTrigger = DateTime.now().toString(); // Trigger clearing
    });

    // Add a small delay to ensure the state is updated before logging
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint(
          'After state update: selectedCategory=$_selectedCategory, currentIndex=$_currentQuestionIndex, answersCount=${_answers.length}, hasSelectedCategory=$_hasSelectedCategory');
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
        'Building SurveyScreen: currentIndex=$_currentQuestionIndex, answersCount=${_answers.length}, selectedCategory=$_selectedCategory, hasSelectedCategory=$_hasSelectedCategory');

    // Show category selection if at the beginning and category hasn't been selected yet
    final shouldShowCategorySelection =
        _currentQuestionIndex == 0 && !_hasSelectedCategory;
    debugPrint(
        'Should show category selection: $shouldShowCategorySelection (currentIndex==0: ${_currentQuestionIndex == 0}, !hasSelectedCategory: ${!_hasSelectedCategory})');

    if (shouldShowCategorySelection) {
      debugPrint('Showing category selection screen');
      return _buildCategorySelection();
    }

    final currentQuestion = _currentQuestions[_currentQuestionIndex];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextWidget(
                text: _selectedCategory.replaceAll('_', ' ').toUpperCase(),
                fontSize: 14,
                color: primary,
                fontFamily: 'Bold',
              ),
              TextButton(
                onPressed: () {
                  debugPrint('Change Category button pressed');
                  setState(() {
                    _currentQuestionIndex = 0;
                    _answers.clear();
                    _hasSelectedCategory =
                        false; // Reset the flag when changing category
                    _clearTrigger =
                        DateTime.now().toString(); // Trigger clearing
                    debugPrint(
                        'State reset: currentIndex=$_currentQuestionIndex, answersCount=${_answers.length}, hasSelectedCategory=$_hasSelectedCategory');
                  });
                },
                child: TextWidget(
                  text: 'Change Category',
                  fontSize: 14,
                  color: primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SurveyProgressIndicator(
            currentQuestion: _currentQuestionIndex + 1,
            totalQuestions: _currentQuestions.length,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SurveyQuestionCard(
              key: ValueKey(
                  '$_selectedCategory-$_currentQuestionIndex-$_clearTrigger'), // Use key to force rebuild
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
                    color: Colors.grey,
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
                        label: _currentQuestionIndex ==
                                _currentQuestions.length - 1
                            ? 'Submit'
                            : 'Next',
                        onPressed: () {
                          if (_currentQuestionIndex ==
                              _currentQuestions.length - 1) {
                            _submitSurvey();
                          } else {
                            _nextQuestion();
                          }
                        },
                        color: _isCurrentQuestionAnswered() ||
                                !_currentQuestions[_currentQuestionIndex]
                                    ['required']
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

  Widget _buildCategorySelection() {
    final categories = _questionsByCategory.keys.toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          TextWidget(
            text: 'Select Health Category',
            fontSize: 24,
            color: textPrimary,
            fontFamily: 'Bold',
          ),
          const SizedBox(height: 8),
          TextWidget(
            text: 'Choose which health assessment you want to complete',
            fontSize: 16,
            color: textLight,
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final displayName = category.replaceAll('_', ' ');
                final capitalizedDisplayName = displayName
                    .split(' ')
                    .map((word) =>
                        word.substring(0, 1).toUpperCase() + word.substring(1))
                    .join(' ');

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: TextWidget(
                      text: capitalizedDisplayName,
                      fontSize: 18,
                      color: textPrimary,
                      fontFamily: 'Bold',
                    ),
                    subtitle: TextWidget(
                      text:
                          'Complete a $capitalizedDisplayName risk assessment',
                      fontSize: 14,
                      color: textLight,
                    ),
                    trailing:
                        const Icon(Icons.arrow_forward_ios, color: primary),
                    onTap: () {
                      debugPrint('Tapped on category: $category');
                      _selectCategory(category);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
