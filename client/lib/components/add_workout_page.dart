import 'dart:convert';
import 'package:client/models/workout.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:client/models/meal.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import 'dart:math';

class AddWorkoutPage extends StatefulWidget {
  final bool addToTemplate;
  final int? templateId;

  const AddWorkoutPage({
    super.key,
    this.addToTemplate = false,
    this.templateId,
  });

  @override
  State<AddWorkoutPage> createState() => _AddMealPageState();
}

String stripHtmlTags(String htmlText) {
  final exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
  return htmlText.replaceAll(exp, '');
}

class _AddMealPageState extends State<AddWorkoutPage> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController quantitycontroller = TextEditingController();
  final barcodeController = TextEditingController();
  List<ExerciseDto> searchResults = [];
  bool isLoading = false;
  bool anyResults = false;
  Timer? _debounce;

  List<ExerciseDto> userWorkouts = [];
  List<ExerciseDto> templateWorkouts = [];

  void addMeal(ExerciseDto exercise) {
    setState(() {
      userWorkouts.add(exercise);
    });
    final cleanName = stripHtmlTags(exercise.name);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$cleanName hozzáadva a listádhoz!'),
        showCloseIcon: true,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(bottom: 30, left: 16, right: 16),
        duration: Duration(milliseconds: 1800),
        animation: CurvedAnimation(
          parent: kAlwaysCompleteAnimation,
          curve: Curves.easeInOut,
        ),
      ),
    );
  }

  final ScrollController _scrollController = ScrollController();
  late Future<List<UserWorkoutDto>> futureExercises;

  @override
  void initState() {
    super.initState();
    futureExercises = fetchUserWorkouts();
    loadTopExercises();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
      throw Exception("Nem sikerült lekérni az étkezéseket: ${response.body}");
    }
  }

  Future<int?> addExerciseToTemplate(
    int templateId,
    int userId,
    ExerciseDto exercise,
  ) async {
    final url = Uri.parse("$apiUrl/api/Workout/AddExerciseToTemplate");

    final body = jsonEncode({
      "templateId": templateId,
      "exerciseId": exercise.id,
    });

    print("Adding exercise ${exercise.id} to template $templateId");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['id'];
      } else {
        print("Nem sikerült hozzáadni: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Hiba: $e");
      return null;
    }
  }

  Future<void> loadTopExercises() async {
    try {
      final workouts = await fetchUserWorkouts();

      final Map<int, int> exerciseCounts = {};

      for (final workout in workouts) {
        for (final workoutExercise in workout.exercises) {
          exerciseCounts[workoutExercise.exerciseId] =
              (exerciseCounts[workoutExercise.exerciseId] ?? 0) + 1;
        }
      }

      final sorted = exerciseCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final topIds = sorted
          .take(min(10, sorted.length))
          .map((e) => e.key)
          .toSet();

      final List<ExerciseDto> topList = [];
      final Set<int> addedIds = {};

      for (final workout in workouts) {
        for (final we in workout.exercises) {
          if (topIds.contains(we.exerciseId) &&
              !addedIds.contains(we.exerciseId)) {
            if (we.exercise != null) {
              topList.add(we.exercise!);
              addedIds.add(we.exerciseId);
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          searchResults = topList;
        });
      }
    } catch (e) {
      print("Hiba a top gyakorlatok betöltésekor: $e");
    }
  }

  Future<void> _searchExercises(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      loadTopExercises();
      return;
    }

    setState(() {
      anyResults = true;
      isLoading = true;
    });

    try {
      final uri = Uri.parse('$apiUrl/api/Workout/search?q=$q');
      final response = await http.get(uri);

      if (response.statusCode != 200) {
        print("Hiba: Státuszkód ${response.statusCode}");
        setState(() => searchResults = []);
        return;
      }

      final List<dynamic> decoded = jsonDecode(response.body);

      final results = decoded.map((e) => ExerciseDto.fromJson(e)).toList();

      setState(() => searchResults = results);
    } catch (e) {
      print("Keresési hiba: $e");
      setState(() => searchResults = []);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserWorkoutDto>>(
      future: futureExercises,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Hiba: ${snapshot.error}'));
        }

        // ignore: deprecated_member_use
        return WillPopScope(
          onWillPop: () async {
            if (widget.addToTemplate) {
              Navigator.pop(context, templateWorkouts);
            } else {
              Navigator.pop(context, userWorkouts);
            }
            return false;
          },
          child: Scaffold(
            body: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    margin: const EdgeInsets.fromLTRB(2, 6, 2, 0),
                    child: AppBar(
                      title: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: SizedBox(
                                height: 48,
                                child: TextField(
                                  controller: _controller,
                                  onChanged: (value) {
                                    if (_debounce?.isActive ?? false) {
                                      _debounce!.cancel();
                                    }
                                    _debounce = Timer(
                                      const Duration(milliseconds: 600),
                                      () {
                                        _searchExercises(value);
                                      },
                                    );
                                  },
                                  cursorColor: Colors.white,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: const Color.fromARGB(
                                      255,
                                      45,
                                      45,
                                      45,
                                    ),
                                    hintText: 'Keresés',
                                    hintStyle: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    border: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                        color: Colors.white24,
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                        color: Colors.white24,
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                        color: Colors.grey,
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 4),
                        ],
                      ),
                      backgroundColor: const Color.fromARGB(255, 58, 58, 58),
                      iconTheme: const IconThemeData(color: Colors.white),
                    ),
                  ),

                  !anyResults
                      ? ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            final exercise = searchResults[index];
                            final cleanName = stripHtmlTags(exercise.name);

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
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
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () async {
                                    if (widget.addToTemplate) {
                                      final prefs =
                                          await SharedPreferences.getInstance();
                                      final userId = prefs.getInt("userId");
                                      print("userId: ${userId}");
                                      if (userId != null &&
                                          widget.templateId != null) {
                                        await addExerciseToTemplate(
                                          widget.templateId!,
                                          userId,
                                          exercise,
                                        );
                                        print(widget.templateId);
                                        setState(() {
                                          templateWorkouts.add(exercise);
                                        });
                                      }
                                    } else {
                                      setState(() {
                                        userWorkouts.add(exercise);
                                      });
                                    }
                                    final cleanName = stripHtmlTags(
                                      exercise.name,
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '$cleanName hozzáadva a listádhoz!',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                        margin: EdgeInsets.only(
                                          bottom: 30,
                                          left: 16,
                                          right: 16,
                                        ),
                                        duration: Duration(milliseconds: 1800),
                                        animation: CurvedAnimation(
                                          parent: kAlwaysCompleteAnimation,
                                          curve: Curves.easeInOut,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(
                                        255,
                                        45,
                                        45,
                                        45,
                                      ),
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
                                                  '${exercise.category} | ${exercise.equipment} | ${exercise.force} | ${exercise.level} | ${exercise.mechanic}',
                                                  style: const TextStyle(
                                                    color: Colors.white70,
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
                              ),
                            );
                          },
                        )
                      : isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            final exercise = searchResults[index];
                            final cleanName = stripHtmlTags(exercise.name);

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () async {
                                  if (widget.addToTemplate) {
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    final userId = prefs.getInt("userId");

                                    if (userId != null &&
                                        widget.templateId != null) {
                                      final newId = await addExerciseToTemplate(
                                        widget.templateId!,
                                        userId,
                                        exercise,
                                      );

                                      if (newId != null) {
                                        final mealWithId = exercise.copyWith(
                                          id: newId,
                                        );

                                        setState(() {
                                          templateWorkouts.add(mealWithId);
                                        });
                                      }
                                    } else {
                                      print(
                                        "HIBA: UserId vagy TemplateId null! User: $userId, Template: ${widget.templateId}",
                                      );
                                    }
                                  } else {
                                    setState(() {
                                      userWorkouts.add(exercise);
                                    });
                                  }

                                  final cleanName = stripHtmlTags(
                                    exercise.name,
                                  );
                                  // ignore: use_build_context_synchronously
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '$cleanName hozzáadva a listádhoz!',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      margin: EdgeInsets.only(
                                        bottom: 30,
                                        left: 16,
                                        right: 16,
                                      ),
                                      duration: Duration(milliseconds: 1800),
                                      animation: CurvedAnimation(
                                        parent: kAlwaysCompleteAnimation,
                                        curve: Curves.easeInOut,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(
                                      255,
                                      45,
                                      45,
                                      45,
                                    ),
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
                                                '${exercise.category} | ${exercise.equipment} | ${exercise.force} | ${exercise.level} | ${exercise.mechanic}',
                                                style: const TextStyle(
                                                  color: Colors.white70,
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
                        ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => {
                if (_scrollController.hasClients)
                  {
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOut,
                    ),
                  },
              },
              backgroundColor: const Color.fromRGBO(85, 173, 78, 1),
              child: const Icon(
                Icons.arrow_upward,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        );
      },
    );
  }
}
