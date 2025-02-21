import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:SSCVote/admin_pages/drawerbar_admin.dart';
import 'package:http/http.dart' as http;

class VotersPage extends StatefulWidget {
  const VotersPage({super.key});

  @override
  _VotersPageState createState() => _VotersPageState();
}

class _VotersPageState extends State<VotersPage> {
  List users = [];
  List filteredUsers = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchVisible = false;
  int currentPage = 0; // Current page index
  final int rowsPerPage = 10; // Changed to 10 rows per page

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    final url = Uri.parse('https://studentcouncil.bcp-sms1.com/php/fetch_voters.php');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      setState(() {
        users = (json.decode(response.body) as List).map((user) {
          return {
            'studentno': user['studentno'].toString(),
            'lastname': user['lastname'].toString(),
            'firstname': user['firstname'].toString(),
            'middlename': user['middlename'].toString(),
            'course': user['course'].toString(),
            'section': user['section'].toString(),
            'account_status': user['account_status'].toString(),
          };
        }).toList();
        filteredUsers = users; // Initialize filteredUsers
      });
    } else {
      throw Exception('Failed to load users');
    }
  }

  void _filterUsers() {
    String searchTerm = _searchController.text.toLowerCase();
    setState(() {
      filteredUsers = users.where((user) {
        return user['studentno'].toLowerCase().contains(searchTerm) ||
               user['course'].toLowerCase().contains(searchTerm) ||
               user['section'].toLowerCase().contains(searchTerm) ||
               '${user['lastname']}, ${user['firstname']} ${user['middlename']}'.toLowerCase().contains(searchTerm);
      }).toList();
      currentPage = 0; // Reset to the first page after filtering
    });
  }

  void _showDeleteConfirmation(String studentNo) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Confirmation'),
          content: Text('Are you sure you want to delete user with Student No: $studentNo?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _deleteUser(studentNo);
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteUser(String studentNo) async {
    final url = Uri.parse('https://studentcouncil.bcp-sms1.com/php/delete_user.php'); // Update with your delete API endpoint
    final response = await http.post(url, body: {'studentno': studentNo});

    if (response.statusCode == 200) {
      // Refresh the user list after deletion
      fetchUsers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voter deleted successfully'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete the voter'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _updateUser(String studentNo, String firstname, String lastname, String middlename, String course, String section) async {
  final url = Uri.parse('https://studentcouncil.bcp-sms1.com/php/update_user.php'); // Update with your update API endpoint
  final response = await http.post(url, body: {
    'studentno': studentNo,
    'firstname': firstname,
    'lastname': lastname,
    'middlename': middlename,
    'course': course,
    'section': section,
  });

  if (response.statusCode == 200) {
    // Refresh the user list after updating
    fetchUsers();
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voter updated successfully'), backgroundColor: Colors.green),
      );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update the voter'), backgroundColor: Colors.red),
      );
  }
}


  void _showUpdateUserForm(Map user) {
  // Create TextEditingControllers for each field
  TextEditingController firstnameController = TextEditingController(text: user['firstname']);
  TextEditingController lastnameController = TextEditingController(text: user['lastname']);
  TextEditingController middlenameController = TextEditingController(text: user['middlename']);
  TextEditingController courseController = TextEditingController(text: user['course']);
  TextEditingController sectionController = TextEditingController(text: user['section']);

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Update User: ${user['studentno']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: firstnameController,
                decoration: const InputDecoration(labelText: 'First Name'),
              ),
              TextField(
                controller: lastnameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
              ),
              TextField(
                controller: middlenameController,
                decoration: const InputDecoration(labelText: 'Middle Name'),
              ),
              TextField(
                controller: courseController,
                decoration: const InputDecoration(labelText: 'Course'),
              ),
              TextField(
                controller: sectionController,
                decoration: const InputDecoration(labelText: 'Section'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // Call the update function here with the new values
              await _updateUser(user['studentno'], firstnameController.text, lastnameController.text,
                  middlenameController.text, courseController.text, sectionController.text);
              Navigator.of(context).pop(); // Close the dialog
            },
            child: const Text('Update'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
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
    // Calculate the total number of pages
    int totalPages = (filteredUsers.length / rowsPerPage).ceil();

    // Get the current page users
    List currentPageUsers = filteredUsers.sublist(
      currentPage * rowsPerPage,
      (currentPage + 1) * rowsPerPage > filteredUsers.length
          ? filteredUsers.length
          : (currentPage + 1) * rowsPerPage,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        title: const Text('Voters', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer(); // Use this context
            },
                  );
          }
        ),
        actions: [
          IconButton(
            icon: Icon(_isSearchVisible ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearchVisible = !_isSearchVisible;
                if (!_isSearchVisible) {
                  _searchController.clear();
                  _filterUsers();
                }
              });
            },
          ),
        ],
      ),
      drawer: const AppDrawerAdmin(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_isSearchVisible) ...[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search by Student No or Name...',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => _filterUsers(),
                ),
              ),
            ],
            const SizedBox(height: 16.0),
            Expanded(
              child: filteredUsers.isEmpty
                  ? const Center(child: Text('No Voters yet.'))
                  : ListView.builder(
                      itemCount: currentPageUsers.length,
                      itemBuilder: (context, index) {
                        final user = currentPageUsers[index];
                        return Column(
                          children: [
                            Card(
                              color: Colors.white,
                              elevation: 2,
                              child: ListTile(
                                title: Text('${user['lastname']}, ${user['firstname']} ${user['middlename']}'),
                                subtitle: Text('Student No: ${user['studentno']} - Course: ${user['course']} - Section: ${user['section']}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () {
                                        _showUpdateUserForm(user); // Show the update form
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () {
                                        _showDeleteConfirmation(user['studentno']); // Show delete confirmation
                                      },
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
            // Pagination Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: currentPage > 0
                          ? () {
                              setState(() {
                                currentPage--;
                              });
                            }
                          : null,
                    ),
                    Text('Page ${currentPage + 1} of $totalPages', style: const TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward, color: Colors.black),
                      onPressed: currentPage < totalPages - 1
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
          ],
        ),
      ),
    );
  }
}
