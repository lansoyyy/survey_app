import 'package:flutter/material.dart';
import 'package:survey_app/widgets/text_widget.dart';

class TextFieldWidget extends StatefulWidget {
  final String label;
  final String? hint;
  bool? isObscure;
  final TextEditingController controller;
  final double? width;
  final double? height;
  final int? maxLine;
  final TextInputType? inputType;
  late bool? showEye;
  late bool? enabled;
  late Color? color;
  late Color? borderColor;
  late Color? hintColor;
  late double? radius;
  final String? Function(String?)? validator;

  final TextCapitalization? textCapitalization;

  bool? hasValidator;
  Widget? prefix;

  late int? length;

  Widget? suffix;
  Function(String)? onChanged;

  TextFieldWidget({
    super.key,
    required this.label,
    this.hint = '',
    this.onChanged,
    required this.controller,
    this.isObscure = false,
    this.width = 300,
    this.height = 65,
    this.maxLine = 1,
    this.prefix,
    this.suffix,
    this.length,
    this.hintColor = Colors.black,
    this.borderColor = Colors.grey,
    this.showEye = false,
    this.enabled = true,
    this.color = Colors.black,
    this.radius = 5,
    this.hasValidator = true,
    this.textCapitalization = TextCapitalization.sentences,
    this.inputType = TextInputType.text,
    this.validator,
  });

  @override
  State<TextFieldWidget> createState() => _TextFieldWidgetState();
}

class _TextFieldWidgetState extends State<TextFieldWidget>
    with TickerProviderStateMixin {
  late AnimationController _focusAnimationController;
  late Animation<double> _focusAnimation;
  late AnimationController _errorAnimationController;
  late Animation<double> _errorAnimation;

  bool _isFocused = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();

    _focusAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _errorAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _focusAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _focusAnimationController,
      curve: Curves.easeOut,
    ));

    _errorAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _errorAnimationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _focusAnimationController.dispose();
    _errorAnimationController.dispose();
    super.dispose();
  }

  void _handleFocusChange(bool hasFocus) {
    setState(() {
      _isFocused = hasFocus;
    });

    if (hasFocus) {
      _focusAnimationController.forward();
    } else {
      _focusAnimationController.reverse();
    }
  }

  void _handleError(bool hasError) {
    if (hasError != _hasError) {
      setState(() {
        _hasError = hasError;
      });

      if (hasError) {
        _errorAnimationController.forward();
      } else {
        _errorAnimationController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8, left: 0, right: 0),
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: AnimatedBuilder(
          animation: Listenable.merge(
              [_focusAnimationController, _errorAnimationController]),
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.radius!),
                boxShadow: [
                  BoxShadow(
                    color: _isFocused
                        ? widget.borderColor!.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.1),
                    blurRadius: _isFocused ? 8 : 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextFormField(
                onChanged: widget.onChanged,
                maxLength: widget.length,
                enabled: widget.enabled,
                style: TextStyle(
                  fontFamily: 'Medium',
                  fontSize: 16,
                  color: widget.enabled! ? Colors.black : Colors.grey,
                ),
                textCapitalization: widget.textCapitalization!,
                keyboardType: widget.inputType,
                onTap: () => _handleFocusChange(true),
                onFieldSubmitted: (_) => _handleFocusChange(false),
                decoration: InputDecoration(
                  fillColor: Colors.white,
                  filled: true,
                  prefixIcon: widget.prefix != null
                      ? Padding(
                          padding: const EdgeInsets.all(12),
                          child: widget.prefix,
                        )
                      : null,
                  suffixIcon: widget.suffix ??
                      (widget.showEye! == true
                          ? Container(
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                onPressed: () {
                                  setState(() {
                                    widget.isObscure = !widget.isObscure!;
                                  });
                                },
                                icon: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    widget.isObscure!
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    key: ValueKey(widget.isObscure),
                                    color: Colors.grey[600],
                                    size: 20,
                                  ),
                                ),
                              ),
                            )
                          : null),
                  hintText: widget.hint,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _hasError
                          ? Colors.red.withOpacity(0.5)
                          : Colors.grey.withOpacity(0.3),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(widget.radius!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _isFocused
                          ? widget.borderColor!
                          : Colors.grey.withOpacity(0.3),
                      width: _isFocused ? 2.0 : 1.5,
                    ),
                    borderRadius: BorderRadius.circular(widget.radius!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: widget.borderColor!,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(widget.radius!),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.red.withOpacity(0.7),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(widget.radius!),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.red,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(widget.radius!),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.grey.withOpacity(0.2),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(widget.radius!),
                  ),
                  label: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontFamily: 'Medium',
                      fontSize: _isFocused ? 14 : 16,
                      color: _hasError
                          ? Colors.red
                          : _isFocused
                              ? widget.borderColor!
                              : Colors.grey[600],
                    ),
                    child: TextWidget(
                      text: widget.label,
                      fontSize: _isFocused ? 14 : 16,
                      color: _hasError
                          ? Colors.red
                          : _isFocused
                              ? widget.borderColor!
                              : Colors.grey[600],
                      fontFamily: 'Medium',
                    ),
                  ),
                  hintStyle: TextStyle(
                    fontFamily: 'Regular',
                    color: widget.hintColor!.withOpacity(0.6),
                    fontSize: 16,
                  ),
                  errorStyle: TextStyle(
                    fontFamily: 'Medium',
                    fontSize: 12,
                    color: Colors.red,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                maxLines: widget.maxLine,
                obscureText: widget.isObscure!,
                controller: widget.controller,
                validator: widget.hasValidator!
                    ? (value) {
                        final error = widget.validator != null
                            ? widget.validator!(value)
                            : (value == null || value.isEmpty)
                                ? 'Please enter ${widget.label.toLowerCase()}'
                                : null;

                        _handleError(error != null);
                        return error;
                      }
                    : widget.validator,
              ),
            );
          },
        ),
      ),
    );
  }
}
