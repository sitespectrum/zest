import 'package:client/Providers/language_provider.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meal.dart';
import 'add_meal_page.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../constants.dart';

Future<double> fetchCalorieGoal() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');
  if (token == null) throw Exception("Nincs token");

  final response = await http.get(
    Uri.parse("$apiUrl/api/auth/getUser"),
    headers: {"Authorization": "Bearer $token"},
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final goal = data['calorieGoal'] ?? data['CalorieGoal'];
    return (goal as num).toDouble();
  } else {
    throw Exception(response.body);
  }
}

Future<List<UserMealDto>> fetchUserMeals() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');

  if (token == null) throw Exception("Nincs token");

  final response = await http.get(
    Uri.parse("$apiUrl/api/meals/getUserMeals"),
    headers: {"Authorization": "Bearer $token"},
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((e) => UserMealDto.fromJson(e)).toList();
  } else {
    throw Exception(response.body);
  }
}

Future<double> fetchTodayCalories() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');
  if (token == null) throw Exception("Nincs token");

  final response = await http.get(
    Uri.parse("$apiUrl/api/meals/getTodayCalories"),
    headers: {"Authorization": "Bearer $token"},
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return (data as num).toDouble();
  } else {
    throw Exception(response.body);
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  late Future<List<UserMealDto>> _futureMeals;
  late Future<double> _todaycalories;
  late Future<double> _calorieGoal;

  @override
  bool get wantKeepAlive => false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setState(() {
      _futureMeals = fetchUserMeals();
      _todaycalories = fetchTodayCalories();
      _calorieGoal = fetchCalorieGoal();
    });
  }

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

  final colorList = <Color>[Color.fromRGBO(78, 156, 71, 1)];

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final String locale = lang.languageCode == 'hu' ? 'hu_HU' : 'en_US';
    super.build(context);

    return SingleChildScrollView(
      child: FutureBuilder<List<UserMealDto>>(
        future: _futureMeals,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                "Hiba történt: ${snapshot.error}",
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          final meals = snapshot.data ?? [];

          final lastMeal = meals.isNotEmpty
              ? (meals..sort((a, b) => b.eatenAt.compareTo(a.eatenAt))).first
              : null;

          String formattedDate = '';
          if (lastMeal != null) {
            formattedDate = DateFormat.yMd(
              locale,
            ).add_Hms().format(lastMeal.eatenAt);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Container(
                  margin: const EdgeInsets.all(6),
                  child: AppBar(
                    title: Text(
                      lang.getText("home_page"),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    automaticallyImplyLeading: false,
                    backgroundColor: Color.fromARGB(255, 58, 58, 58),
                  ),
                ),
              ),

              //Kalóriadeficit
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.30,
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
                    child: FutureBuilder<List<double>>(
                      future: Future.wait([_todaycalories, _calorieGoal]),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (snapshot.hasError) {
                          return Center(child: Text("Hiba: ${snapshot.error}"));
                        }

                        final calories = snapshot.data?[0] ?? 0.0;
                        final targetCalories = snapshot.data?[1] ?? 3000.0;
                        final percentage = (calories / targetCalories) * 100;

                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            PieChart(
                              PieChartData(
                                startDegreeOffset: 270,
                                sectionsSpace: 2,
                                centerSpaceRadius: 75,
                                sections: [
                                  PieChartSectionData(
                                    color: Color.fromRGBO(78, 156, 71, 1),
                                    value: calories,
                                    title: "${percentage.toStringAsFixed(1)}%",
                                    radius: 30,
                                    titleStyle: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  PieChartSectionData(
                                    color: Colors.grey.shade800,
                                    value: (targetCalories - calories).clamp(
                                      0,
                                      targetCalories,
                                    ),
                                    title: '',
                                    radius: 25,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              "${calories.toStringAsFixed(0)} / ${targetCalories.toStringAsFixed(0)} kcal",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.005,
                    left: MediaQuery.of(context).size.width * 0.09,
                    child: Text(
                      lang.getText("calorie_deficit"),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              //Legutóbbi edzés
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.18,
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
                  ),
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.005,
                    left: MediaQuery.of(context).size.width * 0.09,
                    child: Text(
                      lang.getText("recent_workout"),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              //Legutóbbi étkezés
              Stack(
                children: [
                  lastMeal == null
                      ? Container(
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
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              lang.getText("no_added_meal_yet"),
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        )
                      : GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
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
                                      border: Border.all(color: Colors.white24),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          getTranslatedName(
                                            lastMeal.mealName,
                                            lang,
                                          ),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Flexible(
                                          child: ListView.builder(
                                            shrinkWrap: true,
                                            itemCount: lastMeal.meals.length,
                                            itemBuilder: (context, index) {
                                              final meal =
                                                  lastMeal.meals[index];
                                              final cleanName = stripHtmlTags(
                                                meal.name,
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
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: Colors.white24,
                                                  ),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "$cleanName (${meal.quantity})",
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .start,
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            '${meal.qCalories.toStringAsFixed(3)} kcal',
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .white70,
                                                                ),
                                                          ),
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            '${meal.qProtein.toStringAsFixed(3)} g ${lang.getText("protein").toLowerCase()}',
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
                                                            '${meal.qCarbs.toStringAsFixed(3)} g ${lang.getText("carbs").toLowerCase()}',
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .white70,
                                                                ),
                                                          ),
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            '${meal.qFat.toStringAsFixed(3)} g ${lang.getText("fat").toLowerCase()}',
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .white70,
                                                                ),
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
                                        Positioned(
                                          child: FilledButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
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
                                              lang.getText("close"),
                                              style: TextStyle(
                                                color: Colors.red,
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
                          child: Container(
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${getTranslatedName(lastMeal.mealName, lang)} - $formattedDate",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize:
                                            MediaQuery.of(context).size.height *
                                            0.021,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "${lang.getText("calories")}: ${lastMeal.totalCalories.toStringAsFixed(0)} kcal",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                      ),
                                    ),
                                    Text(
                                      "${lang.getText("protein")}: ${lastMeal.totalProtein.toStringAsFixed(1)} g",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                      ),
                                    ),
                                    Text(
                                      "${lang.getText("carbs")}: ${lastMeal.totalCarbs.toStringAsFixed(1)} g",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                      ),
                                    ),
                                    Text(
                                      "${lang.getText("fat")}: ${lastMeal.totalFat.toStringAsFixed(1)} g",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),

                                Padding(
                                  padding: EdgeInsets.only(
                                    top:
                                        MediaQuery.of(context).size.height *
                                        0.055,
                                  ),
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.arrow_forward,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.005,
                    left: MediaQuery.of(context).size.width * 0.09,
                    child: Text(
                      lang.getText("recent_meal"),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
