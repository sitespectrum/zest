import 'dart:async' show StreamController;
import 'dart:convert';
import 'package:client/constants.dart';
import 'package:flutter/foundation.dart';
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

  void connect(String sessionId) {
    if (isConnected) return;
    
    String wsUrl = apiUrl.contains('https')
        ? apiUrl.replaceFirst('https', 'wss') + '/api/WorkoutSession/ws/$sessionId'
        : apiUrl.replaceFirst('http', 'ws') + '/api/WorkoutSession/ws/$sessionId';
    
    print("🌐 Csatlakozás a WebSockethez: $wsUrl");

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      isConnected = true;

      _channel!.stream.listen(
        (message) {
          final decodedMessage = jsonDecode(message);

          _messageController.add(decodedMessage);

          if (onMessageReceived != null) {
            onMessageReceived!(jsonDecode(message));
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
}