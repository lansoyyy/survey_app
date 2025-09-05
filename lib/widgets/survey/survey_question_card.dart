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

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
        text: widget.currentValue is String
            ? widget.currentValue as String
            : null);

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
    super.dispose();
  }

  // Method to clear the text field
  void clearTextField() {
    setState(() {
      _textController.clear();
    });
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
