import 'dart:ui';
import 'package:client/components/workout_page.dart';
import 'package:client/components/home_page.dart';
import 'package:client/components/health_page.dart';
import 'package:client/components/profile_page.dart';
import 'package:client/components/custom_workout_page.dart';
import 'package:client/components/custom_meal_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import 'Providers/language_provider.dart';

class Pages extends StatefulWidget {
  const Pages({super.key});

  @override
  State<Pages> createState() => _PagesState();
}

class _PagesState extends State<Pages> {
  String? username;
  int _selectedIndex = 0;

  final List<Color> _pageColors = [
    const Color(0xFF7af970),
    const Color(0xFF34CAFF),
    const Color(0xFFff9c7a),
    const Color.fromARGB(255, 255, 255, 255),
  ];

  final PageController _pageController = PageController();
  late VideoPlayerController _videoController;
  Color _currentColor = const Color(0xFF7af970);

  @override
  void initState() {
    super.initState();
    _loadUser();
    _videoController =
        VideoPlayerController.asset("assets/background/Zest_bg_v2_full.mp4")
          ..initialize().then((_) {
            _videoController.setLooping(true);
            _videoController.setVolume(0.0);
            _videoController.play();
            setState(() {});
          });

    _pageController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onScroll);
    _pageController.dispose();
    _videoController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_pageController.hasClients) return;

    final page = _pageController.page ?? 0;
    final int currentIndex = page.floor();
    final int nextIndex = (currentIndex + 1).clamp(0, _pageColors.length - 1);
    final double percent = page - currentIndex;

    final Color? newColor = Color.lerp(
      _pageColors[currentIndex],
      _pageColors[nextIndex],
      percent,
    );

    if (newColor != null) {
      setState(() {
        _currentColor = newColor;
        _selectedIndex = page.round();
      });
    }
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
          if (_videoController.value.isInitialized)
            Positioned.fill(
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  _currentColor,
                  BlendMode.modulate,
                ),
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _videoController.value.size.width,
                    height: _videoController.value.size.height,
                    child: VideoPlayer(_videoController),
                  ),
                ),
              ),
            )
          else
            Container(color: Colors.black),

          PageView(
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

      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(85, 173, 78, 0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Color.fromRGBO(78, 156, 71, 255)),
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
                        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.15,
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(85, 173, 78, 0.5),
                            border: Border.all(
                              color: Color.fromRGBO(78, 156, 71, 255),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return Dialog(
                                    insetPadding: const EdgeInsets.all(20),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
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
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.white24,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            lang.getText("create_new"),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 12),

                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              GestureDetector(
                                                onTap: () {
                                                  Navigator.pop(context);
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          CWorkoutPage(
                                                            selectedDay:
                                                                DateTime.now(),
                                                          ),
                                                    ),
                                                  );
                                                },
                                                child: Container(
                                                  width: double.infinity,
                                                  padding: const EdgeInsets.all(
                                                    12,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: const Color.fromARGB(
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
                                                      color: Colors.white24,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        lang.getText(
                                                          "new_workout",
                                                        ),
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize:
                                                              MediaQuery.of(
                                                                context,
                                                              ).size.height *
                                                              0.042,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      Container(
                                                        width: 45,
                                                        height: 45,
                                                        decoration: BoxDecoration(
                                                          color:
                                                              const Color.fromARGB(
                                                                255,
                                                                40,
                                                                40,
                                                                40,
                                                              ),
                                                          shape:
                                                              BoxShape.circle,
                                                          border: Border.all(
                                                            color:
                                                                Colors.white24,
                                                          ),
                                                        ),
                                                        child: const Icon(
                                                          Icons.arrow_forward,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),

                                              const SizedBox(height: 12),

                                              GestureDetector(
                                                onTap: () {
                                                  Navigator.pop(context);
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          CMealPage(
                                                            selectedDay:
                                                                DateTime.now(),
                                                          ),
                                                    ),
                                                  );
                                                },
                                                child: Container(
                                                  width: double.infinity,
                                                  margin:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 4,
                                                      ),
                                                  padding: const EdgeInsets.all(
                                                    10,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: const Color.fromARGB(
                                                      255,
                                                      30,
                                                      30,
                                                      30,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    border: Border.all(
                                                      color: Colors.white24,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        lang.getText(
                                                          "new_meal",
                                                        ),
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize:
                                                              MediaQuery.of(
                                                                context,
                                                              ).size.height *
                                                              0.042,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      Container(
                                                        width: 45,
                                                        height: 45,
                                                        decoration: BoxDecoration(
                                                          color:
                                                              const Color.fromARGB(
                                                                255,
                                                                40,
                                                                40,
                                                                40,
                                                              ),
                                                          shape:
                                                              BoxShape.circle,
                                                          border: Border.all(
                                                            color:
                                                                Colors.white24,
                                                          ),
                                                        ),
                                                        child: const Icon(
                                                          Icons.arrow_forward,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),

                                              const SizedBox(height: 20),

                                              Center(
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
                                                      width: 1,
                                                    ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    lang.getText("close"),
                                                    style: const TextStyle(
                                                      color: Colors.red,
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
                  _buildNavItem(2, Icons.favorite, lang.getText("health_page")),
                  _buildNavItem(3, Icons.person, lang.getText("profile_page")),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
