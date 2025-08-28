import 'package:flutter/material.dart';
import 'package:survey_app/utils/colors.dart';
import 'package:survey_app/widgets/text_widget.dart';

class SurveyProgressIndicator extends StatelessWidget {
  final int currentQuestion;
  final int totalQuestions;

  const SurveyProgressIndicator({
    super.key,
    required this.currentQuestion,
    required this.totalQuestions,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = totalQuestions > 0 ? currentQuestion / totalQuestions : 0;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextWidget(
              text: 'Question $currentQuestion of $totalQuestions',
              fontSize: 14,
              color: textLight,
            ),
            TextWidget(
              text: '${(progress * 100).round()}% Complete',
              fontSize: 14,
              color: textLight,
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: grey,
          color: primary,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}