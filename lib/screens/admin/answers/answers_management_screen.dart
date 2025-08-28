import 'package:flutter/material.dart';
import 'package:survey_app/models/survey_response.dart';
import 'package:survey_app/models/user_profile.dart';
import 'package:survey_app/utils/colors.dart';
import 'package:survey_app/widgets/button_widget.dart';
import 'package:survey_app/widgets/text_widget.dart';

class AnswersManagementScreen extends StatefulWidget {
  const AnswersManagementScreen({super.key});

  @override
  State<AnswersManagementScreen> createState() =>
      _AnswersManagementScreenState();
}

class _AnswersManagementScreenState extends State<AnswersManagementScreen> {
  // Sample survey responses
  final List<SurveyResponse> _responses = [
    SurveyResponse(
      responseId: 'resp_001',
      userId: 'user_001',
      surveyId: 'hypertension_risk_2023',
      answers: {
        'age': 45,
        'gender': 'Male',
        'family_history': true,
        'smoking': false,
        'exercise_frequency': 'Occasionally',
      },
      submittedAt: DateTime(2023, 6, 10),
      riskScore: 65.5,
      completionStatus: 'complete',
    ),
    SurveyResponse(
      responseId: 'resp_002',
      userId: 'user_002',
      surveyId: 'hypertension_risk_2023',
      answers: {
        'age': 38,
        'gender': 'Female',
        'family_history': false,
        'smoking': true,
        'exercise_frequency': 'Rarely',
      },
      submittedAt: DateTime(2023, 6, 12),
      riskScore: 42.0,
      completionStatus: 'complete',
    ),
    SurveyResponse(
      responseId: 'resp_003',
      userId: 'user_003',
      surveyId: 'hypertension_risk_2023',
      answers: {
        'age': 52,
        'gender': 'Male',
        'family_history': true,
        'smoking': true,
        'exercise_frequency': 'Never',
      },
      submittedAt: DateTime(2023, 6, 1),
      riskScore: 82.3,
      completionStatus: 'complete',
    ),
    SurveyResponse(
      responseId: 'resp_004',
      userId: 'user_004',
      surveyId: 'hypertension_risk_2023',
      answers: {
        'age': 29,
        'gender': 'Female',
        'family_history': false,
        'smoking': false,
        'exercise_frequency': 'Regularly',
      },
      submittedAt: DateTime(2023, 6, 11),
      riskScore: 25.7,
      completionStatus: 'complete',
    ),
  ];

  // Sample users for display
  final Map<String, UserProfile> _users = {
    'user_001': UserProfile(
      userId: 'user_001',
      name: 'John Doe',
      email: 'john.doe@example.com',
      age: 45,
      gender: 'Male',
      registrationDate: DateTime(2023, 1, 15),
      lastLogin: DateTime(2023, 6, 10),
      accountStatus: 'active',
    ),
    'user_002': UserProfile(
      userId: 'user_002',
      name: 'Jane Smith',
      email: 'jane.smith@example.com',
      age: 38,
      gender: 'Female',
      registrationDate: DateTime(2023, 2, 20),
      lastLogin: DateTime(2023, 6, 12),
      accountStatus: 'active',
    ),
    'user_003': UserProfile(
      userId: 'user_003',
      name: 'Robert Johnson',
      email: 'robert.j@example.com',
      age: 52,
      gender: 'Male',
      registrationDate: DateTime(2023, 3, 5),
      lastLogin: DateTime(2023, 6, 1),
      accountStatus: 'inactive',
    ),
    'user_004': UserProfile(
      userId: 'user_004',
      name: 'Emily Davis',
      email: 'emily.davis@example.com',
      age: 29,
      gender: 'Female',
      registrationDate: DateTime(2023, 4, 18),
      lastLogin: DateTime(2023, 6, 11),
      accountStatus: 'active',
    ),
  };

  String _searchQuery = '';
  String _statusFilter = 'all';
  DateTime? _startDate;
  DateTime? _endDate;

  List<SurveyResponse> get _filteredResponses {
    List<SurveyResponse> filtered = _responses;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((response) {
        final user = _users[response.userId];
        if (user == null) return false;
        return user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            user.email.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply status filter
    if (_statusFilter != 'all') {
      filtered = filtered
          .where((response) => response.completionStatus == _statusFilter)
          .toList();
    }

    // Apply date filter
    if (_startDate != null) {
      filtered = filtered
          .where((response) => response.submittedAt.isAfter(_startDate!))
          .toList();
    }

    if (_endDate != null) {
      filtered = filtered
          .where((response) => response.submittedAt.isBefore(_endDate!))
          .toList();
    }

    return filtered;
  }

  void _showResponseDetails(SurveyResponse response) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return ResponseDetailsSheet(
            response: response, user: _users[response.userId]);
      },
      isScrollControlled: true,
    );
  }

  void _selectDateRange() async {
    DateTime? start = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (start != null) {
      DateTime? end = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: start,
        lastDate: DateTime.now(),
      );

      if (end != null) {
        setState(() {
          _startDate = start;
          _endDate = end;
        });
      }
    }
  }

  Color _getRiskColor(double riskScore) {
    if (riskScore <= 20) return healthGreen; // Normal
    if (riskScore <= 40) return healthYellow; // Elevated
    if (riskScore <= 60) return accent; // High
    if (riskScore <= 80) return Colors.orange; // Very High
    return healthRed; // Critical
  }

  String _getRiskLevel(double riskScore) {
    if (riskScore <= 20) return 'Normal';
    if (riskScore <= 40) return 'Elevated';
    if (riskScore <= 60) return 'High';
    if (riskScore <= 80) return 'Very High';
    return 'Critical';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Filters section
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Search field
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by user name or email',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  // Status filter and date filter
                  Row(
                    children: [
                      // Status filter
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(8)),
                            ),
                          ),
                          value: _statusFilter,
                          items: const [
                            DropdownMenuItem(
                                value: 'all', child: Text('All Statuses')),
                            DropdownMenuItem(
                                value: 'complete', child: Text('Complete')),
                            DropdownMenuItem(
                                value: 'incomplete', child: Text('Incomplete')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _statusFilter = value ?? 'all';
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Date filter
                      Expanded(
                        child: GestureDetector(
                          onTap: _selectDateRange,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 18),
                                const SizedBox(width: 8),
                                TextWidget(
                                  text: _startDate != null
                                      ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year} - ${_endDate?.day ?? ''}/${_endDate?.month ?? ''}/${_endDate?.year ?? ''}'
                                      : 'Select Dates',
                                  fontSize: 14,
                                  color: _startDate != null
                                      ? textPrimary
                                      : textLight,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Export button
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ButtonWidget(
                label: 'Export Data',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: TextWidget(
                        text: 'Export functionality would be implemented here',
                        fontSize: 14,
                        color: textOnPrimary,
                      ),
                      backgroundColor: primary,
                    ),
                  );
                },
                icon: const Icon(Icons.download, color: Colors.white),
                height: 40,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Response list
          Expanded(
            child: ListView.builder(
              itemCount: _filteredResponses.length,
              itemBuilder: (context, index) {
                final response = _filteredResponses[index];
                final user = _users[response.userId];

                if (user == null) return const SizedBox();

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: TextWidget(
                      text: user.name,
                      fontSize: 16,
                      color: textPrimary,
                      fontFamily: 'Bold',
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextWidget(
                          text: user.email,
                          fontSize: 14,
                          color: textLight,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            TextWidget(
                              text:
                                  '${response.submittedAt.day}/${response.submittedAt.month}/${response.submittedAt.year}',
                              fontSize: 12,
                              color: textLight,
                            ),
                            const SizedBox(width: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getRiskColor(response.riskScore)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextWidget(
                                text:
                                    '${response.riskScore.toStringAsFixed(1)}',
                                fontSize: 12,
                                color: _getRiskColor(response.riskScore),
                                fontFamily: 'Medium',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: response.completionStatus == 'complete'
                                ? healthGreen.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextWidget(
                            text: response.completionStatus.capitalize(),
                            fontSize: 12,
                            color: response.completionStatus == 'complete'
                                ? healthGreen
                                : Colors.grey,
                            fontFamily: 'Medium',
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextWidget(
                          text: _getRiskLevel(response.riskScore),
                          fontSize: 10,
                          color: _getRiskColor(response.riskScore),
                        ),
                      ],
                    ),
                    onTap: () => _showResponseDetails(response),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ResponseDetailsSheet extends StatelessWidget {
  final SurveyResponse response;
  final UserProfile? user;

  const ResponseDetailsSheet(
      {super.key, required this.response, required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextWidget(
                text: 'Survey Response Details',
                fontSize: 20,
                color: textPrimary,
                fontFamily: 'Bold',
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (user != null) ...[
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surfaceBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: primary.withOpacity(0.1),
                          child: TextWidget(
                            text: user!.name.substring(0, 1).toUpperCase(),
                            fontSize: 18,
                            color: primary,
                            fontFamily: 'Bold',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextWidget(
                                text: user!.name,
                                fontSize: 16,
                                color: textPrimary,
                                fontFamily: 'Bold',
                              ),
                              TextWidget(
                                text: user!.email,
                                fontSize: 14,
                                color: textLight,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildInfoChip('Age: ${user!.age}', primary),
                        const SizedBox(width: 8),
                        _buildInfoChip('Gender: ${user!.gender}', primary),
                        const SizedBox(width: 8),
                        _buildInfoChip(
                            'Status: ${user!.accountStatus.capitalize()}',
                            user!.accountStatus == 'active'
                                ? healthGreen
                                : Colors.grey),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextWidget(
                    text: 'Survey Information',
                    fontSize: 16,
                    color: textPrimary,
                    fontFamily: 'Bold',
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('Response ID', response.responseId),
                  _buildDetailRow('Survey ID', response.surveyId),
                  _buildDetailRow('Submitted',
                      '${response.submittedAt.day}/${response.submittedAt.month}/${response.submittedAt.year}'),
                  _buildDetailRow(
                      'Status', response.completionStatus.capitalize()),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextWidget(
                          text: 'Risk Score',
                          fontSize: 16,
                          color: textPrimary,
                          fontFamily: 'Bold',
                        ),
                        TextWidget(
                          text: '${response.riskScore.toStringAsFixed(1)}/100',
                          fontSize: 20,
                          color: _getRiskColor(response.riskScore),
                          fontFamily: 'Bold',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextWidget(
            text: 'Survey Answers',
            fontSize: 16,
            color: textPrimary,
            fontFamily: 'Bold',
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: response.answers.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 150,
                          child: TextWidget(
                            text: entry.key.replaceAll('_', ' ').capitalize(),
                            fontSize: 14,
                            color: textLight,
                          ),
                        ),
                        TextWidget(
                          text: ':',
                          fontSize: 14,
                          color: textLight,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextWidget(
                            text: entry.value.toString(),
                            fontSize: 14,
                            color: textPrimary,
                            fontFamily: 'Medium',
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: TextWidget(
              text: label,
              fontSize: 14,
              color: textLight,
            ),
          ),
          TextWidget(
            text: ':',
            fontSize: 14,
            color: textLight,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextWidget(
              text: value,
              fontSize: 14,
              color: textPrimary,
              fontFamily: 'Medium',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextWidget(
        text: text,
        fontSize: 12,
        color: color,
      ),
    );
  }

  Color _getRiskColor(double riskScore) {
    if (riskScore <= 20) return healthGreen; // Normal
    if (riskScore <= 40) return healthYellow; // Elevated
    if (riskScore <= 60) return accent; // High
    if (riskScore <= 80) return Colors.orange; // Very High
    return healthRed; // Critical
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
