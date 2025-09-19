import 'package:client/components/workout_page.dart';
import 'package:client/components/home_page.dart';
import 'package:client/components/health_page.dart';
import 'package:client/components/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    SizedBox.shrink(),
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

      body: _pages[_selectedIndex],
      
      bottomNavigationBar: NavigationBar(
        indicatorColor: Color.fromRGBO(78, 156, 71, 1),
        backgroundColor: Color.fromRGBO(85, 173, 78, 1),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.fitness_center),
          label: 'Workout',
        ),
        NavigationDestination(
          icon: SizedBox.shrink(),
          label: ''
        ),
        NavigationDestination(
          icon: Icon(Icons.favorite),
          label: 'Health',
        ),
        NavigationDestination(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => WorkoutPage()),
          );
        },
        backgroundColor: Colors.white,
        foregroundColor: Color.fromRGBO(85, 173, 78, 1),
        child: Icon(Icons.add, size: 38),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}