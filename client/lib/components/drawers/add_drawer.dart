import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:provider/provider.dart';
import 'package:client/components/custom_meal_page.dart';
import 'package:client/components/custom_workout_page.dart';
import 'package:client/components/ui/custom_button.dart';
import 'package:client/components/ui/custom_drawer.dart';
import 'package:client/providers/language_provider.dart';

part "add_drawer.g.dart";

@hwidget
Widget addDrawer(BuildContext context) {
  final lang = Provider.of<LanguageProvider>(context, listen: false);

  return CustomDrawer(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 24,
      children: [
        Flex(
          direction: Axis.horizontal,
          spacing: 24,
          children: [
            Expanded(
              flex: 1,
              child: AspectRatio(
                aspectRatio: 1,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CWorkoutPage(selectedDay: DateTime.now()),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(50, 50, 146, 255),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color.fromARGB(150, 50, 146, 255),
                      ),
                    ),
                    child: Column(
                      spacing: 16,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fitness_center_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                        Text(
                          lang.getText("new_workout"),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            Expanded(
              flex: 1,
              child: AspectRatio(
                aspectRatio: 1,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CMealPage(selectedDay: DateTime.now()),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(50, 255, 156, 122),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color.fromARGB(255, 255, 115, 69),
                      ),
                    ),
                    child: Column(
                      spacing: 16,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fastfood_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                        Text(
                          lang.getText("new_meal"),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        CustomButton(
          onPressed: () => Navigator.pop(context),
          title: lang.getText("close"),
          iconData: Icons.close_rounded,
          variant: CustomButtonVariant.secondary,
        ),
      ],
    ),
  );
}
