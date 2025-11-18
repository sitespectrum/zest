import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';

class DetailsPage extends StatefulWidget {
  const DetailsPage({super.key, required this.userId});

  final int userId;

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController heightcontroller = TextEditingController();
  final TextEditingController weightcontroller = TextEditingController();
  final TextEditingController birthcontroller = TextEditingController();
  final TextEditingController gendercontroller = TextEditingController();
  final TextEditingController goalcontroller = TextEditingController();
  final TextEditingController activitycontroller = TextEditingController();
  DateTime? selectedBirth;
  int _gselectedIndex = 3;
  int _aselectedIndex = 5;
  double multiplier = 1;
  int IncreaseOrDecreaseCalories = 0;

  final List _goals = ["Tömegelés", "Szintentartás", "Fogyás"];

  final List _activity = [
    "Enyhén_aktív",
    "Közepesen_aktív",
    "Nagyon_aktív",
    "Extrém_aktív",
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      initialEntryMode: DatePickerEntryMode.input,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.green,
              onPrimary: Colors.white,
              surface: Color.fromARGB(255, 72, 72, 72),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedBirth = picked;
        birthcontroller.text = DateFormat('yyyy-MM-dd', 'hu').format(picked);
        final age = _calcAge(picked);
      });
    }
  }

  int _calcAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;

    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }

    return age;
  }

  Future<void> submitDetails() async {
    if (selectedBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Válassz születési dátumot!")),
      );
      return;
    }

    final height = int.tryParse(heightcontroller.text);
    final weight = int.tryParse(weightcontroller.text);
    final gender = gendercontroller.text;
    final goal = goalcontroller.text;
    final activity = activitycontroller.text;

    if (height == null || weight == null || gender.isEmpty || goal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Töltsd ki az összes mezőt helyesen!")),
      );
      return;
    }

    final age = _calcAge(selectedBirth!);

    double BMR = 10 * weight + 6.25 * height - 5 * age + 5;
    double calorieGoal = BMR * multiplier + IncreaseOrDecreaseCalories;
    double proteinGoal = 0.2 * calorieGoal / 4;
    double carbsGoal = 0.5 * calorieGoal / 4;
    double fatGoal = 0.3 * calorieGoal / 9;

    if (selectedBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Válassz születési dátumot!")),
      );
      return;
    }

    final response = await http.post(
      Uri.parse("$apiUrl/api/auth/details"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userId": widget.userId,
        "height": height,
        "weight": weight,
        "birth": selectedBirth!.toIso8601String(),
        "gender": gender,
        "goal": goal,
        "activity": activity,
        "calorieGoal": calorieGoal,
        "proteinGoal": proteinGoal,
        "carbsGoal": carbsGoal,
        "fatGoal": fatGoal,
      }),
    );

    print("$calorieGoal : $proteinGoal");

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Siker"),
            content: const Text("Sikeres regisztráció"),
          ),
        );
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } else {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Hiba"),
            content: Text("${response.body}"),
          ),
        );
      }
    }
  }

  Widget build(BuildContext context) {
    super.build(context);
    const appTitle = "Adataim";

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                margin: const EdgeInsets.all(6),
                child: AppBar(
                  title: const Text(
                    appTitle,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  automaticallyImplyLeading: false,
                  backgroundColor: Color.fromARGB(255, 58, 58, 58),
                ),
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Stack(
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width * 0.41,
                      height: MediaQuery.of(context).size.height * 0.085,
                      margin: const EdgeInsets.fromLTRB(20, 20, 5, 20),
                      padding: const EdgeInsets.fromLTRB(10, 12, 8, 5),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 72, 72, 72),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            cursorColor: Colors.white,
                            style: TextStyle(color: Colors.white, fontSize: 20),
                            controller: heightcontroller,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 0,
                                vertical: 0,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.transparent,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.transparent,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),

                    Positioned(
                      top: MediaQuery.of(context).size.height * 0.008,
                      left: MediaQuery.of(context).size.width * 0.08,
                      child: const Text(
                        "Magasság",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                Stack(
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width * 0.41,
                      height: MediaQuery.of(context).size.height * 0.085,
                      margin: const EdgeInsets.fromLTRB(5, 20, 20, 20),
                      padding: const EdgeInsets.fromLTRB(10, 12, 8, 5),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 72, 72, 72),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            cursorColor: Colors.white,
                            style: TextStyle(color: Colors.white, fontSize: 20),
                            controller: weightcontroller,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 0,
                                vertical: 0,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.transparent,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.transparent,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: MediaQuery.of(context).size.height * 0.008,
                      left: MediaQuery.of(context).size.width * 0.04,
                      child: const Text(
                        "Súly",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Stack(
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width * 0.41,
                      height: MediaQuery.of(context).size.height * 0.085,
                      margin: const EdgeInsets.fromLTRB(20, 20, 5, 20),
                      padding: const EdgeInsets.fromLTRB(0.5, 5, 0.5, 2),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 72, 72, 72),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.075,
                            child: TextField(
                              readOnly: true,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              controller: birthcontroller,
                              decoration: InputDecoration(
                                filled: false,
                                prefixIcon: Icon(Icons.calendar_today),
                                prefixIconColor: Colors.white,
                                prefixIconConstraints: BoxConstraints(
                                  minWidth: 35,
                                  minHeight: 35,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onTap: () => {_selectDate()},
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: MediaQuery.of(context).size.height * 0.007,
                      left: MediaQuery.of(context).size.width * 0.08,
                      child: const Text(
                        "Szül. idő",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                Stack(
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width * 0.41,
                      height: MediaQuery.of(context).size.height * 0.085,
                      margin: const EdgeInsets.fromLTRB(5, 20, 20, 20),
                      padding: const EdgeInsets.fromLTRB(0.5, 5, 0.5, 2),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 72, 72, 72),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: gendercontroller.text.isNotEmpty
                                ? gendercontroller.text
                                : null,
                            decoration: InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.transparent,
                                  width: 0,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.transparent,
                                  width: 0,
                                ),
                              ),
                              filled: true,
                              fillColor: Color.fromARGB(255, 72, 72, 72),
                            ),
                            dropdownColor: const Color.fromARGB(
                              255,
                              72,
                              72,
                              72,
                            ),
                            style: const TextStyle(color: Colors.white),
                            items: const [
                              DropdownMenuItem(
                                value: "Férfi",
                                child: Text(
                                  "Férfi",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: "Nő",
                                child: Text(
                                  "Nő",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                gendercontroller.text = value ?? "";
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: MediaQuery.of(context).size.height * 0.008,
                      left: MediaQuery.of(context).size.width * 0.04,
                      child: const Text(
                        "Nem",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            Stack(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 72, 72, 72),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 15, 8, 15),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _gselectedIndex = 0;
                              goalcontroller.text = _goals[_gselectedIndex];
                              IncreaseOrDecreaseCalories = 500;
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            height: MediaQuery.of(context).size.height * 0.1,
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: _gselectedIndex == 0
                                  ? Color.fromARGB(255, 85, 173, 78)
                                  : Color.fromARGB(255, 58, 58, 58),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Center(
                                  child: Text(
                                    "Tömegelés",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize:
                                          MediaQuery.of(context).size.height *
                                          0.035,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _gselectedIndex = 1;
                              goalcontroller.text = _goals[_gselectedIndex];
                              print(goalcontroller.text);
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            height: MediaQuery.of(context).size.height * 0.1,
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: _gselectedIndex == 1
                                  ? Color.fromARGB(255, 85, 173, 78)
                                  : Color.fromARGB(255, 58, 58, 58),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Center(
                                  child: Text(
                                    "Szintentartás",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize:
                                          MediaQuery.of(context).size.height *
                                          0.035,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _gselectedIndex = 2;
                              goalcontroller.text = _goals[_gselectedIndex];
                              IncreaseOrDecreaseCalories = -500;
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            height: MediaQuery.of(context).size.height * 0.1,
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: _gselectedIndex == 2
                                  ? Color.fromARGB(255, 85, 173, 78)
                                  : Color.fromARGB(255, 58, 58, 58),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Center(
                                  child: Text(
                                    "Fogyás",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize:
                                          MediaQuery.of(context).size.height *
                                          0.035,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.007,
                  left: MediaQuery.of(context).size.width * 0.08,
                  child: Text(
                    "Célok",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            Stack(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 72, 72, 72),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 15, 8, 15),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _aselectedIndex = 0;
                              activitycontroller.text =
                                  _activity[_aselectedIndex];
                              print(activitycontroller.text);
                              multiplier = 1.375;
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            height: MediaQuery.of(context).size.height * 0.1,
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: _aselectedIndex == 0
                                  ? Color.fromARGB(255, 85, 173, 78)
                                  : Color.fromARGB(255, 58, 58, 58),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Center(
                                  child: Text(
                                    "Enyhén aktív",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize:
                                          MediaQuery.of(context).size.height *
                                          0.035,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _aselectedIndex = 1;
                              activitycontroller.text =
                                  _activity[_aselectedIndex];
                              print(activitycontroller.text);
                              multiplier = 1.55;
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            height: MediaQuery.of(context).size.height * 0.1,
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: _aselectedIndex == 1
                                  ? Color.fromARGB(255, 85, 173, 78)
                                  : Color.fromARGB(255, 58, 58, 58),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Center(
                                  child: Text(
                                    "Közepesen aktív",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize:
                                          MediaQuery.of(context).size.height *
                                          0.035,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _aselectedIndex = 2;
                              activitycontroller.text =
                                  _activity[_aselectedIndex];
                              print(activitycontroller.text);
                              multiplier = 1.725;
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            height: MediaQuery.of(context).size.height * 0.1,
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: _aselectedIndex == 2
                                  ? Color.fromARGB(255, 85, 173, 78)
                                  : Color.fromARGB(255, 58, 58, 58),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Center(
                                  child: Text(
                                    "Nagyon aktív",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize:
                                          MediaQuery.of(context).size.height *
                                          0.035,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _aselectedIndex = 3;
                              activitycontroller.text =
                                  _activity[_aselectedIndex];
                              print(activitycontroller.text);
                              multiplier = 1.9;
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            height: MediaQuery.of(context).size.height * 0.1,
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: _aselectedIndex == 3
                                  ? Color.fromARGB(255, 85, 173, 78)
                                  : Color.fromARGB(255, 58, 58, 58),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Center(
                                  child: Text(
                                    "Extrém aktív",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize:
                                          MediaQuery.of(context).size.height *
                                          0.035,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.007,
                  left: MediaQuery.of(context).size.width * 0.08,
                  child: Text(
                    "Aktivitás",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      bottomNavigationBar: Padding(
        padding: EdgeInsetsGeometry.fromLTRB(20, 20, 20, 20),
        child: FilledButton(
          onPressed: () async {
            print("szea");
            submitDetails();
          },
          style: FilledButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 85, 173, 78),
            fixedSize: Size(
              MediaQuery.of(context).size.width * 0.70,
              MediaQuery.of(context).size.height * 0.04,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
            ),
          ),
          child: Text(
            "Regisztráció befejezése",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
