import 'dart:convert';
import 'dart:ui';
import 'package:client/components/ui/custom_button.dart';
import 'package:client/components/ui/custom_drawer.dart';
import 'package:client/components/ui/custom_snackbar.dart';
import 'package:client/components/ui/custom_textfield.dart';
import 'package:client/providers/language_provider.dart';
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
  final TextEditingController nameController = TextEditingController();

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
      debugPrint("Hiba az adatok betöltésekor: $e");
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
      debugPrint("API Hiba ($endpoint): $e");
    }
    return [];
  }

  Future<void> saveNewExercise() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final langCode = lang.languageCode;

    if (nameController.text.isEmpty ||
        selectedEquipment == null ||
        selectedForce == null ||
        selectedPrimaryMuscle == null) {
      CustomSnackbar.show(
        context,
        lang.getText("fill_all_fields"),
        backgroundColor: Colors.red,
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("$apiUrl/api/workout/newExercise"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": nameController.text,
          "equipment": selectedEquipment,
          "force": selectedForce,
          "primaryMuscles": [selectedPrimaryMuscle],
          "secondaryMuscles": selectedSecondaryMuscle != null
              ? [selectedSecondaryMuscle]
              : [],
          "langCode": langCode,
        }),
      );

      if (response.statusCode == 200) {
        if (context.mounted) {
          CustomSnackbar.show(
            context,
            lang.getText("saved_successfully"),
            backgroundColor: const Color.fromARGB(150, 50, 146, 255),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (context.mounted) {
          CustomSnackbar.show(
            context,
            "${lang.getText("error")}: ${response.statusCode}",
            backgroundColor: Colors.red,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackbar.show(context, e.toString(), backgroundColor: Colors.red);
      }
    }
  }

  Widget _buildSelector({
    required BuildContext context,
    required String label,
    required String? currentValue,
    required List<String> options,
    required Function(String) onSelect,
  }) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          elevation: 0,
          builder: (context) => CustomDrawer(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: options.isEmpty
                        ? const Center(
                            child: Text(
                              "Nincs adat",
                              style: TextStyle(color: Colors.white54),
                            ),
                          )
                        : ListView.builder(
                            itemCount: options.length,
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (context, index) {
                              final option = options[index];
                              final isSelected = option == currentValue;

                              return ListTile(
                                title: Text(
                                  option,
                                  style: TextStyle(
                                    color: isSelected
                                        ? const Color.fromARGB(255, 85, 173, 78)
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
                                        color: Color.fromARGB(255, 85, 173, 78),
                                      )
                                    : null,
                                onTap: () {
                                  onSelect(option);
                                  Navigator.pop(context);
                                  FocusScope.of(context).unfocus();
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          filled: true,
          fillColor: const Color(0xFF272727),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: Color.fromARGB(150, 50, 146, 255),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white.withAlpha(20), width: 1),
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 16,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              currentValue ?? "",
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color.fromARGB(255, 85, 173, 78),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PreferredSize(
                    preferredSize: const Size.fromHeight(60),
                    child: Container(
                      margin: const EdgeInsets.all(6),
                      child: AppBar(
                        backgroundColor: Colors.transparent,
                        automaticallyImplyLeading: false,
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ClipRRect(
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
                                      color: const Color.fromRGBO(
                                        45,
                                        45,
                                        45,
                                        0.5,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.arrow_back),
                                          color: Colors.white,
                                          padding: EdgeInsets.only(
                                            left: 0,
                                            top: 0,
                                            bottom: 0,
                                            right: 10,
                                          ),
                                          constraints: const BoxConstraints(),
                                          style: IconButton.styleFrom(
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          onPressed: () =>
                                              Navigator.maybePop(context),
                                        ),
                                        Text(
                                          lang.getText("new_workout"),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    child: Column(
                      children: [
                        CustomTextField(
                          nameController,
                          lang.getText("name"),
                          isNumber: false,
                          isCreateWorkout: true,
                        ),
                        const SizedBox(height: 15),

                        Row(
                          children: [
                            Expanded(
                              child: _buildSelector(
                                context: context,
                                label: lang.getText("equipment"),
                                currentValue: selectedEquipment,
                                options: equipmentList,
                                onSelect: (val) =>
                                    setState(() => selectedEquipment = val),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _buildSelector(
                                context: context,
                                label: lang.getText("force"),
                                currentValue: selectedForce,
                                options: forces,
                                onSelect: (val) =>
                                    setState(() => selectedForce = val),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),

                        Row(
                          children: [
                            Expanded(
                              child: _buildSelector(
                                context: context,
                                label: lang.getText("primaryMuscle"),
                                currentValue: selectedPrimaryMuscle,
                                options: muscles,
                                onSelect: (val) =>
                                    setState(() => selectedPrimaryMuscle = val),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _buildSelector(
                                context: context,
                                label: lang.getText("secondaryMuscle"),
                                currentValue: selectedSecondaryMuscle,
                                options: muscles,
                                onSelect: (val) => setState(
                                  () => selectedSecondaryMuscle = val,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: CustomButton(
            onPressed: () {
              saveNewExercise();
            },
            title: lang.getText("save"),
            iconData: Icons.save,
            variant: CustomButtonVariant.primaryWorkout,
          ),
        ),
      ),
    );
  }
}
