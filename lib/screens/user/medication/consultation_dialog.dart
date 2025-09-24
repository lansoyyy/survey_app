import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:survey_app/widgets/app_text_form_field.dart';
import 'package:survey_app/widgets/button_widget.dart';
import 'package:survey_app/widgets/date_picker_widget.dart' as datePicker;

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
    return AlertDialog(
      title: const Text('Schedule Consultation'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Consultation Date:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
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
                    child: Text(
                      _selectedDate == null
                          ? 'Select Date'
                          : DateFormat('yyyy-MM-dd').format(_selectedDate!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppTextFormField(
                controller: _physicianNameController,
                labelText: 'Physician Name (Optional)',
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 16),
              AppTextFormField(
                controller: _clinicAddressController,
                labelText: 'Clinic Address (Optional)',
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.text,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
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
                const SnackBar(
                  content: Text('Please select a consultation date'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      ],
    );
  }
}
