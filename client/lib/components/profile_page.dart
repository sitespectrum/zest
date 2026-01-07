import 'dart:convert';
import 'package:client/constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:client/main.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  static final ValueNotifier<int> refreshNotifier = ValueNotifier(0);

  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with AutomaticKeepAliveClientMixin {
  String? username;
  bool loggedIn = false;
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initProfile();
  }

  Future<void> _initProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString("username");
      loggedIn = username != null && username!.isNotEmpty;
    });
    if (loggedIn) await _fetchUserData();
    setState(() => isLoading = false);
  }

  Future<void> _fetchUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) return;
    try {
      final response = await http.get(
        Uri.parse("$apiUrl/api/auth/getUser"),
        headers: {"Authorization": "Bearer $token"},
      );
      if (response.statusCode == 200) {
        setState(() => userData = jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint("Hiba az adatok letöltésekor: $e");
    }
  }

  void _showEditPopup() {
    if (userData == null) return;

    final nameController = TextEditingController(text: username);
    final passwordController = TextEditingController(); // Új jelszó kontroller
    final heightController = TextEditingController(
      text: userData!['height'].toString(),
    );
    final weightController = TextEditingController(
      text: userData!['weight'].toString(),
    );
    final birthController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.parse(userData!['birth'])),
    );

    DateTime selectedBirth = DateTime.parse(userData!['birth']);
    String selectedGender = userData!['gender'] == 0 ? "Férfi" : "Nő";
    int gSelectedIndex = userData!['goal'];
    int aSelectedIndex = userData!['activity'];

    final List goals = ["Tömegelés", "Szintentartás", "Fogyás"];
    final List activities = [
      "Enyhén_aktív",
      "Közepesen_aktív",
      "Nagyon_aktív",
      "Extrém_aktív",
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setPopupState) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 35, 35, 35),
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              // Popup fejléc
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Adatok módosítása",
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

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    children: [
                      _buildSectionHeader("Személyes adatok"),
                      _buildProfessionalInput(
                        context,
                        "Felhasználónév",
                        nameController,
                        isNumber: false,
                      ),
                      _buildProfessionalInput(
                        context,
                        "Új jelszó (opcionális)",
                        passwordController,
                        isNumber: false,
                        isPassword: true,
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildProfessionalInput(
                            context,
                            "Magasság",
                            heightController,
                            widthFactor: 0.43,
                          ),
                          _buildProfessionalInput(
                            context,
                            "Súly",
                            weightController,
                            widthFactor: 0.43,
                          ),
                        ],
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildProfessionalDateInput(
                            context,
                            "Szül. idő",
                            birthController,
                            () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedBirth,
                                firstDate: DateTime(1950),
                                lastDate: DateTime.now(),
                                builder: (context, child) => Theme(
                                  data: ThemeData.dark().copyWith(
                                    colorScheme: const ColorScheme.dark(
                                      primary: Colors.green,
                                    ),
                                  ),
                                  child: child!,
                                ),
                              );
                              if (picked != null) {
                                setPopupState(() {
                                  selectedBirth = picked;
                                  birthController.text = DateFormat(
                                    'yyyy-MM-dd',
                                  ).format(picked);
                                });
                              }
                            },
                          ),
                          _buildProfessionalGenderInput(
                            context,
                            "Nem",
                            selectedGender,
                            (val) => setPopupState(() => selectedGender = val!),
                          ),
                        ],
                      ),

                      _buildSectionHeader("Cél"),
                      Column(
                        children: List.generate(
                          3,
                          (index) => _buildSelectionCard(
                            goals[index],
                            gSelectedIndex == index,
                            () => setPopupState(() => gSelectedIndex = index),
                          ),
                        ),
                      ),

                      _buildSectionHeader("Aktivitás"),
                      Column(
                        children: List.generate(
                          4,
                          (index) => _buildSelectionCard(
                            activities[index].replaceAll('_', ' '),
                            aSelectedIndex == index,
                            () => setPopupState(() => aSelectedIndex = index),
                            subText: [
                              "Napi séta, heti 1-3 könnyű edzés.",
                              "Heti 3-5 edzés, ülőmunka.",
                              "Napi edzés, aktív, fizikai munka.",
                              "Napi 2 edzés, például sportkarrier.",
                            ][index],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: _buildZestButton("Módosítások mentése", () async {
                  await _saveAndCalculate(
                    nameController.text,
                    passwordController.text,
                    heightController.text,
                    weightController.text,
                    selectedBirth,
                    selectedGender,
                    goals[gSelectedIndex],
                    activities[aSelectedIndex],
                    gSelectedIndex,
                    aSelectedIndex,
                  );
                  Navigator.pop(context);
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveAndCalculate(
    String name,
    String newPassword,
    String h,
    String w,
    DateTime birth,
    String gender,
    String goal,
    String activity,
    int gIdx,
    int aIdx,
  ) async {
    int height = int.tryParse(h) ?? 0;
    int weight = int.tryParse(w) ?? 0;
    final today = DateTime.now();
    int age = today.year - birth.year;
    if (today.month < birth.month ||
        (today.month == birth.month && today.day < birth.day))
      age--;

    // Details számítás
    double multiplier = [1.375, 1.55, 1.725, 1.9][aIdx];
    int calorieMod = (gIdx == 0) ? 500 : (gIdx == 2 ? -500 : 0);
    double bmr = 10 * weight + 6.25 * height - 5 * age + 5;
    double calorieGoal = bmr * multiplier + calorieMod;

    double proteinGoal = (0.2 * calorieGoal) / 4;
    double carbsGoal = (0.5 * calorieGoal) / 4;
    double fatGoal = (0.3 * calorieGoal) / 9;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    // Jelszó módosítás ha meg lett adva
    if (newPassword.isNotEmpty) {
      await http.put(
        Uri.parse("$apiUrl/api/auth/updatePassword"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"newPassword": newPassword}),
      );
    }

    // Profil adatok mentése
    final response = await http.post(
      Uri.parse("$apiUrl/api/auth/details"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "userId": userData!['id'],
        "userName": name,
        "height": height,
        "weight": weight,
        "birth": birth.toIso8601String(),
        "gender": gender,
        "goal": goal,
        "activity": activity,
        "calorieGoal": calorieGoal,
        "proteinGoal": proteinGoal,
        "carbsGoal": carbsGoal,
        "fatGoal": fatGoal,
      }),
    );

    if (response.statusCode == 200) {
      await prefs.setString("username", name);
      setState(() => username = name);
      await _fetchUserData();
      ProfilePage.refreshNotifier.value++;
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Adatok sikeresen frissítve!"),
            backgroundColor: Colors.green,
          ),
        );
    }
  }

  // --- UI Komponensek ---

  Widget _buildProfessionalInput(
    BuildContext context,
    String label,
    TextEditingController controller, {
    bool isNumber = true,
    double widthFactor = 0.9,
    bool isPassword = false,
  }) {
    return Stack(
      children: [
        Container(
          width: MediaQuery.of(context).size.width * widthFactor,
          height: 70,
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.fromLTRB(10, 15, 8, 5),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 72, 72, 72),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        Positioned(
          top: 5,
          left: 15,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfessionalDateInput(
    BuildContext context,
    String label,
    TextEditingController controller,
    VoidCallback onTap,
  ) {
    return Stack(
      children: [
        Container(
          width: MediaQuery.of(context).size.width * 0.43,
          height: 70,
          margin: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 72, 72, 72),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            readOnly: true,
            onTap: onTap,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: const InputDecoration(
              border: InputBorder.none,
              prefixIcon: Icon(
                Icons.calendar_today,
                color: Colors.white,
                size: 20,
              ),
              contentPadding: EdgeInsets.only(top: 15),
            ),
          ),
        ),
        Positioned(
          top: 5,
          left: 15,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfessionalGenderInput(
    BuildContext context,
    String label,
    String value,
    ValueChanged<String?> onChange,
  ) {
    return Stack(
      children: [
        Container(
          width: MediaQuery.of(context).size.width * 0.43,
          height: 70,
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.only(top: 10),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 72, 72, 72),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            dropdownColor: const Color.fromARGB(255, 72, 72, 72),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 10),
            ),
            items: const [
              DropdownMenuItem(
                value: "Férfi",
                child: Text(
                  "Férfi",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
              DropdownMenuItem(
                value: "Nő",
                child: Text(
                  "Nő",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ],
            onChanged: onChange,
          ),
        ),
        Positioned(
          top: 5,
          left: 15,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionCard(
    String title,
    bool isSelected,
    VoidCallback onTap, {
    String? subText,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color.fromARGB(255, 85, 173, 78)
              : const Color.fromARGB(255, 58, 58, 58),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subText != null)
              Text(
                subText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white70 : Colors.grey,
                  fontSize: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(top: 20, left: 25, bottom: 5),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );

  Widget _buildDisplayCard({
    required String title,
    required List<Widget> rows,
  }) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.fromLTRB(16, 35, 16, 16),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 45, 45, 45),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: rows),
        ),
        Positioned(
          top: 10,
          left: 35,
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: const Color.fromARGB(255, 85, 173, 78),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 18),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZestButton(
    String text,
    VoidCallback onPressed, {
    Color color = const Color.fromARGB(255, 85, 173, 78),
  }) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(double.infinity, 55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 58, 58, 58),
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
                        title: const Text(
                          "Profil",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        automaticallyImplyLeading: false,
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                  ),
                  if (userData != null) ...[
                    _buildDisplayCard(
                      title: "Személyes adatok",
                      rows: [
                        _buildInfoRow(
                          Icons.person_outline,
                          "Felhasználó",
                          username ?? "",
                        ),
                        const Divider(color: Colors.white12),
                        _buildInfoRow(
                          Icons.height,
                          "Magasság",
                          "${userData!['height']} cm",
                        ),
                        const Divider(color: Colors.white12),
                        _buildInfoRow(
                          Icons.fitness_center,
                          "Súly",
                          "${userData!['weight']} kg",
                        ),
                      ],
                    ),
                    _buildDisplayCard(
                      title: "Napi célok",
                      rows: [
                        _buildInfoRow(
                          Icons.local_fire_department,
                          "Kalória",
                          "${userData!['calorieGoal'].toInt()} kcal",
                        ),
                        const Divider(color: Colors.white12),
                        _buildInfoRow(
                          Icons.egg_alt,
                          "Fehérje",
                          "${userData!['proteinGoal'].toInt()} g",
                        ),
                        const Divider(color: Colors.white12),
                        _buildInfoRow(
                          Icons.bakery_dining,
                          "Szénhidrát",
                          "${userData!['carbsGoal'].toInt()} g",
                        ),
                        const Divider(color: Colors.white12),
                        _buildInfoRow(
                          Icons.opacity,
                          "Zsír",
                          "${userData!['fatGoal'].toInt()} g",
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: _buildZestButton(
                        "Adatok módosítása",
                        _showEditPopup,
                      ),
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: _buildZestButton("Kijelentkezés", () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear();
                      if (mounted)
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MainPage(),
                          ),
                          (route) => false,
                        );
                    }, color: const Color.fromARGB(255, 45, 45, 45)),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}
