import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:survey_app/models/analytics_data.dart';
import 'package:survey_app/services/auth_service.dart';
import 'package:survey_app/services/admin_service.dart';
import 'package:survey_app/utils/colors.dart';
import 'package:survey_app/widgets/button_widget.dart';
import 'package:survey_app/widgets/text_widget.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final AuthService _authService = AuthService();
  final AdminService _adminService = AdminService();

  AnalyticsData? _analyticsData;
  bool _isLoading = true;

  String _selectedPeriod = 'monthly';
  String _selectedChart = 'users';

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  void _loadAnalyticsData() {
    setState(() {
      _isLoading = true;
    });

    // Listen to analytics data stream with selected period
    _adminService.getAnalyticsData(period: _selectedPeriod).listen((data) {
      setState(() {
        _analyticsData = data;
        _isLoading = false;
      });
    }, onError: (error) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Failed to load analytics data: $error',
          backgroundColor: healthRed,
          textColor: Colors.white,
        );
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primary))
          : _analyticsData == null
              ? Center(
                  child: TextWidget(
                    text: 'No analytics data available',
                    fontSize: 16,
                    color: textLight,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dashboard metrics
                    TextWidget(
                      text: 'Dashboard Metrics',
                      fontSize: 20,
                      color: textPrimary,
                      fontFamily: 'Bold',
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildMetricCard(
                          'Total Users',
                          _analyticsData!.totalUsers.toString(),
                          Icons.people,
                          primary,
                        ),
                        _buildMetricCard(
                          'Active Users',
                          _analyticsData!.activeUsers.toString(),
                          Icons.person,
                          healthGreen,
                        ),
                        _buildMetricCard(
                          'Avg. Risk Score',
                          '${_analyticsData!.averageRiskScore.toStringAsFixed(1)}',
                          Icons.monitor_heart,
                          accent,
                        ),
                        _buildMetricCard(
                          'Completion Rate',
                          '${_analyticsData!.completionRate.toStringAsFixed(1)}%',
                          Icons.check_circle,
                          healthGreen,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Chart controls
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
                          children: [
                            Row(
                              children: [
                                // Period selector
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    decoration: const InputDecoration(
                                      labelText: 'Period',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(8)),
                                      ),
                                    ),
                                    value: _selectedPeriod,
                                    items: const [
                                      DropdownMenuItem(
                                          value: 'daily', child: Text('Daily')),
                                      DropdownMenuItem(
                                          value: 'weekly',
                                          child: Text('Weekly')),
                                      DropdownMenuItem(
                                          value: 'monthly',
                                          child: Text('Monthly')),
                                      DropdownMenuItem(
                                          value: 'yearly',
                                          child: Text('Yearly')),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedPeriod = value ?? 'monthly';
                                      });
                                      // Reload analytics data with new period
                                      _loadAnalyticsData();
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Chart type selector
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    decoration: const InputDecoration(
                                      labelText: 'Chart Type',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(8)),
                                      ),
                                    ),
                                    value: _selectedChart,
                                    items: const [
                                      DropdownMenuItem(
                                          value: 'users',
                                          child: Text('User\nGrowth')),
                                      DropdownMenuItem(
                                          value: 'risk',
                                          child: Text('Risk\nDistribution')),
                                      DropdownMenuItem(
                                          value: 'completion',
                                          child: Text('Completion\nRate')),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedChart = value ?? 'users';
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Chart visualization
                    TextWidget(
                      text: 'Data Visualization',
                      fontSize: 20,
                      color: textPrimary,
                      fontFamily: 'Bold',
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 300,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: grey),
                      ),
                      child: _buildChart(),
                    ),
                    const SizedBox(height: 24),
                    // Demographics section
                    TextWidget(
                      text: 'Demographics',
                      fontSize: 20,
                      color: textPrimary,
                      fontFamily: 'Bold',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Card(
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
                                    text: 'Gender Distribution',
                                    fontSize: 16,
                                    color: textPrimary,
                                    fontFamily: 'Bold',
                                  ),
                                  const SizedBox(height: 16),
                                  _buildPieChart(
                                    _analyticsData!.demographicData['gender']
                                        as Map<String, dynamic>,
                                    [primary, accent],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Card(
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
                                    text: 'Age Groups',
                                    fontSize: 16,
                                    color: textPrimary,
                                    fontFamily: 'Bold',
                                  ),
                                  const SizedBox(height: 16),
                                  _buildBarChart(
                                    _analyticsData!.demographicData['ageGroups']
                                        as Map<String, dynamic>,
                                    primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Risk level distribution
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
                              text: 'Risk Level Distribution',
                              fontSize: 16,
                              color: textPrimary,
                              fontFamily: 'Bold',
                            ),
                            const SizedBox(height: 16),
                            _buildRiskDistributionChart(
                              _analyticsData!.demographicData['riskLevels']
                                  as Map<String, dynamic>,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            TextWidget(
              text: title,
              fontSize: 14,
              color: textLight,
            ),
            const SizedBox(height: 4),
            TextWidget(
              text: value,
              fontSize: 20,
              color: color,
              fontFamily: 'Bold',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    // Get time-based data from analytics data
    final timeBasedData = _analyticsData?.demographicData['timeBasedData']
            as Map<String, dynamic>? ??
        {};

    switch (_selectedChart) {
      case 'users':
        final userGrowthData =
            timeBasedData['userGrowth'] as List<dynamic>? ?? [];
        return CustomPaint(
          painter: UserGrowthChartPainter(chartData: userGrowthData),
          size: const Size(double.infinity, 300),
        );
      case 'risk':
        final riskDistributionData =
            timeBasedData['riskDistribution'] as List<dynamic>? ?? [];
        return CustomPaint(
          painter:
              RiskDistributionChartPainter(chartData: riskDistributionData),
          size: const Size(double.infinity, 300),
        );
      case 'completion':
        final completionRateData =
            timeBasedData['completionRate'] as List<dynamic>? ?? [];
        return CustomPaint(
          painter: CompletionRateChartPainter(chartData: completionRateData),
          size: const Size(double.infinity, 300),
        );
      default:
        return Center(
          child: TextWidget(
            text: 'Select a chart type',
            fontSize: 16,
            color: textLight,
          ),
        );
    }
  }

  Widget _buildPieChart(Map<String, dynamic> data, List<Color> colors) {
    return CustomPaint(
      painter: PieChartPainter(data, colors),
      size: const Size(double.infinity, 150),
    );
  }

  Widget _buildBarChart(Map<String, dynamic> data, Color color) {
    return CustomPaint(
      painter: BarChartPainter(data, color),
      size: const Size(double.infinity, 150),
    );
  }

  Widget _buildRiskDistributionChart(Map<String, dynamic> data) {
    return CustomPaint(
      painter: RiskDistributionBarChartPainter(data),
      size: const Size(double.infinity, 150),
    );
  }
}

class UserGrowthChartPainter extends CustomPainter {
  final List<dynamic> chartData;

  UserGrowthChartPainter({required this.chartData});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    // Use actual data instead of sample data
    final List<Map<String, dynamic>> data = [];
    if (chartData.isNotEmpty) {
      for (var item in chartData) {
        if (item is Map<String, dynamic>) {
          data.add(item);
        }
      }
    } else {
      // Handle empty data case
      textPainter.text = const TextSpan(
        text: 'No user growth data available',
        style: TextStyle(color: Colors.grey, fontSize: 12),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(size.width / 2 - textPainter.width / 2,
            size.height / 2 - textPainter.height / 2),
      );
      return;
    }

    // Find min and max values for scaling
    int minVal = 0;
    int maxVal = 0;
    if (data.isNotEmpty) {
      maxVal = data
          .map((d) => d['users'] as int? ?? 0)
          .reduce((a, b) => a > b ? a : b);
      // Add some padding to the top
      maxVal = (maxVal * 1.1).toInt();
      if (maxVal == 0) maxVal = 10; // Minimum scale
    }

    final double chartWidth = size.width - 60;
    final double chartHeight = size.height - 60;
    final double pointSpacing =
        data.length > 1 ? chartWidth / (data.length - 1) : 0;

    // Draw grid lines
    final gridPaint = Paint()
      ..color = grey
      ..strokeWidth = 0.5;

    // Draw horizontal grid lines
    for (int i = 0; i <= 5; i++) {
      final double y = 30 + (chartHeight / 5) * i;
      canvas.drawLine(Offset(30, y), Offset(size.width - 30, y), gridPaint);
    }

    // Draw data points and lines
    final trendPaint = paint..color = primary;
    Path trendPath = Path();

    for (int i = 0; i < data.length; i++) {
      final double x = 30 + i * pointSpacing;
      final int userCount = data[i]['users'] as int? ?? 0;
      final double y = 30 +
          chartHeight -
          ((userCount - minVal) / (maxVal - minVal)) * chartHeight;

      if (i == 0) {
        trendPath.moveTo(x, y);
      } else {
        trendPath.lineTo(x, y);
      }

      // Draw point
      canvas.drawCircle(
          Offset(x, y), 4, trendPaint..style = PaintingStyle.fill);
    }
    canvas.drawPath(trendPath, trendPaint..style = PaintingStyle.stroke);

    // Draw labels for periods
    for (int i = 0; i < data.length; i++) {
      final double x = 30 + i * pointSpacing;
      final String period = data[i]['period'] as String? ?? '';
      textPainter.text = TextSpan(
        text: period,
        style: const TextStyle(color: Colors.grey, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(
          canvas, Offset(x - textPainter.width / 2, size.height - 20));
    }

    // Draw Y-axis labels
    for (int i = 0; i <= 5; i++) {
      final double y = 30 + (chartHeight / 5) * i;
      final int labelValue = minVal + ((maxVal - minVal) ~/ 5) * (5 - i);
      textPainter.text = TextSpan(
        text: labelValue.toString(),
        style: const TextStyle(color: Colors.grey, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - 6));
    }

    // Draw title
    textPainter.text = const TextSpan(
      text: 'User Growth Over Time',
      style: TextStyle(color: Colors.grey, fontSize: 12),
    );
    textPainter.layout();
    textPainter.paint(
        canvas, Offset(size.width / 2 - textPainter.width / 2, 0));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RiskDistributionChartPainter extends CustomPainter {
  final List<dynamic> chartData;

  RiskDistributionChartPainter({required this.chartData});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    // Use actual data instead of sample data
    final List<Map<String, dynamic>> data = [];
    if (chartData.isNotEmpty) {
      for (var item in chartData) {
        if (item is Map<String, dynamic>) {
          data.add(item);
        }
      }
    } else {
      // Handle empty data case
      textPainter.text = const TextSpan(
        text: 'No risk distribution data available',
        style: TextStyle(color: Colors.grey, fontSize: 12),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(size.width / 2 - textPainter.width / 2,
            size.height / 2 - textPainter.height / 2),
      );
      return;
    }

    final double chartWidth = size.width - 60;
    final double chartHeight = size.height - 60;
    final double pointSpacing =
        data.length > 1 ? chartWidth / (data.length - 1) : 0;

    // Draw grid lines
    final gridPaint = Paint()
      ..color = grey
      ..strokeWidth = 0.5;

    // Draw horizontal grid lines
    for (int i = 0; i <= 5; i++) {
      final double y = 30 + (chartHeight / 5) * i;
      canvas.drawLine(Offset(30, y), Offset(size.width - 30, y), gridPaint);
    }

    // Define colors for different risk levels
    final normalPaint = paint..color = healthGreen;
    final elevatedPaint = paint..color = healthYellow;
    final highPaint = paint..color = accent;
    final veryHighPaint = paint..color = Colors.orange;
    final criticalPaint = paint..color = healthRed;

    // Draw data for each risk level
    _drawRiskLine(
        canvas, data, pointSpacing, chartHeight, 30, 'normal', normalPaint);
    _drawRiskLine(
        canvas, data, pointSpacing, chartHeight, 30, 'elevated', elevatedPaint);
    _drawRiskLine(
        canvas, data, pointSpacing, chartHeight, 30, 'high', highPaint);
    _drawRiskLine(
        canvas, data, pointSpacing, chartHeight, 30, 'veryHigh', veryHighPaint);
    _drawRiskLine(
        canvas, data, pointSpacing, chartHeight, 30, 'critical', criticalPaint);

    // Draw labels for periods
    for (int i = 0; i < data.length; i++) {
      final double x = 30 + i * pointSpacing;
      final String period = data[i]['period'] as String? ?? '';
      textPainter.text = TextSpan(
        text: period,
        style: const TextStyle(color: Colors.grey, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(
          canvas, Offset(x - textPainter.width / 2, size.height - 20));
    }

    // Draw legend
    final legendY = 10.0;
    _drawLegendItem(canvas, healthGreen, 'Normal', 30, legendY);
    _drawLegendItem(canvas, healthYellow, 'Elevated', 100, legendY);
    _drawLegendItem(canvas, accent, 'High', 190, legendY);
    _drawLegendItem(canvas, Colors.orange, 'Very High', 260, legendY);
    _drawLegendItem(canvas, healthRed, 'Critical', 340, legendY);

    // Draw title
    textPainter.text = const TextSpan(
      text: 'Risk Distribution Over Time',
      style: TextStyle(color: Colors.grey, fontSize: 12),
    );
    textPainter.layout();
    textPainter.paint(
        canvas, Offset(size.width / 2 - textPainter.width / 2, 0));
  }

  void _drawRiskLine(
      Canvas canvas,
      List<Map<String, dynamic>> data,
      double pointSpacing,
      double chartHeight,
      double topPadding,
      String riskLevel,
      Paint paint) {
    Path path = Path();

    for (int i = 0; i < data.length; i++) {
      final double x = 30 + i * pointSpacing;
      // Get the count for this risk level and normalize to 0-100 scale
      final int count = data[i][riskLevel] as int? ?? 0;
      // For visualization, we'll use a fixed max value for consistent scaling
      final int maxCount = 50; // Adjust based on expected max count
      final double normalizedValue = (count / maxCount) * 100;
      final double y =
          topPadding + chartHeight - (normalizedValue / 100) * chartHeight;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      // Draw point
      canvas.drawCircle(Offset(x, y), 3, paint..style = PaintingStyle.fill);
    }
    canvas.drawPath(path, paint..style = PaintingStyle.stroke);
  }

  void _drawLegendItem(
      Canvas canvas, Color color, String label, double x, double y) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(x, y + 3), 4, paint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(color: Colors.grey, fontSize: 10),
      ),
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x + 10, y));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CompletionRateChartPainter extends CustomPainter {
  final List<dynamic> chartData;

  CompletionRateChartPainter({required this.chartData});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    // Use actual data instead of sample data
    final List<Map<String, dynamic>> data = [];
    if (chartData.isNotEmpty) {
      for (var item in chartData) {
        if (item is Map<String, dynamic>) {
          data.add(item);
        }
      }
    } else {
      // Handle empty data case
      textPainter.text = const TextSpan(
        text: 'No completion rate data available',
        style: TextStyle(color: Colors.grey, fontSize: 12),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(size.width / 2 - textPainter.width / 2,
            size.height / 2 - textPainter.height / 2),
      );
      return;
    }

    final double chartWidth = size.width - 60;
    final double chartHeight = size.height - 60;
    final double pointSpacing =
        data.length > 1 ? chartWidth / (data.length - 1) : 0;

    // Draw grid lines
    final gridPaint = Paint()
      ..color = grey
      ..strokeWidth = 0.5;

    // Draw horizontal grid lines
    for (int i = 0; i <= 5; i++) {
      final double y = 30 + (chartHeight / 5) * i;
      canvas.drawLine(Offset(30, y), Offset(size.width - 30, y), gridPaint);
    }

    // Draw data points and lines
    final trendPaint = paint..color = healthGreen;
    Path trendPath = Path();

    for (int i = 0; i < data.length; i++) {
      final double x = 30 + i * pointSpacing;
      // Get completion rate (0-100 scale)
      final double rate = data[i]['rate'] as double? ?? 0.0;
      final double y = 30 + chartHeight - (rate / 100) * chartHeight;

      if (i == 0) {
        trendPath.moveTo(x, y);
      } else {
        trendPath.lineTo(x, y);
      }

      // Draw point
      canvas.drawCircle(
          Offset(x, y), 4, trendPaint..style = PaintingStyle.fill);
    }
    canvas.drawPath(trendPath, trendPaint..style = PaintingStyle.stroke);

    // Draw labels for periods
    for (int i = 0; i < data.length; i++) {
      final double x = 30 + i * pointSpacing;
      final String period = data[i]['period'] as String? ?? '';
      textPainter.text = TextSpan(
        text: period,
        style: const TextStyle(color: Colors.grey, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(
          canvas, Offset(x - textPainter.width / 2, size.height - 20));
    }

    // Draw Y-axis labels (0-100%)
    for (int i = 0; i <= 5; i++) {
      final double y = 30 + (chartHeight / 5) * i;
      final int label = i * 20;
      textPainter.text = TextSpan(
        text: '$label%',
        style: const TextStyle(color: Colors.grey, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - 6));
    }

    // Draw title
    textPainter.text = const TextSpan(
      text: 'Survey Completion Rate',
      style: TextStyle(color: Colors.grey, fontSize: 12),
    );
    textPainter.layout();
    textPainter.paint(
        canvas, Offset(size.width / 2 - textPainter.width / 2, 0));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PieChartPainter extends CustomPainter {
  final Map<String, dynamic> data;
  final List<Color> colors;

  PieChartPainter(this.data, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) * 0.8;

    double total = 0;
    data.values.forEach((value) {
      total += value as int;
    });

    final paint = Paint()..style = PaintingStyle.fill;

    double startAngle = -90 * (3.14159 / 180); // Start from top

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    int colorIndex = 0;
    data.entries.toList().asMap().forEach((index, entry) {
      final sweepAngle = (entry.value / total) * 2 * 3.14159;
      paint.color = colors[colorIndex % colors.length];

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Draw label
      final midAngle = startAngle + sweepAngle / 2;
      final labelRadius = radius * 0.7;
      final labelX = center.dx + labelRadius * math.cos(midAngle);
      final labelY = center.dy + labelRadius * math.sin(midAngle);

      textPainter.text = TextSpan(
        text:
            '${entry.key}\n${(entry.value / total * 100).toStringAsFixed(1)}%',
        style: const TextStyle(color: Colors.grey, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(
          canvas,
          Offset(
              labelX - textPainter.width / 2, labelY - textPainter.height / 2));

      startAngle += sweepAngle;
      colorIndex++;
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BarChartPainter extends CustomPainter {
  final Map<String, dynamic> data;
  final Color color;

  BarChartPainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    // Find max value for scaling
    int maxValue = 0;
    data.values.forEach((value) {
      if (value > maxValue) maxValue = value;
    });

    final double barWidth = (size.width - 40) / data.length - 10;
    final double chartHeight = size.height - 40;

    int index = 0;
    data.entries.toList().asMap().forEach((i, entry) {
      final double barHeight = (entry.value / maxValue) * chartHeight;
      final double x = 20 + index * (barWidth + 10);
      final double y = size.height - 20 - barHeight;

      // Draw bar
      canvas.drawRect(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        paint,
      );

      // Draw value on top of bar
      textPainter.text = TextSpan(
        text: entry.value.toString(),
        style: const TextStyle(color: Colors.grey, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x + barWidth / 2 - textPainter.width / 2, y - 15),
      );

      // Draw label below bar
      textPainter.text = TextSpan(
        text: entry.key,
        style: const TextStyle(color: Colors.grey, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x + barWidth / 2 - textPainter.width / 2, size.height - 15),
      );

      index++;
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RiskDistributionBarChartPainter extends CustomPainter {
  final Map<String, dynamic> data;

  RiskDistributionBarChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    // Handle empty data case
    if (data.isEmpty) {
      textPainter.text = const TextSpan(
        text: 'No risk data available',
        style: TextStyle(color: Colors.grey, fontSize: 12),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(size.width / 2 - textPainter.width / 2,
            size.height / 2 - textPainter.height / 2),
      );
      return;
    }

    // Find max value for scaling
    double maxValue = 0;
    data.values.forEach((value) {
      final numValue = value is num ? value.toDouble() : 0.0;
      if (numValue > maxValue) maxValue = numValue;
    });

    // Ensure we have a minimum maxValue to avoid division by zero
    if (maxValue == 0) maxValue = 1;

    final double barHeight = 20;
    final double spacing = 10;
    final double startY = 20;

    // Colors for different risk levels
    final colors = [
      healthGreen,
      healthYellow,
      accent,
      Colors.orange,
      healthRed
    ];

    int index = 0;
    data.entries.toList().asMap().forEach((i, entry) {
      final double value = entry.value is num ? entry.value.toDouble() : 0.0;
      final double barWidth = (value / maxValue) * (size.width - 120);
      final double y = startY + index * (barHeight + spacing);

      // Draw bar
      final paint = Paint()
        ..color = colors[index % colors.length]
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTWH(100, y, barWidth, barHeight),
        paint,
      );

      // Draw risk level label
      textPainter.text = TextSpan(
        text: entry.key,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(0, y + barHeight / 2 - textPainter.height / 2),
      );

      // Draw value at the end of bar
      textPainter.text = TextSpan(
        text: '${value.toStringAsFixed(1)}%',
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(110 + barWidth, y + barHeight / 2 - textPainter.height / 2),
      );

      index++;
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
