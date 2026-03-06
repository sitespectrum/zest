import 'package:client/providers/language_provider.dart';
import 'package:client/services/websocket_service.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:client/components/ui/custom_button.dart';
import 'package:client/models/workout.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:client/constants.dart';
import 'package:intl/intl.dart';

class PlayerStats {
  final int userId;
  final String userName;
  final String? profilePicture;
  double totalVolume = 0;
  int totalReps = 0;
  int totalSets = 0;
  double maxWeight = 0;
  double score = 0;

  PlayerStats({
    required this.userId,
    required this.userName,
    this.profilePicture,
  });
}

class SharedWorkoutSummaryPage extends StatefulWidget {
  final Map<String, dynamic> finalState;
  final List<ExerciseDto> userWorkouts;
  final bool isHost;

  const SharedWorkoutSummaryPage({
    super.key,
    required this.finalState,
    required this.userWorkouts,
    required this.isHost,
  });

  @override
  State<SharedWorkoutSummaryPage> createState() =>
      _SharedWorkoutSummaryPageState();
}

class _SharedWorkoutSummaryPageState extends State<SharedWorkoutSummaryPage> {
  bool _hasSaved = false;

  @override
  void initState() {
    super.initState();
    _autoSaveMyWorkout();
  }

  String _dependOnHour(String langCode) {
    final hour = DateTime.now().hour;
    if (langCode == 'hu') {
      if (6 <= hour && hour < 12) return "reggeli közös edzés";
      if (12 <= hour && hour < 18) return "délutáni közös edzés";
      if (18 <= hour && hour < 21) return "esti közös edzés";
      return "éjszakai közös edzés";
    } else {
      if (6 <= hour && hour < 12) return "Morning Shared Workout";
      if (12 <= hour && hour < 18) return "Afternoon Shared Workout";
      if (18 <= hour && hour < 21) return "Evening Shared Workout";
      return "Night Shared Workout";
    }
  }

  Future<void> _autoSaveMyWorkout() async {
    if (_hasSaved) return;
    _hasSaved = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      final token = prefs.getString('jwt_token');

      if (userId == null || token == null) return;

      List stats = widget.finalState['stats'] ?? [];
      var myStats = stats.where((s) => s['userId'] == userId).toList();

      if (myStats.isEmpty) return;

      List<ExerciseDto> exercisesToSave = [];
      double totalVolume = 0;
      int totalSets = 0;

      for (var ex in widget.userWorkouts) {
        var myStatForEx = myStats.firstWhere(
          (s) => s['exerciseId'] == ex.id,
          orElse: () => null,
        );
        if (myStatForEx != null) {
          List setsData = myStatForEx['sets'] ?? [];
          if (setsData.isNotEmpty) {
            var exCopy = ex.copyWith();
            List<WorkoutSetDto> completedSets = [];

            for (var s in setsData) {
              double w = (s['weight'] as num).toDouble();
              int r = (s['reps'] as num).toInt();
              completedSets.add(
                WorkoutSetDto(weight: w, reps: r, isCompleted: true),
              );
              totalVolume += (w * r);
              totalSets++;
            }
            exCopy.sets = completedSets;
            exercisesToSave.add(exCopy);
          }
        }
      }

      if (exercisesToSave.isEmpty) return;

      int durationMinutes = totalSets * 3;
      if (durationMinutes < 10) durationMinutes = 10;
      int burntCalories = (3.5 * 3.5 * 75 / 200 * durationMinutes).toInt();

      final langProvider = Provider.of<LanguageProvider>(
        context,
        listen: false,
      );
      final locale = langProvider.languageCode == 'hu' ? 'hu_HU' : 'en_US';
      String timeStr = _dependOnHour(langProvider.languageCode);
      String workoutName =
          "${DateFormat.MMMd(locale).format(DateTime.now())} $timeStr";

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
        "CaloriesBurnt": burntCalories,
        "TotalVolume": totalVolume.toInt(),
        "IsCustom": false,
      };

      final response = await http.post(
        Uri.parse("$apiUrl/api/Workout/AddWorkout"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(dto),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("✅ Közös edzés sikeresen mentve a profilhoz!");
      } else {
        debugPrint("❌ Hiba a közös edzés mentésekor: ${response.body}");
      }
    } catch (e) {
      debugPrint("❌ Kivétel a mentéskor: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    List players = widget.finalState['players'] ?? [];
    List stats = widget.finalState['stats'] ?? [];

    Map<int, PlayerStats> playerStatsMap = {};
    for (var p in players) {
      playerStatsMap[p['userId']] = PlayerStats(
        userId: p['userId'],
        userName: p['userName'],
        profilePicture: p['profilePicture'],
      );
    }

    for (var stat in stats) {
      int uId = stat['userId'];
      List sets = stat['sets'] ?? [];
      var pStat = playerStatsMap[uId];

      if (pStat != null) {
        for (var s in sets) {
          double w = (s['weight'] as num).toDouble();
          int r = (s['reps'] as num).toInt();

          pStat.totalVolume += (w * r);
          pStat.totalReps += r;
          pStat.totalSets += 1;
          if (w > pStat.maxWeight) pStat.maxWeight = w;
        }
      }
    }

    for (var pStat in playerStatsMap.values) {
      pStat.score =
          (pStat.totalVolume * 0.5) +
          (pStat.totalReps * 2) +
          (pStat.maxWeight * 5) +
          (pStat.totalSets * 10);
    }

    var sortedPlayers = playerStatsMap.values.toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        title: Text(
          lang.getText('shared_workout_summary'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
            const SizedBox(height: 15),
            Text(
              lang.getText('great_job_everyone'),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 25),
            Text(
              lang.getText('leaderboard'),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: sortedPlayers.length,
                itemBuilder: (context, index) {
                  var pStat = sortedPlayers[index];

                  final profilePicData = pStat.profilePicture;
                  final hasProfilePic =
                      profilePicData != null &&
                      profilePicData.toString().trim().isNotEmpty;

                  Uint8List? imageBytes;
                  if (hasProfilePic) {
                    try {
                      String cleanBase64 = profilePicData.toString();
                      if (cleanBase64.contains(',')) {
                        cleanBase64 = cleanBase64.split(',').last;
                      }
                      cleanBase64 = cleanBase64.replaceAll(RegExp(r'\s+'), '');
                      imageBytes = base64Decode(cleanBase64);
                    } catch (e) {
                      imageBytes = null;
                    }
                  }

                  Color medalColor;
                  if (index == 0) {
                    medalColor = Colors.amber;
                  } else if (index == 1) {
                    medalColor = Colors.grey.shade300;
                  } else if (index == 2) {
                    medalColor = Colors.brown.shade400;
                  } else {
                    medalColor = Colors.transparent;
                  }

                  return Card(
                    color: const Color(0xFF272727),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: index == 0
                            ? Colors.amber.withOpacity(0.5)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 30,
                                child: Text(
                                  "${index + 1}.",
                                  style: TextStyle(
                                    color: index < 3
                                        ? medalColor
                                        : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              CircleAvatar(
                                radius: 20,
                                backgroundColor:
                                    medalColor == Colors.transparent
                                    ? Colors.black26
                                    : medalColor,
                                child: CircleAvatar(
                                  radius: index < 3 ? 18 : 20,
                                  backgroundColor: const Color(0xFF272727),
                                  backgroundImage: imageBytes != null
                                      ? MemoryImage(imageBytes)
                                      : null,
                                  child: imageBytes == null
                                      ? const Icon(
                                          Icons.person,
                                          color: Colors.white,
                                          size: 20,
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Text(
                                  pStat.userName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    lang.getText('score'),
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    pStat.score.toStringAsFixed(0),
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.0),
                            child: Divider(height: 1, color: Colors.white12),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildStatItem(
                                lang.getText('volume'),
                                "${pStat.totalVolume.toStringAsFixed(0)} kg",
                                Icons.fitness_center,
                              ),
                              _buildStatItem(
                                lang.getText('reps'),
                                "${pStat.totalReps}",
                                Icons.repeat,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildStatItem(
                                lang.getText('sets'),
                                "${pStat.totalSets}",
                                Icons.layers,
                              ),
                              _buildStatItem(
                                lang.getText('max_weight'),
                                "${pStat.maxWeight.toStringAsFixed(1)} kg",
                                Icons.local_fire_department,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: CustomButton(
                  onPressed: () {
                    if (widget.isHost) {
                      WebSocketService().sendAction('end-shared-workout', {});
                    } else {
                      WebSocketService().sendAction('leave-shared-workout', {});
                      SharedPreferences.getInstance().then((prefs) {
                        prefs.remove('active_session_id');
                        prefs.remove('is_host');
                        WebSocketService().disconnect();
                      });
                    }
                    Navigator.pop(context);
                  },
                  variant: CustomButtonVariant.secondary,
                  title: lang.getText('close'),
                  iconData: Icons.home,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white38, size: 16),
        const SizedBox(width: 6),
        Text(
          "$label: ",
          style: const TextStyle(color: Colors.white54, fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
