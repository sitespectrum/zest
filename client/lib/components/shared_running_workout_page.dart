import 'dart:convert';
import 'package:client/components/running_workout_page.dart';
import 'package:client/components/ui/custom_snackbar.dart';
import 'package:client/constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:client/models/workout.dart';
import 'package:client/providers/language_provider.dart';
import 'package:client/services/websocket_service.dart';
import 'package:client/components/ui/custom_button.dart';
import 'package:client/components/shared_workout_summary_page.dart';

class SharedRunningWorkoutPage extends StatefulWidget {
  final List<ExerciseDto> userWorkouts;
  final Map<String, dynamic> initialGameState;

  const SharedRunningWorkoutPage({
    super.key,
    required this.userWorkouts,
    required this.initialGameState,
  });

  @override
  State<SharedRunningWorkoutPage> createState() =>
      _SharedRunningWorkoutPageState();
}

class _SharedRunningWorkoutPageState extends State<SharedRunningWorkoutPage> {
  late Map<String, dynamic> gameState;
  int myUserId = 0;
  bool isHost = false;
  final Color primaryBlue = const Color.fromARGB(255, 50, 146, 255);

  @override
  void initState() {
    super.initState();
    gameState = widget.initialGameState;
    _initUser();

    WebSocketService().onMessageReceived = _handleWebSocketMessage;
  }

  void _restoreMySets() {
    if (myUserId == 0) return;
    List stats = gameState['stats'] ?? [];
    var myStats = stats.where((s) => s['userId'] == myUserId).toList();

    for (var stat in myStats) {
      int exId = stat['exerciseId'];
      for (var ex in widget.userWorkouts) {
        if (ex.id == exId) {
          List setsData = stat['sets'] ?? [];
          if (ex.sets.isEmpty && setsData.isNotEmpty) {
            List<WorkoutSetDto> restoredSets = [];
            for (var s in setsData) {
              restoredSets.add(
                WorkoutSetDto(
                  weight: (s['weight'] as num?)?.toDouble() ?? 0.0,
                  reps: s['reps'] as int? ?? 0,
                  isCompleted: true,
                ),
              );
            }
            ex.sets = restoredSets;
          }
          break;
        }
      }
    }
  }

  Future<void> _initUser() async {
    final prefs = await SharedPreferences.getInstance();
    isHost = prefs.getBool('is_host') ?? false;

    myUserId = prefs.getInt('userId') ?? 0;

    if (myUserId == 0) {
      final token = prefs.getString('jwt_token');
      if (token != null) {
        try {
          final parts = token.split('.');
          if (parts.length >= 2) {
            String normalized = base64Url.normalize(parts[1]);
            final payloadStr = utf8.decode(base64Url.decode(normalized));
            final payload = jsonDecode(payloadStr);
            myUserId =
                int.tryParse(
                  payload['nameid']?.toString() ??
                      payload['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier']
                          ?.toString() ??
                      payload['sub']?.toString() ??
                      '0',
                ) ??
                0;
          }
        } catch (_) {}
      }
    }

    _restoreMySets();

    if (mounted) setState(() {});
  }

  void _handleWebSocketMessage(dynamic data) {
    if (data['type'] == 'promoted-to-host') {
      SharedPreferences.getInstance().then((prefs) {
        prefs.setBool('is_host', true);
      });
      if (mounted) {
        setState(() {
          isHost = true;
        });
        CustomSnackbar.show(
          context,
          "Te lettél az új Host!",
          backgroundColor: Colors.green,
        );
      }
    } else if (data['type'] == 'sync-workout-state') {
      setState(() {
        gameState = data['data'];
      });

      SharedPreferences.getInstance().then((prefs) {
        int storedUserId = prefs.getInt('userId') ?? 0;
        bool amIHost = data['data']['hostId'] == storedUserId;
        if (amIHost && !isHost) {
          prefs.setBool('is_host', true);
          if (mounted) setState(() => isHost = true);
        } else if (!amIHost && isHost) {
          prefs.setBool('is_host', false);
          if (mounted) setState(() => isHost = false);
        }
      });
    } else if (data['type'] == 'workout-finished') {
      if (mounted) {
        Navigator.pop(context, {'status': 'finished', 'data': data['data']});
      }
    }
  }

  void _endTurn(ExerciseDto currentExercise, bool finishExercise) {
    var validSets = currentExercise.sets.where((s) => s.isCompleted).toList();

    if (validSets.isEmpty && !finishExercise) {
      final lang = Provider.of<LanguageProvider>(context, listen: false);
      CustomSnackbar.show(
        context,
        lang.getText("no_valid_sets"),
        backgroundColor: Colors.orange,
      );
      return;
    }

    List<Map<String, dynamic>> setsData = [];
    for (int i = 0; i < validSets.length; i++) {
      setsData.add({
        "setIndex": i + 1,
        "weight": validSets[i].weight,
        "reps": validSets[i].reps,
      });
    }

    print(
      "📤 Adatok küldése: ${jsonEncode(setsData)}, Gyakorlat vége: $finishExercise",
    );

    WebSocketService().sendAction('end-turn', {
      "sets": setsData,
      "finishExercise": finishExercise,
    });
  }

  void _skipPlayer() {
    WebSocketService().sendAction('skip-player', {});
  }

  Future<void> _showExitConfirmDialog() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 30, 30, 30),
        title: Text(
          lang.getText('leave_workout'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          isHost
              ? lang.getText('host_leave_description')
              : lang.getText('leave_workout_description'),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              lang.getText("cancel"),
              style: const TextStyle(color: Colors.grey),
            ),
          ),

          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(
              lang.getText("send_to_background"),
              style: const TextStyle(color: Colors.blue),
            ),
          ),

          if (isHost)
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () {
                WebSocketService().sendAction('end-shared-workout', {});
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text(lang.getText("end_workout_for_all")),
            ),

          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              WebSocketService().sendAction('leave-shared-workout', {});
              SharedPreferences.getInstance().then((prefs) {
                prefs.remove('active_session_id');
                prefs.remove('is_host');
                WebSocketService().disconnect();
              });
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(lang.getText("leave_workout")),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int currentExIndex = gameState['currentExerciseIndex'] ?? 0;
    int currentPlIndex = gameState['currentPlayerIndex'] ?? 0;
    List players = gameState['players'] ?? [];
    List stats = gameState['stats'] ?? [];

    if (players.isEmpty || currentExIndex >= widget.userWorkouts.length) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    var currentPlayer = players[currentPlIndex];
    bool isMyTurn = currentPlayer['userId'] == myUserId;
    var currentExercise = widget.userWorkouts[currentExIndex];

    var currentExStats = stats
        .where((s) => s['exerciseId'] == currentExercise.id)
        .toList();

    int currentSet = 1;
    var activePlayerStat = currentExStats
        .where((s) => s['userId'] == currentPlayer['userId'])
        .toList();
    if (activePlayerStat.isNotEmpty && activePlayerStat.first['sets'] != null) {
      currentSet = (activePlayerStat.first['sets'] as List).length + 1;
    }

    final lang = Provider.of<LanguageProvider>(context, listen: false);

    String setWord = lang.getText('set');
    setWord = setWord.toLowerCase();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            "${lang.getText('shared_workout')} (${currentExIndex + 1}/${widget.userWorkouts.length}) - $currentSet. $setWord",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: primaryBlue,
              fontSize: 18,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
            onPressed: _showExitConfirmDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: players.length,
              itemBuilder: (context, index) {
                var p = players[index];
                bool isActive = index == currentPlIndex;

                final profilePicData =
                    p['profilePicture'] ?? p['ProfilePicture'];
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

                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive ? primaryBlue : Colors.transparent,
                        ),
                        child: CircleAvatar(
                          radius: isActive ? 26 : 22,
                          backgroundColor: const Color(0xFF272727),
                          backgroundImage: imageBytes != null
                              ? MemoryImage(imageBytes)
                              : null,
                          child: imageBytes == null
                              ? Icon(
                                  Icons.person,
                                  color: p['isDisconnected'] == true
                                      ? Colors.red
                                      : Colors.white,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        p['userName'],
                        style: TextStyle(
                          color: isActive ? primaryBlue : Colors.white70,
                          fontWeight: isActive
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const Divider(color: Colors.white24, height: 1),

          Expanded(
            child: isMyTurn
                ? _buildActivePlayerView(currentExercise)
                : _buildSpectatorView(
                    currentPlayer['userName'],
                    currentExStats,
                    currentExercise,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivePlayerView(ExerciseDto currentExercise) {
    final lang = Provider.of<LanguageProvider>(context);
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              lang.getText('your_turn'),
              style: TextStyle(
                fontSize: 20,
                color: primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          ExerciseTrackerCard(
            key: ValueKey(currentExercise.id),
            exercise: currentExercise,
            onremoveExercise: () {},
          ),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Expanded(
                  child: CustomButton(
                    onPressed: () => _endTurn(currentExercise, false),
                    variant: CustomButtonVariant.secondary,
                    title: lang.getText('finish_set'),
                    iconData: Icons.check,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CustomButton(
                    onPressed: () => _endTurn(currentExercise, true),
                    variant: CustomButtonVariant.primaryWorkout,
                    title: lang.getText('finish_exercise'),
                    iconData: Icons.done_all,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSpectatorView(
    String activeUserName,
    List stats,
    ExerciseDto currentExercise,
  ) {
    final lang = Provider.of<LanguageProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            currentExercise.getName(lang.languageCode),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),

          const Icon(Icons.hourglass_empty, size: 60, color: Colors.orange),
          const SizedBox(height: 10),
          Text(
            "${lang.getText('waiting_for')} $activeUserName",
            style: const TextStyle(fontSize: 22, color: Colors.orange),
          ),
          const SizedBox(height: 20),

          if (isHost)
            TextButton.icon(
              onPressed: _skipPlayer,
              icon: const Icon(Icons.skip_next, color: Colors.red),
              label: Text(
                lang.getText('skip_player'),
                style: TextStyle(color: Colors.red),
              ),
            ),

          const SizedBox(height: 20),
          const Divider(color: Colors.white24),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text(
              lang.getText('results_in_this_turn'),
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),

          if (stats.isEmpty)
            Text(
              lang.getText('no_results_yet'),
              style: TextStyle(color: Colors.white38),
            ),

          Expanded(
            child: ListView.builder(
              itemCount: stats.length,
              itemBuilder: (context, index) {
                var stat = stats[index];
                var p = (gameState['players'] as List).firstWhere(
                  (p) => p['userId'] == stat['userId'],
                  orElse: () => {"userName": lang.getText('unknown')},
                );

                String setsText = (stat['sets'] as List)
                    .map((s) => "${s['weight']}kg x ${s['reps']}")
                    .join("  |  ");

                return Card(
                  color: const Color(0xFF272727),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                    title: Text(
                      p['userName'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      setsText,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
