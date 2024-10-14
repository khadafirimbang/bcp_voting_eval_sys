import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:for_testing/admin_pages/drawerbar_admin.dart';
import 'package:http/http.dart' as http;

class ResponsesPage extends StatefulWidget {
  const ResponsesPage({super.key});

  @override
  _ResponsesPageState createState() => _ResponsesPageState();
}

class _ResponsesPageState extends State<ResponsesPage> {
  List<dynamic> responses = [];
  List<dynamic> filteredResponses = [];
  String _searchQuery = '';
  String _selectedFilter = 'All';
  bool _isSearchVisible = false;
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 1; // Current page number
  final int _rowsPerPage = 10; // Number of rows per page

  @override
  void initState() {
    super.initState();
    fetchResponses();
  }

  Future<void> fetchResponses() async {
    const url = 'https://studentcouncil.bcp-sms1.com/php/fetch_responses.php'; // Replace with your server URL
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          responses = json.decode(response.body);
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
        final searchLower = _searchQuery.toLowerCase();
        final questionLower = (response['question'] ?? '').toString().toLowerCase();
        final studentNoLower = (response['studentno'] ?? '').toString().toLowerCase();

        final matchesSearch = searchLower.isEmpty ||
            questionLower.contains(searchLower) ||
            studentNoLower.contains(searchLower);

        final typeLower = (response['type'] ?? '').toString().toLowerCase();
        final matchesFilter = _selectedFilter == 'All' ||
            typeLower == _selectedFilter.toLowerCase();

        return matchesSearch && matchesFilter;
      }).toList();
      _currentPage = 1; // Reset to the first page after filtering
    });
  }

  List<dynamic> getPaginatedResponses() {
    final startIndex = (_currentPage - 1) * _rowsPerPage;
    final endIndex = startIndex + _rowsPerPage;
    return filteredResponses.sublist(
      startIndex,
      endIndex > filteredResponses.length ? filteredResponses.length : endIndex,
    );
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
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
            const SizedBox(height: 16.0),
            // Display responses in a ListView
            Expanded(
              child: filteredResponses.isEmpty
                  ? const Center(child: Text('No responses found.'))
                  : ListView.builder(
                      itemCount: getPaginatedResponses().length,
                      itemBuilder: (context, index) {
                        final response = getPaginatedResponses()[index];
                        return Column(
                          children: [
                            Card(
                              color: Colors.white,
                              elevation: 2,
                              child: ListTile(
                                title: Text('Question: ${response['question']}'),
                                subtitle: Text('Response: ${response['response']}'),
                                trailing: Text('Student No: ${response['studentno']}'),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
            // Pagination controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: _currentPage > 1 ? () {
                    setState(() {
                      _currentPage--;
                    });
                  } : null,
                  ),
                Text('Page $_currentPage of ${((filteredResponses.length + _rowsPerPage - 1) / _rowsPerPage).ceil()}'),
                IconButton(
                    icon: const Icon(Icons.arrow_forward, color: Colors.black),
                    onPressed: (_currentPage * _rowsPerPage < filteredResponses.length) ? () {
                    setState(() {
                      _currentPage++;
                    });
                  } : null,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
