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
  bool disabled = false,
  bool loading = false,
}) {
  return FilledButton(
    onPressed: disabled || loading ? null : onPressed,
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
      CustomButtonVariant.secondary => FilledButton.styleFrom(
        backgroundColor: const Color.fromARGB(25, 255, 255, 255),
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white38,
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
            if (loading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: Colors.white38,
                  strokeCap: StrokeCap.round,
                  strokeWidth: 2,
                ),
              ),
            if (!loading && icon != null) icon,
            if (!loading && icon == null && iconData != null)
              Icon(iconData, size: 20),

            if (title != "")
              Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
          ],
        ),
  );
}
