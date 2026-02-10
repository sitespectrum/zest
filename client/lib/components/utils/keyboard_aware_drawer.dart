import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';

part 'keyboard_aware_drawer.g.dart';

@hwidget
Widget keyboardAwareDrawer(BuildContext context, {required Widget child}) {
  final mediaQuery = MediaQuery.of(context);

  return Padding(
    padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
    child: ConstrainedBox(
      constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.9),
      child: SingleChildScrollView(child: SafeArea(child: child)),
    ),
  );
}
