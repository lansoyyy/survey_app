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
              'Take the hypertension risk assessment survey to get personalized recommendations',
          'priority': 'high',
        },
      ];
    }

    final latestResponse = responses.first;
    final riskScore = latestResponse.riskScore;

    List<Map<String, dynamic>> recommendations = [];

    if (riskScore >= 70) {
      recommendations.addAll([
        {
          'title': 'Immediate Medical Attention',
          'description':
              'Your risk score is very high. Consult with a healthcare professional immediately',
          'priority': 'high',
        },
        {
          'title': 'Medication Compliance',
          'description':
              'If prescribed medication, ensure you take it as directed',
          'priority': 'high',
        },
      ]);
    } else if (riskScore >= 50) {
      recommendations.addAll([
        {
          'title': 'Medical Consultation',
          'description':
              'Your risk score is high. Schedule an appointment with your doctor',
          'priority': 'high',
        },
      ]);
    } else if (riskScore >= 30) {
      recommendations.addAll([
        {
          'title': 'Lifestyle Changes',
          'description':
              'Your risk score is elevated. Implement lifestyle modifications',
          'priority': 'medium',
        },
      ]);
    }

    // Add general recommendations
    recommendations.addAll([
      {
        'title': 'Dietary Changes',
        'description': 'Reduce sodium intake to less than 2,300mg per day',
        'priority': 'high',
      },
      {
        'title': 'Regular Exercise',
        'description':
            'Engage in 30 minutes of moderate exercise 5 days a week',
        'priority': 'high',
      },
      {
        'title': 'Stress Management',
        'description':
            'Practice relaxation techniques like meditation or deep breathing',
        'priority': 'medium',
      },
      {
        'title': 'Regular Monitoring',
        'description': 'Check your blood pressure at least once a week',
        'priority': 'high',
      },
      {
        'title': 'Adequate Sleep',
        'description': 'Aim for 7-9 hours of quality sleep each night',
        'priority': 'medium',
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
