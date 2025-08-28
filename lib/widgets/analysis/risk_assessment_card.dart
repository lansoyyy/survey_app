import 'package:flutter/material.dart';
import 'package:survey_app/utils/colors.dart';
import 'package:survey_app/widgets/text_widget.dart';

class RiskAssessmentCard extends StatelessWidget {
  final double riskScore;
  final String riskLevel;
  final String description;

  const RiskAssessmentCard({
    super.key,
    required this.riskScore,
    required this.riskLevel,
    required this.description,
  });

  Color _getRiskColor() {
    if (riskScore <= 20) return healthGreen; // Normal
    if (riskScore <= 40) return healthYellow; // Elevated
    if (riskScore <= 60) return accent; // High
    if (riskScore <= 80) return Colors.orange; // Very High
    return healthRed; // Critical
  }

  String _getRiskLevel() {
    if (riskScore <= 20) return 'Normal';
    if (riskScore <= 40) return 'Elevated';
    if (riskScore <= 60) return 'High';
    if (riskScore <= 80) return 'Very High';
    return 'Critical';
  }

  @override
  Widget build(BuildContext context) {
    final Color riskColor = _getRiskColor();
    final String riskLevel = _getRiskLevel();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              riskColor.withOpacity(0.1),
              riskColor.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: riskColor.withOpacity(0.3)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextWidget(
                  text: 'Hypertension Assessment',
                  fontSize: 17,
                  color: textPrimary,
                  fontFamily: 'Bold',
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: riskColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextWidget(
                    text: riskLevel,
                    fontSize: 12,
                    color: Colors.white,
                    fontFamily: 'Bold',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: riskScore / 100,
                      strokeWidth: 12,
                      backgroundColor: grey,
                      color: riskColor,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextWidget(
                        text: '${riskScore.round()}',
                        fontSize: 24,
                        color: riskColor,
                        fontFamily: 'Bold',
                      ),
                      TextWidget(
                        text: '/100',
                        fontSize: 14,
                        color: textLight,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextWidget(
              text: description,
              fontSize: 14,
              color: textPrimary,
              align: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
