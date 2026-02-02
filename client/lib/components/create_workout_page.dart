import 'dart:convert';
import 'package:client/Providers/language_provider.dart';
import 'package:client/constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class CreateWorkoutPage extends StatefulWidget {
  const CreateWorkoutPage({super.key});

  @override
  State<CreateWorkoutPage> createState() => _CreateWorkoutPageState();
}

class _CreateWorkoutPageState extends State<CreateWorkoutPage> {
  final TextEditingController namecontroller = TextEditingController();

  String? selectedEquipment;
  String? selectedForce;
  String? selectedPrimaryMuscle;
  String? selectedSecondaryMuscle;

  List<String> equipmentList = [];
  List<String> forces = [];
  List<String> muscles = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAllOptions();
    });
  }

  Future<void> saveNewExercise() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final langCode = Provider.of<LanguageProvider>(
      context,
      listen: false,
    ).languageCode;
    final name = namecontroller.text;
    final equipment = selectedEquipment;
    final force = selectedForce;

    final response = await http.post(
      Uri.parse("$apiUrl/api/workout/newExercise"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": name,
        "equipment": equipment,
        "force": force,
        "primaryMuscles": selectedPrimaryMuscle != null
            ? [selectedPrimaryMuscle]
            : [],
        "secondaryMuscles": selectedSecondaryMuscle != null
            ? [selectedSecondaryMuscle]
            : [],
        "langCode": langCode,
      }),
    );

    if (response.statusCode == 200) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Sikeres mentés!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      print("Hiba: ${response.body}");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hiba történt: ${response.statusCode}")),
        );
      }
    }
  }

  Future<void> _fetchAllOptions() async {
    final langCode = Provider.of<LanguageProvider>(
      context,
      listen: false,
    ).languageCode;

    try {
      final results = await Future.wait([
        _fetchList("equipment", langCode),
        _fetchList("forces", langCode),
        _fetchList("muscle-groups", langCode),
      ]);

      if (mounted) {
        setState(() {
          equipmentList = results[0];
          forces = results[1];
          muscles = results[2];
          isLoading = false;
        });
      }
    } catch (e) {
      print("Hiba az adatok betöltésekor: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<List<String>> _fetchList(String endpoint, String lang) async {
    try {
      final response = await http.get(
        Uri.parse("$apiUrl/api/Workout/$endpoint?lang=$lang"),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<String>();
      }
    } catch (e) {
      print("API Hiba ($endpoint): $e");
    }
    return [];
  }

  Widget _buildSelectorField({
    required BuildContext context,
    required String label,
    required String? currentValue,
    required List<String> options,
    required Function(String) onSelect,
  }) {
    final lang = Provider.of<LanguageProvider>(context);
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          builder: (context) => StatefulBuilder(
            builder: (context, setPopupState) => Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.7,
                clipBehavior: Clip.hardEdge,
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 35, 35, 35),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "$label ${lang.getText("select")}",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: options.isEmpty
                          ? const Center(
                              child: Text(
                                "Nincs elérhető adat",
                                style: TextStyle(color: Colors.white54),
                              ),
                            )
                          : ListView.builder(
                              itemCount: options.length,
                              itemBuilder: (context, index) {
                                final option = options[index];
                                final isSelected = option == currentValue;
                                return ListTile(
                                  title: Text(
                                    option,
                                    style: TextStyle(
                                      color: isSelected
                                          ? const Color.fromARGB(
                                              255,
                                              85,
                                              173,
                                              78,
                                            )
                                          : Colors.white70,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      fontSize: 16,
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          color: Color.fromARGB(
                                            255,
                                            85,
                                            173,
                                            78,
                                          ),
                                        )
                                      : null,
                                  onTap: () {
                                    onSelect(option);
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.085,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 72, 72, 72),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    currentValue ?? "Válassz...",
                    style: TextStyle(
                      color: currentValue != null
                          ? Colors.white
                          : Colors.white38,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.arrow_drop_down,
                  color: Colors.white70,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  PreferredSize(
                    preferredSize: const Size.fromHeight(60),
                    child: Container(
                      margin: const EdgeInsets.all(6),
                      child: AppBar(
                        iconTheme: IconThemeData(color: Colors.white),
                        title: Text(
                          lang.getText('create_exercise'),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: Color.fromARGB(255, 58, 58, 58),
                      ),
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              height:
                                  MediaQuery.of(context).size.height * 0.085,
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
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                    ),
                                    controller: namecontroller,
                                    decoration: InputDecoration(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
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
                                    keyboardType: TextInputType.text,
                                  ),
                                ],
                              ),
                            ),

                            Positioned(
                              top: MediaQuery.of(context).size.height * 0.008,
                              left: MediaQuery.of(context).size.width * 0.08,
                              child: Text(
                                lang.getText("name"),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
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
                            padding: const EdgeInsets.fromLTRB(10, 12, 8, 5),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 72, 72, 72),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Stack(
                              children: [
                                _buildSelectorField(
                                  context: context,
                                  label: lang.getText("equipment"),
                                  currentValue: selectedEquipment,
                                  options: equipmentList,
                                  onSelect: (val) =>
                                      setState(() => selectedEquipment = val),
                                ),
                              ],
                            ),
                          ),

                          Positioned(
                            top: MediaQuery.of(context).size.height * 0.008,
                            left: MediaQuery.of(context).size.width * 0.08,
                            child: Text(
                              lang.getText("equipment"),
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
                            child: Stack(
                              children: [
                                _buildSelectorField(
                                  context: context,
                                  label: lang.getText("force"),
                                  currentValue: selectedForce,
                                  options: forces,
                                  onSelect: (val) =>
                                      setState(() => selectedForce = val),
                                ),
                              ],
                            ),
                          ),

                          Positioned(
                            top: MediaQuery.of(context).size.height * 0.008,
                            left: MediaQuery.of(context).size.width * 0.04,
                            child: Text(
                              lang.getText("force"),
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
                            padding: const EdgeInsets.fromLTRB(10, 12, 8, 5),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 72, 72, 72),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Stack(
                              children: [
                                _buildSelectorField(
                                  context: context,
                                  label: lang.getText("primaryMuscle"),
                                  currentValue: selectedPrimaryMuscle,
                                  options: muscles,
                                  onSelect: (val) => setState(
                                    () => selectedPrimaryMuscle = val,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Positioned(
                            top: MediaQuery.of(context).size.height * 0.008,
                            left: MediaQuery.of(context).size.width * 0.08,
                            child: Text(
                              lang.getText("primaryMuscle"),
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
                            child: Stack(
                              children: [
                                _buildSelectorField(
                                  context: context,
                                  label: lang.getText("secondaryMuscle"),
                                  currentValue: selectedSecondaryMuscle,
                                  options: muscles,
                                  onSelect: (val) => setState(
                                    () => selectedSecondaryMuscle = val,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Positioned(
                            top: MediaQuery.of(context).size.height * 0.008,
                            left: MediaQuery.of(context).size.width * 0.04,
                            child: Text(
                              lang.getText("secondaryMuscle"),
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
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FilledButton(
              onPressed: () async {
                saveNewExercise();
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 85, 173, 78),
                fixedSize: Size(
                  MediaQuery.of(context).size.width * 0.8888,
                  MediaQuery.of(context).size.height * 0.07,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              child: Text(
                lang.getText("save"),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
