import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:for_testing/admin_pages/drawerbar_admin.dart';
import 'package:for_testing/admin_pages/new_candidate.dart';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CandidatesPage extends StatefulWidget {
  const CandidatesPage({super.key});

  @override
  State<CandidatesPage> createState() => _CandidatesPageState();
}

class _CandidatesPageState extends State<CandidatesPage> {
  List candidates = [];
  List filteredCandidates = [];
  final TextEditingController _searchController = TextEditingController();
  final List<String> positions = [
    'President',
    'Vice President',
    'Secretary',
    'Treasurer',
    'Auditor'
  ];
  final List<String> positionsFilter = [
    'All',
    'President',
    'Vice President',
    'Secretary',
    'Treasurer',
    'Auditor'
  ];
  String? selectedPosition;
  bool _isSearchVisible = false;
  XFile? _image;
  String? _uploadedImageUrl;
  Uint8List? _imageBytes;
  int currentPage = 0; // Current page index
  final int rowsPerPage = 10; // Changed to 10 rows per page

  @override
  void initState() {
    super.initState();
    _fetchCandidates();
    _searchController.addListener(_filterCandidates);
  }


  Future<void> _fetchCandidates() async {
    final url = Uri.parse('https://studentcouncil.bcp-sms1.com/php/fetch_all_candidates.php');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      setState(() {
        candidates = json.decode(response.body);
        filteredCandidates = candidates;
      });
    } else {
      print('Failed to fetch candidates');
    }
  }

  void _filterCandidates() {
    String query = _searchController.text.toLowerCase().trim();

    setState(() {
      filteredCandidates = candidates.where((candidate) {
        bool matchesQuery = (candidate['studentno']?.toLowerCase().contains(query) ?? false) ||
            (candidate['lastname']?.toLowerCase().contains(query) ?? false) ||
            (candidate['firstname']?.toLowerCase().contains(query) ?? false) ||
            (candidate['middlename']?.toLowerCase().contains(query) ?? false) ||
            (candidate['section']?.toLowerCase().contains(query) ?? false) ||
            (candidate['course']?.toLowerCase().contains(query) ?? false) ||
            (candidate['position']?.toLowerCase().contains(query) ?? false);

        bool matchesPosition = selectedPosition == null || 
            selectedPosition == 'All' || 
            (candidate['position']?.toLowerCase() == selectedPosition?.toLowerCase());

        return matchesQuery && matchesPosition;
      }).toList();
      currentPage = 0;
    });
  }

  Future<void> _deleteCandidate(String studentNo) async {
    final url = Uri.parse('https://studentcouncil.bcp-sms1.com/php/delete_candidate.php');
    final response = await http.post(url, body: {'studentno': studentNo});

    if (response.statusCode == 200) {
      _fetchCandidates();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Candidate deleted successfully'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete candidate'), backgroundColor: Colors.red),
      );
    }
  }

  void _showDeleteConfirmation(String studentNo) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this candidate?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteCandidate(studentNo);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showUpdateForm(Map candidate) {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController studentnoController = TextEditingController(text: candidate['studentno']);
    final TextEditingController lastnameController = TextEditingController(text: candidate['lastname']);
    final TextEditingController firstnameController = TextEditingController(text: candidate['firstname']);
    final TextEditingController middlenameController = TextEditingController(text: candidate['middlename']);
    final TextEditingController courseController = TextEditingController(text: candidate['course']);
    final TextEditingController sectionController = TextEditingController(text: candidate['section']);
    final TextEditingController sloganController = TextEditingController(text: candidate['slogan']);
    String? selectedPosition = candidate['position'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Candidate'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 400,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: studentnoController,
                      decoration: const InputDecoration(labelText: 'Student Number'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter student number';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: lastnameController,
                      decoration: const InputDecoration(labelText: 'Last Name'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter last name';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: firstnameController,
                      decoration: const InputDecoration(labelText: 'First Name'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter first name';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: middlenameController,
                      decoration: const InputDecoration(labelText: 'Middle Name'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter middle name';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: courseController,
                      decoration: const InputDecoration(labelText: 'Course'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter course';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: sectionController,
                      decoration: const InputDecoration(labelText: 'Section'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter section';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: sloganController,
                      decoration: const InputDecoration(labelText: 'Slogan'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter slogan';
                        }
                        return null;
                      },
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedPosition,
                      decoration: const InputDecoration(labelText: 'Position'),
                      items: positions.map((String position) {
                        return DropdownMenuItem<String>(
                          value: position,
                          child: Text(position),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedPosition = newValue;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  _updateCandidate(studentnoController.text, lastnameController.text, firstnameController.text, middlenameController.text, courseController.text, sectionController.text, sloganController.text, selectedPosition);
                  Navigator.pop(context);
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateCandidate(String studentno, String lastname, String firstname, String middlename, String course, String section, String slogan, String? position) async {
    final url = Uri.parse('https://studentcouncil.bcp-sms1.com/php/update_candidate.php');
    final response = await http.post(url, body: {
      'studentno': studentno,
      'lastname': lastname,
      'firstname': firstname,
      'middlename': middlename,
      'course': course,
      'section': section,
      'slogan': slogan,
      'position': position,
    });

    if (response.statusCode == 200) {
      _fetchCandidates();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Candidate updated successfully'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update candidate'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

    @override
  Widget build(BuildContext context) {
    // Calculate the total number of pages
    int totalPages = (filteredCandidates.length / rowsPerPage).ceil();

    // Get the current page users
    List currentPageUsers = filteredCandidates.sublist(
      currentPage * rowsPerPage,
      (currentPage + 1) * rowsPerPage > filteredCandidates.length
          ? filteredCandidates.length
          : (currentPage + 1) * rowsPerPage,
    );

    return Scaffold(
      drawer: const AppDrawerAdmin(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        title: const Text('Candidates', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(_isSearchVisible ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearchVisible = !_isSearchVisible;
                if (!_isSearchVisible) {
                  _searchController.clear();
                  _filterCandidates();
                }
              });
            },
          ),
          const SizedBox(width: 10),
          DropdownButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            hint: const Text('All', style: TextStyle(color: Colors.white)),
            value: selectedPosition,
            items: positionsFilter.map((String position) {
              return DropdownMenuItem<String>(
                value: position,
                child: Text(position),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                selectedPosition = newValue;
                _filterCandidates();
              });
            },
            dropdownColor: const Color(0xFF1E3A8A),
            style: const TextStyle(color: Colors.white),
          ),
          // const SizedBox(width: 10),
          IconButton(onPressed: (){
            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const CandidatesPage()),
                            );
          }, icon: const Icon(Icons.refresh))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_isSearchVisible)
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search by student number or name',
                  border: OutlineInputBorder(),
                ),
              ),
            const SizedBox(height: 16.0),
            Expanded(
              child: ListView.builder(
                itemCount: currentPageUsers.length,
                itemBuilder: (context, index) {
                  final candidate = currentPageUsers[index];
                  return Card(
                    color: Colors.white,
                    elevation: 2,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: candidate['image_url'] != null && candidate['image_url'].isNotEmpty
                            ? NetworkImage(candidate['image_url'])
                            : const AssetImage('assets/bcp_logo.png'), // Replace with your placeholder path
                      ),
                      title: Text('${candidate['firstname']} ${candidate['lastname']}'),
                      subtitle: Text('Position: ${candidate['position']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              _showUpdateForm(candidate);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              _showDeleteConfirmation(candidate['studentno']);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: currentPage > 0 ? () {
                    setState(() {
                      currentPage--;
                    });
                  } : null,
                  ),
                Text('Page ${currentPage + 1} of $totalPages'),
                IconButton(
                    icon: const Icon(Icons.arrow_forward, color: Colors.black),
                    onPressed: currentPage < totalPages - 1 ? () {
                    setState(() {
                      currentPage++;
                    });
                  } : null,
                  ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NewCandidatePage()),
              );
        },
        backgroundColor: const Color(0xFF1E3A8A),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

}
