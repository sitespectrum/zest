import 'package:client/components/ui/custom_button.dart';
import 'package:client/models/workout.dart';
import 'package:client/providers/workout_provider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:provider/provider.dart';
import 'package:client/components/ui/custom_drawer.dart';
import 'package:client/providers/language_provider.dart';

part "recent_w_drawer.g.dart";

@hwidget
Widget recentWDrawer(
  BuildContext context,
  UserWorkoutDto lastWorkout,
  int currentWorkoutNum,
  LanguageProvider lang,
  WorkoutProvider workoutProvider,
) {
  final lang = Provider.of<LanguageProvider>(context, listen: false);
  double calculatedVolume = 0;
  double calculatedDistance = 0;

  for (var ex in lastWorkout.exercises) {
    final isCardio = ex.exercise?.category?.toLowerCase() == 'cardio';
    for (var s in ex.sets) {
      if (isCardio) {
        calculatedDistance += s.weight;
      } else {
        calculatedVolume += s.weight * s.reps;
      }
    }
  }

  String formattedDuration = "0m";
  if (lastWorkout.durationMinutes != null) {
    int minutes = lastWorkout.durationMinutes!;
    if (minutes >= 60) {
      int hours = minutes ~/ 60;
      int mins = minutes % 60;
      formattedDuration = "${hours}h ${mins}m";
    } else {
      formattedDuration = "${minutes}m";
    }
  }

  return CustomDrawer(
    child: SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.history,
                      color: Color.fromARGB(150, 50, 146, 255),
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lastWorkout.workoutName.isNotEmpty
                              ? lastWorkout.workoutName
                              : lastWorkout.customName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          lastWorkout.date.toString().split(' ')[0],
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(
                      150,
                      50,
                      146,
                      255,
                    ).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color.fromARGB(150, 50, 146, 255),
                    ),
                  ),
                  child: Text(
                    "#$currentWorkoutNum",
                    style: const TextStyle(
                      color: Color.fromARGB(150, 50, 146, 255),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white24),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  Icons.fitness_center,
                  "${lastWorkout.exercises.length}",
                  lang.getText("exercises"),
                ),
                _buildStatItem(
                  Icons.bar_chart,
                  calculatedDistance > 0
                      ? "${calculatedDistance.toStringAsFixed(1)} km"
                      : "${calculatedVolume.toInt()} kg",
                  calculatedDistance > 0 ? "Distance" : "Volume",
                ),
                _buildStatItem(
                  Icons.timer,
                  formattedDuration,
                  lang.getText("duration"),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              lang.getText("exercises"),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Center(child: Text("Set", style: _headerStyle)),
                ),
                Expanded(
                  flex: 2,
                  child: Center(child: Text("Rep", style: _headerStyle)),
                ),
                Expanded(
                  flex: 2,
                  child: Center(child: Text("kg", style: _headerStyle)),
                ),
                Expanded(flex: 7, child: Container()),
              ],
            ),
          ),

          const SizedBox(height: 5),

          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.zero,
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.75,
              ),
              itemCount: lastWorkout.exercises.length,
              itemBuilder: (context, index) {
                final exercise = lastWorkout.exercises[index];
                return Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 40, 40, 40),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                        ),
                        child: Text(
                          exercise.exercise?.name ?? "Unknown",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color.fromARGB(255, 61, 145, 239),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: exercise.sets.asMap().entries.map((
                              entry,
                            ) {
                              int setIndex = entry.key + 1;
                              var s = entry.value;
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: Center(
                                        child: Text(
                                          "$setIndex.",
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Center(
                                        child: Text(
                                          "${s.reps}",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Center(
                                        child: Text(
                                          "${s.weight}",
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: CustomButton(
              onPressed: () => Navigator.pop(context),
              variant: CustomButtonVariant.secondary,
              child: Text(
                lang.getText("close"),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildStatItem(IconData icon, String value, String label) {
  return Column(
    children: [
      Icon(icon, color: const Color.fromARGB(150, 50, 146, 255), size: 24),
      const SizedBox(height: 4),
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
    ],
  );
}

const TextStyle _headerStyle = TextStyle(
  color: Colors.white70,
  fontSize: 12,
  fontWeight: FontWeight.bold,
);
