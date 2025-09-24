import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:survey_app/models/medication.dart';
import 'package:survey_app/services/medication_service.dart';
import 'package:survey_app/widgets/custom_app_bar.dart';
import 'package:survey_app/widgets/button_widget.dart';
import 'add_medication_dialog.dart';
import 'medication_table_widget.dart';
import 'consultation_widget.dart';
import 'consultation_dialog.dart';
import 'notification_widget.dart';

class MedicationScreen extends StatefulWidget {
  const MedicationScreen({super.key});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  final MedicationService _medicationService = MedicationService();
  List<Medication> _medications = [];
  List<Map<String, dynamic>> _notifications = [];
  DateTime? _consultationDate;
  String? _physicianName;
  String? _clinicAddress;

  @override
  void initState() {
    super.initState();
    _loadMedications();
    _loadConsultation();
    _loadNotifications();
  }

  Future<void> _loadMedications() async {
    final medications = await _medicationService.getMedications();
    setState(() {
      _medications = medications;
    });
  }

  Future<void> _loadConsultation() async {
    final consultation = await _medicationService.getConsultation();
    if (consultation != null) {
      setState(() {
        _consultationDate = consultation['date'] != null
            ? DateTime.parse(consultation['date'])
            : null;
        _physicianName = consultation['physicianName'];
        _clinicAddress = consultation['clinicAddress'];
      });
    }
  }

  Future<void> _loadNotifications() async {
    final notifications = await _medicationService.getNotifications();
    setState(() {
      _notifications = notifications;
    });
  }

  void _showAddMedicationDialog({Medication? medication}) {
    showDialog(
      context: context,
      builder: (context) => AddMedicationDialog(
        medication: medication,
        onSave: (medication) async {
          if (medication.id.isEmpty) {
            await _medicationService.saveMedication(medication);
            // Add notification for new medication
            await _medicationService.saveNotification({
              'id': DateTime.now().millisecondsSinceEpoch.toString(),
              'type': 'medication',
              'title': 'New Medication Added',
              'message':
                  '${medication.drugName} (${medication.dose}) at ${medication.time}',
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            });
          } else {
            await _medicationService.updateMedication(medication);
          }
          _loadMedications();
          _loadNotifications();
        },
      ),
    );
  }

  void _deleteMedication(String id) async {
    await _medicationService.deleteMedication(id);
    _loadMedications();
  }

  void _showConsultationDialog() {
    showDialog(
      context: context,
      builder: (context) => ConsultationDialog(
        initialDate: _consultationDate,
        initialPhysicianName: _physicianName,
        initialClinicAddress: _clinicAddress,
        onSave: (date, {physicianName, clinicAddress}) async {
          await _medicationService.saveConsultation(date,
              physicianName: physicianName, clinicAddress: clinicAddress);
          // Add notification for consultation
          await _medicationService.saveNotification({
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'type': 'consultation',
            'title': 'Consultation Scheduled',
            'message':
                'Next consultation on ${DateFormat('yyyy-MM-dd').format(date)}',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
          _loadConsultation();
          _loadNotifications();
        },
      ),
    );
  }

  void _clearNotification(String id) async {
    await _medicationService.clearNotification(id);
    _loadNotifications();
  }

  void _addBPReadingNotification() async {
    await _medicationService.saveNotification({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'type': 'bp_reading',
      'title': 'BP Reading Reminder',
      'message': 'Time to take your blood pressure reading',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'MEDICATION',
        showBackButton: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ButtonWidget(
              label: 'Add Medication',
              onPressed: () => _showAddMedicationDialog(),
              width: 200,
            ),
            const SizedBox(height: 24),
            MedicationTableWidget(
              medications: _medications,
              onEdit: (medication) =>
                  _showAddMedicationDialog(medication: medication),
              onDelete: _deleteMedication,
            ),
            const SizedBox(height: 24),
            ConsultationWidget(
              consultationDate: _consultationDate,
              physicianName: _physicianName,
              clinicAddress: _clinicAddress,
              onEdit: _showConsultationDialog,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ButtonWidget(
                  label: 'Add BP Reminder',
                  onPressed: _addBPReadingNotification,
                  width: 160,
                  fontSize: 14,
                  height: 40,
                ),
              ],
            ),
            const SizedBox(height: 16),
            NotificationWidget(
              notifications: _notifications,
              onClear: _clearNotification,
            ),
          ],
        ),
      ),
    );
  }
}
