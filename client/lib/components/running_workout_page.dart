import 'dart:async';
import 'dart:ui';
import 'package:client/components/ui/custom_button.dart';
import 'package:client/components/ui/custom_snackbar.dart';
import 'package:client/components/ui/custom_textfield.dart';
import 'package:client/main.dart';
import 'package:client/models/workout.dart';
import 'package:client/providers/language_provider.dart';
import 'package:client/pages.dart';
import 'package:client/providers/workout_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:client/constants.dart';
import 'package:http/http.dart' as http;

class RunningWorkoutPage extends StatefulWidget {
  final List<ExerciseDto> userWorkouts;
  final int initialSeconds;
  const RunningWorkoutPage({
    super.key,
    required this.userWorkouts,
    this.initialSeconds = 0,
  });

  @override
  State<RunningWorkoutPage> createState() => _RunningWorkoutPageState();
}

final workoutcontroller = TextEditingController();

class _RunningWorkoutPageState extends State<RunningWorkoutPage> {
  Color workoutColorCode = const Color.fromARGB(150, 50, 146, 255);
  bool _isPopping = false;
  Future<void> saveUserExercises(
    List<ExerciseDto> exercises,
    String workoutName,
    int userId,
    int durationMinutes,
    int caloriesBurnt,
    int totalVolume,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('jwt_token');
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    if (token == null || token.isEmpty) throw Exception("Nincs token.");

    final uri = Uri.parse("$apiUrl/api/Workout/AddWorkout");

    final exercisesToSave = exercises
        .where((e) => e.sets.any((s) => s.isCompleted))
        .map((e) {
          var exCopy = e.copyWith();
          exCopy.sets = e.sets.where((s) => s.isCompleted).toList();
          return exCopy;
        })
        .toList();

    final dto = {
      "userId": userId,
      "WorkoutName": workoutName,
      "UserId": userId,
      "Date": DateTime.now().toIso8601String(),
      "Exercises": exercisesToSave
          .map(
            (e) => {
              "ExerciseId": e.id,
              "Name": e.name,
              "Sets": e.sets.map((s) => s.toJson()).toList(),
            },
          )
          .toList(),
      "DurationMinutes": durationMinutes,
      "CaloriesBurnt": caloriesBurnt,
      "TotalVolume": totalVolume,
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

  Future<void> saveUserExercisesS(
    List<ExerciseDto> exercises,
    String customName,
    int userId,
    int durationMinutes,
    int caloriesBurnt,
    int totalVolume,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('jwt_token');
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    if (token == null || token.isEmpty) throw Exception("Nincs token.");

    final uri = Uri.parse("$apiUrl/api/Workout/AddWorkoutS");

    final exercisesToSave = exercises
        .where((e) => e.sets.any((s) => s.isCompleted))
        .map((e) {
          var exCopy = e.copyWith();
          exCopy.sets = e.sets.where((s) => s.isCompleted).toList();
          return exCopy;
        })
        .toList();

    final dto = {
      "userId": userId,
      "CustomName": customName,
      "UserId": userId,
      "Date": DateTime.now().toIso8601String(),
      "Exercises": exercisesToSave
          .map(
            (e) => {
              "ExerciseId": e.id,
              "Name": e.name,
              "Sets": e.sets.map((s) => s.toJson()).toList(),
            },
          )
          .toList(),
      "DurationMinutes": durationMinutes,
      "CaloriesBurnt": caloriesBurnt,
      "TotalVolume": totalVolume,
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final workoutProvider = Provider.of<WorkoutProvider>(
        context,
        listen: false,
      );
      if (!workoutProvider.isWorkoutActive) {
        workoutProvider.startWorkout(
          widget.userWorkouts,
          initialSeconds: widget.initialSeconds,
        );
      } else {
        workoutProvider.updateExercises(widget.userWorkouts);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  String dependOnHour() {
    final lang = Provider.of<LanguageProvider>(context);
    final hour = DateTime.now().hour;

    if (6 <= hour && hour < 12) return lang.getText("morning");
    if (12 <= hour && hour < 18) return lang.getText("afternoon");
    if (18 <= hour && hour < 21) return lang.getText("evening");
    return lang.getText("night");
  }

  String dependOnHourB() {
    final hour = DateTime.now().hour;

    if (6 <= hour && hour < 12) return "reggeli edzés";
    if (12 <= hour && hour < 18) return "délutáni edzés";
    if (18 <= hour && hour < 21) return "esti edzés";
    return "éjszakai edzés";
  }

  final PageController _pageController = PageController(viewportFraction: 0.95);

  int currentPage = 0;
  final Map<int, double> _pageHeights = {};

  double _getcurrentHeight(BuildContext context) {
    if (_pageHeights.containsKey(currentPage)) {
      return _pageHeights[currentPage]!;
    }
    return MediaQuery.of(context).size.height * 0.7;
  }

  @override
  Widget build(BuildContext context) {
    final workoutProvider = Provider.of<WorkoutProvider>(context);
    final currentExercises = workoutProvider.userWorkouts;
    final lang = Provider.of<LanguageProvider>(context);
    final String locale = lang.languageCode == 'hu' ? 'hu_HU' : 'en_US';
    final defWorkoutName =
        "${DateFormat.MMMd(locale).format(DateTime.now())} ${dependOnHour()}";
    final defWorkoutNameB =
        "${DateFormat.MMMd(locale).format(DateTime.now())} ${dependOnHourB()}";
    Timer? _debounce;

    return PopScope(
      canPop: _isPopping,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        final prefs = await SharedPreferences.getInstance();
        final sessionData = {
          'elapsedSeconds': workoutProvider.totalSeconds,
          'timestamp': DateTime.now()
              .millisecondsSinceEpoch,
          'exercises': workoutProvider.userWorkouts
              .map((e) => e.toJson())
              .toList(),
        };
        final jsonString = jsonEncode(sessionData);

        await prefs.setString('offline_workout', jsonString);
        offlineSessionNotifier.value = jsonString;

        setState(() {
          _isPopping = true;
        });

        if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Container(
                  margin: const EdgeInsets.all(3),
                  child: AppBar(
                    backgroundColor: Colors.transparent,
                    automaticallyImplyLeading: false,
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: ClipRRect(
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
                                    color: const Color.fromRGBO(
                                      45,
                                      45,
                                      45,
                                      0.5,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.arrow_back),
                                        color: Colors.white,
                                        padding: EdgeInsets.only(
                                          left: 0,
                                          top: 0,
                                          bottom: 0,
                                          right: 10,
                                        ),
                                        constraints: const BoxConstraints(),
                                        style: IconButton.styleFrom(
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        onPressed: () =>
                                            Navigator.maybePop(context),
                                      ),
                                      Text(
                                        lang.getText(
                                          "${DateFormat.MMMd(locale).format(DateTime.now())} ${dependOnHour()}",
                                        ),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
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
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  workoutProvider.formattedTime,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
              SizedBox(height: 20),
              AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeOut,
                height: _getcurrentHeight(context),
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: widget.userWorkouts.length,
                  onPageChanged: (index) {
                    setState(() {
                      currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final exercise = widget.userWorkouts[index];
                    return SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: MeasureSize(
                        onChange: (size) {
                          double newHeight = size.height + 60;
                          if (_pageHeights[index] != newHeight) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() {
                                  _pageHeights[index] = newHeight;
                                });
                              }
                            });
                          }
                        },
                        child: ExerciseTrackerCard(
                          exercise: exercise,
                          onremoveExercise: () {
                            setState(() {
                              currentExercises.removeAt(index);
                              _pageHeights.remove(index);
                              if (currentPage >= currentExercises.length &&
                                  currentPage > 0) {
                                currentPage = currentExercises.length - 1;
                              }
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: CustomButton(
                    title: lang.getText("finish_workout"),
                    variant: CustomButtonVariant.primaryWorkout,
                    onPressed: () async {
                      final finishedExercises = workoutProvider.userWorkouts
                          .where((ex) => ex.sets.any((s) => s.isCompleted))
                          .toList();
                      workoutProvider.stopWorkout();
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove('offline_workout');
                      offlineSessionNotifier.value = null;
                      int totalSets = 0;
                      int totalReps = 0;
                      double totalVolume = 0;
                      double totalMet = 0;
                      for (var ex in finishedExercises) {
                        final finishedSets = ex.sets
                            .where((s) => s.isCompleted)
                            .toList();
                        totalSets += ex.sets.length;
                        totalMet += ex.metValue;
                        for (var s in finishedSets) {
                          totalReps += s.reps;
                          totalVolume += s.reps * s.weight;
                        }
                      }

                      double avgMet = workoutProvider.userWorkouts.isNotEmpty
                          ? totalMet / workoutProvider.userWorkouts.length
                          : 3.5;

                      double durationMin =
                          (workoutProvider.minutes + workoutProvider.hours * 60)
                              .toDouble();
                      int burntCalories =
                          (avgMet * 3.5 * 75 / 200 * durationMin).toInt();
                      if (burntCalories == 0 && durationMin > 0)
                        // ignore: curly_braces_in_flow_control_structures
                        burntCalories = (durationMin * 5).toInt();

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
                        debugPrint(
                          "Nem sikerült lekérni az edzések számát: $e",
                        );
                      }

                      for (var ex in workoutProvider.userWorkouts) {
                        totalSets += ex.sets.length;
                        for (var s in ex.sets) {
                          if (s.isCompleted) {
                            totalReps += s.reps;
                            totalVolume += s.reps * s.weight;
                          } else {
                            totalReps += s.reps;
                            totalVolume += s.reps * s.weight;
                          }
                        }
                      }
                      showDialog(
                        barrierDismissible: false,
                        context: context,
                        builder: (builderContext) {
                          return PopScope(
                            canPop: false,
                            child: Dialog(
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
                                  color: const Color.fromRGBO(45, 45, 45, 1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Center(
                                      child: Text(
                                        lang.getText(defWorkoutName),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
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
                                          "$burntCalories",
                                          isHeader: true,
                                        ),
                                        _buildStatCell(
                                          "${workoutProvider.minutes + workoutProvider.hours * 60} ${lang.getText("min")}",
                                          isHeader: true,
                                        ),
                                        _buildStatCell(
                                          "${totalVolume.toInt()}",
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
                                    Row(
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
                                        const Expanded(child: SizedBox()),
                                      ],
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

                                    const Divider(
                                      color: Colors.white24,
                                      height: 30,
                                    ),

                                    Flexible(
                                      child: ListView.separated(
                                        shrinkWrap: true,
                                        itemCount: finishedExercises.length,
                                        separatorBuilder: (ctx, i) =>
                                            const Divider(
                                              color: Colors.white12,
                                            ),

                                        itemBuilder: (context, index) {
                                          final ex = finishedExercises[index];

                                          final isCardio =
                                              ex.category?.toLowerCase() ==
                                              'cardio';
                                          final isBodyweight =
                                              ex.equipment?.toLowerCase() ==
                                                  'body only' ||
                                              ex.equipment?.toLowerCase() ==
                                                  'none';

                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                ex.getName(lang.languageCode),
                                                style: TextStyle(
                                                  color: workoutColorCode,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 6),

                                              if (ex.sets.isEmpty)
                                                const Text(
                                                  " - Nincs sorozat",
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 12,
                                                  ),
                                                )
                                              else
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const SizedBox(height: 8),
                                                    ...ex.sets.where((s) => s.isCompleted).map((
                                                      set,
                                                    ) {
                                                      final isCardio =
                                                          ex.category
                                                              ?.toLowerCase() ==
                                                          'cardio';
                                                      final isBodyweight =
                                                          ex.equipment
                                                                  ?.toLowerCase() ==
                                                              'body only' ||
                                                          ex.equipment
                                                                  ?.toLowerCase() ==
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

                                                      return Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                              left: 10.0,
                                                              bottom: 8.0,
                                                            ),
                                                        child: Text(
                                                          textToShow,
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .white70,
                                                                fontSize: 13,
                                                              ),
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
                                    Center(
                                      child: CustomButton(
                                        variant: CustomButtonVariant.secondary,
                                        onPressed: () async {
                                          Navigator.pop(context);
                                          if (_debounce?.isActive ?? false) {
                                            _debounce!.cancel();
                                          }
                                          _debounce = Timer(
                                            const Duration(milliseconds: 1500),
                                            () {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).hideCurrentSnackBar();
                                            },
                                          );
                                          _showSaveDialog(
                                            context,
                                            lang,
                                            workoutProvider,
                                            defWorkoutNameB,
                                            burntCalories,
                                            totalVolume,
                                          );
                                        },
                                        iconData: Icons.close,
                                        title: lang.getText("close"),
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSaveDialog(
    BuildContext context,
    LanguageProvider lang,
    WorkoutProvider workoutProvider,
    String defWorkoutNameB,
    int burntCalories,
    double totalVolume,
  ) {
    Timer? _debounce;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: Dialog(
            insetPadding: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 45, 45, 45),
                borderRadius: BorderRadius.circular(16),
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
                    SizedBox(height: 30),
                    Stack(
                      children: [
                        customTextField(
                          context,
                          workoutcontroller,
                          lang.getText("sample_name"),
                          isCreateWorkout: true,
                        ),
                      ],
                    ),
                    SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: CustomButton(
                            variant: CustomButtonVariant.primaryWorkout,
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

                                await saveUserExercises(
                                  workoutProvider.userWorkouts,
                                  defWorkoutNameB,
                                  userId,
                                  workoutProvider.minutes +
                                      workoutProvider.hours * 60,
                                  burntCalories,
                                  totalVolume.toInt(),
                                );

                                CustomSnackbar.show(
                                  context,
                                  lang.getText("saved_successfully"),
                                  backgroundColor: workoutColorCode,
                                );
                              } catch (e) {
                                CustomSnackbar.show(
                                  context,
                                  "Hiba: $e",
                                  backgroundColor: Colors.red,
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
                                  Navigator.push<List<ExerciseDto>>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const Pages(),
                                    ),
                                  );
                                },
                              );
                            },
                            child: Text(
                              lang.getText("save_without_sample"),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: CustomButton(
                            variant: CustomButtonVariant.primaryWorkout,
                            onPressed: () async {
                              if (workoutcontroller.text.trim().isEmpty) {
                                CustomSnackbar.show(
                                  context,
                                  lang.getText("name_the_template"),
                                  backgroundColor: Colors.red,
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

                                await saveUserExercisesS(
                                  workoutProvider.userWorkouts,
                                  workoutcontroller.text,
                                  userId,
                                  workoutProvider.minutes +
                                      workoutProvider.hours * 60,
                                  burntCalories,
                                  totalVolume.toInt(),
                                );

                                CustomSnackbar.show(
                                  context,
                                  lang.getText("saved_successfully"),
                                  backgroundColor: workoutColorCode,
                                );
                              } catch (e) {
                                CustomSnackbar.show(
                                  context,
                                  "Hiba: $e",
                                  backgroundColor: Colors.red,
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
                                  Navigator.push<List<ExerciseDto>>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const Pages(),
                                    ),
                                  );
                                },
                              );
                            },
                            child: Text(
                              lang.getText("save"),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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

class HistoryItem {
  final int workoutId;
  final String date;
  final String workoutName;
  final List<WorkoutSetDto> sets;

  HistoryItem({
    required this.workoutId,
    required this.date,
    required this.workoutName,
    required this.sets,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    var setsList = (json['sets'] as List)
        .map(
          (s) => WorkoutSetDto(
            weight: (s['weight'] as num).toDouble(),
            reps: (s['reps'] as num).toInt(),
            distance: s['distance'] != null
                ? (s['distance'] as num).toDouble()
                : 0.0,
            durationSeconds: s['durationSeconds'] != null
                ? (s['durationSeconds'] as num).toInt()
                : 0,
          ),
        )
        .toList();

    return HistoryItem(
      workoutId: json['workoutId'],
      date: json['date'],
      workoutName: json['workoutName'],
      sets: setsList,
    );
  }
}

class ExerciseTrackerCard extends StatefulWidget {
  final ExerciseDto exercise;
  final VoidCallback? onremoveExercise;

  const ExerciseTrackerCard({
    super.key,
    required this.exercise,
    this.onremoveExercise,
  });

  @override
  State<ExerciseTrackerCard> createState() => _ExerciseTrackerCardState();
}

class _ExerciseTrackerCardState extends State<ExerciseTrackerCard>
    with AutomaticKeepAliveClientMixin {
  List<HistoryItem> history = [];
  bool isLoadingHistory = true;
  final PageController _historyPageController = PageController(
    viewportFraction: 0.85,
  );
  final Color primaryBlue = const Color.fromARGB(255, 50, 146, 255);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (widget.exercise.sets.isEmpty) {
      widget.exercise.sets.add(WorkoutSetDto(weight: 0, reps: 0));
    }
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) return;

      final response = await http.get(
        Uri.parse(
          "$apiUrl/api/Workout/getExerciseHistory/${widget.exercise.id}",
        ),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            history = data.map((json) => HistoryItem.fromJson(json)).toList();
            isLoadingHistory = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Hiba az előzmények betöltésekor: $e");
      if (mounted) setState(() => isLoadingHistory = false);
    }
  }

  void _applyHistory(HistoryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Adatok betöltése",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Szeretnéd felülírni a jelenlegi mezőket ezzel a korábbi edzéssel?",
          style: TextStyle(color: Colors.white70),
        ),
        backgroundColor: const Color.fromARGB(255, 45, 45, 45),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Mégse", style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: primaryBlue),
            onPressed: () {
              setState(() {
                widget.exercise.sets = item.sets
                    .map(
                      (s) => WorkoutSetDto(
                        weight: s.weight,
                        reps: s.reps,
                        distance: s.distance,
                        durationSeconds: s.durationSeconds,
                        isCompleted: false,
                      ),
                    )
                    .toList();
              });
              Navigator.pop(context);
            },
            child: const Text("Betöltés"),
          ),
        ],
      ),
    );
  }

  void _addSet() {
    setState(() {
      double lastWeight = widget.exercise.sets.isNotEmpty
          ? widget.exercise.sets.last.weight
          : 0;
      int lastReps = widget.exercise.sets.isNotEmpty
          ? widget.exercise.sets.last.reps
          : 0;

      widget.exercise.sets.add(
        WorkoutSetDto(weight: lastWeight, reps: lastReps),
      );
    });
  }

  void _removeSet(int index) {
    setState(() {
      widget.exercise.sets.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final lang = Provider.of<LanguageProvider>(context);
    final langCode = Provider.of<LanguageProvider>(context).languageCode;

    bool isCardio = widget.exercise.category?.toLowerCase() == 'cardio';
    bool isBodyweight =
        widget.exercise.equipment?.toLowerCase() == 'body only' ||
        widget.exercise.equipment?.toLowerCase() == 'none';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 45, 45, 45),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            children: [
              Container(
                width: double.infinity,
                height: 200,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.black12,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: widget.exercise.images.isNotEmpty
                      ? Image.network(
                          "https://raw.githubusercontent.com/sitespectrum/zest_exercises/main/exercises/${widget.exercise.images[0]}",
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.fitness_center,
                                color: Colors.white24,
                                size: 50,
                              ),
                            );
                          },
                        )
                      : const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.white24,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  widget.exercise.getName(langCode),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              SizedBox(
                width: 42,
                child: Center(
                  child: Text(
                    lang.getText("set"),
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              if (isCardio) ...[
                Expanded(
                  child: Center(
                    child: Text(
                      lang.getText("distance"),
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      lang.getText("time"),
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ] else if (isBodyweight) ...[
                Expanded(child: SizedBox()),
                Expanded(
                  child: Center(
                    child: Text(
                      lang.getText("reps"),
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: Center(
                    child: Text(
                      "KG",
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      lang.getText("reps"),
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],

              SizedBox(
                width: 50,
                child: Center(
                  child: Text(
                    lang.getText("done"),
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          ListView.builder(
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            itemCount: widget.exercise.sets.length,
            itemBuilder: (context, index) {
              final set = widget.exercise.sets[index];
              final backgroundColor = set.isCompleted
                  ? primaryBlue.withOpacity(0.2)
                  : Color.fromARGB(255, 58, 58, 58);
              return Container(
                key: ObjectKey(set),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Center(
                        child: Text(
                          "${index + 1}",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: isBodyweight
                          ? Container()
                          : Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2C2C2E),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: TextFormField(
                                initialValue: isCardio
                                    ? (set.weight == 0
                                          ? ""
                                          : set.weight.toString())
                                    : (set.weight == 0
                                          ? ""
                                          : set.weight.toString()),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: isCardio ? "km" : "-",
                                  hintStyle: TextStyle(color: Colors.white24),
                                  contentPadding: EdgeInsets.only(bottom: 10),
                                ),
                                onChanged: (val) {
                                  set.weight =
                                      double.tryParse(
                                        val.replaceAll(',', '.'),
                                      ) ??
                                      0.0;
                                },
                              ),
                            ),
                    ),

                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextFormField(
                          initialValue: set.reps == 0
                              ? ""
                              : set.reps.toString(),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: isCardio ? lang.getText("min") : "-",
                            hintStyle: TextStyle(color: Colors.white24),
                            contentPadding: EdgeInsets.only(bottom: 10),
                          ),
                          onChanged: (val) {
                            set.reps = int.tryParse(val) ?? 0;
                          },
                        ),
                      ),
                    ),

                    SizedBox(
                      width: 50,
                      child: Center(
                        child: Transform.scale(
                          scale: 1.2,
                          child: Checkbox(
                            value: set.isCompleted,
                            activeColor: primaryBlue,
                            checkColor: Colors.white,
                            side: const BorderSide(
                              color: Colors.grey,
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: (bool? value) {
                              setState(() {
                                set.isCompleted = value ?? false;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: _addSet,
                icon: Icon(Icons.add, color: primaryBlue),
                label: Text(
                  lang.getText("add_set"),
                  style: TextStyle(color: primaryBlue),
                ),
              ),
              if (widget.exercise.sets.length > 1) ...[
                const SizedBox(width: 20),
                TextButton.icon(
                  onPressed: () => _removeSet(widget.exercise.sets.length - 1),
                  icon: const Icon(Icons.remove, color: Colors.redAccent),
                  label: Text(
                    lang.getText("remove"),
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            ],
          ),

          const Divider(color: Colors.white24, height: 38),
          Text(
            "${lang.getText("recent_exercises")} (${history.length})",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),

          if (isLoadingHistory)
            const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.grey,
              ),
            )
          else if (history.isEmpty)
            Center(
              child: Text(
                lang.getText("no_history"),
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            )
          else
            _buildHistorySection(lang, isCardio),
        ],
      ),
    );
  }

  Widget _buildHistorySection(LanguageProvider lang, bool isCardio) {
    return SizedBox(
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PageView.builder(
            controller: _historyPageController,
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              final dateStr = DateFormat(
                'yyyy. MM. dd.',
              ).format(DateTime.parse(item.date));

              return GestureDetector(
                onTap: () => _applyHistory(item),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 60, 60, 60),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dateStr,
                        style: TextStyle(
                          color: primaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.workoutName,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Divider(color: Colors.white12, height: 8),
                      Flexible(
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: item.sets.length > 2
                              ? 2
                              : item.sets.length,
                          itemBuilder: (ctx, i) {
                            final s = item.sets[i];
                            String txt = isCardio
                                ? "${s.weight}km / ${s.reps}${lang.getText("min")}"
                                : "${s.weight}kg x ${s.reps}";
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 1.0,
                              ),
                              child: Center(
                                child: Text(
                                  txt,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      if (item.sets.length > 2)
                        const Padding(
                          padding: EdgeInsets.only(top: 2.0),
                          child: Text(
                            "...",
                            style: TextStyle(
                              color: Colors.white30,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),

          Positioned(
            left: 0,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                size: 16,
                color: Colors.white24,
              ),
              onPressed: () => _historyPageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              ),
            ),
          ),
          Positioned(
            right: 0,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.white24,
              ),
              onPressed: () => _historyPageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MeasureSize extends StatefulWidget {
  final Widget child;
  final ValueChanged<Size> onChange;

  const MeasureSize({super.key, required this.onChange, required this.child});

  @override
  State<MeasureSize> createState() => _MeasureSizeState();
}

class _MeasureSizeState extends State<MeasureSize> {
  @override
  Widget build(BuildContext context) {
    return _MeasureSizeRenderObject(
      onChange: widget.onChange,
      child: widget.child,
    );
  }
}

class _MeasureSizeRenderObject extends SingleChildRenderObjectWidget {
  final ValueChanged<Size> onChange;

  const _MeasureSizeRenderObject({
    required this.onChange,
    required Widget child,
  }) : super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _MeasureSizeRenderBox(onChange);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _MeasureSizeRenderBox renderObject,
  ) {
    renderObject.onChange = onChange;
  }
}

class _MeasureSizeRenderBox extends RenderProxyBox {
  ValueChanged<Size> onChange;
  Size? _oldSize;

  _MeasureSizeRenderBox(this.onChange);

  @override
  void performLayout() {
    super.performLayout();
    if (child != null) {
      final newSize = child!.size;
      if (_oldSize == newSize) return;
      _oldSize = newSize;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onChange(newSize);
      });
    }
  }
}
