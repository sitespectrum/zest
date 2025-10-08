import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meal.dart';

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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<UserMealDto>> _futureMeals;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setState(() {
      _futureMeals = fetchUserMeals();
    });
  }

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
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: lastMeal == null
                      ? const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'Nincsenek hozzáadott ételek',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Legutóbbi étkezés: ${lastMeal.mealName}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Kalória: ${lastMeal.calories.toStringAsFixed(0)} kcal",
                                  style: const TextStyle(color: Colors.white),
                                ),
                                Text(
                                  "Fehérje: ${lastMeal.protein.toStringAsFixed(1)} g",
                                  style: const TextStyle(color: Colors.white),
                                ),
                                Text(
                                  "Szénhidrát: ${lastMeal.carbs.toStringAsFixed(1)} g",
                                  style: const TextStyle(color: Colors.white),
                                ),
                                Text(
                                  "Zsír: ${lastMeal.fat.toStringAsFixed(1)} g",
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),

                            Padding(
                              padding: EdgeInsets.only(
                                top: MediaQuery.of(context).size.height * 0.040,
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
