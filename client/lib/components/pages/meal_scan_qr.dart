import 'dart:convert';

import 'package:ai_barcode_scanner/ai_barcode_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:zest_client/models/meal.dart';
import 'package:zest_client/providers/language_provider.dart';
import 'package:zest_client/servers.dart';

part "meal_scan_qr.g.dart";

@hwidget
Widget mealScanQrPage(
  BuildContext context, {
  required ValueNotifier<List<MealDto>> meals,
}) {
  final lang = Provider.of<LanguageProvider>(context);

  return AiBarcodeScanner(
    onDetect: (BarcodeCapture capture) async {
      String scannedValue = capture.barcodes.first.rawValue ?? "";

      if (scannedValue.isEmpty) return;

      Navigator.of(context).pop();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()),
      );

      try {
        List<MealDto> newMeals = [];

        if (scannedValue.startsWith("[")) {
          List<dynamic> decodedData = jsonDecode(scannedValue);
          newMeals = decodedData.map((item) => MealDto.fromJson(item)).toList();
        } else {
          final response = await http.get(
            Uri.parse("$apiUrl/api/Share/workout-$scannedValue"),
          );

          if (response.statusCode == 200) {
            List<dynamic> decodedData = jsonDecode(response.body);
            newMeals = decodedData
                .map((item) => MealDto.fromJson(item))
                .toList();
          } else {
            throw Exception("Nem található vagy lejárt megosztás.");
          }
        }

        Navigator.pop(context);

        meals.value = [...meals.value, ...newMeals];

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "${newMeals.length} ${lang.getText("added_to_list")}",
            ),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        Navigator.pop(context);
        debugPrint("Hiba az importálásnál: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Hiba: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    },
    controller: MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    ),
  );
}
