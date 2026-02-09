import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zest_client/components/ui/custom_card.dart';
import 'package:zest_client/servers.dart';

part "server_settings.g.dart";

@hwidget
Widget serverSettings() {
  final instances = useState(<ServerInstance>[]);
  final selectedId = useState<int?>(null);

  Future<void> loadData() async {
    selectedId.value =
        (await SharedPreferences.getInstance()).getInt(
          "selectedServerInstanceId",
        ) ??
        0;
    instances.value = await getInstances();
  }

  Future<void> setSelected(int id) async {
    final prefs = await SharedPreferences.getInstance();

    prefs.setInt("selectedServerInstanceId", id);
    selectedId.value = id;

    final newInstance = await getSelectedInstance();
    apiUrl = newInstance.baseUrl;
  }

  useEffect(() {
    loadData();

    return;
  }, []);

  return CustomCard(
    title: "Server instance",
    iconData: Icons.storage_rounded,
    child: Column(
      spacing: 12,
      children: instances.value
          .map(
            (instance) => GestureDetector(
              onTap: () => setSelected(instance.id),
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
                child: Row(
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    ),
  );
}
