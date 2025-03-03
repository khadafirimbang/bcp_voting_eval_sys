import 'package:SSCVote/voter_pages/profile.dart';
import 'package:flutter/material.dart';
import 'package:SSCVote/admin_pages/chatbot_question_type.dart';
import 'package:SSCVote/admin_pages/dashboard2.dart';
import 'package:SSCVote/admin_pages/drawerbar_admin.dart';
import 'package:SSCVote/main.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ChatbotAdminPage extends StatefulWidget {
  @override
  _ChatbotAdminPageState createState() => _ChatbotAdminPageState();
}

class _ChatbotAdminPageState extends State<ChatbotAdminPage> {
  List<Map<String, dynamic>> questions = [];
  List<String> questionTypes = [];
  String? selectedQuestionType;
  bool isLoading = true;
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  @override
  void initState() {
    super.initState();
    fetchQuestions();
    fetchQuestionTypes();
  }

  // Fetch questions from API
  Future<void> fetchQuestions() async {
    final url = Uri.parse('https://studentcouncil.bcp-sms1.com/php/chatbot_questions.php');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          questions = List<Map<String, dynamic>>.from(data);
          isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Failed to load questions.'),
        ));
        throw Exception('Failed to load questions.');
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching questions: $error');
    }
  }

  // Fetch question types from API
  Future<void> fetchQuestionTypes() async {
    final url = Uri.parse('https://studentcouncil.bcp-sms1.com/php/fetch_chatbot_question_type.php');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          questionTypes = (data as List).map((item) => item['type_name'] as String).toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Failed to load question types.'),
        ));
        throw Exception('Failed to load question types.');
      }
    } catch (error) {
      print('Error fetching question types: $error');
    }
  }

  // Add new question
  Future<void> addQuestion(String question, String answer, String type) async {
    final url = Uri.parse('https://studentcouncil.bcp-sms1.com/php/add_chatbot_question.php');
    try {
      final response = await http.post(url, body: {
        'question': question,
        'answer': answer,
        'type': type,
      });

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Add question successfully!'),
        ));
        fetchQuestions();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Add question failed!'),
        ));
        throw Exception('Failed to add question.');
      }
    } catch (error) {
      print('Error adding question: $error');
    }
  }

  // Edit question
  Future<void> editQuestion(String id, String question, String answer, String type) async {
    final url = Uri.parse('https://studentcouncil.bcp-sms1.com/php/edit_chatbot_question.php');
    try {
      final response = await http.post(url, body: {
        'id': id,
        'question': question,
        'answer': answer,
        'type': type,
      });

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Edit question successfully!'),
        ));
        fetchQuestions();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Edit question failed!'),
        ));
        throw Exception('Failed to edit question.');
      }
    } catch (error) {
      print('Error editing question: $error');
    }
  }

  // Delete question
  Future<void> deleteQuestion(String id) async {
    final url = Uri.parse('https://studentcouncil.bcp-sms1.com/php/delete_chatbot_question.php');
    try {
      final response = await http.post(url, body: {
        'id': id,
      });

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Delete question successfully!'),
        ));
        fetchQuestions();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Delete question failed!'),
        ));
        throw Exception('Failed to delete question.');
      }
    } catch (error) {
      print('Error deleting question: $error');
    }
  }

  // Show dialog for adding a new question
  void showAddQuestionDialog() {
    final questionController = TextEditingController();
    final answerController = TextEditingController();
    String? selectedAddQuestionType;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Question'),
          content: Container(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: questionController,
                  decoration: InputDecoration(labelText: 'Question'),
                ),
                TextField(
                  controller: answerController,
                  decoration: InputDecoration(labelText: 'Answer'),
                ),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: 'Question Type'),
                  value: selectedAddQuestionType,
                  items: questionTypes.map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  )).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedAddQuestionType = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final question = questionController.text.trim();
                final answer = answerController.text.trim();

                if (question.isNotEmpty && answer.isNotEmpty && selectedAddQuestionType != null) {
                  addQuestion(question, answer, selectedAddQuestionType!);
                  Navigator.of(context).pop();
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  // Show dialog for editing an existing question
  void showEditQuestionDialog(Map<String, dynamic> questionData) {
    final questionController = TextEditingController(text: questionData['question']);
    final answerController = TextEditingController(text: questionData['answer']);
    String? selectedEditQuestionType = questionData['type'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Question'),
          content: Container(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: questionController,
                  decoration: InputDecoration(labelText: 'Question'),
                ),
                TextField(
                  controller: answerController,
                  decoration: InputDecoration(labelText: 'Answer'),
                ),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: 'Question Type'),
                  value: selectedEditQuestionType,
                  items: questionTypes.map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  )).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedEditQuestionType = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final question = questionController.text.trim();
                final answer = answerController.text.trim();

                if (question.isNotEmpty && answer.isNotEmpty && selectedEditQuestionType != null) {
                  editQuestion(questionData['id'].toString(), question, answer, selectedEditQuestionType!);
                  Navigator.of(context).pop();
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Show delete confirmation dialog
  void showDeleteConfirmationDialog(String questionId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Question'),
          content: Text('Are you sure you want to delete this question?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                deleteQuestion(questionId);
                Navigator.of(context).pop();
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // Get filtered questions based on search and selected type
  List<Map<String, dynamic>> getFilteredQuestions() {
    List<Map<String, dynamic>> filteredQuestions = questions;

    if (selectedQuestionType != null && selectedQuestionType!.isNotEmpty) {
      filteredQuestions = filteredQuestions.where((question) {
        return question['type'] == selectedQuestionType;
      }).toList();
    }

    if (searchController.text.isNotEmpty) {
      filteredQuestions = filteredQuestions.where((question) {
        return question['question'].toLowerCase().contains(searchController.text.toLowerCase());
      }).toList();
    }

    return filteredQuestions;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[200],
        key: _scaffoldKey,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(56), // Set height of the AppBar
          child: Container(
            height: 56,
            alignment: Alignment.center, // Align the AppBar in the center
            margin: const EdgeInsets.fromLTRB(16, 10, 16, 0), // Add margin to control width
            decoration: BoxDecoration(
              color: Colors.white, 
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3), // Shadow color
                  blurRadius: 8, // Blur intensity
                  spreadRadius: 1, // Spread radius
                  offset: const Offset(0, 4), // Vertical shadow position
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                  onPressed: () {
                    _scaffoldKey.currentState?.openDrawer();
                  },
                  icon: const Icon(Icons.menu, color: Colors.black45),
                ),
                const Text(
                  'Chatbot Mngmnt',
                  style: TextStyle(fontSize: 18, color: Colors.black54),
                ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                  icon: Icon(isSearching ? Icons.close : Icons.search),
                  onPressed: () {
                    setState(() {
                      isSearching = !isSearching;
                    });
                    if (!isSearching) {
                      searchController.clear();
                    }
                  },
                ),
                
                IconButton(onPressed: (){
                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => ChatbotAdminPage()),
                                  );
                }, icon: const Icon(Icons.refresh)),
                _buildProfileMenu(context)
                  ],
                )
              ],
            )
          ),
        ),
        drawer: const AppDrawerAdmin(),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (isSearching)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        decoration: const InputDecoration(
                          labelText: 'Search Questions',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            // Automatically filtered by the getFilteredQuestions method
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    // Position filter dropdown
                    DropdownButton<String>(
                      hint: Text('Filter by Type'),
                      value: selectedQuestionType,
                      items: [null, ...questionTypes].map((type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type ?? 'All'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedQuestionType = value;
                        });
                      },
                    ),
                  ],
                ),
                
                SizedBox(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.all(10.0),
                                    backgroundColor: Colors.black,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => ChatbotQuestionTypePage()),
                                    );
                                  },
                                  child: const Text('View Types', 
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                    const SizedBox(height: 16.0),
              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: getFilteredQuestions().length,
                        itemBuilder: (context, index) {
                          final questionData = getFilteredQuestions()[index];
                          return Card(
                            color: Colors.white,
                            elevation: 2,
                            child: ListTile(
                              title: Text(questionData['question']),
                              subtitle: Text(questionData['answer']),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit),
                                    onPressed: () => showEditQuestionDialog(questionData),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete),
                                    onPressed: () => showDeleteConfirmationDialog(questionData['id'].toString()),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: showAddQuestionDialog,
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}

Widget _buildProfileMenu(BuildContext context) {
    return PopupMenuButton<int>(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onSelected: (item) {
        switch (item) {
          case 0:
            // Navigate to Profile page
            Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileInfoPage()));
            break;
          case 1:
            // Handle sign out
            _logout(context); // Example action for Sign Out
            break;
        }
      },
      offset: Offset(0, 50), // Adjust dropdown position
      itemBuilder: (context) => [
        PopupMenuItem<int>(
          padding: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
          value: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Signed in as', style: TextStyle(color: Colors.black54)),
              Text(studentNo ?? 'Unknown'),
            ],
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem<int>(
          value: 0,
          child: Row(
            children: [
              Icon(Icons.person, color: Colors.black54),
              SizedBox(width: 10),
              Text('Profile'),
            ],
          ),
        ),
        PopupMenuItem<int>(
          value: 1,
          child: Row(
            children: [
              Icon(Icons.logout, color: Colors.black54),
              SizedBox(width: 10),
              Text('Sign out'),
            ],
          ),
        ),
      ],
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: Colors.black54),
          ),
        ],
      ),
    );
  }
  
  void _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!context.mounted) return; // Ensure the widget is still mounted

    // Use pushAndRemoveUntil to clear the navigation stack
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoadingScreen()), // Replace with your login page
      (Route<dynamic> route) => false, // Remove all previous routes
    );
  }