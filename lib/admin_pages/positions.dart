import 'package:flutter/material.dart';
import 'package:SSCVote/admin_pages/drawerbar_admin.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PositionsPage extends StatefulWidget {
  const PositionsPage({super.key});

  @override
  State<PositionsPage> createState() => _PositionsPageState();
}

class _PositionsPageState extends State<PositionsPage> {
  late Future<List<dynamic>> _positions;
  Map<String, int> candidateCounts = {};

  @override
  void initState() {
    super.initState();
    _positions = _fetchPositionsAndCandidateCounts();
  }

  Future<List<dynamic>> _fetchPositionsAndCandidateCounts() async {
    try {
      // Fetch positions
      final positionsResponse = await http.get(
          Uri.parse('https://studentcouncil.bcp-sms1.com/php/fetch_positions.php'));

      // Fetch candidate counts
      final candidateCountsResponse = await http.get(
          Uri.parse('https://studentcouncil.bcp-sms1.com/php/fetch_total_running_candidates_pos.php'));

      if (positionsResponse.statusCode == 200 && candidateCountsResponse.statusCode == 200) {
        final positions = json.decode(positionsResponse.body);
        final counts = json.decode(candidateCountsResponse.body);
        
        // Store the counts in the map
        candidateCounts.clear();
        for (var count in counts) {
          candidateCounts[count['position']] = int.parse(count['count'].toString());
        }

        if (positions is List) {
          return positions;
        } else {
          throw Exception('Expected a list but got ${positions.runtimeType}');
        }
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      rethrow;
    }
  }


  Future<void> _editPosition(String positionId, String newName, String votesQty) async {
    try {
      if (votesQty.isEmpty || int.tryParse(votesQty) == null) {
        throw Exception('Votes Quantity must be a valid number');
      }
      final response = await http.post(
        Uri.parse('https://studentcouncil.bcp-sms1.com/php/edit_position.php'),
        body: {
          'id': positionId,
          'name': newName,
          'votes_qty': votesQty, // Ensure votes_qty is passed here
        },
      );
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['status'] == 'success') {
        setState(() {
          _positions = _fetchPositionsAndCandidateCounts();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Position updated successfully'),
              backgroundColor: Colors.green),
        );
      } else {
        throw Exception(jsonResponse['message']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _addPosition(String name, String votesQty) async {
    try {
      if (votesQty.isEmpty || int.tryParse(votesQty) == null) {
        throw Exception('Votes Quantity must be a valid number');
      }
      final response = await http.post(
        Uri.parse('https://studentcouncil.bcp-sms1.com/php/add_position.php'),
        body: {'name': name, 'votes_qty': votesQty}, // Ensure votes_qty is passed here
      );
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['status'] == 'success') {
        setState(() {
          _positions = _fetchPositionsAndCandidateCounts();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Position added successfully'),
              backgroundColor: Colors.green),
        );
      } else {
        throw Exception(jsonResponse['message']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deletePosition(String positionId) async {
    try {
      final response = await http.post(
        Uri.parse('https://studentcouncil.bcp-sms1.com/php/delete_position.php'),
        body: {'id': positionId},
      );
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['status'] == 'success') {
        setState(() {
          _positions = _fetchPositionsAndCandidateCounts();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Position deleted successfully'),
              backgroundColor: Colors.green),
        );
      } else {
        throw Exception(jsonResponse['message']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showPositionDialog(
      {String? positionId, String? initialName, String? initialVotesQty}) async {
    final nameController = TextEditingController(text: initialName);
    final votesQtyController = TextEditingController(text: initialVotesQty);

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(positionId == null ? 'Add Position' : 'Edit Position'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(hintText: 'Position Name'),
              ),
              TextField(
                controller: votesQtyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Votes Quantity'),
              ),
            ],
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
                final votesQty = votesQtyController.text.trim();

                if (name.isEmpty || votesQty.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('All fields are required'),
                        backgroundColor: Colors.red),
                  );
                } else if (int.tryParse(votesQty) == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Votes Quantity must be a number'),
                        backgroundColor: Colors.red),
                  );
                } else {
                  if (positionId == null) {
                    _addPosition(name, votesQty);
                  } else {
                    _editPosition(positionId, name, votesQty);
                  }
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteDialog(String positionId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Position'),
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
                _deletePosition(positionId);
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
          title: const Text('Positions'),
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 50),
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
                    final candidateCount = candidateCounts[position['name']] ?? 0;
                    
                    return SingleChildScrollView(
                      child: Card(
                        color: Colors.white,
                        elevation: 2,
                        child: ListTile(
                          title: Text(position['name']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Votes Quantity: ${position['votes_qty']}'),
                              Text('Running Candidates: $candidateCount'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  _showPositionDialog(
                                    positionId: position['id'].toString(),
                                    initialName: position['name'],
                                    initialVotesQty: position['votes_qty'].toString(),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  _showDeleteDialog(position['id'].toString());
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
          onPressed: () => _showPositionDialog(),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}
