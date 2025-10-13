import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:survey_app/models/medication.dart';
import 'package:survey_app/services/medication_service.dart';
import 'package:survey_app/utils/colors.dart';
import 'package:survey_app/widgets/custom_app_bar.dart';
import 'package:survey_app/widgets/button_widget.dart';
import 'package:survey_app/widgets/text_widget.dart';
import 'add_medication_dialog.dart';
import 'medication_table_widget.dart';
import 'consultation_widget.dart';
import 'consultation_dialog.dart';
import 'notification_widget.dart';
import 'bp_reminder_dialog.dart';

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
    try {
      final medications = await _medicationService.getMedications();
      // Filter out medications with null or empty time
      final validMedications = medications
          .where((med) => med.time != null && med.time.isNotEmpty)
          .toList();

      setState(() {
        _medications = validMedications;
      });
    } catch (e) {
      print('Error loading medications: $e');
      setState(() {
        _medications = [];
      });
    }
  }

  Future<void> _loadConsultation() async {
    try {
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
    } catch (e) {
      print('Error loading consultation: $e');
      setState(() {
        _consultationDate = null;
        _physicianName = null;
        _clinicAddress = null;
      });
    }
  }

  Future<void> _loadNotifications() async {
    try {
      final notifications = await _medicationService.getNotifications();
      setState(() {
        _notifications = notifications;
      });
    } catch (e) {
      print('Error loading notifications: $e');
      setState(() {
        _notifications = [];
      });
    }
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
    // Cancel the scheduled notification
    await _medicationService.cancelScheduledNotification(id);
    // Clear from local storage
    await _medicationService.clearNotification(id);
    _loadNotifications();
  }

  void _addBPReadingNotification() async {
    showDialog(
      context: context,
      builder: (context) => BPReminderDialog(
        onSave: (time) async {
          await _medicationService.saveNotification({
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'type': 'bp_reading',
            'title': 'BP Reading Reminder',
            'message':
                'Time to take your blood pressure reading at ${time.format(context)}',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'time': time.format(context),
          });
          _loadNotifications();
        },
      ),
    );
  }

  void _setNotificationFrequency(String frequency, TimeOfDay time) async {
    await _medicationService.saveNotification({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'type': 'frequency_setting',
      'title': 'Notification Frequency Set',
      'message':
          'Notifications will be sent $frequency at ${time.format(context)}',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'frequency': frequency,
      'time': time.format(context),
    });
    _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: background,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section with title and add button
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: surfaceBlue,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: 180,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextWidget(
                            text: 'Medication Tracker',
                            fontSize: 22,
                            color: textPrimary,
                            fontFamily: 'Bold',
                          ),
                          const SizedBox(height: 4),
                          TextWidget(
                            text: 'Manage your medications and appointments',
                            fontSize: 14,
                            color: textSecondary,
                          ),
                        ],
                      ),
                    ),
                    ButtonWidget(
                      label: 'Add Medication',
                      onPressed: () => _showAddMedicationDialog(),
                      width: 160,
                      height: 45,
                      fontSize: 14,
                      color: accent,
                      textColor: textOnAccent,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Medication section
              _buildSectionCard(
                title: 'Today\'s Medication Schedule',
                icon: Icons.medication,
                iconColor: primary,
                child: MedicationTableWidget(
                  medications: _medications,
                  onEdit: (medication) =>
                      _showAddMedicationDialog(medication: medication),
                  onDelete: _deleteMedication,
                ),
              ),

              const SizedBox(height: 24),

              // Consultation section
              _buildSectionCard(
                title: 'Next Consultation',
                icon: Icons.calendar_today,
                iconColor: healthGreen,
                child: ConsultationWidget(
                  consultationDate: _consultationDate,
                  physicianName: _physicianName,
                  clinicAddress: _clinicAddress,
                  onEdit: _showConsultationDialog,
                ),
              ),

              const SizedBox(height: 24),

              // Notifications section
              _buildSectionCard(
                title: 'Notifications',
                icon: Icons.notifications,
                iconColor: accent,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextWidget(
                          text: 'Reminders & Alerts',
                          fontSize: 16,
                          color: textSecondary,
                        ),
                        ButtonWidget(
                          label: 'Add BP Reminder',
                          onPressed: _addBPReadingNotification,
                          width: 160,
                          fontSize: 12,
                          height: 36,
                          color: primaryLight,
                          textColor: textPrimary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    NotificationWidget(
                      notifications: _notifications,
                      onClear: _clearNotification,
                      onSetFrequency: _setNotificationFrequency,
                      medicationService: _medicationService,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
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
          // Section header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surfaceBlue,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                TextWidget(
                  text: title,
                  fontSize: 18,
                  color: textPrimary,
                  fontFamily: 'Bold',
                ),
              ],
            ),
          ),

          // Section content
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}
