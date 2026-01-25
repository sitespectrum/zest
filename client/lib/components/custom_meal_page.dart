import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zest_client/constants.dart';
import 'package:zest_client/models/meal.dart';
import 'package:zest_client/pages.dart';
import 'package:zest_client/providers/language_provider.dart';

import 'add_meal_page.dart';

class CMealPage extends StatefulWidget {
  final DateTime selectedDay;
  const CMealPage({super.key, required this.selectedDay});

  @override
  State<CMealPage> createState() => _CMealPageState();
}

final mealtypecontroller = TextEditingController();
final mealnamecontroller = TextEditingController();

class _CMealPageState extends State<CMealPage> {
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
      "EatenAt": widget.selectedDay.toIso8601String(),
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
      "CustomName": mealnamecontroller.text,
      "UserId": userId,
      "EatenAt": widget.selectedDay.toIso8601String(),
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

  // ignore: non_constant_identifier_names
  Future<void> UserMealsSampleSave(
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
      "EatenAt": widget.selectedDay.toIso8601String(),
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
    await UserMealsSampleSave(template.meals, template.customName, userId);
  }

  List<MealDto> userMeals = [];
  int mealindex = 4;
  bool showdelete = false;
  final List _mealtypes = ["Reggeli", "Ebéd", "Vacsora", "Egyéb"];
  int get userCaloriesSum =>
      userMeals.fold<int>(0, (sum, meal) => sum + meal.qCalories);
  double get userProteinsSum =>
      userMeals.fold<double>(0.0, (sum, meal) => sum + meal.qProtein);
  double get userCarbsSum =>
      userMeals.fold<double>(0, (sum, meal) => sum + meal.qCarbs);
  double get userFatSum =>
      userMeals.fold<double>(0, (sum, meal) => sum + meal.qFat);
  Timer? _debounce;
  late Future<List<CustomUserMealDto>> futureCustomMeals;

  @override
  void initState() {
    super.initState();
    futureCustomMeals = fetchCustomUserMeals().catchError((e) {
      return <CustomUserMealDto>[];
    });
  }

  Future<List<CustomUserMealDto>> fetchCustomUserMeals() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    if (token == null) throw Exception("Nincs token");

    final response = await http.get(
      Uri.parse("$apiUrl/api/meals/getCustomUserMeals"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => CustomUserMealDto.fromJson(e)).toList();
    } else {
      throw Exception(
        "${lang.getText("failed_to_fetch_meals")} ${response.body}",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, userMeals);
        return false;
      },
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(2, 6, 2, 0),
                  child: AppBar(
                    title: Text(
                      lang.getText("new_meal"),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    iconTheme: const IconThemeData(color: Colors.white),
                  ),
                ),
              ),
              Center(
                child: Container(
                  margin: EdgeInsets.all(20),
                  width: double.infinity,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Stack(
                            children: [
                              FilledButton(
                                onPressed: () {
                                  setState(() {
                                    mealindex = 0;
                                  });
                                  mealtypecontroller.text =
                                      _mealtypes[mealindex];
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: mealindex == 0
                                      ? const Color.fromARGB(255, 85, 173, 78)
                                      : const Color.fromARGB(255, 45, 45, 45),
                                  fixedSize: Size(
                                    MediaQuery.of(context).size.width * 0.41,
                                    MediaQuery.of(context).size.height * 0.07,
                                  ),
                                  elevation: 8,
                                  // ignore: deprecated_member_use
                                  shadowColor: Colors.black.withOpacity(0.8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(11),
                                    side: const BorderSide(
                                      color: Colors.white24,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Text(lang.getText("breakfast")),
                              ),
                            ],
                          ),

                          SizedBox(width: 20),

                          Stack(
                            children: [
                              FilledButton(
                                onPressed: () {
                                  setState(() {
                                    mealindex = 1;
                                  });
                                  mealtypecontroller.text =
                                      _mealtypes[mealindex];
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: mealindex == 1
                                      ? const Color.fromARGB(255, 85, 173, 78)
                                      : const Color.fromARGB(255, 45, 45, 45),
                                  fixedSize: Size(
                                    MediaQuery.of(context).size.width * 0.41,
                                    MediaQuery.of(context).size.height * 0.07,
                                  ),
                                  elevation: 8,
                                  // ignore: deprecated_member_use
                                  shadowColor: Colors.black.withOpacity(0.8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(11),
                                    side: const BorderSide(
                                      color: Colors.white24,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Text(lang.getText("lunch")),
                              ),
                            ],
                          ),
                        ],
                      ),

                      SizedBox(height: 20),

                      Row(
                        children: [
                          Stack(
                            children: [
                              FilledButton(
                                onPressed: () {
                                  setState(() {
                                    mealindex = 2;
                                  });
                                  mealtypecontroller.text =
                                      _mealtypes[mealindex];
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: mealindex == 2
                                      ? const Color.fromARGB(255, 85, 173, 78)
                                      : const Color.fromARGB(255, 45, 45, 45),
                                  fixedSize: Size(
                                    MediaQuery.of(context).size.width * 0.41,
                                    MediaQuery.of(context).size.height * 0.07,
                                  ),
                                  elevation: 8,
                                  // ignore: deprecated_member_use
                                  shadowColor: Colors.black.withOpacity(0.8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(11),
                                    side: const BorderSide(
                                      color: Colors.white24,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Text(lang.getText("dinner")),
                              ),
                            ],
                          ),

                          SizedBox(width: 20),

                          Stack(
                            children: [
                              FilledButton(
                                onPressed: () {
                                  setState(() {
                                    mealindex = 3;
                                  });
                                  mealtypecontroller.text =
                                      _mealtypes[mealindex];
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: mealindex == 3
                                      ? const Color.fromARGB(255, 85, 173, 78)
                                      : const Color.fromARGB(255, 45, 45, 45),
                                  fixedSize: Size(
                                    MediaQuery.of(context).size.width * 0.41,
                                    MediaQuery.of(context).size.height * 0.07,
                                  ),
                                  elevation: 8,
                                  // ignore: deprecated_member_use
                                  shadowColor: Colors.black.withOpacity(0.8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(11),
                                    side: const BorderSide(
                                      color: Colors.white24,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Text(lang.getText("other")),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              Container(
                child: userMeals.isEmpty
                    ? Center(
                        child: Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                lang.getText("no_added_meal_yet"),
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: userMeals.length,
                        itemBuilder: (context, index) {
                          final meal = userMeals[index];
                          final cleanName = stripHtmlTags(meal.name);
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 6,
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 45, 45, 45),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white24),
                                  boxShadow: [
                                    BoxShadow(
                                      // ignore: deprecated_member_use
                                      color: Colors.black.withOpacity(0.5),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cleanName,
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
                                            setState(() {
                                              userMeals.remove(meal);
                                            }),
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
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),

              SizedBox(height: 20),

              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 45, 45, 45),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                      boxShadow: [
                        BoxShadow(
                          // ignore: deprecated_member_use
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
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
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.006,
                    left: MediaQuery.of(context).size.width * 0.09,
                    child: Text(
                      lang.getText("summary"),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),

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

              FutureBuilder<List<CustomUserMealDto>>(
                future: futureCustomMeals,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        "Hiba történt: ${snapshot.error}",
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  final meals = snapshot.data ?? [];

                  if (meals.isEmpty) {
                    return Center(
                      child: Text(
                        lang.getText("no_added_template_yet"),
                        style: TextStyle(color: Colors.white70, fontSize: 18),
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
                                      borderRadius: BorderRadius.circular(16),
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
                                        borderRadius: BorderRadius.circular(16),
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
                                                final cleanName = stripHtmlTags(
                                                  item.name,
                                                );

                                                return Container(
                                                  width: double.infinity,
                                                  margin:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 3,
                                                        horizontal: 4,
                                                      ),
                                                  padding: const EdgeInsets.all(
                                                    12,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: const Color.fromARGB(
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
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              '${item.qCalories.toStringAsFixed(3)} kcal',
                                                              style:
                                                                  const TextStyle(
                                                                    color: Colors
                                                                        .white70,
                                                                  ),
                                                            ),
                                                          ),
                                                          Expanded(
                                                            child: Text(
                                                              '${item.qProtein.toStringAsFixed(3)} g ${lang.getText("protein")}',
                                                              style:
                                                                  const TextStyle(
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
                                                              style:
                                                                  const TextStyle(
                                                                    color: Colors
                                                                        .white70,
                                                                  ),
                                                            ),
                                                          ),
                                                          Expanded(
                                                            child: Text(
                                                              '${item.qFat.toStringAsFixed(3)} g ${lang.getText("fat")}',
                                                              style:
                                                                  const TextStyle(
                                                                    color: Colors
                                                                        .white70,
                                                                  ),
                                                            ),
                                                          ),
                                                          showdelete
                                                              ? Padding(
                                                                  padding:
                                                                      EdgeInsets.only(
                                                                        right:
                                                                            10,
                                                                      ),
                                                                  child: IconButton(
                                                                    onPressed: () async {
                                                                      final itemToDelete =
                                                                          meal.meals[i];
                                                                      final ok = await deleteMealFromTemplate(
                                                                        itemToDelete
                                                                            .Id!,
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
                                                                      color: Colors
                                                                          .red,
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

                                          Center(
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.white,
                                                foregroundColor: Colors.black,
                                              ),
                                              onPressed: () async {
                                                try {
                                                  final prefs =
                                                      await SharedPreferences.getInstance();
                                                  print(prefs);
                                                  final userId = prefs.getInt(
                                                    'userId',
                                                  );
                                                  if (userId == null) {
                                                    throw Exception(
                                                      lang.getText("no_userId"),
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
                                                }
                                                if (_debounce?.isActive ??
                                                    false) {
                                                  _debounce!.cancel();
                                                }
                                                _debounce = Timer(
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
                                                lang.getText("save_as_meal"),
                                              ),
                                            ),
                                          ),
                                          Center(
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.white,
                                                foregroundColor: Colors.black,
                                              ),
                                              onPressed: () async {
                                                setStateDialog(() {
                                                  showdelete = true;
                                                });
                                              },
                                              child: Text(lang.getText("edit")),
                                            ),
                                          ),
                                          Center(
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.white,
                                                foregroundColor: Colors.black,
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
                                                    result is List<MealDto> &&
                                                    result.isNotEmpty) {
                                                  setStateDialog(() {
                                                    meal.meals.addAll(result);
                                                  });
                                                }
                                              },
                                              child: Text(lang.getText("add")),
                                            ),
                                          ),
                                          Center(
                                            child: ElevatedButton(
                                              onPressed: () {
                                                setState(() {
                                                  userMeals.addAll(meal.meals);
                                                });
                                                Navigator.pop(context);
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      "${meal.customName} ${lang.getText("added_to_list")}",
                                                    ),
                                                    duration: const Duration(
                                                      milliseconds: 1500,
                                                    ),
                                                    behavior: SnackBarBehavior
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
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                              child: Text(
                                                lang.getText("continue_meal"),
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
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
                          setState(() {
                            showdelete = false;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 6,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 45, 45, 45),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white24),
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
                                  const SizedBox(height: 6),
                                  Text(
                                    '${meal.totalCalories} kcal | ${meal.totalProtein.toStringAsFixed(3)} g ${lang.getText("protein")} | ${meal.totalCarbs.toStringAsFixed(3)} g ${lang.getText("carbs")} | ${meal.totalFat.toStringAsFixed(3)} g ${lang.getText("fat")}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
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
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FilledButton(
                onPressed: () async {
                  final result = await Navigator.push<List<MealDto>>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddMealPage(),
                    ),
                  );

                  if (result != null) {
                    setState(() {
                      userMeals.addAll(result);
                    });
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 85, 173, 78),
                  fixedSize: Size(
                    MediaQuery.of(context).size.width * 0.41,
                    MediaQuery.of(context).size.height * 0.07,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                child: Text(
                  lang.getText("add"),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              FilledButton(
                onPressed: () async {
                  if (userMeals.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(lang.getText("no_meals_selected")),
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
                            color: const Color.fromARGB(255, 40, 40, 40),
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
                                      padding: const EdgeInsets.fromLTRB(
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
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: TextField(
                                        cursorColor: Colors.white,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                        ),
                                        controller: mealnamecontroller,
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: Colors.transparent,
                                              width: 2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: Colors.transparent,
                                              width: 1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        keyboardType: TextInputType.text,
                                      ),
                                    ),

                                    Positioned(
                                      top:
                                          MediaQuery.of(context).size.height *
                                          0.01,
                                      left:
                                          MediaQuery.of(context).size.width *
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
                                          final userId = prefs.getInt('userId');
                                          if (userId == null) {
                                            throw Exception(
                                              lang.getText("no_userId_found"),
                                            );
                                          }

                                          await saveUserMeals(
                                            userMeals,
                                            _mealtypes[mealindex],
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
                                              behavior:
                                                  SnackBarBehavior.floating,
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
                                              backgroundColor: Colors.red,
                                              behavior:
                                                  SnackBarBehavior.floating,
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
                                        if (_debounce?.isActive ?? false) {
                                          _debounce!.cancel();
                                        }
                                        _debounce = Timer(
                                          const Duration(milliseconds: 1500),
                                          () {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).hideCurrentSnackBar();
                                            Navigator.push<List<MealDto>>(
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
                                        backgroundColor: const Color.fromARGB(
                                          255,
                                          85,
                                          173,
                                          78,
                                        ),
                                        fixedSize: Size(
                                          MediaQuery.of(context).size.width *
                                              0.36,
                                          MediaQuery.of(context).size.height *
                                              0.07,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            11,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                        ),
                                      ),
                                      child: Text(
                                        lang.getText("save_without_sample"),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),

                                    FilledButton(
                                      onPressed: () async {
                                        if (mealnamecontroller.text
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
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          return;
                                        }
                                        try {
                                          final prefs =
                                              await SharedPreferences.getInstance();
                                          final userId = prefs.getInt('userId');
                                          if (userId == null) {
                                            throw Exception(
                                              lang.getText("no_userId_found"),
                                            );
                                          }

                                          await saveUserMealsS(
                                            userMeals,
                                            mealnamecontroller.text,
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
                                              behavior:
                                                  SnackBarBehavior.floating,
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
                                              behavior:
                                                  SnackBarBehavior.floating,
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
                                        if (_debounce?.isActive ?? false) {
                                          _debounce!.cancel();
                                        }
                                        _debounce = Timer(
                                          const Duration(milliseconds: 1500),
                                          () {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).hideCurrentSnackBar();
                                            Navigator.push<List<MealDto>>(
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
                                        backgroundColor: const Color.fromARGB(
                                          255,
                                          85,
                                          173,
                                          78,
                                        ),
                                        fixedSize: Size(
                                          MediaQuery.of(context).size.width *
                                              0.36,
                                          MediaQuery.of(context).size.height *
                                              0.07,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            11,
                                          ),
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
                style: FilledButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 85, 173, 78),
                  fixedSize: Size(
                    MediaQuery.of(context).size.width * 0.41,
                    MediaQuery.of(context).size.height * 0.07,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                child: Text(
                  lang.getText("continue"),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
