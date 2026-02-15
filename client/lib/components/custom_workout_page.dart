import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:ai_barcode_scanner/ai_barcode_scanner.dart';
import 'package:client/components/drawers/workout_details_drawer.dart';
import 'package:client/components/drawers/workout_template_drawer.dart';
import 'package:client/components/running_workout_page.dart';
import 'package:client/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:client/models/workout.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:http/http.dart' as http;
import 'package:nfc_host_card_emulation/nfc_host_card_emulation_platform_interface.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'dart:typed_data';
import 'package:nfc_host_card_emulation/nfc_host_card_emulation.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_workout_page.dart';
import 'package:client/providers/language_provider.dart';
import 'package:client/providers/workout_provider.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:client/components/ui/custom_card.dart';
import 'package:client/components/ui/custom_button.dart';
import 'package:client/components/ui/custom_drawer.dart';

class CWorkoutPage extends StatefulWidget {
  final DateTime selectedDay;
  const CWorkoutPage({super.key, required this.selectedDay});

  @override
  State<CWorkoutPage> createState() => _CWorkoutPageState();
}

class _CWorkoutPageState extends State<CWorkoutPage> {
  List<ExerciseDto> userWorkouts = [];
  late Future<List<CustomUserWorkoutDto>> futureCustomWorkouts;
  bool showdelete = false;
  Timer? _debounce;
  String _nfcData = 'No data';
  bool isNfcActive = false;
  String nfcStatus = "";
  String _statusText = "";
  bool _isNfcReading = false;
  String shareId = "";

  @override
  void initState() {
    super.initState();
    futureCustomWorkouts = fetchCustomUserWorkouts().catchError((e) {
      return <CustomUserWorkoutDto>[];
    });
    NfcManager.instance.isAvailable().then((isAvailable) {
      if (isAvailable) {
      } else {
        setState(() {
          _nfcData = 'NFC is not available';
        });
      }
    });
  }

  Future<List<CustomUserWorkoutDto>> fetchCustomUserWorkouts() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    if (token == null) throw Exception("Nincs token");

    final response = await http.get(
      Uri.parse("$apiUrl/api/workout/getCustomUserWorkouts"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => CustomUserWorkoutDto.fromJson(e)).toList();
    } else {
      throw Exception(
        "${lang.getText("failed_to_fetch_meals")} ${response.body}",
      );
    }
  }

  Future<bool> deleteUserWorkoutTemplate(int id) async {
    final url = Uri.parse("$apiUrl/api/Workout/DeleteTemplate?id=$id");
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

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final ExerciseDto item = userWorkouts.removeAt(oldIndex);
      userWorkouts.insert(newIndex, item);
    });
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
              Container(
                width: double.infinity,
                child: CustomButton(
                  onPressed: () {
                    stopNfcSharing();
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Bezárás",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
        List<ExerciseDto> newWorkouts = decodedData
            .map((item) => ExerciseDto.fromJson(item))
            .toList();

        if (mounted) {
          setState(() {
            userWorkouts.addAll(newWorkouts);
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
      builder: (c) => AlertDialog(
        backgroundColor: Color.fromARGB(255, 30, 30, 30),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.nfc, size: 80, color: Colors.green),
            SizedBox(height: 20),
            Text(
              "Érintsd a másik telefonhoz...",
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                onPressed: () {
                  FlutterBluePlus.stopScan();
                  Navigator.pop(context);
                },
                child: Text(
                  "Bezárás",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
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

      List<Map<String, dynamic>> jsonList = userWorkouts
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

  Future<String?> _generateQrCodeOnly() async {
    String? id = await _uploadWorkoutToBackend();

    if (id != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("QR kód legenerálva!"),
          backgroundColor: Colors.green,
        ),
      );
    }
    return id;
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
              List<ExerciseDto> newWorkouts = [];

              if (scannedValue.startsWith("[")) {
                List<dynamic> decodedData = jsonDecode(scannedValue);
                newWorkouts = decodedData
                    .map((item) => ExerciseDto.fromJson(item))
                    .toList();
              } else {
                final response = await http.get(
                  Uri.parse("$apiUrl/api/Share/workout-$scannedValue"),
                );

                if (response.statusCode == 200) {
                  List<dynamic> decodedData = jsonDecode(response.body);
                  newWorkouts = decodedData
                      .map((item) => ExerciseDto.fromJson(item))
                      .toList();
                } else {
                  throw Exception("Nem található vagy lejárt megosztás.");
                }
              }

              Navigator.pop(context);

              setState(() {
                userWorkouts.addAll(newWorkouts);
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "${newWorkouts.length} ${lang.getText("added_to_list")}",
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            } catch (e) {
              if (context.mounted) {
                Navigator.pop(context);
                debugPrint("Hiba az importálásnál: $e");
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Hiba: ${e.toString()}"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          controller: MobileScannerController(
            detectionSpeed: DetectionSpeed.noDuplicates,
            autoStart: true,
            formats: [BarcodeFormat.qrCode],
            returnImage: false,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final langCode = Provider.of<LanguageProvider>(context).languageCode;
    final workoutProvider = Provider.of<WorkoutProvider>(context);
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, userWorkouts);
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
                  margin: const EdgeInsets.all(5),
                  child: AppBar(
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
                                  color: const Color.fromRGBO(45, 45, 45, 0.5),
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
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
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
                        SizedBox(width: 8),
                        IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              50,
                              50,
                              146,
                              255,
                            ),
                            disabledBackgroundColor: const Color.fromARGB(
                              25,
                              64,
                              255,
                              50,
                            ),
                            foregroundColor: Colors.white,
                            disabledForegroundColor: Colors.white38,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            side: BorderSide(
                              color: const Color.fromARGB(150, 50, 146, 255),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
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
                                    child: SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                          0.5,
                                      child: Column(
                                        spacing: 12,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                lang.getText("share"),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Expanded(
                                            child: DefaultTabController(
                                              initialIndex: 0,
                                              length: 2,
                                              child: Column(
                                                children: [
                                                  Container(
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
                                                                FontWeight.bold,
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
                                                        shape:
                                                            BoxShape.rectangle,
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
                                                      labelColor: Colors.white,
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
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal: 0,
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
                                                                      borderRadius:
                                                                          BorderRadius.circular(
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
                                                                        Icons
                                                                            .contactless_rounded,
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
                                                                ),
                                                                Flex(
                                                                  direction: Axis
                                                                      .horizontal,
                                                                  spacing: 12,
                                                                  children: [
                                                                    Expanded(
                                                                      child: Container(
                                                                        height:
                                                                            2,
                                                                        color: Colors
                                                                            .white38,
                                                                      ),
                                                                    ),
                                                                    Text(
                                                                      lang.getText(
                                                                        "or",
                                                                      ),
                                                                      style: const TextStyle(
                                                                        color: Colors
                                                                            .white38,
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
                                                                        color: Colors
                                                                            .white38,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                                CustomButton(
                                                                  onPressed: () {
                                                                    startNfcReceivingCloud();
                                                                  },
                                                                  title: lang
                                                                      .getText(
                                                                        "recive_workout",
                                                                      ),
                                                                  iconData: Icons
                                                                      .call_received_rounded,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal: 5,
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
                                                                        Alignment
                                                                            .center,
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
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            16,
                                                                          ),
                                                                      border: Border.all(
                                                                        color: Colors
                                                                            .white
                                                                            .withAlpha(
                                                                              50,
                                                                            ),
                                                                      ),
                                                                    ),
                                                                    child:
                                                                        shareId
                                                                            .isNotEmpty
                                                                        ? QrImageView(
                                                                            data:
                                                                                shareId,
                                                                            version:
                                                                                QrVersions.auto,
                                                                            dataModuleStyle: const QrDataModuleStyle(
                                                                              color: Colors.white,
                                                                              dataModuleShape: QrDataModuleShape.square,
                                                                            ),
                                                                            eyeStyle: const QrEyeStyle(
                                                                              color: Colors.white,
                                                                              eyeShape: QrEyeShape.square,
                                                                            ),
                                                                          )
                                                                        : Column(
                                                                            spacing:
                                                                                12,
                                                                            mainAxisSize:
                                                                                MainAxisSize.min,
                                                                            children: [
                                                                              Icon(
                                                                                Icons.qr_code,
                                                                                size: 96,
                                                                                color: Colors.white38,
                                                                              ),
                                                                              Text(
                                                                                lang.getText(
                                                                                  "no_qr_code_yet",
                                                                                ),
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
                                                                  direction: Axis
                                                                      .horizontal,
                                                                  spacing: 12,
                                                                  children: [
                                                                    CustomButton(
                                                                      onPressed: () async {
                                                                        await _generateQrCodeOnly();
                                                                        setPopupState(
                                                                          () {},
                                                                        );
                                                                      },
                                                                      variant:
                                                                          CustomButtonVariant
                                                                              .secondary,
                                                                      child: const Padding(
                                                                        padding: EdgeInsets.symmetric(
                                                                          vertical:
                                                                              2.5,
                                                                        ),
                                                                        child: Icon(
                                                                          Icons
                                                                              .refresh_rounded,
                                                                          color:
                                                                              Colors.white,
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
                                                                        title: lang.getText(
                                                                          "scan",
                                                                        ),
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
                            );
                          },
                          icon: const Icon(
                            CupertinoIcons.share,
                            size: 25,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    automaticallyImplyLeading: false,
                    backgroundColor: Colors.transparent,
                    iconTheme: const IconThemeData(color: Colors.white),
                  ),
                ),
              ),
              Container(
                child: userWorkouts.isEmpty
                    ? Center(
                        child: Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.all(30),
                              child: Text(
                                lang.getText("no_added_exercise_yet"),
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: userWorkouts.length,
                        onReorder: _onReorder,
                        proxyDecorator:
                            (
                              Widget child,
                              int index,
                              Animation<double> animation,
                            ) {
                              return AnimatedBuilder(
                                animation: animation,
                                builder: (BuildContext context, Widget? child) {
                                  return Material(
                                    color: Colors.transparent,
                                    elevation: 0,
                                    child: child,
                                  );
                                },
                                child: child,
                              );
                            },
                        itemBuilder: (context, index) {
                          final exerciseItem = userWorkouts[index];
                          final name = exerciseItem.getName(langCode);

                          return GestureDetector(
                            key: ValueKey(exerciseItem),
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                builder: (context) {
                                  return StatefulBuilder(
                                    builder: (context, setStateDialog) {
                                      return WorkoutDetailsDrawer(
                                        exerciseItem,
                                        name,
                                      );
                                    },
                                  );
                                },
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF272727,
                                    ).withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(12),
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
                                          name,
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
                                              child: Text.rich(
                                                TextSpan(
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 14,
                                                  ),
                                                  children: [
                                                    TextSpan(
                                                      text:
                                                          '${lang.getText("category")}: ',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text:
                                                          '${exerciseItem.getCategory(langCode)} | ',
                                                    ),

                                                    TextSpan(
                                                      text:
                                                          '${lang.getText("equipment")}: ',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),

                                                    TextSpan(
                                                      text:
                                                          '${exerciseItem.getEquipment(langCode)} | ',
                                                    ),

                                                    TextSpan(
                                                      text:
                                                          '${lang.getText("force")}: ',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text:
                                                          '${exerciseItem.getForce(langCode)} | ',
                                                    ),

                                                    TextSpan(
                                                      text:
                                                          '${lang.getText("level")}: ',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text:
                                                          '${exerciseItem.getLevel(langCode)} | ',
                                                    ),

                                                    TextSpan(
                                                      text:
                                                          '${lang.getText("primary_muscles")}: ',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text: exerciseItem
                                                          .getPMuscles(langCode)
                                                          .join(", "),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Center(
                                          child: Container(
                                            margin: EdgeInsets.only(top: 15),
                                            width: double.infinity,
                                            child: CustomButton(
                                              variant: CustomButtonVariant
                                                  .primaryDelete,
                                              onPressed: () => {
                                                setState(() {
                                                  userWorkouts.removeAt(index);
                                                }),
                                              },
                                              child: Text(
                                                lang.getText("delete"),
                                                style: TextStyle(
                                                  color: Colors.redAccent,
                                                  fontWeight: FontWeight.bold,
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
                            ),
                          );
                        },
                      ),
              ),

              SizedBox(height: 20),

              CustomCard(
                title: lang.getText("my_templates"),
                iconData: Icons.folder_copy_outlined,
                height: 220,
                child: FutureBuilder<List<CustomUserWorkoutDto>>(
                  future: futureCustomWorkouts,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: Text(
                          "Hiba történt: ${snapshot.error}",
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    final templates = snapshot.data ?? [];

                    if (templates.isEmpty) {
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
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: templates.length,
                      itemBuilder: (context, index) {
                        final template = templates[index];

                        return GestureDetector(
                          onTap: () async {
                            final result = await showModalBottomSheet<bool>(
                              context: context,
                              builder: (context) {
                                return WorkoutTemplateDrawer(
                                  template,
                                  userWorkouts,
                                );
                              },
                            );

                            if (result == true) {
                              setState(() {});
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 55, 55, 55),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            template.customName.isNotEmpty
                                                ? template.customName
                                                : lang.getText(
                                                    "unknown_template",
                                                  ),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Center(
                                          child: Container(
                                            margin: EdgeInsets.only(top: 15),
                                            child: CustomButton(
                                              variant: CustomButtonVariant
                                                  .primaryDelete,
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
                                                          BorderRadius.circular(
                                                            16,
                                                          ),
                                                      side: const BorderSide(
                                                        color: Colors.white24,
                                                      ),
                                                    ),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            20,
                                                          ),
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            lang.getText(
                                                              "delete",
                                                            ),
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 22,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            height: 16,
                                                          ),
                                                          Text(
                                                            "${lang.getText("sure_delete_template")}\n'${template.customName}'?",
                                                            textAlign: TextAlign
                                                                .center,
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .white70,
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
                                                                child: Text(
                                                                  lang.getText(
                                                                    "cancel",
                                                                  ),
                                                                  style: const TextStyle(
                                                                    color: Colors
                                                                        .white54,
                                                                    fontSize:
                                                                        16,
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
                                                                    fontSize:
                                                                        16,
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
                                                      await deleteUserWorkoutTemplate(
                                                        template.id,
                                                      );

                                                  if (success) {
                                                    setState(() {
                                                      templates.removeAt(index);
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
                                                          ),
                                                          backgroundColor:
                                                              Colors.green,
                                                          behavior:
                                                              SnackBarBehavior
                                                                  .floating,
                                                        ),
                                                      );
                                                    }
                                                  }
                                                }
                                              },
                                              child: Text(
                                                lang.getText("delete"),
                                                style: TextStyle(
                                                  color: Colors.redAccent,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${lang.getText('exercises')}: ${template.exercises.length} \n${template.exercises.map((e) => e.exercise?.getName(langCode) ?? "").join(' | ')}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
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
            child: userWorkouts.isNotEmpty
                ? Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          iconData: Icons.add,
                          title: lang.getText("add"),
                          variant: CustomButtonVariant.secondary,
                          onPressed: () async {
                            final result =
                                await Navigator.push<List<ExerciseDto>>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AddWorkoutPage(),
                                  ),
                                );
                            if (result != null) {
                              setState(() {
                                userWorkouts.addAll(result);
                              });
                            }
                          },
                        ),
                      ),

                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          iconData: Icons.skip_next,
                          title: workoutProvider.isWorkoutActive
                              ? lang.getText("continue_workout")
                              : lang.getText("start"),
                          variant: CustomButtonVariant.primaryWorkout,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RunningWorkoutPage(
                                  userWorkouts: userWorkouts,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          iconData: Icons.add,
                          title: lang.getText("add"),
                          variant: CustomButtonVariant.primaryWorkout,
                          onPressed: () async {
                            final result =
                                await Navigator.push<List<ExerciseDto>>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AddWorkoutPage(),
                                  ),
                                );
                            if (result != null) {
                              setState(() {
                                userWorkouts.addAll(result);
                              });
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
}
