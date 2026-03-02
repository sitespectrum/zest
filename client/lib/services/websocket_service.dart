import 'dart:async' show StreamController;
import 'dart:convert';
import 'package:client/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  Function(dynamic)? onMessageReceived;
  bool isConnected = false;

  final ValueNotifier<String?> activeSessionNotifier = ValueNotifier<String?>(null);

  final StreamController<dynamic> _messageController = StreamController<dynamic>.broadcast();
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
            myUserId = int.tryParse(
                    payload['nameid']?.toString() ??
                    payload['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier']?.toString() ??
                    payload['sub']?.toString() ?? '0') ?? 0;
          }
        } catch (e) {
          print("Hiba a token dekódolásánál: $e");
        }
      }
    }
    
    String wsUrl = apiUrl.contains('https')
        ? apiUrl.replaceFirst('https', 'wss') + '/api/WorkoutSession/ws/$sessionId/$myUserId'
        : apiUrl.replaceFirst('http', 'ws') + '/api/WorkoutSession/ws/$sessionId/$myUserId';
    
    print("🌐 Csatlakozás a WebSockethez: $wsUrl");

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      isConnected = true;

      _channel!.stream.listen(
        (message) {
          if (onMessageReceived != null) {
            onMessageReceived!(jsonDecode(message));
          }
        },
        onDone: () { isConnected = false; },
        onError: (e) { isConnected = false; },
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
}