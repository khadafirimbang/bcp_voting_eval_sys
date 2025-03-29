import 'dart:convert';
import 'package:SSCVote/admin_pages/profile_menu_admin.dart';
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = false;
  int totalVoters = 0; // Variable to store total voters
  List<String> courses = []; // List to hold unique courses
  String? selectedCourse; // Selected course for filtering

  @override
  void initState() {
    super.initState();
    fetchUsers();
    fetchTotalVoters();
  }

  Future<void> fetchTotalVoters() async {
    final response = await http.get(Uri.parse('https://studentcouncil.bcp-sms1.com/php/results.php'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        totalVoters = data['total_voters'];
      });
    } else {
      throw Exception('Failed to load results');
    }
  }

  Future<void> fetchUsers() async {
    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse('https://studentcouncil.bcp-sms1.com/php/fetch_voters.php');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      setState(() {
        users = (json.decode(response.body) as List).map((user) {
          return {
            'studentno': user['studentno']?.toString() ?? '', // Handle null studentno
            'lastname': user['lastname']?.toString() ?? '', // Handle null lastname
            'firstname': user['firstname']?.toString() ?? '', // Handle null firstname
            'middlename': user['middlename']?.toString() ?? '', // Handle null middlename
            'course': user['course']?.toString() ?? '', // Handle null course
            'section': user['section']?.toString() ?? '', // Handle null section
            'account_status': user['account_status']?.toString() ?? '',
          };
        }).toList();

        // Extract unique courses and add 'All' option
        courses = users.map((user) => user['course'] as String).toSet().toList().cast<String>();
        courses.insert(0, 'All'); // Add 'All' at the beginning
        filteredUsers = users; // Initialize filteredUsers
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      throw Exception('Failed to load users');
    }
  }

  void _filterUsers() {
    String searchTerm = _searchController.text.toLowerCase();
    setState(() {
      filteredUsers = users.where((user) {
        bool matchesSearch = user['studentno'].toLowerCase().contains(searchTerm) ||
                             user['course'].toLowerCase().contains(searchTerm) ||
                             user['section'].toLowerCase().contains(searchTerm) ||
                             '${user['lastname']}, ${user['firstname']} ${user['middlename']}'.toLowerCase().contains(searchTerm);
        
        bool matchesCourse = selectedCourse == null || selectedCourse == 'All' || user['course'] == selectedCourse;

        return matchesSearch && matchesCourse;
      }).toList();
      currentPage = 0; // Reset to the first page after filtering
    });
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
                      'Voters',
                      style: TextStyle(fontSize: 18, color: Colors.black54),
                    ),
                  ],
                ),
                Row(
                  children: [
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
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        fetchUsers();
                      },
                    ),
                    ProfileMenu()
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
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.black,))
                    : filteredUsers.isEmpty
                    ? const Center(child: Text('No Voters yet.'))
                    : Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Voters: $totalVoters',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                // Dropdown for course selection
                                Container(
                                  width: 150,
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    hint: const Text('Select Program'),
                                    value: selectedCourse,
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        selectedCourse = newValue;
                                        _filterUsers(); // Re-filter when course is selected
                                      });
                                    },
                                    items: courses.map<DropdownMenuItem<String>>((String course) {
                                      return DropdownMenuItem<String>(
                                        value: course,
                                        child: Text(course),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: currentPageUsers.length,
                              itemBuilder: (context, index) {
                                final user = currentPageUsers[index];
                                final fullName = '${user['lastname']}, ${user['firstname']}' +
                                    (user['middlename'] != null && user['middlename'].isNotEmpty
                                        ? ' ${user['middlename']}'
                                        : '');
                                return Card(
                                  color: Colors.white,
                                  elevation: 2,
                                  child: ListTile(
                                    title: Text(fullName),
                                    subtitle: Text('Student No: ${user['studentno']} - Course: ${user['course']} - Section: ${user['section']}'),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
              ),
              // Pagination Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
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
        ),
      ),
    );
  }
}
