import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:zest_client/components/ui/custom_button.dart';
import 'package:zest_client/components/ui/custom_drawer.dart';
import 'package:zest_client/providers/language_provider.dart';

part "share_drawer.g.dart";

@hwidget
Widget shareDrawer(
  BuildContext context, {
  required Function(BuildContext) startScanning,
  required Future<String?> Function() generateShareId,
  required Function(BuildContext) startNfcSharing,
  required Function(BuildContext) startNfcReceiving,
}) {
  final lang = Provider.of<LanguageProvider>(context);

  final shareId = useState("");

  return CustomDrawer(
    padding: const EdgeInsets.all(24).copyWith(top: 16, left: 0, right: 0),
    child: SizedBox(
      height: MediaQuery.of(context).size.height * 0.5,
      child: Column(
        spacing: 12,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  lang.getText("share"),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: DefaultTabController(
              initialIndex: 0,
              length: 2,
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(50, 64, 255, 50),
                      border: Border.all(
                        color: const Color.fromARGB(100, 64, 255, 50),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TabBar(
                      labelStyle: TextStyle(fontWeight: FontWeight.bold),
                      splashFactory: NoSplash.splashFactory,
                      indicator: BoxDecoration(
                        color: const Color.fromARGB(100, 64, 255, 50),
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorPadding: EdgeInsetsGeometry.all(4),
                      dividerHeight: 0,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.green,
                      tabs: [
                        Tab(text: "NFC"),
                        Tab(text: "QR"),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: TabBarView(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              spacing: 12,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: IconButton(
                                      style: IconButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadiusGeometry.circular(16),
                                        ),
                                        backgroundColor: const Color.fromARGB(
                                          65,
                                          50,
                                          142,
                                          255,
                                        ),
                                        side: BorderSide(
                                          color: const Color.fromARGB(
                                            100,
                                            50,
                                            142,
                                            255,
                                          ),
                                        ),
                                      ),
                                      onPressed: () {
                                        startNfcSharing(context);
                                      },
                                      icon: const Icon(
                                        Icons.contactless_rounded,
                                      ),
                                      color: Colors.white70,
                                      iconSize:
                                          MediaQuery.of(context).size.width *
                                          0.35,
                                    ),
                                  ),
                                ),

                                Flex(
                                  direction: Axis.horizontal,
                                  spacing: 12,
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 2,
                                        color: Colors.white38,
                                      ),
                                    ),

                                    Text(
                                      lang.getText("or"),
                                      style: TextStyle(
                                        color: Colors.white38,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    Expanded(
                                      child: Container(
                                        height: 2,
                                        color: Colors.white38,
                                      ),
                                    ),
                                  ],
                                ),

                                CustomButton(
                                  onPressed: () {
                                    startNfcReceiving(context);
                                  },
                                  title: lang.getText("recive_workout"),
                                  iconData: Icons.call_received_rounded,
                                ),
                              ],
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              spacing: 24,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Container(
                                    width: double.infinity,
                                    alignment: AlignmentGeometry.center,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(25),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white.withAlpha(50),
                                      ),
                                    ),
                                    child: shareId.value.isNotEmpty
                                        ? QrImageView(
                                            data: shareId.value,
                                            version: QrVersions.auto,

                                            dataModuleStyle: QrDataModuleStyle(
                                              color: Colors.white,
                                              dataModuleShape:
                                                  QrDataModuleShape.square,
                                            ),
                                            eyeStyle: QrEyeStyle(
                                              color: Colors.white,
                                              eyeShape: QrEyeShape.square,
                                            ),
                                          )
                                        : Column(
                                            spacing: 12,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.qr_code,
                                                size: 96,
                                                color: Colors.white38,
                                              ),

                                              Text(
                                                "Még nincs QR kód",
                                                style: TextStyle(
                                                  color: Colors.white38,
                                                  fontSize: 20,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                  ),
                                ),

                                Flex(
                                  direction: Axis.horizontal,
                                  spacing: 12,

                                  children: [
                                    CustomButton(
                                      onPressed: () async {
                                        shareId.value =
                                            await generateShareId() ?? "";
                                      },
                                      variant: CustomButtonVariant.secondary,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 2.5,
                                        ),
                                        child: Icon(
                                          Icons.refresh_rounded,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: CustomButton(
                                        onPressed: () => startScanning(context),
                                        title: "Scan QR code",
                                        iconData: Icons.qr_code_scanner_rounded,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
