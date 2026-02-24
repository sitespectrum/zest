import 'dart:convert';
import 'package:http/http.dart' as http;
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

  final tabController = useTabController(initialLength: 2);
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
        shareId.value = data['sessionId'];
        sessionController.text = shareId.value;
        isSessionCreated.value = true;

        // Automatikus átváltás a QR kód / NFC fülre!
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
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          Padding(
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
                                      MediaQuery.of(context).size.width * 0.6,
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
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => isPublic.value = true,
                                          behavior: HitTestBehavior.opaque,
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            margin: const EdgeInsets.all(4),
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
                                                  BorderRadius.circular(16),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              lang.getText("public"),
                                              style: TextStyle(
                                                color: isPublic.value
                                                    ? Colors.white
                                                    : Colors.grey,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => isPublic.value = false,
                                          behavior: HitTestBehavior.opaque,
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            margin: const EdgeInsets.all(4),
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
                                                  BorderRadius.circular(16),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              lang.getText("private"),
                                              style: TextStyle(
                                                color: !isPublic.value
                                                    ? Colors.white
                                                    : Colors.grey,
                                                fontWeight: FontWeight.bold,
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
                                  variant: CustomButtonVariant.primaryWorkout,
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
                                            onPressed: () {},
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
