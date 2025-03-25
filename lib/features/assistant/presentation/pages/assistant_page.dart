import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class AssistantPage extends StatefulWidget {
  const AssistantPage({Key? key}) : super(key: key);

  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage>
    with TickerProviderStateMixin {
  final List<Map<String, String>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  late AnimationController _typingDot1;
  late AnimationController _typingDot2;
  late AnimationController _typingDot3;

  final List<Map<String, dynamic>> _predefinedQuestions = [
    {
      "icon": Icons.map,
      "text": "How do I navigate the map to locate charging stations?",
    },
    {
      "icon": Icons.ev_station,
      "text":
          "What types of charging stations are available (Level 1, 2, DC Fast Charging)?",
    },
    {
      "icon": Icons.directions_car,
      "text": "Which charging stations are compatible with my EV?",
    },
    {
      "icon": Icons.timer,
      "text":
          "How long does it take to charge my EV and what factors affect charging times?",
    },
    {
      "icon": Icons.build,
      "text":
          "What are the best practices for EV battery maintenance and troubleshooting?",
    },
    {
      "icon": Icons.attach_money,
      "text": "What payment methods and charging networks are available?",
    }
  ];

  final String _backendUrl = "http://10.0.2.2:8000/chat";

  @override
  void initState() {
    super.initState();

    _typingDot1 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..repeat(reverse: true);

    _typingDot2 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..repeat(reverse: true, period: const Duration(milliseconds: 400));

    _typingDot3 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..repeat(reverse: true, period: const Duration(milliseconds: 500));

    _addBotMessage(
        "Hi there! I'm your EV Assistant. I can help you with finding charging stations, costs, scheduling, and more. What would you like to know today?");
  }

  @override
  void dispose() {
    _typingDot1.dispose();
    _typingDot2.dispose();
    _typingDot3.dispose();
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _addBotMessage(String message) {
    String botTime = DateFormat('h:mm a').format(DateTime.now());
    setState(() {
      _messages.add({
        "sender": "bot",
        "message": message,
        "timestamp": botTime,
      });
    });
    _scrollToBottom();
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    String currentTime = DateFormat('h:mm a').format(DateTime.now());
    setState(() {
      _messages.add({
        "sender": "user",
        "message": message,
        "timestamp": currentTime,
      });
      _isTyping = true;
    });
    _controller.clear();

    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"message": message}),
      );

      setState(() {
        _isTyping = false;
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String reply = data['reply'];
        String botTime = DateFormat('h:mm a').format(DateTime.now());
        setState(() {
          _messages.add({
            "sender": "bot",
            "message": reply,
            "timestamp": botTime,
          });
        });
      } else {
        _addBotMessage(
            "Sorry, I'm having trouble connecting to my services. Please try again later.");
      }
    } catch (error) {
      setState(() {
        _isTyping = false;
      });
      _addBotMessage(
          "Oops! I couldn't process your request. Please check your connection and try again.");
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showMorePredefinedQuestions() {
    List<Map<String, dynamic>> remainingQuestions =
        _predefinedQuestions.skip(3).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "More Questions",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: remainingQuestions.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            Theme.of(context).primaryColor.withOpacity(0.1),
                        child: Icon(
                          remainingQuestions[index]["icon"],
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      title: Text(remainingQuestions[index]["text"]),
                      onTap: () {
                        Navigator.pop(context);
                        _sendMessage(remainingQuestions[index]["text"]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPredefinedQuestions() {
    List<Map<String, dynamic>> initialQuestions =
        _predefinedQuestions.take(3).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: initialQuestions.map((q) {
              return Container(
                margin: const EdgeInsets.only(right: 12),
                child: InkWell(
                  onTap: () => _sendMessage(q["text"]),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(q["icon"], color: Theme.of(context).primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          q["text"],
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        if (_predefinedQuestions.length > 3)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _showMorePredefinedQuestions,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text(
                "More Questions",
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMessageItem(Map<String, String> message) {
    bool isUser = message["sender"] == "user";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(isUser),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        isUser ? Theme.of(context).primaryColor : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: isUser
                          ? const Radius.circular(20)
                          : const Radius.circular(5),
                      bottomRight: isUser
                          ? const Radius.circular(5)
                          : const Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message["message"] ?? "",
                    style: TextStyle(
                      fontSize: 15,
                      color: isUser ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Text(
                    message["timestamp"] ?? "",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isUser) _buildAvatar(isUser),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isUser) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isUser
            ? Theme.of(context).primaryColor.withOpacity(0.2)
            : Theme.of(context).primaryColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          isUser ? Icons.person : Icons.electric_car,
          size: 20,
          color: isUser ? Theme.of(context).primaryColor : Colors.white,
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(false),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildAnimatedDot(_typingDot1),
                const SizedBox(width: 4),
                _buildAnimatedDot(_typingDot2),
                const SizedBox(width: 4),
                _buildAnimatedDot(_typingDot3),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedDot(AnimationController controller) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8 * (0.5 + controller.value * 0.5), // Animate size
          decoration: BoxDecoration(
            color: Theme.of(context)
                .primaryColor
                .withOpacity(0.6 + controller.value * 0.4), // Animate opacity
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        primaryColor: const Color(0xFF4CAF50),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          foregroundColor: Colors.black87,
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('EV Assistant'),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                // TODO: Implement menu options
              },
            ),
          ],
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () {
              // TODO: Handle back navigation
            },
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.grey[50]!,
                Colors.grey[100]!,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        Color(0xFF66BB6A),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.electric_car,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "EV Assistant",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              "Get answers to all your EV questions",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Predefined questions section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildPredefinedQuestions(),
                ),
                // Date divider with style
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Colors.grey[300],
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "Today",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Colors.grey[300],
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                // Chat messages list
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isTyping) {
                        return _buildTypingIndicator();
                      }
                      return _buildMessageItem(_messages[index]);
                    },
                  ),
                ),
                // Modern chat input area
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.attach_file),
                        color: Colors.grey[600],
                        onPressed: () {
                          // TODO: Implement attachment feature
                        },
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: _controller,
                            decoration: InputDecoration(
                              hintText: 'Type your message...',
                              hintStyle: TextStyle(color: Colors.grey[500]),
                              border: InputBorder.none,
                            ),
                            onSubmitted: _sendMessage,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send_rounded),
                        color: Theme.of(context).primaryColor,
                        onPressed: () => _sendMessage(_controller.text),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
