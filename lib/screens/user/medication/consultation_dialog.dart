import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:survey_app/utils/colors.dart';
import 'package:survey_app/widgets/app_text_form_field.dart';
import 'package:survey_app/widgets/button_widget.dart';
import 'package:survey_app/widgets/date_picker_widget.dart' as datePicker;
import 'package:survey_app/widgets/text_widget.dart';

class ConsultationDialog extends StatefulWidget {
  final DateTime? initialDate;
  final String? initialPhysicianName;
  final String? initialClinicAddress;
  final Function(DateTime, {String? physicianName, String? clinicAddress})
      onSave;

  const ConsultationDialog({
    super.key,
    this.initialDate,
    this.initialPhysicianName,
    this.initialClinicAddress,
    required this.onSave,
  });

  @override
  State<ConsultationDialog> createState() => _ConsultationDialogState();
}

class _ConsultationDialogState extends State<ConsultationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _physicianNameController = TextEditingController();
  final _clinicAddressController = TextEditingController();

  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _physicianNameController.text = widget.initialPhysicianName ?? '';
    _clinicAddressController.text = widget.initialClinicAddress ?? '';
  }

  @override
  void dispose() {
    _physicianNameController.dispose();
    _clinicAddressController.dispose();
    super.dispose();
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
                    color: healthGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    color: healthGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                TextWidget(
                  text: 'Schedule\nConsultation',
                  fontSize: 20,
                  color: textPrimary,
                  fontFamily: 'Bold',
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Form content
            Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Date picker
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
                            color: healthGreen.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.event,
                            color: healthGreen,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextWidget(
                                text: 'Consultation Date',
                                fontSize: 14,
                                color: textSecondary,
                              ),
                              const SizedBox(height: 4),
                              TextWidget(
                                text: _selectedDate == null
                                    ? 'Select a date'
                                    : DateFormat('EEEE, MMMM d, yyyy')
                                        .format(_selectedDate!),
                                fontSize: 16,
                                color: textPrimary,
                                fontFamily: 'Medium',
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final DateTime? picked =
                                await datePicker.datePickerWidget(
                              context,
                              _selectedDate ?? DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() {
                                _selectedDate = picked;
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

                  // Physician name
                  AppTextFormField(
                    controller: _physicianNameController,
                    labelText: 'Physician Name (Optional)',
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.text,
                  ),

                  const SizedBox(height: 16),

                  // Clinic address
                  AppTextFormField(
                    controller: _clinicAddressController,
                    labelText: 'Clinic Address (Optional)',
                    textInputAction: TextInputAction.done,
                    keyboardType: TextInputType.text,
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
                    if (_selectedDate != null) {
                      widget.onSave(
                        _selectedDate!,
                        physicianName: _physicianNameController.text.isEmpty
                            ? null
                            : _physicianNameController.text,
                        clinicAddress: _clinicAddressController.text.isEmpty
                            ? null
                            : _clinicAddressController.text,
                      );
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: TextWidget(
                            text: 'Please select a consultation date',
                            fontSize: 14,
                            color: textOnPrimary,
                          ),
                          backgroundColor: healthRed,
                        ),
                      );
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
