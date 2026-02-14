import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:ai_barcode_scanner/ai_barcode_scanner.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zest_client/components/add_meal_page.dart';
import 'package:zest_client/components/drawers/share_drawer.dart';
import 'package:zest_client/components/ui/custom_button.dart';
import 'package:zest_client/components/ui/custom_card.dart';
import 'package:zest_client/components/ui/custom_separator.dart';
import 'package:zest_client/models/meal.dart';
import 'package:zest_client/pages.dart';
import 'package:zest_client/providers/language_provider.dart';
import 'package:zest_client/queries/queries.dart';
import 'package:zest_client/queries/wrappers.dart';
import 'package:zest_client/servers.dart';

part "custom_meal_page.g.dart";

final _mealTypes = ["Reggeli", "Ebéd", "Vacsora", "Egyéb"];

@hwidget
Widget cMealPage(BuildContext context, {required DateTime selectedDay}) {
  final lang = Provider.of<LanguageProvider>(context);
  final mealNameController = useTextEditingController();

  final customMeals = useQuery(userCustomMealsQuery);

  final debounce = useState<Timer?>(null);
  final userMeals = useState(<MealDto>[]);
  // final futureCustomMeals = useState<Future<List<CustomUserMealDto>>?>(null);
  final mealIndex = useState(4);
  final showDelete = useState(false);

  final userCaloriesSum = useMemoized(
    () => userMeals.value.fold<int>(0, (sum, meal) => sum + meal.qCalories),
    [userMeals.value],
  );
  final userProteinsSum = useMemoized(
    () => userMeals.value.fold<double>(0.0, (sum, meal) => sum + meal.qProtein),
    [userMeals.value],
  );
  final userCarbsSum = useMemoized(
    () => userMeals.value.fold<double>(0, (sum, meal) => sum + meal.qCarbs),
    [userMeals.value],
  );
  final userFatSum = useMemoized(
    () => userMeals.value.fold<double>(0, (sum, meal) => sum + meal.qFat),
    [userMeals.value],
  );

  Future<void> saveUserMeals(
    List<MealDto> meals,
    String mealName,
    int userId,
  ) async {
    final totalCalories = meals.fold<int>(
      0,
      (sum, meal) => sum + meal.calories,
    );
    final totalProtein = meals.fold<double>(
      0.0,
      (sum, meal) => sum + meal.protein,
    );
    final totalCarbs = meals.fold<double>(0.0, (sum, meal) => sum + meal.carbs);
    final totalFat = meals.fold<double>(0.0, (sum, meal) => sum + meal.fat);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    if (token == null || token.isEmpty) throw Exception("Nincs token.");

    final uri = Uri.parse("$apiUrl/api/Meals/addGroup");

    final dto = {
      "MealName": mealName,
      "UserId": userId,
      "EatenAt": selectedDay.toIso8601String(),
      "Meals": meals.map((m) => m.toJson()).toList(),
      "TotalCalories": totalCalories,
      "TotalProtein": totalProtein,
      "TotalCarbs": totalCarbs,
      "TotalFat": totalFat,
      "BaseWeight": meals.first.baseWeight,
      "Unit": meals.first.unit,
      "IsCustom": false,
    };

    final response = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(dto),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        "${lang.getText("failed_to_save")} ${response.statusCode} ${response.body}",
      );
    }
  }

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

  Future<bool> deleteUserMealTemplate(int id) async {
    final url = Uri.parse("$apiUrl/api/Meals/DeleteTemplate?id=$id");
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
        print("Szerver hiba (${response.statusCode}): ${response.body}");
        return false;
      }
    } catch (e) {
      print("Hálózati hiba: $e");
      return false;
    }
  }

  Future<void> saveUserMealsS(
    List<MealDto> meals,
    String customName,
    int userId,
  ) async {
    final totalCalories = meals.fold<int>(
      0,
      (sum, meal) => sum + meal.calories,
    );
    final totalProtein = meals.fold<double>(
      0.0,
      (sum, meal) => sum + meal.protein,
    );
    final totalCarbs = meals.fold<double>(0.0, (sum, meal) => sum + meal.carbs);
    final totalFat = meals.fold<double>(0.0, (sum, meal) => sum + meal.fat);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    if (token == null || token.isEmpty) throw Exception("Nincs token.");

    final uri = Uri.parse("$apiUrl/api/Meals/addGroupS");

    final dto = {
      "CustomName": mealNameController.text,
      "UserId": userId,
      "EatenAt": selectedDay.toIso8601String(),
      "Meals": meals.map((m) => m.toJson()).toList(),
      "TotalCalories": totalCalories,
      "TotalProtein": totalProtein,
      "TotalCarbs": totalCarbs,
      "TotalFat": totalFat,
      "BaseWeight": meals.first.baseWeight,
      "Unit": meals.first.unit,
      "IsCustom": true,
    };

    final response = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(dto),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        "${lang.getText("failed_to_save")} ${response.statusCode} ${response.body}",
      );
    }
  }

  Future<void> userMealsSampleSave(
    List<MealDto> meals,
    String customName,
    int userId,
  ) async {
    final totalCalories = meals.fold<int>(
      0,
      (sum, meal) => sum + meal.calories,
    );
    final totalProtein = meals.fold<double>(
      0.0,
      (sum, meal) => sum + meal.protein,
    );
    final totalCarbs = meals.fold<double>(0.0, (sum, meal) => sum + meal.carbs);
    final totalFat = meals.fold<double>(0.0, (sum, meal) => sum + meal.fat);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    if (token == null || token.isEmpty) throw Exception("Nincs token.");

    final uri = Uri.parse("$apiUrl/api/Meals/addGroupS");

    final dto = {
      "CustomName": customName,
      "UserId": userId,
      "EatenAt": selectedDay.toIso8601String(),
      "Meals": meals.map((m) => m.toJson()).toList(),
      "TotalCalories": totalCalories,
      "TotalProtein": totalProtein,
      "TotalCarbs": totalCarbs,
      "TotalFat": totalFat,
      "BaseWeight": meals.first.baseWeight,
      "Unit": meals.first.unit,
      "IsCustom": false,
    };

    final response = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(dto),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        "${lang.getText("failed_to_save")} ${response.statusCode} ${response.body}",
      );
    }
  }

  Future<void> saveTemplateAsUserMeal(
    CustomUserMealDto template,
    int userId,
  ) async {
    await userMealsSampleSave(template.meals, template.customName, userId);
  }

  Future<String> generateShareId() async {
    final response = await http.post(
      Uri.parse("$apiUrl/api/share/uploadWorkout"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(userMeals.value),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return responseData['shareId'];
    } else {
      throw Exception(
        "Szerver hiba: ${response.statusCode} - ${response.body}",
      );
    }
  }

  void startScanning(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AiBarcodeScanner(
          onDetect: (BarcodeCapture capture) async {
            String scannedValue = capture.barcodes.first.rawValue ?? "";

            if (scannedValue.isEmpty) return;

            Navigator.of(context).pop();

            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (c) => const Center(child: CircularProgressIndicator()),
            );

            try {
              List<MealDto> newMeals = [];

              if (scannedValue.startsWith("[")) {
                List<dynamic> decodedData = jsonDecode(scannedValue);
                newMeals = decodedData
                    .map((item) => MealDto.fromJson(item))
                    .toList();
              } else {
                final response = await http.get(
                  Uri.parse("$apiUrl/api/Share/workout-$scannedValue"),
                );

                if (response.statusCode == 200) {
                  List<dynamic> decodedData = jsonDecode(response.body);
                  newMeals = decodedData
                      .map((item) => MealDto.fromJson(item))
                      .toList();
                } else {
                  throw Exception("Nem található vagy lejárt megosztás.");
                }
              }

              Navigator.pop(context);

              userMeals.value = [...userMeals.value, ...newMeals];

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "${newMeals.length} ${lang.getText("added_to_list")}",
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            } catch (e) {
              Navigator.pop(context);
              debugPrint("Hiba az importálásnál: $e");
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Hiba: ${e.toString()}"),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          controller: MobileScannerController(
            detectionSpeed: DetectionSpeed.noDuplicates,
          ),
        ),
      ),
    );
  }

  return Scaffold(
    extendBody: true,
    body: Stack(
      children: [
        Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, Color.fromARGB(50, 64, 255, 50)],
              transform: GradientRotation(-0.5 * pi),
            ),
          ),
        ),
        SingleChildScrollView(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                spacing: 24,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // title bar + actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 20,
                            top: 8,
                            bottom: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Color.fromARGB(75, 0, 0, 0),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            spacing: 8,
                            children: [
                              Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                              Text(
                                lang.getText("new_meal"),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Color.fromARGB(75, 0, 0, 0),
                          padding: EdgeInsets.all(13),
                        ),
                        onPressed: () async {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (context) => StatefulBuilder(
                              builder: (context, setPopupState) => ShareDrawer(
                                generateShareId: generateShareId,
                                startScanning: startScanning,
                                startNfcSharing: (context) {},
                                startNfcReceiving: (context) {},
                              ),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.ios_share_rounded,
                          size: 24,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  // type selector
                  Flex(
                    direction: Axis.horizontal,
                    spacing: 12,
                    children: [
                      ...([
                        "breakfast",
                        "lunch",
                        "dinner",
                        "other",
                      ].asMap().entries.map(
                        (entry) => Expanded(
                          child: CustomButton(
                            onPressed: () => mealIndex.value = entry.key,
                            iconData: switch (entry.value) {
                              "breakfast" => Icons.coffee_rounded,
                              "lunch" => Icons.wb_sunny_rounded,
                              "dinner" => Icons.wb_twilight_rounded,
                              "other" => Icons.cookie_rounded,
                              _ => Icons.question_mark_rounded,
                            },
                            variant: mealIndex.value == entry.key
                                ? CustomButtonVariant.primary
                                : CustomButtonVariant.secondary,
                            child: Icon(switch (entry.value) {
                              "breakfast" => Icons.coffee_rounded,
                              "lunch" => Icons.wb_sunny_rounded,
                              "dinner" => Icons.wb_twilight_rounded,
                              "other" => Icons.cookie_rounded,
                              _ => Icons.question_mark_rounded,
                            }, size: 24),
                            // child: Column(
                            //   spacing: 4,
                            //   children: [
                            //     Icon(switch (entry.value) {
                            //       "breakfast" => Icons.coffee_rounded,
                            //       "lunch" => Icons.wb_sunny_rounded,
                            //       "dinner" => Icons.wb_twilight_rounded,
                            //       "other" => Icons.cookie_rounded,
                            //       _ => Icons.question_mark_rounded,
                            //     }, size: 24),
                            //     Text(
                            //       lang.getText(entry.value),
                            //       style: TextStyle(
                            //         fontSize: 8,
                            //         fontWeight: FontWeight.bold,
                            //         color: Colors.white38,
                            //       ),
                            //     ),
                            //   ],
                            // ),
                          ),
                        ),
                      )),
                    ],
                  ),

                  CustomSeparator(),

                  // added meals
                  Container(
                    child: userMeals.value.isEmpty
                        ? Center(
                            child: Column(
                              children: [
                                Text(
                                  lang.getText("no_added_meal_yet"),
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: userMeals.value.length,
                            itemBuilder: (context, index) {
                              final meal = userMeals.value[index];
                              final cleanName = stripHtmlTags(meal.name);
                              return Container(
                                margin: EdgeInsets.only(
                                  bottom: index != userMeals.value.length - 1
                                      ? 12
                                      : 0,
                                ),
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(25),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cleanName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${meal.qCalories} kcal | ${meal.qProtein.toStringAsFixed(3)} g ${lang.getText("protein")} | ${meal.qCarbs.toStringAsFixed(3)} g ${lang.getText("carbs")} | ${meal.qFat.toStringAsFixed(3)} g ${lang.getText("fat")} | ${meal.quantity.toStringAsFixed(0)} ${lang.getText("piece(s)")} | ${meal.baseWeight} ${meal.unit}',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Center(
                                      child: TextButton(
                                        onPressed: () => {
                                          userMeals.value = userMeals.value
                                              .where((x) => x != meal)
                                              .toList(),
                                        },
                                        child: Text(
                                          lang.getText("delete"),
                                          style: TextStyle(
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),

                  CustomSeparator(),

                  // summary card
                  CustomCard(
                    title: lang.getText("summary"),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Stack(
                              children: [
                                Text(
                                  '${lang.getText("calories")}: $userCaloriesSum kcal',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        Row(
                          children: [
                            Stack(
                              children: [
                                Text(
                                  '${lang.getText("protein")}: ${userProteinsSum.toStringAsFixed(3)} g',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        Row(
                          children: [
                            Stack(
                              children: [
                                Text(
                                  '${lang.getText("carbs")}: ${userCarbsSum.toStringAsFixed(3)} g',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        Row(
                          children: [
                            Stack(
                              children: [
                                Text(
                                  '${lang.getText("fat")}: ${userFatSum.toStringAsFixed(3)} g',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Center(
                    child: Text(
                      lang.getText("my_templates"),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  Builder(
                    builder: (context) {
                      if (customMeals.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (customMeals.isError) {
                        return Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            "Hiba történt: ${customMeals.error}",
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      }

                      final meals = customMeals.data ?? [];

                      if (meals.isEmpty) {
                        return Center(
                          child: Text(
                            lang.getText("no_added_template_yet"),
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: meals.length,
                        itemBuilder: (context, index) {
                          final meal = meals[index];

                          return GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return StatefulBuilder(
                                    builder: (context, setStateDialog) {
                                      return Dialog(
                                        insetPadding: const EdgeInsets.all(20),
                                        backgroundColor: const Color.fromARGB(
                                          255,
                                          30,
                                          30,
                                          30,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: const Color.fromARGB(
                                              255,
                                              40,
                                              40,
                                              40,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            border: Border.all(
                                              color: Colors.white24,
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                meal.customName.isNotEmpty
                                                    ? meal.customName
                                                    : lang.getText(
                                                        "unknown_template",
                                                      ),
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
                                                  itemCount: meal.meals.length,
                                                  itemBuilder: (context, i) {
                                                    final item = meal.meals[i];
                                                    final cleanName =
                                                        stripHtmlTags(
                                                          item.name,
                                                        );

                                                    return Container(
                                                      width: double.infinity,
                                                      margin:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 3,
                                                            horizontal: 4,
                                                          ),
                                                      padding:
                                                          const EdgeInsets.all(
                                                            12,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            const Color.fromARGB(
                                                              255,
                                                              30,
                                                              30,
                                                              30,
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                        border: Border.all(
                                                          color: Colors.white24,
                                                        ),
                                                      ),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            "$cleanName (${item.quantity})",
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            height: 6,
                                                          ),
                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                child: Text(
                                                                  '${item.qCalories.toStringAsFixed(3)} kcal',
                                                                  style: const TextStyle(
                                                                    color: Colors
                                                                        .white70,
                                                                  ),
                                                                ),
                                                              ),
                                                              Expanded(
                                                                child: Text(
                                                                  '${item.qProtein.toStringAsFixed(3)} g ${lang.getText("protein")}',
                                                                  style: const TextStyle(
                                                                    color: Colors
                                                                        .white70,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                child: Text(
                                                                  '${item.qCarbs.toStringAsFixed(3)} g ${lang.getText("carbs")}',
                                                                  style: const TextStyle(
                                                                    color: Colors
                                                                        .white70,
                                                                  ),
                                                                ),
                                                              ),
                                                              Expanded(
                                                                child: Text(
                                                                  '${item.qFat.toStringAsFixed(3)} g ${lang.getText("fat")}',
                                                                  style: const TextStyle(
                                                                    color: Colors
                                                                        .white70,
                                                                  ),
                                                                ),
                                                              ),
                                                              showDelete.value
                                                                  ? Padding(
                                                                      padding: EdgeInsets.only(
                                                                        right:
                                                                            10,
                                                                      ),
                                                                      child: IconButton(
                                                                        onPressed: () async {
                                                                          final itemToDelete =
                                                                              meal.meals[i];
                                                                          final ok = await deleteMealFromTemplate(
                                                                            itemToDelete.Id!,
                                                                          );

                                                                          if (ok) {
                                                                            setStateDialog(() {
                                                                              meal.meals.removeWhere(
                                                                                (
                                                                                  m,
                                                                                ) =>
                                                                                    m.Id ==
                                                                                    itemToDelete.Id,
                                                                              );
                                                                            });
                                                                            ScaffoldMessenger.of(
                                                                              context,
                                                                            ).showSnackBar(
                                                                              SnackBar(
                                                                                content: Text(
                                                                                  lang.getText(
                                                                                    "meal_deleted",
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            );
                                                                          } else {
                                                                            ScaffoldMessenger.of(
                                                                              context,
                                                                            ).showSnackBar(
                                                                              SnackBar(
                                                                                content: Text(
                                                                                  lang.getText(
                                                                                    "deletion_failed",
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            );
                                                                          }
                                                                        },

                                                                        icon: Icon(
                                                                          CupertinoIcons
                                                                              .trash,
                                                                          color:
                                                                              Colors.red,
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

                                              Center(
                                                child: ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.white,
                                                        foregroundColor:
                                                            Colors.black,
                                                      ),
                                                  onPressed: () async {
                                                    try {
                                                      final prefs =
                                                          await SharedPreferences.getInstance();
                                                      print(prefs);
                                                      final userId = prefs
                                                          .getInt('userId');
                                                      if (userId == null) {
                                                        throw Exception(
                                                          lang.getText(
                                                            "no_userId",
                                                          ),
                                                        );
                                                      }

                                                      await saveTemplateAsUserMeal(
                                                        meal,
                                                        userId,
                                                      );

                                                      ScaffoldMessenger.of(
                                                        // ignore: use_build_context_synchronously
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            lang.getText(
                                                              "saved_successfully",
                                                            ),
                                                          ),
                                                          behavior:
                                                              SnackBarBehavior
                                                                  .floating,
                                                          margin:
                                                              EdgeInsets.only(
                                                                bottom: 30,
                                                                left: 16,
                                                                right: 16,
                                                              ),
                                                          duration: Duration(
                                                            milliseconds: 1800,
                                                          ),
                                                          animation:
                                                              CurvedAnimation(
                                                                parent:
                                                                    kAlwaysCompleteAnimation,
                                                                curve: Curves
                                                                    .easeInOut,
                                                              ),
                                                        ),
                                                      );
                                                    } catch (e) {
                                                      ScaffoldMessenger.of(
                                                        // ignore: use_build_context_synchronously
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            "Hiba: $e",
                                                          ),
                                                          behavior:
                                                              SnackBarBehavior
                                                                  .floating,
                                                          margin:
                                                              EdgeInsets.only(
                                                                bottom: 30,
                                                                left: 16,
                                                                right: 16,
                                                              ),
                                                          duration: Duration(
                                                            milliseconds: 1800,
                                                          ),
                                                          animation:
                                                              CurvedAnimation(
                                                                parent:
                                                                    kAlwaysCompleteAnimation,
                                                                curve: Curves
                                                                    .easeInOut,
                                                              ),
                                                        ),
                                                      );
                                                    }
                                                    if (debounce
                                                            .value
                                                            ?.isActive ??
                                                        false) {
                                                      debounce.value?.cancel();
                                                    }
                                                    debounce.value = Timer(
                                                      const Duration(
                                                        milliseconds: 1500,
                                                      ),
                                                      () {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).hideCurrentSnackBar();
                                                        Navigator.push<
                                                          List<MealDto>
                                                        >(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                const Pages(),
                                                          ),
                                                        );
                                                      },
                                                    );
                                                  },
                                                  child: Text(
                                                    lang.getText(
                                                      "save_as_meal",
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Center(
                                                child: ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.white,
                                                        foregroundColor:
                                                            Colors.black,
                                                      ),
                                                  onPressed: () async {
                                                    showDelete.value = true;
                                                  },
                                                  child: Text(
                                                    lang.getText("edit"),
                                                  ),
                                                ),
                                              ),
                                              Center(
                                                child: ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.white,
                                                        foregroundColor:
                                                            Colors.black,
                                                      ),
                                                  onPressed: () async {
                                                    final result =
                                                        await Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                AddMealPage(
                                                                  addToTemplate:
                                                                      true,
                                                                  templateId:
                                                                      meal.id,
                                                                ),
                                                          ),
                                                        );

                                                    if (result != null &&
                                                        result
                                                            is List<MealDto> &&
                                                        result.isNotEmpty) {
                                                      setStateDialog(() {
                                                        meal.meals.addAll(
                                                          result,
                                                        );
                                                      });
                                                    }
                                                  },
                                                  child: Text(
                                                    lang.getText("add"),
                                                  ),
                                                ),
                                              ),
                                              Center(
                                                child: ElevatedButton(
                                                  onPressed: () {
                                                    userMeals.value = [
                                                      ...userMeals.value,
                                                      ...meal.meals,
                                                    ];

                                                    Navigator.pop(context);
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          "${meal.customName} ${lang.getText("added_to_list")}",
                                                        ),
                                                        duration:
                                                            const Duration(
                                                              milliseconds:
                                                                  1500,
                                                            ),
                                                        behavior:
                                                            SnackBarBehavior
                                                                .floating,
                                                      ),
                                                    );
                                                  },
                                                  style: FilledButton.styleFrom(
                                                    backgroundColor:
                                                        const Color.fromARGB(
                                                          255,
                                                          30,
                                                          30,
                                                          30,
                                                        ),
                                                    side: const BorderSide(
                                                      color: Colors.white24,
                                                      width: 1,
                                                    ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    lang.getText(
                                                      "continue_meal",
                                                    ),
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                              showDelete.value = false;
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(25),
                                borderRadius: BorderRadius.circular(16),
                                // border: Border.all(color: Colors.white24),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      meal.customName.isNotEmpty
                                          ? meal.customName
                                          : lang.getText("unknown_template"),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${meal.totalCalories} kcal | ${meal.totalProtein.toStringAsFixed(3)} g ${lang.getText("protein")} | ${meal.totalCarbs.toStringAsFixed(3)} g ${lang.getText("carbs")} | ${meal.totalFat.toStringAsFixed(3)} g ${lang.getText("fat")}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.redAccent,
                                          ),
                                          onPressed: () async {
                                            final confirmed = await showDialog<bool>(
                                              context: context,
                                              builder: (context) => Dialog(
                                                backgroundColor:
                                                    const Color.fromARGB(
                                                      255,
                                                      30,
                                                      30,
                                                      30,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  side: const BorderSide(
                                                    color: Colors.white24,
                                                  ),
                                                ),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                    20,
                                                  ),
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        lang.getText("delete"),
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 22,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 16,
                                                      ),
                                                      Text(
                                                        "${lang.getText("sure_delete_template")}\n'${meal.customName}'?",
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: const TextStyle(
                                                          color: Colors.white70,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 24,
                                                      ),
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceEvenly,
                                                        children: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                  context,
                                                                  false,
                                                                ),
                                                            style: TextButton.styleFrom(
                                                              foregroundColor:
                                                                  Colors
                                                                      .white54,
                                                            ),
                                                            child: Text(
                                                              lang.getText(
                                                                "cancel",
                                                              ),
                                                              style: const TextStyle(
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                          FilledButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                  context,
                                                                  true,
                                                                ),
                                                            style: FilledButton.styleFrom(
                                                              backgroundColor:
                                                                  Colors
                                                                      .redAccent,
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      12,
                                                                    ),
                                                              ),
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        20,
                                                                    vertical:
                                                                        10,
                                                                  ),
                                                            ),
                                                            child: Text(
                                                              lang.getText(
                                                                "delete",
                                                              ),
                                                              style: const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 16,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );

                                            if (confirmed == true) {
                                              final success =
                                                  await deleteUserMealTemplate(
                                                    meal.id,
                                                  );

                                              if (success) {
                                                meals.removeAt(index);

                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        lang.getText(
                                                          "deleted_successfully",
                                                        ),
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      showCloseIcon: true,
                                                      closeIconColor:
                                                          Colors.white70,
                                                      behavior: SnackBarBehavior
                                                          .floating,
                                                      backgroundColor:
                                                          const Color.fromARGB(
                                                            255,
                                                            45,
                                                            45,
                                                            45,
                                                          ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                        side: const BorderSide(
                                                          color: Colors.white24,
                                                          width: 1,
                                                        ),
                                                      ),
                                                      margin:
                                                          const EdgeInsets.only(
                                                            bottom: 30,
                                                            left: 16,
                                                            right: 16,
                                                          ),
                                                      duration: const Duration(
                                                        milliseconds: 1800,
                                                      ),
                                                      animation: CurvedAnimation(
                                                        parent:
                                                            kAlwaysCompleteAnimation,
                                                        curve: Curves.easeInOut,
                                                      ),
                                                    ),
                                                  );
                                                }
                                              }
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
    bottomNavigationBar: SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                // color: Colors.white.withAlpha(25),
                padding: const EdgeInsets.all(24).copyWith(top: 24),
                child: Row(
                  spacing: 12,
                  children: [
                    Expanded(
                      child: CustomButton(
                        onPressed: () async {
                          final result = await Navigator.push<List<MealDto>>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddMealPage(),
                            ),
                          );
                          if (result != null) {
                            userMeals.value = [...userMeals.value, ...result];
                          }
                        },
                        title: lang.getText("add"),
                        iconData: Icons.add_rounded,
                      ),
                    ),

                    Expanded(
                      child: CustomButton(
                        onPressed: () async {
                          if (userMeals.value.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  lang.getText("no_meals_selected"),
                                ),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return Dialog(
                                insetPadding: const EdgeInsets.all(20),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(
                                      255,
                                      40,
                                      40,
                                      40,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          lang.getText("save_sample"),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Stack(
                                          children: [
                                            Container(
                                              width: double.infinity,
                                              height: null,
                                              margin: const EdgeInsets.fromLTRB(
                                                0,
                                                20,
                                                0,
                                                20,
                                              ),
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                    0,
                                                    0,
                                                    5,
                                                    5,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color.fromARGB(
                                                  255,
                                                  72,
                                                  72,
                                                  72,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: TextField(
                                                cursorColor: Colors.white,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                ),
                                                controller: mealNameController,
                                                decoration: InputDecoration(
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                        borderSide:
                                                            const BorderSide(
                                                              color: Colors
                                                                  .transparent,
                                                              width: 2,
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                        borderSide:
                                                            const BorderSide(
                                                              color: Colors
                                                                  .transparent,
                                                              width: 1,
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                ),
                                                keyboardType:
                                                    TextInputType.text,
                                              ),
                                            ),

                                            Positioned(
                                              top:
                                                  MediaQuery.of(
                                                    context,
                                                  ).size.height *
                                                  0.01,
                                              left:
                                                  MediaQuery.of(
                                                    context,
                                                  ).size.width *
                                                  0.04,
                                              child: Text(
                                                lang.getText("sample_name"),
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            FilledButton(
                                              onPressed: () async {
                                                try {
                                                  final prefs =
                                                      await SharedPreferences.getInstance();
                                                  final userId = prefs.getInt(
                                                    'userId',
                                                  );
                                                  if (userId == null) {
                                                    throw Exception(
                                                      lang.getText(
                                                        "no_userId_found",
                                                      ),
                                                    );
                                                  }

                                                  await saveUserMeals(
                                                    userMeals.value,
                                                    _mealTypes[mealIndex.value],
                                                    userId,
                                                  );

                                                  ScaffoldMessenger.of(
                                                    // ignore: use_build_context_synchronously
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        lang.getText(
                                                          "saved_successfully",
                                                        ),
                                                      ),
                                                      showCloseIcon: true,
                                                      behavior: SnackBarBehavior
                                                          .floating,
                                                      margin: EdgeInsets.only(
                                                        bottom: 30,
                                                        left: 16,
                                                        right: 16,
                                                      ),
                                                      duration: Duration(
                                                        milliseconds: 1800,
                                                      ),
                                                      animation: CurvedAnimation(
                                                        parent:
                                                            kAlwaysCompleteAnimation,
                                                        curve: Curves.easeInOut,
                                                      ),
                                                    ),
                                                  );
                                                } catch (e) {
                                                  ScaffoldMessenger.of(
                                                    // ignore: use_build_context_synchronously
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text("Hiba: $e"),
                                                      backgroundColor:
                                                          Colors.red,
                                                      behavior: SnackBarBehavior
                                                          .floating,
                                                      margin: EdgeInsets.only(
                                                        bottom: 30,
                                                        left: 16,
                                                        right: 16,
                                                      ),
                                                      duration: Duration(
                                                        milliseconds: 1800,
                                                      ),
                                                      animation: CurvedAnimation(
                                                        parent:
                                                            kAlwaysCompleteAnimation,
                                                        curve: Curves.easeInOut,
                                                      ),
                                                    ),
                                                  );
                                                  return;
                                                }
                                                if (debounce.value?.isActive ??
                                                    false) {
                                                  debounce.value?.cancel();
                                                }
                                                debounce.value = Timer(
                                                  const Duration(
                                                    milliseconds: 1500,
                                                  ),
                                                  () {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).hideCurrentSnackBar();
                                                    Navigator.push<
                                                      List<MealDto>
                                                    >(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            const Pages(),
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                              style: FilledButton.styleFrom(
                                                backgroundColor:
                                                    const Color.fromARGB(
                                                      255,
                                                      85,
                                                      173,
                                                      78,
                                                    ),
                                                fixedSize: Size(
                                                  MediaQuery.of(
                                                        context,
                                                      ).size.width *
                                                      0.36,
                                                  MediaQuery.of(
                                                        context,
                                                      ).size.height *
                                                      0.07,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(11),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                    ),
                                              ),
                                              child: Text(
                                                lang.getText(
                                                  "save_without_sample",
                                                ),
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),

                                            FilledButton(
                                              onPressed: () async {
                                                if (mealNameController.text
                                                    .trim()
                                                    .isEmpty) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        lang.getText(
                                                          "name_the_template",
                                                        ),
                                                      ),
                                                      behavior: SnackBarBehavior
                                                          .floating,
                                                      backgroundColor:
                                                          Colors.red,
                                                    ),
                                                  );
                                                  return;
                                                }

                                                final newName =
                                                    mealNameController.text
                                                        .trim();

                                                final bool isDuplicate =
                                                    (customMeals.data ?? []).any(
                                                      (template) =>
                                                          template.customName
                                                              .trim()
                                                              .toLowerCase() ==
                                                          newName.toLowerCase(),
                                                    );

                                                if (isDuplicate) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        lang.getText(
                                                          'duplicate_template',
                                                        ),
                                                      ),
                                                      behavior: SnackBarBehavior
                                                          .floating,
                                                      backgroundColor:
                                                          Colors.red,
                                                    ),
                                                  );
                                                  return;
                                                }

                                                try {
                                                  final prefs =
                                                      await SharedPreferences.getInstance();
                                                  final userId = prefs.getInt(
                                                    'userId',
                                                  );
                                                  if (userId == null) {
                                                    throw Exception(
                                                      lang.getText(
                                                        "no_userId_found",
                                                      ),
                                                    );
                                                  }

                                                  await saveUserMealsS(
                                                    userMeals.value,
                                                    mealNameController.text,
                                                    userId,
                                                  );

                                                  ScaffoldMessenger.of(
                                                    // ignore: use_build_context_synchronously
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        lang.getText(
                                                          "saved_successfully",
                                                        ),
                                                      ),
                                                      showCloseIcon: true,
                                                      behavior: SnackBarBehavior
                                                          .floating,
                                                      margin: EdgeInsets.only(
                                                        bottom: 30,
                                                        left: 16,
                                                        right: 16,
                                                      ),
                                                      duration: Duration(
                                                        milliseconds: 1800,
                                                      ),
                                                      animation: CurvedAnimation(
                                                        parent:
                                                            kAlwaysCompleteAnimation,
                                                        curve: Curves.easeInOut,
                                                      ),
                                                    ),
                                                  );
                                                } catch (e) {
                                                  ScaffoldMessenger.of(
                                                    // ignore: use_build_context_synchronously
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text("Hiba: $e"),
                                                      behavior: SnackBarBehavior
                                                          .floating,
                                                      margin: EdgeInsets.only(
                                                        bottom: 30,
                                                        left: 16,
                                                        right: 16,
                                                      ),
                                                      duration: Duration(
                                                        milliseconds: 1800,
                                                      ),
                                                      animation: CurvedAnimation(
                                                        parent:
                                                            kAlwaysCompleteAnimation,
                                                        curve: Curves.easeInOut,
                                                      ),
                                                    ),
                                                  );
                                                  return;
                                                }
                                                if (debounce.value?.isActive ??
                                                    false) {
                                                  debounce.value?.cancel();
                                                }
                                                debounce.value = Timer(
                                                  const Duration(
                                                    milliseconds: 1500,
                                                  ),
                                                  () {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).hideCurrentSnackBar();
                                                    Navigator.push<
                                                      List<MealDto>
                                                    >(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            const Pages(),
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                              style: FilledButton.styleFrom(
                                                backgroundColor:
                                                    const Color.fromARGB(
                                                      255,
                                                      85,
                                                      173,
                                                      78,
                                                    ),
                                                fixedSize: Size(
                                                  MediaQuery.of(
                                                        context,
                                                      ).size.width *
                                                      0.36,
                                                  MediaQuery.of(
                                                        context,
                                                      ).size.height *
                                                      0.07,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(11),
                                                ),
                                              ),
                                              child: Text(
                                                lang.getText("save"),
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        title: lang.getText("continue"),
                        iconData: Icons.skip_next_rounded,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
