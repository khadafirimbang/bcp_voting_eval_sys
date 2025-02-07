import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PartyListPage extends StatefulWidget {
  const PartyListPage({super.key});

  @override
  State<PartyListPage> createState() => _PartyListPageState();
}

class _PartyListPageState extends State<PartyListPage> {
  late Future<List<dynamic>> _partyLists;

  @override
  void initState() {
    super.initState();
    _partyLists = _fetchPartyLists();
  }

  Future<List<dynamic>> _fetchPartyLists() async {
    try {
      final response = await http.get(Uri.parse(
          'https://studentcouncil.bcp-sms1.com/php/fetch_partylist.php')); // Replace with your URL

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        // Check if the response is a list
        if (jsonResponse is List) {
          return jsonResponse; // Return the entire list if it's an array
        } else {
          // Handle case where response is not a list
          throw Exception('Expected a list but got ${jsonResponse.runtimeType}');
        }
      } else {
        throw Exception('Failed to load party lists');
      }
    } catch (e) {
      rethrow;
    }
}

  Future<void> _editPartyList(String partyListId, String newName) async {
    try {
      final response = await http.post(
        Uri.parse('https://studentcouncil.bcp-sms1.com/php/edit_partylist.php'),
        body: {'id': partyListId, 'name': newName},
      );
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['status'] == 'success') {
        setState(() {
          _partyLists = _fetchPartyLists();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Partylist updated successfully'), backgroundColor: Colors.green,),
        );
      } else {
        throw Exception(jsonResponse['message']);
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> _deletePartyList(String partyListId) async {
    try {
      final response = await http.post(
        Uri.parse('https://studentcouncil.bcp-sms1.com/php/delete_partylist.php'),
        body: {'id': partyListId},
      );
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['status'] == 'success') {
        setState(() {
          _partyLists = _fetchPartyLists();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Partylist deleted successfully'), backgroundColor: Colors.green),
        );
      } else {
        throw Exception(jsonResponse['message']);
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> _addPartyList(String name) async {
    try {
      final response = await http.post(
        Uri.parse('https://studentcouncil.bcp-sms1.com/php/add_partylist.php'),
        body: {'name': name},
      );
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['status'] == 'success') {
        setState(() {
          _partyLists = _fetchPartyLists();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Partylist added successfully'), backgroundColor: Colors.green),
        );
      } else {
        throw Exception(jsonResponse['message']);
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Dialog to add or edit party list
  Future<void> _showPartyListDialog({String? partyListId, String? initialName}) async {
    final nameController = TextEditingController(text: initialName);

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(partyListId == null ? 'Add Party List' : 'Edit Party List'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: 'Party List Name'),
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
                if (partyListId == null) {
                  _addPartyList(name);
                } else {
                  _editPartyList(partyListId, name);
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
  Future<void> _confirmDelete(String partyListId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this party list?'),
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
                _deletePartyList(partyListId);
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
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Partylists'),
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 50),
          child: FutureBuilder<List<dynamic>>(
            future: _partyLists,
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
                return const Center(child: Text('No party lists found.'));
              } else {
                final partyLists = snapshot.data!;
                return ListView.builder(
                  itemCount: partyLists.length,
                  itemBuilder: (context, index) {
                    final partyList = partyLists[index];
                    return SingleChildScrollView(
                      child: Card(
                        color: Colors.white,
                        elevation: 2,
                        child: ListTile(
                          title: Text(partyList['name']),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  _showPartyListDialog(
                                      partyListId: partyList['id'].toString(),
                                      initialName: partyList['name']);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  _confirmDelete(partyList['id'].toString());
                                },
                              ),
                            ],
                          ),
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
          backgroundColor: Colors.black,
          onPressed: () => _showPartyListDialog(),
          child: const Icon(Icons.add, color: Colors.white,),
        ),
      ),
    );
  }
}
