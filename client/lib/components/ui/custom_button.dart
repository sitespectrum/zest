import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';

part "custom_button.g.dart";

enum CustomButtonVariant {
  primary,
  primaryMeal,
  primaryWorkout,
  primaryDelete,
  secondary,
}

@hwidget
Widget customButton({
  required void Function()? onPressed,
  String title = "",
  CustomButtonVariant variant = CustomButtonVariant.primary,
  IconData? iconData,
  Widget? icon,
  Widget? child,
  bool disabled = false,
}) {
  return FilledButton(
    onPressed: disabled ? null : onPressed,
    style: switch (variant) {
      CustomButtonVariant.primary => FilledButton.styleFrom(
        backgroundColor: const Color.fromARGB(50, 64, 255, 50),
        disabledBackgroundColor: const Color.fromARGB(25, 64, 255, 50),
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white38,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide(
          color: disabled
              ? const Color.fromARGB(50, 64, 255, 50)
              : const Color.fromARGB(100, 64, 255, 50),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      CustomButtonVariant.primaryWorkout => FilledButton.styleFrom(
        backgroundColor: const Color.fromARGB(50, 50, 146, 255),
        disabledBackgroundColor: const Color.fromARGB(25, 64, 255, 50),
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white38,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide(
          color: disabled
              ? const Color.fromARGB(50, 64, 255, 50)
              : const Color.fromARGB(150, 50, 146, 255),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      CustomButtonVariant.primaryMeal => FilledButton.styleFrom(
        backgroundColor: const Color.fromARGB(50, 255, 156, 122),
        disabledBackgroundColor: const Color.fromARGB(25, 64, 255, 50),
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white38,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide(
          color: disabled
              ? const Color.fromARGB(50, 64, 255, 50)
              : const Color.fromARGB(255, 255, 115, 69),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      CustomButtonVariant.primaryDelete => FilledButton.styleFrom(
        backgroundColor: const Color.fromARGB(40, 255, 122, 122),
        disabledBackgroundColor: const Color.fromARGB(25, 64, 255, 50),
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white38,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide(
          color: disabled
              ? const Color.fromARGB(50, 64, 255, 50)
              : const Color.fromARGB(255, 255, 69, 69),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      CustomButtonVariant.secondary => FilledButton.styleFrom(
        backgroundColor: const Color.fromARGB(25, 255, 255, 255),
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white38,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 12),
      ),
    },
    child:
        child ??
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 12,
          children: [
            if (icon != null) icon,
            if (icon == null && iconData != null) Icon(iconData, size: 20),

            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
  );
}
