import 'dart:ui';
import 'package:client/Providers/language_provider.dart';
import 'package:client/models/workout.dart';
import 'package:client/providers/workout_provider.dart';
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

class NoGlowScrollBehavior extends MaterialScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

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

Future<List<UserWorkoutDto>> fetchUserWorkouts() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');

  if (token == null) throw Exception("Nincs token");

  final response = await http.get(
    Uri.parse("$apiUrl/api/workout/getUserWorkouts"),
    headers: {"Authorization": "Bearer $token"},
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((e) => UserWorkoutDto.fromJson(e)).toList();
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
  late Future<List<UserWorkoutDto>> _futureWorkouts;

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
    final workoutProvider = Provider.of<WorkoutProvider>(context);
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ScrollConfiguration(
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
                          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
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

                    const Color colorProtein = Colors.red;
                    const Color colorCarbs = Colors.green;
                    const Color colorFat = Colors.blue;
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
                              "${totalProtein.toStringAsFixed(0)}g",
                            ),
                            SizedBox(width: 25),
                            _buildLegendItem(
                              colorCarbs,
                              lang.getText("carbs"),
                              "${totalCarbs.toStringAsFixed(0)}g",
                            ),
                            SizedBox(width: 25),
                            _buildLegendItem(
                              colorFat,
                              lang.getText("fat"),
                              "${totalFat.toStringAsFixed(0)}g",
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),

              Stack(
                children: [
                  FutureBuilder<List<UserWorkoutDto>>(
                    future: _futureWorkouts,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Container(
                          height: MediaQuery.of(context).size.height * 0.18,
                          margin: const EdgeInsets.all(20),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final workouts = snapshot.data ?? [];
                      final lastWorkout = workouts.isNotEmpty
                          ? (workouts..sort((a, b) => b.date.compareTo(a.date)))
                                .first
                          : null;

                      String formattedDate = '';
                      if (lastWorkout != null) {
                        formattedDate = DateFormat.yMd(
                          locale,
                        ).add_Hm().format(lastWorkout.date);
                      }

                      return Stack(
                        children: [
                          lastWorkout == null
                              ? Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.all(20),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 20.0,
                                        sigmaY: 20.0,
                                      ),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color.fromRGBO(
                                            45,
                                            45,
                                            45,
                                            0.5,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.all(20),
                                          child: Text(
                                            lang.getText(
                                              "no_added_workout_yet",
                                            ),
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : GestureDetector(
                                  onTap: () async {
                                    int currentWorkoutNum = 1;
                                    try {
                                      final prefs =
                                          await SharedPreferences.getInstance();
                                      final token = prefs.getString(
                                        'jwt_token',
                                      );
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

                                    showDialog(
                                      context: context,
                                      builder: (builderContext) {
                                        double calculatedVolume = 0;
                                        double calculatedDistance = 0;

                                        for (var ex in lastWorkout.exercises) {
                                          final isCardio =
                                              ex.exercise?.category
                                                  ?.toLowerCase() ==
                                              'cardio';
                                          for (var s in ex.sets) {
                                            if (isCardio) {
                                              calculatedDistance += s.weight;
                                            } else {
                                              calculatedVolume +=
                                                  s.weight * s.reps;
                                            }
                                          }
                                        }

                                        String headerValueText = "";
                                        String headerLabelText = "";

                                        if (calculatedVolume > 0 &&
                                            calculatedDistance > 0) {
                                          headerValueText =
                                              "${calculatedVolume.toInt()}kg + ${calculatedDistance.toStringAsFixed(1)}km";
                                          headerLabelText = lang.getText(
                                            "volume",
                                          );
                                        } else if (calculatedVolume > 0) {
                                          headerValueText =
                                              "${calculatedVolume.toInt()} kg";
                                          headerLabelText = lang.getText(
                                            "volume",
                                          );
                                        } else {
                                          headerValueText =
                                              "${calculatedDistance.toStringAsFixed(1)} km";
                                          headerLabelText = lang.getText(
                                            "distance",
                                          );
                                        }

                                        return PopScope(
                                          canPop: true,
                                          child: Dialog(
                                            insetPadding: const EdgeInsets.all(
                                              20,
                                            ),
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
                                            ),
                                            child: Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: const Color.fromARGB(
                                                  255,
                                                  40,
                                                  40,
                                                  40,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: Colors.white24,
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Center(
                                                    child: Text(
                                                      lastWorkout
                                                              .workoutName
                                                              .isEmpty
                                                          ? lastWorkout
                                                                .customName
                                                          : lastWorkout
                                                                .workoutName,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ),

                                                  const Divider(
                                                    color: Colors.white24,
                                                    height: 30,
                                                  ),

                                                  Row(
                                                    children: [
                                                      _buildStatCell(
                                                        "$currentWorkoutNum.",
                                                        isHeader: true,
                                                      ),
                                                      _buildStatCell(
                                                        "${lastWorkout.totalBurntCalories}",
                                                        isHeader: true,
                                                      ),
                                                      _buildStatCell(
                                                        "${lastWorkout.durationMinutes} ${lang.getText("min")}",
                                                        isHeader: true,
                                                      ),

                                                      Expanded(
                                                        child: Center(
                                                          child: Text(
                                                            headerValueText,
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 14,
                                                                ),
                                                            textAlign: TextAlign
                                                                .center,
                                                            maxLines: 2,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Row(
                                                    children: [
                                                      _buildStatCell(
                                                        lang.getText("workout"),
                                                        color: Colors.grey,
                                                      ),
                                                      _buildStatCell(
                                                        lang.getText(
                                                          "calories",
                                                        ),
                                                        color: Colors.grey,
                                                      ),
                                                      _buildStatCell(
                                                        lang.getText(
                                                          "duration",
                                                        ),
                                                        color: Colors.grey,
                                                      ),
                                                      _buildStatCell(
                                                        headerLabelText,
                                                        color: Colors.grey,
                                                      ),
                                                    ],
                                                  ),

                                                  const SizedBox(height: 15),

                                                  Builder(
                                                    builder: (context) {
                                                      final totalSets = lastWorkout
                                                          .exercises
                                                          .fold<int>(
                                                            0,
                                                            (sum, ex) =>
                                                                sum +
                                                                ex.sets
                                                                    .where(
                                                                      (s) => s
                                                                          .isCompleted,
                                                                    )
                                                                    .length,
                                                          );
                                                      final totalReps = lastWorkout
                                                          .exercises
                                                          .fold<int>(
                                                            0,
                                                            (sum, ex) =>
                                                                sum +
                                                                ex.sets
                                                                    .where(
                                                                      (s) => s
                                                                          .isCompleted,
                                                                    )
                                                                    .fold<int>(
                                                                      0,
                                                                      (
                                                                        r,
                                                                        set,
                                                                      ) =>
                                                                          r +
                                                                          set.reps,
                                                                    ),
                                                          );
                                                      return Row(
                                                        children: [
                                                          _buildStatCell(
                                                            "${workoutProvider.userWorkouts.length}",
                                                            isHeader: true,
                                                          ),
                                                          _buildStatCell(
                                                            "$totalSets",
                                                            isHeader: true,
                                                          ),
                                                          _buildStatCell(
                                                            "$totalReps",
                                                            isHeader: true,
                                                          ),
                                                          const Expanded(
                                                            child: SizedBox(),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  ),
                                                  Row(
                                                    children: [
                                                      _buildStatCell(
                                                        lang.getText(
                                                          "exercises",
                                                        ),
                                                        color: Colors.grey,
                                                      ),
                                                      _buildStatCell(
                                                        lang.getText("sets"),
                                                        color: Colors.grey,
                                                      ),
                                                      _buildStatCell(
                                                        lang.getText("reps"),
                                                        color: Colors.grey,
                                                      ),
                                                      const Expanded(
                                                        child: SizedBox(),
                                                      ),
                                                    ],
                                                  ),

                                                  const Divider(
                                                    color: Colors.white24,
                                                    height: 30,
                                                  ),

                                                  Flexible(
                                                    child: ListView.separated(
                                                      shrinkWrap: true,
                                                      itemCount: lastWorkout
                                                          .exercises
                                                          .length,
                                                      separatorBuilder:
                                                          (ctx, i) =>
                                                              const Divider(
                                                                color: Colors
                                                                    .white12,
                                                              ),
                                                      itemBuilder: (context, index) {
                                                        final ex = lastWorkout
                                                            .exercises[index];

                                                        final isCardio =
                                                            ex
                                                                .exercise
                                                                ?.category
                                                                ?.toLowerCase() ==
                                                            'cardio';
                                                        final isBodyweight =
                                                            ex
                                                                    .exercise
                                                                    ?.equipment
                                                                    ?.toLowerCase() ==
                                                                'body only' ||
                                                            ex
                                                                    .exercise
                                                                    ?.equipment
                                                                    ?.toLowerCase() ==
                                                                'none';

                                                        return Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    vertical:
                                                                        8.0,
                                                                  ),
                                                              child: Text(
                                                                ex.exercise?.getName(
                                                                      langCode,
                                                                    ) ??
                                                                    lang.getText(
                                                                      "unknown_exercise",
                                                                    ),
                                                                style: const TextStyle(
                                                                  color: Colors
                                                                      .green,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 16,
                                                                ),
                                                              ),
                                                            ),

                                                            if (ex.sets.isEmpty)
                                                              const Text(
                                                                " - ",
                                                                style: TextStyle(
                                                                  color: Colors
                                                                      .grey,
                                                                ),
                                                              )
                                                            else
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets.only(
                                                                      left:
                                                                          10.0,
                                                                    ),
                                                                child: Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: ex.sets.map((
                                                                    set,
                                                                  ) {
                                                                    String
                                                                    textToShow =
                                                                        "";
                                                                    if (isCardio) {
                                                                      textToShow =
                                                                          "${set.weight} km | ${set.reps} ${lang.getText("min")}";
                                                                    } else if (isBodyweight) {
                                                                      textToShow =
                                                                          "${set.reps} ${lang.getText("reps")}";
                                                                    } else {
                                                                      textToShow =
                                                                          "${set.weight} kg x ${set.reps}";
                                                                    }

                                                                    return Padding(
                                                                      padding: const EdgeInsets.symmetric(
                                                                        vertical:
                                                                            2.0,
                                                                      ),
                                                                      child: Text(
                                                                        textToShow,
                                                                        style: const TextStyle(
                                                                          color:
                                                                              Colors.white70,
                                                                          fontSize:
                                                                              13,
                                                                        ),
                                                                      ),
                                                                    );
                                                                  }).toList(),
                                                                ),
                                                              ),
                                                          ],
                                                        );
                                                      },
                                                    ),
                                                  ),

                                                  const SizedBox(height: 10),

                                                  Center(
                                                    child: FilledButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            context,
                                                          ),
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
                                                        lang.getText("close"),
                                                        style: const TextStyle(
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.all(20),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                          sigmaX: 5.0,
                                          sigmaY: 5.0,
                                        ),
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color.fromRGBO(
                                              45,
                                              45,
                                              45,
                                              0.5,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    // ignore: unnecessary_string_interpolations
                                                    "${lastWorkout.workoutName.isEmpty ? lastWorkout.customName : getTranslatedName(lastWorkout.workoutName, lang)}",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize:
                                                          MediaQuery.of(
                                                            context,
                                                          ).size.height *
                                                          0.02,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    "${lang.getText("duration")}: ${lastWorkout.durationMinutes} ${lang.getText("min")}",
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                  Text(
                                                    "${lang.getText("burnt_calories")}: ${lastWorkout.totalBurntCalories} kcal",
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
                                                      MediaQuery.of(
                                                        context,
                                                      ).size.height *
                                                      0.02,
                                                ),
                                                child: Container(
                                                  width: 50,
                                                  height: 50,
                                                  decoration:
                                                      const BoxDecoration(
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
                                    ),
                                  ),
                                ),
                        ],
                      );
                    },
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
              FutureBuilder<List<UserMealDto>>(
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
                      ? (meals..sort((a, b) => b.eatenAt.compareTo(a.eatenAt)))
                            .first
                      : null;

                  String formattedDate = '';
                  if (lastMeal != null) {
                    formattedDate = DateFormat.yMd(
                      locale,
                    ).add_Hms().format(lastMeal.eatenAt);
                  }
                  return Stack(
                    children: [
                      lastMeal == null
                          ? Container(
                              width: double.infinity,
                              margin: const EdgeInsets.all(20),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 20.0,
                                    sigmaY: 20.0,
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color.fromRGBO(
                                        45,
                                        45,
                                        45,
                                        0.5,
                                      ),
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
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              getTranslatedName(
                                                lastMeal.mealName,
                                                lang,
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
                                                itemCount:
                                                    lastMeal.meals.length,
                                                itemBuilder: (context, index) {
                                                  final meal =
                                                      lastMeal.meals[index];
                                                  final cleanName =
                                                      stripHtmlTags(meal.name);

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
                                                          "$cleanName (${meal.quantity})",
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
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Expanded(
                                                              child: Text(
                                                                '${meal.qCalories.toStringAsFixed(3)} kcal',
                                                                style: const TextStyle(
                                                                  color: Colors
                                                                      .white70,
                                                                ),
                                                              ),
                                                            ),
                                                            Expanded(
                                                              child: Text(
                                                                '${meal.qProtein.toStringAsFixed(3)} g ${lang.getText("protein").toLowerCase()}',
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
                                                                '${meal.qCarbs.toStringAsFixed(3)} g ${lang.getText("carbs").toLowerCase()}',
                                                                style: const TextStyle(
                                                                  color: Colors
                                                                      .white70,
                                                                ),
                                                              ),
                                                            ),
                                                            Expanded(
                                                              child: Text(
                                                                '${meal.qFat.toStringAsFixed(3)} g ${lang.getText("fat").toLowerCase()}',
                                                                style: const TextStyle(
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

                                            Center(
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
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                ),
                                                child: Text(
                                                  lang.getText("close"),
                                                  style: const TextStyle(
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
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 5.0,
                                      sigmaY: 5.0,
                                    ),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color.fromRGBO(
                                          45,
                                          45,
                                          45,
                                          0.5,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "${getTranslatedName(lastMeal.mealName, lang)} - $formattedDate",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize:
                                                      MediaQuery.of(
                                                        context,
                                                      ).size.height *
                                                      0.02,
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
                                                  MediaQuery.of(
                                                    context,
                                                  ).size.height *
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
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildStatCell(
  String text, {
  bool isHeader = false,
  Color color = Colors.white,
}) {
  return Expanded(
    child: Center(
      child: Text(
        text,
        style: TextStyle(
          color: isHeader ? Colors.white : color,
          fontWeight: FontWeight.bold,
          fontSize: isHeader ? 16 : 12,
        ),
      ),
    ),
  );
}

Widget _buildLegendItem(Color color, String label, String value) {
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
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    ],
  );
}
