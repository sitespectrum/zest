import 'dart:ui';
import 'package:client/components/drawers/recent_m_drawer.dart';
import 'package:client/providers/language_provider.dart';
import 'package:client/components/drawers/recent_w_drawer.dart';
import 'package:client/models/workout.dart';
import 'package:client/providers/workout_provider.dart';
import 'package:flutter/material.dart';
import 'package:client/utils/scroll_behavior.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:client/models/meal.dart';
import 'add_meal_page.dart';
import 'package:intl/intl.dart';
import 'package:client/components/ui/custom_card.dart';
import 'package:client/constants.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future<double> fetchCalorieGoal() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');
  if (token == null) return 3000.0;

  final cacheBox = Hive.box('cacheBox');
  const cacheKey = 'calorie_goal';

  var connectivityResult = await Connectivity().checkConnectivity();
  if (!connectivityResult.contains(ConnectivityResult.none)) {
    try {
      final response = await http.get(
        Uri.parse("$apiUrl/api/auth/getUser"),
        headers: {"Authorization": "Bearer $token"},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final goal = data['calorieGoal'] ?? data['CalorieGoal'];
        final goalDouble = (goal as num).toDouble();
        cacheBox.put(cacheKey, goalDouble);
        return goalDouble;
      }
    } catch (e) {
      debugPrint("Szerver hiba, olvasás cache-ből...");
    }
  }

  final cachedData = cacheBox.get(cacheKey);
  if (cachedData != null) return (cachedData as num).toDouble();
  return 3000.0;
}

Future<List<UserMealDto>> fetchUserMeals() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');
  if (token == null) return [];

  final cacheBox = Hive.box('cacheBox');
  const cacheKey = 'user_meals';

  var connectivityResult = await Connectivity().checkConnectivity();
  if (!connectivityResult.contains(ConnectivityResult.none)) {
    try {
      final response = await http.get(
        Uri.parse("$apiUrl/api/meals/getUserMeals"),
        headers: {"Authorization": "Bearer $token"},
      );
      if (response.statusCode == 200) {
        cacheBox.put(cacheKey, response.body);
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => UserMealDto.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint("Szerver hiba, olvasás cache-ből...");
    }
  }

  final cachedData = cacheBox.get(cacheKey);
  if (cachedData != null) {
    final List<dynamic> data = jsonDecode(cachedData);
    return data.map((e) => UserMealDto.fromJson(e)).toList();
  }
  return [];
}

Future<List<UserWorkoutDto>> fetchUserWorkouts() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');
  if (token == null) return [];

  final cacheBox = Hive.box('cacheBox');
  const cacheKey = 'user_workouts';

  var connectivityResult = await Connectivity().checkConnectivity();
  if (!connectivityResult.contains(ConnectivityResult.none)) {
    try {
      final response = await http.get(
        Uri.parse("$apiUrl/api/workout/getUserWorkouts"),
        headers: {"Authorization": "Bearer $token"},
      );
      if (response.statusCode == 200) {
        cacheBox.put(cacheKey, response.body);
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => UserWorkoutDto.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint("Szerver hiba, olvasás cache-ből...");
    }
  }

  final cachedData = cacheBox.get(cacheKey);
  if (cachedData != null) {
    final List<dynamic> data = jsonDecode(cachedData);
    return data.map((e) => UserWorkoutDto.fromJson(e)).toList();
  }
  return [];
}

Future<double> fetchTodayCalories() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');
  if (token == null) return 0.0;

  final cacheBox = Hive.box('cacheBox');
  const cacheKey = 'today_calories';

  var connectivityResult = await Connectivity().checkConnectivity();
  if (!connectivityResult.contains(ConnectivityResult.none)) {
    try {
      final response = await http.get(
        Uri.parse("$apiUrl/api/meals/getTodayCalories"),
        headers: {"Authorization": "Bearer $token"},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final calDouble = (data as num).toDouble();
        cacheBox.put(cacheKey, calDouble);
        return calDouble;
      }
    } catch (e) {
      debugPrint("Szerver hiba, olvasás cache-ből...");
    }
  }

  final cachedData = cacheBox.get(cacheKey);
  if (cachedData != null) return (cachedData as num).toDouble();
  return 0.0;
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
  late Future<List<UserWorkoutDto>> _futureWorkouts;
  bool _isDrawerOpen = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _futureMeals = fetchUserMeals();
      _todaycalories = fetchTodayCalories();
      _calorieGoal = fetchCalorieGoal();
      _futureWorkouts = fetchUserWorkouts();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
    final langCode = Provider.of<LanguageProvider>(context).languageCode;
    final String locale = lang.languageCode == 'hu' ? 'hu_HU' : 'en_US';
    final workoutProvider = Provider.of<WorkoutProvider>(
      context,
      listen: false,
    );
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () async => _refreshData(),
        child: ScrollConfiguration(
          behavior: NoGlowScrollBehavior(),
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PreferredSize(
                  preferredSize: const Size.fromHeight(60),
                  child: Container(
                    margin: const EdgeInsets.all(6),
                    child: AppBar(
                      title: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: ClipRect(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                              sigmaX: 10.0,
                              sigmaY: 10.0,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color.fromRGBO(45, 45, 45, 0.5),
                              ),
                              child: Text(
                                lang.getText("home_page"),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      automaticallyImplyLeading: false,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                ),

                Container(
                  margin: EdgeInsets.only(left: 8, right: 8, top: 40),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: FutureBuilder<List<dynamic>>(
                    future: Future.wait([
                      _todaycalories,
                      _calorieGoal,
                      _futureMeals,
                    ]),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text("Hiba: ${snapshot.error}"));
                      }

                      final double currentCalories =
                          (snapshot.data?[0] as double?) ?? 0.0;
                      final double targetCalories =
                          (snapshot.data?[1] as double?) ?? 3000.0;
                      final List<UserMealDto> meals =
                          (snapshot.data?[2] as List<UserMealDto>?) ?? [];

                      double totalProtein = 0;
                      double totalCarbs = 0;
                      double totalFat = 0;

                      final now = DateTime.now();
                      for (var meal in meals) {
                        if (meal.eatenAt.year == now.year &&
                            meal.eatenAt.month == now.month &&
                            meal.eatenAt.day == now.day) {
                          totalProtein += meal.totalProtein;
                          totalCarbs += meal.totalCarbs;
                          totalFat += meal.totalFat;
                        }
                      }

                      double proteinKcal = totalProtein * 4;
                      double carbsKcal = totalCarbs * 4;
                      double fatKcal = totalFat * 9;

                      double totalEatenKcal = proteinKcal + carbsKcal + fatKcal;
                      double remainingKcal = (targetCalories - totalEatenKcal)
                          .clamp(0.0, targetCalories);

                      final double percentage = (targetCalories > 0)
                          ? (currentCalories / targetCalories) * 100
                          : 0.0;

                      const Color colorProtein = Colors.blue;
                      const Color colorCarbs = Colors.orange;
                      const Color colorFat = Colors.pink;
                      final Color colorEmpty = Colors.grey.shade800;

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 15),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              RichText(
                                text: TextSpan(
                                  text: currentCalories.toStringAsFixed(0),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  children: [
                                    TextSpan(
                                      text:
                                          " / ${targetCalories.toStringAsFixed(0)} kcal",
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 25,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              height: 40,
                              child: Row(
                                children: [
                                  Flexible(
                                    flex: (proteinKcal * 100).toInt(),
                                    fit: FlexFit.tight,
                                    child: Container(color: colorProtein),
                                  ),
                                  Flexible(
                                    flex: (carbsKcal * 100).toInt(),
                                    fit: FlexFit.tight,
                                    child: Container(color: colorCarbs),
                                  ),
                                  Flexible(
                                    flex: (fatKcal * 100).toInt(),
                                    fit: FlexFit.tight,
                                    child: Container(color: colorFat),
                                  ),
                                  Flexible(
                                    flex: (remainingKcal * 100).toInt(),
                                    fit: FlexFit.tight,
                                    child: Container(color: colorEmpty),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              _buildLegendItem(
                                colorProtein,
                                lang.getText("protein"),
                              ),
                              SizedBox(width: 25),
                              _buildLegendItem(
                                colorCarbs,
                                lang.getText("carbs"),
                              ),
                              SizedBox(width: 25),
                              _buildLegendItem(colorFat, lang.getText("fat")),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),

                FutureBuilder<List<UserWorkoutDto>>(
                  future: _futureWorkouts,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        height: 100,
                        margin: const EdgeInsets.all(20),
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    }

                    final workouts = snapshot.data ?? [];
                    final lastWorkout = workouts.isNotEmpty
                        ? (workouts..sort((a, b) => b.date.compareTo(a.date)))
                              .first
                        : null;

                    return CustomCard(
                      title: lang.getText("recent_workout"),
                      iconData: Icons.fitness_center,
                      child: SizedBox(
                        width: double.infinity,
                        child: lastWorkout == null
                            ? Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  lang.getText("no_added_workout_yet"),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () async {
                                  if (_isDrawerOpen) return;
                                  _isDrawerOpen = true;
                                  int currentWorkoutNum = 1;
                                  try {
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    final token = prefs.getString('jwt_token');
                                    final response = await http.get(
                                      Uri.parse(
                                        "$apiUrl/api/workouts/getUserWorkouts",
                                      ),
                                      headers: {
                                        "Authorization": "Bearer $token",
                                      },
                                    );
                                    if (response.statusCode == 200) {
                                      List data = jsonDecode(response.body);
                                      currentWorkoutNum = data.length + 1;
                                    }
                                  } catch (e) {
                                    debugPrint(
                                      "Nem sikerült lekérni az edzések számát: $e",
                                    );
                                  }

                                  showModalBottomSheet(
                                    isScrollControlled: true,
                                    elevation: 0,
                                    context: context,
                                    builder: (builderContext) {
                                      return RecentWDrawer(
                                        lastWorkout,
                                        currentWorkoutNum,
                                        lang,
                                        workoutProvider,
                                      );
                                    },
                                  );
                                  _isDrawerOpen = false;
                                },
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          lastWorkout.workoutName.isEmpty
                                              ? lastWorkout.customName
                                              : getTranslatedName(
                                                  lastWorkout.workoutName,
                                                  lang,
                                                ),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          "${lang.getText("duration")}: ${lastWorkout.durationMinutes} ${lang.getText("min")}",
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          "${lang.getText("burnt_calories")}: ${lastWorkout.totalBurntCalories} kcal",
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(8),
                                      child: const Icon(
                                        Icons.arrow_forward,
                                        color: Colors.black,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    );
                  },
                ),
                FutureBuilder<List<UserMealDto>>(
                  future: _futureMeals,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(height: 50);
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          "Hiba: ${snapshot.error}",
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    final meals = snapshot.data ?? [];
                    final lastMeal = meals.isNotEmpty
                        ? (meals..sort(
                                (a, b) => b.eatenAt.compareTo(a.eatenAt),
                              ))
                              .first
                        : null;

                    String formattedDate = '';
                    if (lastMeal != null) {
                      formattedDate = DateFormat.Hm().format(lastMeal.eatenAt);
                    }

                    return CustomCard(
                      title: lang.getText("recent_meal"),
                      iconData: Icons.restaurant,
                      child: SizedBox(
                        width: double.infinity,
                        child: lastMeal == null
                            ? Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  lang.getText("no_added_meal_yet"),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return RecentMDrawer(lastMeal, lang);
                                    },
                                  );
                                },
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "${getTranslatedName(lastMeal.mealName, lang)} ($formattedDate)",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          "${lang.getText("calories")}: ${lastMeal.totalCalories.toStringAsFixed(0)} kcal",
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          "${lang.getText("protein")}: ${lastMeal.totalProtein.toStringAsFixed(1)} g",
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(8),
                                      child: const Icon(
                                        Icons.arrow_forward,
                                        color: Colors.black,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    );
                  },
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.13),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildLegendItem(Color color, String label) {
  return Row(
    children: [
      Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(5),
        ),
      ),
      const SizedBox(width: 5),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    ],
  );
}
