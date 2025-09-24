import 'package:flutter/material.dart';
import 'package:survey_app/utils/colors.dart';

Future<TimeOfDay?> timePickerWidget(
    BuildContext context, TimeOfDay selectedTime) async {
  final TimeOfDay? picked = await showTimePicker(
    context: context,
    initialTime: selectedTime,
    builder: (BuildContext context, Widget? child) {
      return Theme(
        data: ThemeData.light().copyWith(
          primaryColor: primary, // Header background color

          colorScheme: ColorScheme.light(primary: primary), // Selection color
          buttonTheme: const ButtonThemeData(
            textTheme: ButtonTextTheme.primary, // Text color
          ),
        ),
        child: child!,
      );
    },
  );

  return picked;
}
