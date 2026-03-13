import 'package:client/components/add_meal_page.dart';
import 'package:client/models/meal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:provider/provider.dart';
import 'package:client/components/ui/custom_button.dart';
import 'package:client/components/ui/custom_drawer.dart';
import 'package:client/providers/language_provider.dart';

part "recent_m_drawer.g.dart";

@hwidget
Widget recentMDrawer(
  BuildContext context,
  UserMealDto lastMeal,
  LanguageProvider lang,
) {
  final lang = Provider.of<LanguageProvider>(context, listen: false);
  String getTranslatedName(String mealName, LanguageProvider lang) {
    switch (mealName) {
      case 'Reggeli':
        return lang.getText('breakfast');
      case 'Ebéd':
        return lang.getText('lunch');
      case 'Vacsora':
        return lang.getText('dinner');
      case 'Egyéb':
        return lang.getText('other');
      default:
        return mealName;
    }
  }

  return SafeArea(
    child: CustomDrawer(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.4,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.history,
                        color: Color(0xFFff9c7a),
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lastMeal.customName.isNotEmpty
                                ? lastMeal.customName
                                : getTranslatedName(lastMeal.mealName, lang),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            lastMeal.eatenAt.toString().split(' ')[0],
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(color: Colors.white24),

            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                physics: const BouncingScrollPhysics(),
                itemCount: lastMeal.meals.length,
                itemBuilder: (context, index) {
                  final meal = lastMeal.meals[index];
                  final cleanName = stripHtmlTags(meal.name);

                  return Container(
                    margin: const EdgeInsets.symmetric(
                      vertical: 3,
                      horizontal: 0,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 55, 55, 55),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "$cleanName (${meal.quantity})",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                '${meal.qCalories.toStringAsFixed(3)} kcal',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${meal.qProtein.toStringAsFixed(3)} g ${lang.getText("protein").toLowerCase()}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${meal.qCarbs.toStringAsFixed(3)} g ${lang.getText("carbs").toLowerCase()}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${meal.qFat.toStringAsFixed(3)} g ${lang.getText("fat").toLowerCase()}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            CustomButton(
              onPressed: () => Navigator.pop(context),
              title: lang.getText("close"),
              iconData: Icons.close_rounded,
              variant: CustomButtonVariant.secondary,
            ),
          ],
        ),
      ),
    ),
  );
}
