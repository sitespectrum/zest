import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nfc_host_card_emulation/nfc_host_card_emulation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:client/constants.dart';
import 'package:client/components/ui/custom_snackbar.dart';
import 'package:flutter/services.dart';
import 'package:client/components/ui/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:provider/provider.dart';
import 'package:client/components/ui/custom_button.dart';
import 'package:client/components/ui/custom_drawer.dart';
import 'package:client/providers/language_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:geolocator/geolocator.dart';

part "host_session_drawer.g.dart";

@hwidget
Widget hostSessionDrawer(BuildContext context) {
  final lang = Provider.of<LanguageProvider>(context, listen: false);
  final nameController = useTextEditingController();
  final sessionController = useTextEditingController();
  final isPublic = useState<bool>(true);

  final shareId = useState<String>("");
  final isSessionCreated = useState<bool>(false);
  final isLoading = useState<bool>(false);

  final isNfcActive = useState<bool>(false);

  final isCreated = useState<bool>(false);

  final participants = useState<List<dynamic>>([]);

  final tabController = useTabController(initialLength: 2);

  Future<void> fetchParticipants() async {
    if (shareId.value.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final response = await http.get(
        Uri.parse("$apiUrl/api/WorkoutSession/${shareId.value}/participants"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        participants.value = jsonDecode(response.body);
      } else {
        if (context.mounted) {
          CustomSnackbar.show(
            context,
            "Szerver hiba a lekérésnél: ${response.body}",
            backgroundColor: Colors.red,
          );
        }
      }
    } catch (e) {
      debugPrint("Hiba a résztvevők lekérésekor: $e");
    }
  }

  useEffect(() {
    Timer? timer;
    if (isSessionCreated.value && shareId.value.isNotEmpty) {
      fetchParticipants();
      timer = Timer.periodic(const Duration(seconds: 1), (_) {
        fetchParticipants();
      });
    }
    return () => timer?.cancel();
  }, [isSessionCreated.value, shareId.value]);

  Future<void> stopSession() async {
    if (shareId.value.isEmpty) return;

    isLoading.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      final response = await http.delete(
        Uri.parse("$apiUrl/api/WorkoutSession/${shareId.value}"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        if (isNfcActive.value) {
          await NfcHce.removeApduResponse(0);
        }
        isCreated.value = false;

        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('active_session_id');

        if (context.mounted) {
          CustomSnackbar.show(
            context,
            lang.getText("session_stopped"),
            backgroundColor: Colors.green,
          );
          Navigator.pop(context);
        }
      } else {
        if (context.mounted) {
          CustomSnackbar.show(
            context,
            "Szerver hiba a törlésnél: ${response.body}",
            backgroundColor: Colors.red,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackbar.show(
          context,
          "Hiba a leállításkor: $e",
          backgroundColor: Colors.red,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  useEffect(() {
    Future<void> loadSavedSession() async {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString('active_session_id');

      if (savedId != null && savedId.isNotEmpty) {
        shareId.value = savedId;
        sessionController.text = savedId;
        isCreated.value = true;
        isSessionCreated.value = true;
        tabController.animateTo(0);
      }
    }

    loadSavedSession();
    return null;
  }, []);

  useEffect(() {
    void listener() {
      if (tabController.index == 1 && !isSessionCreated.value) {
        tabController.index = 0;
        CustomSnackbar.show(
          context,
          lang.getText("create_session_first"),
          backgroundColor: Colors.red,
        );
      }
    }

    tabController.addListener(listener);
    return () => tabController.removeListener(listener);
  }, [isSessionCreated.value]);

  Future<void> createSession() async {
    if (nameController.text.trim().isEmpty) {
      CustomSnackbar.show(
        context,
        lang.getText("name_the_template"),
        backgroundColor: Colors.red,
      );
      return;
    }
    isCreated.value = true;
    isLoading.value = true;
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        CustomSnackbar.show(
          context,
          "A helymeghatározás szükséges a megosztáshoz!",
          backgroundColor: Colors.red,
        );
        isLoading.value = false;
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      final response = await http.post(
        Uri.parse("$apiUrl/api/WorkoutSession/create"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "name": nameController.text.trim(),
          "isPublic": isPublic.value,
          "latitude": position.latitude,
          "longitude": position.longitude,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final sid = data['sessionId'] ?? data['SessionId'] ?? "";
        shareId.value = sid.toString().trim();
        sessionController.text = shareId.value;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('active_session_id', shareId.value);

        isCreated.value = true;
        isSessionCreated.value = true;
        tabController.animateTo(1);
      } else {
        throw Exception("Szerver hiba: ${response.statusCode}");
      }
    } catch (e) {
      CustomSnackbar.show(
        context,
        "Hiba a létrehozáskor: $e",
        backgroundColor: Colors.red,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleNfc() async {
    if (shareId.value.isEmpty) return;

    if (isNfcActive.value) {
      isNfcActive.value = false;
      await NfcHce.removeApduResponse(0);
      if (context.mounted) {
        CustomSnackbar.show(
          context,
          lang.getText("nfc_stopped"),
          backgroundColor: Colors.orange,
        );
      }
    } else {
      isNfcActive.value = true;
      final nfcState = await NfcHce.checkDeviceNfcState();

      if (nfcState == NfcState.enabled) {
        await NfcHce.addApduResponse(0, utf8.encode(shareId.value));
        if (context.mounted) {
          CustomSnackbar.show(
            context,
            lang.getText("nfc_started"),
            backgroundColor: Colors.green,
          );
        }
      } else {
        isNfcActive.value = false;
        if (context.mounted) {
          CustomSnackbar.show(
            context,
            lang.getText("nfc_not_supported"),
            backgroundColor: Colors.red,
          );
        }
      }
    }
  }

  return Container(
    decoration: const BoxDecoration(
      color: Color.fromARGB(255, 30, 30, 30),
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    child: CustomDrawer(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.5,
        child: Column(
          spacing: 12,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(50, 64, 255, 50),
                      border: Border.all(
                        color: const Color.fromARGB(100, 64, 255, 50),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TabBar(
                      controller: tabController,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                      splashFactory: NoSplash.splashFactory,
                      indicator: BoxDecoration(
                        color: const Color.fromARGB(100, 64, 255, 50),
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorPadding: const EdgeInsets.all(4),
                      dividerHeight: 0,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.green,
                      tabs: [
                        Tab(text: lang.getText("create")),
                        Tab(text: lang.getText("share")),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: TabBarView(
                        controller: tabController,
                        physics: isSessionCreated.value
                            ? const AlwaysScrollableScrollPhysics()
                            : const NeverScrollableScrollPhysics(),
                        children: [
                          isCreated.value
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 0,
                                    vertical: 5,
                                  ),
                                  child: Column(
                                    spacing: 12,
                                    children: [
                                      Container(
                                        height:
                                            MediaQuery.of(context).size.height *
                                            0.2,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF272727),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: Colors.white24,
                                            width: 1,
                                          ),
                                        ),
                                        child: participants.value.isEmpty
                                            ? const Center(
                                                child: Text(
                                                  "Még senki sem csatlakozott...",
                                                  style: TextStyle(
                                                    color: Colors.white54,
                                                  ),
                                                ),
                                              )
                                            : RefreshIndicator(
                                                onRefresh: fetchParticipants,
                                                color: Colors.green,
                                                backgroundColor: const Color(
                                                  0xFF272727,
                                                ),
                                                child: ListView.builder(
                                                  padding: const EdgeInsets.all(
                                                    8,
                                                  ),
                                                  itemCount:
                                                      participants.value.length,
                                                  itemBuilder: (context, index) {
                                                    final p = participants
                                                        .value[index];
                                                    final isHost =
                                                        p['role'] == "Host" ||
                                                        p['role'] == 0;

                                                    return ListTile(
                                                      dense: true,
                                                      leading: Icon(
                                                        isHost
                                                            ? Icons.star
                                                            : Icons.person,
                                                        color: isHost
                                                            ? Colors.amber
                                                            : Colors.blueAccent,
                                                      ),
                                                      title: Text(
                                                        p['userName'] ??
                                                            'Ismeretlen',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      subtitle: Text(
                                                        isHost
                                                            ? 'Host'
                                                            : 'Vendég',
                                                        style: const TextStyle(
                                                          color: Colors.white54,
                                                        ),
                                                      ),
                                                      trailing: isHost
                                                          ? null
                                                          : Icon(
                                                              p['isReady'] ==
                                                                      true
                                                                  ? Icons
                                                                        .check_circle
                                                                  : Icons
                                                                        .hourglass_empty,
                                                              color:
                                                                  p['isReady'] ==
                                                                      true
                                                                  ? Colors.green
                                                                  : Colors
                                                                        .orange,
                                                              size: 20,
                                                            ),
                                                    );
                                                  },
                                                ),
                                              ),
                                      ),

                                      const Spacer(),

                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: CustomButton(
                                              onPressed: stopSession,
                                              variant: CustomButtonVariant
                                                  .primaryWorkout,
                                              title: lang.getText(
                                                "stop_session",
                                              ),
                                              iconData: Icons.stop,
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Expanded(
                                            child: CustomButton(
                                              onPressed: () {},
                                              variant: CustomButtonVariant
                                                  .primaryWorkout,
                                              title: lang.getText("start"),
                                              iconData: Icons.skip_next,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                )
                              : Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 0,
                                    vertical: 5,
                                  ),
                                  child: Column(
                                    spacing: 12,
                                    children: [
                                      CustomTextField(
                                        nameController,
                                        lang.getText("jam_name"),
                                        isCreateWorkout: true,
                                      ),
                                      Container(
                                        height: 45,
                                        width:
                                            MediaQuery.of(context).size.width *
                                            0.6,
                                        decoration: BoxDecoration(
                                          color: const Color.fromARGB(
                                            50,
                                            50,
                                            146,
                                            255,
                                          ),
                                          border: Border.all(
                                            color: const Color.fromARGB(
                                              100,
                                              50,
                                              146,
                                              255,
                                            ),
                                            width: 1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () =>
                                                    isPublic.value = true,
                                                behavior:
                                                    HitTestBehavior.opaque,
                                                child: AnimatedContainer(
                                                  duration: const Duration(
                                                    milliseconds: 200,
                                                  ),
                                                  margin: const EdgeInsets.all(
                                                    4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: isPublic.value
                                                        ? const Color.fromARGB(
                                                            100,
                                                            50,
                                                            146,
                                                            255,
                                                          )
                                                        : Colors.transparent,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    lang.getText("public"),
                                                    style: TextStyle(
                                                      color: isPublic.value
                                                          ? Colors.white
                                                          : Colors.grey,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () =>
                                                    isPublic.value = false,
                                                behavior:
                                                    HitTestBehavior.opaque,
                                                child: AnimatedContainer(
                                                  duration: const Duration(
                                                    milliseconds: 200,
                                                  ),
                                                  margin: const EdgeInsets.all(
                                                    4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: !isPublic.value
                                                        ? const Color.fromARGB(
                                                            100,
                                                            50,
                                                            146,
                                                            255,
                                                          )
                                                        : Colors.transparent,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    lang.getText("private"),
                                                    style: TextStyle(
                                                      color: !isPublic.value
                                                          ? Colors.white
                                                          : Colors.grey,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const Spacer(),

                                      CustomButton(
                                        onPressed: createSession,
                                        variant:
                                            CustomButtonVariant.primaryWorkout,
                                        title: lang.getText("create"),
                                        iconData: Icons.cast,
                                      ),
                                    ],
                                  ),
                                ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 5,
                            ),
                            child: Column(
                              spacing: 24,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: AspectRatio(
                                        aspectRatio: 1,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          child: IconButton(
                                            style: IconButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              backgroundColor:
                                                  const Color.fromARGB(
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
                                            onPressed: toggleNfc,
                                            icon: const Icon(
                                              Icons.contactless_rounded,
                                            ),
                                            color: Colors.white70,
                                            iconSize:
                                                MediaQuery.of(
                                                  context,
                                                ).size.width *
                                                0.25,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: AspectRatio(
                                        aspectRatio: 1,
                                        child: Container(
                                          alignment: Alignment.center,
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withAlpha(25),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            border: Border.all(
                                              color: Colors.white.withAlpha(50),
                                            ),
                                          ),
                                          child: shareId.value.isNotEmpty
                                              ? QrImageView(
                                                  data: shareId.value,
                                                  version: QrVersions.auto,
                                                  dataModuleStyle:
                                                      const QrDataModuleStyle(
                                                        color: Colors.white,
                                                        dataModuleShape:
                                                            QrDataModuleShape
                                                                .square,
                                                      ),
                                                  eyeStyle: const QrEyeStyle(
                                                    color: Colors.white,
                                                    eyeShape: QrEyeShape.square,
                                                  ),
                                                )
                                              : Column(
                                                  spacing: 12,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.qr_code,
                                                      size: 64,
                                                      color: Colors.white38,
                                                    ),
                                                    Text(
                                                      lang.getText(
                                                        "no_qr_code_yet",
                                                      ),
                                                      style: const TextStyle(
                                                        color: Colors.white38,
                                                        fontSize: 14,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ],
                                                ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                TextField(
                                  controller: sessionController,
                                  readOnly: true,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    letterSpacing: 4.0,
                                  ),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: const Color(0xFF272727),
                                    labelText: "Session ID",
                                    labelStyle: const TextStyle(
                                      color: Colors.white54,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: Colors.white24,
                                        width: 1,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: Colors.white24,
                                        width: 1,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: Colors.white24,
                                        width: 1,
                                      ),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: const Icon(
                                        Icons.copy,
                                        color: Colors.white54,
                                      ),
                                      onPressed: () async {
                                        await Clipboard.setData(
                                          ClipboardData(
                                            text: sessionController.text,
                                          ),
                                        );

                                        if (context.mounted) {
                                          CustomSnackbar.show(
                                            context,
                                            lang.getText("copied_to_clipboard"),
                                            backgroundColor: Colors.green,
                                          );
                                        }
                                      },
                                    ),
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
          ],
        ),
      ),
    ),
  );
}
