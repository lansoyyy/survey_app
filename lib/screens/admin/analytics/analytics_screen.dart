import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:survey_app/models/analytics_data.dart';
import 'package:survey_app/utils/colors.dart';
import 'package:survey_app/widgets/button_widget.dart';
import 'package:survey_app/widgets/text_widget.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  // Sample analytics data
  final AnalyticsData _analyticsData = AnalyticsData(
    analyticsId: 'analytics_001',
    startDate: DateTime(2023, 1, 1),
    endDate: DateTime(2023, 6, 30),
    totalUsers: 1240,
    activeUsers: 876,
    averageRiskScore: 42.3,
    completionRate: 78.5,
    demographicData: {
      'gender': {'Male': 52, 'Female': 48},
      'ageGroups': {
        '18-30': 25,
        '31-45': 35,
        '46-60': 28,
        '60+': 12,
      },
      'riskLevels': {
        'Normal': 20,
        'Elevated': 30,
        'High': 25,
        'Very High': 15,
        'Critical': 10,
      },
    },
  );

  String _selectedPeriod = 'monthly';
  String _selectedChart = 'users';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
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
                _analyticsData.totalUsers.toString(),
                Icons.people,
                primary,
              ),
              _buildMetricCard(
                'Active Users',
                _analyticsData.activeUsers.toString(),
                Icons.person,
                healthGreen,
              ),
              _buildMetricCard(
                'Avg. Risk Score',
                '${_analyticsData.averageRiskScore.toStringAsFixed(1)}',
                Icons.monitor_heart,
                accent,
              ),
              _buildMetricCard(
                'Completion Rate',
                '${_analyticsData.completionRate.toStringAsFixed(1)}%',
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
                              borderRadius:
                                  BorderRadius.all(Radius.circular(8)),
                            ),
                          ),
                          value: _selectedPeriod,
                          items: const [
                            DropdownMenuItem(
                                value: 'daily', child: Text('Daily')),
                            DropdownMenuItem(
                                value: 'weekly', child: Text('Weekly')),
                            DropdownMenuItem(
                                value: 'monthly', child: Text('Monthly')),
                            DropdownMenuItem(
                                value: 'yearly', child: Text('Yearly')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedPeriod = value ?? 'monthly';
                            });
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
                              borderRadius:
                                  BorderRadius.all(Radius.circular(8)),
                            ),
                          ),
                          value: _selectedChart,
                          items: const [
                            DropdownMenuItem(
                                value: 'users', child: Text('User\nGrowth')),
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
                          _analyticsData.demographicData['gender']
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
                          _analyticsData.demographicData['ageGroups']
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
                    _analyticsData.demographicData['riskLevels']
                        as Map<String, dynamic>,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Report generation
          Center(
            child: ButtonWidget(
              label: 'Generate Report',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: TextWidget(
                      text:
                          'Report generation functionality would be implemented here',
                      fontSize: 14,
                      color: textOnPrimary,
                    ),
                    backgroundColor: primary,
                  ),
                );
              },
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            ),
          ),
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
    switch (_selectedChart) {
      case 'users':
        return CustomPaint(
          painter: UserGrowthChartPainter(),
          size: const Size(double.infinity, 300),
        );
      case 'risk':
        return CustomPaint(
          painter: RiskDistributionChartPainter(),
          size: const Size(double.infinity, 300),
        );
      case 'completion':
        return CustomPaint(
          painter: CompletionRateChartPainter(),
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
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    // Sample data points for user growth
    final List<Map<String, dynamic>> data = [
      {'month': 'Jan', 'users': 200},
      {'month': 'Feb', 'users': 350},
      {'month': 'Mar', 'users': 500},
      {'month': 'Apr', 'users': 680},
      {'month': 'May', 'users': 920},
      {'month': 'Jun', 'users': 1240},
    ];

    final double chartWidth = size.width - 60;
    final double chartHeight = size.height - 60;
    final double pointSpacing = chartWidth / (data.length - 1);

    // Find min and max values for scaling
    int minVal = 0;
    int maxVal = 1400;

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
      final double y = 30 +
          chartHeight -
          ((data[i]['users'] - minVal) / (maxVal - minVal)) * chartHeight;

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

    // Draw labels for months
    for (int i = 0; i < data.length; i++) {
      final double x = 30 + i * pointSpacing;
      textPainter.text = TextSpan(
        text: data[i]['month'],
        style: const TextStyle(color: Colors.grey, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(
          canvas, Offset(x - textPainter.width / 2, size.height - 20));
    }

    // Draw Y-axis labels
    for (int i = 0; i <= 5; i++) {
      final double y = 30 + (chartHeight / 5) * i;
      final label = ((maxVal - (i * (maxVal - minVal) ~/ 5))).toString();
      textPainter.text = TextSpan(
        text: label,
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
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    // Sample data points for risk distribution
    final List<Map<String, dynamic>> data = [
      {
        'month': 'Jan',
        'normal': 40,
        'elevated': 30,
        'high': 20,
        'veryHigh': 10
      },
      {
        'month': 'Feb',
        'normal': 35,
        'elevated': 35,
        'high': 20,
        'veryHigh': 10
      },
      {
        'month': 'Mar',
        'normal': 30,
        'elevated': 35,
        'high': 25,
        'veryHigh': 10
      },
      {
        'month': 'Apr',
        'normal': 25,
        'elevated': 30,
        'high': 30,
        'veryHigh': 15
      },
      {
        'month': 'May',
        'normal': 20,
        'elevated': 25,
        'high': 35,
        'veryHigh': 20
      },
      {
        'month': 'Jun',
        'normal': 15,
        'elevated': 20,
        'high': 40,
        'veryHigh': 25
      },
    ];

    final double chartWidth = size.width - 60;
    final double chartHeight = size.height - 60;
    final double pointSpacing = chartWidth / (data.length - 1);

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
    final veryHighPaint = paint..color = healthRed;

    // Draw data for each risk level
    _drawRiskLine(
        canvas, data, pointSpacing, chartHeight, 30, 'normal', normalPaint);
    _drawRiskLine(
        canvas, data, pointSpacing, chartHeight, 30, 'elevated', elevatedPaint);
    _drawRiskLine(
        canvas, data, pointSpacing, chartHeight, 30, 'high', highPaint);
    _drawRiskLine(
        canvas, data, pointSpacing, chartHeight, 30, 'veryHigh', veryHighPaint);

    // Draw labels for months
    for (int i = 0; i < data.length; i++) {
      final double x = 30 + i * pointSpacing;
      textPainter.text = TextSpan(
        text: data[i]['month'],
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
    _drawLegendItem(canvas, healthRed, 'Very High', 260, legendY);

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
      // For simplicity, we're using a fixed max value of 100
      final double y =
          topPadding + chartHeight - (data[i][riskLevel] / 100) * chartHeight;

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
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    // Sample data points for completion rate
    final List<Map<String, dynamic>> data = [
      {'month': 'Jan', 'rate': 65},
      {'month': 'Feb', 'rate': 70},
      {'month': 'Mar', 'rate': 72},
      {'month': 'Apr', 'rate': 75},
      {'month': 'May', 'rate': 78},
      {'month': 'Jun', 'rate': 82},
    ];

    final double chartWidth = size.width - 60;
    final double chartHeight = size.height - 60;
    final double pointSpacing = chartWidth / (data.length - 1);

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
      // For completion rate, max value is 100
      final double y = 30 + chartHeight - (data[i]['rate'] / 100) * chartHeight;

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

    // Draw labels for months
    for (int i = 0; i < data.length; i++) {
      final double x = 30 + i * pointSpacing;
      textPainter.text = TextSpan(
        text: data[i]['month'],
        style: const TextStyle(color: Colors.grey, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(
          canvas, Offset(x - textPainter.width / 2, size.height - 20));
    }

    // Draw Y-axis labels (0-100%)
    for (int i = 0; i <= 5; i++) {
      final double y = 30 + (chartHeight / 5) * i;
      final label = '${i * 20}%';
      textPainter.text = TextSpan(
        text: label,
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

    // Find max value for scaling
    int maxValue = 0;
    data.values.forEach((value) {
      if (value > maxValue) maxValue = value;
    });

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
      final double barWidth = (entry.value / maxValue) * (size.width - 120);
      final double y = startY + index * (barHeight + spacing);

      // Draw bar
      final paint = Paint()
        ..color = colors[index]
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
        const Offset(0, 0),
      );

      // Draw value at the end of bar
      textPainter.text = TextSpan(
        text: '${entry.value}%',
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
