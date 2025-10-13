import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:survey_app/models/medication.dart';
import 'package:survey_app/utils/colors.dart';
import 'package:survey_app/widgets/button_widget.dart';
import 'package:survey_app/widgets/text_widget.dart';

class MedicationTableWidget extends StatelessWidget {
  final List<Medication> medications;
  final Function(Medication) onEdit;
  final Function(String) onDelete;

  const MedicationTableWidget({
    super.key,
    required this.medications,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Group medications by time
    Map<String, List<Medication>> groupedMedications = {};

    for (var medication in medications) {
      // Skip medications with null or empty time
      if (medication.time == null || medication.time.isEmpty) {
        print(
            'Skipping medication with null or empty time: ${medication.drugName}');
        continue;
      }

      if (!groupedMedications.containsKey(medication.time)) {
        groupedMedications[medication.time] = [];
      }
      groupedMedications[medication.time]!.add(medication);
    }

    // Sort times
    List<String> sortedTimes = groupedMedications.keys.toList();
    sortedTimes.sort((a, b) {
      try {
        final format = DateFormat.jm();
        // Skip empty or null time strings
        if (a.isEmpty || b.isEmpty) return 0;
        return format.parse(a).compareTo(format.parse(b));
      } catch (e) {
        // If parsing fails, keep original order
        print('Error parsing time: $e');
        return 0;
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Today\'s Medication Schedule',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (medications.isEmpty || groupedMedications.isEmpty)
          const Center(
            child: Text(
              'No medications added yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          )
        else
          ...sortedTimes.map((time) {
            final timeMedications = groupedMedications[time]!;
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...timeMedications.map((medication) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    medication.drugName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    medication.dose,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.blue),
                                  onPressed: () => onEdit(medication),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => onDelete(medication.id),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            );
          }).toList(),
      ],
    );
  }
}
