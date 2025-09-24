import 'package:flutter/material.dart';
import 'package:survey_app/utils/colors.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: primary,
      unselectedItemColor: textLight,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      selectedLabelStyle: const TextStyle(fontSize: 11),
      unselectedLabelStyle: const TextStyle(fontSize: 11),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.question_answer_outlined),
          activeIcon: Icon(Icons.question_answer),
          label: 'Assessment',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.monitor_heart_outlined),
          activeIcon: Icon(Icons.monitor_heart),
          label: 'Monitoring',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.medication_outlined),
          activeIcon: Icon(Icons.medication),
          label: 'Medication',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics_outlined),
          activeIcon: Icon(Icons.analytics),
          label: 'Management',
        ),
      ],
    );
  }
}
