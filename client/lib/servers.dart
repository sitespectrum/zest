import 'package:shared_preferences/shared_preferences.dart';

typedef ServerInstance = ({int id, String name, String baseUrl});

const List<ServerInstance> defaultInstances = [
  (id: 0, name: "Production", baseUrl: "https://zest-dev.sitespectrum.dev"),
  (id: 1, name: "Local (AVD)", baseUrl: "http://10.0.2.2:5031"),
  (
    id: 2,
    name: "Coolify dave (dev)",
    baseUrl: "http://wcgsw0cc40okos4skskkk40s.152.53.60.152.sslip.io",
  ),
];

void saveInstances(List<ServerInstance> customInstances) async {
  final instances = [...defaultInstances, ...customInstances];

  final prefs = await SharedPreferences.getInstance();
  await Future.wait([
    prefs.setStringList(
      "serverInstanceIds",
      instances.map((x) => x.id.toString()).toList(),
    ),
    prefs.setStringList(
      "serverInstanceNames",
      instances.map((x) => x.name).toList(),
    ),
    prefs.setStringList(
      "serverInstanceUrls",
      instances.map((x) => x.baseUrl).toList(),
    ),
  ]);
}

Future<List<ServerInstance>> getInstances() async {
  final prefs = await SharedPreferences.getInstance();

  final ids =
      (prefs.getStringList("serverInstanceIds")?.map((x) => int.parse(x)) ?? [])
          .toList();
  final names = (prefs.getStringList("serverInstanceNames") ?? []).toList();
  final urls = (prefs.getStringList("serverInstanceUrls") ?? []).toList();

  final instances = <ServerInstance>[];
  for (var i = 0; i < ids.length; i++) {
    instances.add((id: ids[i], name: names[i], baseUrl: urls[i]));
  }

  return [...defaultInstances, ...instances];
}

Future<ServerInstance> getSelectedInstance() async {
  final prefs = await SharedPreferences.getInstance();

  final instances = await getInstances();
  final selectedId = prefs.getInt("selectedServerInstanceId") ?? 0;
  return instances.firstWhere((x) => x.id == selectedId);
}

//TODO: use riverpod provider instead (after migrating to riverpod)
var apiUrl = "";
