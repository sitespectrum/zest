import 'package:client/components/workout_page.dart';
import 'package:client/components/home_page.dart';
import 'package:client/components/health_page.dart';
import 'package:client/components/profile_page.dart';
import 'package:client/components/custom_workout_page.dart';
import 'package:client/components/custom_meal_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_popup/flutter_popup.dart';

class Pages extends StatefulWidget {
  const Pages({super.key});

  @override
  State<Pages> createState() => _PagesState();
}

class _PagesState extends State<Pages> {
  String? username;
  int _selectedIndex = 0;

    final List<Widget> _pages = [
    HomePage(),
    WorkoutPage(),
    HealthPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    username = prefs.getString("username");
  });
  }

  Widget build(BuildContext context) {
    final appTitle = 'Üdv, $username!';

    return Scaffold(

      body: SingleChildScrollView(
        child: _pages[_selectedIndex],
      ),
      
      bottomNavigationBar: NavigationBar(
      backgroundColor: Color.fromARGB(255, 85, 173, 78),
      indicatorColor: Color.fromARGB(255, 78, 156, 71),
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) => setState(() => _selectedIndex = index),
      destinations: [
        Padding(
          padding: EdgeInsets.only(right: 20),
          child: NavigationDestination(icon: Icon(Icons.home), label: 'Főoldal'),
        ),
        Padding(
          padding: EdgeInsets.only(right: 30),
          child: NavigationDestination(icon: Icon(Icons.fitness_center), label: 'Edzés'),
        ),
        Padding(
          padding: EdgeInsets.only(left: 30),
          child: NavigationDestination(icon: Icon(Icons.favorite), label: 'Egészség'),
        ),
        Padding(
          padding: EdgeInsets.only(left: 20),
          child: NavigationDestination(icon: Icon(Icons.person), label: 'Profil'),
        ),
      ],
    ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
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
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 85, 173, 78),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: -MediaQuery.of(context).size.height * 0.02,
                      left: MediaQuery.of(context).size.width * 0.03,
                      child: Text(
                        "Új létrehozása",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const CWorkoutPage()),
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              height: MediaQuery.of(context).size.height * 0.13,
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: const Color.fromRGBO(78, 156, 71, 1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [ 
                                Text(
                                  "Új edzés",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: MediaQuery.of(context).size.height * 0.042,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward,
                                    color: Colors.black,
                                  ),
                                )
                              ],
                            ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const CMealPage()),
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              height: MediaQuery.of(context).size.height * 0.13,
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: const Color.fromRGBO(78, 156, 71, 1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [ 
                                Text(
                                  "Új étkezés",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: MediaQuery.of(context).size.height * 0.042,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward,
                                    color: Colors.black,
                                  ),
                                )
                              ],
                            ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
            },
          );
        },
        backgroundColor: Colors.white,
        foregroundColor: const Color.fromRGBO(85, 173, 78, 1),
        child: const Icon(Icons.add, size: 38),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}