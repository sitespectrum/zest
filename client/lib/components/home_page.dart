import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meal.dart';
import 'add_meal_page.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

Future<List<UserMealDto>> fetchUserMeals() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');

  if (token == null) throw Exception("Nincs token");

  final response = await http.get(
    Uri.parse("http://10.169.236.110:5031/api/Meals/getUserMeals"),
    headers: {"Authorization": "Bearer $token"},
  );

  print("RESPONSE BODY: ${response.body}");

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    print('szia, $token');
    return data.map((e) => UserMealDto.fromJson(e)).toList();
  } else {
    throw Exception("Nem sikerült lekérni az étkezéseket: ${response.body}");
  }
}

Future<double> fetchTodayCalories() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');
  if (token == null) throw Exception("Nincs token");

  final response = await http.get(
    Uri.parse("http://10.169.236.110:5031/api/Meals/getTodayCalories"),
    headers: {"Authorization": "Bearer $token"},
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    print("szia, ${data}");
    return (data as num).toDouble();
  } else {
    throw Exception("Nem sikerült lekérni az étkezéseket: ${response.body}");
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<UserMealDto>> _futureMeals;
  late Future<double> _todaycalories;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setState(() {
      _futureMeals = fetchUserMeals();
      _todaycalories = fetchTodayCalories();
    });
  }

  final colorList = <Color>[Color.fromRGBO(78, 156, 71, 1)];

  @override
  Widget build(BuildContext context) {
    const appTitle = "Főoldal";

    return FutureBuilder<List<UserMealDto>>(
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
          formattedDate = DateFormat(
            'yyyy-MM-dd HH:mm:ss',
          ).format(lastMeal.eatenAt);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                margin: const EdgeInsets.all(6),
                child: AppBar(
                  title: const Text(
                    appTitle,
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
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: FutureBuilder<double>(
                    future: _todaycalories,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            "Hiba: ${snapshot.error}",
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      }

                      final calories = snapshot.data ?? 0.0;
                      const targetCalories = 3000.0;
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
                            "${calories.toStringAsFixed(0)} / 3000 kcal",
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
                    "Kalóriadeficit",
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
                    "Legutóbbi edzés",
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
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'Nincsenek hozzáadott ételek',
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
                              print("Meals hossza: ${lastMeal.meals.length}");
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
                                        lastMeal.mealName,
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
                                            final meal = lastMeal.meals[index];
                                            final cleanName = stripHtmlTags(
                                              meal.name ?? "Ismeretlen étel",
                                            );

                                            return Container(
                                              width: double.infinity,
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 3,
                                                    horizontal: 4,
                                                  ),
                                              padding: const EdgeInsets.all(12),
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
                                                    "${cleanName} (${meal.quantity})",
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
                                                        MainAxisAlignment.start,
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
                                                          '${meal.qProtein.toStringAsFixed(3)} g protein',
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
                                                          '${meal.qCarbs.toStringAsFixed(3)} g szénhidrát',
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .white70,
                                                              ),
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: Text(
                                                          '${meal.qFat.toStringAsFixed(3)} g zsír',
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
                                            "Bezárás",
                                            style: TextStyle(color: Colors.red),
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
                                    "${lastMeal.mealName} - ${formattedDate}",
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
                                    "Kalória: ${lastMeal.totalCalories.toStringAsFixed(0)} kcal",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                  ),
                                  Text(
                                    "Fehérje: ${lastMeal.totalProtein.toStringAsFixed(1)} g",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                  ),
                                  Text(
                                    "Szénhidrát: ${lastMeal.totalCarbs.toStringAsFixed(1)} g",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                  ),
                                  Text(
                                    "Zsír: ${lastMeal.totalFat.toStringAsFixed(1)} g",
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
                    "Legutóbbi étkezés",
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
    );
  }
}
