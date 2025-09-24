import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:survey_app/utils/colors.dart';
import 'package:survey_app/widgets/button_widget.dart';
import 'package:survey_app/widgets/text_widget.dart';

class ConsultationWidget extends StatelessWidget {
  final DateTime? consultationDate;
  final String? physicianName;
  final String? clinicAddress;
  final VoidCallback onEdit;

  const ConsultationWidget({
    super.key,
    this.consultationDate,
    this.physicianName,
    this.clinicAddress,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (consultationDate == null)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: surfaceBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 48,
                    color: textLight,
                  ),
                  const SizedBox(height: 12),
                  TextWidget(
                    text: 'No consultation scheduled',
                    fontSize: 16,
                    color: textLight,
                  ),
                  const SizedBox(height: 8),
                  TextWidget(
                    text: 'Schedule your next appointment',
                    fontSize: 14,
                    color: textLight,
                  ),
                  const SizedBox(height: 16),
                  ButtonWidget(
                    label: 'Schedule Consultation',
                    onPressed: onEdit,
                    width: 300,
                    color: healthGreen,
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Consultation date card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: healthGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: healthGreen,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.calendar_today,
                          color: textOnPrimary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextWidget(
                              text: 'Next Consultation',
                              fontSize: 14,
                              color: textSecondary,
                            ),
                            const SizedBox(height: 4),
                            TextWidget(
                              text: DateFormat('EEEE, MMMM d, yyyy')
                                  .format(consultationDate!),
                              fontSize: 16,
                              color: textPrimary,
                              fontFamily: 'Medium',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Physician info
                if (physicianName != null && physicianName!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: surfaceBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.person,
                            color: primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextWidget(
                                text: 'Physician',
                                fontSize: 12,
                                color: textSecondary,
                              ),
                              const SizedBox(height: 2),
                              TextWidget(
                                text: physicianName!,
                                fontSize: 14,
                                color: textPrimary,
                                fontFamily: 'Medium',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                if (physicianName != null && physicianName!.isNotEmpty)
                  const SizedBox(height: 12),

                // Clinic info
                if (clinicAddress != null && clinicAddress!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: surfaceBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.location_on,
                            color: primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextWidget(
                                text: 'Clinic',
                                fontSize: 12,
                                color: textSecondary,
                              ),
                              const SizedBox(height: 2),
                              TextWidget(
                                text: clinicAddress!,
                                fontSize: 14,
                                color: textPrimary,
                                fontFamily: 'Medium',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Edit button
                ButtonWidget(
                  label: 'Edit Consultation',
                  onPressed: onEdit,
                  width: 160,
                  color: primaryLight,
                  textColor: textPrimary,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
