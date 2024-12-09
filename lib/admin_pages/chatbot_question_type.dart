import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatbotQuestionTypePage extends StatefulWidget {
  @override
  _ChatbotQuestionTypePageState createState() => _ChatbotQuestionTypePageState();
}

class _ChatbotQuestionTypePageState extends State<ChatbotQuestionTypePage> {
  List<Map<String, dynamic>> _types = [];
  bool _isLoading = true;
  final TextEditingController _controller = TextEditingController();

  // Fetch question types from the backend
  Future<void> fetchTypes() async {
    final response = await http.get(Uri.parse('https://studentcouncil.bcp-sms1.com/php/chatbot_question_type.php'));

    if (response.statusCode == 200) {
      try {
        final decodedResponse = json.decode(response.body);
        if (decodedResponse is List) {
          setState(() {
            _types = decodedResponse.map((e) => e as Map<String, dynamic>).toList();
            _isLoading = false;
          });
        } else {
          throw FormatException('Unexpected response format');
        }
      } catch (e) {
        // Handle the case where the response is not valid JSON
        print("Error parsing JSON: $e");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.red,
          content: Text('Failed to load data.'),
        ));
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      // Handle error
      print('Failed to load data, status code: ${response.statusCode}');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Add a new type
  Future<void> addType(String typeName) async {
    final response = await http.post(
      Uri.parse('https://studentcouncil.bcp-sms1.com/php/chatbot_question_type.php'),
      body: {'type': typeName},
    );

    try {
      final result = json.decode(response.body);
      if (result['success'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.green,
          content: Text('New type added!'),
        ));
        fetchTypes(); // Refresh the list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Failed to add type.'),
        ));
        // Show error message
        print(result['error']);
      }
    } catch (e) {
      print("Error parsing JSON: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red,
        content: Text('Failed to add type, invalid response format.'),
      ));
    }
  }

  // Edit an existing type
  Future<void> editType(int id, String typeName) async {
    final response = await http.put(
      Uri.parse('https://studentcouncil.bcp-sms1.com/php/chatbot_question_type.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'id': id, 'type_name': typeName}),
    );

    try {
      final result = json.decode(response.body);
      if (result['success'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Edit type successfully!'),
        ));
        fetchTypes(); // Refresh the list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Failed to edit type.'),
        ));
        // Show error message
        print(result['error']);
      }
    } catch (e) {
      print("Error parsing JSON: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red,
        content: Text('Failed to edit type, invalid response format.'),
      ));
    }
  }

  // Delete a type with confirmation dialog
  Future<void> deleteType(int id) async {
    final response = await http.delete(
      Uri.parse('https://studentcouncil.bcp-sms1.com/php/chatbot_question_type.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'id': id}),
    );

    try {
      final result = json.decode(response.body);
      if (result['success'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Delete type successfully!'),
        ));
        fetchTypes(); // Refresh the list
      } else {
        // Show error message
        print(result['error']);
      }
    } catch (e) {
      print("Error parsing JSON: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red,
        content: Text('Failed to delete type, invalid response format.'),
      ));
    }
  }

  // Show dialog for adding new type
  Future<void> showAddDialog() async {
    _controller.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Type'),
        content: TextField(
          controller: _controller,
          decoration: InputDecoration(hintText: 'Enter type name'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_controller.text.isNotEmpty) {
                addType(_controller.text);
                Navigator.pop(context);
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  // Show dialog for editing type
  Future<void> showEditDialog(int id, String currentName) async {
    _controller.text = currentName;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Type'),
        content: TextField(
          controller: _controller,
          decoration: InputDecoration(hintText: 'Enter new type name'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_controller.text.isNotEmpty) {
                editType(id, _controller.text);
                Navigator.pop(context);
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  // Show confirmation dialog for deletion
  Future<void> showDeleteDialog(int id) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Type'),
        content: Text('Are you sure you want to delete this type?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              deleteType(id);
              Navigator.pop(context);
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchTypes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chatbot Question Types'),

      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                ElevatedButton(
                  onPressed: showAddDialog,
                  child: Text('Add New Type'),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _types.length,
                    itemBuilder: (context, index) {
                      final type = _types[index];
                      return ListTile(
                        title: Text(type['type_name']),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () {
                                showEditDialog(type['id'], type['type_name']);
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () {
                                showDeleteDialog(type['id']);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
