import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';

part "custom_separator.g.dart";

@hwidget
Widget customSeparator({Axis direction = Axis.horizontal, Color? color}) {
  return Flex(
    direction: direction,
    spacing: 12,
    children: [
      Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14,
        color: color ?? Colors.white.withAlpha(25),
      ),

      Expanded(
        child: Container(
          height: 1,
          decoration: BoxDecoration(color: color ?? Colors.white.withAlpha(25)),
        ),
      ),

      Icon(
        Icons.close_rounded,
        size: 16,
        color: color ?? Colors.white.withAlpha(25),
      ),

      Expanded(
        child: Container(
          height: 1,
          decoration: BoxDecoration(color: color ?? Colors.white.withAlpha(25)),
        ),
      ),

      Icon(
        Icons.arrow_back_ios_rounded,
        size: 14,
        color: color ?? Colors.white.withAlpha(25),
      ),
    ],
  );
}
