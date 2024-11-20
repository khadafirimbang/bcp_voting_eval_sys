import 'package:flutter/material.dart';
import 'package:for_testing/admin_pages/drawerbar_admin.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PositionsPage extends StatefulWidget {
  const PositionsPage({super.key});

  @override
  State<PositionsPage> createState() => _PositionsPageState();
}

class _PositionsPageState extends State<PositionsPage> {
  late Future<List<dynamic>> _positions;

  @override
  void initState() {
    super.initState();
    _positions = _fetchPositions();
  }

  Future<List<dynamic>> _fetchPositions() async {
    try {
      final response = await http.get(Uri.parse(
          'https://studentcouncil.bcp-sms1.com/php/fetch_positions.php')); // Replace with your URL
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == 'success') {
          return jsonResponse['data']; // Only return the 'data' without 'id'
        } else {
          throw Exception(jsonResponse['message']);
        }
      } else {
        throw Exception('Failed to load positions');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> _editPosition(String positionId, String newName) async {
    try {
      final response = await http.post(
        Uri.parse('https://studentcouncil.bcp-sms1.com/php/edit_position.php'),
        body: {'id': positionId, 'name': newName},
      );
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['status'] == 'success') {
        setState(() {
          _positions = _fetchPositions();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Position updated successfully'), backgroundColor: Colors.green),
        );
      } else {
        throw Exception(jsonResponse['message']);
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Fixing the deletePosition function: convert id to string
  Future<void> _deletePosition(String positionId) async {
    try {
      // Convert positionId to String
      final response = await http.post(
        Uri.parse('https://studentcouncil.bcp-sms1.com/php/delete_position.php'),
        body: {'id': positionId.toString()},  // Ensure positionId is a string
      );
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['status'] == 'success') {
        setState(() {
          _positions = _fetchPositions();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Position deleted successfully'), backgroundColor: Colors.green),
        );
      } else {
        throw Exception(jsonResponse['message']);
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> _addPosition(String name) async {
    try {
      final response = await http.post(
        Uri.parse('https://studentcouncil.bcp-sms1.com/php/add_position.php'),
        body: {'name': name},
      );
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['status'] == 'success') {
        setState(() {
          _positions = _fetchPositions();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Position added successfully'), backgroundColor: Colors.green,),
        );
      } else {
        throw Exception(jsonResponse['message']);
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Dialog to add or edit position
  Future<void> _showPositionDialog({String? positionId, String? initialName}) async {
    final nameController = TextEditingController(text: initialName);

    return showDialog<void>( // Fixed the 'showDialog' function signature
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(positionId == null ? 'Add Position' : 'Edit Position'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: 'Position Name'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                final name = nameController.text.trim();
                if (positionId == null) {
                  _addPosition(name);
                } else {
                  _editPosition(positionId, name); // positionId is a String
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Confirm delete dialog
  Future<void> _confirmDelete(String positionId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this position?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                _deletePosition(positionId); // positionId passed as string
                Navigator.of(context).pop();
              },
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
        backgroundColor: const Color(0xFF1E3A8A),
        title: const Text('Positions', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<dynamic>>(
          future: _positions,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No positions found.'));
            } else {
              final positions = snapshot.data!;
              return ListView.builder(
                itemCount: positions.length,
                itemBuilder: (context, index) {
                  final position = positions[index];
                  return Card(
                    color: Colors.white,
                    elevation: 2,
                    child: ListTile(
                      title: Text(position['name']), // Display the 'name'
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              _showPositionDialog(positionId: position['id'].toString(), initialName: position['name']);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              _confirmDelete(position['id'].toString()); // Ensure ID is passed as a string
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1E3A8A),
        onPressed: () => _showPositionDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
