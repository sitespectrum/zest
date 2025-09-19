import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  String? username;

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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          margin: const EdgeInsets.all(4),
          child: AppBar(
              title: Text(appTitle, style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),),
              automaticallyImplyLeading: false,
              backgroundColor: Color.fromARGB(255, 58, 58, 58),
            ),
          ),
        ),
    );
  }
}