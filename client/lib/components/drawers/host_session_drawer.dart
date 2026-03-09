import 'dart:async';
import 'dart:convert';
import 'package:client/components/friend_profile_page.dart';
import 'package:client/services/websocket_service.dart';
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
  final isHost = useState<bool>(true);

  final participants = useState<List<dynamic>>([]);
  final lastResponse = useState<String>("");
  final myUserName = useState<String>("");
  final myUserId = useState<int>(0);
  final tabController = useTabController(initialLength: 2);
  final friends = useState<List<dynamic>>([]);

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<void> fetchFriends() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse("$apiUrl/api/Friends/list"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        if (context.mounted) {
          friends.value = jsonDecode(response.body);
        }
      }
    } catch (e) {
      debugPrint("Hiba a barátok lekérésekor: $e");
    }
  }

  useEffect(() {
    fetchFriends();
    return null;
  }, []);

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
        if (context.mounted) {
          if (lastResponse.value != response.body) {
            lastResponse.value = response.body;
            participants.value = jsonDecode(response.body);
          }
        }
      } else {
        if (context.mounted) {
          CustomSnackbar.show(
            context,
            "${lang.getText("error")} ${response.body}",
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

        await prefs.remove('active_session_id');

        WebSocketService().activeSessionNotifier.value = null;
        WebSocketService().disconnect();

        if (context.mounted) {
          CustomSnackbar.show(
            context,
            lang.getText("session_stopped"),
            backgroundColor: Colors.green,
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackbar.show(
          context,
          "${lang.getText("error")} $e",
          backgroundColor: Colors.red,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> leaveSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('active_session_id');
    final token = prefs.getString('jwt_token');

    if (savedId != null && savedId.isNotEmpty && token != null) {
      try {
        await http.post(
          Uri.parse('$apiUrl/api/WorkoutSession/leave'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'SessionId': savedId}),
        );
      } catch (e) {
        debugPrint("Hiba a szerver felé történő kilépéskor: $e");
      }
    }

    await prefs.remove('active_session_id');
    await prefs.remove('is_host');

    WebSocketService().activeSessionNotifier.value = null;
    WebSocketService().disconnect();

    if (context.mounted) {
      CustomSnackbar.show(
        context,
        lang.getText("you_left_the_session"),
        backgroundColor: Colors.blue,
      );
      Navigator.pop(context);
    }
  }

  useEffect(() {
    StreamSubscription? subscription;

    if (isSessionCreated.value && shareId.value.isNotEmpty) {
      subscription = WebSocketService().messageStream.listen((data) async {
        if (data['type'] == 'user-kicked') {
          final kickedId = data['kickedUserId'];

          if (kickedId == myUserId.value) {
            leaveSession();
          } else {
            fetchParticipants();
          }
        } else if (data['type'] == 'promoted-to-host') {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_host', true);
          isHost.value = true;

          if (context.mounted) {
            CustomSnackbar.show(
              context,
              "Te lettél az új Host!",
              backgroundColor: Colors.green,
            );
          }
          fetchParticipants();
        } else if (data['type'] == 'sync-workout-state') {
          final hostId = data['data']['hostId'];
          bool amIHost = hostId == myUserId.value;
          if (isHost.value != amIHost) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('is_host', amIHost);
            isHost.value = amIHost;
          }
          fetchParticipants();
        }
      });
    }

    return () => subscription?.cancel();
  }, [isSessionCreated.value, shareId.value, myUserId.value]);

  useEffect(() {
    Future<void> loadSavedSession() async {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('jwt_token');
      if (token != null && token.isNotEmpty) {
        try {
          final parts = token.split('.');
          if (parts.length >= 2) {
            String normalized = base64Url.normalize(parts[1]);
            final payloadStr = utf8.decode(base64Url.decode(normalized));
            final payload = jsonDecode(payloadStr);
            myUserName.value =
                payload['unique_name'] ??
                payload['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name'] ??
                payload['name'] ??
                payload['sub'] ??
                '';
            myUserId.value =
                int.tryParse(
                  payload['nameid']?.toString() ??
                      payload['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier']
                          ?.toString() ??
                      payload['sub']?.toString() ??
                      '0',
                ) ??
                0;
          }
        } catch (e) {
          debugPrint("Token dekódolási hiba: $e");
        }
      }

      final savedId = prefs.getString('active_session_id');

      if (savedId != null && savedId.isNotEmpty) {
        shareId.value = savedId;
        sessionController.text = savedId;
        isCreated.value = true;
        isSessionCreated.value = true;
        isHost.value = prefs.getBool('is_host') ?? false;
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

  Future<void> kickUser(int targetUserId, String targetUserName) async {
    if (shareId.value.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      final response = await http.delete(
        Uri.parse(
          "$apiUrl/api/WorkoutSession/${shareId.value}/kick/$targetUserId",
        ),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        if (context.mounted) {
          CustomSnackbar.show(
            context,
            "$targetUserName kirúgva!",
            backgroundColor: Colors.green,
          );
          fetchParticipants();
        }
      } else {
        if (context.mounted) {
          CustomSnackbar.show(
            context,
            "Hiba a kirúgáskor: ${response.body}",
            backgroundColor: Colors.red,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackbar.show(
          context,
          "${lang.getText("error")} $e",
          backgroundColor: Colors.red,
        );
      }
    }
  }

  Future<void> inviteFriend(int friendId, String friendName) async {
    if (shareId.value.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      final response = await http.post(
        Uri.parse(
          "$apiUrl/api/WorkoutSession/${shareId.value}/invite/$friendId",
        ),
        headers: {"Authorization": "Bearer $token"},
      );

      debugPrint("🚀 MEGHÍVÁS HTTP KÓD: ${response.statusCode}");
      debugPrint("🚀 MEGHÍVÁS VÁLASZ BODY: ${response.body}");

      if (response.statusCode == 200) {
        if (context.mounted) {
          CustomSnackbar.show(
            context,
            "Meghívó elküldve $friendName számára!",
            backgroundColor: Colors.green,
          );
        }
      } else {
        if (context.mounted) {
          CustomSnackbar.show(
            context,
            "Hiba a meghíváskor: ${response.body}",
            backgroundColor: Colors.red,
          );
        }
      }
    } catch (e) {
      debugPrint("Hiba a meghívás küldésekor: $e");
    }
  }

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
          lang.getText("location_needed"),
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

        await prefs.setString('active_session_id', shareId.value);
        await prefs.setBool('is_host', true);

        WebSocketService().activeSessionNotifier.value = shareId.value;
        WebSocketService().connect(shareId.value);

        isCreated.value = true;
        isSessionCreated.value = true;
        tabController.animateTo(1);
      }
    } catch (e) {
      CustomSnackbar.show(
        context,
        "${lang.getText("error")} $e",
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
                              ? Column(
                                  spacing: 12,
                                  children: [
                                    Expanded(
                                      child: Container(
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

                                                    final roleVal =
                                                        p['role'] ?? p['Role'];
                                                    final isParticipantHost =
                                                        roleVal == "Host" ||
                                                        roleVal == 0 ||
                                                        roleVal == "0";
                                                    final userName =
                                                        p['userName'] ??
                                                        p['UserName'] ??
                                                        'Ismeretlen';
                                                    final userId =
                                                        p['userId'] ??
                                                        p['UserId'] ??
                                                        0;

                                                    bool isMe =
                                                        p['isMe'] == true ||
                                                        p['isMe'] == 'true' ||
                                                        p['IsMe'] == true ||
                                                        p['IsMe'] == 'true';

                                                    if (isHost.value &&
                                                        isParticipantHost) {
                                                      isMe = true;
                                                    }

                                                    if (myUserName
                                                            .value
                                                            .isNotEmpty &&
                                                        userName
                                                                .toLowerCase() ==
                                                            myUserName.value
                                                                .toLowerCase()) {
                                                      isMe = true;
                                                    }

                                                    final profilePicData =
                                                        p['profilePicture'] ??
                                                        p['ProfilePicture'];
                                                    final hasProfilePic =
                                                        profilePicData !=
                                                            null &&
                                                        profilePicData
                                                            .toString()
                                                            .trim()
                                                            .isNotEmpty;

                                                    Uint8List? imageBytes;
                                                    if (hasProfilePic) {
                                                      try {
                                                        String cleanBase64 =
                                                            profilePicData
                                                                .toString();
                                                        if (cleanBase64
                                                            .contains(',')) {
                                                          cleanBase64 =
                                                              cleanBase64
                                                                  .split(',')
                                                                  .last;
                                                        }
                                                        cleanBase64 =
                                                            cleanBase64
                                                                .replaceAll(
                                                                  RegExp(
                                                                    r'\s+',
                                                                  ),
                                                                  '',
                                                                );
                                                        imageBytes =
                                                            base64Decode(
                                                              cleanBase64,
                                                            );
                                                      } catch (e) {
                                                        imageBytes = null;
                                                      }
                                                    }

                                                    var tapPosition =
                                                        Offset.zero;

                                                    return GestureDetector(
                                                      onTapDown: isMe
                                                          ? null
                                                          : (
                                                              details,
                                                            ) => tapPosition =
                                                                details
                                                                    .globalPosition,
                                                      onTap: isMe
                                                          ? null
                                                          : () async {
                                                              List<
                                                                PopupMenuEntry<
                                                                  String
                                                                >
                                                              >
                                                              menuItems = [
                                                                PopupMenuItem(
                                                                  value:
                                                                      'profile',
                                                                  child: Row(
                                                                    children: [
                                                                      const Icon(
                                                                        Icons
                                                                            .person,
                                                                        color: Colors
                                                                            .blueAccent,
                                                                      ),
                                                                      const SizedBox(
                                                                        width:
                                                                            12,
                                                                      ),
                                                                      Text(
                                                                        lang.getText(
                                                                          "view_profile",
                                                                        ),
                                                                        style: const TextStyle(
                                                                          color:
                                                                              Colors.white,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ];

                                                              if (isHost
                                                                      .value &&
                                                                  !isParticipantHost) {
                                                                menuItems.add(
                                                                  PopupMenuItem(
                                                                    value:
                                                                        'kick',
                                                                    child: Row(
                                                                      children: [
                                                                        const Icon(
                                                                          Icons
                                                                              .person_remove,
                                                                          color:
                                                                              Colors.redAccent,
                                                                        ),
                                                                        const SizedBox(
                                                                          width:
                                                                              12,
                                                                        ),
                                                                        Text(
                                                                          lang.getText(
                                                                            "kick_user",
                                                                          ),
                                                                          style: const TextStyle(
                                                                            color:
                                                                                Colors.white,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                );
                                                              }

                                                              final selectedValue = await showMenu<String>(
                                                                context:
                                                                    context,
                                                                color:
                                                                    const Color(
                                                                      0xFF333333,
                                                                    ),
                                                                elevation: 8,
                                                                shape: RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        16,
                                                                      ),
                                                                ),
                                                                position: RelativeRect.fromLTRB(
                                                                  tapPosition
                                                                      .dx,
                                                                  tapPosition
                                                                      .dy,
                                                                  MediaQuery.of(
                                                                        context,
                                                                      ).size.width -
                                                                      tapPosition
                                                                          .dx,
                                                                  MediaQuery.of(
                                                                        context,
                                                                      ).size.height -
                                                                      tapPosition
                                                                          .dy,
                                                                ),
                                                                items:
                                                                    menuItems,
                                                              );

                                                              if (selectedValue ==
                                                                  'profile') {
                                                                Navigator.push(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                    builder: (context) => FriendProfilePage(
                                                                      friendId:
                                                                          userId,
                                                                      friendName:
                                                                          userName,
                                                                      friendImage:
                                                                          profilePicData,
                                                                    ),
                                                                  ),
                                                                );
                                                                CustomSnackbar.show(
                                                                  context,
                                                                  "$userName ${lang.getText("someones_profile")}",
                                                                  backgroundColor:
                                                                      Colors
                                                                          .blue,
                                                                );
                                                              }
                                                              if (selectedValue ==
                                                                  'kick') {
                                                                kickUser(
                                                                  userId,
                                                                  userName,
                                                                );
                                                                CustomSnackbar.show(
                                                                  context,
                                                                  "$userName ${lang.getText("kicked")}",
                                                                  backgroundColor:
                                                                      Colors
                                                                          .red,
                                                                );
                                                              }
                                                            },
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                          color:
                                                              const Color.fromARGB(
                                                                255,
                                                                55,
                                                                55,
                                                                55,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                20,
                                                              ),
                                                        ),
                                                        margin:
                                                            const EdgeInsets.symmetric(
                                                              vertical: 5,
                                                            ),
                                                        child: ListTile(
                                                          dense: true,
                                                          leading: CircleAvatar(
                                                            backgroundColor:
                                                                Colors.green,
                                                            backgroundImage:
                                                                imageBytes !=
                                                                    null
                                                                ? MemoryImage(
                                                                    imageBytes,
                                                                  )
                                                                : null,
                                                            child:
                                                                imageBytes ==
                                                                    null
                                                                ? Icon(
                                                                    isParticipantHost
                                                                        ? Icons
                                                                              .star
                                                                        : Icons
                                                                              .person,
                                                                    color: Colors
                                                                        .white,
                                                                  )
                                                                : null,
                                                          ),
                                                          title: Text(
                                                            userName,
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                          ),
                                                          subtitle: Text(
                                                            isParticipantHost
                                                                ? lang.getText(
                                                                    "Host",
                                                                  )
                                                                : lang.getText(
                                                                    "guest",
                                                                  ),
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .white54,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                      ),
                                    ),

                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: CustomButton(
                                            onPressed: isHost.value
                                                ? stopSession
                                                : leaveSession,
                                            variant: CustomButtonVariant
                                                .primaryWorkout,
                                            title: isHost.value
                                                ? lang.getText("stop_session")
                                                : lang.getText("quit"),
                                            iconData: isHost.value
                                                ? Icons.stop
                                                : Icons.exit_to_app,
                                          ),
                                        ),

                                        if (isHost.value) ...[
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: CustomButton(
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (builder) => Dialog(
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
                                                    ),
                                                    child: Container(
                                                      height:
                                                          MediaQuery.of(
                                                            context,
                                                          ).size.height *
                                                          0.5,
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
                                                                "invite_friends",
                                                              ),
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 20,
                                                              ),
                                                            ),
                                                            SizedBox(height: 5),
                                                            Divider(
                                                              color: Colors
                                                                  .white24,
                                                              thickness: 2,
                                                            ),
                                                            SizedBox(height: 5),
                                                            Expanded(
                                                              child: Builder(
                                                                builder: (context) {
                                                                  final availableFriends = friends.value.where((
                                                                    friend,
                                                                  ) {
                                                                    final friendId =
                                                                        friend['id'] ??
                                                                        friend['userId'] ??
                                                                        friend['friendId'];

                                                                    bool
                                                                    isAlreadyIn = participants.value.any((
                                                                      p,
                                                                    ) {
                                                                      final pId =
                                                                          p['userId'] ??
                                                                          p['UserId'];
                                                                      return pId ==
                                                                          friendId;
                                                                    });

                                                                    return !isAlreadyIn;
                                                                  }).toList();

                                                                  if (availableFriends
                                                                      .isEmpty) {
                                                                    return Center(
                                                                      child: Text(
                                                                        "Minden barátod csatlakozott már!",
                                                                        style: TextStyle(
                                                                          color:
                                                                              Colors.white54,
                                                                        ),
                                                                      ),
                                                                    );
                                                                  }

                                                                  return ListView.builder(
                                                                    itemCount:
                                                                        availableFriends
                                                                            .length,
                                                                    itemBuilder:
                                                                        (
                                                                          context,
                                                                          index,
                                                                        ) {
                                                                          final friend =
                                                                              availableFriends[index];
                                                                          return Card(
                                                                            color: const Color.fromARGB(
                                                                              255,
                                                                              45,
                                                                              45,
                                                                              45,
                                                                            ),
                                                                            margin: const EdgeInsets.symmetric(
                                                                              horizontal: 5,
                                                                              vertical: 5,
                                                                            ),
                                                                            child: ListTile(
                                                                              leading: CircleAvatar(
                                                                                backgroundColor: Colors.green,
                                                                                backgroundImage:
                                                                                    (friend['profilePicture'] !=
                                                                                            null &&
                                                                                        friend['profilePicture'].toString().isNotEmpty)
                                                                                    ? MemoryImage(
                                                                                        base64Decode(
                                                                                          friend['profilePicture'],
                                                                                        ),
                                                                                      )
                                                                                    : null,
                                                                                child:
                                                                                    (friend['profilePicture'] ==
                                                                                            null ||
                                                                                        friend['profilePicture'].toString().isEmpty)
                                                                                    ? const Icon(
                                                                                        Icons.person,
                                                                                        color: Colors.white,
                                                                                      )
                                                                                    : null,
                                                                              ),
                                                                              title: Text(
                                                                                friend['userName'],
                                                                                style: const TextStyle(
                                                                                  color: Colors.white,
                                                                                  fontWeight: FontWeight.bold,
                                                                                ),
                                                                              ),
                                                                              trailing: IconButton(
                                                                                onPressed: () {
                                                                                  final friendId =
                                                                                      friend['id'] ??
                                                                                      friend['userId'] ??
                                                                                      friend['friendId'];
                                                                                  inviteFriend(
                                                                                    friendId,
                                                                                    friend['userName'],
                                                                                  );
                                                                                },
                                                                                icon: const Icon(
                                                                                  Icons.send,
                                                                                  color: Colors.blueAccent,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          );
                                                                        },
                                                                  );
                                                                },
                                                              ),
                                                            ),
                                                            CustomButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                    context,
                                                                  ),
                                                              variant:
                                                                  CustomButtonVariant
                                                                      .secondary,
                                                              iconData:
                                                                  Icons.close,
                                                              title: lang
                                                                  .getText(
                                                                    "close",
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                              variant: CustomButtonVariant
                                                  .primaryWorkout,
                                              title: lang.getText("invite"),
                                              iconData: Icons.person_add_alt_1,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                )
                              : Column(
                                  spacing: 12,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(top: 5),
                                      child: CustomTextField(
                                        nameController,
                                        lang.getText("jam_name"),
                                        isCreateWorkout: true,
                                      ),
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
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () =>
                                                  isPublic.value = true,
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
                                              onTap: () =>
                                                  isPublic.value = false,
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
                                      variant:
                                          CustomButtonVariant.primaryWorkout,
                                      title: lang.getText("create"),
                                      iconData: Icons.cast,
                                    ),
                                  ],
                                ),
                          Column(
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
                                                mainAxisSize: MainAxisSize.min,
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
                                                    textAlign: TextAlign.center,
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
