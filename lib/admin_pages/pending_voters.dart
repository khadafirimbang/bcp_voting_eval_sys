import 'package:flutter/material.dart';
import 'package:SSCVote/admin_pages/drawerbar_admin.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PendingVotersPage extends StatefulWidget {
  const PendingVotersPage({super.key});

  @override
  _PendingVotersPageState createState() => _PendingVotersPageState();
}

class _PendingVotersPageState extends State<PendingVotersPage> {
  List<dynamic> pendingVoters = [];
  List<dynamic> filteredVoters = [];
  String searchQuery = '';
  int currentPage = 1;
  final int itemsPerPage = 10;
  bool isSearchVisible = false; // Variable to control search visibility

  @override
  void initState() {
    super.initState();
    fetchPendingVoters();
  }

  Future<void> fetchPendingVoters() async {
    try {
      final response = await http.get(Uri.parse('https://studentcouncil.bcp-sms1.com/php/fetch_pending_voters.php'));

      if (response.statusCode == 200) {
        setState(() {
          pendingVoters = json.decode(response.body);
          filteredVoters = pendingVoters; // Initialize filtered list
        });
      } else {
        throw Exception('Failed to load pending voters');
      }
    } catch (e) {
      print('Error fetching pending voters: $e');
    }
  }

  void filterVoters(String query) {
    setState(() {
      searchQuery = query;
      filteredVoters = pendingVoters.where((voter) {
        final fullName = '${voter['lastname']} ${voter['firstname']} ${voter['middlename']}';
        final studentNo = '${voter['studentno']}';
        return fullName.toLowerCase().contains(query.toLowerCase()) || studentNo.toLowerCase().contains(query.toLowerCase());
      }).toList();
      currentPage = 1; // Reset to first page on new search
    });
  }

  List<dynamic> get paginatedVoters {
    int startIndex = (currentPage - 1) * itemsPerPage;
    int endIndex = startIndex + itemsPerPage;
    return filteredVoters.sublist(
      startIndex,
      endIndex > filteredVoters.length ? filteredVoters.length : endIndex,
    );
  }

  Future<void> acceptVoter(String studentNo) async {
    try {
      final response = await http.post(
        Uri.parse('https://studentcouncil.bcp-sms1.com/php/accept_voter.php'),
        body: json.encode({'studentno': studentNo}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        fetchPendingVoters(); // Refresh the list
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voter accepted successfully'), backgroundColor: Colors.green),
      );
      } else {
        throw Exception('Failed to update account status');
      }
    } catch (e) {
      print('Error accepting voter: $e');
    }
  }

  Future<void> rejectVoter(String studentNo) async {
    final response = await http.delete(
      Uri.parse('https://studentcouncil.bcp-sms1.com/php/reject_voter.php?studentno=$studentNo'),
    );

    if (response.statusCode == 200) {
      fetchPendingVoters(); // Refresh the list
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voter rejected successfully'), backgroundColor: Colors.green),
      );
    } else {
      throw Exception('Failed to delete voter');
    }
  }

  void showAcceptDialog(BuildContext context, String studentNo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Accept'),
          content: const Text('Are you sure you want to accept this voter?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                acceptVoter(studentNo);
              },
              child: const Text('Accept'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void showRejectDialog(BuildContext context, String studentNo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Reject'),
          content: const Text('Are you sure you want to reject this voter?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                rejectVoter(studentNo);
              },
              child: const Text('Reject'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
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
        title: const Text('Pending Voters', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer(); // Use this context
              },
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(isSearchVisible ? Icons.close : Icons.search), // Toggle icon based on visibility
            onPressed: () {
              setState(() {
                isSearchVisible = !isSearchVisible; // Toggle search visibility
                if (!isSearchVisible) {
                  searchQuery = ''; // Clear search query when hiding
                  filteredVoters = pendingVoters; // Reset filtered list
                }
              });
            },
          ),
        ],
      ),
      drawer: const AppDrawerAdmin(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: pendingVoters.isEmpty
            ? const Center(child: Text("No pending"))
            : Column(
                children: [
                  if (isSearchVisible) // Show search field only if visible
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        onChanged: filterVoters,
                        decoration: const InputDecoration(
                          labelText: 'Search',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                  Expanded(
                    child: ListView.builder(
                      itemCount: paginatedVoters.length,
                      itemBuilder: (context, index) {
                        var voter = paginatedVoters[index];
                        return Column(
                          children: [
                            Card(
                              color: Colors.white,
                              elevation: 2,
                              child: ListTile(
                                title: Text('${voter['lastname']}, ${voter['firstname']} ${voter['middlename']}'),
                                subtitle: Text('${voter['studentno']} - ${voter['course']} - ${voter['section']}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextButton(
                                      onPressed: () => showAcceptDialog(context, voter['studentno'].toString()),
                                      style: TextButton.styleFrom(
                                        backgroundColor: Colors.green, // Set the background color to green
                                        foregroundColor: Colors.white, // Set the text color to white for better contrast
                                      ), // Convert to String
                                      child: const Text('Accept'),
                                    ),
                                    const SizedBox(width: 5,),
                                    TextButton(
                                      onPressed: () => showRejectDialog(context, voter['studentno'].toString()),
                                      style: TextButton.styleFrom(
                                        backgroundColor: Colors.red, // Set the background color to green
                                        foregroundColor: Colors.white, // Set the text color to white for better contrast
                                      ), // Convert to String
                                      child: const Text('Reject'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: currentPage > 1
                            ? () {
                                setState(() {
                                  currentPage--;
                                });
                              }
                            : null,
                      ),
                      Text('Page $currentPage'),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward, color: Colors.black,),
                        onPressed: currentPage < (filteredVoters.length / itemsPerPage).ceil()
                            ? () {
                                setState(() {
                                  currentPage++;
                                });
                              }
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
