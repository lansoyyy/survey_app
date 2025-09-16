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
      // Biological & Genetic Factors
      {
        'id': 'age',
        'text': 'How old are you?',
        'type': 'single_choice',
        'options': ['Under 40', '40–49', '50 and above'],
        'required': true,
        'category': 'Biological & Genetic',
      },
      {
        'id': 'sex',
        'text': 'What is your sex assigned at birth?',
        'type': 'single_choice',
        'options': ['Male', 'Female'],
        'required': true,
        'category': 'Biological & Genetic',
      },
      {
        'id': 'family_history',
        'text':
            'Do you have a family history of hypertension or diabetes (parents or siblings)?',
        'type': 'single_choice',
        'options': ['Yes', 'No / Not sure'],
        'required': true,
        'category': 'Biological & Genetic',
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
        'category': 'Biological & Genetic',
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
        'category': 'Biological & Genetic',
      },

      // Socioeconomic & Demographic Factors
      {
        'id': 'education',
        'text': 'What is your highest level of education completed?',
        'type': 'single_choice',
        'options': ['Elementary or below', 'High school', 'College or higher'],
        'required': true,
        'category': 'Socioeconomic & Demographic',
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
        'category': 'Socioeconomic & Demographic',
      },
      {
        'id': 'residence',
        'text': 'Where do you currently live?',
        'type': 'single_choice',
        'options': ['Urban area', 'Rural or provincial area'],
        'required': true,
        'category': 'Socioeconomic & Demographic',
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
        'category': 'Socioeconomic & Demographic',
      },
      {
        'id': 'marital_status',
        'text': 'What is your marital status?',
        'type': 'single_choice',
        'options': ['Widowed or Divorced', 'Single or Married'],
        'required': true,
        'category': 'Socioeconomic & Demographic',
      },

      // Lifestyle & Behavioral Factors
      {
        'id': 'smoking',
        'text': 'Do you currently smoke or have you smoked in the past year?',
        'type': 'single_choice',
        'options': ['Yes', 'No'],
        'required': true,
        'category': 'Lifestyle & Behavioral',
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
        'category': 'Lifestyle & Behavioral',
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
        'category': 'Lifestyle & Behavioral',
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
        'category': 'Lifestyle & Behavioral',
      },
      {
        'id': 'stress',
        'text': 'How often do you feel overwhelmed or stressed?',
        'type': 'single_choice',
        'options': ['Often or daily', 'Sometimes', 'Rarely'],
        'required': true,
        'category': 'Lifestyle & Behavioral',
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
        'category': 'Lifestyle & Behavioral',
      },

      // Dietary & Nutritional Factors
      {
        'id': 'unhealthy_foods',
        'text':
            'How often do you eat salty, fatty, or sugary foods (e.g., fast food, processed snacks)?',
        'type': 'single_choice',
        'options': ['Almost daily', '2–3 times a week', 'Rarely', 'Never'],
        'required': true,
        'category': 'Dietary & Nutritional',
      },
      {
        'id': 'fruits_vegetables',
        'text': 'How often do you consume fruits and vegetables?',
        'type': 'single_choice',
        'options': ['Rarely', '2–3 times per week', 'Daily'],
        'required': true,
        'category': 'Dietary & Nutritional',
      },
      {
        'id': 'height',
        'text': 'What is your height? (cm)',
        'type': 'number',
        'required': true,
        'category': 'Dietary & Nutritional',
      },
      {
        'id': 'weight',
        'text': 'What is your weight? (kg)',
        'type': 'number',
        'required': true,
        'category': 'Dietary & Nutritional',
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
        'category': 'Dietary & Nutritional',
      },
      {
        'id': 'high_protein_fat',
        'text':
            'How often do you eat high-protein/high-fat meals (e.g., meat-heavy, fried foods)?',
        'type': 'single_choice',
        'options': ['Daily or often', 'Occasionally', 'Rarely'],
        'required': true,
        'category': 'Dietary & Nutritional',
      },
      {
        'id': 'potassium_calcium_fiber',
        'text':
            'Do you include potassium, calcium, or fiber-rich foods in your diet?',
        'type': 'single_choice',
        'options': ['Rarely', 'Occasionally', 'Daily'],
        'required': true,
        'category': 'Dietary & Nutritional',
      },

      // Healthcare Access & Management Behaviors
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
        'category': 'Healthcare Access & Management',
      },
      {
        'id': 'access_medication',
        'text': 'Do you have access to antihypertensive medications if needed?',
        'type': 'single_choice',
        'options': ['No or uncertain', 'Yes'],
        'required': true,
        'category': 'Healthcare Access & Management',
      },
      {
        'id': 'bp_monitor',
        'text': 'Do you check your blood pressure at home using a BP monitor?',
        'type': 'single_choice',
        'options': ['Rarely or never', 'Occasionally', 'Regularly'],
        'required': true,
        'category': 'Healthcare Access & Management',
      },
      {
        'id': 'traditional_remedies',
        'text': 'Do you use traditional remedies for managing blood pressure?',
        'type': 'single_choice',
        'options': ['Yes', 'No'],
        'required': true,
        'category': 'Healthcare Access & Management',
      },
      {
        'id': 'medical_advice',
        'text':
            'Have you been advised by a healthcare provider on how to manage your blood pressure?',
        'type': 'single_choice',
        'options': ['No or not sure', 'Yes'],
        'required': true,
        'category': 'Healthcare Access & Management',
      },
      {
        'id': 'bp_awareness',
        'text': 'Are you aware of your current blood pressure levels?',
        'type': 'single_choice',
        'options': ['No', 'Yes'],
        'required': true,
        'category': 'Healthcare Access & Management',
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
    // New comprehensive hypertension risk scoring based on the provided matrix
    double score = 0;

    if (_selectedCategory == 'hypertension') {
      // Biological & Genetic Factors
      // Age scoring
      final age = _answers['age'];
      if (age == '40–49') {
        score += 1;
      } else if (age == '50 and above') {
        score += 3;
      }

      // Sex scoring
      if (_answers['sex'] == 'Male') {
        score += 2;
      }

      // Family history scoring
      if (_answers['family_history'] == 'Yes') {
        score += 2;
      }

      // Conditions scoring
      final conditions = _answers['conditions'] is List
          ? _answers['conditions'].cast<String>()
          : null;
      if (conditions != null) {
        if (conditions.contains('Diabetes')) {
          score += 2;
        }
        if (conditions.contains('High cholesterol or triglycerides')) {
          score += 1;
        }
      }

      // Genetic test scoring
      if (_answers['genetic_test'] == 'Yes, and results show increased risk') {
        score += 3;
      }

      // Socioeconomic & Demographic Factors
      // Education scoring
      if (_answers['education'] == 'Elementary or below') {
        score += 2;
      }

      // Financial situation scoring
      if (_answers['financial_situation'] == 'Struggling or low-income' ||
          _answers['financial_situation'] == 'Well-off / high-income') {
        score += 2;
      } else if (_answers['financial_situation'] ==
          'Comfortable / middle-income') {
        score += 1;
      }

      // Residence scoring
      if (_answers['residence'] == 'Urban area') {
        score += 1;
      }

      // Living arrangement scoring
      if (_answers['living_arrangement'] == 'I live alone' ||
          _answers['living_arrangement'] ==
              'I live with a large household (5 or more)') {
        score += 1;
      }

      // Marital status scoring
      if (_answers['marital_status'] == 'Widowed or Divorced') {
        score += 1;
      }

      // Lifestyle & Behavioral Factors
      // Smoking scoring
      if (_answers['smoking'] == 'Yes') {
        score += 2;
      }

      // Alcohol scoring
      if (_answers['alcohol'] == '3 or more times per week') {
        score += 2;
      } else if (_answers['alcohol'] == '1–2 times per week') {
        score += 1;
      }

      // Physical activity scoring
      if (_answers['physical_activity'] == 'Rarely / Not at all') {
        score += 2;
      } else if (_answers['physical_activity'] == '1–2 times per week') {
        score += 1;
      }

      // Sleep pattern scoring
      if (_answers['sleep_pattern'] ==
          'Irregular or insufficient (<6 hrs/night)') {
        score += 1;
      }

      // Stress scoring
      if (_answers['stress'] == 'Often or daily') {
        score += 1;
      } else if (_answers['stress'] == 'Sometimes') {
        score += 0.5;
      }

      // Meal planning scoring
      if (_answers['meal_planning'] ==
          'I frequently eat out / don\'t plan meals') {
        score += 1;
      }

      // Dietary & Nutritional Factors
      // Unhealthy foods scoring
      if (_answers['unhealthy_foods'] == 'Almost daily') {
        score += 3;
      } else if (_answers['unhealthy_foods'] == '2–3 times a week') {
        score += 2;
      } else if (_answers['unhealthy_foods'] == 'Rarely') {
        score += 1;
      }

      // Fruits and vegetables scoring
      if (_answers['fruits_vegetables'] == 'Rarely') {
        score += 2;
      } else if (_answers['fruits_vegetables'] == '2–3 times per week') {
        score += 1;
      }

      // BMI calculation and scoring
      if (_answers['height'] != null && _answers['weight'] != null) {
        try {
          double height = (_answers['height'] as num).toDouble() /
              100; // Convert cm to meters
          double weight = (_answers['weight'] as num).toDouble();
          double bmi = weight / (height * height);

          if (bmi >= 30) {
            score += 3; // Obese
          } else if (bmi >= 25) {
            score += 2; // Overweight
          }
        } catch (e) {
          debugPrint('Error calculating BMI: $e');
        }
      }

      // Waist circumference scoring
      if (_answers['waist_circumference'] ==
          'Yes, and it\'s high (male ≥90cm, female ≥80cm)') {
        score += 2;
      }

      // High protein/fat scoring
      if (_answers['high_protein_fat'] == 'Daily or often') {
        score += 2;
      } else if (_answers['high_protein_fat'] == 'Occasionally') {
        score += 1;
      }

      // Potassium/calcium/fiber scoring
      if (_answers['potassium_calcium_fiber'] == 'Rarely') {
        score += 2;
      } else if (_answers['potassium_calcium_fiber'] == 'Occasionally') {
        score += 1;
      }

      // Healthcare Access & Management Behaviors
      // Medication hypertension scoring
      if (_answers['medication_hypertension'] == 'Yes, but not regularly') {
        score += 3;
      }

      // Access to medication scoring
      if (_answers['access_medication'] == 'No or uncertain') {
        score += 2;
      }

      // BP monitor scoring
      if (_answers['bp_monitor'] == 'Rarely or never') {
        score += 2;
      } else if (_answers['bp_monitor'] == 'Occasionally') {
        score += 1;
      }

      // Traditional remedies scoring
      if (_answers['traditional_remedies'] == 'Yes') {
        score += 1;
      }

      // Medical advice scoring
      if (_answers['medical_advice'] == 'No or not sure') {
        score += 2;
      }

      // BP awareness scoring
      if (_answers['bp_awareness'] == 'No') {
        score += 2;
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
