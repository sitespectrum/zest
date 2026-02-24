import 'package:client/components/drawers/host_session_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:provider/provider.dart';
import 'package:client/components/ui/custom_button.dart';
import 'package:client/components/ui/custom_drawer.dart';
import 'package:client/providers/language_provider.dart';
import 'package:client/components/drawers/join_session_drawer.dart';

part "host_guest_drawer.g.dart";

@hwidget
Widget hostGuestDrawer(BuildContext context) {
  final lang = Provider.of<LanguageProvider>(context, listen: false);

  return Container(
    decoration: const BoxDecoration(
      color: Color.fromARGB(255, 30, 30, 30),
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    child: CustomDrawer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 24,
        children: [
          Text(
            lang.getText("shared_workout"),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          Flex(
            direction: Axis.horizontal,
            spacing: 16,
            children: [
              Expanded(
                child: CustomButton(
                  onPressed: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const HostSessionDrawer(),
                    );
                  },
                  title: lang.getText("host"),
                  iconData: Icons.wifi_tethering_rounded,
                  variant: CustomButtonVariant.primaryWorkout,
                ),
              ),
              Expanded(
                child: CustomButton(
                  onPressed: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const JoinSessionDrawer(),
                    );
                  },
                  title: lang.getText("join"),
                  iconData: Icons.link_rounded,
                  variant: CustomButtonVariant.secondary,
                ),
              ),
            ],
          ),

          CustomButton(
            onPressed: () => Navigator.pop(context),
            title: lang.getText("close"),
            iconData: Icons.close_rounded,
            variant: CustomButtonVariant.secondary,
          ),
        ],
      ),
    ),
  );
}
