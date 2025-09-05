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
  const AnalysisScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    _loadSurveyData();
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

    // Take the last 6 responses for the trend chart
    final recentResponses =
        responses.length > 6 ? responses.sublist(0, 6) : responses;

    for (int i = 0; i < recentResponses.length; i++) {
      final response = recentResponses[i];
      final month = _getMonthAbbreviation(response.submittedAt.month);

      trendData.add({
        'month': month,
        'score': response.riskScore.toInt(),
      });
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
    if (responses.isEmpty) {
      return [
        {
          'title': 'Complete a Survey',
          'description':
              'Take the hypertension risk assessment survey to get personalized recommendations. This will help us understand your specific risk factors and provide targeted advice for improving your health. Completing the survey is the first step toward better health management.',
          'priority': 'high',
        },
      ];
    }

    final latestResponse = responses.first;
    final riskScore = latestResponse.riskScore;
    final answers = latestResponse.answers;

    List<Map<String, dynamic>> recommendations = [];

    if (riskScore >= 70) {
      recommendations.addAll([
        {
          'title': 'Immediate Medical Attention',
          'description':
              'Your risk score is very high. Consult with a healthcare professional immediately. Early intervention can significantly improve your health outcomes and prevent complications. Do not delay in seeking professional medical advice.',
          'priority': 'high',
        },
        {
          'title': 'Medication Compliance',
          'description':
              'If prescribed medication, ensure you take it as directed. Do not stop or change your dosage without consulting your doctor. Consistent medication use is crucial for managing your condition effectively. Proper adherence can significantly improve your health outcomes.',
          'priority': 'high',
        },
      ]);
    } else if (riskScore >= 50) {
      recommendations.addAll([
        {
          'title': 'Medical Consultation',
          'description':
              'Your risk score is high. Schedule an appointment with your doctor. Professional medical guidance will help you develop a comprehensive plan to address your risk factors and improve your health. Early consultation can prevent further complications.',
          'priority': 'high',
        },
      ]);
    } else if (riskScore >= 30) {
      recommendations.addAll([
        {
          'title': 'Lifestyle Changes',
          'description':
              'Your risk score is elevated. Implement lifestyle modifications to reduce your risk. Small changes can make a significant difference in your overall health and well-being. Focus on diet, exercise, and stress management for the best results.',
          'priority': 'medium',
        },
      ]);
    }

    // Add personalized recommendations based on survey answers
    if (latestResponse.surveyId == 'hypertension') {
      // Smoking recommendation
      if (answers['smoking'] == true) {
        recommendations.add({
          'title': 'Quit Smoking',
          'description':
              'Smoking significantly increases your hypertension risk. Consider smoking cessation programs or nicotine replacement therapy. Quitting smoking can improve your blood pressure and overall cardiovascular health within just a few weeks.',
          'priority': 'high',
        });
      }

      // Family history recommendation
      if (answers['family_history'] == true) {
        recommendations.add({
          'title': 'Regular Health Screenings',
          'description':
              'With a family history of hypertension, regular monitoring is crucial. Schedule check-ups every 3-6 months. Early detection of changes in your blood pressure can help prevent serious complications.',
          'priority': 'high',
        });
      }

      // Stress management recommendation
      final stressLevel = answers['stress_level'];
      if (stressLevel is num && stressLevel >= 7) {
        recommendations.add({
          'title': 'Stress Reduction Techniques',
          'description':
              'Your high stress level contributes to hypertension risk. Try mindfulness, yoga, or counseling. Managing stress through relaxation techniques can have a positive impact on your blood pressure and overall well-being.',
          'priority': 'medium',
        });
      }

      // Exercise recommendation
      final exerciseFreq = answers['exercise_frequency'];
      if (exerciseFreq == 'Never' || exerciseFreq == 'Rarely') {
        recommendations.add({
          'title': 'Increase Physical Activity',
          'description':
              'Regular exercise helps lower blood pressure. Start with 10-15 minutes of walking daily. Gradually increase your activity level as your fitness improves to maximize cardiovascular benefits.',
          'priority': 'high',
        });
      }

      // Medication recommendation
      if (answers['medications'] == true) {
        recommendations.add({
          'title': 'Medication Adherence',
          'description':
              'Continue taking your blood pressure medications as prescribed. Never stop without consulting your doctor. Proper medication management is essential for controlling hypertension and preventing complications.',
          'priority': 'high',
        });
      }

      // Conditions recommendation
      final conditions = answers['conditions'];
      if (conditions is List &&
          conditions.isNotEmpty &&
          !conditions.contains('None')) {
        recommendations.add({
          'title': 'Comprehensive Health Management',
          'description':
              'Managing co-existing conditions like diabetes or heart disease is important for overall cardiovascular health. Work with your healthcare team to coordinate care for all your conditions. Proper management can reduce the risk of complications.',
          'priority': 'high',
        });
      }

      // Additional hypertension recommendations
      recommendations.addAll([
        {
          'title': 'Reduce Sodium Intake',
          'description':
              'Limit sodium to less than 1,500mg per day. Avoid processed foods and use herbs and spices for flavoring instead of salt. Reducing sodium intake can significantly lower your blood pressure and reduce strain on your heart.',
          'priority': 'high',
        },
        {
          'title': 'Increase Potassium-Rich Foods',
          'description':
              'Include foods like bananas, oranges, spinach, and sweet potatoes which can help counteract sodium\'s effects on blood pressure. Potassium helps your body eliminate excess sodium and ease tension in blood vessel walls.',
          'priority': 'medium',
        },
        {
          'title': 'Limit Caffeine',
          'description':
              'Caffeine can temporarily raise blood pressure. Monitor your intake and consider reducing consumption if sensitive. Try switching to decaffeinated beverages or herbal teas to reduce your overall caffeine consumption.',
          'priority': 'medium',
        },
        {
          'title': 'Mindful Eating',
          'description':
              'Practice portion control and eat slowly. Overeating can temporarily raise blood pressure. Pay attention to hunger and fullness cues to maintain a healthy weight and support cardiovascular health.',
          'priority': 'medium',
        },
      ]);
    } else if (latestResponse.surveyId == 'diabetes') {
      // High blood pressure recommendation for diabetes patients
      if (answers['diabetes_high_bp'] == true) {
        recommendations.add({
          'title': 'Blood Pressure Management',
          'description':
              'Managing both diabetes and hypertension is crucial. Monitor both regularly. Controlling both conditions together can significantly reduce your risk of heart disease, stroke, and kidney problems.',
          'priority': 'high',
        });
      }

      // Diet recommendation for diabetes patients
      final diet = answers['diabetes_diet'];
      if (diet == 'Poor' || diet == 'Fair') {
        recommendations.add({
          'title': 'Improve Dietary Habits',
          'description':
              'A healthy diet is essential for diabetes management. Focus on whole grains, lean proteins, and vegetables. Work with a dietitian to create a meal plan that helps control your blood sugar and supports overall health.',
          'priority': 'high',
        });
      }

      // Physical activity recommendation for diabetes patients
      final activity = answers['diabetes_physical_activity'];
      if (activity == 'Never' || activity == 'Rarely') {
        recommendations.add({
          'title': 'Increase Physical Activity',
          'description':
              'Regular exercise helps manage blood sugar levels. Aim for at least 150 minutes of moderate activity per week. Physical activity increases insulin sensitivity and helps your muscles use glucose for energy.',
          'priority': 'high',
        });
      }

      // Smoking recommendation for diabetes patients
      if (answers['diabetes_smoking'] == true) {
        recommendations.add({
          'title': 'Quit Smoking',
          'description':
              'Smoking increases complications in diabetes patients. Seek support to quit smoking. Quitting can improve circulation, reduce inflammation, and lower your risk of diabetes-related complications.',
          'priority': 'high',
        });
      }

      // Additional diabetes recommendations
      recommendations.addAll([
        {
          'title': 'Monitor Blood Sugar Levels',
          'description':
              'Check your blood glucose regularly as recommended by your healthcare provider. Keep a log of your readings. Monitoring helps you understand how food, activity, and medication affect your blood sugar levels.',
          'priority': 'high',
        },
        {
          'title': 'Foot Care',
          'description':
              'Inspect your feet daily for cuts, sores, or swelling. Proper foot care can prevent serious complications. Diabetes can reduce blood flow to your feet and cause nerve damage, making foot problems more likely.',
          'priority': 'medium',
        },
        {
          'title': 'Stay Hydrated',
          'description':
              'Drink plenty of water to help your kidneys flush out excess glucose through urine. Proper hydration supports all bodily functions and helps maintain stable blood sugar levels throughout the day.',
          'priority': 'low',
        },
        {
          'title': 'Regular Eye Exams',
          'description':
              'Diabetes can affect your eyes. Schedule annual eye exams to detect and treat problems early. Diabetic retinopathy can lead to vision loss if not caught and treated early.',
          'priority': 'medium',
        },
      ]);
    } else if (latestResponse.surveyId == 'heart_disease') {
      // Chest pain recommendation
      if (answers['heart_chest_pain'] == true) {
        recommendations.add({
          'title': 'Chest Pain Monitoring',
          'description':
              'Report any chest pain immediately to your healthcare provider. Chest pain can be a sign of a heart problem that needs immediate attention. Do not ignore or delay seeking medical care for chest discomfort.',
          'priority': 'high',
        });
      }

      // Diabetes recommendation for heart disease patients
      if (answers['heart_diabetes'] == true) {
        recommendations.add({
          'title': 'Diabetes Management',
          'description':
              'Managing diabetes is crucial for heart health. Monitor blood sugar levels regularly. Keeping blood sugar under control can reduce the risk of further heart complications and improve overall cardiovascular health.',
          'priority': 'high',
        });
      }

      // Smoking recommendation for heart disease patients
      if (answers['heart_smoking'] == true) {
        recommendations.add({
          'title': 'Quit Smoking',
          'description':
              'Smoking is a major risk factor for heart disease. Seek immediate help to quit smoking. Quitting smoking is one of the most important steps you can take to improve your heart health and prevent future cardiac events.',
          'priority': 'high',
        });
      }

      // High blood pressure recommendation for heart disease patients
      if (answers['heart_high_bp'] == true) {
        recommendations.add({
          'title': 'Blood Pressure Control',
          'description':
              'Controlling blood pressure is essential for heart health. Monitor regularly and follow medical advice. Proper blood pressure management can reduce the workload on your heart and prevent further damage.',
          'priority': 'high',
        });
      }

      // Additional heart disease recommendations
      recommendations.addAll([
        {
          'title': 'Healthy Fats',
          'description':
              'Include omega-3 fatty acids from fish like salmon and mackerel. Avoid trans fats and limit saturated fats. Healthy fats can help reduce inflammation and lower your risk of heart disease while providing essential nutrients.',
          'priority': 'high',
        },
        {
          'title': 'Manage Cholesterol',
          'description':
              'Keep your cholesterol levels in check through diet, exercise, and medication if prescribed. High cholesterol can lead to plaque buildup in your arteries, increasing the risk of heart attack and stroke.',
          'priority': 'high',
        },
        {
          'title': 'Know Your Numbers',
          'description':
              'Regularly monitor blood pressure, cholesterol, and blood sugar. Understanding these numbers helps manage heart health. Keep track of your health metrics and discuss them with your healthcare provider regularly.',
          'priority': 'medium',
        },
        {
          'title': 'Get Quality Sleep',
          'description':
              'Aim for 7-9 hours of sleep per night. Poor sleep is linked to higher risk of heart disease. Good sleep helps regulate stress hormones and blood pressure, supporting cardiovascular health.',
          'priority': 'medium',
        },
      ]);
    }

    // Add general recommendations
    recommendations.addAll([
      {
        'title': 'Dietary Changes',
        'description':
            'Reduce sodium intake to less than 2,300mg per day. Focus on fresh fruits, vegetables, whole grains, and lean proteins. A heart-healthy diet can help manage weight, blood pressure, and cholesterol levels.',
        'priority': 'high',
      },
      {
        'title': 'Regular Exercise',
        'description':
            'Engage in 30 minutes of moderate exercise 5 days a week. Activities like brisk walking, swimming, or cycling can strengthen your heart and improve circulation. Start slowly and gradually increase intensity as your fitness improves.',
        'priority': 'high',
      },
      {
        'title': 'Stress Management',
        'description':
            'Practice relaxation techniques like meditation or deep breathing. Chronic stress can contribute to high blood pressure and other heart problems. Find healthy ways to manage stress such as hobbies, socializing, or relaxation exercises.',
        'priority': 'medium',
      },
      {
        'title': 'Regular Monitoring',
        'description':
            'Check your blood pressure at least once a week. Regular monitoring helps track progress and identify any concerning changes early. Keep a log of your readings to share with your healthcare provider.',
        'priority': 'high',
      },
      {
        'title': 'Adequate Sleep',
        'description':
            'Aim for 7-9 hours of quality sleep each night. Sleep is essential for heart health and overall well-being. Poor sleep can negatively affect blood pressure, weight, and stress hormone levels.',
        'priority': 'medium',
      },
      // Additional general recommendations
      {
        'title': 'Limit Alcohol Consumption',
        'description':
            'Excessive alcohol can raise blood pressure. Limit to moderate amounts (up to one drink per day for women, two for men). If you choose to drink, do so in moderation and be aware of how alcohol affects your health.',
        'priority': 'medium',
      },
      {
        'title': 'Maintain a Healthy Weight',
        'description':
            'Achieving and maintaining a healthy weight can significantly reduce hypertension risk. Even a small weight loss can have positive effects on blood pressure and overall health. Focus on gradual, sustainable changes to your diet and activity level.',
        'priority': 'high',
      },
      {
        'title': 'Stay Hydrated',
        'description':
            'Drink plenty of water throughout the day to support cardiovascular health. Proper hydration helps maintain blood volume and supports heart function. Limit sugary drinks and excessive caffeine which can negatively impact heart health.',
        'priority': 'low',
      },
    ]);

    return recommendations;
  }

  double _getLatestRiskScore() {
    if (_surveyResponses.isEmpty) return 0;
    return _surveyResponses.first.riskScore;
  }

  String _getRiskLevel(double score) {
    if (score >= 70) return 'High';
    if (score >= 50) return 'Moderate';
    if (score >= 30) return 'Elevated';
    return 'Low';
  }

  String _getRiskDescription(double score) {
    if (score >= 70)
      return 'Your hypertension risk is high. Immediate action is recommended.';
    if (score >= 50)
      return 'Your hypertension risk is moderate. Medical consultation is advised.';
    if (score >= 30)
      return 'Your hypertension risk is elevated. Follow the recommendations to reduce your risk.';
    return 'Your hypertension risk is low. Continue maintaining healthy habits.';
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
                pw.Text(
                  'Risk Assessment Summary',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black),
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Latest Risk Score: ${_getLatestRiskScore().toStringAsFixed(1)}',
                        style: const pw.TextStyle(fontSize: 16),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Risk Level: ${_getRiskLevel(_getLatestRiskScore())}',
                        style: const pw.TextStyle(fontSize: 16),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        _getRiskDescription(_getLatestRiskScore()),
                        style: const pw.TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Recommendations',
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
                RiskAssessmentCard(
                  riskScore: _getLatestRiskScore(),
                  riskLevel: _getRiskLevel(_getLatestRiskScore()),
                  description: _getRiskDescription(_getLatestRiskScore()),
                ),
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
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recommendations.length,
                  itemBuilder: (context, index) {
                    final recommendation = _recommendations[index];
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
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: recommendation['priority'] == 'high'
                                        ? healthRed.withOpacity(0.1)
                                        : accent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    recommendation['priority'] == 'high'
                                        ? Icons.warning_amber
                                        : Icons.info,
                                    size: 20,
                                    color: recommendation['priority'] == 'high'
                                        ? healthRed
                                        : accent,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextWidget(
                                    text: recommendation['title'],
                                    fontSize: 16,
                                    color: textPrimary,
                                    fontFamily: 'Bold',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextWidget(
                              text: recommendation['description'],
                              fontSize: 14,
                              color: textPrimary,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                TextWidget(
                  text: 'Health Trend',
                  fontSize: 20,
                  color: textPrimary,
                  fontFamily: 'Bold',
                ),
                const SizedBox(height: 16),
                Container(
                  height: 200,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: grey),
                  ),
                  child: _trendData.isEmpty
                      ? Center(
                          child: TextWidget(
                            text: 'No data available',
                            fontSize: 16,
                            color: textLight,
                          ),
                        )
                      : CustomPaint(
                          painter: TrendChartPainter(_trendData),
                          size: const Size(double.infinity, 200),
                        ),
                ),
                const SizedBox(height: 24),
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

    final latestResponse = _surveyResponses.first;

    // Check if this is a hypertension survey
    if (latestResponse.surveyId != 'hypertension') {
      return const SizedBox.shrink();
    }

    // Get age from the survey response
    final age = latestResponse.answers['age'];
    if (age == null) {
      return const SizedBox.shrink();
    }

    // Determine age group
    final ageGroup = _getAgeGroup(age);

    // Determine if user has hypertension based on risk score
    final hasHypertension = _getLatestRiskScore() >=
        30; // Using 30 as threshold for hypertension risk

    // Construct image path
    final imagePath = hasHypertension
        ? 'assets/images/With Hypertension/$ageGroup with HPN.png'
        : 'assets/images/Without Hypertension/$ageGroup without HPN.png';

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

    final trendPaint = paint..color = primary;

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    final double chartWidth = size.width - 40;
    final double chartHeight = size.height - 40;
    final double pointSpacing =
        data.length > 1 ? chartWidth / (data.length - 1) : 0;

    // Find min and max values for scaling
    int minVal = 0;
    int maxVal = 100;

    // Draw grid lines
    final gridPaint = Paint()
      ..color = grey
      ..strokeWidth = 0.5;

    // Draw horizontal grid lines
    for (int i = 0; i <= 5; i++) {
      final double y = 20 + (chartHeight / 5) * i;
      canvas.drawLine(Offset(20, y), Offset(size.width - 20, y), gridPaint);

      // Draw labels
      final label = ((maxVal - (i * (maxVal - minVal) ~/ 5))).toString();
      textPainter.text = TextSpan(
        text: label,
        style: const TextStyle(color: Colors.grey, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - 6));
    }

    // Draw data points and lines
    if (data.isNotEmpty) {
      Path trendPath = Path();
      for (int i = 0; i < data.length; i++) {
        final double x = 20 + i * pointSpacing;
        final double y = 20 +
            chartHeight -
            ((data[i]['score'] - minVal) / (maxVal - minVal)) * chartHeight;

        if (i == 0) {
          trendPath.moveTo(x, y);
        } else {
          trendPath.lineTo(x, y);
        }

        // Draw point
        canvas.drawCircle(
            Offset(x, y), 4, trendPaint..style = PaintingStyle.fill);
      }
      canvas.drawPath(trendPath, trendPaint..style = PaintingStyle.stroke);

      // Draw labels for months
      for (int i = 0; i < data.length; i++) {
        final double x = 20 + i * pointSpacing;
        textPainter.text = TextSpan(
          text: data[i]['month'],
          style: const TextStyle(color: Colors.grey, fontSize: 10),
        );
        textPainter.layout();
        textPainter.paint(
            canvas, Offset(x - textPainter.width / 2, size.height - 20));
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
      yLabelPainter.paint(canvas, Offset(0, 0));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
