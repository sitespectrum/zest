import 'dart:async';
import 'package:client/providers/language_provider.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:provider/provider.dart';

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
        setState(() {
          _hasConnection =
              !results.contains(ConnectivityResult.none) || results.length > 1;
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

    return Stack(
      textDirection: TextDirection
          .ltr, // Fontos, hogy ne kapjunk text direction errort a globális térben
      children: [
        // 1. Az eredeti app folyamatosan fut a háttérben (így nem vész el az edzés órája, állapota)
        widget.child,

        // 2. Ha nincs net, overlay-ként rárajzoljuk ezt a Scaffold-ot
        if (!_hasConnection)
          Positioned.fill(
            child: Scaffold(
              backgroundColor: const Color(0xFF151515),
              body: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: const BoxDecoration(
                            color: Color.fromARGB(20, 255, 69, 69),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.wifi_off_rounded,
                            size: 80,
                            color: Color.fromARGB(255, 255, 100, 100),
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          lang.getText('no_internet_title'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          lang.getText('no_internet_message'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 50),
                        const CircularProgressIndicator(
                          color: Color.fromARGB(255, 64, 255, 50),
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          lang.getText('waiting_for_network'),
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
