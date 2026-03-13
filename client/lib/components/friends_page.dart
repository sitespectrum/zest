import 'dart:convert';
import 'dart:async';
import 'dart:ui';
import 'package:client/components/ui/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import 'package:client/providers/language_provider.dart';
import 'friend_profile_page.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> friends = [];
  List<dynamic> pendingRequests = [];
  List<dynamic> searchResults = [];
  TextEditingController searchController = TextEditingController();
  Timer? _debounce;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchFriends();
    fetchRequests();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<void> fetchFriends() async {
    final token = await _getToken();
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse("$apiUrl/api/Friends/list"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            friends = jsonDecode(response.body);
          });
        }
      }
    } catch (e) {}
  }

  Future<void> fetchRequests() async {
    final token = await _getToken();
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse("$apiUrl/api/Friends/requests"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            pendingRequests = jsonDecode(response.body);
          });
        }
      }
    } catch (e) {}
  }

  Future<void> searchUsers(String query) async {
    if (!mounted) return;
    if (query.isEmpty) {
      setState(() => searchResults = []);
      return;
    }

    setState(() => isLoading = true);
    final token = await _getToken();
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse("$apiUrl/api/Friends/search?query=${query.toLowerCase()}"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (mounted) {
        setState(() => isLoading = false);
        if (response.statusCode == 200) {
          setState(() {
            searchResults = jsonDecode(response.body);
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> sendRequest(int userId) async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final token = await _getToken();
    if (token == null) return;

    final response = await http.post(
      Uri.parse("$apiUrl/api/Friends/request/$userId"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      CustomSnackbar.show(
        context,
        lang.getText("request_sent"),
        backgroundColor: Colors.green,
      );

      setState(() {
        searchResults.removeWhere((u) => u['id'] == userId);
      });
    } else {
      if (mounted) {
        CustomSnackbar.show(
          context,
          "${lang.getText("error_occurred")}: ${response.body}",
          backgroundColor: Colors.red,
        );
      }
    }
  }

  Future<void> respondToRequest(int requestId, bool accept) async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final token = await _getToken();
    if (token == null) return;

    final response = await http.post(
      Uri.parse("$apiUrl/api/Friends/respond"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"requestId": requestId, "accept": accept}),
    );

    if (response.statusCode == 200) {
      fetchRequests();
      if (accept) fetchFriends();

      if (accept) {
        CustomSnackbar.show(
          context,
          lang.getText("friend_added"),
          backgroundColor: Colors.green,
        );
      } else {
        CustomSnackbar.show(
          context,
          lang.getText("request_declined"),
          backgroundColor: Colors.red,
        );
      }
    }
  }

  Future<void> deleteFriend(int friendId) async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final token = await _getToken();
    if (token == null) return;

    try {
      final response = await http.delete(
        Uri.parse("$apiUrl/api/Friends/delete/$friendId"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        setState(() {
          friends.removeWhere((f) => f['id'] == friendId);
        });
        CustomSnackbar.show(
          context,
          lang.getText("friend_deleted_successfully"),
          backgroundColor: Colors.green,
        );
      } else {
        if (mounted) {
          CustomSnackbar.show(
            context,
            lang.getText("error_occurred"),
            backgroundColor: Colors.red,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(
          context,
          lang.getText("error_occurred"),
          backgroundColor: Colors.red,
        );
      }
    }
  }

  void _confirmDelete(int friendId, String friendName) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 45, 45, 45),
        title: Text(
          lang.getText("delete_friend_title"),
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          "${lang.getText("sure_delete_friend")} $friendName?",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              lang.getText("cancel"),
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              deleteFriend(friendId);
            },
            child: Text(
              lang.getText("delete"),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 30, 30, 30),
      body: RefreshIndicator(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10.0,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color.fromRGBO(45, 45, 45, 0.5),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back),
                                color: Colors.white,
                                padding: const EdgeInsets.only(right: 10),
                                constraints: const BoxConstraints(),
                                style: IconButton.styleFrom(
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                              Text(
                                lang.getText("friends_title"),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          Container(
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(50, 64, 255, 50),
                              border: Border.all(
                                color: const Color.fromARGB(100, 64, 255, 50),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: TabBar(
                              controller: _tabController,
                              labelStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              splashFactory: NoSplash.splashFactory,
                              indicator: BoxDecoration(
                                color: const Color.fromARGB(100, 64, 255, 50),
                                shape: BoxShape.rectangle,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              indicatorSize: TabBarIndicatorSize.tab,
                              indicatorPadding: const EdgeInsets.all(4),
                              dividerHeight: 0,
                              labelColor: Colors.white,
                              unselectedLabelColor: Colors.grey,
                              indicatorColor: Colors.transparent,
                              tabs: [
                                Tab(text: lang.getText("my_friends")),
                                Tab(
                                  text:
                                      "${lang.getText("requests")} (${pendingRequests.length})",
                                ),
                                Tab(text: lang.getText("search")),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFriendsList(lang),
                    _buildRequestsList(lang),
                    _buildSearchPage(lang),
                  ],
                ),
              ),
            ],
          ),
        ),
        onRefresh: () async => {fetchFriends(), fetchRequests()},
      ),
    );
  }

  Widget _buildFriendsList(LanguageProvider lang) {
    if (friends.isEmpty) {
      return RefreshIndicator(
        color: Colors.green,
        onRefresh: () => fetchFriends(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: Center(
                child: Text(
                  lang.getText("no_friends_yet"),
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: friends.length,
        itemBuilder: (context, index) {
          final friend = friends[index];
          return Card(
            color: const Color.fromARGB(255, 45, 45, 45),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green,
                backgroundImage:
                    (friend['profilePicture'] != null &&
                        friend['profilePicture'].toString().isNotEmpty)
                    ? MemoryImage(base64Decode(friend['profilePicture']))
                    : null,
                child:
                    (friend['profilePicture'] == null ||
                        friend['profilePicture'].toString().isEmpty)
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
              ),
              title: Text(
                friend['userName'],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.account_box,
                      color: Colors.blueAccent,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FriendProfilePage(
                            friendId: friend['id'],
                            friendName: friend['userName'],
                            friendImage: friend['profilePicture'],
                          ),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                    onPressed: () =>
                        _confirmDelete(friend['id'], friend['userName']),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      onRefresh: () => fetchFriends(),
    );
  }

  Widget _buildRequestsList(LanguageProvider lang) {
    if (pendingRequests.isEmpty) {
      return RefreshIndicator(
        color: Colors.green,
        onRefresh: () => fetchRequests(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: Center(
                child: Text(
                  lang.getText("no_pending_requests"),
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      child: ListView.builder(
        itemCount: pendingRequests.length,
        itemBuilder: (context, index) {
          final req = pendingRequests[index];
          return Card(
            color: const Color.fromARGB(255, 45, 45, 45),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green,
                backgroundImage:
                    (req['profilePicture'] != null &&
                        req['profilePicture'].toString().isNotEmpty)
                    ? MemoryImage(base64Decode(req['profilePicture']))
                    : null,
                child:
                    (req['profilePicture'] == null ||
                        req['profilePicture'].toString().isEmpty)
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
              ),
              title: Text(
                req['userName'],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                lang.getText("friend_request_subtitle"),
                style: const TextStyle(color: Colors.grey),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 30,
                    ),
                    onPressed: () => respondToRequest(req['requestId'], true),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
                    onPressed: () => respondToRequest(req['requestId'], false),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      onRefresh: () => fetchRequests(),
    );
  }

  Widget _buildSearchPage(LanguageProvider lang) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: TextField(
            controller: searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: lang.getText("search_username_hint"),
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              filled: true,
              fillColor: const Color.fromARGB(255, 45, 45, 45),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (val) {
              if (_debounce?.isActive ?? false) _debounce!.cancel();
              _debounce = Timer(const Duration(milliseconds: 500), () {
                searchUsers(val);
              });
            },
          ),
        ),
        isLoading
            ? const CircularProgressIndicator(color: Colors.green)
            : Expanded(
                child: ListView.builder(
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    final user = searchResults[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green,
                        backgroundImage:
                            (user['profilePicture'] != null &&
                                user['profilePicture'].toString().isNotEmpty)
                            ? MemoryImage(base64Decode(user['profilePicture']))
                            : null,
                        child:
                            (user['profilePicture'] == null ||
                                user['profilePicture'].toString().isEmpty)
                            ? const Icon(
                                Icons.person_add_alt,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      title: Text(
                        user['userName'],
                        style: const TextStyle(color: Colors.white),
                      ),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        onPressed: () => sendRequest(user['id']),
                        child: Text(
                          lang.getText("send_request"),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }
}
