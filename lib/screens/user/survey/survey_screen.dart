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
import 'package:survey_app/screens/user/analysis/analysis_screen.dart';

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
  String _selectedCategory = 'biological_genetic';
  bool _hasSelectedCategory = false;
  bool _showSummary = false;
  String? _clearTrigger; // Used to trigger text field clearing

  // Survey questions organized by category
  final Map<String, List<Map<String, dynamic>>> _questionsByCategory = {
    'biological_genetic': [
      {
        'id': 'age',
        'text': 'How old are you?',
        'type': 'single_choice',
        'options': ['Under 40', '40–49', '50 and above'],
        'required': true,
        'category': 'Biological and Genetic Factors',
        'scores': {'Under 40': 0, '40–49': 1, '50 and above': 3},
      },
      {
        'id': 'sex',
        'text': 'What is your sex assigned at birth?',
        'type': 'single_choice',
        'options': ['Male', 'Female'],
        'required': true,
        'category': 'Biological and Genetic Factors',
        'scores': {'Male': 2, 'Female': 0},
      },
      {
        'id': 'family_history',
        'text':
            'Do you have a family history of hypertension or diabetes (parents or siblings)?',
        'type': 'single_choice',
        'options': ['Yes', 'No / Not sure'],
        'required': true,
        'category': 'Biological and Genetic Factors',
        'scores': {'Yes': 2, 'No / Not sure': 0},
      },
      {
        'id': 'conditions',
        'text':
            'Have you been diagnosed with any of the following conditions? (Check all that apply)',
        'type': 'multiple_choice',
        'options': [
          'Diabetes',
          'High cholesterol or triglycerides',
          'None of the above'
        ],
        'required': true,
        'category': 'Biological and Genetic Factors',
        'scores': {
          'Diabetes': 2,
          'High cholesterol or triglycerides': 1,
          'None of the above': 0
        },
      },
      {
        'id': 'genetic_test',
        'text':
            '(Optional if available) Have you been tested for any genetic predisposition to hypertension?',
        'type': 'single_choice',
        'options': [
          'Yes, and results show increased risk',
          'Yes, no risk found',
          'No / Not tested'
        ],
        'required': false,
        'category': 'Biological and Genetic Factors',
        'scores': {
          'Yes, and results show increased risk': 3,
          'Yes, no risk found': 0,
          'No / Not tested': 0
        },
      },
    ],
    'socioeconomic_demographic': [
      {
        'id': 'education',
        'text': 'What is your highest level of education completed?',
        'type': 'single_choice',
        'options': ['Elementary or below', 'High school', 'College or higher'],
        'required': true,
        'category': 'Socioeconomic & Demographic Factors',
        'scores': {
          'Elementary or below': 2,
          'High school': 1,
          'College or higher': 0
        },
      },
      {
        'id': 'financial_situation',
        'text': 'How would you describe your current financial situation?',
        'type': 'single_choice',
        'options': [
          'Struggling or low-income',
          'Comfortable / middle-income',
          'Well-off / high-income'
        ],
        'required': true,
        'category': 'Socioeconomic & Demographic Factors',
        'scores': {
          'Struggling or low-income': 2,
          'Comfortable / middle-income': 1,
          'Well-off / high-income': 2
        },
      },
      {
        'id': 'residence',
        'text': 'Where do you currently live?',
        'type': 'single_choice',
        'options': ['Urban area', 'Rural or provincial area'],
        'required': true,
        'category': 'Socioeconomic & Demographic Factors',
        'scores': {'Urban area': 1, 'Rural or provincial area': 0},
      },
      {
        'id': 'living_arrangement',
        'text': 'What is your current living arrangement?',
        'type': 'single_choice',
        'options': [
          'I live alone',
          'I live with a large household (5 or more)',
          'I live with 1–4 people'
        ],
        'required': true,
        'category': 'Socioeconomic & Demographic Factors',
        'scores': {
          'I live alone': 1,
          'I live with a large household (5 or more)': 1,
          'I live with 1–4 people': 0
        },
      },
      {
        'id': 'marital_status',
        'text': 'What is your marital status?',
        'type': 'single_choice',
        'options': ['Widowed or Divorced', 'Single or Married'],
        'required': true,
        'category': 'Socioeconomic & Demographic Factors',
        'scores': {'Widowed or Divorced': 1, 'Single or Married': 0},
      },
    ],
    'lifestyle_behavioral': [
      {
        'id': 'smoking',
        'text': 'Do you currently smoke or have you smoked in the past year?',
        'type': 'single_choice',
        'options': ['Yes', 'No'],
        'required': true,
        'category': 'Lifestyle and Behavioral Factors',
        'scores': {'Yes': 2, 'No': 0},
      },
      {
        'id': 'alcohol',
        'text': 'How often do you consume alcoholic drinks?',
        'type': 'single_choice',
        'options': [
          '3 or more times per week',
          '1–2 times per week',
          'Rarely or never'
        ],
        'required': true,
        'category': 'Lifestyle and Behavioral Factors',
        'scores': {
          '3 or more times per week': 2,
          '1–2 times per week': 1,
          'Rarely or never': 0
        },
      },
      {
        'id': 'physical_activity',
        'text':
            'How often do you engage in physical activity (e.g., walking, exercise)?',
        'type': 'single_choice',
        'options': [
          'Rarely / Not at all',
          '1–2 times per week',
          '3 or more times per week'
        ],
        'required': true,
        'category': 'Lifestyle and Behavioral Factors',
        'scores': {
          'Rarely / Not at all': 2,
          '1–2 times per week': 1,
          '3 or more times per week': 0
        },
      },
      {
        'id': 'sleep_pattern',
        'text': 'How would you describe your sleep pattern?',
        'type': 'single_choice',
        'options': [
          'Irregular or insufficient (<6 hrs/night)',
          'Mostly regular (6–8 hrs/night)'
        ],
        'required': true,
        'category': 'Lifestyle and Behavioral Factors',
        'scores': {
          'Irregular or insufficient (<6 hrs/night)': 1,
          'Mostly regular (6–8 hrs/night)': 0
        },
      },
      {
        'id': 'stress',
        'text': 'How often do you feel overwhelmed or stressed?',
        'type': 'single_choice',
        'options': ['Often or daily', 'Sometimes', 'Rarely'],
        'required': true,
        'category': 'Lifestyle and Behavioral Factors',
        'scores': {'Often or daily': 1, 'Sometimes': 0.5, 'Rarely': 0},
      },
      {
        'id': 'meal_planning',
        'text': 'How would you describe your meal planning habits?',
        'type': 'single_choice',
        'options': [
          'I frequently eat out / don\'t plan meals',
          'I try to eat balanced meals'
        ],
        'required': true,
        'category': 'Lifestyle and Behavioral Factors',
        'scores': {
          'I frequently eat out / don\'t plan meals': 1,
          'I try to eat balanced meals': 0
        },
      },
    ],
    'dietary_nutritional': [
      {
        'id': 'unhealthy_foods',
        'text':
            'How often do you eat salty, fatty, or sugary foods (e.g., fast food, processed snacks)?',
        'type': 'single_choice',
        'options': ['Almost daily', '2–3 times a week', 'Rarely', 'Never'],
        'required': true,
        'category': 'Dietary and Nutritional Factors',
        'scores': {
          'Almost daily': 3,
          '2–3 times a week': 2,
          'Rarely': 1,
          'Never': 0
        },
      },
      {
        'id': 'fruits_vegetables',
        'text': 'How often do you consume fruits and vegetables?',
        'type': 'single_choice',
        'options': ['Rarely', '2–3 times per week', 'Daily'],
        'required': true,
        'category': 'Dietary and Nutritional Factors',
        'scores': {'Rarely': 2, '2–3 times per week': 1, 'Daily': 0},
      },
      {
        'id': 'bmi',
        'text':
            'What is your Body Mass Index (BMI)? (optional: auto-calculate based on height/weight input)',
        'type': 'single_choice',
        'options': [
          '25–29.9 (Overweight)',
          '30+ (Obese)',
          '18.5–24.9 (Normal)'
        ],
        'required': true,
        'category': 'Dietary and Nutritional Factors',
        'scores': {
          '25–29.9 (Overweight)': 2,
          '30+ (Obese)': 3,
          '18.5–24.9 (Normal)': 0
        },
      },
      {
        'id': 'waist_circumference',
        'text': 'Do you know your waist circumference or waist-to-hip ratio?',
        'type': 'single_choice',
        'options': [
          'Yes, and it\'s high (male ≥90cm, female ≥80cm)',
          'No or within normal range'
        ],
        'required': true,
        'category': 'Dietary and Nutritional Factors',
        'scores': {
          'Yes, and it\'s high (male ≥90cm, female ≥80cm)': 2,
          'No or within normal range': 0
        },
      },
      {
        'id': 'high_protein_fat',
        'text':
            'How often do you eat high-protein/high-fat meals (e.g., meat-heavy, fried foods)?',
        'type': 'single_choice',
        'options': ['Daily or often', 'Occasionally', 'Rarely'],
        'required': true,
        'category': 'Dietary and Nutritional Factors',
        'scores': {'Daily or often': 2, 'Occasionally': 1, 'Rarely': 0},
      },
      {
        'id': 'potassium_calcium_fiber',
        'text':
            'Do you include potassium, calcium, or fiber-rich foods in your diet?',
        'type': 'single_choice',
        'options': ['Rarely', 'Occasionally', 'Daily'],
        'required': true,
        'category': 'Dietary and Nutritional Factors',
        'scores': {'Rarely': 2, 'Occasionally': 1, 'Daily': 0},
      },
    ],
    'healthcare_management': [
      {
        'id': 'medication_hypertension',
        'text': 'Do you take medication for hypertension?',
        'type': 'single_choice',
        'options': [
          'Yes, but not regularly',
          'Yes, regularly',
          'No (not needed or not diagnosed)'
        ],
        'required': true,
        'category': 'Healthcare Access and Management Behaviors',
        'scores': {
          'Yes, but not regularly': 3,
          'Yes, regularly': 0,
          'No (not needed or not diagnosed)': 0
        },
      },
      {
        'id': 'access_medication',
        'text': 'Do you have access to antihypertensive medications if needed?',
        'type': 'single_choice',
        'options': ['No or uncertain', 'Yes'],
        'required': true,
        'category': 'Healthcare Access and Management Behaviors',
        'scores': {'No or uncertain': 2, 'Yes': 0},
      },
      {
        'id': 'bp_monitor',
        'text': 'Do you check your blood pressure at home using a BP monitor?',
        'type': 'single_choice',
        'options': ['Rarely or never', 'Occasionally', 'Regularly'],
        'required': true,
        'category': 'Healthcare Access and Management Behaviors',
        'scores': {'Rarely or never': 2, 'Occasionally': 1, 'Regularly': 0},
      },
      {
        'id': 'traditional_remedies',
        'text': 'Do you use traditional remedies for managing blood pressure?',
        'type': 'single_choice',
        'options': ['Yes', 'No'],
        'required': true,
        'category': 'Healthcare Access and Management Behaviors',
        'scores': {'Yes': 1, 'No': 0},
      },
      {
        'id': 'medical_advice',
        'text':
            'Have you been advised by a healthcare provider on how to manage your blood pressure?',
        'type': 'single_choice',
        'options': ['No or not sure', 'Yes'],
        'required': true,
        'category': 'Healthcare Access and Management Behaviors',
        'scores': {'No or not sure': 2, 'Yes': 0},
      },
      {
        'id': 'bp_awareness',
        'text': 'Are you aware of your current blood pressure levels?',
        'type': 'single_choice',
        'options': ['No', 'Yes'],
        'required': true,
        'category': 'Healthcare Access and Management Behaviors',
        'scores': {'No': 2, 'Yes': 0},
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
      _questionsByCategory['biological_genetic']!;

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
    } else if (_currentQuestionIndex == _currentQuestions.length - 1) {
      // Show summary screen when reaching the end
      setState(() {
        _showSummary = true;
      });
    }
  }

  void _skipQuestion() {
    debugPrint(
        'Skip question requested: currentIndex=$_currentQuestionIndex, total=${_currentQuestions.length}');

    // Remove any existing answer for the current question
    final currentQuestion = _currentQuestions[_currentQuestionIndex];
    _onAnswerChanged(currentQuestion['id'], null);

    if (_currentQuestionIndex < _currentQuestions.length - 1) {
      setState(() {
        _clearTrigger = DateTime.now().toString(); // Trigger clearing
        _currentQuestionIndex++;
        debugPrint('Skipped to next question: $_currentQuestionIndex');
      });
    } else {
      // If this is the last question, show the summary screen
      setState(() {
        _showSummary = true;
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
    // New comprehensive hypertension risk scoring based on the provided matrix
    double score = 0;

    // Calculate score for each question based on the scores map for all categories
    if (_selectedCategory == 'biological_genetic' ||
        _selectedCategory == 'socioeconomic_demographic' ||
        _selectedCategory == 'lifestyle_behavioral' ||
        _selectedCategory == 'dietary_nutritional' ||
        _selectedCategory == 'healthcare_management') {
      // Calculate score for each question based on the scores map
      for (final question in _currentQuestions) {
        final questionId = question['id'];
        final answer = _answers[questionId];

        if (answer != null) {
          final scores = question['scores'] as Map<String, dynamic>;

          if (question['type'] == 'multiple_choice' && answer is List) {
            // For multiple choice questions, add scores for each selected option
            for (final selectedOption in answer) {
              score += (scores[selectedOption] ?? 0).toDouble();
            }
          } else if (answer is String) {
            // For single choice questions
            score += (scores[answer] ?? 0).toDouble();
          }
        }
      }
    } else if (_selectedCategory == 'diabetes') {
      // Diabetes risk calculation (existing implementation)
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
      // Heart disease risk calculation (existing implementation)
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

    return score;
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

        // Navigate to AnalysisScreen after successful submission
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                AnalysisScreen(surveyResponse: surveyResponse),
          ),
        );
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

    if (_showSummary) {
      debugPrint('Showing summary screen');
      return _buildSummaryScreen();
    }

    final currentQuestion = _currentQuestions[_currentQuestionIndex];
    final category = currentQuestion['category'] ?? '';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(),
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
          // Show category name above the question if available
          if (category.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextWidget(
              text: category,
              fontSize: 12,
              color: textLight,
              fontFamily: 'Bold',
            ),
          ],
          const SizedBox(height: 8),
          SurveyProgressIndicator(
            currentQuestion: _currentQuestionIndex + 1,
            totalQuestions: _currentQuestions.length,
          ),
          const SizedBox(height: 16),
          // Show current risk score and level
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: primary.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextWidget(
                      text: 'Current Risk Score:',
                      fontSize: 14,
                      color: textPrimary,
                      fontFamily: 'Medium',
                    ),
                    TextWidget(
                      text: _calculateRiskScore().toStringAsFixed(1),
                      fontSize: 16,
                      color: primary,
                      fontFamily: 'Bold',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildRiskLevelIndicator(_calculateRiskScore()),
              ],
            ),
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
                            ? 'View Summary'
                            : 'Next',
                        onPressed: () {
                          _nextQuestion();
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
          // Skip Question button - only shown for non-required questions
          if (!_currentQuestions[_currentQuestionIndex]['required'] &&
              _currentQuestionIndex < _currentQuestions.length - 1)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Center(
                child: TextButton(
                  onPressed: _skipQuestion,
                  child: TextWidget(
                    text: 'Skip Question',
                    fontSize: 14,
                    color: textLight,
                    fontFamily: 'Medium',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategorySelection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          TextWidget(
            text: 'Hypertension Risk Assessment',
            fontSize: 24,
            color: textPrimary,
            fontFamily: 'Bold',
          ),
          const SizedBox(height: 8),
          TextWidget(
            text:
                'This assessment will evaluate your risk factors for hypertension across multiple categories',
            fontSize: 16,
            color: textLight,
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView(
              children: [
                _buildCategoryCard(
                  'Biological and Genetic Factors',
                  'Age, sex, family history, and genetic predisposition',
                  'biological_genetic',
                ),
                _buildCategoryCard(
                  'Socioeconomic & Demographic Factors',
                  'Education, financial situation, and living arrangements',
                  'socioeconomic_demographic',
                ),
                _buildCategoryCard(
                  'Lifestyle and Behavioral Factors',
                  'Smoking, alcohol, physical activity, and stress',
                  'lifestyle_behavioral',
                ),
                _buildCategoryCard(
                  'Dietary and Nutritional Factors',
                  'Eating habits, BMI, and nutritional intake',
                  'dietary_nutritional',
                ),
                _buildCategoryCard(
                  'Healthcare Access and Management Behaviors',
                  'Medication use, monitoring, and healthcare access',
                  'healthcare_management',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String title, String subtitle, String category) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: TextWidget(
          text: title,
          fontSize: 18,
          color: textPrimary,
          fontFamily: 'Bold',
        ),
        subtitle: TextWidget(
          text: subtitle,
          fontSize: 14,
          color: textLight,
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: primary),
        onTap: () {
          debugPrint('Tapped on category: $category');
          _selectCategory(category);
        },
      ),
    );
  }

  Widget _buildRiskLevelIndicator(double score) {
    String riskLevel;
    Color riskColor;
    double progress;

    if (score < 10) {
      riskLevel = 'Low Risk';
      riskColor = Colors.green;
      progress = 0.25;
    } else if (score < 20) {
      riskLevel = 'Moderate Risk';
      riskColor = Colors.yellow;
      progress = 0.5;
    } else if (score < 30) {
      riskLevel = 'High Risk';
      riskColor = Colors.orange;
      progress = 0.75;
    } else {
      riskLevel = 'Very High Risk';
      riskColor = Colors.red;
      progress = 1.0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextWidget(
              text: 'Risk Level:',
              fontSize: 12,
              color: textLight,
              fontFamily: 'Medium',
            ),
            TextWidget(
              text: riskLevel,
              fontSize: 12,
              color: riskColor,
              fontFamily: 'Bold',
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(riskColor),
          minHeight: 6,
        ),
      ],
    );
  }

  Widget _buildSummaryScreen() {
    final riskScore = _calculateRiskScore();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextWidget(
                text: 'SURVEY SUMMARY',
                fontSize: 14,
                color: primary,
                fontFamily: 'Bold',
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _showSummary = false;
                    _currentQuestionIndex = _currentQuestions.length - 1;
                  });
                },
                child: TextWidget(
                  text: 'Edit Answers',
                  fontSize: 14,
                  color: primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Risk score summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: primary.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                TextWidget(
                  text: 'Your Hypertension Risk Score',
                  fontSize: 18,
                  color: textPrimary,
                  fontFamily: 'Bold',
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextWidget(
                      text: riskScore.toStringAsFixed(1),
                      fontSize: 36,
                      color: primary,
                      fontFamily: 'Bold',
                    ),
                    const SizedBox(width: 8),
                    TextWidget(
                      text: 'out of 100',
                      fontSize: 16,
                      color: textLight,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildRiskLevelIndicator(riskScore),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  child: TextWidget(
                    text: _getRiskLevelDescription(riskScore),
                    fontSize: 14,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextWidget(
            text: 'Your Answers',
            fontSize: 18,
            color: textPrimary,
            fontFamily: 'Bold',
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _currentQuestions.length,
              itemBuilder: (context, index) {
                final question = _currentQuestions[index];
                final answer = _answers[question['id']];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextWidget(
                          text: question['text'],
                          fontSize: 14,
                          color: textPrimary,
                          fontFamily: 'Medium',
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: TextWidget(
                            text: _formatAnswer(answer, question),
                            fontSize: 14,
                            color: primary,
                            fontFamily: 'Medium',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ButtonWidget(
                  label: 'Previous',
                  onPressed: () {
                    setState(() {
                      _showSummary = false;
                      _currentQuestionIndex = _currentQuestions.length - 1;
                    });
                  },
                  color: Colors.grey,
                  textColor: primary,
                  isOutlined: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _isSubmitting
                    ? const Center(
                        child: CircularProgressIndicator(color: primary))
                    : ButtonWidget(
                        label: 'Submit Survey',
                        onPressed: _submitSurvey,
                        color: primary,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getRiskLevelDescription(double score) {
    if (score < 10) {
      return 'You have a low risk of developing hypertension. Continue maintaining a healthy lifestyle.';
    } else if (score < 20) {
      return 'You have a moderate risk of developing hypertension. Consider making some lifestyle changes to reduce your risk.';
    } else if (score < 30) {
      return 'You have a high risk of developing hypertension. It is recommended to consult with a healthcare provider and make significant lifestyle changes.';
    } else {
      return 'You have a very high risk of developing hypertension. Please consult with a healthcare provider as soon as possible for proper evaluation and management.';
    }
  }

  String _formatAnswer(dynamic answer, Map<String, dynamic> question) {
    if (answer == null) {
      return 'Not answered';
    }

    if (answer is List) {
      return answer.join(', ');
    }

    if (question['type'] == 'boolean') {
      return answer == true ? 'Yes' : 'No';
    }

    return answer.toString();
  }
}
