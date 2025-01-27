import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() => runApp(ChatBotApp());

class ChatBotApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ChatBotPage(),
    );
  }
}

class ChatBotPage extends StatefulWidget {
  @override
  _ChatBotPageState createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  final List<Map<String, String>> _messages = [];
  final String chatApiUrl =
      "https://bdbs.co.in/php_test_by_invo/anandhu/test/chat/index.php"; // Chat API URL
  final String queriesApiUrl =
      "https://bdbs.co.in/php_test_by_invo/anandhu/test/chat/queriessssssssssssss.php"; // Queries API URL

  List<String> _queries = []; // Queries list fetched from API
  final ScrollController _scrollController = ScrollController();
  bool _isUserInteracting = false;

  @override
  void initState() {
    super.initState();
    fetchQueries();
  }

  void fetchQueries() async {
    try {
      final response = await http.get(Uri.parse(queriesApiUrl));

      if (response.statusCode == 200) {
        // Clean up the response by removing any unwanted text before the JSON
        final rawData = response.body;
        final jsonString =
            rawData.substring(rawData.indexOf('{')); // Extract JSON part
        final data = json.decode(jsonString);

        setState(() {
          _queries = List<String>.from(data['queries']);
        });
      } else {
        print("Error: Unable to fetch queries.");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  void sendMessage(String message) async {
    setState(() {
      _messages.add({"user": message});
    });

    try {
      final response = await http.post(
        Uri.parse(chatApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"text": message}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _messages.add({"bot": data["reply"] ?? "No response"});
        });
      } else {
        setState(() {
          _messages.add({"bot": "Error: Unable to connect to the server."});
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({"bot": "Error: $e"});
      });
    }
  }

  void _onScroll() {
    // Detect when the user scrolls manually
    final offset = _scrollController.offset;
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (offset < maxScroll - 50) {
      setState(() {
        _isUserInteracting = true; // User is manually scrolling
      });
    } else {
      setState(() {
        _isUserInteracting =
            false; // User reached the bottom, allow auto-scrolling
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Chat Bot",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message.containsKey("user");

                return Container(
                  margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isUser
                          ? const Color.fromARGB(255, 241, 242, 244)
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isUser ? message["user"]! : message["bot"]!,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.grey[200],
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _queries.map((query) {
                  return GestureDetector(
                    onTap: () {
                      sendMessage(query);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        query,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // Auto-scroll to the latest message
  @override
  void setState(fn) {
    super.setState(fn);
    if (!_isUserInteracting) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }
}
