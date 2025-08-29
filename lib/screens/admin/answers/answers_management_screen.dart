import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:survey_app/models/survey_response.dart';
import 'package:survey_app/models/user_profile.dart';
import 'package:survey_app/services/auth_service.dart';
import 'package:survey_app/services/admin_service.dart';
import 'package:survey_app/utils/colors.dart';
import 'package:survey_app/widgets/button_widget.dart';
import 'package:survey_app/widgets/text_widget.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';

class AnswersManagementScreen extends StatefulWidget {
  const AnswersManagementScreen({super.key});

  @override
  State<AnswersManagementScreen> createState() =>
      _AnswersManagementScreenState();
}

class _AnswersManagementScreenState extends State<AnswersManagementScreen> {
  final AuthService _authService = AuthService();
  final AdminService _adminService = AdminService();

  List<SurveyResponse> _responses = [];
  List<SurveyResponse> _filteredResponses = [];
  Map<String, UserProfile> _users = {};
  bool _isLoading = true;

  String _searchQuery = '';
  String _statusFilter = 'all';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadSurveyResponses();
  }

  void _loadSurveyResponses() {
    setState(() {
      _isLoading = true;
    });

    // Listen to survey responses stream
    _adminService.getAllSurveyResponses().listen((responses) async {
      // Load user data for each response
      Map<String, UserProfile> usersMap = {};
      for (var response in responses) {
        if (!usersMap.containsKey(response.userId)) {
          try {
            final user = await _adminService.getUserById(response.userId);
            if (user != null) {
              usersMap[response.userId] = user;
            }
          } catch (e) {
            // Handle error silently
          }
        }
      }

      setState(() {
        _responses = responses;
        _users = usersMap;
        _applyFilters();
        _isLoading = false;
      });
    }, onError: (error) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Failed to load survey responses',
          backgroundColor: healthRed,
          textColor: Colors.white,
        );
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  void _applyFilters() {
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

    setState(() {
      _filteredResponses = filtered;
    });
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
          _applyFilters();
        });
      }
    }
  }

  // Export data to PDF
  void _exportDataToPdf() async {
    if (_filteredResponses.isEmpty) {
      Fluttertoast.showToast(
        msg: 'No data to export',
        backgroundColor: healthRed,
        textColor: Colors.white,
      );
      return;
    }

    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: primary),
              const SizedBox(height: 20),
              TextWidget(
                text: 'Generating PDF Report...',
                fontSize: 16,
                color: textPrimary,
                fontFamily: 'Bold',
              ),
              const SizedBox(height: 8),
              TextWidget(
                text: 'Please wait while we prepare your data report',
                fontSize: 14,
                color: textLight,
              ),
            ],
          ),
        );
      },
    );

    try {
      // Create a new PDF document
      final pdf = pw.Document();

      // Add a page to the PDF
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text(
                    'Survey Responses Report',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Generated on: ${DateTime.now().toString().split(' ')[0]}',
                  style: const pw.TextStyle(fontSize: 14),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Total Responses: ${_filteredResponses.length}',
                  style: const pw.TextStyle(fontSize: 14),
                ),
                pw.SizedBox(height: 20),
                pw.Table.fromTextArray(
                  headers: [
                    'User',
                    'Email',
                    'Submitted Date',
                    'Risk Score',
                    'Status',
                  ],
                  data: _filteredResponses.map((response) {
                    final user = _users[response.userId];
                    return [
                      user?.name ?? 'Unknown',
                      user?.email ?? 'Unknown',
                      '${response.submittedAt.day}/${response.submittedAt.month}/${response.submittedAt.year}',
                      response.riskScore.toStringAsFixed(1),
                      response.completionStatus.capitalize(),
                    ];
                  }).toList(),
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.blue800,
                  ),
                  cellAlignment: pw.Alignment.centerLeft,
                  cellStyle: const pw.TextStyle(
                    fontSize: 10,
                  ),
                  border: pw.TableBorder.all(),
                ),
              ],
            );
          },
        ),
      );

      // Save the PDF to a file
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/survey_responses_report.pdf');
      await file.writeAsBytes(await pdf.save());

      // Close progress dialog
      if (mounted) {
        Navigator.of(context).pop();

        // Show success message
        Fluttertoast.showToast(
          msg: 'PDF report generated successfully! Saved to ${file.path}',
          backgroundColor: healthGreen,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      // Close progress dialog
      if (mounted) {
        Navigator.of(context).pop();

        // Show error message
        Fluttertoast.showToast(
          msg: 'Failed to generate PDF report',
          backgroundColor: healthRed,
          textColor: Colors.white,
        );
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
                        _applyFilters();
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
                              _applyFilters();
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
                onPressed: _exportDataToPdf,
                icon: const Icon(Icons.download, color: Colors.white),
                height: 40,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Response list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: primary))
                : _filteredResponses.isEmpty
                    ? Center(
                        child: TextWidget(
                          text: 'No survey responses found',
                          fontSize: 16,
                          color: textLight,
                        ),
                      )
                    : ListView.builder(
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
                                          color:
                                              _getRiskColor(response.riskScore)
                                                  .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: TextWidget(
                                          text:
                                              '${response.riskScore.toStringAsFixed(1)}',
                                          fontSize: 12,
                                          color:
                                              _getRiskColor(response.riskScore),
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
                                      color: response.completionStatus ==
                                              'complete'
                                          ? healthGreen.withOpacity(0.1)
                                          : Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: TextWidget(
                                      text: response.completionStatus
                                          .capitalize(),
                                      fontSize: 12,
                                      color: response.completionStatus ==
                                              'complete'
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
      child: SingleChildScrollView(
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
                            text:
                                '${response.riskScore.toStringAsFixed(1)}/100',
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
