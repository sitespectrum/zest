import 'dart:convert';
import 'dart:ui'; // BackdropFilter-hez
import 'package:client/components/ui/custom_button.dart'; // CustomButton importálása
import 'package:client/components/ui/custom_snackbar.dart';
import 'package:client/providers/language_provider.dart';
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
  bool _isInit = true;

  // Narancssárga szín definíciója az ételekhez (CustomMealPage alapján)
  final Color primaryOrange = const Color.fromARGB(255, 255, 115, 69);

  List<MealDto> userMeals = [];
  List<MealDto> templateMeals = [];

  final ScrollController _scrollController = ScrollController();
  late Future<List<UserMealDto>> futureMeals;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      futureMeals = fetchUserMeals();
      loadTopMeals();
      _isInit = false;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    quantitycontroller.dispose();
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

      if (response.statusCode != 200) throw Exception('HTTP error');

      final data = jsonDecode(response.body);
      if (data is! List) {
        return [];
      }

      final units = List<Map<String, dynamic>>.from(data);
      return units;
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
    } catch (e, st) {
      return [];
    }
  }

  Future<List<UserMealDto>> fetchUserMeals() async {
    final lang = Provider.of<LanguageProvider>(context);
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
      throw Exception(lang.getText("failed_to_fetch_meals"));
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
        return null;
      }
    } catch (e) {
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

    if (mounted) {
      setState(() {
        searchResults = topMeals;
      });
    }
  }

  Future<void> _searchMeals(String query) async {
    final lang = Provider.of<LanguageProvider>(
      context,
      listen: false,
    ).languageCode;
    final q = query.trim();
    if (q.isEmpty) {
      loadTopMeals();
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

      if (response.statusCode != 200) {
        setState(() => searchResults = []);
        return;
      }

      final body = response.body.trim();
      if (body.isEmpty || body.startsWith("<")) {
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
      setState(() => searchResults = []);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // Segédfüggvény a listaelemek megjelenítéséhez
  Widget _buildMealItem(MealDto meal, String langCode, LanguageProvider lang) {
    final cleanName = stripHtmlTags(meal.name);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 45, 45, 45),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          splashColor: primaryOrange.withOpacity(0.2),
          highlightColor: primaryOrange.withOpacity(0.1),
          onTap: () async {
            // Itt jön a dialógus logika
            await _showQuantityDialog(meal, lang);
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                        '${meal.qCalories} kcal | ${meal.qProtein.toStringAsFixed(1)}g ${lang.getText("protein")} | ${meal.qCarbs.toStringAsFixed(1)}g ${lang.getText("carbs")} | ${meal.qFat.toStringAsFixed(1)}g ${lang.getText("fat")}',
                        style: const TextStyle(color: Colors.white70),
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
  }

  Future<void> _showQuantityDialog(MealDto meal, LanguageProvider lang) async {
    final units = await _fetchUnit(meal.foodId);
    if (units.isEmpty) {
      if (!mounted) return;
      CustomSnackbar.show(
        context,
        lang.getText("no_units_available"),
        backgroundColor: Colors.red,
      );
      return;
    }

    String selectedUnit = (units.first["Name"]?.toString() ?? '').replaceFirst(
      "UNIT_",
      "",
    );
    double baseWeight =
        double.tryParse(units.first["nWeight"]?.toString() ?? '1') ?? 1.0;
    double multiplier = baseWeight / 100;

    if (!mounted) return;

    final updatedMeal = await showDialog<MealDto>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              backgroundColor: const Color.fromARGB(255, 35, 35, 35),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      lang.getText("choose_quantity"),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.3,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 72, 72, 72),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        cursorColor: Colors.white,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                        controller: quantitycontroller,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: units.map((unit) {
                        final name = unit["Name"].replaceFirst("UNIT_", "");
                        final weight = double.tryParse(unit["nWeight"]) ?? 1.0;
                        final isSelected = name == selectedUnit;

                        return ChoiceChip(
                          label: Text(
                            "$name (${weight.toStringAsFixed(0)}g/ml)",
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: Colors.white,
                          backgroundColor: const Color.fromARGB(
                            255,
                            60,
                            60,
                            60,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setStateDialog(() {
                                selectedUnit = name;
                                baseWeight = weight;
                                multiplier = baseWeight / 100;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            variant: CustomButtonVariant.secondary,
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              lang.getText("cancel"),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CustomButton(
                            variant: CustomButtonVariant.primaryMeal,
                            onPressed: () {
                              final quantity =
                                  int.tryParse(quantitycontroller.text) ?? 1;
                              final newMeal = MealDto(
                                foodId: meal.foodId,
                                name: meal.name,
                                calories: (meal.calories * multiplier).round(),
                                protein: meal.protein * multiplier,
                                carbs: meal.carbs * multiplier,
                                fat: meal.fat * multiplier,
                                quantity: quantity,
                                baseWeight: baseWeight,
                                unit: selectedUnit,
                                multiplier: multiplier,
                              );
                              Navigator.of(context).pop(newMeal);
                            },
                            child: Text(
                              lang.getText("add"),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (updatedMeal != null) {
      if (widget.addToTemplate) {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getInt("userId");

        if (userId != null && widget.templateId != null) {
          final newId = await addFoodToTemplate(
            widget.templateId!,
            userId,
            updatedMeal,
          );

          if (newId != null) {
            final mealWithId = updatedMeal.copyWith(id: newId);
            setState(() {
              templateMeals.add(mealWithId);
            });
          }
        }
      } else {
        setState(() {
          userMeals.add(updatedMeal);
        });
      }

      final cleanName = stripHtmlTags(updatedMeal.name);
      if (mounted) {
        CustomSnackbar.show(
          context,
          '$cleanName ${lang.getText("added")}',
          backgroundColor: primaryOrange,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return FutureBuilder<List<UserMealDto>>(
      future: futureMeals,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(backgroundColor: Colors.transparent),
            body: Center(child: Text('Hiba: ${snapshot.error}')),
          );
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
            extendBodyBehindAppBar: true,
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                margin: const EdgeInsets.all(5),
                child: AppBar(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: ClipRect(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                              sigmaX: 10.0,
                              sigmaY: 10.0,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color.fromRGBO(45, 45, 45, 0.5),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.arrow_back),
                                    color: Colors.white,
                                    padding: EdgeInsets.only(
                                      left: 0,
                                      top: 0,
                                      bottom: 0,
                                      right: 10,
                                    ),
                                    constraints: const BoxConstraints(),
                                    style: IconButton.styleFrom(
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: () {
                                      if (widget.addToTemplate) {
                                        Navigator.pop(context, templateMeals);
                                      } else {
                                        Navigator.pop(context, userMeals);
                                      }
                                    },
                                  ),
                                  Text(
                                    lang.getText("add"),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  automaticallyImplyLeading: false,
                  backgroundColor: Colors.transparent,
                  iconTheme: const IconThemeData(color: Colors.white),
                ),
              ),
            ),
            body: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(height: MediaQuery.of(context).padding.top + 70),

                // Kereső és Barcode egy sorban
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
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
                              fillColor: const Color.fromARGB(255, 45, 45, 45),
                              hintText: lang.getText("search_hint"),
                              hintStyle: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.white54,
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
                                borderRadius: BorderRadius.circular(16),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: primaryOrange,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: Colors.white24,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Barcode scanner gomb
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: primaryOrange.withOpacity(0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: primaryOrange),
                          ),
                          padding: const EdgeInsets.all(12),
                        ),
                        onPressed: () {
                          Future.microtask(() async {
                            bool hasPopped = false;
                            final scannedCode = await Navigator.of(context)
                                .push<String>(
                                  MaterialPageRoute(
                                    builder: (context) => AiBarcodeScanner(
                                      onDetect: (capture) {
                                        if (hasPopped) return;
                                        final code =
                                            capture.barcodes.first.rawValue;
                                        if (code != null) {
                                          hasPopped = true;
                                          Navigator.of(context).pop(code);
                                        }
                                      },
                                    ),
                                  ),
                                );

                            if (scannedCode != null && scannedCode.isNotEmpty) {
                              final results = await fetchMealsByBarcode(
                                scannedCode,
                              );
                              if (results.isNotEmpty) {
                                setState(() {
                                  searchResults = results;
                                  anyResults = true;
                                });
                              } else {
                                if (mounted) {
                                  CustomSnackbar.show(
                                    context,
                                    lang.getText("no_meal_found_barcode"),
                                    backgroundColor: Colors.red,
                                  );
                                }
                              }
                            }
                          });
                        },
                        icon: const Icon(
                          CupertinoIcons.barcode,
                          size: 24,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: !anyResults
                      ? ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.only(bottom: 80),
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            return _buildMealItem(
                              searchResults[index],
                              Provider.of<LanguageProvider>(
                                context,
                                listen: false,
                              ).languageCode,
                              lang,
                            );
                          },
                        )
                      : isLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.only(bottom: 80),
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            return _buildMealItem(
                              searchResults[index],
                              Provider.of<LanguageProvider>(
                                context,
                                listen: false,
                              ).languageCode,
                              lang,
                            );
                          },
                        ),
                ),
              ],
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
              backgroundColor: primaryOrange,
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
