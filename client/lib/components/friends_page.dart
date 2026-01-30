import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import 'package:client/Providers/language_provider.dart';

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

  void _showSnackBar(
    String message, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    Color backgroundColor = const Color.fromARGB(255, 45, 45, 45);
    Color iconColor = Colors.white;

    if (isSuccess) {
      backgroundColor = Colors.green.shade800;
      iconColor = Colors.white;
    } else if (isError) {
      backgroundColor = Colors.red.shade900;
      iconColor = Colors.white;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess
                  ? Icons.check_circle
                  : (isError ? Icons.error : Icons.info),
              color: iconColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
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
    } catch (e) {
      // Hiba kezelés
    }
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
    } catch (e) {
      // Hiba kezelése
    }
  }

  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() => searchResults = []);
      return;
    }

    setState(() => isLoading = true);
    final token = await _getToken();
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse("$apiUrl/api/Friends/search?query=$query"),
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
      _showSnackBar(lang.getText("request_sent"), isSuccess: true);

      setState(() {
        searchResults.removeWhere((u) => u['id'] == userId);
      });
    } else {
      _showSnackBar(
        "${lang.getText("error_occurred")}: ${response.body}",
        isError: true,
      );
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
        _showSnackBar(lang.getText("friend_added"), isSuccess: true);
      } else {
        _showSnackBar(lang.getText("request_declined"), isError: false);
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
        _showSnackBar(
          lang.getText("friend_deleted_successfully"),
          isSuccess: true,
        );
      } else {
        _showSnackBar(lang.getText("error_occurred"), isError: true);
      }
    } catch (e) {
      _showSnackBar(lang.getText("error_occurred"), isError: true);
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
      appBar: AppBar(
        title: Text(
          lang.getText("friends_title"),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.green,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(text: lang.getText("my_friends")),
            Tab(
              text: "${lang.getText("requests")} (${pendingRequests.length})",
            ),
            Tab(text: lang.getText("search")),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFriendsList(lang),
          _buildRequestsList(lang),
          _buildSearchPage(lang),
        ],
      ),
    );
  }

  Widget _buildFriendsList(LanguageProvider lang) {
    if (friends.isEmpty) {
      return Center(
        child: Text(
          lang.getText("no_friends_yet"),
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }
    return ListView.builder(
      itemCount: friends.length,
      itemBuilder: (context, index) {
        final friend = friends[index];
        return Card(
          color: const Color.fromARGB(255, 45, 45, 45),
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.green,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text(
              friend['userName'],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _confirmDelete(friend['id'], friend['userName']),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRequestsList(LanguageProvider lang) {
    if (pendingRequests.isEmpty) {
      return Center(
        child: Text(
          lang.getText("no_pending_requests"),
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }
    return ListView.builder(
      itemCount: pendingRequests.length,
      itemBuilder: (context, index) {
        final req = pendingRequests[index];
        return Card(
          color: const Color.fromARGB(255, 45, 45, 45),
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            title: Text(
              req['userName'],
              style: const TextStyle(color: Colors.white),
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
    );
  }

  Widget _buildSearchPage(LanguageProvider lang) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
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
                      leading: const Icon(
                        Icons.person_add_alt,
                        color: Colors.white,
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
