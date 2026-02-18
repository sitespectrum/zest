import 'dart:async';
import 'dart:convert';
import 'package:client/components/add_meal_page.dart';
import 'package:client/components/ui/custom_snackbar.dart';
import 'package:client/constants.dart';
import 'package:client/models/meal.dart';
import 'package:client/models/workout.dart';
import 'package:client/pages.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:client/components/ui/custom_button.dart';
import 'package:client/components/ui/custom_drawer.dart';
import 'package:client/providers/language_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

part "meal_template_drawer.g.dart";

@hwidget
Widget mealTemplateDrawer(
  BuildContext context,
  CustomUserMealDto meal,
  List<MealDto> userMeals,
  bool initialShowDelete,
  Future<void> Function(List<MealDto>, String, int) onSaveTemplate,
) {
  final lang = Provider.of<LanguageProvider>(context, listen: false);
  final langCode = Provider.of<LanguageProvider>(context).languageCode;
  Timer? _debounce;
  final isDeleteMode = useState(initialShowDelete);

  final listRefreshTrigger = useState(0);
  final refreshTrigger = useState(0);
  Future<bool> deleteMealFromTemplate(int id) async {
    final url = Uri.parse("$apiUrl/api/Meals/DeleteCustomMeal?id=$id");
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    try {
      final response = await http.delete(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print("Nem sikerült törölni: ${response.body}");
        print("Status: ${response.statusCode}, body: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Hiba törlés közben: $e");
      return false;
    }
  }

  Future<void> saveTemplateAsUserMeal(
    CustomUserMealDto template,
    int userId,
  ) async {
    await onSaveTemplate(template.meals, template.customName, userId);
  }

  return CustomDrawer(
    child: Container(
      height: MediaQuery.of(context).size.height * 0.45,
      width: double.infinity,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            meal.customName.isNotEmpty
                ? meal.customName
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
              key: ValueKey(listRefreshTrigger.value),
              shrinkWrap: true,
              itemCount: meal.meals.length,
              itemBuilder: (context, i) {
                final item = meal.meals[i];
                final cleanName = stripHtmlTags(item.name);

                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(
                    vertical: 3,
                    horizontal: 4,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 30, 30, 30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$cleanName (${item.quantity})",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${item.qCalories.toStringAsFixed(3)} kcal',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${item.qProtein.toStringAsFixed(3)} g ${lang.getText("protein")}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${item.qCarbs.toStringAsFixed(3)} g ${lang.getText("carbs")}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${item.qFat.toStringAsFixed(3)} g ${lang.getText("fat")}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                          isDeleteMode.value
                              ? Padding(
                                  padding: EdgeInsets.only(right: 10),
                                  child: IconButton(
                                    onPressed: () async {
                                      final itemToDelete = meal.meals[i];

                                      if (itemToDelete.Id == null) {
                                        meal.meals.removeAt(i);
                                        refreshTrigger.value++;
                                        return;
                                      }

                                      final ok = await deleteMealFromTemplate(
                                        itemToDelete.Id!,
                                      );

                                      if (ok) {
                                        meal.meals.removeWhere(
                                          (m) => m.Id == itemToDelete.Id,
                                        );

                                        refreshTrigger.value++;

                                        if (context.mounted) {
                                          CustomSnackbar.show(
                                            context,
                                            lang.getText("deletion_success"),
                                            backgroundColor: Colors.green,
                                          );
                                        }
                                      } else {
                                        if (context.mounted) {
                                          CustomSnackbar.show(
                                            context,
                                            lang.getText("deletion_failed"),
                                            backgroundColor: Colors.red,
                                          );
                                        }
                                      }
                                    },
                                    icon: Icon(
                                      CupertinoIcons.trash,
                                      color: Colors.red,
                                    ),
                                  ),
                                )
                              : Container(),
                        ],
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
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(5),
                  child: CustomButton(
                    onPressed: () async {
                      try {
                        final prefs = await SharedPreferences.getInstance();
                        print(prefs);
                        final userId = prefs.getInt('userId');
                        if (userId == null) {
                          throw Exception(lang.getText("no_userId"));
                        }

                        await saveTemplateAsUserMeal(meal, userId);

                        CustomSnackbar.show(
                          context,
                          lang.getText("save_success"),
                          backgroundColor: Colors.green,
                        );
                      } catch (e) {
                        CustomSnackbar.show(
                          context,
                          lang.getText("save_failed"),
                          backgroundColor: Colors.red,
                        );
                      }
                      if (_debounce?.isActive ?? false) {
                        _debounce!.cancel();
                      }
                      _debounce = Timer(const Duration(milliseconds: 1500), () {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        Navigator.push<List<MealDto>>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Pages(),
                          ),
                        );
                      });
                    },
                    variant: CustomButtonVariant.primaryMeal,
                    child: const Center(
                      child: Icon(Icons.save, color: Colors.white, size: 22),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(5),
                  child: CustomButton(
                    onPressed: () async {
                      isDeleteMode.value = !isDeleteMode.value;
                    },
                    variant: CustomButtonVariant.primaryMeal,
                    child: const Center(
                      child: Icon(Icons.edit, color: Colors.white, size: 22),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(5),
                  child: CustomButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddMealPage(
                            addToTemplate: true,
                            templateId: meal.id,
                          ),
                        ),
                      );

                      if (result != null &&
                          result is List<MealDto> &&
                          result.isNotEmpty) {
                        meal.meals.addAll(result);
                        refreshTrigger.value++;
                      }
                    },
                    variant: CustomButtonVariant.primaryMeal,
                    child: const Center(
                      child: Icon(Icons.add, color: Colors.white, size: 22),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(5),
                  child: CustomButton(
                    onPressed: () => Navigator.pop(context),
                    title: lang.getText("close"),
                    iconData: Icons.close_rounded,
                    variant: CustomButtonVariant.secondary,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(5),
                  child: CustomButton(
                    onPressed: () {
                      userMeals.addAll(meal.meals);
                      Navigator.pop(context, true);
                      CustomSnackbar.show(
                        context,
                        lang.getText(
                          "${meal.meals.length} ${lang.getText("added_to_list")}",
                        ),
                        backgroundColor: Colors.green,
                      );
                    },
                    variant: CustomButtonVariant.primaryMeal,
                    iconData: Icons.skip_next,
                    title: lang.getText("continue_meal"),
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
