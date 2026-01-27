import 'dart:async';
import 'dart:convert';
import 'package:ai_barcode_scanner/ai_barcode_scanner.dart';
import 'package:client/components/running_workout_page.dart';
import 'package:client/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:client/models/workout.dart';
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
import '../Providers/language_provider.dart';
import '../providers/workout_provider.dart';

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

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final ExerciseDto item = userWorkouts.removeAt(oldIndex);
      userWorkouts.insert(newIndex, item);
    });
  }

  void startCloudNfcSharing(BuildContext context) async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    try {
      List<Map<String, dynamic>> jsonList = userWorkouts
          .map((e) => e.toJson())
          .toList();

      final response = await http.post(
        Uri.parse("$apiUrl/api/Share/uploadWorkout"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(jsonList),
      );

      if (mounted) Navigator.pop(context);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        String shareId = responseData['shareId'].toString();
        print("GENERÁLT ID: $shareId");

        List<int> idBytes = utf8.encode(shareId);
        List<int> responsePayload = [...idBytes, 0x90, 0x00];

        await NfcHce.removeApduResponse(0);
        await NfcHce.removeApduResponse(1);
        await NfcHce.removeApduResponse(2);

        await NfcHce.addApduResponse(0, responsePayload);
        await NfcHce.addApduResponse(1, responsePayload);
        await NfcHce.addApduResponse(2, responsePayload);

        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color.fromARGB(255, 30, 30, 30),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.nfc, size: 80, color: Colors.green),
                  const SizedBox(height: 20),
                  Text(
                    lang.getText("share_via_NFC"),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "ID: $shareId",
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    stopNfcSharing();
                    Navigator.pop(context);
                  },
                  child: Text(
                    lang.getText("close"),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        }
      } else {
        throw Exception("Hiba: ${response.statusCode}");
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      print("Hiba: $e");
    }
  }

  void stopNfcSharing() async {
    await NfcHce.removeApduResponse(0);
    print("NFC megosztás kikapcsolva.");
  }

  void startNfcReceivingCloud() {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    print("NFC Keresés indítása...");

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
              "Tartsd oda a telefont...",
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );

    NfcManager.instance.startSession(
      pollingOptions: {NfcPollingOption.iso14443},
      onDiscovered: (NfcTag tag) async {
        IsoDepAndroid? isoDep = IsoDepAndroid.from(tag);

        if (isoDep != null) {
          try {
            isoDep.setTimeout(5000);

            String? foundId;

            List<int> selectCmd = [
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
            ];

            print("1. Küldés (Select)...");
            Uint8List response1 = await isoDep.transceive(
              Uint8List.fromList(selectCmd),
            );
            print("1. Válasz: $response1");

            if (response1.length > 2 && response1[0] != 0x68) {
              var payload = response1.sublist(0, response1.length - 2);
              try {
                foundId = utf8.decode(payload);
              } catch (_) {}
            }

            if (foundId == null || foundId.isEmpty) {
              print("Az első válasz nem az adat. Küldöm a 2. parancsot...");

              List<int> command2 = [0x80, 0x10, 0x00, 0x00, 0x00];

              await Future.delayed(const Duration(milliseconds: 100));

              Uint8List response2 = await isoDep.transceive(
                Uint8List.fromList(command2),
              );
              print("2. Válasz: $response2");

              if (response2.length > 2) {
                var payload = response2.sublist(0, response2.length - 2);
                try {
                  foundId = utf8.decode(payload);
                } catch (e) {
                  print("Decode hiba: $e");
                }
              }
            }

            if (foundId != null && foundId.length > 1) {
              print(">>> ID FOGADVA: $foundId <<<");
              if (mounted) Navigator.pop(context);

              // Letöltés backendről
              final apiResponse = await http.get(
                Uri.parse("$apiUrl/api/Share/workout-$foundId"),
              );

              if (apiResponse.statusCode == 200) {
                List<dynamic> decodedData = jsonDecode(apiResponse.body);
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
              } else {
                throw Exception("Backend hiba: 404");
              }
            } else {
              print("NFC Sikertelen.");
              if (mounted) Navigator.pop(context);
              if (mounted)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Nem jött adat. Próbáld újra!"),
                    backgroundColor: Colors.orange,
                  ),
                );
            }

            NfcManager.instance.stopSession();
          } catch (e) {
            print("NFC Hiba: $e");
            NfcManager.instance.stopSession();
            if (mounted && Navigator.canPop(context)) Navigator.pop(context);
          }
        } else {
          NfcManager.instance.stopSession();
        }
      },
    );
  }

  Future<Widget> showQrCode(
    BuildContext context,
    List<dynamic> workouts,
  ) async {
    String jsonString = jsonEncode(workouts);
    String shareId = await _uploadWorkoutAndGenerateQr(context, jsonString);
    return userWorkouts.isNotEmpty
        ? Center(
            child: QrImageView(
              data: shareId,
              version: QrVersions.auto,
              size: MediaQuery.of(context).size.width * 0.5,
            ),
          )
        : Container();
  }

  Future<String> _uploadWorkoutAndGenerateQr(
    BuildContext context,
    String jsonString,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("$apiUrl/api/share/uploadWorkout"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(userWorkouts),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['shareId'];
      } else {
        throw Exception(
          "Szerver hiba: ${response.statusCode} - ${response.body}",
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Hiba: $e")));
      }
    }
    return '';
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
                  margin: const EdgeInsets.all(6),
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
                                          MediaQuery.of(context).size.height *
                                          0.6,
                                      clipBehavior: Clip.hardEdge,
                                      decoration: const BoxDecoration(
                                        color: Color.fromARGB(255, 35, 35, 35),
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(25),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(20),
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
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                IconButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
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
                                                    labelColor: Colors.white,
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
                                                                  color:
                                                                      const Color.fromARGB(
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
                                                                    startCloudNfcSharing(
                                                                      context,
                                                                    );
                                                                  },
                                                                  icon:
                                                                      const Icon(
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
                                                                  fontSize: 20,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
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
                                                                        0.55,
                                                                    MediaQuery.of(
                                                                          context,
                                                                        ).size.height *
                                                                        0.07,
                                                                  ),
                                                                  shape: RoundedRectangleBorder(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          11,
                                                                        ),
                                                                  ),
                                                                ),
                                                                onPressed: () {
                                                                  startNfcReceivingCloud();
                                                                },
                                                                child: Text(
                                                                  lang.getText(
                                                                    "recive_workout",
                                                                  ),
                                                                  style: TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize:
                                                                        20,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
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
                                                                  color: Colors
                                                                      .white,
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        11,
                                                                      ),
                                                                ),
                                                                child: FutureBuilder<Widget>(
                                                                  future: showQrCode(
                                                                    context,
                                                                    userWorkouts,
                                                                  ),
                                                                  builder:
                                                                      (
                                                                        context,
                                                                        snapshot,
                                                                      ) {
                                                                        if (snapshot.connectionState ==
                                                                            ConnectionState.waiting) {
                                                                          return Center(
                                                                            child:
                                                                                CircularProgressIndicator(),
                                                                          );
                                                                        } else if (snapshot
                                                                            .hasError) {
                                                                          return Center(
                                                                            child: Text(
                                                                              'Error: ${snapshot.error}',
                                                                            ),
                                                                          );
                                                                        } else {
                                                                          return snapshot.data ??
                                                                              SizedBox.shrink();
                                                                        }
                                                                      },
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
                                                                  fontSize: 20,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
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
                                                                        0.55,
                                                                    MediaQuery.of(
                                                                          context,
                                                                        ).size.height *
                                                                        0.07,
                                                                  ),
                                                                  shape: RoundedRectangleBorder(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
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
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize:
                                                                        20,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
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
                        ),
                      ],
                    ),
                    backgroundColor: const Color.fromARGB(255, 58, 58, 58),
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
                              padding: EdgeInsets.all(20),
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
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
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
                                            children: [
                                              Expanded(
                                                child: SingleChildScrollView(
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      if (exerciseItem
                                                          .images
                                                          .isNotEmpty)
                                                        Container(
                                                          width:
                                                              double.infinity,
                                                          clipBehavior:
                                                              Clip.hardEdge,
                                                          decoration: BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                            border: Border.all(
                                                              color: Colors
                                                                  .white24,
                                                            ),
                                                          ),
                                                          child: ClipRRect(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                            child: Transform.scale(
                                                              scale: 1,
                                                              child: Image.network(
                                                                "https://raw.githubusercontent.com/sitespectrum/zest_exercises/main/exercises/${exerciseItem.images[0]}",
                                                                fit: BoxFit
                                                                    .contain,
                                                                loadingBuilder:
                                                                    (
                                                                      context,
                                                                      child,
                                                                      loadingProgress,
                                                                    ) {
                                                                      if (loadingProgress ==
                                                                          null)
                                                                        return child;
                                                                      return const Center(
                                                                        child:
                                                                            CircularProgressIndicator(),
                                                                      );
                                                                    },
                                                                errorBuilder:
                                                                    (
                                                                      context,
                                                                      error,
                                                                      stackTrace,
                                                                    ) {
                                                                      return const Center(
                                                                        child: Icon(
                                                                          Icons
                                                                              .fitness_center,
                                                                          color:
                                                                              Colors.white24,
                                                                          size:
                                                                              50,
                                                                        ),
                                                                      );
                                                                    },
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      const SizedBox(
                                                        height: 20,
                                                      ),
                                                      Text(
                                                        name,
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 16,
                                                      ),
                                                      Text(
                                                        lang.getText(
                                                          "description",
                                                        ),
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 20,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          decoration:
                                                              TextDecoration
                                                                  .underline,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 20,
                                                      ),
                                                      Flexible(
                                                        child: SingleChildScrollView(
                                                          child: Container(
                                                            width:
                                                                double.infinity,
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
                                                                color: Colors
                                                                    .white24,
                                                              ),
                                                            ),
                                                            child: Text(
                                                              exerciseItem
                                                                  .getInstructions(
                                                                    langCode,
                                                                  )
                                                                  .join('\n\n'),
                                                              style:
                                                                  const TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize:
                                                                        15,
                                                                  ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 16,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              ElevatedButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
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
                                                  lang.getText("close"),
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
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
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 6,
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(
                                      255,
                                      45,
                                      45,
                                      45,
                                    ),
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
                                          child: TextButton(
                                            onPressed: () => {
                                              setState(() {
                                                userWorkouts.removeAt(index);
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
                            ),
                          );
                        },
                      ),
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

              FutureBuilder<List<CustomUserWorkoutDto>>(
                future: futureCustomWorkouts,
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

                  final templates = snapshot.data ?? [];

                  if (templates.isEmpty) {
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
                    itemCount: templates.length,
                    itemBuilder: (context, index) {
                      final template = templates[index];

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
                                            template.customName.isNotEmpty
                                                ? template.customName
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
                                              itemCount:
                                                  template.exercises.length,
                                              itemBuilder: (context, i) {
                                                final item =
                                                    template.exercises[i];

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
                                                        item.exercise!.getName(
                                                          langCode,
                                                        ),
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
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
                                              onPressed: () {
                                                setState(() {
                                                  userWorkouts.addAll(
                                                    template.exercises
                                                        .map(
                                                          (we) => we.exercise,
                                                        )
                                                        .where((e) => e != null)
                                                        .cast<ExerciseDto>()
                                                        .toList(),
                                                  );
                                                });
                                                Navigator.pop(context);
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      "${template.customName} ${lang.getText("added_to_list")}",
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
                                                lang.getText("load_template"),
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
                                    template.customName.isNotEmpty
                                        ? template.customName
                                        : lang.getText("unknown_template"),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
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
            ],
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(20),
          child: userWorkouts.isNotEmpty
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FilledButton(
                      onPressed: () async {
                        final result = await Navigator.push<List<ExerciseDto>>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddWorkoutPage(),
                          ),
                        );

                        if (result != null) {
                          setState(() {
                            userWorkouts.addAll(result);
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
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                RunningWorkoutPage(userWorkouts: userWorkouts),
                          ),
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
                        workoutProvider.isWorkoutActive
                            ? lang.getText("continue_workout")
                            : lang.getText("start"),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FilledButton(
                      onPressed: () async {
                        final result = await Navigator.push<List<ExerciseDto>>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddWorkoutPage(),
                          ),
                        );

                        if (result != null) {
                          setState(() {
                            userWorkouts.addAll(result);
                          });
                        }
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
                        lang.getText("add"),
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
