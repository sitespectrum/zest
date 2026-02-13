import 'dart:typed_data';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ai_barcode_scanner/ai_barcode_scanner.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nfc_host_card_emulation/nfc_host_card_emulation.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:client/providers/language_provider.dart';
import 'add_meal_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:client/models/meal.dart';
import 'dart:async';
import 'package:client/pages.dart';
import 'package:client/constants.dart';
import 'package:client/components/ui/custom_card.dart';
import 'package:client/components/ui/custom_button.dart';
import 'package:client/components/ui/custom_drawer.dart';
import 'package:client/components/ui/custom_selector_button.dart';

class CMealPage extends StatefulWidget {
  final DateTime selectedDay;
  const CMealPage({super.key, required this.selectedDay});

  @override
  State<CMealPage> createState() => _CMealPageState();
}

final mealtypecontroller = TextEditingController();
final mealnamecontroller = TextEditingController();

class _CMealPageState extends State<CMealPage> {
  String _nfcData = 'No data';
  bool isNfcActive = false;
  String nfcStatus = "";
  String _statusText = "";
  bool _isNfcReading = false;
  String shareId = "";
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

  Future<void> startCloudNfcSharing(BuildContext context) async {
    String? id = await _uploadWorkoutToBackend();

    if (id == null) return;

    setState(() {
      isNfcActive = true;
      nfcStatus = "Megosztás indítása... (Kód: $id)";
    });

    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    if (statuses.values.any((status) => status.isDenied)) {
      setState(() => nfcStatus = "Hiányzó Bluetooth engedélyek!");
      return;
    }

    try {
      final blePeripheral = FlutterBlePeripheral();
      await blePeripheral.stop();

      final AdvertiseData advertiseData = AdvertiseData(
        includeDeviceName: false,
        manufacturerId: 0xFFFF,
        manufacturerData: Uint8List.fromList(utf8.encode(id)),
        serviceUuid: 'bf27cf98-eda3-4875-99a3-537446d7e003',
      );

      await blePeripheral.start(advertiseData: advertiseData);

      await NfcHce.removeApduResponse(0);
      await NfcHce.addApduResponse(0, [0x90, 0x00]);

      await NfcHce.init(
        aid: Uint8List.fromList([0xA0, 0x00, 0x00, 0x00, 0x04, 0x10, 0x10]),
        permanentApduResponses: true,
        listenOnlyConfiguredPorts: false,
      );

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: const Color.fromARGB(255, 30, 30, 30),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.nfc, size: 80, color: Colors.green),
                const SizedBox(height: 20),
                const Text(
                  "NFC és Bluetooth Aktív",
                  style: TextStyle(color: Colors.white),
                ),
                Text("ID: $id", style: const TextStyle(color: Colors.grey)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  stopNfcSharing();
                  Navigator.pop(context);
                },
                child: const Text(
                  "Bezárás",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      _showError("Hiba: $e");
    }
  }

  void stopNfcSharing() async {
    await NfcHce.removeApduResponse(0);
    final blePeripheral = FlutterBlePeripheral();
    await blePeripheral.stop();
    print("Megosztás (NFC + BLE) leállítva.");
  }

  Future<void> _fetchAndShowSharedWorkout(String shareId) async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    setState(() {
      _statusText = "Edzés betöltése...";
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      final response = await http.get(
        Uri.parse("$apiUrl/api/Share/workout-$shareId"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        List<dynamic> decodedData = jsonDecode(response.body);
        List<MealDto> newWorkouts = decodedData
            .map((item) => MealDto.fromJson(item))
            .toList();

        if (mounted) {
          setState(() {
            userMeals.addAll(newWorkouts);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "${newWorkouts.length} ${lang.getText("added_to_list")}",
              ),
              backgroundColor: Colors.green,
            ),
          );
        }

        int addedCount = 0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$addedCount gyakorlat hozzáadva a listához!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        await Future.delayed(Duration(milliseconds: 800));

        if (!mounted) return;

        Navigator.pop(context);
      }
    } catch (e) {
      _showError("Hiba az edzés betöltésekor: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isNfcReading = false;
          _statusText = "";
        });
      }
    }
  }

  Future<void> startNfcReceivingCloud() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    if (statuses.values.any((status) => status.isDenied)) {
      _showError("Hiányzó Bluetooth engedélyek!");
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const AlertDialog(
        backgroundColor: Color.fromARGB(255, 30, 30, 30),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.nfc, size: 60, color: Colors.white),
            SizedBox(height: 20),
            Text(
              "Érintsd a másik telefonhoz...",
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );

    try {
      await FlutterNfcKit.poll(
        timeout: Duration(seconds: 30),
        iosMultipleTagMessage: "Több címke",
        iosAlertMessage: "Érintsd oda",
      );

      await FlutterNfcKit.finish();

      if (mounted) Navigator.pop(context);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const AlertDialog(
          backgroundColor: Color.fromARGB(255, 30, 30, 30),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text(
                "Adatok fogadása Bluetooth-on...",
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );

      bool found = false;

      await FlutterBluePlus.startScan(
        timeout: Duration(seconds: 8),
        withServices: [Guid("bf27cf98-eda3-4875-99a3-537446d7e003")],
      );

      var subscription = FlutterBluePlus.scanResults.listen((results) async {
        for (ScanResult r in results) {
          final manufacturerData = r.advertisementData.manufacturerData;

          if (manufacturerData.containsKey(0xFFFF)) {
            try {
              String id = utf8.decode(manufacturerData[0xFFFF]!);
              print(">>> MEGVAN AZ ID BLUETOOTH-ON: $id");

              if (!found) {
                found = true;
                FlutterBluePlus.stopScan();

                if (mounted) Navigator.pop(context);

                await _fetchAndShowSharedWorkout(id);
              }
              return;
            } catch (e) {
              print("Dekódolási hiba: $e");
            }
          }
        }
      });

      await Future.delayed(Duration(seconds: 8));

      if (FlutterBluePlus.isScanningNow) {
        await FlutterBluePlus.stopScan();
      }
      subscription.cancel();

      if (!found) {
        if (mounted) Navigator.pop(context);
        _showError("Nem sikerült azonosítani a telefont.");
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);

      if (!e.toString().contains("poll timeout")) {
        _showError("Hiba: $e");
      }
    }
  }

  @override
  void dispose() {
    FlutterBlePeripheral().stop();
    super.dispose();
  }

  Future<String?> _uploadWorkoutToBackend() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      List<Map<String, dynamic>> jsonList = userMeals
          .map((e) => e.toJson())
          .toList();

      final response = await http.post(
        Uri.parse("$apiUrl/api/Share/uploadWorkout"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(jsonList),
      );

      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        String newId = responseData['shareId'].toString();
        print(">>> SZERVERRŐL KAPOTT ID: $newId");

        setState(() {
          shareId = newId;
        });

        return newId;
      } else {
        throw Exception("Szerver hiba: ${response.statusCode}");
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      _showError("Feltöltési hiba: $e");
      return null;
    }
  }

  Future<void> _generateQrCodeOnly() async {
    String? id = await _uploadWorkoutToBackend();

    if (id != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("QR kód legenerálva!"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void startScanning(BuildContext context) async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AiBarcodeScanner(
          onDetect: (BarcodeCapture capture) async {
            String scannedValue = capture.barcodes.first.rawValue ?? "";

            if (scannedValue.isEmpty) return;

            Navigator.of(context).pop();

            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (c) => const Center(child: CircularProgressIndicator()),
            );

            try {
              List<MealDto> newMeals = [];

              if (scannedValue.startsWith("[")) {
                List<dynamic> decodedData = jsonDecode(scannedValue);
                newMeals = decodedData
                    .map((item) => MealDto.fromJson(item))
                    .toList();
              } else {
                final response = await http.get(
                  Uri.parse("$apiUrl/api/Share/workout-$scannedValue"),
                );

                if (response.statusCode == 200) {
                  List<dynamic> decodedData = jsonDecode(response.body);
                  newMeals = decodedData
                      .map((item) => MealDto.fromJson(item))
                      .toList();
                } else {
                  throw Exception("Nem található vagy lejárt megosztás.");
                }
              }

              Navigator.pop(context);

              setState(() {
                userMeals.addAll(newMeals);
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "${newMeals.length} ${lang.getText("added_to_list")}",
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            } catch (e) {
              Navigator.pop(context);
              debugPrint("Hiba az importálásnál: $e");
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Hiba: ${e.toString()}"),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          controller: MobileScannerController(
            detectionSpeed: DetectionSpeed.noDuplicates,
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
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
                              lang.getText("new_meal"),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 85, 173, 78),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: IconButton(
                            onPressed: () async {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                elevation: 0,
                                backgroundColor: Colors.transparent,
                                builder: (context) => StatefulBuilder(
                                  builder: (context, setPopupState) => Container(
                                    decoration: const BoxDecoration(
                                      color: Color.fromARGB(255, 30, 30, 30),
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(24),
                                      ),
                                    ),
                                    child: CustomDrawer(
                                      child: Padding(
                                        padding: const EdgeInsets.all(
                                          24,
                                        ).copyWith(top: 16, left: 0, right: 0),
                                        child: SizedBox(
                                          height:
                                              MediaQuery.of(
                                                context,
                                              ).size.height *
                                              0.5,
                                          child: Column(
                                            spacing: 12,
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 24,
                                                    ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      lang.getText("share"),
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 24,
                                                        fontWeight:
                                                            FontWeight.bold,
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
                                                      // Tabfül stílus az edzés oldalról
                                                      Container(
                                                        margin:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 24,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color:
                                                              const Color.fromARGB(
                                                                50,
                                                                64,
                                                                255,
                                                                50,
                                                              ),
                                                          border: Border.all(
                                                            color:
                                                                const Color.fromARGB(
                                                                  100,
                                                                  64,
                                                                  255,
                                                                  50,
                                                                ),
                                                            width: 1,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                20,
                                                              ),
                                                        ),
                                                        child: TabBar(
                                                          labelStyle:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                          splashFactory: NoSplash
                                                              .splashFactory,
                                                          indicator: BoxDecoration(
                                                            color:
                                                                const Color.fromARGB(
                                                                  100,
                                                                  64,
                                                                  255,
                                                                  50,
                                                                ),
                                                            shape: BoxShape
                                                                .rectangle,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  16,
                                                                ),
                                                          ),
                                                          indicatorSize:
                                                              TabBarIndicatorSize
                                                                  .tab,
                                                          indicatorPadding:
                                                              const EdgeInsets.all(
                                                                4,
                                                              ),
                                                          dividerHeight: 0,
                                                          labelColor:
                                                              Colors.white,
                                                          unselectedLabelColor:
                                                              Colors.grey,
                                                          indicatorColor:
                                                              Colors.green,
                                                          tabs: const [
                                                            Tab(text: "NFC"),
                                                            Tab(text: "QR"),
                                                          ],
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets.only(
                                                                top: 24,
                                                              ),
                                                          child: TabBarView(
                                                            children: [
                                                              // NFC TAB TARTALMA
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          24,
                                                                    ),
                                                                child: Column(
                                                                  spacing: 12,
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .spaceBetween,
                                                                  children: [
                                                                    Expanded(
                                                                      child: Container(
                                                                        width: double
                                                                            .infinity,
                                                                        decoration: BoxDecoration(
                                                                          borderRadius: BorderRadius.circular(
                                                                            16,
                                                                          ),
                                                                        ),
                                                                        child: IconButton(
                                                                          style: IconButton.styleFrom(
                                                                            shape: RoundedRectangleBorder(
                                                                              borderRadius: BorderRadius.circular(
                                                                                16,
                                                                              ),
                                                                            ),
                                                                            backgroundColor: const Color.fromARGB(
                                                                              65,
                                                                              50,
                                                                              142,
                                                                              255,
                                                                            ),
                                                                            side: const BorderSide(
                                                                              color: Color.fromARGB(
                                                                                100,
                                                                                50,
                                                                                142,
                                                                                255,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          onPressed: () {
                                                                            startCloudNfcSharing(
                                                                              context,
                                                                            );
                                                                          },
                                                                          icon: const Icon(
                                                                            Icons.contactless_rounded,
                                                                          ),
                                                                          color:
                                                                              Colors.white70,
                                                                          iconSize:
                                                                              MediaQuery.of(
                                                                                context,
                                                                              ).size.width *
                                                                              0.35,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    // "VAGY" elválasztó
                                                                    Flex(
                                                                      direction:
                                                                          Axis.horizontal,
                                                                      spacing:
                                                                          12,
                                                                      children: [
                                                                        Expanded(
                                                                          child: Container(
                                                                            height:
                                                                                2,
                                                                            color:
                                                                                Colors.white38,
                                                                          ),
                                                                        ),
                                                                        Text(
                                                                          lang.getText(
                                                                            "or",
                                                                          ),
                                                                          style: const TextStyle(
                                                                            color:
                                                                                Colors.white38,
                                                                            fontSize:
                                                                                16,
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                          ),
                                                                        ),
                                                                        Expanded(
                                                                          child: Container(
                                                                            height:
                                                                                2,
                                                                            color:
                                                                                Colors.white38,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    CustomButton(
                                                                      onPressed:
                                                                          () {
                                                                            startNfcReceivingCloud();
                                                                          },
                                                                      title: lang.getText(
                                                                        "recive_workout",
                                                                      ), // Lehet, hogy "recive_meal"-re kellene javítani a lang fájlban ha van
                                                                      iconData:
                                                                          Icons
                                                                              .call_received_rounded,
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              // QR TAB TARTALMA
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          24,
                                                                    ),
                                                                child: Column(
                                                                  spacing: 24,
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .spaceBetween,
                                                                  children: [
                                                                    Expanded(
                                                                      child: Container(
                                                                        width: double
                                                                            .infinity,
                                                                        alignment:
                                                                            Alignment.center,
                                                                        padding:
                                                                            const EdgeInsets.all(
                                                                              12,
                                                                            ),
                                                                        decoration: BoxDecoration(
                                                                          color: Colors
                                                                              .white
                                                                              .withAlpha(
                                                                                25,
                                                                              ),
                                                                          borderRadius: BorderRadius.circular(
                                                                            16,
                                                                          ),
                                                                          border: Border.all(
                                                                            color: Colors.white.withAlpha(
                                                                              50,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        child:
                                                                            shareId.isNotEmpty
                                                                            ? QrImageView(
                                                                                data: shareId,
                                                                                version: QrVersions.auto,
                                                                                dataModuleStyle: const QrDataModuleStyle(
                                                                                  color: Colors.white,
                                                                                  dataModuleShape: QrDataModuleShape.square,
                                                                                ),
                                                                                eyeStyle: const QrEyeStyle(
                                                                                  color: Colors.white,
                                                                                  eyeShape: QrEyeShape.square,
                                                                                ),
                                                                              )
                                                                            : const Column(
                                                                                spacing: 12,
                                                                                mainAxisSize: MainAxisSize.min,
                                                                                children: [
                                                                                  Icon(
                                                                                    Icons.qr_code,
                                                                                    size: 96,
                                                                                    color: Colors.white38,
                                                                                  ),
                                                                                  Text(
                                                                                    "Még nincs QR kód",
                                                                                    style: TextStyle(
                                                                                      color: Colors.white38,
                                                                                      fontSize: 20,
                                                                                    ),
                                                                                    textAlign: TextAlign.center,
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                      ),
                                                                    ),
                                                                    Flex(
                                                                      direction:
                                                                          Axis.horizontal,
                                                                      spacing:
                                                                          12,
                                                                      children: [
                                                                        CustomButton(
                                                                          onPressed: () async {
                                                                            await _generateQrCodeOnly(); // Itt lehet kell kis módosítás, mert a workout page visszatér ID-val, itt void volt
                                                                            // A _generateQrCodeOnly függvényt érdemes módosítani, hogy visszaadja az ID-t, vagy itt a shareId-t frissíteni setState-el
                                                                          },
                                                                          variant:
                                                                              CustomButtonVariant.secondary,
                                                                          child: const Padding(
                                                                            padding: EdgeInsets.symmetric(
                                                                              vertical: 2.5,
                                                                            ),
                                                                            child: Icon(
                                                                              Icons.refresh_rounded,
                                                                              color: Colors.white,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        Expanded(
                                                                          child: CustomButton(
                                                                            onPressed: () {
                                                                              startScanning(
                                                                                context,
                                                                              );
                                                                            },
                                                                            title:
                                                                                "Scan QR code",
                                                                            iconData:
                                                                                Icons.qr_code_scanner_rounded,
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
                        ),
                      ],
                    ),
                    iconTheme: const IconThemeData(color: Colors.white),
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
                    Row(
                      children: [
                        CustomSelectorButton(
                          title: lang.getText("breakfast"),
                          isSelected: mealindex == 0,
                          onPressed: () {
                            setState(() {
                              mealindex = 0;
                            });
                            mealtypecontroller.text = _mealtypes[mealindex];
                          },
                        ),
                        const SizedBox(width: 12),
                        CustomSelectorButton(
                          title: lang.getText("lunch"),
                          isSelected: mealindex == 1,
                          onPressed: () {
                            setState(() {
                              mealindex = 1;
                            });
                            mealtypecontroller.text = _mealtypes[mealindex];
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CustomSelectorButton(
                          title: lang.getText("dinner"),
                          isSelected: mealindex == 2,
                          onPressed: () {
                            setState(() {
                              mealindex = 2;
                            });
                            mealtypecontroller.text = _mealtypes[mealindex];
                          },
                        ),
                        const SizedBox(width: 12),
                        CustomSelectorButton(
                          title: lang.getText("other"),
                          isSelected: mealindex == 3,
                          onPressed: () {
                            setState(() {
                              mealindex = 3;
                            });
                            mealtypecontroller.text = _mealtypes[mealindex];
                          },
                        ),
                      ],
                    ),
                  ],
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

              CustomCard(
                title: lang.getText("my_templates"),
                iconData: Icons.folder_copy_outlined,
                child: FutureBuilder<List<CustomUserMealDto>>(
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
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            lang.getText("no_added_template_yet"),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
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
                                                  final cleanName =
                                                      stripHtmlTags(item.name);

                                                  return Container(
                                                    width: double.infinity,
                                                    margin:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 3,
                                                          horizontal: 4,
                                                        ),
                                                    padding:
                                                        const EdgeInsets.all(
                                                          12,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          const Color.fromARGB(
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
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          height: 6,
                                                        ),
                                                        Row(
                                                          children: [
                                                            Expanded(
                                                              child: Text(
                                                                '${item.qCalories.toStringAsFixed(3)} kcal',
                                                                style: const TextStyle(
                                                                  color: Colors
                                                                      .white70,
                                                                ),
                                                              ),
                                                            ),
                                                            Expanded(
                                                              child: Text(
                                                                '${item.qProtein.toStringAsFixed(3)} g ${lang.getText("protein")}',
                                                                style: const TextStyle(
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
                                                                style: const TextStyle(
                                                                  color: Colors
                                                                      .white70,
                                                                ),
                                                              ),
                                                            ),
                                                            Expanded(
                                                              child: Text(
                                                                '${item.qFat.toStringAsFixed(3)} g ${lang.getText("fat")}',
                                                                style: const TextStyle(
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
                                                        lang.getText(
                                                          "no_userId",
                                                        ),
                                                      );
                                                    }

                                                    await saveTemplateAsUserMeal(
                                                      meal,
                                                      userId,
                                                    );

                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          lang.getText(
                                                            "saved_successfully",
                                                          ),
                                                        ),
                                                        behavior:
                                                            SnackBarBehavior
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
                                                          curve:
                                                              Curves.easeInOut,
                                                        ),
                                                      ),
                                                    );
                                                  } catch (e) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          "Hiba: $e",
                                                        ),
                                                        behavior:
                                                            SnackBarBehavior
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
                                                          curve:
                                                              Curves.easeInOut,
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
                                                child: Text(
                                                  lang.getText("edit"),
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
                                                child: Text(
                                                  lang.getText("add"),
                                                ),
                                              ),
                                            ),
                                            Center(
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  setState(() {
                                                    userMeals.addAll(
                                                      meal.meals,
                                                    );
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
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
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
                            padding: const EdgeInsets.symmetric(vertical: 6),
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
                                                      const SizedBox(
                                                        height: 16,
                                                      ),
                                                      Text(
                                                        "${lang.getText("sure_delete_template")}\n'${meal.customName}'?",
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: const TextStyle(
                                                          color: Colors.white70,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 24,
                                                      ),
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
                                                            style: TextButton.styleFrom(
                                                              foregroundColor:
                                                                  Colors
                                                                      .white54,
                                                            ),
                                                            child: Text(
                                                              lang.getText(
                                                                "cancel",
                                                              ),
                                                              style: const TextStyle(
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
                                                                    vertical:
                                                                        10,
                                                                  ),
                                                            ),
                                                            child: Text(
                                                              lang.getText(
                                                                "delete",
                                                              ),
                                                              style: const TextStyle(
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
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Bal oldali gomb: Hozzáadás
                Expanded(
                  child: CustomButton(
                    title: lang.getText("add"),
                    variant: CustomButtonVariant.secondary,
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
                  ),
                ),

                const SizedBox(width: 12),

                // Jobb oldali gomb: Tovább / Mentés
                Expanded(
                  child: CustomButton(
                    title: lang.getText("continue"),
                    variant: CustomButtonVariant.primary,
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
                                      style: const TextStyle(
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
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
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
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderSide: const BorderSide(
                                                  color: Colors.transparent,
                                                  width: 2,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderSide: const BorderSide(
                                                  color: Colors.transparent,
                                                  width: 1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            keyboardType: TextInputType.text,
                                          ),
                                        ),

                                        Positioned(
                                          top:
                                              MediaQuery.of(
                                                context,
                                              ).size.height *
                                              0.01,
                                          left:
                                              MediaQuery.of(
                                                context,
                                              ).size.width *
                                              0.04,
                                          child: Text(
                                            lang.getText("sample_name"),
                                            style: const TextStyle(
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
                                              final userId = prefs.getInt(
                                                'userId',
                                              );
                                              if (userId == null) {
                                                throw Exception(
                                                  lang.getText(
                                                    "no_userId_found",
                                                  ),
                                                );
                                              }

                                              await saveUserMeals(
                                                userMeals,
                                                _mealtypes[mealindex],
                                                userId,
                                              );

                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      lang.getText(
                                                        "saved_successfully",
                                                      ),
                                                    ),
                                                    showCloseIcon: true,
                                                    behavior: SnackBarBehavior
                                                        .floating,
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
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text("Hiba: $e"),
                                                    backgroundColor: Colors.red,
                                                    behavior: SnackBarBehavior
                                                        .floating,
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
                                              return;
                                            }
                                            if (_debounce?.isActive ?? false) {
                                              _debounce!.cancel();
                                            }
                                            _debounce = Timer(
                                              const Duration(
                                                milliseconds: 1500,
                                              ),
                                              () {
                                                if (context.mounted) {
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
                                                }
                                              },
                                            );
                                          },
                                          style: FilledButton.styleFrom(
                                            backgroundColor:
                                                const Color.fromARGB(
                                                  255,
                                                  85,
                                                  173,
                                                  78,
                                                ),
                                            fixedSize: Size(
                                              MediaQuery.of(
                                                    context,
                                                  ).size.width *
                                                  0.36,
                                              MediaQuery.of(
                                                    context,
                                                  ).size.height *
                                                  0.07,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(11),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                            ),
                                          ),
                                          child: Text(
                                            lang.getText("save_without_sample"),
                                            style: const TextStyle(
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
                                            final newName = mealnamecontroller
                                                .text
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
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      lang.getText(
                                                        'duplicate_template',
                                                      ),
                                                    ),
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                              return;
                                            }

                                            try {
                                              final prefs =
                                                  await SharedPreferences.getInstance();
                                              final userId = prefs.getInt(
                                                'userId',
                                              );
                                              if (userId == null) {
                                                throw Exception(
                                                  lang.getText(
                                                    "no_userId_found",
                                                  ),
                                                );
                                              }

                                              await saveUserMealsS(
                                                userMeals,
                                                mealnamecontroller.text,
                                                userId,
                                              );

                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      lang.getText(
                                                        "saved_successfully",
                                                      ),
                                                    ),
                                                    showCloseIcon: true,
                                                    behavior: SnackBarBehavior
                                                        .floating,
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
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text("Hiba: $e"),
                                                    behavior: SnackBarBehavior
                                                        .floating,
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
                                              return;
                                            }
                                            if (_debounce?.isActive ?? false) {
                                              _debounce!.cancel();
                                            }
                                            _debounce = Timer(
                                              const Duration(
                                                milliseconds: 1500,
                                              ),
                                              () {
                                                if (context.mounted) {
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
                                                }
                                              },
                                            );
                                          },
                                          style: FilledButton.styleFrom(
                                            backgroundColor:
                                                const Color.fromARGB(
                                                  255,
                                                  85,
                                                  173,
                                                  78,
                                                ),
                                            fixedSize: Size(
                                              MediaQuery.of(
                                                    context,
                                                  ).size.width *
                                                  0.36,
                                              MediaQuery.of(
                                                    context,
                                                  ).size.height *
                                                  0.07,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(11),
                                            ),
                                          ),
                                          child: Text(
                                            lang.getText("save"),
                                            style: const TextStyle(
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
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
