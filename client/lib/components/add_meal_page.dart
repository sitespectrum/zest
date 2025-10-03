import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AddMealPage extends StatefulWidget {
  const AddMealPage({super.key});

  @override
  State<AddMealPage> createState() => _AddMealPageState();
}

String stripHtmlTags(String htmlText) {
  final exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
  return htmlText.replaceAll(exp, '');
}

class Meal {
  final String id;
  final String foodId;
  final String name;
  final String piece;
  final String cal;
  final String protein;
  final String carbo;
  final String fat;

  Meal({
    required this.id,
    required this.foodId,
    required this.name,
    required this.piece,
    required this.cal,
    required this.protein,
    required this.carbo,
    required this.fat,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: json["id"] ?? "",
      foodId: json["food_id"] ?? "",
      name: json["name"] ?? "",
      piece: json["piece"] ?? "",
      cal: json["cal"] ?? "",
      protein: json["protein"] ?? "",
      carbo: json["carbo"] ?? "",
      fat: json["fat"] ?? "",
    );
  }
}

class _AddMealPageState extends State<AddMealPage> {
  final TextEditingController _controller = TextEditingController();
  List<Meal> searchResults = [];
  bool isLoading = false;

  List<Meal> userMeals = [];

  void addMeal(Meal meal) {
    setState(() {
      userMeals.add(meal);
    });
    final cleanName = stripHtmlTags(meal.name);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${cleanName} hozzáadva a listádhoz!')),
    );
  }

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _searchMeals(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      setState(() => searchResults = []);
      return;
    }

    setState(() => isLoading = true);

    try {
      final uri = Uri.https('kaloriabazis.hu', '/getfood.php', {
        'q': q,
        'p': '1',
        's': '1000',
        'expropsearch_id': '0',
        'expropsearch_inc': '0',
        'all_public_food': '0',
      });

      final headers = {'Cookie': 'myPHP83SESSID=bQa99fWhh5WMDMP8SJIwEZg24r;'};
      final response = await http.get(uri, headers: headers);

      if (response.statusCode != 200) {
        print('HTTP error: ${response.statusCode}');
        setState(() {
          searchResults = [];
        });
        return;
      }

      final body = response.body.trim();

      dynamic decoded;
      try {
        decoded = jsonDecode(body);
      } catch (e) {
        print('Nem JSON a válasz: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nincs találat vagy hiba történt.')),
          );
        }
        setState(() => searchResults = []);
        return;
      }

      List items = [];
      if (decoded is List) {
        items = decoded;
      } else if (decoded is Map<String, dynamic>) {
        if (decoded['results2'] is List) {
          items = decoded['results2'];
        } else if (decoded['results'] is List) {
          items = decoded['results'];
        } else if (decoded['data'] is List) {
          items = decoded['data'];
        } else {
          items = [];
        }
      } else {
        items = [];
      }

      final results = items
          .whereType<Map<String, dynamic>>()
          .map((e) => Meal.fromJson(e))
          .toList();

      setState(() {
        searchResults = results;
      });
    } catch (e, st) {
      print('Keresés hiba: $e\n$st');
      setState(() => searchResults = []);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, userMeals);
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
                              onChanged: _searchMeals,
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
                                hintText: 'Keresés',
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
                          onPressed: () {},
                          icon: const Icon(
                            CupertinoIcons.barcode,
                            size: 25,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      const SizedBox(width: 4),

                      Container(
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 200, 70, 70),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: IconButton(
                          onPressed: () {},
                          icon: const Icon(
                            CupertinoIcons.add_circled,
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

              isLoading
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
                            onTap: () {
                              addMeal(meal);
                            },
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
                                            '${meal.cal}',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            '${meal.protein} g protein',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            '${meal.carbo} g szénhidrát',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            '${meal.fat} g zsír',
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
          child: const Icon(Icons.arrow_upward, color: Colors.white, size: 32),
        ),
      ),
    );
  }
}
