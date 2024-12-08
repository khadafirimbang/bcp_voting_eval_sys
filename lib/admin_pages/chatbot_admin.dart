import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatbotAdminPage extends StatefulWidget {
  @override
  _ChatbotAdminPageState createState() => _ChatbotAdminPageState();
}

class _ChatbotAdminPageState extends State<ChatbotAdminPage> {
  List<Map<String, dynamic>> questions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchQuestions();
  }

  Future<void> fetchQuestions() async {
    final url = Uri.parse('https://studentcouncil.bcp-sms1.com/php/chatbot_questions.php'); // Update with your PHP URL
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          questions = List<Map<String, dynamic>>.from(data);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load questions.');
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching questions: $error');
    }
  }

  Future<void> addQuestion(String question, String answer) async {
    final url = Uri.parse('https://studentcouncil.bcp-sms1.com/php/add_chatbot_question.php');
    try {
      final response = await http.post(url, body: {
        'question': question,
        'answer': answer,
      });

      if (response.statusCode == 200) {
        fetchQuestions();
      } else {
        throw Exception('Failed to add question.');
      }
    } catch (error) {
      print('Error adding question: $error');
    }
  }

  Future<void> editQuestion(String id, String question, String answer) async {
    final url = Uri.parse('https://studentcouncil.bcp-sms1.com/php/edit_chatbot_question.php');
    try {
      final response = await http.post(url, body: {
        'id': id,
        'question': question,
        'answer': answer,
      });

      if (response.statusCode == 200) {
        fetchQuestions();
      } else {
        throw Exception('Failed to edit question.');
      }
    } catch (error) {
      print('Error editing question: $error');
    }
  }

  Future<void> deleteQuestion(String id) async {
    final url = Uri.parse('https://studentcouncil.bcp-sms1.com/php/delete_chatbot_question.php');
    try {
      final response = await http.post(url, body: {
        'id': id,
      });

      if (response.statusCode == 200) {
        fetchQuestions();
      } else {
        throw Exception('Failed to delete question.');
      }
    } catch (error) {
      print('Error deleting question: $error');
    }
  }

  void showAddQuestionDialog() {
    final questionController = TextEditingController();
    final answerController = TextEditingController();

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

                if (question.isNotEmpty && answer.isNotEmpty) {
                  addQuestion(question, answer);
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

  void showEditQuestionDialog(Map<String, dynamic> questionData) {
    final questionController = TextEditingController(text: questionData['question']);
    final answerController = TextEditingController(text: questionData['answer']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Question'),
          content: Container(
            width: 400, // Set the fixed width here
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

                if (question.isNotEmpty && answer.isNotEmpty) {
                  editQuestion(questionData['id'].toString(), question, answer); // Convert to String
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
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                deleteQuestion(questionId); // Proceed to delete the question
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chatbot Admin'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: showAddQuestionDialog,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final questionData = questions[index];

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
                        onPressed: () => showDeleteConfirmationDialog(questionData['id'].toString()), // Show delete confirmation
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
