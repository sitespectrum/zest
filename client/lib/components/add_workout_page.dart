import 'dart:convert';
import 'package:client/components/create_workout_page.dart';
import 'package:client/models/workout.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/language_provider.dart';
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
  String? selectedFilter;
  List<String> muscleFilters = [];
  bool isFilterLoading = true;
  Set<int> _topExerciseIds = {};
  bool _isInit = true;

  List<ExerciseDto> userWorkouts = [];
  List<ExerciseDto> templateWorkouts = [];

  void addMeal(ExerciseDto exercise) {
    setState(() {
      userWorkouts.add(exercise);
    });
    final cleanName = stripHtmlTags(exercise.name);
    final lang = Provider.of<LanguageProvider>(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$cleanName ${lang.getText("added_to_list")}'),
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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      futureExercises = fetchUserWorkouts();
      loadTopExercises();
      fetchMuscleGroups();
      _isInit = false;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> fetchMuscleGroups() async {
    try {
      final langCode = Provider.of<LanguageProvider>(
        context,
        listen: false,
      ).languageCode;

      final response = await http.get(
        Uri.parse("$apiUrl/api/Workout/muscle-groups?lang=$langCode"),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            muscleFilters = data.cast<String>().toList();
            isFilterLoading = false;
          });
        }
      }
    } catch (e) {
      print("Hiba az izomcsoportok betöltésekor: $e");
      if (mounted) {
        setState(() {
          isFilterLoading = false;
        });
      }
    }
  }

  Future<void> _filterByMuscle(String muscle) async {
    setState(() {
      anyResults = true;
      isLoading = true;
    });

    try {
      final uri = Uri.parse(
        '$apiUrl/api/Workout/filter-by-muscle?muscle=${Uri.encodeQueryComponent(muscle)}',
      );

      print("DEBUG: Keresés indítása erre: $uri");

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);

        if (decoded == null) {
          setState(() => searchResults = []);
          return;
        }

        if (decoded is! List) {
          print("Hiba: A szerver nem listát küldött: $decoded");
          setState(() => searchResults = []);
          return;
        }

        final rawResults = decoded.map((e) => ExerciseDto.fromJson(e)).toList();
        final sortedResults = _sortWithTopPriority(rawResults);

        setState(() {
          searchResults = sortedResults;
        });
      } else {
        print("Szerver hiba kód: ${response.statusCode}");
        setState(() {
          searchResults = [];
        });
      }
    } catch (e, stackTrace) {
      print("Szűrési hiba: $e");
      print(stackTrace);
      setState(() => searchResults = []);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget _buildFilterList() {
    if (isFilterLoading) {
      return const SizedBox(
        height: 50,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (muscleFilters.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: muscleFilters.length,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemBuilder: (context, index) {
          final filterName = muscleFilters[index];
          final isSelected = selectedFilter == filterName;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filterName),
              selected: isSelected,
              onSelected: (bool selected) {
                setState(() {
                  if (isSelected) {
                    selectedFilter = null;
                    _controller.clear();
                    loadTopExercises();
                    anyResults = false;
                  } else {
                    selectedFilter = filterName;
                    _controller.clear();
                    _filterByMuscle(filterName);
                  }
                });
              },
              backgroundColor: const Color.fromARGB(255, 45, 45, 45),
              selectedColor: const Color.fromARGB(255, 85, 173, 78),
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? Colors.transparent : Colors.white24,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<List<UserWorkoutDto>> fetchUserWorkouts() async {
    final lang = Provider.of<LanguageProvider>(context);
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
      throw Exception(lang.getText("failed_to_fetch_meals"));
    }
  }

  Future<void> _addExerciseWrapper(ExerciseDto exercise) async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final langCode = lang.languageCode;

    if (widget.addToTemplate) {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt("userId");

      if (userId != null && widget.templateId != null) {
        final newId = await addExerciseToTemplate(
          widget.templateId!,
          userId,
          exercise,
        );

        if (newId != null) {
          final exerciseWithId = exercise.copyWith(id: newId);
          setState(() {
            templateWorkouts.add(exerciseWithId);
          });
        }
      }
    } else {
      setState(() {
        userWorkouts.add(exercise);
      });
    }

    final cleanName = stripHtmlTags(exercise.getName(langCode));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$cleanName ${lang.getText("added_to_list")}'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 30, left: 16, right: 16),
          duration: const Duration(milliseconds: 1800),
          animation: CurvedAnimation(
            parent: kAlwaysCompleteAnimation,
            curve: Curves.easeInOut,
          ),
        ),
      );
    }
  }

  void _showExerciseDetails(ExerciseDto exercise) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final langCode = lang.languageCode;
    print(
      "DEBUG LEÍRÁS: ${exercise.instructions} / HU: ${exercise.instructionsHu}",
    );

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
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
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (exercise.images.isNotEmpty)
                              Container(
                                width: double.infinity,
                                clipBehavior: Clip.hardEdge,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    "https://raw.githubusercontent.com/sitespectrum/zest_exercises/main/exercises/${exercise.images[0]}",
                                    fit: BoxFit.contain,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
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
                                  ),
                                ),
                              ),
                            const SizedBox(height: 20),
                            Text(
                              exercise.getName(langCode),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              lang.getText("description"),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 30, 30, 30),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Text(
                                exercise.getInstructions(langCode).join('\n\n'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
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
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              lang.getText("close"),
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              _addExerciseWrapper(exercise);
                              Navigator.pop(context);
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                85,
                                173,
                                78,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              lang.getText("add"),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
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
            );
          },
        );
      },
    );
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

      _topExerciseIds = sorted
          .take(min(10, sorted.length))
          .map((e) => e.key)
          .toSet();

      final topIds = _topExerciseIds;

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

  List<ExerciseDto> _sortWithTopPriority(List<ExerciseDto> exercises) {
    List<ExerciseDto> topPart = [];
    List<ExerciseDto> otherPart = [];

    for (var ex in exercises) {
      if (_topExerciseIds.contains(ex.id)) {
        topPart.add(ex);
      } else {
        otherPart.add(ex);
      }
    }

    otherPart.sort((a, b) => a.name.compareTo(b.name));

    return [...topPart, ...otherPart];
  }

  Future<void> _searchExercises(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      if (selectedFilter != null) {
        _filterByMuscle(selectedFilter!);
      } else {
        loadTopExercises();
      }
      return;
    }

    setState(() {
      anyResults = true;
      isLoading = true;
    });

    try {
      String url = '$apiUrl/api/Workout/search?q=$q';
      if (selectedFilter != null) {
        url += '&muscle=$selectedFilter';
      }
      final uri = Uri.parse(url);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> decoded = jsonDecode(response.body);
        var results = decoded.map((e) => ExerciseDto.fromJson(e)).toList();

        setState(() => searchResults = results);
      } else {
        setState(() => searchResults = []);
      }
    } catch (e) {
      print("Keresési hiba: $e");
      setState(() => searchResults = []);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final langCode = Provider.of<LanguageProvider>(context).languageCode;
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                    hintText: lang.getText("search_hint"),
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

                          const SizedBox(width: 6),

                          Container(
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 85, 173, 78),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const CreateWorkoutPage(),
                                  ),
                                );
                              },
                              icon: const Icon(
                                CupertinoIcons.add_circled,
                                size: 25,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: const Color.fromARGB(255, 58, 58, 58),
                      iconTheme: const IconThemeData(color: Colors.white),
                    ),
                  ),

                  _buildFilterList(),

                  !anyResults
                      ? ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            final exercise = searchResults[index];
                            final cleanName = stripHtmlTags(
                              exercise.getName(langCode),
                            );

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
                                      color: Colors.black.withOpacity(0.5),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () async {
                                    await _addExerciseWrapper(exercise);
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
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          Expanded(
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
                                                        '${exercise.getCategory(langCode)} | ${exercise.getEquipment(langCode)} | ${exercise.getForce(langCode)} | ${exercise.getLevel(langCode)} | ${exercise.getMechanic(langCode)} | ${exercise.getPMuscles(langCode).join(", ")}',
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
                                          IconButton(
                                            onPressed: () {
                                              _showExerciseDetails(exercise);
                                            },
                                            icon: const Icon(
                                              Icons.search,
                                              color: Color.fromARGB(
                                                255,
                                                85,
                                                173,
                                                78,
                                              ),
                                              size: 28,
                                            ),
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
                            final cleanName = stripHtmlTags(
                              exercise.getName(langCode),
                            );

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
                                    }
                                  } else {
                                    setState(() {
                                      userWorkouts.add(exercise);
                                    });
                                  }
                                  final cleanName = stripHtmlTags(
                                    exercise.getName(langCode),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '$cleanName ${lang.getText("added_to_list")}',
                                      ),
                                      behavior: SnackBarBehavior.floating,
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
                                        color: Colors.black.withOpacity(0.5),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        Expanded(
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
                                                      '${exercise.getCategory(langCode)} | ${exercise.getEquipment(langCode)} | ${exercise.getForce(langCode)} | ${exercise.getLevel(langCode)} | ${exercise.getMechanic(langCode)}',
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
                                        IconButton(
                                          onPressed: () {
                                            _showExerciseDetails(exercise);
                                          },
                                          icon: const Icon(
                                            Icons.search,
                                            color: Color.fromARGB(
                                              255,
                                              85,
                                              173,
                                              78,
                                            ),
                                            size: 28,
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
