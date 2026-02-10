import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:zest_client/components/utils/keyboard_aware_drawer.dart';

part "custom_drawer.g.dart";

@hwidget
Widget customDrawer({required Widget child, EdgeInsetsGeometry? padding}) {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: AlignmentGeometry.topCenter,
        end: AlignmentGeometry.bottomCenter,
        colors: [Colors.white.withAlpha(20), Colors.white.withAlpha(5)],
      ),
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
    ),
    child: KeyboardAwareDrawer(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(24).copyWith(top: 16),
        child: Column(
          spacing: 24,
          children: [
            Container(
              height: 4,
              width: 96,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child,
          ],
        ),
      ),
    ),
  );
}
