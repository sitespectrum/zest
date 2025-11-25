import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../models/meal.dart';
import 'add_meal_page.dart';
import '../constants.dart';

class HealthPage extends StatefulWidget {
  const HealthPage({super.key});

  @override
  State<HealthPage> createState() => _HealthPageState();
}

Future<List<UserMealDto>> fetchUserMeals() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');

  if (token == null) throw Exception("Nincs token");

  final response = await http.get(
    Uri.parse("$apiUrl/api/meals/getUserMeals"), // s || l
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

Future<Map<String, double>> fetchMacroGoals() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');
  if (token == null) throw Exception("Nincs token");

  final response = await http.get(
    Uri.parse("$apiUrl/api/auth/getUser"),
    headers: {"Authorization": "Bearer $token"},
  );
  print("szia, ${response.body}");

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return {
      'carbsGoal': (data['carbsGoal'] as num).toDouble(),
      'fatGoal': (data['fatGoal'] as num).toDouble(),
      'proteinGoal': (data['proteinGoal'] as num).toDouble(),
    };
  } else {
    throw Exception("Nem sikerült lekérni a tápanyagokat: ${response.body}");
  }
}

Future<Map<String, double>> fetchTodayNutrients() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');
  if (token == null) throw Exception("Nincs token");

  final response = await http.get(
    Uri.parse("$apiUrl/api/Meals/getTodayNutrients"), // s || l
    headers: {"Authorization": "Bearer $token"},
  );
  print("szia, ${response.body}");

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return {
      'calories': (data['totalcalories'] as num).toDouble(),
      'carbs': (data['totalcarbs'] as num).toDouble(),
      'fat': (data['totalfat'] as num).toDouble(),
      'protein': (data['totalprotein'] as num).toDouble(),
    };
  } else {
    throw Exception("Nem sikerült lekérni a tápanyagokat: ${response.body}");
  }
}

class _HealthPageState extends State<HealthPage>
    with AutomaticKeepAliveClientMixin {
  String? username;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<String, double>? nutrients;
  Map<String, double>? macros;
  late Future<List<UserMealDto>> _futureMeals;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadUser();
    initializeDateFormatting('hu_HU', null);
    loadNutrients();
    loadMacros();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setState(() {
      _futureMeals = fetchUserMeals();
    });
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString("username");
    });
  }

  void loadNutrients() async {
    try {
      final fetched = await fetchTodayNutrients();
      setState(() {
        nutrients = fetched;
      });
    } catch (e) {
      print("Hiba a fetchnél: $e");
    }
  }

  void loadMacros() async {
    try {
      final fetched = await fetchMacroGoals();
      setState(() {
        macros = fetched;
      });
    } catch (e) {
      print("Hiba a fetchnél: $e");
    }
  }

  Map<DateTime, List<UserMealDto>> groupMealsByDay(List<UserMealDto> meals) {
    final Map<DateTime, List<UserMealDto>> grouped = {};
    for (var meal in meals) {
      final d = DateTime(
        meal.eatenAt.year,
        meal.eatenAt.month,
        meal.eatenAt.day,
      );
      grouped.putIfAbsent(d, () => []);
      grouped[d]!.add(meal);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final appTitle = "Egészség";

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

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Container(
                  margin: const EdgeInsets.all(6),
                  child: AppBar(
                    title: Text(
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

              //Naptár
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
                    child: TableCalendar(
                      locale: 'hu_HU',
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) =>
                          isSameDay(_selectedDay, day),
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                        leftChevronIcon: const Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                        ),
                        rightChevronIcon: const Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                        ),
                      ),
                      calendarStyle: CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: Color.fromARGB(255, 58, 58, 58),
                          shape: BoxShape.circle,
                        ),
                        defaultTextStyle: const TextStyle(color: Colors.white),
                        weekendTextStyle: const TextStyle(color: Colors.white),
                      ),
                      onDaySelected: (selectedDay, focusedDay) async {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });

                        final allMeals = await fetchUserMeals();
                        final grouped = groupMealsByDay(allMeals);

                        final int window = 30;
                        final DateTime startDate = DateTime(
                          selectedDay.year,
                          selectedDay.month,
                          selectedDay.day,
                        ).subtract(Duration(days: window));
                        final List<DateTime> days = List.generate(
                          window * 2 + 1,
                          (i) => startDate.add(Duration(days: i)),
                        );
                        final int initialPage = window;

                        if (!context.mounted) return;

                        showDialog(
                          context: context,
                          builder: (context) {
                            final PageController controller = PageController(
                              initialPage: initialPage,
                            );
                            return Dialog(
                              insetPadding: const EdgeInsets.all(15),
                              backgroundColor: const Color.fromARGB(
                                255,
                                40,
                                40,
                                40,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(color: Colors.white24),
                              ),
                              child: SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.65,
                                width: double.infinity,
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: PageView.builder(
                                        controller: controller,
                                        itemCount: days.length,
                                        onPageChanged: (page) {
                                          final DateTime newDay = days[page];
                                          setState(() {
                                            _selectedDay = newDay;
                                            _focusedDay = newDay;
                                          });
                                        },
                                        itemBuilder: (context, index) {
                                          final DateTime day = days[index];
                                          final List<UserMealDto> mealsForDay =
                                              grouped[day] ?? [];

                                          return Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Column(
                                              children: [
                                                Text(
                                                  "${day.year}.${day.month}.${day.day}",
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                Expanded(
                                                  child: mealsForDay.isEmpty
                                                      ? Center(
                                                          child: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: const [
                                                              Icon(
                                                                Icons
                                                                    .calendar_month,
                                                                size: 56,
                                                                color: Colors
                                                                    .white24,
                                                              ),
                                                              SizedBox(
                                                                height: 8,
                                                              ),
                                                              Text(
                                                                "Ezen a napon nincs adat",
                                                                style: TextStyle(
                                                                  color: Colors
                                                                      .white70,
                                                                  fontSize: 16,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        )
                                                      : ListView.builder(
                                                          itemCount: mealsForDay
                                                              .length,
                                                          itemBuilder: (context, i) {
                                                            final meal =
                                                                mealsForDay[i];
                                                            final cleanName =
                                                                stripHtmlTags(
                                                                  meal.mealName ??
                                                                      "Ismeretlen étel",
                                                                );

                                                            return Container(
                                                              margin:
                                                                  const EdgeInsets.symmetric(
                                                                    vertical: 6,
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
                                                                      10,
                                                                    ),
                                                                border: Border.all(
                                                                  color: Colors
                                                                      .white24,
                                                                ),
                                                              ),
                                                              child: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Text(
                                                                    cleanName,
                                                                    style: const TextStyle(
                                                                      color: Colors
                                                                          .white,
                                                                      fontSize:
                                                                          16,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                    height: 6,
                                                                  ),
                                                                  Text(
                                                                    "${meal.totalCalories.toStringAsFixed(2)} kcal  |  ${meal.totalProtein.toStringAsFixed(2)}g fehérje  |  ${meal.totalCarbs.toStringAsFixed(2)}g szénhidrát  |  ${meal.totalFat.toStringAsFixed(2)}g zsír",
                                                                    style: const TextStyle(
                                                                      color: Colors
                                                                          .white70,
                                                                      fontSize:
                                                                          13,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: FilledButton(
                                        onPressed: () => Navigator.pop(context),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: const Color.fromARGB(
                                            255,
                                            30,
                                            30,
                                            30,
                                          ),
                                          side: const BorderSide(
                                            color: Colors.white24,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
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
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.005,
                    left: MediaQuery.of(context).size.width * 0.09,
                    child: Text(
                      "Korábbi étkezések",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              //Bevitt tápanyagok
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
                    child: nutrients == null
                        ? Center(child: CircularProgressIndicator())
                        : Stack(
                            children: [
                              Column(
                                children: [
                                  Row(
                                    children: [
                                      Stack(
                                        children: [
                                          Text(
                                            'Kalória: ${nutrients!['calories']!.toStringAsFixed(0)} kcal \n',
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
                                          LinearPercentIndicator(
                                            width:
                                                MediaQuery.of(
                                                  context,
                                                ).size.width *
                                                0.5,
                                            animation: true,
                                            animationDuration: 1000,
                                            lineHeight: 20.0,
                                            leading: Text(
                                              "Fehérje:",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            percent: min(
                                              (nutrients!['protein']! /
                                                      macros!['proteinGoal']!)
                                                  .toDouble(),
                                              1.0,
                                            ),
                                            center: Text(
                                              "${nutrients!['protein']!.toStringAsFixed(0)} g / ${macros!['proteinGoal']!.toStringAsFixed(0)} g ${macros!['proteinGoal']! <= nutrients!['protein']! && nutrients!['protein']! <= macros!['proteinGoal']! + 50
                                                  ? "✅"
                                                  : nutrients!['protein']! > macros!['proteinGoal']! + 50
                                                  ? "😡"
                                                  : ""}",
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                            progressColor: Colors.blue,
                                            backgroundColor: Color.fromRGBO(
                                              58,
                                              58,
                                              58,
                                              1,
                                            ),
                                            barRadius: const Radius.circular(
                                              12,
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
                                          LinearPercentIndicator(
                                            width:
                                                MediaQuery.of(
                                                  context,
                                                ).size.width *
                                                0.5,
                                            animation: true,
                                            animationDuration: 1000,
                                            lineHeight: 20.0,
                                            leading: Text(
                                              "Szénhidrát:",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            percent: min(
                                              (nutrients!['carbs']! /
                                                      macros!['carbsGoal']!)
                                                  .toDouble(),
                                              1.0,
                                            ),
                                            center: Text(
                                              "${nutrients!['carbs']!.toStringAsFixed(0)} g / ${macros!['carbsGoal']!.toStringAsFixed(0)} g ${macros!['carbsGoal']! <= nutrients!['carbs']! && nutrients!['carbs']! <= macros!['carbsGoal']! + 30
                                                  ? "✅"
                                                  : nutrients!['carbs']! > macros!['carbsGoal']! + 30
                                                  ? "😡"
                                                  : ""}",
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                            progressColor: Colors.orange,
                                            backgroundColor: Color.fromRGBO(
                                              58,
                                              58,
                                              58,
                                              1,
                                            ),
                                            barRadius: const Radius.circular(
                                              12,
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
                                          LinearPercentIndicator(
                                            width:
                                                MediaQuery.of(
                                                  context,
                                                ).size.width *
                                                0.5,
                                            animation: true,
                                            animationDuration: 1000,
                                            lineHeight: 20.0,
                                            leading: Text(
                                              "Zsír:",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            percent: min(
                                              (nutrients!['fat']! /
                                                      macros!['fatGoal']!)
                                                  .toDouble(),
                                              1.0,
                                            ),
                                            center: Text(
                                              "${nutrients!['fat']!.toStringAsFixed(0)} g / ${macros!['fatGoal']!.toStringAsFixed(0)} g ${macros!['fatGoal']! <= nutrients!['fat']! && nutrients!['fat']! <= macros!['fatGoal']! + 20
                                                  ? "✅"
                                                  : nutrients!['fat']! > macros!['fatGoal']! + 20
                                                  ? "😡"
                                                  : ""}",
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                            progressColor: Colors.pink,
                                            backgroundColor: Color.fromRGBO(
                                              58,
                                              58,
                                              58,
                                              1,
                                            ),
                                            barRadius: const Radius.circular(
                                              12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.005,
                    left: MediaQuery.of(context).size.width * 0.09,
                    child: Text(
                      "Bevitt tápanyagok",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  SizedBox(height: MediaQuery.of(context).size.height * 0.40),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
