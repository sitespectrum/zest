import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_meal_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:client/models/meal.dart';
import 'dart:async';
import 'package:client/pages.dart';
import '../constants.dart';

class CMealPage extends StatefulWidget {
  const CMealPage({super.key});

  @override
  State<CMealPage> createState() => _CMealPageState();
}

class UserMealDto {
  final String mealName;
  final String foodId;
  final DateTime eatenAt;

  UserMealDto({
    required this.mealName,
    required this.foodId,
    required this.eatenAt,
  });

  Map<String, dynamic> toJson() {
    return {
      "mealName": mealName,
      "foodId": foodId,
      "eatenAt": eatenAt.toIso8601String(),
    };
  }
}

final mealtypecontroller = TextEditingController();

Future<void> saveUserMeals(
  List<MealDto> meals,
  String mealName,
  int userId,
) async {
  final totalCalories = meals.fold<int>(0, (sum, meal) => sum + meal.calories);
  final totalProtein = meals.fold<double>(
    0.0,
    (sum, meal) => sum + meal.protein,
  );
  final totalCarbs = meals.fold<double>(0.0, (sum, meal) => sum + meal.carbs);
  final totalFat = meals.fold<double>(0.0, (sum, meal) => sum + meal.fat);
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');

  if (token == null || token.isEmpty) throw Exception("Nincs token.");

  final uri = Uri.parse("$apiUrl/api/Meals/addGroup"); // s || l

  final dto = {
    "MealName": mealName,
    "UserId": userId,
    "EatenAt": DateTime.now().toIso8601String(),
    "Meals": meals.map((m) => m.toJson()).toList(),
    "TotalCalories": totalCalories,
    "TotalProtein": totalProtein,
    "TotalCarbs": totalCarbs,
    "TotalFat": totalFat,
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
      "Nem sikerült menteni: ${response.statusCode} ${response.body}",
    );
  }
}

class _CMealPageState extends State<CMealPage> {
  List<MealDto> userMeals = [];
  int mealindex = 4;
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

  @override
  Widget build(BuildContext context) {
    const appTitle = "Új étkezés";
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
                    title: const Text(
                      appTitle,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: const Color.fromARGB(255, 58, 58, 58),
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
                                child: Text("Reggeli"),
                                style: FilledButton.styleFrom(
                                  backgroundColor: mealindex == 0
                                      ? const Color.fromARGB(255, 85, 173, 78)
                                      : const Color.fromARGB(255, 45, 45, 45),
                                  fixedSize: Size(
                                    MediaQuery.of(context).size.width * 0.41,
                                    MediaQuery.of(context).size.height * 0.07,
                                  ),
                                  elevation: 8,
                                  shadowColor: Colors.black.withOpacity(0.8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(11),
                                    side: const BorderSide(
                                      color: Colors.white24,
                                      width: 1,
                                    ),
                                  ),
                                ),
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
                                child: Text("Ebéd"),
                                style: FilledButton.styleFrom(
                                  backgroundColor: mealindex == 1
                                      ? const Color.fromARGB(255, 85, 173, 78)
                                      : const Color.fromARGB(255, 45, 45, 45),
                                  fixedSize: Size(
                                    MediaQuery.of(context).size.width * 0.41,
                                    MediaQuery.of(context).size.height * 0.07,
                                  ),
                                  elevation: 8,
                                  shadowColor: Colors.black.withOpacity(0.8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(11),
                                    side: const BorderSide(
                                      color: Colors.white24,
                                      width: 1,
                                    ),
                                  ),
                                ),
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
                                child: Text("Vacsora"),
                                style: FilledButton.styleFrom(
                                  backgroundColor: mealindex == 2
                                      ? const Color.fromARGB(255, 85, 173, 78)
                                      : const Color.fromARGB(255, 45, 45, 45),
                                  fixedSize: Size(
                                    MediaQuery.of(context).size.width * 0.41,
                                    MediaQuery.of(context).size.height * 0.07,
                                  ),
                                  elevation: 8,
                                  shadowColor: Colors.black.withOpacity(0.8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(11),
                                    side: const BorderSide(
                                      color: Colors.white24,
                                      width: 1,
                                    ),
                                  ),
                                ),
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
                                child: Text("Egyéb"),
                                style: FilledButton.styleFrom(
                                  backgroundColor: mealindex == 3
                                      ? const Color.fromARGB(255, 85, 173, 78)
                                      : const Color.fromARGB(255, 45, 45, 45),
                                  fixedSize: Size(
                                    MediaQuery.of(context).size.width * 0.41,
                                    MediaQuery.of(context).size.height * 0.07,
                                  ),
                                  elevation: 8,
                                  shadowColor: Colors.black.withOpacity(0.8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(11),
                                    side: const BorderSide(
                                      color: Colors.white24,
                                      width: 1,
                                    ),
                                  ),
                                ),
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
                            const Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                'Nincsenek hozzáadott ételek',
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
                          final cleanName = stripHtmlTags(
                            meal.name ?? "Ismeretlen étel",
                          );
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
                                              '${meal.qCalories} kcal | ${meal.qProtein.toStringAsFixed(3)} g protein | ${meal.qCarbs.toStringAsFixed(3)} g szénhidrát | ${meal.qFat.toStringAsFixed(3)} g zsír | ${meal.quantity.toStringAsFixed(0)} darab | ${meal.baseWeight} ${meal.unit}',
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
                                          child: const Text(
                                            "Törlés",
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

              Container(
                child: Stack(
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
                                    'Kalória: ${userCaloriesSum} kcal',
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
                                    'Fehérje: ${userProteinsSum.toStringAsFixed(3)} g',
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
                                    'Szénhidrát: ${userCarbsSum.toStringAsFixed(3)} g',
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
                                    'Zsír: ${userFatSum.toStringAsFixed(3)} g',
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
                        "Összegzés",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
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
                child: const Text(
                  'Hozzáadás',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              FilledButton(
                onPressed: () async {
                  try {
                    final prefs = await SharedPreferences.getInstance();
                    final userId = prefs.getInt('userId');
                    if (userId == null)
                      throw Exception("Nincs userId a gépen.");

                    await saveUserMeals(
                      userMeals,
                      _mealtypes[mealindex],
                      userId,
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Sikeresen mentve!"),
                        showCloseIcon: true,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text("Hiba: $e")));
                  }
                  if (_debounce?.isActive ?? false) _debounce!.cancel();
                  _debounce = Timer(const Duration(milliseconds: 1500), () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    Navigator.push<List<MealDto>>(
                      context,
                      MaterialPageRoute(builder: (context) => const Pages()),
                    );
                  });
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
                child: const Text(
                  'Mentés',
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
