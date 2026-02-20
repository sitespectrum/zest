import 'dart:convert';
import 'dart:ui';
import 'package:client/components/ui/custom_button.dart';
import 'package:client/providers/language_provider.dart';
import 'package:client/components/custom_workout_page.dart';
import 'package:client/constants.dart';
import 'package:client/models/workout.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:client/components/ui/custom_card.dart';
import 'package:client/utils/scroll_behavior.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

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

class _WorkoutPageState extends State<WorkoutPage>
    with AutomaticKeepAliveClientMixin {
  String? username;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late Future<List<UserWorkoutDto>> _futureWorkouts;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadUser();
    initializeDateFormatting('hu_HU', null);
    initializeDateFormatting('en_US', null);
    _futureWorkouts = fetchUserWorkouts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString("username");
    });
  }

  Map<DateTime, List<UserWorkoutDto>> groupWorkoutsByDay(
    List<UserWorkoutDto> workouts,
  ) {
    final Map<DateTime, List<UserWorkoutDto>> grouped = {};
    for (var workout in workouts) {
      final d = DateTime(
        workout.date.year,
        workout.date.month,
        workout.date.day,
      );
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

    print("DELETE válasz: ${response.statusCode} - ${response.body}");
    print("TOKEN: $token");

    return response.statusCode == 204;
  }

  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final langCode = Provider.of<LanguageProvider>(context).languageCode;
    final String calendarLocale = lang.languageCode == 'hu' ? 'hu_HU' : 'en_US';
    final StartingDayOfWeek startDay = lang.languageCode == 'hu'
        ? StartingDayOfWeek.monday
        : StartingDayOfWeek.sunday;
    return ScrollConfiguration(
      behavior: NoGlowScrollBehavior(),
      child: SingleChildScrollView(
        physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        child: FutureBuilder<List<UserWorkoutDto>>(
          future: _futureWorkouts,
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
                      title: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: ClipRect(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                              sigmaX: 10.0,
                              sigmaY: 10.0,
                            ),
                            child: Container(
                              height: MediaQuery.of(context).size.height * 0.07,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color.fromRGBO(45, 45, 45, 0.5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                lang.getText("workout_page"),
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

                CustomCard(
                  title: lang.getText("previous_workouts"),
                  iconData: Icons.calendar_month,
                  child: TableCalendar(
                    locale: calendarLocale,
                    startingDayOfWeek: startDay,
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
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
                        color: const Color.fromARGB(150, 50, 146, 255),
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

                      final allWorkouts = await fetchUserWorkouts();
                      final grouped = groupWorkoutsByDay(allWorkouts);

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

                      DateTime tempSelectedDay = _selectedDay ?? DateTime.now();

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
                                backgroundColor: const Color(0xFF272727),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
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
                                              selectedDay = newDay;
                                            });
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
                                                                              setState(
                                                                                () {
                                                                                  _futureWorkouts = fetchUserWorkouts();
                                                                                },
                                                                              );
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
                                                  CustomButton(
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

                                                      setState(() {
                                                        selectedDay =
                                                            DateTime.now();
                                                        _selectedDay =
                                                            DateTime.now();
                                                        _focusedDay =
                                                            DateTime.now();
                                                      });
                                                    },
                                                    icon: const Icon(
                                                      Icons.add,
                                                      color: Colors.white,
                                                    ),
                                                    title: lang.getText(
                                                      "add_new_workout",
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
                                          bottom: 17,
                                          left: 17,
                                          right: 17,
                                        ),
                                        child: CustomButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          variant:
                                              CustomButtonVariant.secondary,
                                          title: lang.getText("close"),
                                          iconData: Icons.close,
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
                SizedBox(height: MediaQuery.of(context).size.height * 0.13),
              ],
            );
          },
        ),
      ),
    );
  }
}
