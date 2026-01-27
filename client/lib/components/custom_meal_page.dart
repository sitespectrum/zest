import 'dart:typed_data';

import 'package:ai_barcode_scanner/ai_barcode_scanner.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nfc_host_card_emulation/nfc_host_card_emulation.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Providers/language_provider.dart';
import 'add_meal_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:client/models/meal.dart';
import 'dart:async';
import 'package:client/pages.dart';
import '../constants.dart';

class CMealPage extends StatefulWidget {
  final DateTime selectedDay;
  const CMealPage({super.key, required this.selectedDay});

  @override
  State<CMealPage> createState() => _CMealPageState();
}

final mealtypecontroller = TextEditingController();
final mealnamecontroller = TextEditingController();

class _CMealPageState extends State<CMealPage> {
  Future<void> saveUserMeals(
    List<MealDto> meals,
    String mealName,
    int userId,
  ) async {
    final totalCalories = meals.fold<int>(
      0,
      (sum, meal) => sum + meal.calories,
    );
    final totalProtein = meals.fold<double>(
      0.0,
      (sum, meal) => sum + meal.protein,
    );
    final totalCarbs = meals.fold<double>(0.0, (sum, meal) => sum + meal.carbs);
    final totalFat = meals.fold<double>(0.0, (sum, meal) => sum + meal.fat);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    if (token == null || token.isEmpty) throw Exception("Nincs token.");

    final uri = Uri.parse("$apiUrl/api/Meals/addGroup");

    final dto = {
      "MealName": mealName,
      "UserId": userId,
      "EatenAt": widget.selectedDay.toIso8601String(),
      "Meals": meals.map((m) => m.toJson()).toList(),
      "TotalCalories": totalCalories,
      "TotalProtein": totalProtein,
      "TotalCarbs": totalCarbs,
      "TotalFat": totalFat,
      "BaseWeight": meals.first.baseWeight,
      "Unit": meals.first.unit,
      "IsCustom": false,
    };

    final response = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(dto),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        "${lang.getText("failed_to_save")} ${response.statusCode} ${response.body}",
      );
    }
  }

  Future<bool> deleteMealFromTemplate(int id) async {
    final url = Uri.parse("$apiUrl/api/Meals/DeleteCustomMeal?id=$id");
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    try {
      final response = await http.delete(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print("Nem sikerült törölni: ${response.body}");
        print("Status: ${response.statusCode}, body: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Hiba törlés közben: $e");
      return false;
    }
  }

  Future<bool> deleteUserMealTemplate(int id) async {
    final url = Uri.parse("$apiUrl/api/Meals/DeleteTemplate?id=$id");
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    try {
      final response = await http.delete(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print("Szerver hiba (${response.statusCode}): ${response.body}");
        return false;
      }
    } catch (e) {
      print("Hálózati hiba: $e");
      return false;
    }
  }

  Future<void> saveUserMealsS(
    List<MealDto> meals,
    String customName,
    int userId,
  ) async {
    final totalCalories = meals.fold<int>(
      0,
      (sum, meal) => sum + meal.calories,
    );
    final totalProtein = meals.fold<double>(
      0.0,
      (sum, meal) => sum + meal.protein,
    );
    final totalCarbs = meals.fold<double>(0.0, (sum, meal) => sum + meal.carbs);
    final totalFat = meals.fold<double>(0.0, (sum, meal) => sum + meal.fat);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    if (token == null || token.isEmpty) throw Exception("Nincs token.");

    final uri = Uri.parse("$apiUrl/api/Meals/addGroupS");

    final dto = {
      "CustomName": mealnamecontroller.text,
      "UserId": userId,
      "EatenAt": widget.selectedDay.toIso8601String(),
      "Meals": meals.map((m) => m.toJson()).toList(),
      "TotalCalories": totalCalories,
      "TotalProtein": totalProtein,
      "TotalCarbs": totalCarbs,
      "TotalFat": totalFat,
      "BaseWeight": meals.first.baseWeight,
      "Unit": meals.first.unit,
      "IsCustom": true,
    };

    final response = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(dto),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        "${lang.getText("failed_to_save")} ${response.statusCode} ${response.body}",
      );
    }
  }

  // ignore: non_constant_identifier_names
  Future<void> UserMealsSampleSave(
    List<MealDto> meals,
    String customName,
    int userId,
  ) async {
    final totalCalories = meals.fold<int>(
      0,
      (sum, meal) => sum + meal.calories,
    );
    final totalProtein = meals.fold<double>(
      0.0,
      (sum, meal) => sum + meal.protein,
    );
    final totalCarbs = meals.fold<double>(0.0, (sum, meal) => sum + meal.carbs);
    final totalFat = meals.fold<double>(0.0, (sum, meal) => sum + meal.fat);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    if (token == null || token.isEmpty) throw Exception("Nincs token.");

    final uri = Uri.parse("$apiUrl/api/Meals/addGroupS");

    final dto = {
      "CustomName": customName,
      "UserId": userId,
      "EatenAt": widget.selectedDay.toIso8601String(),
      "Meals": meals.map((m) => m.toJson()).toList(),
      "TotalCalories": totalCalories,
      "TotalProtein": totalProtein,
      "TotalCarbs": totalCarbs,
      "TotalFat": totalFat,
      "BaseWeight": meals.first.baseWeight,
      "Unit": meals.first.unit,
      "IsCustom": false,
    };

    final response = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(dto),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        "${lang.getText("failed_to_save")} ${response.statusCode} ${response.body}",
      );
    }
  }

  Future<void> saveTemplateAsUserMeal(
    CustomUserMealDto template,
    int userId,
  ) async {
    await UserMealsSampleSave(template.meals, template.customName, userId);
  }

  List<MealDto> userMeals = [];
  int mealindex = 4;
  bool showdelete = false;
  final List _mealtypes = ["Reggeli", "Ebéd", "Vacsora", "Egyéb"];
  int get userCaloriesSum =>
      userMeals.fold<int>(0, (sum, meal) => sum + meal.qCalories);
  double get userProteinsSum =>
      userMeals.fold<double>(0.0, (sum, meal) => sum + meal.qProtein);
  double get userCarbsSum =>
      userMeals.fold<double>(0, (sum, meal) => sum + meal.qCarbs);
  double get userFatSum =>
      userMeals.fold<double>(0, (sum, meal) => sum + meal.qFat);
  Timer? _debounce;
  late Future<List<CustomUserMealDto>> futureCustomMeals;

  @override
  void initState() {
    super.initState();
    futureCustomMeals = fetchCustomUserMeals().catchError((e) {
      return <CustomUserMealDto>[];
    });
  }

  Future<List<CustomUserMealDto>> fetchCustomUserMeals() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    if (token == null) throw Exception("Nincs token");

    final response = await http.get(
      Uri.parse("$apiUrl/api/meals/getCustomUserMeals"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => CustomUserMealDto.fromJson(e)).toList();
    } else {
      throw Exception(
        "${lang.getText("failed_to_fetch_meals")} ${response.body}",
      );
    }
  }

  void startNfcSharing(List<dynamic> workouts) async {
    print("Megosztás indítása");

    String jsonString = jsonEncode(workouts.map((e) => e.toJson()).toList());
    Uint8List databytes = utf8.encode(jsonString);

    if (databytes.length > 240) {
      print(
        "Hiba: Túl sok adat az NFC kézfogáshoz! (${databytes.length} bájt)",
      );
    }
    try {
      await NfcHce.removeApduResponse(0);
      List<int> response = [...databytes, 0x90, 0x00];

      await NfcHce.addApduResponse(0, response);

      print("A telefon most NFC kártyaként üzemel! Érintsd hozzá a másikat.");
    } catch (e) {
      print("Nem sikerült elindítani az emulációt: $e");
    }
  }

  void stopNfcSharing() async {
    await NfcHce.removeApduResponse(0);
    print("NFC megosztás kikapcsolva.");
  }

  void startNfcReceiving() {
    print("Keresem a másik telefont...");

    NfcManager.instance.startSession(
      pollingOptions: {NfcPollingOption.iso14443},
      onDiscovered: (NfcTag tag) async {
        IsoDepAndroid? isoDep = IsoDepAndroid.from(tag);

        if (isoDep != null) {
          try {
            List<int> command = [
              0x00,
              0xA4,
              0x04,
              0x00,
              0x07,
              0xF0,
              0x01,
              0x02,
              0x03,
              0x04,
              0x05,
              0x06,
              0x00,
            ];

            print("Adat lekérése...");

            isoDep.setTimeout(3000);
            Uint8List response = await isoDep.transceive(
              Uint8List.fromList(command),
            );

            if (response.length > 2) {
              var payload = response.sublist(0, response.length - 2);

              String jsonString = utf8.decode(payload);
              print("Sikeres vétel: $jsonString");
            } else {
              print("Túl rövid válasz érkezett. Kapott bájtok: $response");
            }

            NfcManager.instance.stopSession();
          } catch (e) {
            print("Hiba: $e");
            NfcManager.instance.stopSession();
          }
        } else {
          print("Nem megfelelő eszköz.");
          NfcManager.instance.stopSession();
        }
      },
    );
  }

  Widget ShowQrCode(BuildContext context, List<dynamic> workouts) {
    String jsonString = jsonEncode(workouts);

    return Center(
      child: QrImageView(
        data: jsonString,
        version: QrVersions.auto,
        size: MediaQuery.of(context).size.width * 0.5,
      ),
    );
  }

  void startScanning(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AiBarcodeScanner(
          onDetect: (BarcodeCapture capture) {
            String value = capture.barcodes.first.rawValue ?? "";

            if (value.startsWith("[")) {
              try {
                List<dynamic> decodedData = jsonDecode(value);
                List<MealDto> newWorkouts = decodedData
                    .map((item) => MealDto.fromJson(item))
                    .toList();

                Navigator.of(context).pop();

                setState(() {
                  userMeals.addAll(newWorkouts);
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "${newWorkouts.length} edzés sikeresen importálva!",
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                debugPrint("Hiba a JSON feldolgozásnál: $e");
              }
            } else {
              debugPrint("Ez nem edzés lista (nem '['-el kezdődik).");
            }
          },
          onDispose: () {
            debugPrint("Scanner bezárva");
          },
          controller: MobileScannerController(
            detectionSpeed: DetectionSpeed.noDuplicates,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, userMeals);
        return false;
      },
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(2, 6, 2, 0),
                  child: AppBar(
                    title: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              lang.getText("new_workout"),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        userMeals.isNotEmpty
                            ? Container(
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 85, 173, 78),
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: IconButton(
                                  onPressed: () async {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      elevation: 0,
                                      builder: (context) => StatefulBuilder(
                                        builder: (context, setPopupState) => Padding(
                                          padding: EdgeInsets.only(
                                            bottom: MediaQuery.of(
                                              context,
                                            ).viewInsets.bottom,
                                          ),
                                          child: Container(
                                            height:
                                                MediaQuery.of(
                                                  context,
                                                ).size.height *
                                                0.6,
                                            clipBehavior: Clip.hardEdge,
                                            decoration: const BoxDecoration(
                                              color: Color.fromARGB(
                                                255,
                                                35,
                                                35,
                                                35,
                                              ),
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                    top: Radius.circular(25),
                                                  ),
                                            ),
                                            child: Column(
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.all(
                                                    20,
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        lang.getText("share"),
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 24,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      IconButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                              context,
                                                            ),
                                                        icon: const Icon(
                                                          Icons.close,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Expanded(
                                                  child: DefaultTabController(
                                                    initialIndex: 0,
                                                    length: 2,
                                                    child: Column(
                                                      children: [
                                                        const TabBar(
                                                          labelColor:
                                                              Colors.white,
                                                          unselectedLabelColor:
                                                              Colors.grey,
                                                          indicatorColor:
                                                              Colors.green,
                                                          tabs: <Widget>[
                                                            Tab(text: "NFC"),
                                                            Tab(text: "QR"),
                                                          ],
                                                        ),
                                                        Expanded(
                                                          child: TabBarView(
                                                            children: <Widget>[
                                                              Center(
                                                                child: Column(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  children: [
                                                                    Container(
                                                                      decoration: BoxDecoration(
                                                                        color: const Color.fromARGB(
                                                                          255,
                                                                          85,
                                                                          173,
                                                                          78,
                                                                        ),
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              11,
                                                                            ),
                                                                      ),
                                                                      child: IconButton(
                                                                        onPressed: () {
                                                                          Navigator.pop(
                                                                            context,
                                                                          );
                                                                          showDialog(
                                                                            context:
                                                                                context,
                                                                            builder:
                                                                                (
                                                                                  context,
                                                                                ) {
                                                                                  return StatefulBuilder(
                                                                                    builder:
                                                                                        (
                                                                                          context,
                                                                                          setStateDialog,
                                                                                        ) {
                                                                                          return Dialog(
                                                                                            insetPadding: const EdgeInsets.all(
                                                                                              20,
                                                                                            ),
                                                                                            backgroundColor: const Color.fromARGB(
                                                                                              255,
                                                                                              30,
                                                                                              30,
                                                                                              30,
                                                                                            ),
                                                                                            shape: RoundedRectangleBorder(
                                                                                              borderRadius: BorderRadius.circular(
                                                                                                16,
                                                                                              ),
                                                                                            ),
                                                                                            child: Container(
                                                                                              width: double.infinity,
                                                                                              padding: const EdgeInsets.all(
                                                                                                16,
                                                                                              ),
                                                                                              decoration: BoxDecoration(
                                                                                                color: const Color.fromARGB(
                                                                                                  255,
                                                                                                  40,
                                                                                                  40,
                                                                                                  40,
                                                                                                ),
                                                                                                borderRadius: BorderRadius.circular(
                                                                                                  16,
                                                                                                ),
                                                                                                border: Border.all(
                                                                                                  color: Colors.white24,
                                                                                                ),
                                                                                              ),
                                                                                              child: Column(
                                                                                                mainAxisSize: MainAxisSize.min,
                                                                                                children: [
                                                                                                  Expanded(
                                                                                                    child: SingleChildScrollView(
                                                                                                      child: Column(
                                                                                                        mainAxisSize: MainAxisSize.min,
                                                                                                        children: [
                                                                                                          Text(
                                                                                                            lang.getText(
                                                                                                              "share_via_NFC",
                                                                                                            ),
                                                                                                            style: TextStyle(
                                                                                                              color: Colors.white,
                                                                                                              fontSize: 20,
                                                                                                              fontWeight: FontWeight.bold,
                                                                                                              decoration: TextDecoration.underline,
                                                                                                            ),
                                                                                                          ),
                                                                                                        ],
                                                                                                      ),
                                                                                                    ),
                                                                                                  ),
                                                                                                ],
                                                                                              ),
                                                                                            ),
                                                                                          );
                                                                                        },
                                                                                  );
                                                                                },
                                                                          );
                                                                          startNfcSharing(
                                                                            userMeals,
                                                                          );
                                                                        },
                                                                        icon: const Icon(
                                                                          Icons
                                                                              .nfc,
                                                                        ),
                                                                        color: Colors
                                                                            .white70,
                                                                        iconSize:
                                                                            MediaQuery.of(
                                                                              context,
                                                                            ).size.width *
                                                                            0.35,
                                                                      ),
                                                                    ),
                                                                    SizedBox(
                                                                      height:
                                                                          MediaQuery.of(
                                                                            context,
                                                                          ).size.height *
                                                                          0.03,
                                                                    ),
                                                                    Text(
                                                                      lang.getText(
                                                                        "or",
                                                                      ),
                                                                      style: TextStyle(
                                                                        color: Colors
                                                                            .white24,
                                                                        fontSize:
                                                                            20,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                      ),
                                                                    ),
                                                                    SizedBox(
                                                                      height:
                                                                          MediaQuery.of(
                                                                            context,
                                                                          ).size.height *
                                                                          0.03,
                                                                    ),
                                                                    FilledButton(
                                                                      style: FilledButton.styleFrom(
                                                                        backgroundColor: const Color.fromARGB(
                                                                          255,
                                                                          85,
                                                                          173,
                                                                          78,
                                                                        ),
                                                                        fixedSize: Size(
                                                                          MediaQuery.of(
                                                                                context,
                                                                              ).size.width *
                                                                              0.55,
                                                                          MediaQuery.of(
                                                                                context,
                                                                              ).size.height *
                                                                              0.07,
                                                                        ),
                                                                        shape: RoundedRectangleBorder(
                                                                          borderRadius: BorderRadius.circular(
                                                                            11,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      onPressed: () {
                                                                        Navigator.pop(
                                                                          context,
                                                                        );
                                                                        showDialog(
                                                                          context:
                                                                              context,
                                                                          builder:
                                                                              (
                                                                                context,
                                                                              ) {
                                                                                return StatefulBuilder(
                                                                                  builder:
                                                                                      (
                                                                                        context,
                                                                                        setStateDialog,
                                                                                      ) {
                                                                                        return Dialog(
                                                                                          insetPadding: const EdgeInsets.all(
                                                                                            20,
                                                                                          ),
                                                                                          backgroundColor: const Color.fromARGB(
                                                                                            255,
                                                                                            30,
                                                                                            30,
                                                                                            30,
                                                                                          ),
                                                                                          shape: RoundedRectangleBorder(
                                                                                            borderRadius: BorderRadius.circular(
                                                                                              16,
                                                                                            ),
                                                                                          ),
                                                                                          child: Container(
                                                                                            width: double.infinity,
                                                                                            padding: const EdgeInsets.all(
                                                                                              16,
                                                                                            ),
                                                                                            decoration: BoxDecoration(
                                                                                              color: const Color.fromARGB(
                                                                                                255,
                                                                                                40,
                                                                                                40,
                                                                                                40,
                                                                                              ),
                                                                                              borderRadius: BorderRadius.circular(
                                                                                                16,
                                                                                              ),
                                                                                              border: Border.all(
                                                                                                color: Colors.white24,
                                                                                              ),
                                                                                            ),
                                                                                            child: Column(
                                                                                              mainAxisSize: MainAxisSize.min,
                                                                                              children: [
                                                                                                Expanded(
                                                                                                  child: SingleChildScrollView(
                                                                                                    child: Column(
                                                                                                      mainAxisSize: MainAxisSize.min,
                                                                                                      children: [
                                                                                                        Text(
                                                                                                          lang.getText(
                                                                                                            "recive_workout",
                                                                                                          ),
                                                                                                          style: TextStyle(
                                                                                                            color: Colors.white,
                                                                                                            fontSize: 20,
                                                                                                            fontWeight: FontWeight.bold,
                                                                                                          ),
                                                                                                        ),
                                                                                                      ],
                                                                                                    ),
                                                                                                  ),
                                                                                                ),
                                                                                              ],
                                                                                            ),
                                                                                          ),
                                                                                        );
                                                                                      },
                                                                                );
                                                                              },
                                                                        );
                                                                        startNfcReceiving();
                                                                      },
                                                                      child: Text(
                                                                        lang.getText(
                                                                          "recive_workout",
                                                                        ),
                                                                        style: TextStyle(
                                                                          color:
                                                                              Colors.white,
                                                                          fontSize:
                                                                              20,
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),

                                                              Center(
                                                                child: Column(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  children: [
                                                                    Container(
                                                                      width:
                                                                          MediaQuery.of(
                                                                            context,
                                                                          ).size.width *
                                                                          0.5,
                                                                      decoration: BoxDecoration(
                                                                        color: const Color.fromARGB(
                                                                          255,
                                                                          85,
                                                                          173,
                                                                          78,
                                                                        ),
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              11,
                                                                            ),
                                                                      ),
                                                                      child: ShowQrCode(
                                                                        context,
                                                                        userMeals,
                                                                      ),
                                                                    ),
                                                                    SizedBox(
                                                                      height:
                                                                          MediaQuery.of(
                                                                            context,
                                                                          ).size.height *
                                                                          0.01,
                                                                    ),
                                                                    Text(
                                                                      lang.getText(
                                                                        "or",
                                                                      ),
                                                                      style: TextStyle(
                                                                        color: Colors
                                                                            .white24,
                                                                        fontSize:
                                                                            20,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                      ),
                                                                    ),
                                                                    SizedBox(
                                                                      height:
                                                                          MediaQuery.of(
                                                                            context,
                                                                          ).size.height *
                                                                          0.01,
                                                                    ),
                                                                    FilledButton(
                                                                      style: FilledButton.styleFrom(
                                                                        backgroundColor: const Color.fromARGB(
                                                                          255,
                                                                          85,
                                                                          173,
                                                                          78,
                                                                        ),
                                                                        fixedSize: Size(
                                                                          MediaQuery.of(
                                                                                context,
                                                                              ).size.width *
                                                                              0.55,
                                                                          MediaQuery.of(
                                                                                context,
                                                                              ).size.height *
                                                                              0.07,
                                                                        ),
                                                                        shape: RoundedRectangleBorder(
                                                                          borderRadius: BorderRadius.circular(
                                                                            11,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      onPressed: () {
                                                                        startScanning(
                                                                          context,
                                                                        );
                                                                      },
                                                                      child: Text(
                                                                        lang.getText(
                                                                          "scan",
                                                                        ),
                                                                        style: TextStyle(
                                                                          color:
                                                                              Colors.white,
                                                                          fontSize:
                                                                              20,
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
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
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    CupertinoIcons.share,
                                    size: 25,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : Container(),
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: Container(
                  margin: EdgeInsets.all(20),
                  width: double.infinity,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Stack(
                            children: [
                              FilledButton(
                                onPressed: () {
                                  setState(() {
                                    mealindex = 0;
                                  });
                                  mealtypecontroller.text =
                                      _mealtypes[mealindex];
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: mealindex == 0
                                      ? const Color.fromARGB(255, 85, 173, 78)
                                      : const Color.fromARGB(255, 45, 45, 45),
                                  fixedSize: Size(
                                    MediaQuery.of(context).size.width * 0.41,
                                    MediaQuery.of(context).size.height * 0.07,
                                  ),
                                  elevation: 8,
                                  // ignore: deprecated_member_use
                                  shadowColor: Colors.black.withOpacity(0.8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(11),
                                    side: const BorderSide(
                                      color: Colors.white24,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Text(lang.getText("breakfast")),
                              ),
                            ],
                          ),

                          SizedBox(width: 20),

                          Stack(
                            children: [
                              FilledButton(
                                onPressed: () {
                                  setState(() {
                                    mealindex = 1;
                                  });
                                  mealtypecontroller.text =
                                      _mealtypes[mealindex];
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: mealindex == 1
                                      ? const Color.fromARGB(255, 85, 173, 78)
                                      : const Color.fromARGB(255, 45, 45, 45),
                                  fixedSize: Size(
                                    MediaQuery.of(context).size.width * 0.41,
                                    MediaQuery.of(context).size.height * 0.07,
                                  ),
                                  elevation: 8,
                                  // ignore: deprecated_member_use
                                  shadowColor: Colors.black.withOpacity(0.8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(11),
                                    side: const BorderSide(
                                      color: Colors.white24,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Text(lang.getText("lunch")),
                              ),
                            ],
                          ),
                        ],
                      ),

                      SizedBox(height: 20),

                      Row(
                        children: [
                          Stack(
                            children: [
                              FilledButton(
                                onPressed: () {
                                  setState(() {
                                    mealindex = 2;
                                  });
                                  mealtypecontroller.text =
                                      _mealtypes[mealindex];
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: mealindex == 2
                                      ? const Color.fromARGB(255, 85, 173, 78)
                                      : const Color.fromARGB(255, 45, 45, 45),
                                  fixedSize: Size(
                                    MediaQuery.of(context).size.width * 0.41,
                                    MediaQuery.of(context).size.height * 0.07,
                                  ),
                                  elevation: 8,
                                  // ignore: deprecated_member_use
                                  shadowColor: Colors.black.withOpacity(0.8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(11),
                                    side: const BorderSide(
                                      color: Colors.white24,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Text(lang.getText("dinner")),
                              ),
                            ],
                          ),

                          SizedBox(width: 20),

                          Stack(
                            children: [
                              FilledButton(
                                onPressed: () {
                                  setState(() {
                                    mealindex = 3;
                                  });
                                  mealtypecontroller.text =
                                      _mealtypes[mealindex];
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: mealindex == 3
                                      ? const Color.fromARGB(255, 85, 173, 78)
                                      : const Color.fromARGB(255, 45, 45, 45),
                                  fixedSize: Size(
                                    MediaQuery.of(context).size.width * 0.41,
                                    MediaQuery.of(context).size.height * 0.07,
                                  ),
                                  elevation: 8,
                                  // ignore: deprecated_member_use
                                  shadowColor: Colors.black.withOpacity(0.8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(11),
                                    side: const BorderSide(
                                      color: Colors.white24,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Text(lang.getText("other")),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              Container(
                child: userMeals.isEmpty
                    ? Center(
                        child: Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                lang.getText("no_added_meal_yet"),
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: userMeals.length,
                        itemBuilder: (context, index) {
                          final meal = userMeals[index];
                          final cleanName = stripHtmlTags(meal.name);
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 6,
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 45, 45, 45),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white24),
                                  boxShadow: [
                                    BoxShadow(
                                      // ignore: deprecated_member_use
                                      color: Colors.black.withOpacity(0.5),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cleanName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${meal.qCalories} kcal | ${meal.qProtein.toStringAsFixed(3)} g ${lang.getText("protein")} | ${meal.qCarbs.toStringAsFixed(3)} g ${lang.getText("carbs")} | ${meal.qFat.toStringAsFixed(3)} g ${lang.getText("fat")} | ${meal.quantity.toStringAsFixed(0)} ${lang.getText("piece(s)")} | ${meal.baseWeight} ${meal.unit}',
                                              style: const TextStyle(
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Center(
                                        child: TextButton(
                                          onPressed: () => {
                                            setState(() {
                                              userMeals.remove(meal);
                                            }),
                                          },
                                          child: Text(
                                            lang.getText("delete"),
                                            style: TextStyle(
                                              color: Colors.redAccent,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),

              SizedBox(height: 20),

              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 45, 45, 45),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                      boxShadow: [
                        BoxShadow(
                          // ignore: deprecated_member_use
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Stack(
                              children: [
                                Text(
                                  '${lang.getText("calories")}: $userCaloriesSum kcal',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        Row(
                          children: [
                            Stack(
                              children: [
                                Text(
                                  '${lang.getText("protein")}: ${userProteinsSum.toStringAsFixed(3)} g',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        Row(
                          children: [
                            Stack(
                              children: [
                                Text(
                                  '${lang.getText("carbs")}: ${userCarbsSum.toStringAsFixed(3)} g',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        Row(
                          children: [
                            Stack(
                              children: [
                                Text(
                                  '${lang.getText("fat")}: ${userFatSum.toStringAsFixed(3)} g',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.006,
                    left: MediaQuery.of(context).size.width * 0.09,
                    child: Text(
                      lang.getText("summary"),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),

              Center(
                child: Text(
                  lang.getText("my_templates"),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              FutureBuilder<List<CustomUserMealDto>>(
                future: futureCustomMeals,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        "Hiba történt: ${snapshot.error}",
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  final meals = snapshot.data ?? [];

                  if (meals.isEmpty) {
                    return Center(
                      child: Text(
                        lang.getText("no_added_template_yet"),
                        style: TextStyle(color: Colors.white70, fontSize: 18),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: meals.length,
                    itemBuilder: (context, index) {
                      final meal = meals[index];

                      return GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return StatefulBuilder(
                                builder: (context, setStateDialog) {
                                  return Dialog(
                                    insetPadding: const EdgeInsets.all(20),
                                    backgroundColor: const Color.fromARGB(
                                      255,
                                      30,
                                      30,
                                      30,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(
                                          255,
                                          40,
                                          40,
                                          40,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.white24,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            meal.customName.isNotEmpty
                                                ? meal.customName
                                                : lang.getText(
                                                    "unknown_template",
                                                  ),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Flexible(
                                            child: ListView.builder(
                                              shrinkWrap: true,
                                              itemCount: meal.meals.length,
                                              itemBuilder: (context, i) {
                                                final item = meal.meals[i];
                                                final cleanName = stripHtmlTags(
                                                  item.name,
                                                );

                                                return Container(
                                                  width: double.infinity,
                                                  margin:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 3,
                                                        horizontal: 4,
                                                      ),
                                                  padding: const EdgeInsets.all(
                                                    12,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: const Color.fromARGB(
                                                      255,
                                                      30,
                                                      30,
                                                      30,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    border: Border.all(
                                                      color: Colors.white24,
                                                    ),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        "$cleanName (${item.quantity})",
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              '${item.qCalories.toStringAsFixed(3)} kcal',
                                                              style:
                                                                  const TextStyle(
                                                                    color: Colors
                                                                        .white70,
                                                                  ),
                                                            ),
                                                          ),
                                                          Expanded(
                                                            child: Text(
                                                              '${item.qProtein.toStringAsFixed(3)} g ${lang.getText("protein")}',
                                                              style:
                                                                  const TextStyle(
                                                                    color: Colors
                                                                        .white70,
                                                                  ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              '${item.qCarbs.toStringAsFixed(3)} g ${lang.getText("carbs")}',
                                                              style:
                                                                  const TextStyle(
                                                                    color: Colors
                                                                        .white70,
                                                                  ),
                                                            ),
                                                          ),
                                                          Expanded(
                                                            child: Text(
                                                              '${item.qFat.toStringAsFixed(3)} g ${lang.getText("fat")}',
                                                              style:
                                                                  const TextStyle(
                                                                    color: Colors
                                                                        .white70,
                                                                  ),
                                                            ),
                                                          ),
                                                          showdelete
                                                              ? Padding(
                                                                  padding:
                                                                      EdgeInsets.only(
                                                                        right:
                                                                            10,
                                                                      ),
                                                                  child: IconButton(
                                                                    onPressed: () async {
                                                                      final itemToDelete =
                                                                          meal.meals[i];
                                                                      final ok = await deleteMealFromTemplate(
                                                                        itemToDelete
                                                                            .Id!,
                                                                      );

                                                                      if (ok) {
                                                                        setStateDialog(() {
                                                                          meal.meals.removeWhere(
                                                                            (
                                                                              m,
                                                                            ) =>
                                                                                m.Id ==
                                                                                itemToDelete.Id,
                                                                          );
                                                                        });
                                                                        ScaffoldMessenger.of(
                                                                          context,
                                                                        ).showSnackBar(
                                                                          SnackBar(
                                                                            content: Text(
                                                                              lang.getText(
                                                                                "meal_deleted",
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        );
                                                                      } else {
                                                                        ScaffoldMessenger.of(
                                                                          context,
                                                                        ).showSnackBar(
                                                                          SnackBar(
                                                                            content: Text(
                                                                              lang.getText(
                                                                                "deletion_failed",
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        );
                                                                      }
                                                                    },

                                                                    icon: Icon(
                                                                      CupertinoIcons
                                                                          .trash,
                                                                      color: Colors
                                                                          .red,
                                                                    ),
                                                                  ),
                                                                )
                                                              : Container(),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          const SizedBox(height: 10),

                                          Center(
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.white,
                                                foregroundColor: Colors.black,
                                              ),
                                              onPressed: () async {
                                                try {
                                                  final prefs =
                                                      await SharedPreferences.getInstance();
                                                  print(prefs);
                                                  final userId = prefs.getInt(
                                                    'userId',
                                                  );
                                                  if (userId == null) {
                                                    throw Exception(
                                                      lang.getText("no_userId"),
                                                    );
                                                  }

                                                  await saveTemplateAsUserMeal(
                                                    meal,
                                                    userId,
                                                  );

                                                  ScaffoldMessenger.of(
                                                    // ignore: use_build_context_synchronously
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        lang.getText(
                                                          "saved_successfully",
                                                        ),
                                                      ),
                                                      behavior: SnackBarBehavior
                                                          .floating,
                                                      margin: EdgeInsets.only(
                                                        bottom: 30,
                                                        left: 16,
                                                        right: 16,
                                                      ),
                                                      duration: Duration(
                                                        milliseconds: 1800,
                                                      ),
                                                      animation: CurvedAnimation(
                                                        parent:
                                                            kAlwaysCompleteAnimation,
                                                        curve: Curves.easeInOut,
                                                      ),
                                                    ),
                                                  );
                                                } catch (e) {
                                                  ScaffoldMessenger.of(
                                                    // ignore: use_build_context_synchronously
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text("Hiba: $e"),
                                                      behavior: SnackBarBehavior
                                                          .floating,
                                                      margin: EdgeInsets.only(
                                                        bottom: 30,
                                                        left: 16,
                                                        right: 16,
                                                      ),
                                                      duration: Duration(
                                                        milliseconds: 1800,
                                                      ),
                                                      animation: CurvedAnimation(
                                                        parent:
                                                            kAlwaysCompleteAnimation,
                                                        curve: Curves.easeInOut,
                                                      ),
                                                    ),
                                                  );
                                                }
                                                if (_debounce?.isActive ??
                                                    false) {
                                                  _debounce!.cancel();
                                                }
                                                _debounce = Timer(
                                                  const Duration(
                                                    milliseconds: 1500,
                                                  ),
                                                  () {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).hideCurrentSnackBar();
                                                    Navigator.push<
                                                      List<MealDto>
                                                    >(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            const Pages(),
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                              child: Text(
                                                lang.getText("save_as_meal"),
                                              ),
                                            ),
                                          ),
                                          Center(
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.white,
                                                foregroundColor: Colors.black,
                                              ),
                                              onPressed: () async {
                                                setStateDialog(() {
                                                  showdelete = true;
                                                });
                                              },
                                              child: Text(lang.getText("edit")),
                                            ),
                                          ),
                                          Center(
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.white,
                                                foregroundColor: Colors.black,
                                              ),
                                              onPressed: () async {
                                                final result =
                                                    await Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            AddMealPage(
                                                              addToTemplate:
                                                                  true,
                                                              templateId:
                                                                  meal.id,
                                                            ),
                                                      ),
                                                    );

                                                if (result != null &&
                                                    result is List<MealDto> &&
                                                    result.isNotEmpty) {
                                                  setStateDialog(() {
                                                    meal.meals.addAll(result);
                                                  });
                                                }
                                              },
                                              child: Text(lang.getText("add")),
                                            ),
                                          ),
                                          Center(
                                            child: ElevatedButton(
                                              onPressed: () {
                                                setState(() {
                                                  userMeals.addAll(meal.meals);
                                                });
                                                Navigator.pop(context);
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      "${meal.customName} ${lang.getText("added_to_list")}",
                                                    ),
                                                    duration: const Duration(
                                                      milliseconds: 1500,
                                                    ),
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                  ),
                                                );
                                              },
                                              style: FilledButton.styleFrom(
                                                backgroundColor:
                                                    const Color.fromARGB(
                                                      255,
                                                      30,
                                                      30,
                                                      30,
                                                    ),
                                                side: const BorderSide(
                                                  color: Colors.white24,
                                                  width: 1,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                              child: Text(
                                                lang.getText("continue_meal"),
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                          setState(() {
                            showdelete = false;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 6,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 45, 45, 45),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    meal.customName.isNotEmpty
                                        ? meal.customName
                                        : lang.getText("unknown_template"),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${meal.totalCalories} kcal | ${meal.totalProtein.toStringAsFixed(3)} g ${lang.getText("protein")} | ${meal.totalCarbs.toStringAsFixed(3)} g ${lang.getText("carbs")} | ${meal.totalFat.toStringAsFixed(3)} g ${lang.getText("fat")}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.redAccent,
                                        ),
                                        onPressed: () async {
                                          final confirmed = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => Dialog(
                                              backgroundColor:
                                                  const Color.fromARGB(
                                                    255,
                                                    30,
                                                    30,
                                                    30,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                side: const BorderSide(
                                                  color: Colors.white24,
                                                ),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  20,
                                                ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      lang.getText("delete"),
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 22,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 16),
                                                    Text(
                                                      "${lang.getText("sure_delete_template")}\n'${meal.customName}'?",
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: const TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 24),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceEvenly,
                                                      children: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                context,
                                                                false,
                                                              ),
                                                          style:
                                                              TextButton.styleFrom(
                                                                foregroundColor:
                                                                    Colors
                                                                        .white54,
                                                              ),
                                                          child: Text(
                                                            lang.getText(
                                                              "cancel",
                                                            ),
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                          ),
                                                        ),
                                                        FilledButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                context,
                                                                true,
                                                              ),
                                                          style: FilledButton.styleFrom(
                                                            backgroundColor:
                                                                Colors
                                                                    .redAccent,
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    12,
                                                                  ),
                                                            ),
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      20,
                                                                  vertical: 10,
                                                                ),
                                                          ),
                                                          child: Text(
                                                            lang.getText(
                                                              "delete",
                                                            ),
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 16,
                                                                ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );

                                          if (confirmed == true) {
                                            final success =
                                                await deleteUserMealTemplate(
                                                  meal.id,
                                                );

                                            if (success) {
                                              setState(() {
                                                meals.removeAt(index);
                                              });

                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      lang.getText(
                                                        "deleted_successfully",
                                                      ),
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    showCloseIcon: true,
                                                    closeIconColor:
                                                        Colors.white70,
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                    backgroundColor:
                                                        const Color.fromARGB(
                                                          255,
                                                          45,
                                                          45,
                                                          45,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      side: const BorderSide(
                                                        color: Colors.white24,
                                                        width: 1,
                                                      ),
                                                    ),
                                                    margin:
                                                        const EdgeInsets.only(
                                                          bottom: 30,
                                                          left: 16,
                                                          right: 16,
                                                        ),
                                                    duration: const Duration(
                                                      milliseconds: 1800,
                                                    ),
                                                    animation: CurvedAnimation(
                                                      parent:
                                                          kAlwaysCompleteAnimation,
                                                      curve: Curves.easeInOut,
                                                    ),
                                                  ),
                                                );
                                              }
                                            }
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
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
                  final result = await Navigator.push<List<MealDto>>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddMealPage(),
                    ),
                  );

                  if (result != null) {
                    setState(() {
                      userMeals.addAll(result);
                    });
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 85, 173, 78),
                  fixedSize: Size(
                    MediaQuery.of(context).size.width * 0.41,
                    MediaQuery.of(context).size.height * 0.07,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                child: Text(
                  lang.getText("add"),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              FilledButton(
                onPressed: () async {
                  if (userMeals.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(lang.getText("no_meals_selected")),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return Dialog(
                        insetPadding: const EdgeInsets.all(20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 40, 40, 40),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  lang.getText("save_sample"),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Stack(
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      height: null,
                                      margin: const EdgeInsets.fromLTRB(
                                        0,
                                        20,
                                        0,
                                        20,
                                      ),
                                      padding: const EdgeInsets.fromLTRB(
                                        0,
                                        0,
                                        5,
                                        5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(
                                          255,
                                          72,
                                          72,
                                          72,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: TextField(
                                        cursorColor: Colors.white,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                        ),
                                        controller: mealnamecontroller,
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: Colors.transparent,
                                              width: 2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: Colors.transparent,
                                              width: 1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        keyboardType: TextInputType.text,
                                      ),
                                    ),

                                    Positioned(
                                      top:
                                          MediaQuery.of(context).size.height *
                                          0.01,
                                      left:
                                          MediaQuery.of(context).size.width *
                                          0.04,
                                      child: Text(
                                        lang.getText("sample_name"),
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    FilledButton(
                                      onPressed: () async {
                                        try {
                                          final prefs =
                                              await SharedPreferences.getInstance();
                                          final userId = prefs.getInt('userId');
                                          if (userId == null) {
                                            throw Exception(
                                              lang.getText("no_userId_found"),
                                            );
                                          }

                                          await saveUserMeals(
                                            userMeals,
                                            _mealtypes[mealindex],
                                            userId,
                                          );

                                          ScaffoldMessenger.of(
                                            // ignore: use_build_context_synchronously
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                lang.getText(
                                                  "saved_successfully",
                                                ),
                                              ),
                                              showCloseIcon: true,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              margin: EdgeInsets.only(
                                                bottom: 30,
                                                left: 16,
                                                right: 16,
                                              ),
                                              duration: Duration(
                                                milliseconds: 1800,
                                              ),
                                              animation: CurvedAnimation(
                                                parent:
                                                    kAlwaysCompleteAnimation,
                                                curve: Curves.easeInOut,
                                              ),
                                            ),
                                          );
                                        } catch (e) {
                                          ScaffoldMessenger.of(
                                            // ignore: use_build_context_synchronously
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text("Hiba: $e"),
                                              backgroundColor: Colors.red,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              margin: EdgeInsets.only(
                                                bottom: 30,
                                                left: 16,
                                                right: 16,
                                              ),
                                              duration: Duration(
                                                milliseconds: 1800,
                                              ),
                                              animation: CurvedAnimation(
                                                parent:
                                                    kAlwaysCompleteAnimation,
                                                curve: Curves.easeInOut,
                                              ),
                                            ),
                                          );
                                          return;
                                        }
                                        if (_debounce?.isActive ?? false) {
                                          _debounce!.cancel();
                                        }
                                        _debounce = Timer(
                                          const Duration(milliseconds: 1500),
                                          () {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).hideCurrentSnackBar();
                                            Navigator.push<List<MealDto>>(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const Pages(),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                      style: FilledButton.styleFrom(
                                        backgroundColor: const Color.fromARGB(
                                          255,
                                          85,
                                          173,
                                          78,
                                        ),
                                        fixedSize: Size(
                                          MediaQuery.of(context).size.width *
                                              0.36,
                                          MediaQuery.of(context).size.height *
                                              0.07,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            11,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                        ),
                                      ),
                                      child: Text(
                                        lang.getText("save_without_sample"),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),

                                    FilledButton(
                                      onPressed: () async {
                                        if (mealnamecontroller.text
                                            .trim()
                                            .isEmpty) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                lang.getText(
                                                  "name_the_template",
                                                ),
                                              ),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          return;
                                        }

                                        final existingTemplates =
                                            await futureCustomMeals;
                                        final newName = mealnamecontroller.text
                                            .trim();

                                        final bool isDuplicate =
                                            existingTemplates.any(
                                              (template) =>
                                                  template.customName
                                                      .trim()
                                                      .toLowerCase() ==
                                                  newName.toLowerCase(),
                                            );

                                        if (isDuplicate) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                lang.getText(
                                                  'duplicate_template',
                                                ),
                                              ),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          return;
                                        }

                                        try {
                                          final prefs =
                                              await SharedPreferences.getInstance();
                                          final userId = prefs.getInt('userId');
                                          if (userId == null) {
                                            throw Exception(
                                              lang.getText("no_userId_found"),
                                            );
                                          }

                                          await saveUserMealsS(
                                            userMeals,
                                            mealnamecontroller.text,
                                            userId,
                                          );

                                          ScaffoldMessenger.of(
                                            // ignore: use_build_context_synchronously
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                lang.getText(
                                                  "saved_successfully",
                                                ),
                                              ),
                                              showCloseIcon: true,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              margin: EdgeInsets.only(
                                                bottom: 30,
                                                left: 16,
                                                right: 16,
                                              ),
                                              duration: Duration(
                                                milliseconds: 1800,
                                              ),
                                              animation: CurvedAnimation(
                                                parent:
                                                    kAlwaysCompleteAnimation,
                                                curve: Curves.easeInOut,
                                              ),
                                            ),
                                          );
                                        } catch (e) {
                                          ScaffoldMessenger.of(
                                            // ignore: use_build_context_synchronously
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text("Hiba: $e"),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              margin: EdgeInsets.only(
                                                bottom: 30,
                                                left: 16,
                                                right: 16,
                                              ),
                                              duration: Duration(
                                                milliseconds: 1800,
                                              ),
                                              animation: CurvedAnimation(
                                                parent:
                                                    kAlwaysCompleteAnimation,
                                                curve: Curves.easeInOut,
                                              ),
                                            ),
                                          );
                                          return;
                                        }
                                        if (_debounce?.isActive ?? false) {
                                          _debounce!.cancel();
                                        }
                                        _debounce = Timer(
                                          const Duration(milliseconds: 1500),
                                          () {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).hideCurrentSnackBar();
                                            Navigator.push<List<MealDto>>(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const Pages(),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                      style: FilledButton.styleFrom(
                                        backgroundColor: const Color.fromARGB(
                                          255,
                                          85,
                                          173,
                                          78,
                                        ),
                                        fixedSize: Size(
                                          MediaQuery.of(context).size.width *
                                              0.36,
                                          MediaQuery.of(context).size.height *
                                              0.07,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            11,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        lang.getText("save"),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 85, 173, 78),
                  fixedSize: Size(
                    MediaQuery.of(context).size.width * 0.41,
                    MediaQuery.of(context).size.height * 0.07,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                child: Text(
                  lang.getText("continue"),
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
      ),
    );
  }
}
