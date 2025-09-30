import 'package:flutter/material.dart';
import 'package:survey_app/utils/colors.dart';
import 'package:survey_app/widgets/text_widget.dart';
import 'package:survey_app/widgets/app_text_form_field.dart';

class SurveyQuestionCard extends StatefulWidget {
  final String questionId;
  final String questionText;
  final String questionType;
  final List<String>? options;
  final bool isRequired;
  final Function(dynamic) onAnswerChanged;
  final dynamic currentValue;
  final Function()? onClearTextField;

  const SurveyQuestionCard({
    super.key,
    required this.questionId,
    required this.questionText,
    required this.questionType,
    this.options,
    required this.isRequired,
    required this.onAnswerChanged,
    this.currentValue,
    this.onClearTextField,
  });

  @override
  State<SurveyQuestionCard> createState() => _SurveyQuestionCardState();
}

class _SurveyQuestionCardState extends State<SurveyQuestionCard> {
  late TextEditingController _textController;
  List<bool>? _multipleChoiceSelections;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  double? _calculatedBMI;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
        text: widget.currentValue is String
            ? widget.currentValue as String
            : null);

    _heightController = TextEditingController();
    _weightController = TextEditingController();

    // Initialize _multipleChoiceSelections only for multiple_choice questions
    if (widget.questionType == 'multiple_choice' && widget.options != null) {
      _multipleChoiceSelections =
          List<bool>.filled(widget.options!.length, false);

      // Initialize selections if we have current values
      if (widget.currentValue != null && widget.currentValue is List) {
        for (int i = 0; i < widget.options!.length; i++) {
          _multipleChoiceSelections![i] =
              widget.currentValue.contains(widget.options![i]);
        }
      }
    }

    // Initialize BMI values if we have current values
    if (widget.questionType == 'bmi_calculation' &&
        widget.currentValue != null) {
      if (widget.currentValue is Map) {
        _heightController.text =
            widget.currentValue['height']?.toString() ?? '';
        _weightController.text =
            widget.currentValue['weight']?.toString() ?? '';
        _calculatedBMI = widget.currentValue['bmi']?.toDouble();
      }
    }
  }

  @override
  void didUpdateWidget(covariant SurveyQuestionCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update the text controller value if the current value changes
    if (widget.currentValue != null &&
        widget.currentValue is String &&
        _textController.text != widget.currentValue) {
      _textController.text = widget.currentValue;
    } else if (widget.currentValue == null && _textController.text.isNotEmpty) {
      _textController.clear();
    }

    // For non-string values, clear if needed
    if (widget.currentValue == null &&
        widget.questionType != 'multiple_choice' &&
        widget.questionType != 'single_choice' &&
        widget.questionType != 'boolean' &&
        widget.questionType != 'scale_rating' &&
        widget.questionType != 'date' &&
        _textController.text.isNotEmpty) {
      _textController.clear();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  // Method to clear the text field
  void clearTextField() {
    setState(() {
      _textController.clear();
    });
  }

  // Method to calculate BMI
  void _calculateBMI() {
    final heightText = _heightController.text.trim();
    final weightText = _weightController.text.trim();

    if (heightText.isNotEmpty && weightText.isNotEmpty) {
      final height = double.tryParse(heightText);
      final weight = double.tryParse(weightText);

      if (height != null && weight != null && height > 0) {
        // BMI = weight (kg) / (height (m))^2
        final heightInMeters = height / 100; // Convert cm to m
        final bmi = weight / (heightInMeters * heightInMeters);

        setState(() {
          _calculatedBMI = bmi;
        });

        // Determine BMI category and update the answer
        String bmiCategory;
        if (bmi < 18.5) {
          bmiCategory = 'Underweight';
        } else if (bmi < 25) {
          bmiCategory = '18.5–24.9';
        } else if (bmi < 30) {
          bmiCategory = '25–29.9';
        } else {
          bmiCategory = '30+';
        }

        widget.onAnswerChanged({
          'height': height,
          'weight': weight,
          'bmi': bmi,
          'category': bmiCategory,
        });
      }
    }
  }

  // Method to get BMI category
  String _getBMICategory(double bmi) {
    if (bmi < 18.5) {
      return 'Underweight';
    } else if (bmi < 25) {
      return 'Normal (18.5–24.9)';
    } else if (bmi < 30) {
      return 'Overweight (25–29.9)';
    } else {
      return 'Obese (30+)';
    }
  }

  // Method to get BMI category color
  Color _getBMICategoryColor(double bmi) {
    if (bmi < 18.5) {
      return Colors.blue; // Underweight
    } else if (bmi < 25) {
      return Colors.green; // Normal
    } else if (bmi < 30) {
      return Colors.orange; // Overweight
    } else {
      return Colors.red; // Obese
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextWidget(
                      text: widget.questionText,
                      fontSize: 16,
                      color: textPrimary,
                      fontFamily: 'Bold',
                    ),
                  ),
                  if (widget.isRequired)
                    TextWidget(
                      text: ' *',
                      fontSize: 16,
                      color: healthRed,
                      fontFamily: 'Bold',
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _buildQuestionInput(),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTextAnswer(String value) {
    // For number inputs
    if (widget.questionType == 'number') {
      if (value.isNotEmpty) {
        final number = int.tryParse(value);
        if (number != null) {
          widget.onAnswerChanged(number);
        } else {
          widget.onAnswerChanged(null);
        }
      } else {
        widget.onAnswerChanged(null);
      }
    } else {
      // For text inputs
      if (value.isNotEmpty) {
        widget.onAnswerChanged(value);
      } else {
        widget.onAnswerChanged(null);
      }
    }
  }

  Widget _buildQuestionInput() {
    switch (widget.questionType) {
      case 'number':
        return AppTextFormField(
          controller: _textController,
          labelText: 'Enter number',
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          onChanged: _handleTextAnswer,
          onEditingComplete: () {
            // Move to next question when editing is complete
            FocusScope.of(context).unfocus();
          },
        );

      case 'text':
        return AppTextFormField(
          controller: _textController,
          labelText: 'Enter text',
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          onChanged: _handleTextAnswer,
          onEditingComplete: () {
            // Move to next question when editing is complete
            FocusScope.of(context).unfocus();
          },
        );

      case 'boolean':
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  widget.onAnswerChanged(true);
                  setState(() {});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      widget.currentValue == true ? primary : surface,
                  side: BorderSide(color: primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: TextWidget(
                  text: 'Yes',
                  fontSize: 16,
                  color: widget.currentValue == true ? textOnPrimary : primary,
                  fontFamily: 'Medium',
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  widget.onAnswerChanged(false);
                  setState(() {});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      widget.currentValue == false ? primary : surface,
                  side: BorderSide(color: primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: TextWidget(
                  text: 'No',
                  fontSize: 16,
                  color: widget.currentValue == false ? textOnPrimary : primary,
                  fontFamily: 'Medium',
                ),
              ),
            ),
          ],
        );

      case 'single_choice':
        if (widget.options == null) return const SizedBox();
        return Column(
          children: widget.options!.map((option) {
            return RadioListTile<String>(
              title: TextWidget(
                text: option,
                fontSize: 14,
                color: textPrimary,
              ),
              value: option,
              groupValue: widget.currentValue,
              onChanged: (value) {
                widget.onAnswerChanged(value);
                setState(() {});
              },
              activeColor: primary,
            );
          }).toList(),
        );

      case 'multiple_choice':
        if (widget.options == null) return const SizedBox();
        // Ensure _multipleChoiceSelections is initialized
        _multipleChoiceSelections ??=
            List<bool>.filled(widget.options!.length, false);
        return Column(
          children: List.generate(widget.options!.length, (index) {
            return CheckboxListTile(
              title: TextWidget(
                text: widget.options![index],
                fontSize: 14,
                color: textPrimary,
              ),
              value: _multipleChoiceSelections![index],
              onChanged: (bool? value) {
                setState(() {
                  _multipleChoiceSelections![index] = value ?? false;

                  // Collect all selected options
                  final selectedOptions = <String>[];
                  for (int i = 0; i < widget.options!.length; i++) {
                    if (_multipleChoiceSelections![i]) {
                      selectedOptions.add(widget.options![i]);
                    }
                  }

                  widget.onAnswerChanged(
                      selectedOptions.isEmpty ? null : selectedOptions);
                });
              },
              activeColor: primary,
            );
          }),
        );

      case 'scale_rating':
        return Column(
          children: [
            Slider(
              value: widget.currentValue is double ? widget.currentValue : 0.0,
              min: 0,
              max: 10,
              divisions: 10,
              label: (widget.currentValue is double ? widget.currentValue : 0.0)
                  .round()
                  .toString(),
              onChanged: (double value) {
                widget.onAnswerChanged(value);
                setState(() {});
              },
              activeColor: primary,
              inactiveColor: primaryLight,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextWidget(
                  text: '0',
                  fontSize: 12,
                  color: textLight,
                ),
                TextWidget(
                  text: '5',
                  fontSize: 12,
                  color: textLight,
                ),
                TextWidget(
                  text: '10',
                  fontSize: 12,
                  color: textLight,
                ),
              ],
            ),
          ],
        );

      case 'bmi_calculation':
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: AppTextFormField(
                    controller: _heightController,
                    labelText: 'Height (cm)',
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    onChanged: (value) {
                      _calculateBMI();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppTextFormField(
                    controller: _weightController,
                    labelText: 'Weight (kg)',
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    onChanged: (value) {
                      _calculateBMI();
                    },
                  ),
                ),
              ],
            ),
            if (_calculatedBMI != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: primary.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    TextWidget(
                      text: 'Your BMI',
                      fontSize: 14,
                      color: textLight,
                      fontFamily: 'Medium',
                    ),
                    const SizedBox(height: 4),
                    TextWidget(
                      text: _calculatedBMI!.toStringAsFixed(1),
                      fontSize: 24,
                      color: primary,
                      fontFamily: 'Bold',
                    ),
                    const SizedBox(height: 4),
                    TextWidget(
                      text: _getBMICategory(_calculatedBMI!),
                      fontSize: 14,
                      color: _getBMICategoryColor(_calculatedBMI!),
                      fontFamily: 'Medium',
                    ),
                  ],
                ),
              ),
            ],
          ],
        );

      case 'date':
        return GestureDetector(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: widget.currentValue is DateTime
                  ? widget.currentValue
                  : DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
              builder: (BuildContext context, Widget? child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: primary,
                      onPrimary: textOnPrimary,
                    ),
                    textButtonTheme: TextButtonThemeData(
                      style: TextButton.styleFrom(
                        foregroundColor: primary,
                      ),
                    ),
                  ),
                  child: child!,
                );
              },
            );

            if (picked != null) {
              widget.onAnswerChanged(picked);
              setState(() {});
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextWidget(
                  text: widget.currentValue is DateTime
                      ? '${(widget.currentValue as DateTime).day}/${(widget.currentValue as DateTime).month}/${(widget.currentValue as DateTime).year}'
                      : 'Select date',
                  fontSize: 16,
                  color:
                      widget.currentValue is DateTime ? textPrimary : textLight,
                ),
                Icon(Icons.calendar_today, color: primary),
              ],
            ),
          ),
        );

      default:
        return AppTextFormField(
          controller: _textController,
          labelText: 'Enter answer',
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          onChanged: _handleTextAnswer,
          onEditingComplete: () {
            // Move to next question when editing is complete
            FocusScope.of(context).unfocus();
          },
        );
    }
  }
}
