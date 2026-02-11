import 'dart:convert';
import 'dart:ui';
import 'package:client/Providers/language_provider.dart';
import 'package:client/components/ui/custom_button.dart';
import 'package:client/components/ui/custom_card.dart';
import 'package:client/components/ui/custom_drawer.dart';
import 'package:provider/provider.dart';
import 'package:client/constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:client/main.dart';
import 'package:intl/intl.dart';
import 'friends_page.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../utils/scroll_behavior.dart';

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
  String currentLanguage = "Magyar";

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
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final nameController = TextEditingController(text: username);
    final passwordController = TextEditingController();
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
    String selectedLanguage = currentLanguage;
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
      elevation: 0,
      builder: (context) => StatefulBuilder(
        builder: (context, setPopupState) => CustomDrawer(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.9,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      lang.getText("modify_details"),
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

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Center(
                          child: _buildProfessionalLanguageInput(
                            context,
                            lang.getText("language"),
                            selectedLanguage,
                            (val) =>
                                setPopupState(() => selectedLanguage = val!),
                          ),
                        ),
                        Center(
                          child: _buildSectionHeader(
                            lang.getText("personal_details"),
                          ),
                        ),
                        _buildProfessionalInput(
                          context,
                          lang.getText("username_hint"),
                          nameController,
                          isNumber: false,
                        ),
                        _buildProfessionalInput(
                          context,
                          lang.getText("password_hint"),
                          passwordController,
                          isNumber: false,
                          isPassword: true,
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildProfessionalInput(
                              context,
                              lang.getText("height"),
                              heightController,
                              widthFactor: 0.4,
                              suffix: " cm",
                            ),
                            _buildProfessionalInput(
                              context,
                              lang.getText("weight"),
                              weightController,
                              widthFactor: 0.4,
                              suffix: " kg",
                            ),
                          ],
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildProfessionalDateInput(
                              context,
                              lang.getText("born_in"),
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
                                        onPrimary: Colors.white,
                                        surface: Color.fromARGB(
                                          255,
                                          72,
                                          72,
                                          72,
                                        ),
                                        onSurface: Colors.white,
                                      ),
                                      dialogBackgroundColor:
                                          const Color.fromARGB(255, 72, 72, 72),
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
                              lang.getText("gender"),
                              selectedGender,
                              (val) =>
                                  setPopupState(() => selectedGender = val!),
                            ),
                          ],
                        ),

                        Center(
                          child: _buildSectionHeader(lang.getText("goals")),
                        ),
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

                        Center(
                          child: _buildSectionHeader(lang.getText("activity")),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Column(
                            children: List.generate(4, (index) {
                              final titles = [
                                lang.getText("slightly_active"),
                                lang.getText("moderately_active"),
                                lang.getText("very_active"),
                                lang.getText("extremely_active"),
                              ];

                              final descriptions = [
                                lang.getText("slightly_active_desc"),
                                lang.getText("moderately_active_desc"),
                                lang.getText("very_active_desc"),
                                lang.getText("extremely_active_desc"),
                              ];

                              return _buildSelectionCard(
                                titles[index],
                                aSelectedIndex == index,
                                () =>
                                    setPopupState(() => aSelectedIndex = index),
                                subText: descriptions[index],
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: _buildZestButton(
                    lang.getText("save_changes"),
                    () async {
                      setState(() {
                        currentLanguage = selectedLanguage;
                      });

                      bool shouldClose = await _saveAndCalculate(
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

                      if (shouldClose && context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _saveAndCalculate(
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
        (today.month == birth.month && today.day < birth.day)) {
      age--;
    }

    double multiplier = [1.375, 1.55, 1.725, 1.9][aIdx];
    int calorieMod = (gIdx == 0) ? 500 : (gIdx == 2 ? -500 : 0);
    double bmr = 10 * weight + 6.25 * height - 5 * age + 5;
    double calorieGoal = bmr * multiplier + calorieMod;

    double proteinGoal = (0.2 * calorieGoal) / 4;
    double carbsGoal = (0.5 * calorieGoal) / 4;
    double fatGoal = (0.3 * calorieGoal) / 9;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final lang = Provider.of<LanguageProvider>(context, listen: false);

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

      if (newPassword.isNotEmpty) {
        await http.put(
          Uri.parse("$apiUrl/api/auth/updatePassword"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
          body: jsonEncode({"newPassword": newPassword}),
        );
        await _logout();
        return false;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lang.getText("data_successfully_updated")),
            showCloseIcon: true,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(bottom: 30, left: 16, right: 16),
            duration: Duration(milliseconds: 1800),
            animation: CurvedAnimation(
              parent: kAlwaysCompleteAnimation,
              curve: Curves.easeInOut,
            ),
          ),
        );
      }
      return true;
    }
    return false;
  }

  Future<void> _logout() async {
    OneSignal.logout();
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final refreshToken = prefs.getString('refresh_token');

    try {
      final response = await http.post(
        Uri.parse("$apiUrl/api/auth/logout"),
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
        body: jsonEncode(refreshToken ?? ""),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint("Sikeres kijelentkezés a szerveren.");
      } else {
        debugPrint(
          "Sikertelen kijelentkezés: ${response.statusCode} ${response.body}",
        );
      }
    } catch (e) {
      debugPrint("Hiba a kijelentkezés során: $e");
    }

    await prefs.remove("username");
    await prefs.remove("jwt_token");
    await prefs.remove("accessToken");
    await prefs.remove("refreshToken");

    setState(() {
      loggedIn = false;
      username = null;
    });

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainPage()),
        (route) => false,
      );
    }
  }

  Widget _buildProfessionalInput(
    BuildContext context,
    String label,
    TextEditingController controller, {
    bool isNumber = true,
    double widthFactor = 0.9,
    bool isPassword = false,
    String? suffix,
  }) {
    return Stack(
      children: [
        Container(
          width: MediaQuery.of(context).size.width * widthFactor,
          height: MediaQuery.of(context).size.height * 0.092,
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          padding: const EdgeInsets.fromLTRB(12, 11, 12, 5),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 72, 72, 72),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              suffixText: suffix,
              suffixStyle: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height * -0.003,
          left: MediaQuery.of(context).size.width * 0.03,
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
      clipBehavior: Clip.none,
      children: [
        Container(
          width: MediaQuery.of(context).size.width * 0.43,
          height: MediaQuery.of(context).size.height * 0.092,
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.fromLTRB(5, 7, 0.5, 2),
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
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  controller: controller,
                  decoration: InputDecoration(
                    border: InputBorder.none,
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
                  onTap: onTap,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height * -0.015,
          left: MediaQuery.of(context).size.width * 0.02,
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
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    return Stack(
      children: [
        Container(
          width: MediaQuery.of(context).size.width * 0.43,
          height: MediaQuery.of(context).size.height * 0.092,
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
          padding: const EdgeInsets.fromLTRB(1, 9, 8, 5),
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
            items: [
              DropdownMenuItem(
                value: "Férfi",
                child: Text(
                  lang.getText("male"),
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
              DropdownMenuItem(
                value: "Nő",
                child: Text(
                  lang.getText("female"),
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ],
            onChanged: onChange,
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height * -0.003,
          left: MediaQuery.of(context).size.width * 0.015,
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

  Widget _buildProfessionalLanguageInput(
    BuildContext context,
    String label,
    String value,
    ValueChanged<String?> onChange,
  ) {
    return Stack(
      children: [
        Container(
          width: MediaQuery.of(context).size.width * 0.4,
          height: MediaQuery.of(context).size.height * 0.092,
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
          padding: const EdgeInsets.fromLTRB(1, 9, 8, 5),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 72, 72, 72),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<String>(
            value: Provider.of<LanguageProvider>(context).languageCode,
            dropdownColor: const Color.fromARGB(255, 72, 72, 72),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 10),
            ),
            items: const [
              DropdownMenuItem(
                value: "hu",
                child: Text(
                  "Magyar",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
              DropdownMenuItem(
                value: "en",
                child: Text(
                  "English",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ],
            onChanged: (String? newValue) {
              if (newValue != null) {
                Provider.of<LanguageProvider>(
                  context,
                  listen: false,
                ).changeLanguage(newValue);
              }
            },
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height * -0.003,
          left: MediaQuery.of(context).size.width * 0.015,
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
        width: MediaQuery.of(context).size.width * 0.4,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        padding: const EdgeInsets.symmetric(vertical: 15),
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
    padding: const EdgeInsets.only(top: 10, bottom: 5),
    child: Align(
      alignment: Alignment.center,
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
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
    Color color = const Color.fromRGBO(85, 173, 78, 0.5),
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color.fromRGBO(78, 156, 71, 255)),
            ),
            child: FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.transparent,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
                elevation: 0,
              ),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color.fromARGB(255, 85, 173, 78),
              ),
            )
          : ScrollConfiguration(
              behavior: NoGlowScrollBehavior(),
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PreferredSize(
                      preferredSize: const Size.fromHeight(60),
                      child: Container(
                        margin: const EdgeInsets.all(6),
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
                                    color: const Color.fromRGBO(
                                      45,
                                      45,
                                      45,
                                      0.5,
                                    ),
                                  ),
                                  child: Text(
                                    lang.getText("profile_page"),
                                    style: TextStyle(
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
                          actions: [
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: IconButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const FriendsPage(),
                                    ),
                                  );
                                },
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Color.fromARGB(255, 85, 173, 78),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.group,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (userData != null) ...[
                      CustomCard(
                        title: lang.getText("personal_details"),
                        iconData: Icons.person,
                        child: Column(
                          children: [
                            _buildInfoRow(
                              Icons.person_outline,
                              lang.getText("user"),
                              username ?? "",
                            ),
                            const Divider(color: Colors.white12),
                            _buildInfoRow(
                              Icons.height,
                              lang.getText("height"),
                              "${userData!['height']} cm",
                            ),
                            const Divider(color: Colors.white12),
                            _buildInfoRow(
                              Icons.fitness_center,
                              lang.getText("weight"),
                              "${userData!['weight']} kg",
                            ),
                          ],
                        ),
                      ),
                      CustomCard(
                        title: lang.getText("daily_goals"),
                        iconData: Icons.calendar_month,
                        child: Column(
                          children: [
                            _buildInfoRow(
                              Icons.local_fire_department,
                              lang.getText("calories"),
                              "${userData!['calorieGoal'].toInt()} kcal",
                            ),
                            const Divider(color: Colors.white12),
                            _buildInfoRow(
                              Icons.egg_alt,
                              lang.getText("protein"),
                              "${userData!['proteinGoal'].toInt()} g",
                            ),
                            const Divider(color: Colors.white12),
                            _buildInfoRow(
                              Icons.bakery_dining,
                              lang.getText("carbs"),
                              "${userData!['carbsGoal'].toInt()} g",
                            ),
                            const Divider(color: Colors.white12),
                            _buildInfoRow(
                              Icons.opacity,
                              lang.getText("fat"),
                              "${userData!['fatGoal'].toInt()} g",
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: CustomButton(
                          onPressed: () {
                            _showEditPopup();
                          },
                          title: lang.getText("modify_details"),
                          variant: CustomButtonVariant.primary,
                        ),
                      ),
                    ],
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: CustomButton(
                        onPressed: () async {
                          await _logout();
                        },
                        title: lang.getText("logout"),
                        variant: CustomButtonVariant.secondary,
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.14),
                  ],
                ),
              ),
            ),
    );
  }
}
