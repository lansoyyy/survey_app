import 'package:flutter/material.dart';
import 'package:survey_app/utils/colors.dart';
import 'package:survey_app/widgets/text_widget.dart';

class HealthMetricsCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final String? subtitle;
  final Color? color;
  final IconData? icon;
  final VoidCallback? onTap;

  const HealthMetricsCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    this.subtitle,
    this.color,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: surfaceBlue,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextWidget(
                        text: title,
                        fontSize: 16,
                        color: textPrimary,
                        fontFamily: 'Bold',
                      ),
                      SizedBox(
                        width: 20,
                      ),
                      if (icon != null)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color?.withOpacity(0.1) ??
                                primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            icon,
                            color: color ?? primary,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      TextWidget(
                        text: value,
                        fontSize: 24,
                        color: color ?? textPrimary,
                        fontFamily: 'Bold',
                      ),
                      const SizedBox(width: 4),
                      TextWidget(
                        text: unit,
                        fontSize: 14,
                        color: textLight,
                      ),
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    TextWidget(
                      text: subtitle!,
                      fontSize: 12,
                      color: textLight,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
