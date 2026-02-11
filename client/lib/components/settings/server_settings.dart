import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:terminate_restart/terminate_restart.dart';
import 'package:zest_client/components/ui/custom_button.dart';
import 'package:zest_client/components/ui/custom_card.dart';
import 'package:zest_client/components/ui/custom_drawer.dart';
import 'package:zest_client/servers.dart';

part "server_settings.g.dart";

@hwidget
Widget serverSettings(BuildContext context) {
  final selectedId = useState<int?>(null);
  final currentSaved = useState<int?>(null);

  final instances = useQuery(const [
    "serverInstances",
    "all",
  ], (context) async => await getInstances());

  final saveMutation = useMutation((int id, ctx) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt("selectedServerInstanceId", id);
    currentSaved.value = id;

    if (context.mounted) {
      showModalBottomSheet(
        context: context,
        builder: (context) => RestartRequiredDrawer(),
      );
    }

    return;
  });

  useEffect(() {
    SharedPreferences.getInstance().then((prefs) {
      selectedId.value = prefs.getInt("selectedServerInstanceId");
      currentSaved.value = prefs.getInt("selectedServerInstanceId");
    });

    return;
  }, []);

  return CustomCard(
    title: "Server instance",
    iconData: Icons.storage_rounded,
    child: Column(
      spacing: 12,
      children: [
        ...(instances.data ?? []).map(
          (instance) => GestureDetector(
            onTap: () => selectedId.value = instance.id,
            child: Container(
              decoration: BoxDecoration(
                color: Color.fromARGB(15, 255, 255, 255),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selectedId.value == instance.id
                      ? Color.fromARGB(150, 64, 255, 50)
                      : Colors.transparent,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Flex(
                direction: Axis.horizontal,
                spacing: 12,
                children: [
                  Container(
                    color: const Color.fromARGB(15, 255, 255, 255),
                    height: 64,
                    width: 64,
                    child: selectedId.value == instance.id
                        ? Icon(
                            Icons.check_rounded,
                            color: Color.fromARGB(150, 64, 255, 50),
                          )
                        : null,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            instance.name,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            instance.baseUrl,
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              overflow: TextOverflow.ellipsis,
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
        ),

        CustomButton(
          disabled: selectedId.value == currentSaved.value,
          onPressed: () => saveMutation.mutate(selectedId.value ?? 0),
          title: "Save",
          iconData: Icons.save_rounded,
        ),
      ],
    ),
  );
}

@hwidget
Widget restartRequiredDrawer() {
  return CustomDrawer(
    child: Column(
      spacing: 24,
      children: [
        Text(
          "Restart required",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          "A full app restart is required to save the modified settings. If the app doesn't start automatically after closing, please open it manually.",
        ),
        CustomButton(
          onPressed: () async {
            await TerminateRestart.instance.restartApp(
              options: const TerminateRestartOptions(terminate: true),
            );
          },
          title: "Restart now",
          iconData: Icons.restart_alt_rounded,
        ),
      ],
    ),
  );
}
