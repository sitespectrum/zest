import 'package:client/providers/language_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:provider/provider.dart';

part 'custom_textfield.g.dart';

@hwidget
Widget customTextField(
  BuildContext context,
  TextEditingController controller,
  String? labelText, {
  bool isPassword = false,
  bool isNumber = false,
  bool isSuffix = false,
  String? suffix,
  bool readOnly = false,
  VoidCallback? onTap,
  IconData? prefixIcon,
  bool isCreateWorkout = false,
  bool isCustomMeal = false,
}) {
  final lang = Provider.of<LanguageProvider>(context);
  return TextField(
    clipBehavior: Clip.none,
    cursorColor: Colors.white,
    style: TextStyle(color: Colors.white),
    controller: controller,
    obscureText: isPassword,
    keyboardType: isNumber ? TextInputType.number : TextInputType.text,
    decoration: InputDecoration(
      fillColor: const Color(0xFF272727),
      filled: true,
      labelText: labelText,
      labelStyle: TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      floatingLabelStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: Colors.white70)
          : null,
      suffixText: isSuffix ? suffix : null,
      suffixStyle: const TextStyle(
        color: Colors.white70,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: isCreateWorkout
              ? const Color.fromARGB(150, 50, 146, 255)
              : isCustomMeal
              ? const Color.fromARGB(255, 255, 115, 69)
              : const Color.fromARGB(100, 64, 255, 50),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white.withAlpha(20), width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}
