import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';

part "custom_button.g.dart";

enum CustomButtonVariant { primary, secondary }

@hwidget
Widget customButton({
  required void Function()? onPressed,
  String title = "",
  CustomButtonVariant variant = CustomButtonVariant.primary,
  IconData? iconData,
  Widget? icon,
  Widget? child,
}) {
  return FilledButton(
    onPressed: onPressed,
    style: switch (variant) {
      CustomButtonVariant.primary => FilledButton.styleFrom(
        backgroundColor: const Color.fromARGB(50, 64, 255, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide(color: const Color.fromARGB(100, 64, 255, 50)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      CustomButtonVariant.secondary => FilledButton.styleFrom(
        backgroundColor: const Color.fromARGB(25, 255, 255, 255),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    },
    child:
        child ??
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 12,
          children: [
            if (icon != null) icon,
            if (icon == null && iconData != null)
              Icon(iconData, color: Colors.white, size: 20),

            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
  );
}
