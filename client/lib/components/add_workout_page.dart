import 'dart:convert';
import 'dart:ui';
import 'package:client/components/create_workout_page.dart';
import 'package:client/components/ui/custom_button.dart';
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
import 'package:client/components/ui/custom_snackbar.dart';

class AddWorkoutPage extends StatefulWidget {
  final bool addToTemplate;
  final int? templateId;

  const AddWorkoutPage({
    super.key,
    this.addToTemplate = false,
    this.templateId,
  });

  @override
  State<AddWorkoutPage> createState() => _AddWorkoutPageState();
}

String stripHtmlTags(String htmlText) {
  final exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
  return htmlText.replaceAll(exp, '');
}

class _AddWorkoutPageState extends State<AddWorkoutPage> {
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

  final Color primaryBlue = const Color.fromARGB(255, 50, 146, 255);

  List<ExerciseDto> userWorkouts = [];
  List<ExerciseDto> templateWorkouts = [];

  final ScrollController _scrollController = ScrollController();
  late Future<List<UserWorkoutDto>> futureExercises;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();

    if (userWorkouts.isEmpty) {
      await prefs.remove('draft_workout');
    } else {
      final jsonString = jsonEncode(
        userWorkouts.map((e) => e.toJson()).toList(),
      );
      await prefs.setString('draft_workout', jsonString);
    }
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
    _controller.dispose();
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

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);

        if (decoded == null) {
          setState(() => searchResults = []);
          return;
        }

        if (decoded is! List) {
          setState(() => searchResults = []);
          return;
        }

        final rawResults = decoded.map((e) => ExerciseDto.fromJson(e)).toList();
        final sortedResults = _sortWithTopPriority(rawResults);

        setState(() {
          searchResults = sortedResults;
        });
      } else {
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
      margin: const EdgeInsets.only(top: 10, bottom: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: muscleFilters.length,
        padding: const EdgeInsets.symmetric(horizontal: 20),
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
              selectedColor: primaryBlue,
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
      _saveDraft();
    }

    final cleanName = stripHtmlTags(exercise.getName(langCode));
    if (mounted) {
      CustomSnackbar.show(
        context,
        '$cleanName ${lang.getText("added_to_list")}',
        backgroundColor: primaryBlue,
      );
    }
  }

  void _showExerciseDetails(ExerciseDto exercise) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final langCode = lang.languageCode;

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
                          child: CustomButton(
                            variant: CustomButtonVariant.secondary,
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              lang.getText("close"),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CustomButton(
                            variant: CustomButtonVariant.primaryWorkout,
                            onPressed: () {
                              _addExerciseWrapper(exercise);
                              Navigator.pop(context);
                            },
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
        return null;
      }
    } catch (e) {
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

  Widget _buildExerciseItem(
    ExerciseDto exercise,
    String langCode,
    LanguageProvider lang,
  ) {
    final cleanName = stripHtmlTags(exercise.getName(langCode));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
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
          splashColor: primaryBlue.withOpacity(0.2),
          highlightColor: primaryBlue.withOpacity(0.1),
          onTap: () async {
            await _addExerciseWrapper(exercise);
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                              style: const TextStyle(color: Colors.white70),
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
                  icon: Icon(Icons.search, color: primaryBlue, size: 28),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final langCode = Provider.of<LanguageProvider>(context).languageCode;

    return FutureBuilder<List<UserWorkoutDto>>(
      future: futureExercises,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(backgroundColor: Colors.transparent),
            body: Center(child: Text('Hiba: ${snapshot.error}')),
          );
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
            extendBodyBehindAppBar: true,
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                margin: const EdgeInsets.only(left: 2),
                child: AppBar(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ClipRRect(
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
                                    onPressed: () {
                                      if (widget.addToTemplate) {
                                        Navigator.pop(
                                          context,
                                          templateWorkouts,
                                        );
                                      } else {
                                        Navigator.pop(context, userWorkouts);
                                      }
                                    },
                                  ),
                                  Text(
                                    lang.getText("new_workout"),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            50,
                            50,
                            146,
                            255,
                          ),
                          disabledBackgroundColor: const Color.fromARGB(
                            25,
                            64,
                            255,
                            50,
                          ),
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.white38,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(
                            color: const Color.fromARGB(150, 50, 146, 255),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CreateWorkoutPage(),
                            ),
                          );
                        },
                        icon: const Icon(
                          CupertinoIcons.add_circled,
                          size: 25,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  automaticallyImplyLeading: false,
                  backgroundColor: Colors.transparent,
                  iconTheme: const IconThemeData(color: Colors.white),
                ),
              ),
            ),
            body: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(height: MediaQuery.of(context).padding.top + 70),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
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
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color.fromARGB(255, 45, 45, 45),
                        hintText: lang.getText("search_hint"),
                        hintStyle: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        prefixIcon: Icon(Icons.search, color: Colors.white54),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Colors.white24,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: primaryBlue,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Colors.white24,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ),

                _buildFilterList(),

                Expanded(
                  child: !anyResults
                      ? ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.only(bottom: 80),
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            return _buildExerciseItem(
                              searchResults[index],
                              langCode,
                              lang,
                            );
                          },
                        )
                      : isLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.only(bottom: 80),
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            return _buildExerciseItem(
                              searchResults[index],
                              langCode,
                              lang,
                            );
                          },
                        ),
                ),
              ],
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
              backgroundColor: primaryBlue,
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
