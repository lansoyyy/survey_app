import 'package:flutter/material.dart';
import 'package:survey_app/utils/colors.dart';
import 'package:survey_app/widgets/text_widget.dart';

class RiskAssessmentCard extends StatelessWidget {
  final double riskScore;
  final String riskLevel;
  final String description;
  final String? title;

  const RiskAssessmentCard({
    super.key,
    required this.riskScore,
    required this.riskLevel,
    required this.description,
    this.title,
  });

  Color _getRiskColor() {
    // Convert percentage back to score out of 20 for comparison
    final double score = (riskScore / 100) * 20;
    if (score <= 6) return healthGreen; // Low
    if (score <= 12) return Colors.orange; // Moderate
    return healthRed; // High
  }

  String _getRiskLevel() {
    // Convert percentage back to score out of 20 for comparison
    final double score = (riskScore / 100) * 20;
    if (score <= 6) return 'Low';
    if (score <= 12) return 'Moderate';
    return 'High';
  }

  @override
  Widget build(BuildContext context) {
    final Color riskColor = _getRiskColor();
    final String riskLevel = _getRiskLevel();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
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
                  SizedBox(
                    width: 270,
                    child: TextWidget(
                      text: title ?? 'Hypertension Assessment',
                      fontSize: 17,
                      color: textPrimary,
                      fontFamily: 'Bold',
                      maxLines: 3,
                    ),
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
      ),
    );
  }
}
