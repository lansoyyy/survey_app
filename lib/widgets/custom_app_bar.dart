import 'package:flutter/material.dart';
import 'package:survey_app/utils/colors.dart';
import 'package:survey_app/widgets/text_widget.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final bool showBackButton;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.onBack,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: primary,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: textOnPrimary),
              onPressed: onBack ?? () => Navigator.of(context).pop(),
            )
          : null,
      title: TextWidget(
        text: title,
        fontSize: 20,
        color: textOnPrimary,
        fontFamily: 'Bold',
      ),
      actions: actions,
      elevation: 0,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}