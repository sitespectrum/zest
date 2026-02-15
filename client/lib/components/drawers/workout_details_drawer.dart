import 'package:client/components/add_meal_page.dart';
import 'package:client/models/meal.dart';
import 'package:client/models/workout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:provider/provider.dart';
import 'package:client/components/ui/custom_button.dart';
import 'package:client/components/ui/custom_drawer.dart';
import 'package:client/providers/language_provider.dart';

part "workout_details_drawer.g.dart";

@hwidget
Widget workoutDetailsDrawer(
  BuildContext context,
  ExerciseDto exerciseItem,
  String name,
) {
  final lang = Provider.of<LanguageProvider>(context, listen: false);
  final langCode = Provider.of<LanguageProvider>(context).languageCode;

  return CustomDrawer(
    child: Container(
      height: MediaQuery.of(context).size.height * 0.46,
      width: double.infinity,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (exerciseItem.images.isNotEmpty)
                    Container(
                      width: double.infinity,
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.network(
                        "https://raw.githubusercontent.com/sitespectrum/zest_exercises/main/exercises/${exerciseItem.images[0]}",
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const SizedBox(
                            height: 150,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox(
                              height: 100,
                              child: Icon(
                                Icons.fitness_center,
                                color: Colors.white24,
                                size: 50,
                              ),
                            ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      lang.getText("description"),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 30, 30, 30),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      exerciseItem.getInstructions(langCode).join('\n\n'),
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),
          CustomButton(
            onPressed: () => Navigator.pop(context),
            title: lang.getText("close"),
            iconData: Icons.close_rounded,
            variant: CustomButtonVariant.secondary,
          ),
        ],
      ),
    ),
  );
}
