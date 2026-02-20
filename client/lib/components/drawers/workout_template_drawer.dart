import 'package:client/components/add_meal_page.dart';
import 'package:client/components/ui/custom_snackbar.dart';
import 'package:client/models/meal.dart';
import 'package:client/models/workout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:provider/provider.dart';
import 'package:client/components/ui/custom_button.dart';
import 'package:client/components/ui/custom_drawer.dart';
import 'package:client/providers/language_provider.dart';

part "workout_template_drawer.g.dart";

@hwidget
Widget workoutTemplateDrawer(
  BuildContext context,
  CustomUserWorkoutDto template,
  List<ExerciseDto> userWorkouts,
) {
  final lang = Provider.of<LanguageProvider>(context, listen: false);
  final langCode = Provider.of<LanguageProvider>(context).languageCode;
  Color workoutColorCode = const Color.fromARGB(150, 50, 146, 255);
  return CustomDrawer(
    child: Container(
      width: double.infinity,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            template.customName.isNotEmpty
                ? template.customName
                : lang.getText("unknown_template"),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: template.exercises.length,
              itemBuilder: (context, i) {
                final item = template.exercises[i];

                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(
                    vertical: 3,
                    horizontal: 4,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 55, 55, 55),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.exercise!.getName(langCode),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                margin: EdgeInsets.fromLTRB(5, 5, 2, 5),
                child: CustomButton(
                  onPressed: () => Navigator.pop(context),
                  title: lang.getText("close"),
                  iconData: Icons.close_rounded,
                  variant: CustomButtonVariant.secondary,
                ),
              ),
              Container(
                margin: EdgeInsets.fromLTRB(2, 5, 5, 5),
                child: CustomButton(
                  onPressed: () {
                    template.exercises
                        .map((we) => we.exercise)
                        .where((e) => e != null)
                        .cast<ExerciseDto>()
                        .forEach((exercise) {
                          final exerciseCopy = exercise.copyWith();
                          exerciseCopy.sets = [];
                          userWorkouts.add(exerciseCopy);
                        });
                    Navigator.pop(context, true);
                    CustomSnackbar.show(
                      context,
                      lang.getText("template_loaded"),
                      backgroundColor: workoutColorCode,
                    );
                  },
                  variant: CustomButtonVariant.primaryWorkout,
                  child: Text(
                    lang.getText("load_template"),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
