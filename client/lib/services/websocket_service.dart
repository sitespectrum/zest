import 'dart:convert';
import 'package:client/constants.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  Function(dynamic)? onMessageReceived;
  bool isConnected = false;

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
          print("📥 WebSocket üzenet érkezett: $message");
          if (onMessageReceived != null) {
            onMessageReceived!(jsonDecode(message));
          }
        },
        onDone: () { 
          print("❌ WebSocket kapcsolat lezárult.");
          isConnected = false; 
        },
        onError: (e) { 
          print("⚠️ WebSocket hiba: $e");
          isConnected = false; 
        },
      );
    } catch (e) {
      print("⚠️ WebSocket csatlakozási hiba: $e");
      isConnected = false;
    }
  }

  void sendAction(String type, dynamic data) {
    if (_channel != null && isConnected) {
      final msg = jsonEncode({"type": type, "data": data});
      print("📤 WebSocket üzenet küldése: $msg");
      _channel!.sink.add(msg);
    } else {
      print("⚠️ Sikertelen küldés: Nincs WebSocket kapcsolat!");
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    isConnected = false;
  }
}