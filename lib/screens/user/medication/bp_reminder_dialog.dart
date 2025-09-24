import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:survey_app/utils/colors.dart';
import 'package:survey_app/widgets/button_widget.dart';
import 'package:survey_app/widgets/text_widget.dart';
import 'package:survey_app/widgets/time_picker_widget.dart' as timePicker;

class BPReminderDialog extends StatefulWidget {
  final Function(TimeOfDay) onSave;

  const BPReminderDialog({
    super.key,
    required this.onSave,
  });

  @override
  State<BPReminderDialog> createState() => _BPReminderDialogState();
}

class _BPReminderDialogState extends State<BPReminderDialog> {
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedTime = TimeOfDay.now();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: healthRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.favorite,
                    color: healthRed,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                TextWidget(
                  text: 'BP Reading\nReminder',
                  fontSize: 20,
                  color: textPrimary,
                  fontFamily: 'Bold',
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Time selection
            TextWidget(
              text: 'Reminder Time',
              fontSize: 16,
              color: textPrimary,
              fontFamily: 'Medium',
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: healthRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.access_time,
                      color: healthRed,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextWidget(
                          text: 'When would you like to be reminded?',
                          fontSize: 14,
                          color: textSecondary,
                        ),
                        const SizedBox(height: 4),
                        TextWidget(
                          text:
                              _selectedTime?.format(context) ?? 'Select a time',
                          fontSize: 16,
                          color: textPrimary,
                          fontFamily: 'Medium',
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final TimeOfDay? picked =
                          await timePicker.timePickerWidget(
                        context,
                        _selectedTime ?? TimeOfDay.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedTime = picked;
                        });
                      }
                    },
                    child: TextWidget(
                      text: 'Change',
                      fontSize: 14,
                      color: healthRed,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Information
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryLight.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextWidget(
                      text:
                          'You will receive a notification at the selected time to remind you to take your blood pressure reading.',
                      fontSize: 14,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: TextWidget(
                    text: 'Cancel',
                    fontSize: 16,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                ButtonWidget(
                  label: 'Set Reminder',
                  onPressed: () {
                    if (_selectedTime != null) {
                      widget.onSave(_selectedTime!);
                      Navigator.of(context).pop();
                    }
                  },
                  width: 150,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
