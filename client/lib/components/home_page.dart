import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zest_client/components/topo_background.dart';
import 'package:zest_client/components/ui/custom_card.dart';
import 'package:zest_client/constants.dart';
import 'package:zest_client/models/meal.dart';
import 'package:zest_client/models/workout.dart';
import 'package:zest_client/providers/language_provider.dart';
import 'package:zest_client/providers/workout_provider.dart';

import 'add_meal_page.dart';

part "home_page.g.dart";

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

@hwidget
Widget homePage(BuildContext context) {
  final futureMeals = useState(fetchUserMeals());
  final futureWorkouts = useState(fetchUserWorkouts());
  final todayCalories = useState(fetchTodayCalories());
  final calorieGoal = useState(fetchCalorieGoal());

  final lang = Provider.of<LanguageProvider>(context);

  return SingleChildScrollView(
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
    child: Stack(
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
          child: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white38, Colors.transparent],
            ).createShader(bounds),
            child: TopoBackground(),
          ),
        ),
        FutureBuilder<List<UserMealDto>>(
          future: futureMeals.value,
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

            final lastMeal =
                ((snapshot.data ?? [])
                      ..sort((a, b) => b.eatenAt.compareTo(a.eatenAt)))
                    .firstOrNull;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PreferredSize(
                  preferredSize: const Size.fromHeight(60),
                  child: Container(
                    margin: const EdgeInsets.all(6),
                    child: AppBar(
                      title: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
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
                                  Icons.home_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                Text(
                                  lang.getText("home_page"),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      automaticallyImplyLeading: false,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                ),

                FutureBuilder(
                  future: Future.wait([todayCalories.value, calorieGoal.value]),
                  builder: (context, asyncSnapshot) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      margin: const EdgeInsets.fromLTRB(0, 64, 0, 8),
                      child: Column(
                        children: [
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  // text: (asyncSnapshot.data?[0] ?? 0)
                                  //     .toStringAsFixed(0),
                                  text: "1643",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 44,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  // text: (asyncSnapshot.data?[0] ?? 0)
                                  //     .toStringAsFixed(0),
                                  text: " / 2154 kcal",
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                Container(
                  height: 32,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Color.fromARGB(25, 255, 255, 255),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Flex(
                    direction: Axis.horizontal,
                    children: [
                      Expanded(
                        flex: 1643,
                        child: Flex(
                          direction: Axis.horizontal,
                          children: [
                            Expanded(
                              flex: 13,
                              child: Container(color: const Color(0xFF1f84d8)),
                            ),
                            Expanded(
                              flex: 15,
                              child: Container(color: const Color(0xFFe3d135)),
                            ),
                            Expanded(
                              flex: 7,
                              child: Container(color: const Color(0xFFd93c30)),
                            ),
                          ],
                        ),
                      ),
                      Expanded(flex: 2154 - 1643, child: Container()),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                Container(
                  margin: EdgeInsets.symmetric(horizontal: 24),
                  child: Flex(
                    spacing: 18,
                    direction: Axis.horizontal,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Row(
                        spacing: 6,
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1f84d8),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          Text(
                            "Fehérje",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      Row(
                        spacing: 6,
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: const Color(0xFFe3d135),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          Text(
                            "Szénhidrát",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      Row(
                        spacing: 6,
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: const Color(0xFFd93c30),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          Text(
                            "Zsír",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    spacing: 24,
                    children: [
                      //Legutóbbi edzés
                      CustomCard(
                        title: lang.getText("recent_workout"),
                        iconData: Icons.fitness_center_rounded,
                        child: FutureBuilder<List<UserWorkoutDto>>(
                          future: futureWorkouts.value,
                          builder: (context, snapshot) =>
                              snapshot.connectionState ==
                                  ConnectionState.waiting
                              ? Container(
                                  margin: const EdgeInsets.only(
                                    bottom: 20,
                                    top: 20,
                                  ),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Color.fromARGB(50, 64, 255, 50),
                                    ),
                                  ),
                                )
                              : LastWorkoutCardContent(
                                  lastWorkout:
                                      ((snapshot.data ?? [])..sort(
                                            (a, b) => b.date.compareTo(a.date),
                                          ))
                                          .firstOrNull,
                                ),
                        ),
                      ),

                      //Legutóbbi étkezés
                      CustomCard(
                        title: lang.getText("recent_meal"),
                        iconData: Icons.fastfood_rounded,
                        child: LastMealCardContent(lastMeal: lastMeal),
                      ),
                    ],
                  ),
                ),

                //Legutóbbi edzés
              ],
            );
          },
        ),
      ],
    ),
  );
}

@hwidget
Widget lastMealCardContent(BuildContext context, {UserMealDto? lastMeal}) {
  final lang = Provider.of<LanguageProvider>(context);
  final locale = lang.languageCode == 'hu' ? 'hu_HU' : 'en_US';

  final formattedDate = lastMeal != null
      ? DateFormat.yMd(locale).add_Hms().format(lastMeal.eatenAt)
      : "";

  if (lastMeal == null) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          lang.getText("no_added_meal_yet"),
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 18),
        ),
      ),
    );
  }

  return GestureDetector(
    onTap: () {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            insetPadding: const EdgeInsets.all(20),
            backgroundColor: const Color.fromARGB(255, 30, 30, 30),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 40, 40, 40),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    getTranslatedName(lastMeal.mealName, lang),
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
                        final cleanName = stripHtmlTags(meal.name);

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
                                "$cleanName (${meal.quantity})",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${meal.qCalories.toStringAsFixed(3)} kcal',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '${meal.qProtein.toStringAsFixed(3)} g ${lang.getText("protein").toLowerCase()}',
                                      style: const TextStyle(
                                        color: Colors.white70,
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
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '${meal.qFat.toStringAsFixed(3)} g ${lang.getText("fat").toLowerCase()}',
                                      style: const TextStyle(
                                        color: Colors.white70,
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
                      onPressed: () => Navigator.pop(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 30, 30, 30),
                        side: const BorderSide(color: Colors.white24, width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        lang.getText("close"),
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
      // margin: const EdgeInsets.all(20),
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
                  fontSize: MediaQuery.of(context).size.height * 0.021,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "${lang.getText("calories")}: ${lastMeal.totalCalories.toStringAsFixed(0)} kcal",
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              Text(
                "${lang.getText("protein")}: ${lastMeal.totalProtein.toStringAsFixed(1)} g",
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              Text(
                "${lang.getText("carbs")}: ${lastMeal.totalCarbs.toStringAsFixed(1)} g",
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              Text(
                "${lang.getText("fat")}: ${lastMeal.totalFat.toStringAsFixed(1)} g",
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),

          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).size.height * 0.055,
            ),
            child: Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward, color: Colors.black),
            ),
          ),
        ],
      ),
    ),
  );
}

@hwidget
Widget lastWorkoutCardContent(
  BuildContext context, {
  UserWorkoutDto? lastWorkout,
}) {
  final lang = Provider.of<LanguageProvider>(context);
  final workoutProvider = Provider.of<WorkoutProvider>(context);

  if (lastWorkout == null) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          lang.getText("no_added_meal_yet"),
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 18),
        ),
      ),
    );
  }

  return GestureDetector(
    onTap: () async {
      int currentWorkoutNum = 1;
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('jwt_token');
        final response = await http.get(
          Uri.parse("$apiUrl/api/workouts/getUserWorkouts"),
          headers: {"Authorization": "Bearer $token"},
        );
        if (response.statusCode == 200) {
          List data = jsonDecode(response.body);
          currentWorkoutNum = data.length + 1;
        }
      } catch (e) {
        debugPrint("Nem sikerült lekérni az edzések számát: $e");
      }
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (builderContext) {
          return PopScope(
            canPop: false,
            child: Dialog(
              insetPadding: const EdgeInsets.all(20),
              backgroundColor: const Color.fromARGB(255, 30, 30, 30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 40, 40, 40),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Text(
                        lastWorkout.workoutName.isEmpty
                            ? lastWorkout.customName
                            : lastWorkout.workoutName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const Divider(color: Colors.white24, height: 30),

                    Row(
                      children: [
                        _buildStatCell("$currentWorkoutNum.", isHeader: true),
                        _buildStatCell(
                          "${lastWorkout.totalBurntCalories}",
                          isHeader: true,
                        ),
                        _buildStatCell(
                          "${lastWorkout.durationMinutes} ${lang.getText("min")}",
                          isHeader: true,
                        ),
                        _buildStatCell(
                          "${lastWorkout.totalLiftedWeight.toInt()} kg",
                          isHeader: true,
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
                          lang.getText("calories"),
                          color: Colors.grey,
                        ),
                        _buildStatCell(
                          lang.getText("duration"),
                          color: Colors.grey,
                        ),
                        _buildStatCell(
                          lang.getText("volume"),
                          color: Colors.grey,
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),
                    Builder(
                      builder: (context) {
                        final totalSets = lastWorkout.exercises.fold<int>(
                          0,
                          (sum, ex) =>
                              sum + ex.sets.where((s) => s.isCompleted).length,
                        );
                        final totalReps = lastWorkout.exercises.fold<int>(
                          0,
                          (sum, ex) =>
                              sum +
                              ex.sets
                                  .where((s) => s.isCompleted)
                                  .fold<int>(0, (r, set) => r + set.reps),
                        );
                        return Row(
                          children: [
                            _buildStatCell(
                              "${workoutProvider.userWorkouts.length}",
                              isHeader: true,
                            ),
                            _buildStatCell("$totalSets", isHeader: true),
                            _buildStatCell("$totalReps", isHeader: true),
                            const Expanded(child: SizedBox()),
                          ],
                        );
                      },
                    ),
                    Row(
                      children: [
                        _buildStatCell(
                          lang.getText("exercises"),
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
                        const Expanded(child: SizedBox()),
                      ],
                    ),

                    const Divider(color: Colors.white24, height: 30),

                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: lastWorkout.exercises.length,
                        separatorBuilder: (ctx, i) =>
                            const Divider(color: Colors.white12),

                        itemBuilder: (context, index) {
                          final ex = lastWorkout.exercises[index];

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (ex.sets.isEmpty)
                                const Text(
                                  " - Nincs sorozat",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                )
                              else
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    ...lastWorkout.exercises.map((
                                      exerciseData,
                                    ) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8.0,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              exerciseData.exercise?.getName(
                                                    lang.languageCode,
                                                  ) ??
                                                  lang.getText(
                                                    "unknown_exercise",
                                                  ),
                                              style: const TextStyle(
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                left: 10.0,
                                                top: 2,
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: exerciseData.sets.map((
                                                  set,
                                                ) {
                                                  final isCardio =
                                                      exerciseData
                                                          .exercise
                                                          ?.category
                                                          .toLowerCase() ==
                                                      'cardio';
                                                  final isBodyweight =
                                                      exerciseData
                                                              .exercise
                                                              ?.equipment
                                                              .toLowerCase() ==
                                                          'body only' ||
                                                      exerciseData
                                                              .exercise
                                                              ?.equipment
                                                              .toLowerCase() ==
                                                          'none';

                                                  String textToShow = "";

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

                                                  return Text(
                                                    textToShow,
                                                    style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 13,
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    Positioned(
                      child: Center(
                        child: FilledButton(
                          onPressed: () async {
                            Navigator.pop(context);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
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
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            lang.getText("close"),
                            style: TextStyle(color: Colors.red),
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
      // margin: const EdgeInsets.all(20),
      // padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // color: const Color.fromARGB(255, 45, 45, 45),
        // borderRadius: BorderRadius.circular(16),
        // border: Border.all(color: Colors.white24),
        boxShadow: [
          // BoxShadow(
          //   // ignore: deprecated_member_use
          //   // color: Colors.black.withOpacity(0.5),
          //   blurRadius: 4,
          //   offset: const Offset(0, 2),
          // ),
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
                // ignore: unnecessary_string_interpolations
                "${lastWorkout.workoutName.isEmpty ? lastWorkout.customName : getTranslatedName(lastWorkout.workoutName, lang)}",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: MediaQuery.of(context).size.height * 0.02,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "${lang.getText("duration")}: ${lastWorkout.durationMinutes} ${lang.getText("min")}",
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              Text(
                "${lang.getText("burnt_calories")}: ${lastWorkout.totalBurntCalories} kcal",
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),

          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).size.height * 0.02,
            ),
            child: Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward, color: Colors.black),
            ),
          ),
        ],
      ),
    ),
  );
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
