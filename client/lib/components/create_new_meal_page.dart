import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';

class CreateNewMealPage extends StatefulWidget {
  const CreateNewMealPage({super.key});

  @override
  State<CreateNewMealPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<CreateNewMealPage>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController mealnamecontroller = TextEditingController();
  final TextEditingController caloriescontroller = TextEditingController();
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
        birthcontroller.text = DateFormat(
          'yyyy-MM-dd',
          'hu',
        ).format(DateTime.now());
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

            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.085,
                  margin: const EdgeInsets.fromLTRB(20, 20, 20, 20),
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
                        controller: mealnamecontroller,
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
                      ),
                    ],
                  ),
                ),

                Positioned(
                  top: MediaQuery.of(context).size.height * 0.008,
                  left: MediaQuery.of(context).size.width * 0.08,
                  child: const Text(
                    "Név",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
          ],
        ),
      ),

      bottomNavigationBar: Padding(
        padding: EdgeInsetsGeometry.fromLTRB(20, 20, 20, 20),
        child: FilledButton(
          onPressed: () async {
            print("szea");
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
