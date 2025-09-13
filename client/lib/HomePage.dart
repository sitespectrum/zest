import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.username});
  final String username;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  Widget build(BuildContext context) {
    final appTitle = 'Zest | Üdv ${widget.username}!';

    return Scaffold(
      appBar: AppBar(
        title: Text(appTitle),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[

        ],
      ),
    );
  }
}