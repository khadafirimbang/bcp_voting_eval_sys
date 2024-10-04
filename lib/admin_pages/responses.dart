import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:for_testing/admin_pages/drawerbar_admin.dart';
import 'package:http/http.dart' as http;

class ResponsesPage extends StatefulWidget {
  @override
  _ResponsesPageState createState() => _ResponsesPageState();
}

class _ResponsesPageState extends State<ResponsesPage> {
  List<dynamic> responses = [];
  List<dynamic> filteredResponses = [];
  String _searchQuery = '';
  String _selectedFilter = 'All';
  bool _isSearchVisible = false;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchResponses();
  }

  Future<void> fetchResponses() async {
  final url = 'http://192.168.1.6/for_testing/fetch_responses.php'; // Replace with your server URL
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      setState(() {
        responses = json.decode(response.body);
        // print(responses); // Debugging: print the data
        _filterResponses(); // Initial filter for when responses are fetched
      });
    } else {
      print('Failed to load responses');
    }
  } catch (e) {
    print('Error: $e');
  }
}


void _filterResponses() {
  setState(() {
    filteredResponses = responses.where((response) {
      // Convert values to lowercase safely, handle nulls by using an empty string if null
      final searchLower = _searchQuery.toLowerCase();

      final questionLower = (response['question'] ?? '').toString().toLowerCase();
      final studentNoLower = (response['studentno'] ?? '').toString().toLowerCase();

      // Check if search query matches either question or student number
      final matchesSearch = searchLower.isEmpty ||
          questionLower.contains(searchLower) ||
          studentNoLower.contains(searchLower);

      // Filter based on selected type (Survey, Feedback, or All)
      final typeLower = (response['type'] ?? '').toString().toLowerCase();
      final matchesFilter = _selectedFilter == 'All' ||
          typeLower == _selectedFilter.toLowerCase();

      return matchesSearch && matchesFilter;
    }).toList();
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        title: const Text('Responses', style: TextStyle(color: Colors.white)),
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
                  // Clear search query when closing the search bar
                  _searchController.clear();
                  _searchQuery = '';
                  _filterResponses(); // Reset filter when search is closed
                }
              });
            },
          ),
          DropdownButton<String>(
            value: _selectedFilter,
            dropdownColor: const Color(0xFF1E3A8A),
            icon: const Icon(Icons.filter_list, color: Colors.white),
            items: ['All', 'Survey', 'Feedback'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value, style: const TextStyle(color: Colors.white)),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedFilter = value!;
                _filterResponses(); // Reapply filtering whenever the dropdown changes
              });
            },
          ),
        ],
      ),
      drawer: const AppDrawerAdmin(),
      body: Column(
        children: [
          // Search field visibility controlled by the search icon
          if (_isSearchVisible)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search by question or student number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value; // Update the search query
                    _filterResponses(); // Filter the responses as the search query changes
                  });
                },
              ),
            ),
          // Display responses in a ListView
          Expanded(
            child: filteredResponses.isEmpty
                ? const Center(child: Text('No responses found.'))
                : ListView.builder(
                    itemCount: filteredResponses.length,
                    itemBuilder: (context, index) {
                      final response = filteredResponses[index];
                      return Column(
                        children: [
                          Divider(),
                          ListTile(
                            title: Text('Question: ${response['question']}'),
                            subtitle: Text('Response: ${response['response']}'),
                            trailing: Text('Student No: ${response['studentno']}'),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
