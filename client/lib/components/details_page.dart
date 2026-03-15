import 'dart:ui';
import 'package:client/components/ui/custom_button.dart';
import 'package:client/components/ui/custom_card.dart';
import 'package:client/components/ui/custom_snackbar.dart';
import 'package:client/components/ui/custom_textfield.dart';
import 'package:client/providers/language_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
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
  // ignore: non_constant_identifier_names
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

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.green,
              onPrimary: Colors.white,
              surface: Color(0xFF272727),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF272727),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedBirth = picked;
        birthcontroller.text = DateFormat('yyyy-MM-dd').format(picked);
        _calcAge(picked);
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
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    if (selectedBirth == null) {
      _showErrorSnackBar(lang.getText("choose_date_of_birth"));
      return;
    }

    final height = int.tryParse(heightcontroller.text);
    final weight = int.tryParse(weightcontroller.text);
    final gender = gendercontroller.text;
    final goal = goalcontroller.text;
    final activity = activitycontroller.text;

    if (height == null || weight == null || gender.isEmpty || goal.isEmpty) {
      _showErrorSnackBar(lang.getText("all_fields_are_required"));
      return;
    }

    final age = _calcAge(selectedBirth!);

    // ignore: non_constant_identifier_names
    double BMR = 10 * weight + 6.25 * height - 5 * age + 5;
    double calorieGoal = BMR * multiplier + IncreaseOrDecreaseCalories;
    double proteinGoal = 0.2 * calorieGoal / 4;
    double carbsGoal = 0.5 * calorieGoal / 4;
    double fatGoal = 0.3 * calorieGoal / 9;

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

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => const AlertDialog(
            backgroundColor: Color(0xFF272727),
            title: Text("Siker", style: TextStyle(color: Colors.white)),
            content: Text(
              "Sikeres regisztráció",
              style: TextStyle(color: Colors.white70),
            ),
          ),
        );
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } else {
      if (context.mounted) {
        _showErrorSnackBar("${lang.getText("error")}: ${response.body}");
      }
    }
  }

  void _showErrorSnackBar(String message) {
    CustomSnackbar.show(context, message, backgroundColor: Colors.red);
  }

  Widget _buildStyledField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF272727),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(
            color: Color.fromARGB(100, 64, 255, 50),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white.withAlpha(20), width: 1),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildStyledDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items,
      onChanged: onChanged,
      dropdownColor: const Color(0xFF272727),
      style: const TextStyle(color: Colors.white, fontSize: 16),
      icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        filled: true,
        fillColor: const Color(0xFF272727),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(
            color: Color.fromARGB(100, 64, 255, 50),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white.withAlpha(20), width: 1),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final lang = Provider.of<LanguageProvider>(context);

    return SafeArea(
      child: PopScope(
        canPop: false,
        child: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                PreferredSize(
                  preferredSize: const Size.fromHeight(60),
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 5,
                    ),
                    child: AppBar(
                      title: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: ClipRect(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                              sigmaX: 10.0,
                              sigmaY: 10.0,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color.fromRGBO(45, 45, 45, 0.5),
                              ),
                              child: Text(
                                lang.getText("my_details"),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      automaticallyImplyLeading: false,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          heightcontroller,
                          lang.getText("height"),
                          isNumber: true,
                          isSuffix: true,
                          suffix: " cm",
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: CustomTextField(
                          weightcontroller,
                          lang.getText("weight"),
                          isNumber: true,
                          isSuffix: true,
                          suffix: " kg",
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStyledField(
                          controller: birthcontroller,
                          label: lang.getText("born_in"),
                          icon: Icons.calendar_today,
                          onTap: _selectDate,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildStyledDropdown(
                          label: lang.getText("gender"),
                          value: gendercontroller.text.isNotEmpty
                              ? gendercontroller.text
                              : null,
                          items: [
                            DropdownMenuItem(
                              value: "Férfi",
                              child: Text(lang.getText("male")),
                            ),
                            DropdownMenuItem(
                              value: "Nő",
                              child: Text(lang.getText("female")),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              gendercontroller.text = value ?? "";
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                CustomCard(
                  title: lang.getText("goals"),
                  child: Padding(
                    padding: const EdgeInsets.all(0),
                    child: Column(
                      children: List.generate(_goals.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 15),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _gselectedIndex = index;
                                goalcontroller.text = _goals[index];
                                if (index == 0)
                                  IncreaseOrDecreaseCalories = 500;
                                else if (index == 2)
                                  IncreaseOrDecreaseCalories = -500;
                                else
                                  IncreaseOrDecreaseCalories = 0;
                              });
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: _gselectedIndex == index
                                    ? const Color.fromARGB(50, 64, 255, 50)
                                    : const Color.fromARGB(255, 58, 58, 58),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Color.fromARGB(100, 64, 255, 50),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  [
                                    lang.getText("bulking"),
                                    lang.getText("level_maintenance"),
                                    lang.getText("weight_loss"),
                                  ][index],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),

                CustomCard(
                  title: lang.getText("activity"),
                  child: Padding(
                    padding: const EdgeInsets.all(0),
                    child: Column(
                      children: List.generate(_activity.length, (index) {
                        final titles = [
                          lang.getText("slightly_active"),
                          lang.getText("moderately_active"),
                          lang.getText("very_active"),
                          lang.getText("extremely_active"),
                        ];
                        final descs = [
                          lang.getText("slightly_active_desc"),
                          lang.getText("moderately_active_desc"),
                          lang.getText("very_active_desc"),
                          lang.getText("extremely_active_desc"),
                        ];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 15),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _aselectedIndex = index;
                                activitycontroller.text = _activity[index];
                                multiplier = [1.375, 1.55, 1.725, 1.9][index];
                              });
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: _aselectedIndex == index
                                    ? const Color.fromARGB(50, 64, 255, 50)
                                    : const Color.fromARGB(255, 58, 58, 58),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Color.fromARGB(100, 64, 255, 50),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    titles[index],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    descs[index],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _aselectedIndex == index
                                          ? Colors.white
                                          : Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),

          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(20),
            child: CustomButton(
              onPressed: () async {
                submitDetails();
              },
              child: Text(
                lang.getText("finish_register"),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
