import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:zest_client/components/custom_workout_page.dart';
import 'package:zest_client/models/workout.dart';
import 'package:zest_client/providers/language_provider.dart';
import 'package:zest_client/servers.dart';

part "workout_page.g.dart";

Future<List<UserWorkoutDto>> fetchUserWorkouts() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');

  if (token == null) throw Exception("Nincs token");

  final response = await http.get(
    Uri.parse("$apiUrl/api/Workout/getUserWorkouts"),
    headers: {"Authorization": "Bearer $token"},
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((e) => UserWorkoutDto.fromJson(e)).toList();
  } else {
    throw Exception(response.body);
  }
}

Map<DateTime, List<UserWorkoutDto>> groupWorkoutsByDay(
  List<UserWorkoutDto> workouts,
) {
  final Map<DateTime, List<UserWorkoutDto>> grouped = {};
  for (var workout in workouts) {
    final d = DateTime(workout.date.year, workout.date.month, workout.date.day);
    grouped.putIfAbsent(d, () => []);
    grouped[d]!.add(workout);
  }
  return grouped;
}

Future<bool> deleteMeal(int workoutId) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');

  final url = Uri.parse("$apiUrl/api/Workout/deleteUserWorkout/$workoutId");

  final response = await http.delete(
    url,
    headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    },
  );

  if (kDebugMode) {
    print("DELETE válasz: ${response.statusCode} - ${response.body}");
    print("TOKEN: $token");
  }

  return response.statusCode == 204;
}

@hwidget
Widget workoutPage(BuildContext context) {
  useAutomaticKeepAlive(wantKeepAlive: true);
  final futureWorkouts = useState(fetchUserWorkouts());
  final focusedDay = useState(DateTime.now());
  final selectedDay = useState<DateTime?>(null);

  final lang = Provider.of<LanguageProvider>(context);
  final langCode = Provider.of<LanguageProvider>(context).languageCode;
  final String calendarLocale = lang.languageCode == 'hu' ? 'hu_HU' : 'en_US';
  final StartingDayOfWeek startDay = lang.languageCode == 'hu'
      ? StartingDayOfWeek.monday
      : StartingDayOfWeek.sunday;

  return SingleChildScrollView(
    child: FutureBuilder<List<UserWorkoutDto>>(
      future: futureWorkouts.value,
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                margin: const EdgeInsets.all(6),
                child: AppBar(
                  title: Text(
                    lang.getText("workout_page"),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  automaticallyImplyLeading: false,
                  backgroundColor: Colors.transparent,
                ),
              ),
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
                        // ignore: deprecated_member_use
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TableCalendar(
                    locale: calendarLocale,
                    startingDayOfWeek: startDay,
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: focusedDay.value,
                    selectedDayPredicate: (day) =>
                        isSameDay(selectedDay.value, day),
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
                    onDaySelected: (newSelectedDay, newFocusedDay) async {
                      selectedDay.value = newSelectedDay;
                      focusedDay.value = newFocusedDay;

                      final allWorkouts = await fetchUserWorkouts();
                      final grouped = groupWorkoutsByDay(allWorkouts);

                      final int window = 30;
                      final DateTime startDate = DateTime(
                        newSelectedDay.year,
                        newSelectedDay.month,
                        newSelectedDay.day,
                      ).subtract(Duration(days: window));
                      final List<DateTime> days = List.generate(
                        window * 2 + 1,
                        (i) => startDate.add(Duration(days: i)),
                      );
                      final int initialPage = window;

                      if (!context.mounted) return;

                      DateTime tempSelectedDay =
                          selectedDay.value ?? DateTime.now();

                      showDialog(
                        context: context,
                        builder: (context) {
                          final PageController controller = PageController(
                            initialPage: initialPage,
                          );
                          return StatefulBuilder(
                            builder: (context, setStateDialog) {
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
                                            selectedDay.value = newDay;
                                            focusedDay.value = newDay;
                                            newSelectedDay = newDay;
                                          },
                                          itemBuilder: (context, index) {
                                            final DateTime day = days[index];
                                            final List<UserWorkoutDto>
                                            workoutsForDay = grouped[day] ?? [];

                                            return Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Column(
                                                children: [
                                                  Text(
                                                    DateFormat.yMd(
                                                      calendarLocale,
                                                    ).format(day),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Expanded(
                                                    child:
                                                        workoutsForDay.isEmpty
                                                        ? Center(
                                                            child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
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
                                                                  lang.getText(
                                                                    "no_data_on_this_day",
                                                                  ),
                                                                  style: TextStyle(
                                                                    color: Colors
                                                                        .white70,
                                                                    fontSize:
                                                                        16,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          )
                                                        : ListView.builder(
                                                            itemCount:
                                                                workoutsForDay
                                                                    .length,
                                                            itemBuilder: (context, i) {
                                                              final workout =
                                                                  workoutsForDay[i];
                                                              final displayName =
                                                                  (workout
                                                                      .customName
                                                                      .isNotEmpty)
                                                                  ? workout
                                                                        .customName
                                                                  : workout
                                                                        .workoutName;

                                                              return Container(
                                                                margin:
                                                                    const EdgeInsets.symmetric(
                                                                      vertical:
                                                                          6,
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
                                                                    Row(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .spaceBetween,
                                                                      children: [
                                                                        Expanded(
                                                                          child: Text(
                                                                            displayName,
                                                                            style: const TextStyle(
                                                                              color: Colors.white,
                                                                              fontSize: 16,
                                                                              fontWeight: FontWeight.bold,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        IconButton(
                                                                          icon: const Icon(
                                                                            Icons.delete,
                                                                            color:
                                                                                Colors.red,
                                                                          ),
                                                                          onPressed: () async {
                                                                            final success = await deleteMeal(
                                                                              workout.id,
                                                                            );

                                                                            if (success) {
                                                                              setStateDialog(
                                                                                () {
                                                                                  grouped[day]!.removeAt(
                                                                                    i,
                                                                                  );
                                                                                },
                                                                              );

                                                                              futureWorkouts.value = fetchUserWorkouts();
                                                                            }
                                                                          },
                                                                        ),
                                                                      ],
                                                                    ),

                                                                    const SizedBox(
                                                                      height: 6,
                                                                    ),

                                                                    Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .start,
                                                                      children: [
                                                                        const SizedBox(
                                                                          height:
                                                                              8,
                                                                        ),
                                                                        ...workout.exercises.map((
                                                                          exerciseData,
                                                                        ) {
                                                                          return Padding(
                                                                            padding: const EdgeInsets.only(
                                                                              bottom: 8.0,
                                                                            ),
                                                                            child: Column(
                                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                                              children: [
                                                                                Text(
                                                                                  exerciseData.exercise?.getName(
                                                                                        langCode,
                                                                                      ) ??
                                                                                      lang.getText(
                                                                                        "unknown_exercise",
                                                                                      ),
                                                                                  style: const TextStyle(
                                                                                    color: Colors.green,
                                                                                    fontWeight: FontWeight.bold,
                                                                                    fontSize: 14,
                                                                                  ),
                                                                                ),
                                                                                Padding(
                                                                                  padding: const EdgeInsets.only(
                                                                                    left: 10.0,
                                                                                    top: 2,
                                                                                  ),
                                                                                  child: Column(
                                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                                    children: exerciseData.sets.map(
                                                                                      (
                                                                                        set,
                                                                                      ) {
                                                                                        final isCardio =
                                                                                            exerciseData.exercise?.category?.toLowerCase() ==
                                                                                            'cardio';
                                                                                        final isBodyweight =
                                                                                            exerciseData.exercise?.equipment?.toLowerCase() ==
                                                                                                'body only' ||
                                                                                            exerciseData.exercise?.equipment?.toLowerCase() ==
                                                                                                'none';

                                                                                        String textToShow = "";

                                                                                        if (isCardio) {
                                                                                          textToShow = "${set.weight} km | ${set.reps} ${lang.getText("min")}";
                                                                                        } else if (isBodyweight) {
                                                                                          textToShow = "${set.reps} ${lang.getText("reps")}";
                                                                                        } else {
                                                                                          textToShow = "${set.weight} kg x ${set.reps}";
                                                                                        }

                                                                                        return Text(
                                                                                          textToShow,
                                                                                          style: const TextStyle(
                                                                                            color: Colors.white70,
                                                                                            fontSize: 13,
                                                                                          ),
                                                                                        );
                                                                                      },
                                                                                    ).toList(),
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          );
                                                                        }).toList(),
                                                                      ],
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  ElevatedButton.icon(
                                                    onPressed: () async {
                                                      await Navigator.of(
                                                        context,
                                                      ).push(
                                                        MaterialPageRoute(
                                                          builder: (_) =>
                                                              CWorkoutPage(
                                                                selectedDay:
                                                                    tempSelectedDay,
                                                              ),
                                                        ),
                                                      );

                                                      selectedDay.value =
                                                          DateTime.now();
                                                      newSelectedDay =
                                                          DateTime.now();
                                                      focusedDay.value =
                                                          DateTime.now();
                                                    },
                                                    icon: const Icon(
                                                      Icons.add,
                                                      color: Colors.white,
                                                    ),
                                                    label: Text(
                                                      lang.getText(
                                                        "add_new_workout",
                                                      ),
                                                    ),
                                                    style:
                                                        ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.green,
                                                          foregroundColor:
                                                              Colors.white,
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
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
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
                      );
                    },
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.005,
                  left: MediaQuery.of(context).size.width * 0.09,
                  child: Text(
                    lang.getText("previous_meals"),
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
    ),
  );
}
