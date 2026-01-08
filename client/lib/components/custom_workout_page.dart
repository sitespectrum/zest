import 'dart:convert';
import 'package:client/constants.dart';
import 'package:flutter/material.dart';
import 'package:client/models/workout.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'add_workout_page.dart';

class CWorkoutPage extends StatefulWidget {
  const CWorkoutPage({super.key});

  @override
  State<CWorkoutPage> createState() => _CWorkoutPageState();
}

class _CWorkoutPageState extends State<CWorkoutPage> {
  List<ExerciseDto> userWorkouts = [];
  late Future<List<CustomUserWorkoutDto>> futureCustomWorkouts;

  @override
  void initState() {
    super.initState();
    futureCustomWorkouts = fetchCustomUserWorkouts().catchError((e) {
      return <CustomUserWorkoutDto>[];
    });
  }

  Future<List<CustomUserWorkoutDto>> fetchCustomUserWorkouts() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) throw Exception("Nincs token");

    final response = await http.get(
      Uri.parse("$apiUrl/api/workout/getCustomUserWorkouts"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => CustomUserWorkoutDto.fromJson(e)).toList();
    } else {
      throw Exception("Nem sikerült lekérni az étkezéseket: ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    const appTitle = "Új edzés";
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, userWorkouts);
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
                    backgroundColor: const Color.fromARGB(255, 58, 58, 58),
                    iconTheme: const IconThemeData(color: Colors.white),
                  ),
                ),
              ),
              Container(
                child: userWorkouts.isEmpty
                    ? Center(
                        child: Column(
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                'Nincsenek hozzáadott gyakorlatok',
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
                        itemCount: userWorkouts.length,
                        itemBuilder: (context, index) {
                          final exerciseItem = userWorkouts[index];
                          final name =
                              exerciseItem.name ?? "Ismeretlen gyakorlat";

                          return GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return StatefulBuilder(
                                    builder: (context, setStateDialog) {
                                      return Dialog(
                                        insetPadding: const EdgeInsets.all(20),
                                        backgroundColor: const Color.fromARGB(
                                          255,
                                          30,
                                          30,
                                          30,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
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
                                            border: Border.all(
                                              color: Colors.white24,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              SingleChildScrollView(
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    if (exerciseItem
                                                        .images
                                                        .isNotEmpty)
                                                      Container(
                                                        height:
                                                            MediaQuery.of(
                                                              context,
                                                            ).size.height *
                                                            0.5,
                                                        width: double.infinity,
                                                        margin: EdgeInsets.only(
                                                          bottom: 16,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                          border: Border.all(
                                                            color:
                                                                Colors.white24,
                                                          ),
                                                        ),
                                                        child: ClipRRect(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                          child: Image.network(
                                                            "https://raw.githubusercontent.com/sitespectrum/zest_exercises/main/exercises/${exerciseItem.images[0]}",
                                                            fit: BoxFit.contain,
                                                            loadingBuilder:
                                                                (
                                                                  context,
                                                                  child,
                                                                  loadingProgress,
                                                                ) {
                                                                  if (loadingProgress ==
                                                                      null)
                                                                    return child;
                                                                  return const Center(
                                                                    child:
                                                                        CircularProgressIndicator(),
                                                                  );
                                                                },
                                                            errorBuilder:
                                                                (
                                                                  context,
                                                                  error,
                                                                  stackTrace,
                                                                ) {
                                                                  return const Center(
                                                                    child: Icon(
                                                                      Icons
                                                                          .fitness_center,
                                                                      color: Colors
                                                                          .white24,
                                                                      size: 50,
                                                                    ),
                                                                  );
                                                                },
                                                          ),
                                                        ),
                                                      ),
                                                    Text(
                                                      name,
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 16),
                                                    const Text(
                                                      "Leírás",
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 17,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        decoration:
                                                            TextDecoration
                                                                .underline,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Flexible(
                                                      child: SingleChildScrollView(
                                                        child: Container(
                                                          width:
                                                              double.infinity,
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
                                                              color: Colors
                                                                  .white24,
                                                            ),
                                                          ),
                                                          child: Text(
                                                            exerciseItem
                                                                .instructions
                                                                .join('\n\n'),
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 15,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 16),
                                                  ],
                                                ),
                                              ),
                                              ElevatedButton(
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
                                                child: const Text(
                                                  "Bezárás",
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
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
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 6,
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
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
                                          name,
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
                                              child: Text.rich(
                                                TextSpan(
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 14,
                                                  ),
                                                  children: [
                                                    const TextSpan(
                                                      text: 'Category: ',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text:
                                                          '${exerciseItem.category} | ',
                                                    ),

                                                    const TextSpan(
                                                      text: 'Equipment: ',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),

                                                    TextSpan(
                                                      text:
                                                          '${exerciseItem.equipment} | ',
                                                    ),

                                                    const TextSpan(
                                                      text: 'Force: ',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text:
                                                          '${exerciseItem.force ?? "-"} | ',
                                                    ),

                                                    const TextSpan(
                                                      text: 'Level: ',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text:
                                                          '${exerciseItem.level} | ',
                                                    ),

                                                    const TextSpan(
                                                      text: 'Mechanic: ',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text:
                                                          '${exerciseItem.mechanic ?? "-"} | ',
                                                    ),

                                                    const TextSpan(
                                                      text: 'Primary muscle: ',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text: exerciseItem
                                                          .primaryMuscles
                                                          .join(", "),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Center(
                                          child: TextButton(
                                            onPressed: () => {
                                              setState(() {
                                                userWorkouts.removeAt(index);
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
                            ),
                          );
                        },
                      ),
              ),

              SizedBox(height: 20),

              Center(
                child: Text(
                  "Sablonjaim",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              FutureBuilder<List<CustomUserWorkoutDto>>(
                future: futureCustomWorkouts,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        "Hiba történt: ${snapshot.error}",
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  final templates = snapshot.data ?? [];

                  if (templates.isEmpty) {
                    return const Center(
                      child: Text(
                        "Nincs sablon létrehozva.",
                        style: TextStyle(color: Colors.white70, fontSize: 18),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: templates.length,
                    itemBuilder: (context, index) {
                      final template = templates[index];

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 6,
                        ),
                        child: InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  backgroundColor: const Color.fromARGB(
                                    255,
                                    30,
                                    30,
                                    30,
                                  ),
                                  title: Text(
                                    template.customWorkoutName,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  content: SizedBox(
                                    width: double.maxFinite,
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: template.exercises.length,
                                      itemBuilder: (ctx, i) {
                                        final ex = template.exercises[i];
                                        return ListTile(
                                          title: Text(
                                            ex.exercise?.name ?? "Gyakorlat",
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          subtitle: Text(
                                            "${ex.sets.length} sorozat",
                                            style: const TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text(
                                        "Mégse",
                                        style: TextStyle(color: Colors.white54),
                                      ),
                                    ),
                                    FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: const Color.fromARGB(
                                          255,
                                          85,
                                          173,
                                          78,
                                        ),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          final exercisesFromTemplate = template
                                              .exercises
                                              .map((we) => we.exercise)
                                              .where((e) => e != null)
                                              .cast<ExerciseDto>()
                                              .toList();

                                          userWorkouts.addAll(
                                            exercisesFromTemplate,
                                          );
                                        });
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "${template.customWorkoutName} betöltve!",
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Text("Betöltés"),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 45, 45, 45),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        template.customWorkoutName.isNotEmpty
                                            ? template.customWorkoutName
                                            : "Ismeretlen sablon",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${template.exercises.length} gyakorlat',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: Colors.white54,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
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
                  final result = await Navigator.push<List<ExerciseDto>>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddWorkoutPage(),
                    ),
                  );

                  if (result != null) {
                    setState(() {
                      userWorkouts.addAll(result);
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
                onPressed: () {},
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
                  'Kezdés',
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
