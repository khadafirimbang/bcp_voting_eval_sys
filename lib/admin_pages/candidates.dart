import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:SSCVote/voter_pages/profile.dart';
import 'package:flutter/material.dart';
import 'package:SSCVote/admin_pages/dashboard2.dart';
import 'package:SSCVote/admin_pages/drawerbar_admin.dart';
import 'package:SSCVote/admin_pages/new_candidate.dart';
import 'package:SSCVote/admin_pages/partylist.dart';
import 'package:SSCVote/admin_pages/positions.dart';
import 'package:SSCVote/admin_pages/update_candidate.dart';
import 'package:SSCVote/main.dart';
import 'package:SSCVote/voter_pages/candidate_info.dart';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    _fetchCandidates();
                    _loadPositions();
                  },
                ),
              // SizedBox(width: 16), // Spacing _loadPositions
              _buildProfileMenu(context),
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
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search by student number or name',
                          border: OutlineInputBorder(),
                        ),
                      ),
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
                  ],
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
          SizedBox(width: 5,),
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
          SizedBox(width: 5,),
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
                    backgroundImage: candidate['img'] != null && candidate['img'].isNotEmpty
                      ? MemoryImage(
                          (() {
                            try {
                              // Print raw data for debugging
                              // print('Raw image data: ${candidate['img'].substring(0, 50)}...'); // Show first 50 chars
                              
                              // Clean and decode the base64 string
                              String cleanBase64 = candidate['img']
                                  .replaceAll(RegExp(r'data:image/[^;]+;base64,'), '')
                                  .replaceAll('\n', '')
                                  .replaceAll('\r', '')
                                  .replaceAll(' ', '+');
                                  
                              // print('Cleaned base64: ${cleanBase64.substring(0, 50)}...'); // Show first 50 chars
                              
                              return base64Decode(cleanBase64);
                            } catch (e) {
                              print('Error decoding image: $e');
                              return Uint8List(0); // Return empty image data
                            }
                          })()
                        )
                      : const AssetImage('assets/bcp_logo.png') as ImageProvider,
                    radius: 25,
                  )
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UpdateCandidatePage(
                            candidate: candidate, 
                            positions: positions, 
                            partylists: partylists
                          )
                        )
                      ).then((result) {
                        if (result == true) {
                          // Refresh the candidates list if update was successful
                          _fetchCandidates();
                        }
                      });
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
      ),
    );
    
  }

}

Widget _buildProfileMenu(BuildContext context) {
    return PopupMenuButton<int>(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onSelected: (item) {
        switch (item) {
          case 0:
            // Navigate to Profile page
            Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileInfoPage()));
            break;
          case 1:
            // Handle sign out
            _logout(context); // Example action for Sign Out
            break;
        }
      },
      offset: Offset(0, 50), // Adjust dropdown position
      itemBuilder: (context) => [
        PopupMenuItem<int>(
          padding: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
          value: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Signed in as', style: TextStyle(color: Colors.black54)),
              Text(studentNo ?? 'Unknown'),
            ],
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem<int>(
          value: 0,
          child: Row(
            children: [
              Icon(Icons.person, color: Colors.black54),
              SizedBox(width: 10),
              Text('Profile'),
            ],
          ),
        ),
        PopupMenuItem<int>(
          value: 1,
          child: Row(
            children: [
              Icon(Icons.logout, color: Colors.black54),
              SizedBox(width: 10),
              Text('Sign out'),
            ],
          ),
        ),
      ],
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: Colors.black54),
          ),
        ],
      ),
    );
  }
  
  void _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!context.mounted) return; // Ensure the widget is still mounted

    // Use pushAndRemoveUntil to clear the navigation stack
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoadingScreen()), // Replace with your login page
      (Route<dynamic> route) => false, // Remove all previous routes
    );
  }