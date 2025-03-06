import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Chatbot Model to represent individual messages
class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

// Predefined questions and answers from the database, grouped by type
class ChatbotData {
  static List<Map<String, dynamic>> questionsWithTypes = [];

  // Fetch questions and their types from PHP backend and order them by id
  static Future<void> fetchQuestions() async {
    try {
      final response = await http.get(Uri.parse('https://studentcouncil.bcp-sms1.com/php/chatbot_questions.php'));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        questionsWithTypes = data
            .map((item) => {
                  'id': item['id'] as int,
                  'question': item['question'] as String,
                  'answer': item['answer'] as String,
                  'type': item['type'] as String,
                })
            .toList();

        // Sort the questions by id
        questionsWithTypes.sort((a, b) => a['id'].compareTo(b['id']));
      } else {
        // Fallback questions if database fetch fails
        questionsWithTypes = [
          {'id': 1, 'question': 'Hello', 'answer': 'Hi there! How can I help you?', 'type': 'General'},
          {'id': 2, 'question': 'Help', 'answer': 'I can answer basic questions.', 'type': 'General'}
        ];
      }
    } catch (e) {
      // Error handling
      print('Error fetching questions: $e');
      questionsWithTypes = [
        {'id': 1, 'question': 'Hello', 'answer': 'Hi there! How can I help you?', 'type': 'General'},
        {'id': 2, 'question': 'Help', 'answer': 'I can answer basic questions.', 'type': 'General'}
      ];
    }
  }

  // Get all unique types
  static List<String> getUniqueTypes() {
    return questionsWithTypes
        .map((question) => question['type'] as String)
        .toSet()
        .toList();
  }

  // Get questions by type
  static List<Map<String, String>> getQuestionsByType(String type) {
    return questionsWithTypes
        .where((question) => question['type'] == type)
        .map((item) => {
              'question': item['question'] as String,
              'answer': item['answer'] as String,
            })
        .toList();
  }
}

class ChatbotScreen extends StatefulWidget {
  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  bool _isTyping = false;
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    _initializeChatbot();
  }

  Future<void> _initializeChatbot() async {
    await ChatbotData.fetchQuestions();
    setState(() {
      _isLoading = false;

      // Add welcome message automatically when chatbot initializes
      _messages.add(ChatMessage(
        text: 'Welcome to the Student Council Chatbot! 👋\n\n'
              'I can help you with various questions. '
              'Please select a category to get started.',
        isUser: false
      ));
    });
  }

  void _sendPredefinedMessage(String question, String answer) async {
    setState(() {
      _messages.add(ChatMessage(text: question, isUser: true));
      _isTyping = true; // Disable buttons
    });

    // Scroll to the latest question immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // Simulate typing delay for the answer
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _messages.add(ChatMessage(text: answer, isUser: false));
      _isTyping = false; // Enable buttons after delay
    });

    // Ensure scrolling after the typing indicator is removed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("FAQ's"),
          centerTitle: true,
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Chat messages list
                  Expanded(
                    flex: 3,
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: _messages.length + (_isTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index < _messages.length) {
                          return _buildMessageBubble(_messages[index]);
                        } else {
                          return _buildTypingIndicator();
                        }
                      },
                    ),
                  ),
      
                  // Type selection buttons or questions
                  if (_selectedType == null) ...[
                    // Type selection column
                    Expanded(
                      flex: 1,
                      child: ListView.builder(
                        itemCount: ChatbotData.getUniqueTypes().length,
                        itemBuilder: (context, index) {
                          var type = ChatbotData.getUniqueTypes()[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                            child: ElevatedButton(
                              onPressed: _isTyping
                                  ? null
                                  : () {
                                      setState(() {
                                        _selectedType = type;
                                      });
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                minimumSize: Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                type,
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ] else ...[
                    // Display questions for selected type
                    Expanded(
                      flex: 1,
                      child: ListView.builder(
                        itemCount: ChatbotData.getQuestionsByType(_selectedType!).length,
                        itemBuilder: (context, index) {
                          var question = ChatbotData.getQuestionsByType(_selectedType!)[index]['question']!;
                          var answer = ChatbotData.getQuestionsByType(_selectedType!)[index]['answer']!;
      
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                            child: ElevatedButton(
                              onPressed: _isTyping
                                  ? null
                                  : () => _sendPredefinedMessage(question, answer),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                minimumSize: Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                question,
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Back to Type Selection button
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: _isTyping
                            ? null
                            : () {
                                setState(() {
                                  _selectedType = null;
                                });
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                          minimumSize: Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Back to Type Selection',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  // Custom message bubble widget
  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: message.isUser ? Colors.blue[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.text,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  // Typing indicator widget
  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        padding: EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DotWidget(),
            SizedBox(width: 4),
            DotWidget(delay: 200),
            SizedBox(width: 4),
            DotWidget(delay: 300),
          ],
        ),
      ),
    );
  }
}

// Dot animation widget
class DotWidget extends StatefulWidget {
  final int delay;

  const DotWidget({this.delay = 0});

  @override
  _DotWidgetState createState() => _DotWidgetState();
}

class _DotWidgetState extends State<DotWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 4).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Start the animation after the specified delay
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -_animation.value),
          child: CircleAvatar(
            radius: 4,
            backgroundColor: Colors.grey,
          ),
        );
      },
    );
  }
}

// Main app widget
class ChatbotApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Predefined Questions Chatbot',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ChatbotScreen(),
    );
  }
}

void main() {
  runApp(ChatbotApp());
}
