import 'dart:async';
import 'package:flutter/material.dart';

class CustomSnackbar {
  static OverlayEntry? _overlayEntry;
  static Timer? _timer;

  static void show(
    BuildContext context,
    String message, {
    Color? backgroundColor,
  }) {
    try {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    } catch (_) {}

    hide();

    final overlayState = Overlay.of(context, rootOverlay: true);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          bottom: 0,
          left: 20,
          right: 20,
          child: Material(
            color: Colors.transparent,
            child: _SnackbarWidget(
              message: message,
              backgroundColor: backgroundColor,
              onClose: hide,
            ),
          ),
        );
      },
    );

    overlayState.insert(_overlayEntry!);

    _timer = Timer(const Duration(seconds: 3), () {
      hide();
    });
  }

  static void hide() {
    _timer?.cancel();
    _timer = null;
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }
}

class _SnackbarWidget extends StatefulWidget {
  final String message;
  final Color? backgroundColor;
  final VoidCallback onClose;

  const _SnackbarWidget({
    required this.message,
    this.backgroundColor,
    required this.onClose,
  });

  @override
  State<_SnackbarWidget> createState() => _SnackbarWidgetState();
}

class _SnackbarWidgetState extends State<_SnackbarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();
  }

  Future<void> _close() async {
    await _controller.reverse();
    widget.onClose();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    final bottomOffset = keyboardHeight > 0 ? keyboardHeight + 20 : 120.0;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomOffset),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color:
                  widget.backgroundColor ??
                  const Color.fromARGB(255, 45, 45, 45),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.message,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _close,
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(Icons.close, color: Colors.white70, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
