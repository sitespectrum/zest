import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';

part "custom_card.g.dart";

@hwidget
Widget customCard({
  required Widget child,
  String title = "",
  IconData? iconData,
  Widget? icon,
}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(0),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
    child: Column(
      spacing: 4,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(
            top: 12,
            bottom: 12,
            left: 18,
            right: 18,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF272727),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              (icon ??
                  (iconData != null
                      ? Icon(iconData, color: Colors.white)
                      : Container())),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF272727),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: child,
        ),
      ],
    ),
  );
}
