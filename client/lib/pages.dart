import 'dart:math';
import 'dart:ui';
import 'package:client/components/drawers/add_drawer.dart';
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

class Pages extends StatefulWidget {
  const Pages({super.key});

  @override
  State<Pages> createState() => _PagesState();
}

class _PagesState extends State<Pages> with SingleTickerProviderStateMixin {
  String? username;
  int _selectedIndex = 0;

  final List<Color> _pageColors = [
    const Color(0xFF7af970),
    const Color.fromARGB(150, 50, 146, 255),
    const Color(0xFFff9c7a),
    const Color.fromARGB(255, 255, 255, 255),
  ];

  // ignore: prefer_final_fields
  late PageController _pageController = PageController();
  Color _currentColor = const Color(0xFF7af970);

  @override
  void initState() {
    super.initState();
    _loadUser();
    _pageController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onScroll);
    _pageController.dispose();
    super.dispose();
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
        child: Container(
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
                  border: Border.all(color: Color(0xFF4E9C47)),
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
