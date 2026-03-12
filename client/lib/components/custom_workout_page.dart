import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:ai_barcode_scanner/ai_barcode_scanner.dart';
import 'package:client/components/drawers/workout_details_drawer.dart';
import 'package:client/components/drawers/workout_template_drawer.dart';
import 'package:client/components/running_workout_page.dart';
import 'package:client/components/shared_running_workout_page.dart';
import 'package:client/components/shared_workout_summary_page.dart';
import 'package:client/components/ui/custom_snackbar.dart';
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
import 'package:client/components/drawers/host_guest_drawer.dart';
import 'package:client/providers/language_provider.dart';
import 'package:client/providers/workout_provider.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:client/components/ui/custom_card.dart';
import 'package:client/components/ui/custom_button.dart';
import 'package:client/components/ui/custom_drawer.dart';
import 'package:client/services/websocket_service.dart';

class CWorkoutPage extends StatefulWidget {
  final DateTime selectedDay;
  final List<ExerciseDto>? restoredExercises;
  const CWorkoutPage({
    super.key,
    required this.selectedDay,
    this.restoredExercises,
  });

  @override
  State<CWorkoutPage> createState() => _CWorkoutPageState();
}

class _CWorkoutPageState extends State<CWorkoutPage>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  List<ExerciseDto> userWorkouts = [];
  late Future<List<CustomUserWorkoutDto>> futureCustomWorkouts;
  late Future<List<CustomUserWorkoutDto>> futureOfficialWorkouts;
  bool showdelete = false;
  Timer? _debounce;
  String _nfcData = 'No data';
  bool isNfcActive = false;
  String nfcStatus = "";
  String _statusText = "";
  bool _isNfcReading = false;
  String shareId = "";
  Color workoutColorCode = const Color.fromARGB(150, 50, 146, 255);

  String? currentSessionId;
  bool isOnlineMode = false;
  bool isHost = false;
  Map<String, dynamic>? currentGameState;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (widget.restoredExercises != null) {
      userWorkouts = widget.restoredExercises!;
    } else {
      _loadDraft();
    }
    WidgetsBinding.instance.addObserver(this);
    futureCustomWorkouts = fetchCustomUserWorkouts().catchError((e) {
      return <CustomUserWorkoutDto>[];
    });
    futureOfficialWorkouts = fetchOfficialUserWorkouts().catchError((e) {
      return <CustomUserWorkoutDto>[];
    });

    WebSocketService().activeSessionNotifier.addListener(
      _onSessionStateChanged,
    );

    _setupWebSocketListeners();

    NfcManager.instance.isAvailable().then((isAvailable) {
      if (isAvailable) {
      } else {
        setState(() {
          _nfcData = 'NFC is not available';
        });
      }
    });
    _checkAndConnectSession();
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final draftString = prefs.getString('draft_workout');

    if (draftString != null) {
      final decoded = jsonDecode(draftString) as List;
      if (mounted) {
        setState(() {
          userWorkouts = decoded.map((e) => ExerciseDto.fromJson(e)).toList();
        });
      }
    }
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();

    if (userWorkouts.isEmpty) {
      await prefs.remove('draft_workout');
    } else {
      final jsonString = jsonEncode(
        userWorkouts.map((e) => e.toJson()).toList(),
      );
      await prefs.setString('draft_workout', jsonString);
    }
  }

  Future<void> _onSessionStateChanged() async {
    final sessionId = WebSocketService().activeSessionNotifier.value;
    final prefs = await SharedPreferences.getInstance();
    final hostStatus = prefs.getBool('is_host') ?? false;

    if (mounted) {
      setState(() {
        if (sessionId != null && sessionId.isNotEmpty) {
          currentSessionId = sessionId;
          isOnlineMode = true;
          isHost = hostStatus;
        } else {
          currentSessionId = null;
          isOnlineMode = false;
          isHost = false;
        }
      });
    }
  }

  void _setupWebSocketListeners() {
    WebSocketService().onMessageReceived = (data) {
      if (data['type'] == 'promoted-to-host') {
        SharedPreferences.getInstance().then((prefs) {
          prefs.setBool('is_host', true);
        });
        if (mounted) {
          setState(() {
            isHost = true;
          });
          final lang = Provider.of<LanguageProvider>(context, listen: false);
          CustomSnackbar.show(
            context,
            "Te lettél a Host!",
            backgroundColor: Colors.green,
          );
        }
      } else if (data['type'] == 'session-ended') {
        SharedPreferences.getInstance().then((prefs) {
          prefs.remove('active_session_id');
          prefs.remove('is_host');
          WebSocketService().disconnect();

          if (mounted) {
            setState(() {
              currentGameState = null;
            });
            if (Navigator.canPop(context)) Navigator.pop(context);
            CustomSnackbar.show(
              context,
              "A Host befejezte a közös edzést.",
              backgroundColor: Colors.orange,
            );
          }
        });
      } else if (data['type'] == 'sync-exercises') {
        try {
          List<dynamic> rawData = data['data'];
          if (mounted) {
            setState(() {
              userWorkouts = rawData
                  .map((e) => ExerciseDto.fromJson(e))
                  .toList();
            });
          }
        } catch (e) {
          print("Hiba a JSON feldolgozásakor: $e");
        }
      } else if (data['type'] == 'sync-workout-state') {
        if (mounted) {
          setState(() {
            currentGameState = data['data'];
          });
        }

        SharedPreferences.getInstance().then((prefs) {
          int myUserId = prefs.getInt('userId') ?? 0;
          bool amIHost = data['data']['hostId'] == myUserId;

          if (amIHost && !isHost) {
            prefs.setBool('is_host', true);
            if (mounted) setState(() => isHost = true);
          } else if (!amIHost && isHost) {
            prefs.setBool('is_host', false);
            if (mounted) setState(() => isHost = false);
          }
        });
      } else if (data['type'] == 'workout-started') {
        if (mounted) {
          for (var ex in userWorkouts) {
            for (var set in ex.sets) {
              set.isCompleted = false;
            }
          }

          setState(() {
            currentGameState = data['data'];
          });

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SharedRunningWorkoutPage(
                userWorkouts: userWorkouts,
                initialGameState: data['data'],
              ),
            ),
          ).then((result) {
            _setupWebSocketListeners();

            if (result != null &&
                result is Map &&
                result['status'] == 'finished') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SharedWorkoutSummaryPage(
                    finalState: result['data'],
                    userWorkouts: userWorkouts,
                    isHost: isHost,
                  ),
                ),
              ).then((_) {
                if (mounted)
                  setState(() {
                    currentGameState = null;
                  });
              });
            } else {
              if (isOnlineMode && currentSessionId != null) {
                WebSocketService().sendAction('get-workout-state', {});
              }
              if (mounted) setState(() {});
            }
          });
        }
      }
    };
  }

  Future<void> _checkAndConnectSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('active_session_id');
    final hostStatus = prefs.getBool('is_host') ?? false;

    if (savedId != null && savedId.isNotEmpty) {
      if (mounted) {
        setState(() {
          currentSessionId = savedId;
          isOnlineMode = true;
          isHost = hostStatus;
        });
      }

      WebSocketService().activeSessionNotifier.value = savedId;
      await WebSocketService().connect(savedId);

      if (WebSocketService().isConnected) {
        WebSocketService().sendAction('get-workout-state', {});
        WebSocketService().sendAction('get-exercises', {});
      }
    } else {
      if (mounted) {
        setState(() {
          currentSessionId = null;
          isOnlineMode = false;
          isHost = false;
        });
      }
      WebSocketService().activeSessionNotifier.value = null;
      WebSocketService().disconnect();
    }
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

  Future<List<CustomUserWorkoutDto>> fetchOfficialUserWorkouts() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) throw Exception("Nincs token");

    final response = await http.get(
      Uri.parse("$apiUrl/api/Workout/official-templates"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => CustomUserWorkoutDto.fromJson(e)).toList();
    } else {
      throw Exception(
        "Hiba a hivatalos sablonok betöltésekor: ${response.body}",
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
      _saveDraft();

      if (isOnlineMode && currentSessionId != null) {
        final List<int> orderedIds = userWorkouts.map((e) => e.id).toList();

        WebSocketService().sendAction('reorder-exercises', {
          'orderedIds': orderedIds,
        });
      }
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    CustomSnackbar.show(context, message, backgroundColor: Colors.red);
  }

  Future<void> startCloudNfcSharing(BuildContext context) async {
    String? id = await _uploadWorkoutToBackend();
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    if (id == null) return;

    setState(() {
      isNfcActive = true;
      nfcStatus = "${lang.getText("start_sharing")}... (ID: $id)";
    });

    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    if (statuses.values.any((status) => status.isDenied)) {
      setState(() => nfcStatus = lang.getText("missing_bt"));
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
                Text(
                  lang.getText("nfc_&_bt_active"),
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
                  child: Text(
                    lang.getText("close"),
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
      _showError(e.toString());
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
      _statusText = lang.getText("loading_workout");
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
          _saveDraft();
          CustomSnackbar.show(
            context,
            "${newWorkouts.length} ${lang.getText("meal_added_to_list")}",
            backgroundColor: workoutColorCode,
          );
        }
        await Future.delayed(Duration(milliseconds: 800));

        if (!mounted) return;

        Navigator.pop(context);
      }
    } catch (e) {
      _showError("${lang.getText("failed_to_fetch_meals")}: ${e.toString()}");
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
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    if (statuses.values.any((status) => status.isDenied)) {
      _showError(lang.getText("missing_bt"));
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
              lang.getText("touch_the_other_phone"),
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
                  lang.getText("close"),
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

              if (id.contains('M-')) {
                found = false;
                return;
              }

              if (!found) {
                found = true;
                FlutterBluePlus.stopScan();

                if (mounted) Navigator.pop(context);

                await _fetchAndShowSharedWorkout(id);
              }
              return;
            } catch (e) {
              print("${lang.getText("decoding_error")} $e");
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
        _showError(lang.getText("failed_to_identitify"));
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);

      if (!e.toString().contains("poll timeout")) {
        _showError("Hiba: ${e.toString()}");
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    FlutterBlePeripheral().stop();
    WebSocketService().activeSessionNotifier.removeListener(
      _onSessionStateChanged,
    );
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      _checkAndConnectSession();
    } else if (state == AppLifecycleState.paused) {
      WebSocketService().disconnect();
    }
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
        throw Exception("${response.statusCode}");
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      _showError("$e");
      return null;
    }
  }

  Future<void> _generateQrCodeOnly() async {
    String? id = await _uploadWorkoutToBackend();
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    if (id != null) {
      CustomSnackbar.show(
        context,
        lang.getText("qr_success"),
        backgroundColor: workoutColorCode,
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
                  throw Exception(lang.getText("missing_error"));
                }
              }

              Navigator.pop(context);

              setState(() {
                userWorkouts.addAll(newWorkouts);
              });
              _saveDraft();

              CustomSnackbar.show(
                context,
                "${newWorkouts.length} ${lang.getText("meal_added_to_list")}",
                backgroundColor: workoutColorCode,
              );
            } catch (e) {
              Navigator.pop(context);
              debugPrint("$e");
              CustomSnackbar.show(
                context,
                "${lang.getText("error")}: ${e.toString()}",
                backgroundColor: Colors.red,
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
                            side: const BorderSide(
                              color: Color.fromARGB(150, 50, 146, 255),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              elevation: 0,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const HostGuestDrawer(),
                            );
                            _checkAndConnectSession();
                          },
                          icon: const Icon(
                            Icons.link_rounded,
                            size: 25,
                            color: Colors.white,
                          ),
                        ),

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
                                                                          6,
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
                                                                        variant:
                                                                            CustomButtonVariant.primaryWorkout,
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
                                              onPressed: () {
                                                if (isOnlineMode &&
                                                    currentSessionId != null) {
                                                  WebSocketService().sendAction(
                                                    'remove-exercise',
                                                    {
                                                      'exerciseId':
                                                          exerciseItem.id,
                                                    },
                                                  );
                                                } else {
                                                  setState(() {
                                                    userWorkouts.removeAt(
                                                      index,
                                                    );
                                                  });
                                                  _saveDraft();
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
                height: 350,
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.white24, width: 1),
                          ),
                        ),
                        child: TabBar(
                          indicatorColor: workoutColorCode,
                          labelColor: workoutColorCode,
                          unselectedLabelColor: Colors.grey,
                          tabs: const [
                            Tab(text: "Saját"),
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: 16,
                                    color: Colors.amber,
                                  ),
                                  SizedBox(width: 4),
                                  Text("Zest"),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        child: TabBarView(
                          children: [
                            FutureBuilder<List<CustomUserWorkoutDto>>(
                              future: futureCustomWorkouts,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                if (snapshot.hasError) {
                                  return Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      0,
                                      12,
                                      12,
                                    ),
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
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 20,
                                      ),
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
                                  padding: const EdgeInsets.only(top: 8),
                                  shrinkWrap: true,
                                  itemCount: templates.length,
                                  itemBuilder: (context, index) {
                                    final template = templates[index];

                                    return GestureDetector(
                                      onTap: () async {
                                        final result =
                                            await showModalBottomSheet<bool>(
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
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 6,
                                        ),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: const Color.fromARGB(
                                              255,
                                              55,
                                              55,
                                              55,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        template
                                                                .customName
                                                                .isNotEmpty
                                                            ? template
                                                                  .customName
                                                            : lang.getText(
                                                                "unknown_template",
                                                              ),
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                    Center(
                                                      child: Container(
                                                        margin:
                                                            const EdgeInsets.only(
                                                              top: 15,
                                                            ),
                                                        child: CustomButton(
                                                          variant:
                                                              CustomButtonVariant
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
                                                                    color: Colors
                                                                        .white24,
                                                                  ),
                                                                ),
                                                                child: Padding(
                                                                  padding:
                                                                      const EdgeInsets.all(
                                                                        20,
                                                                      ),
                                                                  child: Column(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .min,
                                                                    children: [
                                                                      Text(
                                                                        lang.getText(
                                                                          "delete",
                                                                        ),
                                                                        style: const TextStyle(
                                                                          color:
                                                                              Colors.white,
                                                                          fontSize:
                                                                              22,
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                        ),
                                                                      ),
                                                                      const SizedBox(
                                                                        height:
                                                                            16,
                                                                      ),
                                                                      Text(
                                                                        "${lang.getText("sure_delete_template")}\n'${template.customName}'?",
                                                                        textAlign:
                                                                            TextAlign.center,
                                                                        style: const TextStyle(
                                                                          color:
                                                                              Colors.white70,
                                                                          fontSize:
                                                                              16,
                                                                        ),
                                                                      ),
                                                                      const SizedBox(
                                                                        height:
                                                                            24,
                                                                      ),
                                                                      Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.spaceEvenly,
                                                                        children: [
                                                                          TextButton(
                                                                            onPressed: () => Navigator.pop(
                                                                              context,
                                                                              false,
                                                                            ),
                                                                            child: Text(
                                                                              lang.getText(
                                                                                "cancel",
                                                                              ),
                                                                              style: const TextStyle(
                                                                                color: Colors.white54,
                                                                                fontSize: 16,
                                                                                fontWeight: FontWeight.bold,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          FilledButton(
                                                                            onPressed: () => Navigator.pop(
                                                                              context,
                                                                              true,
                                                                            ),
                                                                            style: FilledButton.styleFrom(
                                                                              backgroundColor: Colors.redAccent,
                                                                              shape: RoundedRectangleBorder(
                                                                                borderRadius: BorderRadius.circular(
                                                                                  12,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                            child: Text(
                                                                              lang.getText(
                                                                                "delete",
                                                                              ),
                                                                              style: const TextStyle(
                                                                                color: Colors.white,
                                                                                fontWeight: FontWeight.bold,
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

                                                            if (confirmed ==
                                                                true) {
                                                              final success =
                                                                  await deleteUserWorkoutTemplate(
                                                                    template.id,
                                                                  );
                                                              if (success) {
                                                                setState(() {
                                                                  templates
                                                                      .removeAt(
                                                                        index,
                                                                      );
                                                                });
                                                                if (context
                                                                    .mounted) {
                                                                  CustomSnackbar.show(
                                                                    context,
                                                                    lang.getText(
                                                                      "deleted_successfully",
                                                                    ),
                                                                    backgroundColor:
                                                                        workoutColorCode,
                                                                  );
                                                                }
                                                              }
                                                            }
                                                          },
                                                          child: Text(
                                                            lang.getText(
                                                              "delete",
                                                            ),
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .redAccent,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
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

                            FutureBuilder<List<CustomUserWorkoutDto>>(
                              future: futureOfficialWorkouts,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.amber,
                                    ),
                                  );
                                }
                                if (snapshot.hasError) {
                                  return Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(
                                      "Hiba: ${snapshot.error}",
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  );
                                }
                                final templates = snapshot.data ?? [];
                                if (templates.isEmpty) {
                                  return const Center(
                                    child: Text(
                                      "Jelenleg nincs hivatalos sablon.",
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  );
                                }

                                return ListView.builder(
                                  padding: const EdgeInsets.only(top: 8),
                                  shrinkWrap: true,
                                  itemCount: templates.length,
                                  itemBuilder: (context, index) {
                                    final template = templates[index];
                                    return GestureDetector(
                                      onTap: () async {
                                        final result =
                                            await showModalBottomSheet<bool>(
                                              context: context,
                                              builder: (context) =>
                                                  WorkoutTemplateDrawer(
                                                    template,
                                                    userWorkouts,
                                                  ),
                                            );
                                        if (result == true) setState(() {});
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 6,
                                        ),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: const Color.fromARGB(
                                              255,
                                              30,
                                              30,
                                              30,
                                            ),
                                            border: Border.all(
                                              color: Colors.amber.withOpacity(
                                                0.3,
                                              ),
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.star,
                                                    color: Colors.amber,
                                                    size: 22,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      template.customName,
                                                      style: const TextStyle(
                                                        color: Colors.amber,
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
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
                                    );
                                  },
                                );
                              },
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
                            if (result != null && result.isNotEmpty) {
                              if (isOnlineMode && currentSessionId != null) {
                                for (var ex in result) {
                                  WebSocketService().sendAction(
                                    'add-exercise',
                                    {'exerciseId': ex.id},
                                  );
                                }
                              } else {
                                setState(() {
                                  userWorkouts.addAll(result);
                                });
                                _saveDraft();
                              }
                            }
                          },
                        ),
                      ),

                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          iconData: Icons.skip_next,
                          title: isOnlineMode
                              ? (currentGameState != null &&
                                        currentGameState!['status'] == "Running"
                                    ? lang.getText("continue_workout")
                                    : lang.getText("start"))
                              : (workoutProvider.isWorkoutActive
                                    ? lang.getText("continue_workout")
                                    : lang.getText("start")),
                          variant: CustomButtonVariant.primaryWorkout,
                          onPressed: () async {
                            if (isOnlineMode) {
                              if (currentGameState != null &&
                                  currentGameState!['status'] == "Running") {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        SharedRunningWorkoutPage(
                                          userWorkouts: userWorkouts,
                                          initialGameState: currentGameState!,
                                        ),
                                  ),
                                ).then((result) {
                                  _setupWebSocketListeners();

                                  if (result != null &&
                                      result is Map &&
                                      result['status'] == 'finished') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            SharedWorkoutSummaryPage(
                                              finalState: result['data'],
                                              userWorkouts: userWorkouts,
                                              isHost: isHost,
                                            ),
                                      ),
                                    ).then((_) {
                                      if (mounted)
                                        setState(() {
                                          currentGameState = null;
                                        });
                                    });
                                  } else {
                                    if (isOnlineMode &&
                                        currentSessionId != null) {
                                      WebSocketService().sendAction(
                                        'get-workout-state',
                                        {},
                                      );
                                    }
                                    if (mounted) setState(() {});
                                  }
                                });
                              } else {
                                if (isHost) {
                                  WebSocketService().sendAction(
                                    'start-shared-workout',
                                    {},
                                  );
                                } else {
                                  CustomSnackbar.show(
                                    context,
                                    lang.getText("only_host_can_start"),
                                    backgroundColor: Colors.orange,
                                  );
                                }
                              }
                            } else {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.remove('draft_workout');
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RunningWorkoutPage(
                                    userWorkouts: userWorkouts,
                                  ),
                                ),
                              );
                            }
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
                            if (result != null && result.isNotEmpty) {
                              if (isOnlineMode && currentSessionId != null) {
                                for (var ex in result) {
                                  WebSocketService().sendAction(
                                    'add-exercise',
                                    {'exerciseId': ex.id},
                                  );
                                }
                              } else {
                                setState(() {
                                  userWorkouts.addAll(result);
                                });
                                _saveDraft();
                              }
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
