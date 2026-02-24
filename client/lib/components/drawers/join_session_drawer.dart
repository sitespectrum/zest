import 'dart:convert';
import 'package:client/constants.dart';
import 'package:client/providers/language_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:client/components/ui/custom_button.dart';
import 'package:client/components/ui/custom_drawer.dart';
import 'package:client/components/ui/custom_textfield.dart';
import 'package:client/components/ui/custom_snackbar.dart';

part 'join_session_drawer.g.dart';

@hwidget
Widget joinSessionDrawer(BuildContext context) {
  final lang = Provider.of<LanguageProvider>(context);
  final controller = useTextEditingController(text: "");
  final nearbySessions = useState<List<dynamic>>([]);
  final isLoading = useState(false);

  final tabController = useTabController(initialLength: 2);

  Future<void> fetchNearbySessions() async {
    isLoading.value = true;
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        isLoading.value = false;
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      final response = await http.get(
        Uri.parse(
          '$apiUrl/api/WorkoutSession/nearby?lat=${position.latitude}&lon=${position.longitude}&radiusKm=50',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        nearbySessions.value = jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint("Hiba a közeli edzések lekérésekor: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> joinSession(String sessionId) async {
    if (sessionId.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      final response = await http.post(
        Uri.parse('$apiUrl/api/WorkoutSession/join'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'SessionId': sessionId}),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context);
        CustomSnackbar.show(
          context,
          "Sikeres csatlakozás!",
          backgroundColor: Colors.green,
        );
        // későbbi navigáció
      } else {
        CustomSnackbar.show(
          context,
          "Hiba: ${response.body}",
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      CustomSnackbar.show(
        context,
        "Hálózati hiba: $e",
        backgroundColor: Colors.red,
      );
    }
  }

  useEffect(() {
    void listener() {
      if (tabController.index == 0) {
        fetchNearbySessions();
      }
    }

    tabController.addListener(listener);
    if (tabController.index == 0) fetchNearbySessions();
    return () => tabController.removeListener(listener);
  }, [tabController]);

  return Container(
    decoration: const BoxDecoration(
      color: Color.fromARGB(255, 30, 30, 30),
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    child: CustomDrawer(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          spacing: 12,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  lang.getText("join"),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

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
                  Tab(text: lang.getText("nearby")),
                  Tab(text: lang.getText("join")),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: tabController,
                children: [
                  isLoading.value
                      ? const Center(child: CircularProgressIndicator())
                      : nearbySessions.value.isEmpty
                      ? Center(
                          child: Text(
                            "Nincs elérhető edzés a közelben.",
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                      : ListView.builder(
                          itemCount: nearbySessions.value.length,
                          itemBuilder: (context, index) {
                            final session = nearbySessions.value[index];
                            return GestureDetector(
                              onTap: () {
                                controller.text = session['sessionId']
                                    .toString()
                                    .replaceFirst("ZJ-", "");
                                tabController.animateTo(1);
                              },
                              child: Card(
                                color: Colors.white.withOpacity(0.05),
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.fitness_center,
                                    color: Colors.green,
                                  ),
                                  title: Text(
                                    session['name'] ??
                                        lang.getText("unknown"),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "${session['distanceKm']} km",
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.circle,
                                        size: 4,
                                        color: Colors.white30,
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.people_rounded,
                                        size: 18,
                                        color: Colors.white70,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${session['participantCount']}",
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.white54,
                                    size: 16,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      spacing: 24,
                      children: [
                        Flex(
                          direction: Axis.horizontal,
                          spacing: 24,
                          children: [
                            Expanded(
                              flex: 1,
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(
                                      50,
                                      50,
                                      146,
                                      255,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color.fromARGB(
                                        150,
                                        50,
                                        146,
                                        255,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        Icons.nfc,
                                        color: Colors.white,
                                        size: 36,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        "NFC",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(
                                      50,
                                      50,
                                      146,
                                      255,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color.fromARGB(
                                        180,
                                        50,
                                        146,
                                        255,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        Icons.qr_code,
                                        color: Colors.white,
                                        size: 36,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        "QR",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        customTextField(
                          context,
                          controller,
                          "Session ID",
                          isNumber: false,
                          isUpperCase: true,
                          fixedPrefix: "ZJ-",
                          prefixIcon: Icons.vpn_key_rounded,
                          isCreateWorkout: true,
                        ),

                        SizedBox(
                          width: double.infinity,
                          child: CustomButton(
                            onPressed: () =>
                                joinSession("ZJ-${controller.text}"),
                            title: lang.getText("join"),
                            iconData: Icons.login_rounded,
                            variant: CustomButtonVariant.primaryWorkout,
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
  );
}
