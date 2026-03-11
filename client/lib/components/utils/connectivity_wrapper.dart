import 'dart:async';
import 'dart:convert';
import 'package:client/providers/language_provider.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

class ConnectivityWrapper extends StatefulWidget {
  final Widget child;

  const ConnectivityWrapper({super.key, required this.child});

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  bool _hasConnection = true;
  late StreamSubscription<List<ConnectivityResult>> _subscription;

  @override
  void initState() {
    super.initState();
    _checkInitialConnection();

    _subscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (mounted) {
        bool isConnected =
            !results.contains(ConnectivityResult.none) || results.length > 1;

        if (isConnected && !_hasConnection) {
          _syncOfflineQueue();
        }

        setState(() {
          _hasConnection = isConnected;
        });
      }
    });
  }

  Future<void> _checkInitialConnection() async {
    final results = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() {
        _hasConnection = !results.contains(ConnectivityResult.none);
      });
      if (_hasConnection) {
        _syncOfflineQueue();
      }
    }
  }

  Future<void> _syncOfflineQueue() async {
    final queueBox = Hive.box('queueBox');
    if (queueBox.isEmpty) return;

    debugPrint(
      "Offline várakozási sor szinkronizálása kezdődik. Elemek: ${queueBox.length}",
    );

    final keys = queueBox.keys.toList();
    for (var key in keys) {
      try {
        final item = queueBox.get(key);
        if (item != null) {
          final String url = item['url'];
          final String body = item['body'];
          final Map<String, String> headers = Map<String, String>.from(
            item['headers'],
          );

          final response = await http.post(
            Uri.parse(url),
            headers: headers,
            body: body,
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            await queueBox.delete(key);
            debugPrint("Sikeresen szinkronizálva: $url");
          } else {
            debugPrint(
              "Hiba a szinkronizálás során ($url): ${response.statusCode}",
            );
          }
        }
      } catch (e) {
        debugPrint("Hálózati hiba a szinkronizálás során: $e");
        break;
      }
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final mediaQuery = MediaQuery.of(context);

    return Material(
      color: Colors.black,
      child: Column(
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _hasConnection
                ? const SizedBox(width: double.infinity, height: 0)
                : Container(
                    width: double.infinity,
                    color: const Color.fromARGB(255, 230, 57, 70),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.wifi_off_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              lang.getText('no_connection'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),

          Expanded(
            child: MediaQuery(
              data: mediaQuery.copyWith(
                padding: _hasConnection
                    ? mediaQuery.padding
                    : mediaQuery.padding.copyWith(top: 0),
              ),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}
