import 'package:flutter/material.dart';
import 'package:survey_app/utils/colors.dart';
import 'package:survey_app/widgets/text_widget.dart';
import 'package:survey_app/widgets/analysis/risk_assessment_card.dart';
import 'package:survey_app/widgets/button_widget.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  // Sample recommendations based on risk level
  final List<Map<String, dynamic>> _recommendations = [
    {
      'title': 'Dietary Changes',
      'description': 'Reduce sodium intake to less than 2,300mg per day',
      'priority': 'high',
    },
    {
      'title': 'Regular Exercise',
      'description': 'Engage in 30 minutes of moderate exercise 5 days a week',
      'priority': 'high',
    },
    {
      'title': 'Stress Management',
      'description': 'Practice relaxation techniques like meditation or deep breathing',
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
  ];

  // Sample trend data
  final List<Map<String, dynamic>> _trendData = [
    {'month': 'Jan', 'score': 45},
    {'month': 'Feb', 'score': 42},
    {'month': 'Mar', 'score': 38},
    {'month': 'Apr', 'score': 35},
    {'month': 'May', 'score': 32},
    {'month': 'Jun', 'score': 30},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextWidget(
            text: 'Risk Assessment',
            fontSize: 20,
            color: textPrimary,
            fontFamily: 'Bold',
          ),
          const SizedBox(height: 16),
          const RiskAssessmentCard(
            riskScore: 32.0,
            riskLevel: 'Elevated',
            description: 'Your hypertension risk is elevated. Follow the recommendations to reduce your risk.',
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
            child: CustomPaint(
              painter: TrendChartPainter(_trendData),
              size: const Size(double.infinity, 200),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: ButtonWidget(
              label: 'Export Health Report',
              onPressed: () {
                // In a real app, this would export the health report
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: TextWidget(
                      text: 'Health report export functionality would be implemented here',
                      fontSize: 14,
                      color: textOnPrimary,
                    ),
                    backgroundColor: primary,
                  ),
                );
              },
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
    final double pointSpacing = chartWidth / (data.length - 1);

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
    Path trendPath = Path();
    for (int i = 0; i < data.length; i++) {
      final double x = 20 + i * pointSpacing;
      final double y = 20 + chartHeight - ((data[i]['score'] - minVal) / (maxVal - minVal)) * chartHeight;
      
      if (i == 0) {
        trendPath.moveTo(x, y);
      } else {
        trendPath.lineTo(x, y);
      }
      
      // Draw point
      canvas.drawCircle(Offset(x, y), 4, trendPaint..style = PaintingStyle.fill);
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
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, size.height - 20));
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

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}