import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:survey_app/services/auth_service.dart';
import 'package:survey_app/services/user_service.dart';
import 'package:survey_app/models/health_metrics.dart';
import 'package:survey_app/utils/colors.dart';
import 'package:survey_app/widgets/button_widget.dart';
import 'package:survey_app/widgets/text_widget.dart';
import 'package:survey_app/widgets/monitoring/health_metrics_card.dart';
import 'package:fluttertoast/fluttertoast.dart';

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({super.key});

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  List<HealthMetrics> _healthMetricsList = [];
  List<Map<String, dynamic>> _bpReadings = [];
  bool _isLoading = true;

  // Controllers for the new reading form
  final TextEditingController _systolicController = TextEditingController();
  final TextEditingController _diastolicController = TextEditingController();
  final TextEditingController _heartRateController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadHealthMetrics();
  }

  void _loadHealthMetrics() {
    if (_authService.currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    // Listen to health metrics updates
    _userService.getUserHealthMetrics(_authService.currentUser!.uid).listen(
        (metrics) {
      setState(() {
        _healthMetricsList = metrics;
        _bpReadings = _convertToChartData(metrics);
        _isLoading = false;
      });
    }, onError: (error) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Failed to load health metrics',
          backgroundColor: healthRed,
          textColor: Colors.white,
        );
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  List<Map<String, dynamic>> _convertToChartData(List<HealthMetrics> metrics) {
    // Convert health metrics to chart data format
    List<Map<String, dynamic>> chartData = [];

    // Take the last 7 readings for the chart
    final recentMetrics = metrics.length > 7 ? metrics.sublist(0, 7) : metrics;

    for (int i = 0; i < recentMetrics.length; i++) {
      final metric = recentMetrics[i];
      final DateTime recordDate = metric.recordedAt;

      // Format date as MM/DD for better display
      final String formattedDate =
          '${recordDate.month.toString().padLeft(2, '0')}/${recordDate.day.toString().padLeft(2, '0')}';

      chartData.add({
        'date': formattedDate,
        'systolic': metric.systolicBP,
        'diastolic': metric.diastolicBP,
        'combined': '${metric.systolicBP}/${metric.diastolicBP}',
        'fullDate': metric.recordedAt.toString().split(' ')[0],
      });
    }

    return chartData;
  }

  Map<String, dynamic> _getLatestMetrics() {
    if (_healthMetricsList.isEmpty) {
      return {
        'systolic': 0,
        'diastolic': 0,
        'heartRate': 0,
        'weight': 0.0,
        'height': 0.0,
        'bmi': 0.0,
      };
    }

    final latest = _healthMetricsList.first;
    return {
      'systolic': latest.systolicBP,
      'diastolic': latest.diastolicBP,
      'heartRate': latest.heartRate,
      'weight': latest.weight,
      'height': latest.height,
      'bmi': latest.bmi,
    };
  }

  List<Map<String, dynamic>> _getHealthMetricsCards() {
    final latestMetrics = _getLatestMetrics();

    return [
      {
        'title': 'Blood\nPressure',
        'value': '${latestMetrics['systolic']}/${latestMetrics['diastolic']}',
        'unit': 'mmHg',
        'subtitle':
            _getBpStatus(latestMetrics['systolic'], latestMetrics['diastolic']),
        'color':
            _getBpColor(latestMetrics['systolic'], latestMetrics['diastolic']),
        'icon': Icons.monitor_heart,
      },
      {
        'title': 'Heart Rate',
        'value': latestMetrics['heartRate'].toString(),
        'unit': 'bpm',
        'subtitle': _getHeartRateStatus(latestMetrics['heartRate']),
        'color': _getHeartRateColor(latestMetrics['heartRate']),
        'icon': Icons.favorite,
      },
      {
        'title': 'Weight',
        'value': latestMetrics['weight'].toString(),
        'unit': 'kg',
        'subtitle':
            _getWeightStatus(latestMetrics['weight'], latestMetrics['height']),
        'color': primary,
        'icon': Icons.monitor_weight,
      },
      {
        'title': 'BMI',
        'value': latestMetrics['bmi'].toStringAsFixed(1),
        'unit': '',
        'subtitle': _getBmiStatus(latestMetrics['bmi']),
        'color': _getBmiColor(latestMetrics['bmi']),
        'icon': Icons.accessibility_new,
      },
    ];
  }

  String _getBpStatus(int systolic, int diastolic) {
    // LOW: If either systolic BP is less than 90 or diastolic BP is less than 60
    if (systolic < 90 || diastolic < 60) return 'LOW';

    // VERY HIGH: 140 and up or 90 and up
    if (systolic >= 140 || diastolic >= 90) return 'VERY HIGH';

    // HIGH: 130-139 or 80-89
    if ((systolic >= 130 && systolic <= 139) ||
        (diastolic >= 80 && diastolic <= 89)) return 'HIGH';

    // ELEVATED: 120-129 or 60-79
    if ((systolic >= 120 && systolic <= 129) ||
        (diastolic >= 60 && diastolic <= 79)) return 'ELEVATED';

    // NORMAL: 90-199 or 60-79 (but not matching other categories)
    if ((systolic >= 90 && systolic <= 199) ||
        (diastolic >= 60 && diastolic <= 79)) return 'NORMAL';

    return 'NORMAL';
  }

  Color _getBpColor(int systolic, int diastolic) {
    // LOW: Blue color
    if (systolic < 90 || diastolic < 60) return Colors.blue;

    // VERY HIGH: Dark red color
    if (systolic >= 140 || diastolic >= 90) return Colors.red.shade900;

    // HIGH: Red color
    if ((systolic >= 130 && systolic <= 139) ||
        (diastolic >= 80 && diastolic <= 89)) return Colors.red;

    // ELEVATED: Orange color
    if ((systolic >= 120 && systolic <= 129) ||
        (diastolic >= 60 && diastolic <= 79)) return Colors.orange;

    // NORMAL: Green color
    if ((systolic >= 90 && systolic <= 199) ||
        (diastolic >= 60 && diastolic <= 79)) return healthGreen;

    return healthGreen;
  }

  bool _isBpElevatedOrHigher(int systolic, int diastolic) {
    // Check if BP is elevated, high, or very high based on new criteria
    // ELEVATED: 120-129 or 60-79
    if ((systolic >= 120 && systolic <= 129) ||
        (diastolic >= 60 && diastolic <= 79))
      return true; // Elevated Blood Pressure

    // HIGH: 130-139 or 80-89
    if ((systolic >= 130 && systolic <= 139) ||
        (diastolic >= 80 && diastolic <= 89))
      return true; // High Blood Pressure

    // VERY HIGH: 140 and up or 90 and up
    if (systolic >= 140 || diastolic >= 90)
      return true; // Very High Blood Pressure

    return false;
  }

  String _getHeartRateStatus(int heartRate) {
    if (heartRate >= 60 && heartRate <= 100) return 'Normal';
    if (heartRate < 60) return 'Low';
    return 'High';
  }

  Color _getHeartRateColor(int heartRate) {
    if (heartRate >= 60 && heartRate <= 100) return healthGreen;
    return healthRed;
  }

  String _getWeightStatus(double weight, double height) {
    final bmi = weight / ((height / 100) * (height / 100));
    return _getBmiStatus(bmi);
  }

  String _getBmiStatus(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal weight';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Color _getBmiColor(double bmi) {
    if (bmi < 18.5) return Colors.orange;
    if (bmi < 25) return healthGreen;
    if (bmi < 30) return Colors.orangeAccent;
    return healthRed;
  }

  // Show dialog for adding new reading
  void _showAddReadingDialog() {
    _systolicController.clear();
    _diastolicController.clear();
    _heartRateController.clear();
    _weightController.clear();
    _heightController.clear();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: TextWidget(
            text: 'Add New Reading',
            fontSize: 20,
            color: textPrimary,
            fontFamily: 'Bold',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(_systolicController, 'Systolic (Upper Number)',
                    Icons.monitor_heart),
                const SizedBox(height: 16),
                _buildTextField(_diastolicController,
                    'Diastolic (Lower Number) ', Icons.monitor_heart_outlined),
                const SizedBox(height: 16),
                _buildTextField(
                    _heartRateController, 'Heart Rate (bpm)', Icons.favorite),
                const SizedBox(height: 16),
                _buildTextField(
                    _weightController, 'Weight (kg)', Icons.monitor_weight),
                const SizedBox(height: 16),
                _buildTextField(_heightController, 'Height (cm)', Icons.height),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: TextWidget(
                text: 'Cancel',
                fontSize: 16,
                color: textLight,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _saveNewReading();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: TextWidget(
                text: 'Save',
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  // Build a text field for the dialog
  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: 12,
        ),
        prefixIcon: Icon(icon, color: primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primary, width: 2),
        ),
      ),
    );
  }

  // Save the new reading to Firebase
  void _saveNewReading() async {
    if (_authService.currentUser == null) {
      Fluttertoast.showToast(
        msg: 'You must be logged in to add readings',
        backgroundColor: healthRed,
        textColor: Colors.white,
      );
      return;
    }

    // Get values from controllers
    final String systolicStr = _systolicController.text;
    final String diastolicStr = _diastolicController.text;
    final String heartRateStr = _heartRateController.text;
    final String weightStr = _weightController.text;
    final String heightStr = _heightController.text;

    // Validate inputs
    if (systolicStr.isEmpty || diastolicStr.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please enter at least systolic and diastolic values',
        backgroundColor: healthRed,
        textColor: Colors.white,
      );
      return;
    }

    try {
      final int systolic = int.parse(systolicStr);
      final int diastolic = int.parse(diastolicStr);
      final int heartRate = heartRateStr.isEmpty ? 0 : int.parse(heartRateStr);
      final double weight = weightStr.isEmpty ? 0 : double.parse(weightStr);
      final double height = heightStr.isEmpty ? 0 : double.parse(heightStr);

      // Calculate BMI if weight and height are provided
      double bmi = 0;
      if (weight > 0 && height > 0) {
        bmi = weight / ((height / 100) * (height / 100));
      }

      final healthMetrics = HealthMetrics(
        metricId: '', // Will be generated by Firebase
        userId: _authService.currentUser!.uid,
        systolicBP: systolic,
        diastolicBP: diastolic,
        heartRate: heartRate,
        weight: weight,
        height: height,
        bmi: bmi,
        recordedAt: DateTime.now(),
      );

      await _userService.addHealthMetrics(healthMetrics);

      if (mounted) {
        Fluttertoast.showToast(
          msg: 'New reading saved successfully!',
          backgroundColor: healthGreen,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Failed to save reading. Please try again.',
          backgroundColor: healthRed,
          textColor: Colors.white,
        );
      }
    }
  }

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _heartRateController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final healthMetricsCards = _getHealthMetricsCards();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primary))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextWidget(
                  text: 'Health Summary',
                  fontSize: 20,
                  color: textPrimary,
                  fontFamily: 'Bold',
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: surfaceBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextWidget(
                              text: 'Current Blood Pressure',
                              fontSize: 16,
                              color: textPrimary,
                              fontFamily: 'Bold',
                            ),
                            Row(
                              children: [
                                // Show alarm icon if BP is elevated or higher
                                if (_isBpElevatedOrHigher(
                                    _getLatestMetrics()['systolic'],
                                    _getLatestMetrics()['diastolic']))
                                  Icon(
                                    Icons.notifications_active,
                                    color: healthRed,
                                    size: 20,
                                  ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _getBpColor(
                                        _getLatestMetrics()['systolic'],
                                        _getLatestMetrics()['diastolic']),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: TextWidget(
                                    text: _getBpStatus(
                                        _getLatestMetrics()['systolic'],
                                        _getLatestMetrics()['diastolic']),
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontFamily: 'Bold',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            TextWidget(
                              text: _getLatestMetrics()['systolic'].toString(),
                              fontSize: 32,
                              color: textPrimary,
                              fontFamily: 'Bold',
                            ),
                            TextWidget(
                              text: '/',
                              fontSize: 24,
                              color: textLight,
                            ),
                            TextWidget(
                              text: _getLatestMetrics()['diastolic'].toString(),
                              fontSize: 32,
                              color: textPrimary,
                              fontFamily: 'Bold',
                            ),
                            const SizedBox(width: 8),
                            TextWidget(
                              text: 'mmHg',
                              fontSize: 16,
                              color: textLight,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextWidget(
                          text:
                              'Last recorded: ${_healthMetricsList.isNotEmpty ? _healthMetricsList.first.recordedAt.toString().split(' ')[0] : 'N/A'}',
                          fontSize: 12,
                          color: textLight,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: ButtonWidget(
                    label: 'Add New Reading',
                    onPressed: _showAddReadingDialog,
                    icon: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 24),
                TextWidget(
                  text: 'Health Parameters',
                  fontSize: 20,
                  color: textPrimary,
                  fontFamily: 'Bold',
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: healthMetricsCards.length,
                  itemBuilder: (context, index) {
                    final metric = healthMetricsCards[index];
                    return HealthMetricsCard(
                      title: metric['title'],
                      value: metric['value'],
                      unit: metric['unit'],
                      subtitle: metric['subtitle'],
                      color: metric['color'],
                      icon: metric['icon'],
                    );
                  },
                ),
                const SizedBox(height: 24),
                TextWidget(
                  text: 'Blood Pressure Trend',
                  fontSize: 20,
                  color: textPrimary,
                  fontFamily: 'Bold',
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: grey),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextWidget(
                            text: 'Last Tracked',
                            fontSize: 14,
                            color: textLight,
                          ),
                          TextWidget(
                            text: _healthMetricsList.isNotEmpty
                                ? _healthMetricsList.first.recordedAt
                                    .toString()
                                    .split(' ')[0]
                                : 'N/A',
                            fontSize: 14,
                            color: textPrimary,
                            fontFamily: 'Bold',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 200,
                        child: _bpReadings.isEmpty
                            ? Center(
                                child: TextWidget(
                                  text: 'No data available',
                                  fontSize: 16,
                                  color: textLight,
                                ),
                              )
                            : CustomPaint(
                                painter: BloodPressureChartPainter(_bpReadings),
                                size: const Size(double.infinity, 200),
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextWidget(
                  text: 'Blood Pressure Classification',
                  fontSize: 20,
                  color: textPrimary,
                  fontFamily: 'Bold',
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: grey),
                  ),
                  child: Column(
                    children: [
                      // Header Row
                      Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF2C3E50), // Dark header background
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextWidget(
                                text: 'Blood Pressure Category',
                                fontSize: 13,
                                color: Colors.white,
                                fontFamily: 'Bold',
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: TextWidget(
                                text: 'Systolic mm Hg (upper number)',
                                fontSize: 11,
                                color: Colors.white,
                                fontFamily: 'Bold',
                              ),
                            ),
                            const SizedBox(width: 32), // Space for connector
                            Expanded(
                              flex: 2,
                              child: TextWidget(
                                text: 'Diastolic mm Hg (lower number)',
                                fontSize: 11,
                                color: Colors.white,
                                fontFamily: 'Bold',
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildBpClassificationRow(
                        'Normal',
                        'less than 120',
                        'and',
                        'less than 80',
                        const Color(0xFF4CAF50), // Green
                      ),
                      _buildBpClassificationRow(
                        'Elevated',
                        '120-129',
                        'and',
                        'less than 80',
                        const Color(0xFFFFC107), // Yellow/Orange
                      ),
                      _buildBpClassificationRow(
                        'High Blood Pressure\n(Hypertension) Stage 1',
                        '130-139',
                        'or',
                        '80-89',
                        const Color(0xFFFF9800), // Orange
                      ),
                      _buildBpClassificationRow(
                        'High Blood Pressure\n(Hypertension) Stage 2',
                        '140 or higher',
                        'or',
                        '90 or higher',
                        const Color(0xFFE53935), // Red
                      ),
                      _buildBpClassificationRow(
                        'Hypertensive Crisis',
                        'higher than 180',
                        'and/or',
                        'higher than 120',
                        const Color(0xFFB71C1C), // Dark Red
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // Helper method to build BP classification rows
  Widget _buildBpClassificationRow(
    String category,
    String systolicRange,
    String connector,
    String diastolicRange,
    Color backgroundColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: const Border(
          bottom: BorderSide(color: Colors.white, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextWidget(
              text: category,
              fontSize: 13,
              color: Colors.white,
              fontFamily: 'Bold',
            ),
          ),
          Expanded(
            flex: 2,
            child: TextWidget(
              text: systolicRange,
              fontSize: 12,
              color: Colors.white,
              fontFamily: 'Medium',
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TextWidget(
              text: connector,
              fontSize: 12,
              color: Colors.white,
              fontFamily: 'Bold',
            ),
          ),
          Expanded(
            flex: 2,
            child: TextWidget(
              text: diastolicRange,
              fontSize: 12,
              color: Colors.white,
              fontFamily: 'Medium',
            ),
          ),
        ],
      ),
    );
  }
}

class BloodPressureChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;

  BloodPressureChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final systolicPaint = paint..color = Colors.red;
    final diastolicPaint = paint..color = Colors.blue;

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    final double chartWidth = size.width - 40;
    final double chartHeight = size.height - 40;
    final double pointSpacing =
        data.length > 1 ? chartWidth / (data.length - 1) : 0;

    // Find min and max values for scaling
    int minVal = 60;
    int maxVal = 180;

    // Draw grid lines
    final gridPaint = Paint()
      ..color = grey
      ..strokeWidth = 0.5;

    // Draw horizontal grid lines
    for (int i = 0; i <= 6; i++) {
      final double y = 20 + (chartHeight / 6) * i;
      canvas.drawLine(Offset(20, y), Offset(size.width - 20, y), gridPaint);

      // Draw labels
      final label = ((maxVal - (i * (maxVal - minVal) ~/ 6))).toString();
      textPainter.text = TextSpan(
        text: label,
        style: const TextStyle(color: Colors.grey, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - 6));
    }

    // Draw data points and lines for systolic and diastolic blood pressure
    if (data.isNotEmpty) {
      // Draw systolic line
      Path systolicPath = Path();
      for (int i = 0; i < data.length; i++) {
        final double x = 20 + i * pointSpacing;
        final double y = 20 +
            chartHeight -
            ((data[i]['systolic'] - minVal) / (maxVal - minVal)) * chartHeight;

        if (i == 0) {
          systolicPath.moveTo(x, y);
        } else {
          systolicPath.lineTo(x, y);
        }

        // Draw systolic point
        canvas.drawCircle(
            Offset(x, y), 4, systolicPaint..style = PaintingStyle.fill);
      }
      canvas.drawPath(
          systolicPath, systolicPaint..style = PaintingStyle.stroke);

      // Draw diastolic line
      Path diastolicPath = Path();
      for (int i = 0; i < data.length; i++) {
        final double x = 20 + i * pointSpacing;
        final double y = 20 +
            chartHeight -
            ((data[i]['diastolic'] - minVal) / (maxVal - minVal)) * chartHeight;

        if (i == 0) {
          diastolicPath.moveTo(x, y);
        } else {
          diastolicPath.lineTo(x, y);
        }

        // Draw diastolic point
        canvas.drawCircle(
            Offset(x, y), 4, diastolicPaint..style = PaintingStyle.fill);
      }
      canvas.drawPath(
          diastolicPath, diastolicPaint..style = PaintingStyle.stroke);

      // Draw labels for days and BP readings
      for (int i = 0; i < data.length; i++) {
        final double x = 20 + i * pointSpacing;

        // Draw date label
        textPainter.text = TextSpan(
          text: data[i]['date'],
          style: const TextStyle(color: Colors.grey, fontSize: 10),
        );
        textPainter.layout();
        textPainter.paint(
            canvas, Offset(x - textPainter.width / 2, size.height - 20));

        // Draw BP reading label
        textPainter.text = TextSpan(
          text: data[i]['combined'],
          style: const TextStyle(
              color: textPrimary, fontSize: 10, fontWeight: FontWeight.bold),
        );
        textPainter.layout();
        textPainter.paint(
            canvas, Offset(x - textPainter.width / 2, size.height - 35));
      }

      // Draw legend
      final legendPaint = Paint()..style = PaintingStyle.fill;

      // Systolic legend
      canvas.drawCircle(Offset(30, 10), 4, legendPaint..color = Colors.red);
      textPainter.text = const TextSpan(
        text: 'Systolic',
        style: TextStyle(color: Colors.grey, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(canvas, const Offset(40, 5));

      // Diastolic legend
      canvas.drawCircle(Offset(100, 10), 4, legendPaint..color = Colors.blue);
      textPainter.text = const TextSpan(
        text: 'Diastolic',
        style: TextStyle(color: Colors.grey, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(canvas, const Offset(110, 5));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
