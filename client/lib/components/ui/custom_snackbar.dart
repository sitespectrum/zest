import 'package:flutter/material.dart';

class CustomSnackbar {
  static void show(BuildContext context, String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white70),
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ],
        ),
        backgroundColor: backgroundColor ?? const Color.fromARGB(255, 45, 45, 45),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.white24, width: 1),
        ),
        margin: const EdgeInsets.only(bottom: 30, left: 20, right: 20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        duration: const Duration(seconds: 3),
        elevation: 6,
      ),
    );
  }
}