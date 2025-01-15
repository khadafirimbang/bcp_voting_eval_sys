import 'package:flutter/material.dart';
import 'package:for_testing/admin_pages/chatbot_question_type.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
    return Scaffold(
      appBar: AppBar(
        title: Text('Chatbot Questions'),
        actions: [
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
              // Position filter dropdown
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButton<String>(
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
              ),
              IconButton(onPressed: (){
                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => ChatbotAdminPage()),
                                );
              }, icon: const Icon(Icons.refresh))
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (isSearching)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
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
                const SizedBox(width: 10.0),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: getFilteredQuestions().length,
                    itemBuilder: (context, index) {
                      final questionData = getFilteredQuestions()[index];
                      return ListTile(
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
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddQuestionDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}
