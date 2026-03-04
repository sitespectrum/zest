import 'dart:convert';
import 'dart:ui';
import 'package:client/components/ui/custom_snackbar.dart';
import 'package:client/components/ui/custom_textfield.dart';
import 'package:client/components/utils/keyboard_aware_drawer.dart';
import 'package:client/providers/language_provider.dart';
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
import 'package:image_picker/image_picker.dart';
import 'friends_page.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:client/utils/scroll_behavior.dart';

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
  String currentLanguage = "hu";

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

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (image == null) return;

    try {
      List<int> imageBytes = await image.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      final response = await http.post(
        Uri.parse("$apiUrl/api/auth/uploadImage"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(base64Image),
      );

      if (response.statusCode == 200) {
        setState(() {
          if (userData != null) {
            userData!['profilePicture'] = base64Image;
          }
        });
        if (mounted) {
          CustomSnackbar.show(
            context,
            "Profilkép frissítve!",
            backgroundColor: Colors.green,
          );
        }
      } else {
        debugPrint("Hiba a feltöltéskor: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Hiba: $e");
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

    Future<void> _selectDate(BuildContext context) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.tryParse(birthController.text) ?? DateTime(2000),
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Color.fromARGB(255, 85, 173, 78),
                onPrimary: Colors.white,
                surface: Color.fromRGBO(39, 39, 39, 1),
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
          birthController.text = DateFormat('yyyy-MM-dd').format(picked);
        });
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      elevation: 0,
      builder: (context) => StatefulBuilder(
        builder: (context, setPopupState) => CustomDrawer(
          child: KeyboardAwareDrawer(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.78,
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 10, bottom: 10),
                    child: Row(
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
                  ),
                  SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          _buildStyledDropdown(
                            label: lang.getText("language"),
                            value: selectedLanguage,
                            items: const [
                              DropdownMenuItem(
                                value: "hu",
                                child: Text("Magyar"),
                              ),
                              DropdownMenuItem(
                                value: "en",
                                child: Text("English"),
                              ),
                            ],
                            onChanged: (val) {
                              setPopupState(() => selectedLanguage = val!);
                              Provider.of<LanguageProvider>(
                                context,
                                listen: false,
                              ).changeLanguage(val!);
                            },
                            isLangSelector: true,
                          ),
                          SizedBox(height: 20),
                          Center(
                            child: _buildSectionHeader(
                              lang.getText("personal_details"),
                            ),
                          ),
                          SizedBox(height: 20),
                          CustomTextField(
                            nameController,
                            lang.getText("username_hint"),
                            isPassword: false,
                            isNumber: false,
                            isSuffix: false,
                          ),
                          SizedBox(height: 20),
                          CustomTextField(
                            passwordController,
                            lang.getText("password_hint"),
                            isNumber: false,
                            isPassword: true,
                            isSuffix: false,
                          ),
                          SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: CustomTextField(
                                  heightController,
                                  lang.getText("height"),
                                  isNumber: true,
                                  isSuffix: true,
                                  suffix: " cm",
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: CustomTextField(
                                  weightController,
                                  lang.getText("weight"),
                                  isNumber: true,
                                  isSuffix: true,
                                  suffix: " kg",
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => _selectDate(context),
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      isDense: true,
                                      prefixIconConstraints:
                                          const BoxConstraints(
                                            minWidth: 40,
                                            minHeight: 40,
                                          ),
                                      contentPadding: const EdgeInsets.fromLTRB(
                                        12,
                                        16,
                                        12,
                                        16,
                                      ),
                                      labelText: lang.getText("born_in"),
                                      labelStyle: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.calendar_today,
                                        color: Colors.white70,
                                      ),
                                      filled: true,
                                      fillColor: const Color(0xFF272727),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.white.withAlpha(20),
                                          width: 1,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Text(
                                      birthController.text.isEmpty
                                          ? "ÉÉÉÉ-HH-NN"
                                          : birthController.text,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: _buildStyledDropdown(
                                  label: lang.getText("gender"),
                                  value: selectedGender,
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
                                  onChanged: (val) => setPopupState(
                                    () => selectedGender = val!,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          Center(
                            child: _buildSectionHeader(lang.getText("goals")),
                          ),
                          SizedBox(height: 20),
                          Column(
                            children: List.generate(
                              3,
                              (index) => _buildSelectionCard(
                                goals[index],
                                gSelectedIndex == index,
                                () =>
                                    setPopupState(() => gSelectedIndex = index),
                              ),
                            ),
                          ),

                          Center(
                            child: _buildSectionHeader(
                              lang.getText("activity"),
                            ),
                          ),
                          SizedBox(height: 20),
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
                                  () => setPopupState(
                                    () => aSelectedIndex = index,
                                  ),
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
                    padding: const EdgeInsets.only(top: 15, right: 5, left: 5),
                    child: customButton(
                      title: lang.getText("save_changes"),
                      onPressed: () async {
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
        CustomSnackbar.show(
          context,
          lang.getText("data_successfully_updated"),
          backgroundColor: Colors.green,
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
    OneSignal.logout();

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
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color.fromARGB(50, 64, 255, 50)
              : const Color.fromARGB(255, 58, 58, 58),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color.fromARGB(100, 64, 255, 50)),
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
    padding: const EdgeInsets.only(top: 10, bottom: 10),
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

  Widget _buildStyledDropdown({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    bool isLangSelector = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Color.fromRGBO(39, 39, 39, 1),
        borderRadius: BorderRadius.circular(16),
      ),
      margin: isLangSelector
          ? const EdgeInsets.only(top: 30)
          : const EdgeInsets.all(0),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items,
        onChanged: onChanged,
        dropdownColor: const Color(0xFF272727),
        style: const TextStyle(color: Colors.white, fontSize: 16),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
          alignLabelWithHint: true,
          isDense: true,
          labelText: label,
          labelStyle: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          fillColor: const Color.fromRGBO(45, 45, 45, 1),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () async => _initProfile(),
        child: isLoading
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
                                        builder: (context) =>
                                            const FriendsPage(),
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
                      if (userData != null)
                        Center(
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              GestureDetector(
                                onTap: _pickAndUploadImage,
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color.fromARGB(
                                            255,
                                            85,
                                            173,
                                            78,
                                          ),
                                          width: 3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.3,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        radius: 60,
                                        backgroundColor: const Color(
                                          0xFF272727,
                                        ),
                                        backgroundImage:
                                            (userData!['profilePicture'] !=
                                                    null &&
                                                userData!['profilePicture']
                                                    .toString()
                                                    .isNotEmpty)
                                            ? MemoryImage(
                                                base64Decode(
                                                  userData!['profilePicture'],
                                                ),
                                              )
                                            : null,
                                        child:
                                            (userData!['profilePicture'] ==
                                                    null ||
                                                userData!['profilePicture']
                                                    .toString()
                                                    .isEmpty)
                                            ? const Icon(
                                                Icons.person,
                                                size: 60,
                                                color: Colors.white54,
                                              )
                                            : null,
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: const BoxDecoration(
                                          color: Color.fromARGB(
                                            255,
                                            85,
                                            173,
                                            78,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 15),
                              Text(
                                username ?? "Felhasználó",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      if (userData != null) ...[
                        CustomCard(
                          title: lang.getText("personal_details"),
                          iconData: Icons.person,
                          child: Column(
                            children: [
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
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.14,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
