import 'package:flutter/material.dart';
import 'package:survey_app/utils/colors.dart';
import 'package:survey_app/widgets/button_widget.dart';
import 'package:survey_app/widgets/text_widget.dart';
import 'package:survey_app/widgets/monitoring/health_metrics_card.dart';

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({super.key});

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  // Sample health metrics data
  final List<Map<String, dynamic>> _healthMetrics = [
    {
      'title': 'Blood\nPressure',
      'value': '120/80',
      'unit': 'mmHg',
      'subtitle': 'Normal',
      'color': healthGreen,
      'icon': Icons.monitor_heart,
    },
    {
      'title': 'Heart Rate',
      'value': '72',
      'unit': 'bpm',
      'subtitle': 'Normal',
      'color': healthGreen,
      'icon': Icons.favorite,
    },
    {
      'title': 'Weight',
      'value': '70',
      'unit': 'kg',
      'subtitle': 'Healthy range',
      'color': primary,
      'icon': Icons.monitor_weight,
    },
    {
      'title': 'BMI',
      'value': '22.9',
      'unit': '',
      'subtitle': 'Normal weight',
      'color': healthGreen,
      'icon': Icons.accessibility_new,
    },
  ];

  // Sample blood pressure readings for chart
  final List<Map<String, dynamic>> _bpReadings = [
    {'date': 'Mon', 'systolic': 120, 'diastolic': 80},
    {'date': 'Tue', 'systolic': 118, 'diastolic': 78},
    {'date': 'Wed', 'systolic': 122, 'diastolic': 82},
    {'date': 'Thu', 'systolic': 119, 'diastolic': 79},
    {'date': 'Fri', 'systolic': 121, 'diastolic': 81},
    {'date': 'Sat', 'systolic': 123, 'diastolic': 83},
    {'date': 'Sun', 'systolic': 120, 'diastolic': 80},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: healthGreen,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextWidget(
                          text: 'Normal',
                          fontSize: 12,
                          color: Colors.white,
                          fontFamily: 'Bold',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      TextWidget(
                        text: '120',
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
                        text: '80',
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
                    text: 'Last recorded: Today, 08:30 AM',
                    fontSize: 12,
                    color: textLight,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          TextWidget(
            text: 'Health Metrics',
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
              childAspectRatio: 1.2,
            ),
            itemCount: _healthMetrics.length,
            itemBuilder: (context, index) {
              final metric = _healthMetrics[index];
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
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: grey),
            ),
            child: CustomPaint(
              painter: BloodPressureChartPainter(_bpReadings),
              size: const Size(double.infinity, 200),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: ButtonWidget(
              label: 'Add New Reading',
              onPressed: () {
                // In a real app, this would open a dialog to add a new reading
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: TextWidget(
                      text:
                          'Add new reading functionality would be implemented here',
                      fontSize: 14,
                      color: textOnPrimary,
                    ),
                    backgroundColor: primary,
                  ),
                );
              },
              icon: const Icon(Icons.add, color: Colors.white),
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
    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final systolicPaint = paint..color = primary;
    final diastolicPaint = paint..color = accent;

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    final double chartWidth = size.width - 40;
    final double chartHeight = size.height - 40;
    final double pointSpacing = chartWidth / (data.length - 1);

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

    // Draw data points and lines for systolic
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

      // Draw point
      canvas.drawCircle(
          Offset(x, y), 4, systolicPaint..style = PaintingStyle.fill);
    }
    canvas.drawPath(systolicPath, systolicPaint..style = PaintingStyle.stroke);

    // Draw data points and lines for diastolic
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

      // Draw point
      canvas.drawCircle(
          Offset(x, y), 4, diastolicPaint..style = PaintingStyle.fill);
    }
    canvas.drawPath(
        diastolicPath, diastolicPaint..style = PaintingStyle.stroke);

    // Draw labels for days
    for (int i = 0; i < data.length; i++) {
      final double x = 20 + i * pointSpacing;
      textPainter.text = TextSpan(
        text: data[i]['date'],
        style: const TextStyle(color: Colors.grey, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(
          canvas, Offset(x - textPainter.width / 2, size.height - 20));
    }

    // Draw legend
    final legendPaint = Paint()..style = PaintingStyle.fill;

    // Systolic legend
    canvas.drawCircle(Offset(30, 10), 4, legendPaint..color = primary);
    textPainter.text = const TextSpan(
      text: 'Systolic',
      style: TextStyle(color: Colors.grey, fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(40, 5));

    // Diastolic legend
    canvas.drawCircle(Offset(100, 10), 4, legendPaint..color = accent);
    textPainter.text = const TextSpan(
      text: 'Diastolic',
      style: TextStyle(color: Colors.grey, fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(110, 5));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
