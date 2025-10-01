import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:survey_app/services/auth_service.dart';
import 'package:survey_app/services/user_service.dart';
import 'package:survey_app/models/survey_response.dart';
import 'package:survey_app/utils/colors.dart';
import 'package:survey_app/widgets/text_widget.dart';
import 'package:survey_app/widgets/analysis/risk_assessment_card.dart';
import 'package:survey_app/widgets/button_widget.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class AnalysisScreen extends StatefulWidget {
  final SurveyResponse? surveyResponse;

  const AnalysisScreen({super.key, this.surveyResponse});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  List<SurveyResponse> _surveyResponses = [];
  List<Map<String, dynamic>> _recommendations = [];
  List<Map<String, dynamic>> _trendData = [];
  bool _isLoading = true;
  int? _selectedRecommendationIndex;

  @override
  void initState() {
    super.initState();
    if (widget.surveyResponse != null) {
      // Use the provided survey response
      setState(() {
        _surveyResponses = [widget.surveyResponse!];
        _trendData = _convertToTrendData(_surveyResponses);
        _recommendations = _generateRecommendations(_surveyResponses);
        _isLoading = false;
      });
    } else {
      // Load data from Firebase
      _loadSurveyData();
    }
  }

  void _loadSurveyData() {
    if (_authService.currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    // Listen to survey responses
    _userService.getUserSurveyResponses(_authService.currentUser!.uid).listen(
        (responses) {
      setState(() {
        _surveyResponses = responses;
        _trendData = _convertToTrendData(responses);
        _recommendations = _generateRecommendations(responses);
        _isLoading = false;
      });
    }, onError: (error) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Failed to load survey data',
          backgroundColor: healthRed,
          textColor: Colors.white,
        );
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  List<Map<String, dynamic>> _convertToTrendData(
      List<SurveyResponse> responses) {
    List<Map<String, dynamic>> trendData = [];

    // Group responses by category and get the most recent for each category
    Map<String, List<SurveyResponse>> responsesByCategory = {};

    for (final response in responses) {
      if ([
        'biological_genetic',
        'socioeconomic_demographic',
        'lifestyle_behavioral',
        'dietary_nutritional',
        'healthcare_management'
      ].contains(response.surveyId)) {
        if (!responsesByCategory.containsKey(response.surveyId)) {
          responsesByCategory[response.surveyId] = [];
        }
        responsesByCategory[response.surveyId]!.add(response);
      }
    }

    // For each category, take the last 6 responses for the trend chart
    for (final category in responsesByCategory.keys) {
      final categoryResponses = responsesByCategory[category]!;
      final recentResponses = categoryResponses.length > 6
          ? categoryResponses.sublist(0, 6)
          : categoryResponses;

      for (int i = 0; i < recentResponses.length; i++) {
        final response = recentResponses[i];
        final month = _getMonthAbbreviation(response.submittedAt.month);
        final categoryName = _getCategoryDisplayName(category);

        // Check if we already have an entry for this month
        final existingIndex =
            trendData.indexWhere((item) => item['month'] == month);

        if (existingIndex != -1) {
          // Add to existing month entry
          trendData[existingIndex][category] = response.riskScore.toInt();
        } else {
          // Create new month entry
          final newEntry = {
            'month': month,
            'Biological and Genetic Factors': 0,
            'Socioeconomic & Demographic Factors': 0,
            'Lifestyle and Behavioral Factors': 0,
            'Dietary and Nutritional Factors': 0,
            'Healthcare Access and Management Behaviors': 0,
          };
          newEntry[category] = response.riskScore.toInt();
          trendData.add(newEntry);
        }
      }
    }

    // Sort by month (chronological order - newest first)
    trendData.sort((a, b) => b['month'].compareTo(a['month']));

    // Take only the last 6 months
    if (trendData.length > 6) {
      trendData = trendData.sublist(0, 6);
    }

    return trendData;
  }

  String _getMonthAbbreviation(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  List<Map<String, dynamic>> _generateRecommendations(
      List<SurveyResponse> responses) {
    List<Map<String, dynamic>> recommendations = [];

    // Only use age-specific recommendations
    if (responses.isNotEmpty) {
      // Find a response with age data
      SurveyResponse? responseWithAge;
      for (final response in responses) {
        if (response.answers.containsKey('age')) {
          responseWithAge = response;
          break;
        }
      }

      if (responseWithAge != null) {
        final age = responseWithAge.answers['age'];
        if (age != null) {
          final ageGroup = _getAgeGroupFromAnswer(age);

          // Determine if user has hypertension based on risk score
          // Use the hypertension survey score if available, otherwise use the overall risk
          double riskScore;
          if (responseWithAge.surveyId == 'hypertension') {
            riskScore = responseWithAge.riskScore;
          } else {
            riskScore = _getLatestRiskScore();
          }

          final hasHypertension = riskScore >= 13;
          recommendations.addAll(
              _getAgeSpecificRecommendations(ageGroup, hasHypertension));
        }
      } else {
        // If no response with age data, use a default age group
        recommendations.addAll(_getAgeSpecificRecommendations('30-39', false));
      }
    } else {
      // If no responses, use a default age group
      recommendations.addAll(_getAgeSpecificRecommendations('30-39', false));
    }

    return recommendations;
  }

  // Helper method to determine age group from answer
  String _getAgeGroupFromAnswer(dynamic age) {
    int ageValue;

    if (age is String) {
      if (age == 'Under 40') {
        return '20-29';
      } else if (age == '40–49') {
        return '40-49';
      } else if (age == '50 and above') {
        // For simplicity, we'll use 50-59 for this group
        return '50-59';
      }
      ageValue = int.tryParse(age) ?? 0;
    } else if (age is int) {
      ageValue = age;
    } else if (age is double) {
      ageValue = age.toInt();
    } else {
      ageValue = 0;
    }

    if (ageValue >= 20 && ageValue <= 29) {
      return '20-29';
    } else if (ageValue >= 30 && ageValue <= 39) {
      return '30-39';
    } else if (ageValue >= 40 && ageValue <= 49) {
      return '40-49';
    } else if (ageValue >= 50 && ageValue <= 59) {
      return '50-59';
    } else if (ageValue >= 60 && ageValue <= 69) {
      return '60-69';
    } else if (ageValue >= 70 && ageValue <= 79) {
      return '70-79';
    } else {
      // Default to a safe age group
      return '30-39';
    }
  }

  // Helper method to get age-specific recommendations
  List<Map<String, dynamic>> _getAgeSpecificRecommendations(
      String ageGroup, bool hasHypertension) {
    List<Map<String, dynamic>> recommendations = [];

    if (hasHypertension) {
      // Recommendations for those diagnosed with hypertension
      switch (ageGroup) {
        case '20-29':
          recommendations.addAll([
            {
              'title': 'Diet',
              'bullets': [
                'Eat fish, chicken, lean meat, beans, nuts, and seeds to lower BP and bad cholesterol.',
                'Limit sodium to 1,300 mg daily.',
                'Avoid sugary drinks and desserts; drink 6–8 glasses of water daily.'
              ],
              'priority': 'high',
            },
            {
              'title': 'Exercise',
              'bullets': [
                'Brisk walk or jog 30 minutes, 5 days a week.',
                'Warm up and cool down for 5–10 minutes.',
                'Monitor BP before and after exercise.'
              ],
              'priority': 'high',
            },
            {
              'title': 'Lifestyle Changes',
              'bullets': [
                'Sleep 7–9 hours nightly with a regular schedule.',
                'Maintain healthy weight (BMI <25).',
                'Avoid smoking and limit alcohol intake.'
              ],
              'priority': 'medium',
            },
            {
              'title': 'Medication Adherence',
              'bullets': [
                'Take medicines at the same time daily.',
                'Use pillbox/phone reminders.',
                'Don\'t stop/skip meds without doctor\'s advice.'
              ],
              'priority': 'high',
            },
            {
              'title': 'Exercise Reminder',
              'bullets': [
                'Consult your doctor before starting new exercises to ensure they\'re safe and appropriate.',
                'Avoid overexertion and listen to your body.'
              ],
              'priority': 'high',
            },
          ]);
          break;
        case '30-39':
          recommendations.addAll([
            {
              'title': 'Diet',
              'bullets': [
                'Eat more gulay (kangkong, malunggay, ampalaya) and fruits (banana, papaya, oranges, mangga).',
                'Limit sodium to 1,300 mg/day.',
                'Reduce sugary drinks/desserts; drink 6–8 glasses water daily.'
              ],
              'priority': 'high',
            },
            {
              'title': 'Exercise',
              'bullets': [
                'Brisk walking/jog 30 minutes/day, 5 days/week.',
                'Warm-up 5-10 mins before exercise and a cool-down after.',
                'Monitor BP before and after exercise.'
              ],
              'priority': 'high',
            },
            {
              'title': 'Lifestyle Changes',
              'bullets': [
                'Manage stress with short breaks and meditation.',
                'Sleep 7–9 hours nightly with a regular schedule.',
                'Avoid smoking and limt alcohol intake.'
              ],
              'priority': 'medium',
            },
            {
              'title': 'Medication Adherence',
              'bullets': [
                'Take medicines at the same time daily.',
                'Use pillbox/phone reminders.',
                'Track BP at home 2–3 times per week.'
              ],
              'priority': 'high',
            },
            {
              'title': 'Exercise Reminder',
              'bullets': [
                'Consult your doctor before starting new exercises to ensure they\'re safe and appropriate.',
                'Avoid overexertion and listen to your body.'
              ],
              'priority': 'high',
            },
          ]);
          break;
        case '40-49':
          recommendations.addAll([
            {
              'title': 'Diet',
              'bullets': [
                'Follow DASH diet with Filipino meals (sinigang w/ gulay, grilled tilapia, brown rice).',
                'Limit processed foods (canned, instant noodles, chips).',
                'Drink 6–8 glasses water daily (unless restricted).'
              ],
              'priority': 'high',
            },
            {
              'title': 'Exercise',
              'bullets': [
                'Walk/cycle 150 mins/week (30 mins, 5 days).',
                'Strength training 2x/week, 1–3 sets of 10–15 reps.',
                'Always warm up/cool down.'
              ],
              'priority': 'high',
            },
            {
              'title': 'Lifestyle Changes',
              'bullets': [
                'Practice relaxation exercises like yoga or stretching.',
                'Maintain a regular sleeping pattern & at least 7-9 hrs of sleep daily.',
                'Avoid smoking and limit alcohol intake.'
              ],
              'priority': 'medium',
            },
            {
              'title': 'Medication Adherence',
              'bullets': [
                'Take medicines consistently at same time.',
                'Use pillbox/phone reminders.',
                'Attend follow-up visits every 3–6 months.'
              ],
              'priority': 'high',
            },
            {
              'title': 'Exercise Reminder',
              'bullets': [
                'Consult your doctor before starting new exercises to ensure they\'re safe and appropriate.',
                'Avoid overexertion and listen to your body.'
              ],
              'priority': 'high',
            },
          ]);
          break;
        case '50-59':
          recommendations.addAll([
            {
              'title': 'Diet',
              'bullets': [
                'Choose boiled or grilled fish/chicken instead of fried.',
                'Increase vegetable servings (upo, sitaw, pechay).',
                'Drink 6–8 glasses water daily (unless restricted).'
              ],
              'priority': 'high',
            },
            {
              'title': 'Exercise',
              'bullets': [
                'Walk/jog 30 mins daily, 5 days/week.',
                'Join Zumba/dance for fun.',
                'Stretch daily 5–10 mins.'
              ],
              'priority': 'high',
            },
            {
              'title': 'Lifestyle Changes',
              'bullets': [
                'Avoid smoking/alcohol.',
                'Manage stress with hobbies, prayer, gardening.',
                'Maintain a healthy weight and monitor BMI.'
              ],
              'priority': 'medium',
            },
            {
              'title': 'Medication Adherence',
              'bullets': [
                'Take medicines consistently.',
                'Use phone reminders/pillbox.',
                'Attend follow-up visits every 3–6 months.'
              ],
              'priority': 'high',
            },
            {
              'title': 'Exercise Reminder',
              'bullets': [
                'Consult your doctor before starting new exercises to ensure they\'re safe and appropriate.',
                'Avoid overexertion and listen to your body.'
              ],
              'priority': 'high',
            },
          ]);
          break;
        case '60-69':
          recommendations.addAll([
            {
              'title': 'Diet',
              'bullets': [
                'Eat soft, nutritious foods (boiled saba, lugaw w/ malunggay, fish tinola).',
                'Maintain low-salt diet; avoid bagoong, instant, canned goods.',
                'Drink enough fluids unless restricted.'
              ],
              'priority': 'high',
            },
            {
              'title': 'Exercise',
              'bullets': [
                'Brisk walk/slow jog 30 mins, 5 days/week.',
                'Avoid sitting for long periods; move every hour.',
                'Monitor BP before and after exercise.'
              ],
              'priority': 'high',
            },
            {
              'title': 'Lifestyle Changes',
              'bullets': [
                'Ensure a safe home environment (remove clutter, handrails if needed).',
                'Maintain a regular sleeping pattern.',
                'Join social/church activities.'
              ],
              'priority': 'medium',
            },
            {
              'title': 'Medication Adherence',
              'bullets': [
                'Take prescribed medicines at the same time daily.',
                'Ask family members to assist in medication reminder.',
                'Check blood pressure at home 2x/week for monitoring.'
              ],
              'priority': 'high',
            },
            {
              'title': 'Exercise Reminder',
              'bullets': [
                'Consult your doctor before starting new exercises to ensure they\'re safe and appropriate.',
                'Avoid overexertion and listen to your body.'
              ],
              'priority': 'high',
            },
          ]);
          break;
        case '70-79':
          recommendations.addAll([
            {
              'title': 'Diet',
              'bullets': [
                'Eat soft, easy-to-chew foods (malunggay soup, mashed kalabasa).',
                'Drink enough water unless restricted.',
                'Eat small, frequent meals.'
              ],
              'priority': 'high',
            },
            {
              'title': 'Exercise',
              'bullets': [
                'Light walking 20–30 mins daily.',
                'Balance training 3x/week (heel-to-toe, one-leg w/ support).',
                'Stretching 2x/week after activity.'
              ],
              'priority': 'high',
            },
            {
              'title': 'Lifestyle Changes',
              'bullets': [
                'Maintain regular sleep routine.',
                'Join group/family activities.',
                'Keep home safe (lighting, clutter-free).'
              ],
              'priority': 'medium',
            },
            {
              'title': 'Medication Adherence',
              'bullets': [
                'Follow medication schedule regularly.',
                'Ask family members to assist in medication reminder.',
                'Check blood pressure at home 2x/week for monitoring.'
              ],
              'priority': 'high',
            },
            {
              'title': 'Exercise Reminder',
              'bullets': [
                'Consult your doctor before starting new exercises to ensure they\'re safe and appropriate.',
                'Avoid overexertion and listen to your body.'
              ],
              'priority': 'high',
            },
          ]);
          break;
        default:
          recommendations.addAll([
            {
              'title': 'Diet',
              'bullets': [
                'Follow a heart-healthy diet with plenty of fruits, vegetables, and whole grains.',
                'Limit sodium intake to less than 1,500mg per day.',
                'Stay hydrated by drinking 6-8 glasses of water daily.'
              ],
              'priority': 'high',
            },
            {
              'title': 'Exercise',
              'bullets': [
                'Engage in at least 30 minutes of moderate-intensity exercise most days of the week.',
                'Include both aerobic activities and strength training.',
                'Always warm up and cool down properly.'
              ],
              'priority': 'high',
            },
            {
              'title': 'Lifestyle Changes',
              'bullets': [
                'Maintain a regular sleep schedule with 7-9 hours of quality sleep.',
                'Manage stress through relaxation techniques.',
                'Avoid smoking and limit alcohol consumption.'
              ],
              'priority': 'medium',
            },
            {
              'title': 'Medication Adherence',
              'bullets': [
                'Take all prescribed medications as directed.',
                'Use reminders to ensure consistent dosing.',
                'Never stop or change medications without consulting your healthcare provider.'
              ],
              'priority': 'high',
            },
            {
              'title': 'Exercise Reminder',
              'bullets': [
                'Consult your doctor before starting new exercises to ensure they\'re safe and appropriate.',
                'Avoid overexertion and listen to your body.'
              ],
              'priority': 'high',
            },
          ]);
      }
    } else {
      // Recommendations for those not diagnosed with hypertension
      switch (ageGroup) {
        case '20-29':
          recommendations.addAll([
            {
              'title': 'Diet',
              'bullets': [
                'Eat more gulay (kangkong, talbos ng kamote, malunggay, ampalaya) and fruits in daily.'
              ],
              'priority': 'high',
            },
            {
              'title': 'Exercise',
              'bullets': [
                'Jog, brisk walk, or cycle 30 mins, 5 days/week.',
                'Play sports (basketball, badminton, volleyball) for fun and activity.',
                'Stretch 5–10 mins daily.'
              ],
              'priority': 'high',
            },
            {
              'title': 'Lifestyle Changes',
              'bullets': [
                'Sleep 7–9 hrs with consistent schedule.',
                'Avoid smoking, limit alcohol.',
                'Manage stress through breaks, hobbies, or relaxation.'
              ],
              'priority': 'medium',
            },
          ]);
          break;
        case '30-39':
          recommendations.addAll([
            {
              'title': 'Diet',
              'bullets': [
                'Cook with less oil/salt (grilled fish, pinakbet, boiled chicken).',
                'Limit salty condiments (patis, toyo, bagoong).',
                'Drink 6–8 glasses water daily (unless restricted).'
              ],
              'priority': 'high',
            },
            {
              'title': 'Exercise',
              'bullets': [
                'Exercise 150 mins/week (e.g., brisk walk/cycle).',
                'Add resistance training 2x/week (bodyweight, dumbbells).',
                'Stretch or yoga 5–10 mins/day.'
              ],
              'priority': 'high',
            },
            {
              'title': 'Lifestyle Changes',
              'bullets': [
                'Avoid smoking, limit alcohol.',
                'Sleep 7–8 hrs with regular bedtime routine.',
                'Maintain healthy weight (BMI <25).'
              ],
              'priority': 'medium',
            },
          ]);
          break;
        case '40-49':
          recommendations.addAll([
            {
              'title': 'Diet',
              'bullets': [
                'Eat high-fiber meals (brown rice, mongo, vegetables).',
                'Add potassium-rich fruits (saba, melon, papaya).',
                'Drink 6–8 glasses water daily (unless restricted).'
              ],
              'priority': 'high',
            },
            {
              'title': 'Exercise',
              'bullets': [
                'Brisk walk/jog 30 mins daily.',
                'Join community Zumba/aerobics.',
                'Stretch daily 5–10 mins.'
              ],
              'priority': 'high',
            },
            {
              'title': 'Lifestyle Changes',
              'bullets': [
                'Maintain healthy weight.',
                'Manage stress through hobbies, prayer, or relaxation exercises.',
                'Avoid smoking and limit alcohol intake.'
              ],
              'priority': 'medium',
            },
          ]);
          break;
        case '50-59':
          recommendations.addAll([
            {
              'title': 'Diet',
              'bullets': [
                'Eat high-fiber meals (brown rice, mongo, vegetables).',
                'Add potassium-rich fruits (saba, melon, papaya).',
                'Drink 6–8 glasses water daily (unless restricted).'
              ],
              'priority': 'high',
            },
            {
              'title': 'Exercise',
              'bullets': [
                'Do brisk walking, swimming, biking, or Zumba 150 mins/week.',
                'Add light resistance training 2x/week.',
                'Stretch daily 5–10 mins.'
              ],
              'priority': 'high',
            },
            {
              'title': 'Lifestyle Changes',
              'bullets': [
                'Monitor weight/waist monthly.',
                'Avoid smoking, limit alcohol.',
                'Do hobbies or relaxation to lower stress.'
              ],
              'priority': 'medium',
            },
          ]);
          break;
        case '60-69':
          recommendations.addAll([
            {
              'title': 'Diet',
              'bullets': [
                'Eat soft, low-salt meals (lugaw with gulay, tinola).',
                'Ensure protein from fish, eggs, or tofu.',
                'Drink enough fluids unless restricted.'
              ],
              'priority': 'high',
            },
            {
              'title': 'Exercise',
              'bullets': [
                'Brisk walk or light jog 30 mins daily.',
                'Stretch or yoga 5–10 mins/day.',
                'Avoid long sitting; move often.'
              ],
              'priority': 'high',
            },
            {
              'title': 'Lifestyle Changes',
              'bullets': [
                'Maintain an active lifestyle with social activities.',
                'Ensure a safe home environment to prevent falls.',
                'Avoid smoking and limit alcohol intake.'
              ],
              'priority': 'medium',
            },
          ]);
          break;
        case '70-79':
          recommendations.addAll([
            {
              'title': 'Diet',
              'bullets': [
                'Prepare easy-to-chew, low-salt meals (malunggay soup, mashed kalabasa).',
                'Drink enough water unless restricted.',
                'Eat small, frequent meals.'
              ],
              'priority': 'high',
            },
            {
              'title': 'Exercise',
              'bullets': [
                'Light walk 20–30 mins daily.',
                'Do chair/seated exercises 5–10 mins, 3x/week.',
                'Move regularly to prevent stiffness.'
              ],
              'priority': 'high',
            },
            {
              'title': 'Lifestyle Changes',
              'bullets': [
                'Keep home safe (lighting, clutter-free).',
                'Stay socially connected (family, friends, community).',
                'Avoid smoking, limit alcohol.'
              ],
              'priority': 'medium',
            },
          ]);
          break;
        default:
          recommendations.addAll([
            {
              'title': 'Diet',
              'bullets': [
                'Maintain a balanced diet rich in fruits, vegetables, and whole grains.',
                'Limit sodium and added sugars.',
                'Stay hydrated with 6-8 glasses of water daily.'
              ],
              'priority': 'high',
            },
            {
              'title': 'Exercise',
              'bullets': [
                'Aim for at least 150 minutes of moderate-intensity aerobic activity per week.',
                'Include muscle-strengthening activities twice a week.',
                'Add flexibility exercises daily.'
              ],
              'priority': 'high',
            },
            {
              'title': 'Lifestyle Changes',
              'bullets': [
                'Maintain a consistent sleep schedule.',
                'Manage stress through healthy coping mechanisms.',
                'Avoid smoking and limit alcohol consumption.'
              ],
              'priority': 'medium',
            },
          ]);
      }
    }

    return recommendations;
  }

  double _getLatestRiskScore() {
    if (_surveyResponses.isEmpty) return 0;
    return _surveyResponses.first.riskScore;
  }

  // Get all hypertension category scores
  Map<String, double> _getHypertensionCategoryScores() {
    Map<String, double> categoryScores = {
      'Biological and Genetic Factors': 0.0,
      'Socioeconomic & Demographic Factors': 0.0,
      'Lifestyle and Behavioral Factors': 0.0,
      'Dietary and Nutritional Factors': 0.0,
      'Healthcare Access and Management Behaviors': 0.0,
    };

    // Get all survey responses for hypertension categories
    for (final response in _surveyResponses) {
      if ([
        'biological_genetic',
        'socioeconomic_demographic',
        'lifestyle_behavioral',
        'dietary_nutritional',
        'healthcare_management'
      ].contains(response.surveyId)) {
        final categoryName = _getCategoryDisplayName(response.surveyId);
        categoryScores[categoryName] = response.riskScore;
      }
    }

    return categoryScores;
  }

  // Get display name for category ID
  String _getCategoryDisplayName(String categoryId) {
    switch (categoryId) {
      case 'biological_genetic':
        return 'Biological and Genetic Factors';
      case 'socioeconomic_demographic':
        return 'Socioeconomic & Demographic Factors';
      case 'lifestyle_behavioral':
        return 'Lifestyle and Behavioral Factors';
      case 'dietary_nutritional':
        return 'Dietary and Nutritional Factors';
      case 'healthcare_management':
        return 'Healthcare Access and Management Behaviors';
      default:
        return categoryId;
    }
  }

  // Get risk level for a specific score
  String _getRiskLevel(double score) {
    // For hypertension surveys, use the correct scoring system
    if (score >= 13) return 'High';
    if (score >= 7) return 'Moderate';
    return 'Low';
  }

  // Get risk description for a specific score
  String _getRiskDescription(double score) {
    // For hypertension surveys, use the new scoring system
    if (score >= 13)
      return '● You\'ve taken a crucial first step by assessing your risk. Your HIGH score signals the need for action.\n● Schedule a check-up, reduce sodium and processed foods, stay physically active, and follow your provider\'s advice to protect your heart health.';
    if (score >= 7)
      return '● Great effort! Your score shows a MODERATE risk for hypertension, meaning now is the perfect time to strengthen your routine.\n● Add more fruits and vegetables, stay active most days, and monitor your blood pressure regularly to lower your risk.';
    return '● Excellent work! Your blood pressure risk is LOW, showing that your healthy eating, regular activity, and mindful stress management are paying off.\n● Keep reinforcing these habits to stay protected.';
  }

  // Get overall risk level based on average of all categories
  String _getOverallRiskLevel() {
    final categoryScores = _getHypertensionCategoryScores();
    final totalScore = categoryScores.values.reduce((a, b) => a + b);
    final averageScore = totalScore / categoryScores.length;
    return _getRiskLevel(averageScore);
  }

  // Get overall risk description based on average of all categories
  String _getOverallRiskDescription() {
    final categoryScores = _getHypertensionCategoryScores();
    final totalScore = categoryScores.values.reduce((a, b) => a + b);
    final averageScore = totalScore / categoryScores.length;
    return _getRiskDescription(averageScore);
  }

  // Show dialog for export options
  void _showExportOptionsDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: grey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextWidget(
                text: 'Export Health Report',
                fontSize: 20,
                color: textPrimary,
                fontFamily: 'Bold',
              ),
              const SizedBox(height: 8),
              TextWidget(
                text: 'Choose a format to export your health report',
                fontSize: 14,
                color: textLight,
              ),
              const SizedBox(height: 24),
              _buildExportOption(
                Icons.picture_as_pdf,
                'PDF Document',
                'Detailed report with charts and recommendations',
                () => _exportReport('PDF'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // Build an export option card
  Widget _buildExportOption(
      IconData icon, String title, String description, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text: title,
                      fontSize: 16,
                      color: textPrimary,
                      fontFamily: 'Bold',
                    ),
                    const SizedBox(height: 4),
                    TextWidget(
                      text: description,
                      fontSize: 13,
                      color: textLight,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: textLight),
            ],
          ),
        ),
      ),
    );
  }

  // Export the health report as PDF
  void _exportReport(String format) async {
    Navigator.of(context).pop(); // Close the bottom sheet

    // Request storage permission
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      Fluttertoast.showToast(
        msg: 'Storage permission is required to export reports',
        backgroundColor: healthRed,
        textColor: Colors.white,
      );
      return;
    }

    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: primary),
              const SizedBox(height: 20),
              TextWidget(
                text: 'Generating $format Report...',
                fontSize: 16,
                color: textPrimary,
                fontFamily: 'Bold',
              ),
              const SizedBox(height: 8),
              TextWidget(
                text: 'Please wait while we prepare your health report',
                fontSize: 14,
                color: textLight,
              ),
            ],
          ),
        );
      },
    );

    try {
      final pdf = pw.Document();

      // Add content to PDF
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text(
                    'Health Risk Assessment Report',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Generated on: ${DateTime.now().toString().split(' ')[0]}',
                  style: const pw.TextStyle(fontSize: 14),
                ),
                pw.SizedBox(height: 20),

                // Add category-based assessment scores
                pw.Text(
                  'Hypertension Risk Assessment by Category',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),

                // Get category scores
                ..._getHypertensionCategoryScores().entries.map((entry) {
                  final categoryName = entry.key;
                  final score = entry.value;
                  final percentage = (score / 20.0) * 100;
                  final riskLevel = _getRiskLevel(score);
                  final riskDescription = _getRiskDescription(score);

                  return pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 10),
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.black),
                      borderRadius: pw.BorderRadius.circular(5),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          children: [
                            pw.Expanded(
                              child: pw.Text(
                                categoryName,
                                style: pw.TextStyle(
                                  fontSize: 16,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: pw.BoxDecoration(
                                color: riskLevel == 'High'
                                    ? PdfColors.red
                                    : riskLevel == 'Moderate'
                                        ? PdfColors.orange
                                        : PdfColors.green,
                                borderRadius: pw.BorderRadius.circular(3),
                              ),
                              child: pw.Text(
                                riskLevel,
                                style: pw.TextStyle(
                                  color: PdfColors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          'Score: ${percentage.toStringAsFixed(0)}% (${score.toStringAsFixed(1)}/20)',
                          style: const pw.TextStyle(fontSize: 14),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          riskDescription,
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }).toList(),

                pw.SizedBox(height: 20),
                pw.Text(
                  'Personalized Recommendations',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                ..._recommendations.map(
                  (rec) => pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 10),
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.black),
                      borderRadius: pw.BorderRadius.circular(5),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          children: [
                            pw.Container(
                              padding: const pw.EdgeInsets.all(4),
                              decoration: pw.BoxDecoration(
                                color: rec['priority'] == 'high'
                                    ? PdfColors.red100
                                    : PdfColors.orange100,
                                borderRadius: pw.BorderRadius.circular(3),
                              ),
                              child: pw.Text(
                                rec['priority'] == 'high' ? 'HIGH' : 'MEDIUM',
                                style: pw.TextStyle(
                                  color: rec['priority'] == 'high'
                                      ? PdfColors.red
                                      : PdfColors.orange,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            pw.SizedBox(width: 10),
                            // Add icon representation in PDF
                            pw.Container(
                              width: 12,
                              height: 12,
                              decoration: pw.BoxDecoration(
                                color: rec['priority'] == 'high'
                                    ? PdfColors.red
                                    : PdfColors.orange,
                                shape: pw.BoxShape.circle,
                              ),
                            ),
                            pw.SizedBox(width: 5),
                            pw.Expanded(
                              child: pw.Text(
                                rec['title'],
                                style: pw.TextStyle(
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 5),
                        // Check if recommendation has bullets
                        if (rec.containsKey('bullets'))
                          ...((rec['bullets'] as List<String>)
                              .map((bullet) => pw.Padding(
                                    padding:
                                        const pw.EdgeInsets.only(bottom: 4),
                                    child: pw.Row(
                                      crossAxisAlignment:
                                          pw.CrossAxisAlignment.start,
                                      children: [
                                        pw.Container(
                                          margin: const pw.EdgeInsets.only(
                                              top: 5, right: 6),
                                          width: 4,
                                          height: 4,
                                          decoration: pw.BoxDecoration(
                                            color: rec['priority'] == 'high'
                                                ? PdfColors.red
                                                : PdfColors.orange,
                                            shape: pw.BoxShape.circle,
                                          ),
                                        ),
                                        pw.Expanded(
                                          child: pw.Text(
                                            bullet,
                                            style: const pw.TextStyle(
                                                fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList())
                        else
                          // Fallback to description if bullets are not available
                          pw.Text(
                            rec['description'],
                            style: const pw.TextStyle(fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Save PDF to device
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/health_report.pdf');
      await file.writeAsBytes(await pdf.save());

      // Close progress dialog
      if (mounted) {
        Navigator.of(context).pop();

        // Show success message
        Fluttertoast.showToast(
          msg: 'Health report exported successfully to ${file.path}',
          backgroundColor: healthGreen,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      // Close progress dialog
      if (mounted) {
        Navigator.of(context).pop();

        // Show detailed error message
        String errorMessage = 'Failed to export health report';
        if (e is FileSystemException) {
          errorMessage =
              'Storage permission denied. Please check app permissions.';
        } else if (e is Exception) {
          errorMessage = 'Export failed: ${e.toString()}';
        }

        // Show error message
        Fluttertoast.showToast(
          msg: errorMessage,
          backgroundColor: healthRed,
          textColor: Colors.white,
        );

        // Also log to console for debugging
        print('Export error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primary))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextWidget(
                  text: 'Risk Assessment',
                  fontSize: 20,
                  color: textPrimary,
                  fontFamily: 'Bold',
                ),
                const SizedBox(height: 16),
                // Individual Category Scores
                _buildCategoryScoresCards(),
                const SizedBox(height: 24),
                // Add the hypertension result image section
                _buildHypertensionResultImage(),
                const SizedBox(height: 24),
                TextWidget(
                  text: 'Personalized Recommendations',
                  fontSize: 20,
                  color: textPrimary,
                  fontFamily: 'Bold',
                ),
                const SizedBox(height: 16),

                // Check if a recommendation is selected
                if (_selectedRecommendationIndex != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back button
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedRecommendationIndex = null;
                          });
                        },
                        icon: const Icon(Icons.arrow_back, color: primary),
                        label: TextWidget(
                          text: 'Back to Recommendations',
                          fontSize: 14,
                          color: primary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Selected recommendation details
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: _recommendations[
                                                      _selectedRecommendationIndex!]
                                                  ['priority'] ==
                                              'high'
                                          ? healthRed.withOpacity(0.1)
                                          : accent.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      _getCategoryIcon(_recommendations[
                                              _selectedRecommendationIndex!]
                                          ['title']),
                                      size: 20,
                                      color: _recommendations[
                                                      _selectedRecommendationIndex!]
                                                  ['priority'] ==
                                              'high'
                                          ? healthRed
                                          : accent,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextWidget(
                                      text: _recommendations[
                                              _selectedRecommendationIndex!]
                                          ['title'],
                                      fontSize: 16,
                                      color: textPrimary,
                                      fontFamily: 'Bold',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Recommendation bullets
                              if (_recommendations[
                                      _selectedRecommendationIndex!]
                                  .containsKey('bullets'))
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: (_recommendations[
                                              _selectedRecommendationIndex!]
                                          ['bullets'] as List<String>)
                                      .map((bullet) => Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 8),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  margin: const EdgeInsets.only(
                                                      top: 6, right: 8),
                                                  width: 6,
                                                  height: 6,
                                                  decoration: BoxDecoration(
                                                    color: _recommendations[
                                                                    _selectedRecommendationIndex!]
                                                                ['priority'] ==
                                                            'high'
                                                        ? healthRed
                                                        : accent,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: TextWidget(
                                                    text: bullet,
                                                    fontSize: 14,
                                                    color: textPrimary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ))
                                      .toList(),
                                )
                              else
                                // Fallback to description if bullets are not available
                                TextWidget(
                                  text: _recommendations[
                                          _selectedRecommendationIndex!]
                                      ['description'],
                                  fontSize: 14,
                                  color: textPrimary,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  // Grid view of recommendation cards
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: _recommendations.length,
                    itemBuilder: (context, index) {
                      final recommendation = _recommendations[index];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedRecommendationIndex = index;
                          });
                        },
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: recommendation['priority'] == 'high'
                                        ? healthRed.withOpacity(0.1)
                                        : accent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _getCategoryIcon(recommendation['title']),
                                    size: 24,
                                    color: recommendation['priority'] == 'high'
                                        ? healthRed
                                        : accent,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextWidget(
                                  text: recommendation['title'],
                                  fontSize: 14,
                                  color: textPrimary,
                                  fontFamily: 'Bold',
                                  align: TextAlign.center,
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 30),

                Center(
                  child: ButtonWidget(
                    label: 'Export Health Report',
                    onPressed: _showExportOptionsDialog,
                    icon: const Icon(Icons.download, color: Colors.white),
                  ),
                ),
              ],
            ),
    );
  }

  // Helper method to build the hypertension result image section
  Widget _buildHypertensionResultImage() {
    if (_surveyResponses.isEmpty) {
      return const SizedBox.shrink();
    }

    // Find the hypertension survey response or use the first response with age data
    SurveyResponse? responseWithAge;
    for (final response in _surveyResponses) {
      if (response.surveyId == 'hypertension' ||
          response.answers.containsKey('age')) {
        responseWithAge = response;
        break;
      }
    }

    if (responseWithAge == null) {
      return const SizedBox.shrink();
    }

    // Get age from the survey response
    final age = responseWithAge.answers['age'];
    if (age == null) {
      return const SizedBox.shrink();
    }

    // Determine age group
    final ageGroup = _getAgeGroup(age);

    // Determine if user has hypertension based on risk score and new thresholds
    // Use the hypertension survey score if available, otherwise use the overall risk
    double riskScore;
    if (responseWithAge.surveyId == 'hypertension') {
      riskScore = responseWithAge.riskScore;
    } else {
      riskScore = _getLatestRiskScore();
    }

    final hasHypertension =
        riskScore >= 13; // Using 13 as threshold for high risk in new system

    // Construct image path based on actual filenames in the assets folders
    String imagePath;
    if (hasHypertension) {
      // For "With Hypertension" folder, all files end with "with HPN.png"
      imagePath = 'assets/images/With Hypertension/$ageGroup with HPN.png';
    } else {
      // For "Without Hypertension" folder, most files end with "without HPN.png"
      // but 40-49 y.o. ends with "wo HPN.png"
      if (ageGroup == '40-49 y.o.') {
        imagePath = 'assets/images/Without Hypertension/40-49 wo HPN.png';
      } else {
        imagePath =
            'assets/images/Without Hypertension/${ageGroup.split(' ')[0]} without HPN.png';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextWidget(
          text: 'Your Hypertension Risk Visualization',
          fontSize: 20,
          color: textPrimary,
          fontFamily: 'Bold',
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 16),
                TextWidget(
                  text: hasHypertension
                      ? 'Based on your assessment, you are at risk for hypertension.'
                      : 'Based on your assessment, you are not at risk for hypertension.',
                  fontSize: 14,
                  color: textPrimary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to determine age group
  String _getAgeGroup(dynamic age) {
    int ageValue;

    if (age is String) {
      ageValue = int.tryParse(age) ?? 0;
    } else if (age is int) {
      ageValue = age;
    } else if (age is double) {
      ageValue = age.toInt();
    } else {
      ageValue = 0;
    }

    if (ageValue >= 20 && ageValue <= 29) {
      return '20-29 y.o.';
    } else if (ageValue >= 30 && ageValue <= 39) {
      return '30-39 y.o.';
    } else if (ageValue >= 40 && ageValue <= 49) {
      return '40-49 y.o.';
    } else if (ageValue >= 50 && ageValue <= 59) {
      return '50-59 y.o.';
    } else if (ageValue >= 60 && ageValue <= 69) {
      return '60-69 y.o.';
    } else if (ageValue >= 70 && ageValue <= 79) {
      return '70-79 y.o.';
    } else {
      // Default to a safe age group
      return '30-39 y.o.';
    }
  }

  // Helper method to get the appropriate icon for each category
  IconData _getCategoryIcon(String title) {
    switch (title) {
      case 'Diet':
        return Icons.restaurant;
      case 'Exercise':
        return Icons.fitness_center;
      case 'Lifestyle Changes':
        return Icons.psychology;
      case 'Medication Adherence':
        return Icons.medication;
      case 'Exercise Reminder':
        return Icons.timer;
      default:
        return Icons.info;
    }
  }

  // Build category score cards
  Widget _buildCategoryScoresCards() {
    final categoryScores = _getHypertensionCategoryScores();

    return Column(
      children: categoryScores.entries.map((entry) {
        final categoryName = entry.key;
        final score = entry.value;
        final riskLevel = _getRiskLevel(score);
        final riskDescription = _getRiskDescription(score);

        // Check if score is 0 (survey not taken)
        if (score == 0) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextWidget(
                    text:
                        '● Answer the ${categoryName.split(' ')[0]} Survey to get your Risk Score.',
                    fontSize: 16,
                    color: textPrimary,
                  ),
                ],
              ),
            ),
          );
        }

        // Calculate percentage (score out of 20)
        final percentage = (score / 20.0) * 100;

        // Use the same UI as RiskAssessmentCard for each category
        // but modify the description to include the percentage
        return RiskAssessmentCard(
          riskScore: percentage, // Pass percentage instead of raw score
          riskLevel: riskLevel,
          description: riskDescription,
          title: categoryName, // Pass category name as title
        );
      }).toList(),
    );
  }

  // Get risk color based on score
  Color _getRiskColor(double score) {
    if (score >= 13) return healthRed;
    if (score >= 7) return Colors.orange;
    return healthGreen;
  }
}

class TrendChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;

  TrendChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Define colors for each category
    final categoryColors = {
      'Biological and Genetic Factors': Colors.red,
      'Socioeconomic & Demographic Factors': Colors.green,
      'Lifestyle and Behavioral Factors': Colors.blue,
      'Dietary and Nutritional Factors': Colors.orange,
      'Healthcare Access and Management Behaviors': Colors.purple,
    };

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    final double chartWidth = size.width - 40;
    final double chartHeight = size.height - 60; // Extra space for legend
    final double pointSpacing =
        data.length > 1 ? chartWidth / (data.length - 1) : 0;

    // Find min and max values for scaling
    int minVal = 0;
    int maxVal = 20; // Maximum score per category

    // Draw grid lines
    final gridPaint = Paint()
      ..color = grey
      ..strokeWidth = 0.5;

    // Draw horizontal grid lines
    for (int i = 0; i <= 4; i++) {
      final double y = 20 + (chartHeight / 4) * i;
      canvas.drawLine(Offset(20, y), Offset(size.width - 20, y), gridPaint);

      // Draw labels
      final label = ((maxVal - (i * (maxVal - minVal) ~/ 4))).toString();
      textPainter.text = TextSpan(
        text: label,
        style: const TextStyle(color: Colors.grey, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - 6));
    }

    // Draw data points and lines for each category
    for (final category in categoryColors.keys) {
      final categoryPaint = paint..color = categoryColors[category]!;
      Path categoryPath = Path();

      for (int i = 0; i < data.length; i++) {
        final double x = 20 + i * pointSpacing;
        final score = data[i][category] ?? 0;
        final double y = 20 +
            chartHeight -
            ((score - minVal) / (maxVal - minVal)) * chartHeight;

        if (i == 0) {
          categoryPath.moveTo(x, y);
        } else {
          categoryPath.lineTo(x, y);
        }

        // Draw point
        canvas.drawCircle(
            Offset(x, y), 3, categoryPaint..style = PaintingStyle.fill);
      }
      canvas.drawPath(
          categoryPath, categoryPaint..style = PaintingStyle.stroke);
    }

    // Draw labels for months
    for (int i = 0; i < data.length; i++) {
      final double x = 20 + i * pointSpacing;
      textPainter.text = TextSpan(
        text: data[i]['month'],
        style: const TextStyle(color: Colors.grey, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(
          canvas, Offset(x - textPainter.width / 2, size.height - 40));
    }

    // Draw Y-axis label
    final yLabelPainter = TextPainter(
      text: const TextSpan(
        text: 'Risk Score',
        style: TextStyle(color: Colors.grey, fontSize: 12),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    yLabelPainter.layout();
    yLabelPainter.paint(canvas, const Offset(0, 0));

    // Draw legend
    double legendX = 20;
    double legendY = size.height - 30;

    for (final category in categoryColors.keys) {
      // Draw color indicator
      canvas.drawCircle(Offset(legendX, legendY), 4,
          Paint()..color = categoryColors[category]!);

      // Draw category name (abbreviated for space)
      String abbreviatedName = category.split(' ')[0];
      if (abbreviatedName.length > 8) {
        abbreviatedName = abbreviatedName.substring(0, 8);
      }

      textPainter.text = TextSpan(
        text: abbreviatedName,
        style: const TextStyle(color: Colors.grey, fontSize: 9),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(legendX + 8, legendY - 5));

      legendX += textPainter.width + 20;

      // Move to next line if needed
      if (legendX > size.width - 100) {
        legendX = 20;
        legendY += 15;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
