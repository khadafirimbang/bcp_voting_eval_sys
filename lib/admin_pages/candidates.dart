import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:for_testing/admin_pages/drawerbar_admin.dart';
import 'package:http/http.dart' as http;

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

  @override
  void initState() {
    super.initState();
    _fetchCandidates();
    _searchController.addListener(_filterCandidates);
  }

  Future<void> _fetchCandidates() async {
    final url = Uri.parse('http://192.168.1.2/for_testing/fetch_all_candidates.php');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      setState(() {
        candidates = json.decode(response.body);
        filteredCandidates = candidates; // Initialize filteredCandidates with all candidates
      });
    } else {
      print('Failed to fetch candidates');
    }
  }

  void _filterCandidates() {
    String query = _searchController.text.toLowerCase().trim();

    setState(() {
      filteredCandidates = candidates.where((candidate) {
        return candidate['studentno'].toLowerCase().contains(query) ||
               candidate['lastname'].toLowerCase().contains(query) ||
               candidate['firstname'].toLowerCase().contains(query) ||
               candidate['middlename'].toLowerCase().contains(query) ||
               candidate['section'].toLowerCase().contains(query) ||
               candidate['course'].toLowerCase().contains(query) ||
               candidate['position'].toLowerCase().contains(query); // Case-insensitive search
      }).toList();
    });
  }

  Future<void> _deleteCandidate(String studentNo) async {
    final url = Uri.parse('http://192.168.1.2/for_testing/delete_candidate.php');
    final response = await http.post(url, body: {'studentno': studentNo});

    if (response.statusCode == 200) {
      _fetchCandidates(); // Refresh the list after delete
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

  Future<void> _addCandidate(Map<String, String> candidateData) async {
    final url = Uri.parse('http://192.168.1.2/for_testing/add_candidate.php');
    final response = await http.post(url, body: candidateData);

    final responseData = json.decode(response.body);

    if (response.statusCode == 200) {
      if (responseData['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message']), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Close the dialog only if successful
        _fetchCandidates(); // Refresh the list after adding
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message']), backgroundColor: Colors.red),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add candidate'), backgroundColor: Colors.red),
      );
    }
  }

  void _showAddCandidateForm() {
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
    final TextEditingController studentnoController = TextEditingController();
    final TextEditingController lastnameController = TextEditingController();
    final TextEditingController firstnameController = TextEditingController();
    final TextEditingController middlenameController = TextEditingController();
    final TextEditingController courseController = TextEditingController();
    final TextEditingController sectionController = TextEditingController();
    final TextEditingController sloganController = TextEditingController();
    String? selectedPosition;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Candidate'),
          content: SizedBox(
            width: 400, // Set the width of the dialog
            child: Form(
              key: _formKey,
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a position';
                      }
                      return null;
                    },
                  ),
                ],
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
                if (_formKey.currentState?.validate() ?? false) {
                  final candidateData = {
                    'studentno': studentnoController.text,
                    'lastname': lastnameController.text,
                    'firstname': firstnameController.text,
                    'middlename': middlenameController.text,
                    'course': courseController.text,
                    'section': sectionController.text,
                    'slogan': sloganController.text,
                    'position': selectedPosition ?? '',
                  };

                  _addCandidate(candidateData); // Call _addCandidate without closing the dialog
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showUpdateForm(Map candidate) {
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
    final TextEditingController studentnoController = TextEditingController(text: candidate['studentno']);
    final TextEditingController lastnameController = TextEditingController(text: candidate['lastname']);
    final TextEditingController firstnameController = TextEditingController(text: candidate['firstname']);
    final TextEditingController middlenameController = TextEditingController(text: candidate['middlename']);
    final TextEditingController courseController = TextEditingController(text: candidate['course']);
    final TextEditingController sectionController = TextEditingController(text: candidate['section']);
    String? selectedPosition = candidate['position'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Candidate'),
          content: SizedBox(
            width: 400, // Set the width of the dialog
            child: Form(
              key: _formKey,
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a position';
                      }
                      return null;
                    },
                  ),
                ],
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
              onPressed: () async {
                if (_formKey.currentState?.validate() ?? false) {
                  final updateData = {
                    'studentno': studentnoController.text,
                    'lastname': lastnameController.text,
                    'firstname': firstnameController.text,
                    'middlename': middlenameController.text,
                    'course': courseController.text,
                    'section': sectionController.text,
                    'position': selectedPosition ?? '',
                  };

                  final url = Uri.parse('http://192.168.1.2/for_testing/update_candidate.php');
                  final response = await http.post(url, body: updateData);

                  final responseData = json.decode(response.body);

                  Navigator.pop(context);

                  if (response.statusCode == 200) {
                    if (responseData['status'] == 'success') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(responseData['message']), backgroundColor: Colors.green),
                      );
                      _fetchCandidates(); // Refresh the list after update
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(responseData['message']), backgroundColor: Colors.red),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to update candidate'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Update'),
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
        title: const Text('Candidates', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const AppDrawerAdmin(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search here...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                      backgroundColor: const Color(0xFF1E3A8A),
                    ),
                    onPressed: _showAddCandidateForm,
                    child: const Text('Add Candidate', 
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredCandidates.isNotEmpty
                ? ListView.builder(
                    itemCount: filteredCandidates.length,
                    itemBuilder: (context, index) {
                      var candidate = filteredCandidates[index];

                      // Alternate the background color
                      Color rowColor = (index % 2 == 0) ? Colors.grey[300]! : Colors.grey[200]!;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                        child: Container(
                          color: rowColor, // Apply alternating row color
                          child: ListTile(
                            title: Text('${candidate['studentno']}', style: TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${candidate['lastname']}, ${candidate['firstname']} ${candidate['middlename']}', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                                Text('${candidate['course']} - ${candidate['section']} (${candidate['position']})'),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.green, size: 30),
                                  onPressed: () => _showUpdateForm(candidate),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 30),
                                  onPressed: () => _showDeleteConfirmation(candidate['studentno']),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }
}
