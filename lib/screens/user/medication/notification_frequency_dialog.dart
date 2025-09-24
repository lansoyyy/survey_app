import 'package:flutter/material.dart';
import 'package:survey_app/utils/colors.dart';
import 'package:survey_app/widgets/button_widget.dart';
import 'package:survey_app/widgets/text_widget.dart';
import 'package:survey_app/widgets/time_picker_widget.dart' as timePicker;

class NotificationFrequencyDialog extends StatefulWidget {
  final String? initialFrequency;
  final TimeOfDay? initialTime;
  final Function(String, TimeOfDay) onSave;

  const NotificationFrequencyDialog({
    super.key,
    this.initialFrequency,
    this.initialTime,
    required this.onSave,
  });

  @override
  State<NotificationFrequencyDialog> createState() =>
      _NotificationFrequencyDialogState();
}

class _NotificationFrequencyDialogState
    extends State<NotificationFrequencyDialog> {
  String? _selectedFrequency;
  TimeOfDay? _selectedTime;

  final List<String> _frequencies = [
    'Daily',
    'Weekly',
    'Monthly',
    'Only once',
  ];

  @override
  void initState() {
    super.initState();
    _selectedFrequency = widget.initialFrequency ?? 'Daily';
    _selectedTime = widget.initialTime ?? TimeOfDay.now();
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
                    color: primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.notifications_active,
                    color: primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                TextWidget(
                  text: 'Notification Settings',
                  fontSize: 20,
                  color: textPrimary,
                  fontFamily: 'Bold',
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Frequency selection
            TextWidget(
              text: 'Notification Frequency',
              fontSize: 16,
              color: textPrimary,
              fontFamily: 'Medium',
            ),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: surfaceBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: _frequencies.map((frequency) {
                  return RadioListTile<String>(
                    title: TextWidget(
                      text: frequency,
                      fontSize: 16,
                      color: textPrimary,
                    ),
                    value: frequency,
                    groupValue: _selectedFrequency,
                    activeColor: primary,
                    onChanged: (value) {
                      setState(() {
                        _selectedFrequency = value;
                      });
                    },
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // Time selection
            TextWidget(
              text: 'Preferred Time',
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
                      color: primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.access_time,
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
                          text: 'Notification Time',
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
                      color: primary,
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
                  label: 'Save',
                  onPressed: () {
                    if (_selectedFrequency != null && _selectedTime != null) {
                      widget.onSave(_selectedFrequency!, _selectedTime!);
                      Navigator.of(context).pop();
                    }
                  },
                  width: 100,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
