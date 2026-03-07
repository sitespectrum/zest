import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:client/components/drawers/add_drawer.dart';
import 'package:client/components/running_workout_page.dart';
import 'package:client/components/topo_background.dart';
import 'package:client/components/workout_page.dart';
import 'package:client/components/home_page.dart';
import 'package:client/components/health_page.dart';
import 'package:client/components/profile_page.dart';
import 'package:client/components/custom_workout_page.dart';
import 'package:client/components/custom_meal_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/language_provider.dart';
import 'package:client/main.dart';
import 'package:client/models/workout.dart';
import 'package:client/services/websocket_service.dart';
import 'package:client/components/shared_running_workout_page.dart';
import 'package:client/components/shared_workout_summary_page.dart';

class Pages extends StatefulWidget {
  const Pages({super.key});

  @override
  State<Pages> createState() => _PagesState();
}

class _PagesState extends State<Pages>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  String? username;
  int _selectedIndex = 0;

  String? _activeSessionId;
  bool _isLoadingSharedWorkout = false;

  @override
  bool get wantKeepAlive => true;

  final List<Color> _pageColors = [
    const Color(0xFF7af970),
    const Color.fromARGB(150, 50, 146, 255),
    const Color(0xFFff9c7a),
    const Color.fromARGB(255, 255, 255, 255),
  ];

  late PageController _pageController = PageController();
  Color _currentColor = const Color(0xFF7af970);

  @override
  void initState() {
    super.initState();
    _loadUser();
    _pageController.addListener(_onScroll);

    _checkActiveSharedWorkout();
    WebSocketService().activeSessionNotifier.addListener(_onSessionChanged);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onScroll);
    _pageController.dispose();
    WebSocketService().activeSessionNotifier.removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    if (mounted) {
      setState(() {
        _activeSessionId = WebSocketService().activeSessionNotifier.value;
      });
    }
  }

  Future<void> _checkActiveSharedWorkout() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('active_session_id');
    if (mounted) {
      setState(() {
        _activeSessionId = savedId;
      });
    }
    if (savedId != null && savedId.isNotEmpty) {
      if (!WebSocketService().isConnected) {
        await WebSocketService().connect(savedId);
      }
    }
  }

  Future<void> _resumeSharedWorkout() async {
    setState(() {
      _isLoadingSharedWorkout = true;
    });

    if (!WebSocketService().isConnected && _activeSessionId != null) {
      await WebSocketService().connect(_activeSessionId!);
    }

    List<ExerciseDto>? fetchedWorkouts;
    Map<String, dynamic>? fetchedState;

    final oldHandler = WebSocketService().onMessageReceived;

    WebSocketService().onMessageReceived = (data) {
      if (data['type'] == 'session-ended') {
        WebSocketService().onMessageReceived = oldHandler;

        SharedPreferences.getInstance().then((prefs) {
          prefs.remove('active_session_id');
          prefs.remove('is_host');
        });
        WebSocketService().activeSessionNotifier.value = null;
        WebSocketService().disconnect();

        if (mounted) {
          setState(() {
            _isLoadingSharedWorkout = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Az edzés már befejeződött!"),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      if (data['type'] == 'sync-exercises') {
        fetchedWorkouts = (data['data'] as List)
            .map((e) => ExerciseDto.fromJson(e))
            .toList();
      } else if (data['type'] == 'sync-workout-state') {
        fetchedState = data['data'];

        SharedPreferences.getInstance().then((prefs) {
          int myUserId = prefs.getInt('userId') ?? 0;
          if (fetchedState!['hostId'] == myUserId) {
            prefs.setBool('is_host', true);
          }
        });
      }

      if (fetchedWorkouts != null && fetchedState != null) {
        WebSocketService().onMessageReceived = oldHandler;

        if (mounted) {
          setState(() {
            _isLoadingSharedWorkout = false;
          });
        }

        if (fetchedState != null && fetchedState?['status'] == 'Running') {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  CWorkoutPage(
                    selectedDay: DateTime.now(),
                    restoredExercises: fetchedWorkouts,
                  ),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CWorkoutPage(selectedDay: DateTime.now()),
            ),
          ).then((_) {
            _checkActiveSharedWorkout();
          });
        }
      }
    };

    WebSocketService().sendAction('get-exercises', {});
    WebSocketService().sendAction('get-workout-state', {});
  }

  void _onScroll() {
    final page = _pageController.page ?? 0;
    int index = page.floor();
    int nextIndex = (index + 1).clamp(0, _pageColors.length - 1);
    double percent = page - index;

    setState(() {
      _currentColor = Color.lerp(
        _pageColors[index],
        _pageColors[nextIndex],
        percent,
      )!;
    });
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString("username");
    });
  }

  void _onItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void onNavTap(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? Colors.white : Colors.white24;
    final FontWeight fontWeight = isSelected
        ? FontWeight.bold
        : FontWeight.normal;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: fontWeight,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, _currentColor.withOpacity(0.4)],
                transform: GradientRotation(-0.5 * pi),
              ),
            ),
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white24, Colors.transparent],
              ).createShader(bounds),
              child: TopoBackground(foreground: _currentColor),
            ),
          ),

          PageView(
            physics: BouncingScrollPhysics(),
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            children: [
              const HomePage(),
              const WorkoutPage(),
              const HealthPage(),
              const ProfilePage(),
            ],
          ),
        ],
      ),

      bottomNavigationBar: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ValueListenableBuilder<String?>(
              valueListenable: offlineSessionNotifier,
              builder: (context, sessionData, child) {
                if (sessionData == null) return const SizedBox.shrink();

                return GestureDetector(
                  onTap: () {
                    try {
                      final decoded = jsonDecode(sessionData);
                      List<ExerciseDto> restoredWorkouts = [];
                      int restoredSeconds = 0;

                      if (decoded is List) {
                        restoredWorkouts = decoded
                            .map((e) => ExerciseDto.fromJson(e))
                            .toList();
                      } else if (decoded is Map) {
                        int savedSeconds = decoded['elapsedSeconds'] ?? 0;
                        int timestamp =
                            decoded['timestamp'] ??
                            DateTime.now().millisecondsSinceEpoch;

                        int diffSeconds =
                            (DateTime.now().millisecondsSinceEpoch -
                                timestamp) ~/
                            1000;

                        restoredSeconds = savedSeconds + diffSeconds;
                        restoredWorkouts = (decoded['exercises'] as List)
                            .map((e) => ExerciseDto.fromJson(e))
                            .toList();
                      }

                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  CWorkoutPage(
                                    selectedDay: DateTime.now(),
                                    restoredExercises: restoredWorkouts,
                                  ),
                          transitionDuration: Duration.zero,
                          reverseTransitionDuration: Duration.zero,
                        ),
                      );
                    } catch (e) {
                      debugPrint("Hiba a visszatöltéskor: $e");
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(
                      left: 10,
                      right: 10,
                      bottom: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(
                        255,
                        50,
                        146,
                        255,
                      ).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: const Icon(
                        Icons.fitness_center,
                        color: Colors.white,
                        size: 30,
                      ),
                      title: Text(
                        lang.languageCode == 'hu'
                            ? "Edzés folyamatban..."
                            : "Workout in progress...",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 34,
                        ),
                        onPressed: () {
                          try {
                            final decoded = jsonDecode(sessionData);
                            List<ExerciseDto> restoredWorkouts = [];
                            int restoredSeconds = 0;

                            if (decoded is List) {
                              restoredWorkouts = decoded
                                  .map((e) => ExerciseDto.fromJson(e))
                                  .toList();
                            } else if (decoded is Map) {
                              int savedSeconds = decoded['elapsedSeconds'] ?? 0;
                              int timestamp =
                                  decoded['timestamp'] ??
                                  DateTime.now().millisecondsSinceEpoch;

                              int diffSeconds =
                                  (DateTime.now().millisecondsSinceEpoch -
                                      timestamp) ~/
                                  1000;

                              restoredSeconds = savedSeconds + diffSeconds;
                              restoredWorkouts = (decoded['exercises'] as List)
                                  .map((e) => ExerciseDto.fromJson(e))
                                  .toList();
                            }

                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        CWorkoutPage(
                                          selectedDay: DateTime.now(),
                                          restoredExercises: restoredWorkouts,
                                        ),
                                transitionDuration: Duration.zero,
                                reverseTransitionDuration: Duration.zero,
                              ),
                            );
                          } catch (e) {
                            debugPrint("Hiba a visszatöltéskor: $e");
                          }
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            if (_activeSessionId != null && _activeSessionId!.isNotEmpty)
              GestureDetector(
                onTap: _resumeSharedWorkout,
                child: Container(
                  margin: const EdgeInsets.only(
                    left: 10,
                    right: 10,
                    bottom: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(
                      255,
                      50,
                      146,
                      255,
                    ).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: const Icon(
                      Icons.group,
                      color: Colors.white,
                      size: 30,
                    ),
                    title: Text(
                      lang.getText("shared_workout_in_progress"),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 34,
                      ),
                      onPressed: () {
                        try {
                          final decoded = jsonDecode(sessionData);
                          List<ExerciseDto> restoredWorkouts = [];
                          int restoredSeconds = 0;

                          if (decoded is List) {
                            restoredWorkouts = decoded
                                .map((e) => ExerciseDto.fromJson(e))
                                .toList();
                          } else if (decoded is Map) {
                            int savedSeconds = decoded['elapsedSeconds'] ?? 0;
                            int timestamp =
                                decoded['timestamp'] ??
                                DateTime.now().millisecondsSinceEpoch;

                            int diffSeconds =
                                (DateTime.now().millisecondsSinceEpoch -
                                    timestamp) ~/
                                1000;

                            restoredSeconds = savedSeconds + diffSeconds;
                            restoredWorkouts = (decoded['exercises'] as List)
                                .map((e) => ExerciseDto.fromJson(e))
                                .toList();
                          }

                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      CWorkoutPage(
                                        selectedDay: DateTime.now(),
                                        restoredExercises: restoredWorkouts,
                                      ),
                              transitionDuration: Duration.zero,
                              reverseTransitionDuration: Duration.zero,
                            ),
                          )
                        : IconButton(
                            icon: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 34,
                            ),
                            onPressed: _resumeSharedWorkout,
                          ),
                  ),
                ),
              ),

            Container(
              margin: const EdgeInsets.only(left: 10, right: 10, bottom: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(
                      left: 12,
                      right: 12,
                      top: 6,
                      bottom: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(85, 173, 78, 0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF4E9C47)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildNavItem(0, Icons.home, lang.getText("home_page")),
                        _buildNavItem(
                          1,
                          Icons.fitness_center,
                          lang.getText("workout_page"),
                        ),
                        Container(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                sigmaX: 5.0,
                                sigmaY: 5.0,
                              ),
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.15,
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: const Color.fromRGBO(85, 173, 78, 0.5),
                                  border: Border.all(
                                    color: const Color.fromRGBO(
                                      78,
                                      156,
                                      71,
                                      255,
                                    ),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      builder: (context) => const AddDrawer(),
                                    );
                                  },
                                  child: const Icon(
                                    Icons.add,
                                    size: 38,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        _buildNavItem(
                          2,
                          Icons.favorite,
                          lang.getText("health_page"),
                        ),
                        _buildNavItem(
                          3,
                          Icons.person,
                          lang.getText("profile_page"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShaderPainter extends CustomPainter {
  final FragmentShader shader;
  ShaderPainter(this.shader);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = shader,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
