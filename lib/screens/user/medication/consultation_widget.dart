import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:survey_app/widgets/button_widget.dart';

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
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Next Consultation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (consultationDate == null)
              const Text(
                'No consultation scheduled',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your next consultation is on ${DateFormat('yyyy-MM-dd').format(consultationDate!)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (physicianName != null && physicianName!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Physician: $physicianName',
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                  if (clinicAddress != null && clinicAddress!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Clinic: $clinicAddress',
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ],
              ),
            const SizedBox(height: 16),
            ButtonWidget(
              label: consultationDate == null
                  ? 'Schedule Consultation'
                  : 'Edit Consultation',
              onPressed: onEdit,
              width: 200,
            ),
          ],
        ),
      ),
    );
  }
}
