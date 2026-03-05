import 'dart:async' show StreamController;
import 'dart:convert';
import 'package:client/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  Function(dynamic)? onMessageReceived;
  bool isConnected = false;

  int? _myUserId;

  final ValueNotifier<String?> activeSessionNotifier = ValueNotifier<String?>(
    null,
  );

  final StreamController<dynamic> _messageController =
      StreamController<dynamic>.broadcast();
  Stream<dynamic> get messageStream => _messageController.stream;

  Future<void> connect(String sessionId) async {
    if (isConnected) return;

    final prefs = await SharedPreferences.getInstance();
    int myUserId = prefs.getInt('userId') ?? 0;

    if (myUserId == 0) {
      final token = prefs.getString('jwt_token');
      if (token != null) {
        try {
          final parts = token.split('.');
          if (parts.length >= 2) {
            String normalized = base64Url.normalize(parts[1]);
            final payloadStr = utf8.decode(base64Url.decode(normalized));
            final payload = jsonDecode(payloadStr);
            myUserId =
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
          debugPrint("Hiba a token dekódolásánál: $e");
        }
      }
    }

    _myUserId = myUserId;

    String wsUrl = apiUrl.contains('https')
        ? apiUrl.replaceFirst('https', 'wss') +
              '/api/WorkoutSession/ws/$sessionId/$_myUserId'
        : apiUrl.replaceFirst('http', 'ws') +
              '/api/WorkoutSession/ws/$sessionId/$_myUserId';

    debugPrint("🌐 Csatlakozás a WebSockethez: $wsUrl");

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      isConnected = true;

      _channel!.stream.listen(
        (message) async {
          final decodedMessage = jsonDecode(message);

          _messageController.add(decodedMessage);

          if (onMessageReceived != null) {
            onMessageReceived!(decodedMessage);
          }
          if (decodedMessage['type'] == 'user-kicked') {
            final kickedId = decodedMessage['kickedUserId'];

            if (kickedId == _myUserId) {
              debugPrint("🔴 Kidobtak a sessionből, kilépés folyamatban...");
              await forceLeaveSession();
            }
          }
        },
        onDone: () {
          isConnected = false;
        },
        onError: (e) {
          isConnected = false;
        },
      );
    } catch (e) {
      isConnected = false;
    }
  }

  void sendAction(String type, dynamic data) {
    if (_channel != null && isConnected) {
      _channel!.sink.add(jsonEncode({"type": type, "data": data}));
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    isConnected = false;
    activeSessionNotifier.value = null;
  }

  Future<void> forceLeaveSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('active_session_id');
    final token = prefs.getString('jwt_token');

    if (savedId != null && token != null) {
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

    disconnect();
  }
}
