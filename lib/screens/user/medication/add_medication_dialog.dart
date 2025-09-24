import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:survey_app/models/medication.dart';
import 'package:survey_app/widgets/app_text_form_field.dart';
import 'package:survey_app/widgets/button_widget.dart';
import 'package:survey_app/widgets/date_picker_widget.dart' as datePicker;

class AddMedicationDialog extends StatefulWidget {
  final Medication? medication;
  final Function(Medication) onSave;

  const AddMedicationDialog({
    super.key,
    this.medication,
    required this.onSave,
  });

  @override
  State<AddMedicationDialog> createState() => _AddMedicationDialogState();
}

class _AddMedicationDialogState extends State<AddMedicationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _drugNameController = TextEditingController();
  final _doseController = TextEditingController();
  final _timeController = TextEditingController();
  final _physicianNameController = TextEditingController();
  final _clinicAddressController = TextEditingController();

  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    if (widget.medication != null) {
      _drugNameController.text = widget.medication!.drugName;
      _doseController.text = widget.medication!.dose;
      _timeController.text = widget.medication!.time;
      _physicianNameController.text = widget.medication!.physicianName ?? '';
      _clinicAddressController.text = widget.medication!.clinicAddress ?? '';
      _selectedDate = widget.medication!.nextConsultationDate;
    }
  }

  @override
  void dispose() {
    _drugNameController.dispose();
    _doseController.dispose();
    _timeController.dispose();
    _physicianNameController.dispose();
    _clinicAddressController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _timeController.text = picked.format(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          widget.medication == null ? 'Add Medication' : 'Edit Medication'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextFormField(
                controller: _drugNameController,
                labelText: 'Drug Name',
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.text,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter drug name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextFormField(
                controller: _doseController,
                labelText: 'Dose',
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.text,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter dose';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _selectTime(context),
                child: AbsorbPointer(
                  child: AppTextFormField(
                    controller: _timeController,
                    labelText: 'Time of Medication',
                    textInputAction: TextInputAction.done,
                    keyboardType: TextInputType.none,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select time';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Next Consultation Date (Optional):',
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
            if (_formKey.currentState!.validate()) {
              final medication = Medication(
                id: widget.medication?.id ??
                    DateTime.now().millisecondsSinceEpoch.toString(),
                drugName: _drugNameController.text,
                dose: _doseController.text,
                time: _timeController.text,
                nextConsultationDate: _selectedDate,
                physicianName: _physicianNameController.text.isEmpty
                    ? null
                    : _physicianNameController.text,
                clinicAddress: _clinicAddressController.text.isEmpty
                    ? null
                    : _clinicAddressController.text,
              );
              widget.onSave(medication);
              Navigator.of(context).pop();
            }
          },
        ),
      ],
    );
  }
}
