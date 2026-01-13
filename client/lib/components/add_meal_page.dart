import 'dart:convert';
import 'package:client/Providers/language_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:client/models/meal.dart';
import 'dart:async';
import 'package:ai_barcode_scanner/ai_barcode_scanner.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import 'dart:math';

class AddMealPage extends StatefulWidget {
  final bool addToTemplate;
  final int? templateId;

  const AddMealPage({super.key, this.addToTemplate = false, this.templateId});

  @override
  State<AddMealPage> createState() => _AddMealPageState();
}

String stripHtmlTags(String htmlText) {
  final exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
  return htmlText.replaceAll(exp, '');
}

class _AddMealPageState extends State<AddMealPage> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController quantitycontroller = TextEditingController();
  final barcodeController = TextEditingController();
  List<MealDto> searchResults = [];
  bool isLoading = false;
  bool anyResults = false;
  Timer? _debounce;

  List<MealDto> userMeals = [];
  List<MealDto> templateMeals = [];

  void addMeal(MealDto meal) {
    setState(() {
      userMeals.add(meal);
    });
    final cleanName = stripHtmlTags(meal.name);
    final lang = Provider.of<LanguageProvider>(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$cleanName ${lang.getText("added_to_list")}'),
        showCloseIcon: true,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(bottom: 30, left: 16, right: 16),
        duration: Duration(milliseconds: 1800),
        animation: CurvedAnimation(
          parent: kAlwaysCompleteAnimation,
          curve: Curves.easeInOut,
        ),
      ),
    );
  }

  final ScrollController _scrollController = ScrollController();
  late Future<List<UserMealDto>> futureMeals;

  @override
  void initState() {
    super.initState();
    futureMeals = fetchUserMeals();
    loadTopMeals();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchUnit(String foodId) async {
    try {
      var uri;
      final lang = Provider.of<LanguageProvider>(
        context,
        listen: false,
      ).languageCode;
      if (lang == "hu") {
        setState(() {
          uri = Uri.parse('$apiUrl/api/meals/hu-get-units?foodId=$foodId');
        });
      } else if (lang == "en") {
        setState(() {
          uri = Uri.parse('$apiUrl/api/meals/en-get-units?foodId=$foodId');
        });
      }
      final response = await http.get(uri);

      if (response.statusCode != 200) throw Exception('HTTP hiba');

      final data = jsonDecode(response.body);
      if (data is! List) {
        return [];
      }

      final units = List<Map<String, dynamic>>.from(data);
      return units;
      // ignore: unused_catch_stack
    } catch (e, st) {
      return [];
    }
  }

  Future<List<MealDto>> fetchMealsByBarcode(String code) async {
    try {
      var uri;
      final lang = Provider.of<LanguageProvider>(
        context,
        listen: false,
      ).languageCode;
      if (lang == "hu") {
        setState(() {
          uri = Uri.parse('$apiUrl/api/meals/hu-get-by-barcode?code=$code');
        });
      } else if (lang == "en") {
        setState(() {
          uri = Uri.parse('$apiUrl/api/meals/en-get-by-barcode?code=$code');
        });
      }
      final response = await http.get(uri);

      if (response.statusCode != 200) throw Exception('HTTP hiba');

      final data = jsonDecode(response.body);
      if (data is! Map || data['food_data'] == null) return [];

      final foodData = data['food_data'];
      final meal = MealDto(
        foodId: foodData['nID'] ?? '0',
        name: foodData['cDisplayName'] ?? 'Ismeretlen étel',
        calories: (double.tryParse(foodData['nCalorie'] ?? '0') ?? 0).round(),
        protein: double.tryParse(foodData['nProtein'] ?? '0') ?? 0,
        carbs: double.tryParse(foodData['nCarbo'] ?? '0') ?? 0,
        fat: double.tryParse(foodData['nFat'] ?? '0') ?? 0,
        quantity: 1,
        unit: null,
        baseWeight: null,
        multiplier: 1,
      );

      return [meal];
      // ignore: unused_catch_stack
    } catch (e, st) {
      return [];
    }
  }

  Future<List<UserMealDto>> fetchUserMeals() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) throw Exception("Nincs token");

    final response = await http.get(
      Uri.parse("$apiUrl/api/meals/getUserMeals"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => UserMealDto.fromJson(e)).toList();
    } else {
      throw Exception("Nem sikerült lekérni az étkezéseket: ${response.body}");
    }
  }

  Future<int?> addFoodToTemplate(
    int templateId,
    int userId,
    MealDto meal,
  ) async {
    final url = Uri.parse("$apiUrl/api/Meals/AddFoodToTemplate");

    final body = jsonEncode({
      "templateId": templateId,
      "userId": userId,
      "foodId": meal.foodId,
      "name": meal.name,
      "quantity": meal.quantity,
      "calories": meal.calories,
      "protein": meal.protein,
      "carbs": meal.carbs,
      "fat": meal.fat,
      "unit": meal.unit,
      "baseWeight": meal.baseWeight,
    });
    print("templateId: ${templateId}");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['id'];
      } else {
        print("Nem sikerült hozzáadni: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Hiba: $e");
      return null;
    }
  }

  Future<void> loadTopMeals() async {
    final meals = await fetchUserMeals();

    final Map<String, int> foodCounts = {};

    for (final userMeal in meals) {
      for (final meal in userMeal.meals) {
        foodCounts[meal.foodId] = (foodCounts[meal.foodId] ?? 0) + 1;
      }
    }

    final sorted = foodCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topIds = sorted
        .take(min(10, sorted.length))
        .map((e) => e.key)
        .toList();

    final List<MealDto> topMeals = [];

    for (final userMeal in meals) {
      for (final meal in userMeal.meals) {
        if (topIds.contains(meal.foodId) &&
            !topMeals.any((m) => m.foodId == meal.foodId)) {
          topMeals.add(meal);
        }
      }
    }

    setState(() {
      searchResults = topMeals;
    });
  }

  Future<void> _searchMeals(String query) async {
    final lang = Provider.of<LanguageProvider>(
      context,
      listen: false,
    ).languageCode;
    final q = query.trim();
    if (q.isEmpty) {
      setState(() => searchResults = []);
      return;
    }

    setState(() {
      anyResults = true;
      isLoading = true;
    });

    try {
      var uri;
      if (lang == "hu") {
        setState(() {
          uri = Uri.parse('$apiUrl/api/meals/husearch?q=$q');
        });
      } else if (lang == "en") {
        setState(() {
          uri = Uri.parse('$apiUrl/api/meals/ensearch?q=$q');
        });
      }
      final response = await http.get(uri);
      print("URI: ${uri}");

      if (response.statusCode != 200) {
        print("Hiba: Státuszkód ${response.statusCode}");
        setState(() => searchResults = []);
        return;
      }

      final body = response.body.trim();
      if (body.isEmpty || body.startsWith("<")) {
        print("Hiba: Érvénytelen válasz (üres vagy HTML).");
        setState(() => searchResults = []);
        return;
      }

      dynamic decoded = jsonDecode(body);
      List items = [];

      if (decoded is List) {
        items = decoded;
      } else if (decoded is Map<String, dynamic>) {
        if (decoded['results2'] is List)
          items = decoded['results2'];
        else if (decoded['results'] is List)
          items = decoded['results'];
        else if (decoded['data'] is List)
          items = decoded['data'];
        else if (decoded['food_list'] is List)
          items = decoded['food_list'];
        else {
          print(
            "Hiba: Nem találtam listát a JSON objektumban. Kulcsok: ${decoded.keys}",
          );
        }
      }

      final results = items
          .map((e) {
            try {
              return MealDto.fromJson(e);
            } catch (error) {
              return null;
            }
          })
          .where((e) => e != null)
          .cast<MealDto>()
          .toList();

      setState(() => searchResults = results);
    } catch (e) {
      print("Kritikus hiba a keresés közben: $e");
      setState(() => searchResults = []);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    return FutureBuilder<List<UserMealDto>>(
      future: futureMeals,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Hiba: ${snapshot.error}'));
        }

        // ignore: deprecated_member_use
        return WillPopScope(
          onWillPop: () async {
            if (widget.addToTemplate) {
              Navigator.pop(context, templateMeals);
            } else {
              Navigator.pop(context, userMeals);
            }
            return false;
          },
          child: Scaffold(
            body: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    margin: const EdgeInsets.fromLTRB(2, 6, 2, 0),
                    child: AppBar(
                      title: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: SizedBox(
                                height: 48,
                                child: TextField(
                                  controller: _controller,
                                  onChanged: (value) {
                                    if (_debounce?.isActive ?? false) {
                                      _debounce!.cancel();
                                    }
                                    _debounce = Timer(
                                      const Duration(milliseconds: 600),
                                      () {
                                        _searchMeals(value);
                                      },
                                    );
                                  },
                                  cursorColor: Colors.white,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: const Color.fromARGB(
                                      255,
                                      45,
                                      45,
                                      45,
                                    ),
                                    hintText: lang.getText("search_hint"),
                                    hintStyle: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    border: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                        color: Colors.white24,
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                        color: Colors.white24,
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                        color: Colors.grey,
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 4),

                          Container(
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 85, 173, 78),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: IconButton(
                              onPressed: () {
                                Future.microtask(() async {
                                  bool hasPopped = false;
                                  final scannedCode =
                                      // ignore: use_build_context_synchronously
                                      await Navigator.of(context).push<String>(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              AiBarcodeScanner(
                                                onDetect: (capture) {
                                                  if (hasPopped) return;
                                                  final code = capture
                                                      .barcodes
                                                      .first
                                                      .rawValue;
                                                  if (code != null) {
                                                    hasPopped = true;
                                                    Navigator.of(
                                                      context,
                                                    ).pop(code);
                                                  }
                                                },
                                              ),
                                        ),
                                      );

                                  if (scannedCode != null &&
                                      scannedCode.isNotEmpty) {
                                    final results = await fetchMealsByBarcode(
                                      scannedCode,
                                    );
                                    if (results.isNotEmpty) {
                                      setState(() {
                                        searchResults = results;
                                        anyResults = true;
                                      });
                                    } else {
                                      ScaffoldMessenger.of(
                                        // ignore: use_build_context_synchronously
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            lang.getText("no_barcode_found"),
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                          margin: EdgeInsets.only(
                                            bottom: 30,
                                            left: 16,
                                            right: 16,
                                          ),
                                          duration: Duration(
                                            milliseconds: 1800,
                                          ),
                                          animation: CurvedAnimation(
                                            parent: kAlwaysCompleteAnimation,
                                            curve: Curves.easeInOut,
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                });
                              },
                              icon: const Icon(
                                CupertinoIcons.barcode,
                                size: 25,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: const Color.fromARGB(255, 58, 58, 58),
                      iconTheme: const IconThemeData(color: Colors.white),
                    ),
                  ),

                  !anyResults
                      ? ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            final meal = searchResults[index];
                            final cleanName = stripHtmlTags(meal.name);

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 45, 45, 45),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white24),
                                  boxShadow: [
                                    BoxShadow(
                                      // ignore: deprecated_member_use
                                      color: Colors.black.withOpacity(0.5),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () async {
                                    if (widget.addToTemplate) {
                                      final prefs =
                                          await SharedPreferences.getInstance();
                                      final userId = prefs.getInt("userId");
                                      print("userId: ${userId}");
                                      if (userId != null &&
                                          widget.templateId != null) {
                                        await addFoodToTemplate(
                                          widget.templateId!,
                                          userId,
                                          meal,
                                        );
                                        print(widget.templateId);
                                        setState(() {
                                          templateMeals.add(meal);
                                        });
                                      }
                                    } else {
                                      setState(() {
                                        userMeals.add(meal);
                                      });
                                    }
                                    final cleanName = stripHtmlTags(meal.name);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '$cleanName ${lang.getText("added_to_list")}',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                        margin: EdgeInsets.only(
                                          bottom: 30,
                                          left: 16,
                                          right: 16,
                                        ),
                                        duration: Duration(milliseconds: 1800),
                                        animation: CurvedAnimation(
                                          parent: kAlwaysCompleteAnimation,
                                          curve: Curves.easeInOut,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(
                                        255,
                                        45,
                                        45,
                                        45,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white24),
                                      boxShadow: [
                                        BoxShadow(
                                          // ignore: deprecated_member_use
                                          color: Colors.black.withOpacity(0.5),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            cleanName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  '${meal.qCalories} kcal | ${meal.qProtein.toStringAsFixed(3)} g ${lang.getText("protein")} | ${meal.qCarbs.toStringAsFixed(3)} g ${lang.getText("carbs")} | ${meal.qFat.toStringAsFixed(3)} g ${lang.getText("fat")} | ${lang.getText("portion")}: ${meal.quantity} ${meal.piece}',
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      : isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            final meal = searchResults[index];
                            final cleanName = stripHtmlTags(meal.name);

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () async {
                                  final units = await _fetchUnit(meal.foodId);
                                  if (units.isEmpty) {
                                    // ignore: use_build_context_synchronously
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          lang.getText("no_unit_found"),
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                        margin: EdgeInsets.only(
                                          bottom: 30,
                                          left: 16,
                                          right: 16,
                                        ),
                                        duration: Duration(milliseconds: 1800),
                                        animation: CurvedAnimation(
                                          parent: kAlwaysCompleteAnimation,
                                          curve: Curves.easeInOut,
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  String selectedUnit =
                                      (units.first["Name"]?.toString() ?? '')
                                          .replaceFirst("UNIT_", "");
                                  double baseWeight =
                                      double.tryParse(
                                        units.first["nWeight"]?.toString() ??
                                            '1',
                                      ) ??
                                      1.0;
                                  double multiplier = baseWeight / 100;

                                  final updatedMeal = await showDialog<MealDto>(
                                    // ignore: use_build_context_synchronously
                                    context: context,
                                    builder: (context) {
                                      return StatefulBuilder(
                                        builder: (context, setState) {
                                          return Center(
                                            child: SingleChildScrollView(
                                              child: Dialog(
                                                backgroundColor:
                                                    const Color.fromARGB(
                                                      255,
                                                      35,
                                                      35,
                                                      35,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                    16,
                                                  ),
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        lang.getText(
                                                          "choose_quantity",
                                                        ),
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 20,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 12,
                                                      ),
                                                      Container(
                                                        width:
                                                            MediaQuery.of(
                                                              context,
                                                            ).size.width *
                                                            0.3,
                                                        height:
                                                            MediaQuery.of(
                                                              context,
                                                            ).size.height *
                                                            0.06,
                                                        padding:
                                                            const EdgeInsets.fromLTRB(
                                                              0,
                                                              0,
                                                              0,
                                                              18,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color:
                                                              const Color.fromARGB(
                                                                255,
                                                                72,
                                                                72,
                                                                72,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                        ),
                                                        child: TextField(
                                                          cursorColor:
                                                              Colors.white,
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 20,
                                                              ),
                                                          controller:
                                                              quantitycontroller,
                                                          textAlign:
                                                              TextAlign.center,
                                                          decoration: InputDecoration(
                                                            border: OutlineInputBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    12,
                                                                  ),
                                                            ),
                                                            focusedBorder: OutlineInputBorder(
                                                              borderSide:
                                                                  const BorderSide(
                                                                    color: Colors
                                                                        .transparent,
                                                                    width: 2,
                                                                  ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    12,
                                                                  ),
                                                            ),
                                                            enabledBorder: OutlineInputBorder(
                                                              borderSide:
                                                                  const BorderSide(
                                                                    color: Colors
                                                                        .transparent,
                                                                    width: 1,
                                                                  ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    12,
                                                                  ),
                                                            ),
                                                          ),
                                                          keyboardType:
                                                              TextInputType
                                                                  .number,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 12,
                                                      ),
                                                      Wrap(
                                                        spacing: 8,
                                                        runSpacing: 8,
                                                        children: units.map((
                                                          unit,
                                                        ) {
                                                          final name =
                                                              unit["Name"]
                                                                  .replaceFirst(
                                                                    "UNIT_",
                                                                    "",
                                                                  );
                                                          final weight =
                                                              double.tryParse(
                                                                unit["nWeight"],
                                                              ) ??
                                                              1.0;
                                                          final isSelected =
                                                              name ==
                                                              selectedUnit;

                                                          return ChoiceChip(
                                                            label: Text(
                                                              "$name (${weight.toStringAsFixed(0)}g/ml)",
                                                              style: TextStyle(
                                                                color:
                                                                    isSelected
                                                                    ? Colors
                                                                          .black
                                                                    : Colors
                                                                          .white,
                                                              ),
                                                            ),
                                                            selected:
                                                                isSelected,
                                                            selectedColor:
                                                                Colors.white,
                                                            backgroundColor:
                                                                const Color.fromARGB(
                                                                  255,
                                                                  60,
                                                                  60,
                                                                  60,
                                                                ),
                                                            onSelected: (selected) {
                                                              if (selected) {
                                                                setState(() {
                                                                  selectedUnit =
                                                                      name;
                                                                  baseWeight =
                                                                      weight;
                                                                  multiplier =
                                                                      baseWeight /
                                                                      100;
                                                                });
                                                              }
                                                            },
                                                          );
                                                        }).toList(),
                                                      ),
                                                      const SizedBox(
                                                        height: 20,
                                                      ),
                                                      ElevatedButton(
                                                        onPressed: () {
                                                          final quantity =
                                                              int.tryParse(
                                                                quantitycontroller
                                                                    .text,
                                                              ) ??
                                                              1;
                                                          final updatedMeal = MealDto(
                                                            foodId: meal.foodId,
                                                            name: meal.name,
                                                            calories:
                                                                (meal.calories *
                                                                        multiplier)
                                                                    .round(),
                                                            protein:
                                                                meal.protein *
                                                                multiplier,
                                                            carbs:
                                                                meal.carbs *
                                                                multiplier,
                                                            fat:
                                                                meal.fat *
                                                                multiplier,
                                                            quantity: quantity,
                                                            baseWeight:
                                                                baseWeight,
                                                            unit: selectedUnit,
                                                            multiplier:
                                                                multiplier,
                                                          );
                                                          Navigator.of(
                                                            context,
                                                          ).pop(updatedMeal);
                                                        },
                                                        style:
                                                            ElevatedButton.styleFrom(
                                                              backgroundColor:
                                                                  Colors.white,
                                                              foregroundColor:
                                                                  Colors.black,
                                                            ),
                                                        child: Text(
                                                          lang.getText("add"),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  );
                                  if (updatedMeal != null) {
                                    if (widget.addToTemplate) {
                                      final prefs =
                                          await SharedPreferences.getInstance();
                                      final userId = prefs.getInt("userId");

                                      if (userId != null &&
                                          widget.templateId != null) {
                                        final newId = await addFoodToTemplate(
                                          widget.templateId!,
                                          userId,
                                          updatedMeal,
                                        );

                                        if (newId != null) {
                                          final mealWithId = updatedMeal
                                              .copyWith(id: newId);

                                          setState(() {
                                            templateMeals.add(mealWithId);
                                          });
                                        }
                                      } else {
                                        print(
                                          "HIBA: UserId vagy TemplateId null! User: $userId, Template: ${widget.templateId}",
                                        );
                                      }
                                    } else {
                                      setState(() {
                                        userMeals.add(updatedMeal);
                                      });
                                    }

                                    final cleanName = stripHtmlTags(
                                      updatedMeal.name,
                                    );
                                    // ignore: use_build_context_synchronously
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '$cleanName ${lang.getText("added_to_list")}',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                        margin: EdgeInsets.only(
                                          bottom: 30,
                                          left: 16,
                                          right: 16,
                                        ),
                                        duration: Duration(milliseconds: 1800),
                                        animation: CurvedAnimation(
                                          parent: kAlwaysCompleteAnimation,
                                          curve: Curves.easeInOut,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(
                                      255,
                                      45,
                                      45,
                                      45,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white24),
                                    boxShadow: [
                                      BoxShadow(
                                        // ignore: deprecated_member_use
                                        color: Colors.black.withOpacity(0.5),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cleanName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                '${meal.qCalories} kcal | ${meal.qProtein.toStringAsFixed(3)} g ${lang.getText("protein")} | ${meal.qCarbs.toStringAsFixed(3)} g ${lang.getText("carbs")} | ${meal.qFat.toStringAsFixed(3)} g ${lang.getText("fat")} | adag: ${meal.quantity} ${meal.piece}',
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => {
                if (_scrollController.hasClients)
                  {
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOut,
                    ),
                  },
              },
              backgroundColor: const Color.fromRGBO(85, 173, 78, 1),
              child: const Icon(
                Icons.arrow_upward,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        );
      },
    );
  }
}
