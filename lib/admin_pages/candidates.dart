import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:for_testing/admin_pages/drawerbar_admin.dart';
import 'package:for_testing/admin_pages/new_candidate.dart';
import 'package:for_testing/admin_pages/partylist.dart';
import 'package:for_testing/admin_pages/positions.dart';
import 'package:for_testing/voter_pages/candidate_info.dart';

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
  final List<String> positions = [];
  final List<String> partylists = [];

  String? selectedPosition;
  String? selectedPartylist;
  bool _isSearchVisible = false;
  XFile? _image;
  String? _uploadedImageUrl;
  Uint8List? _imageBytes;
  int currentPage = 0; // Current page index
  final int rowsPerPage = 10; // Changed to 10 rows per page
  List<String> selectedCandidates = [];
  bool selectAll = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _fetchCandidates();
    _searchController.addListener(_filterCandidates);
    _loadPositions();
    _loadPartylist();
  }

  Future<void> _resetVotes() async {
    final url = Uri.parse('https://studentcouncil.bcp-sms1.com/php/reset_votes.php');
    final response = await http.post(url);

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      if (result['status'] == 'success') {
        _fetchCandidates(); // Refresh the list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Votes reset successfully'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteSelected() async {
    if (selectedCandidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No candidates selected'), backgroundColor: Colors.red),
      );
      return;
    }

    final url = Uri.parse('https://studentcouncil.bcp-sms1.com/php/delete_selected.php');
    final response = await http.post(
      url,
      body: {'selected_ids': json.encode(selectedCandidates)},
    );

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      if (result['status'] == 'success') {
        setState(() {
          selectedCandidates.clear();
          selectAll = false;
        });
        _fetchCandidates(); // Refresh the list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected candidates deleted successfully'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
        );
      }
    }
  }
  
  Future<void> _loadPartylist() async {
    final url = Uri.parse('https://studentcouncil.bcp-sms1.com/php/get_partylist.php'); // Replace with your endpoint
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            partylists.clear();
            partylists.addAll(List<String>.from(data['partylist']));
          });
        } else {
          throw Exception(data['message']);
        }
      } else {
        throw Exception('Failed to load partylist');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading partylist: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadPositions() async {
    final url = Uri.parse('https://studentcouncil.bcp-sms1.com/php/get_positions.php');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            positions.clear();
            positions.addAll(List<String>.from(data['positions']));
          });
        } else {
          throw Exception(data['message']);
        }
      } else {
        throw Exception('Failed to load positions');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading positions: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  void _showResetVotesConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Reset'),
          content: const Text('Are you sure you want to reset the votes? All of the total votes will be reset.'),
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
                _resetVotes();
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteSelectedConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete all of the selected candidates?'),
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
                _deleteSelected();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
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
    String? selectedPartylist= candidate['partylist'];

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
                    DropdownButtonFormField<String>(
                      value: selectedPartylist,
                      decoration: const InputDecoration(labelText: 'Partylist'),
                      items: partylists.map((String partylist) {
                        return DropdownMenuItem<String>(
                          value: partylist,
                          child: Text(partylist),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedPartylist = newValue;
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
                  _updateCandidate(studentnoController.text, lastnameController.text, firstnameController.text, middlenameController.text, courseController.text, sectionController.text, sloganController.text, selectedPosition, selectedPartylist);
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

  Future<void> _updateCandidate(String studentno, String lastname, String firstname, String middlename, String course, String section, String slogan, String? position, String? partylist) async {
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
      'partylist': partylist,
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
                'Candidates',
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
                      _filterCandidates();
                    }
                  });
                },
              ),
              const SizedBox(width: 10),
              DropdownButton<String>(
                icon: const Icon(Icons.filter_list, color: Colors.black54),
                hint: const Text('All', style: TextStyle(color: Colors.black54)),
                value: selectedPosition,
                items: <String>['All', ...positions]
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedPosition = newValue;
                    _filterCandidates();
                  });
                },
                // dropdownColor: const Color(0xFF1E3A8A),
                style: const TextStyle(color: Colors.black),
              ),
              // const SizedBox(width: 10),
              IconButton(onPressed: (){
                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const CandidatesPage()),
                                );
              }, icon: const Icon(Icons.refresh))
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
            if (_isSearchVisible)
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search by student number or name',
                  border: OutlineInputBorder(),
                ),
              ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.all(10.0),
                                backgroundColor: Colors.black,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const PositionsPage()),
                                );
                              },
                              child: const Text('Positions', 
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                const SizedBox(width: 10.0),
                SizedBox(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.all(10.0),
                                backgroundColor: Colors.black,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const PartyListPage()),
                                );
                              },
                              child: const Text('Partylists', 
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
              ],
            ),
            SizedBox(height: 10,),
            Row(
      children: [
        Checkbox(
          value: selectAll,
          onChanged: (bool? value) {
            setState(() {
              selectAll = value ?? false;
              if (selectAll) {
                selectedCandidates = currentPageUsers.map((c) => c['studentno'].toString()).toList();
              } else {
                selectedCandidates.clear();
              }
            });
          },
        ),
        const Text('Select All'),
        SizedBox(width: 10,),
        SizedBox(
          child: TextButton(
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(10.0),
              backgroundColor: Colors.black,
            ),
            onPressed: _showDeleteSelectedConfirmation,
            child: const Text(
              'Delete Selected',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
        SizedBox(width: 10,),
        SizedBox(
          child: TextButton(
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(10.0),
              backgroundColor: Colors.black,
            ),
            onPressed: _showResetVotesConfirmation,
            child: const Text(
              'Reset Votes',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    ),
            const SizedBox(height: 16.0),
            Expanded(
  child: ListView.builder(
    itemCount: currentPageUsers.length,
    itemBuilder: (context, index) {
      final candidate = currentPageUsers[index];
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CandidateDetailPage(candidate: candidate),
            ),
          );
        },
        child: Card(
          color: Colors.white,
          elevation: 2,
          child: ListTile(
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: selectedCandidates.contains(candidate['studentno'].toString()),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value ?? false) {
                        selectedCandidates.add(candidate['studentno'].toString());
                      } else {
                        selectedCandidates.remove(candidate['studentno'].toString());
                      }
                      selectAll = selectedCandidates.length == currentPageUsers.length;
                    });
                  },
                ),
                CircleAvatar(
                  backgroundImage: candidate['image_url'] != null && candidate['image_url'].isNotEmpty
                      ? NetworkImage(candidate['image_url'])
                      : const AssetImage('assets/bcp_logo.png') as ImageProvider,
                ),
              ],
            ),
            title: Text(
              '${candidate['firstname']} ${candidate['lastname']}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Student No: ${candidate['studentno']}'),
                Text('Position: ${candidate['position']}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.black),
                  onPressed: () {
                    _showUpdateForm(candidate);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.black),
                  onPressed: () {
                    _showDeleteConfirmation(candidate['studentno']);
                  },
                ),
              ],
            ),
            isThreeLine: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
        backgroundColor: Colors.black,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

}
