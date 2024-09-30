import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:for_testing/admin_pages/drawerbar_admin.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:html' as html;

class CandidatesPage extends StatefulWidget {
  const CandidatesPage({super.key});

  @override
  State<CandidatesPage> createState() => _CandidatesPageState();
}

class _CandidatesPageState extends State<CandidatesPage> {
  List candidates = [];
  List filteredCandidates = [];
  final TextEditingController _searchController = TextEditingController();
  final List<String> positions = [// Added 'All' option
    'President',
    'Vice President',
    'Secretary',
    'Treasurer',
    'Auditor'
  ];
  final List<String> positionsFilter = [// Added 'All' option
    'All',
    'President',
    'Vice President',
    'Secretary',
    'Treasurer',
    'Auditor'
  ];
  String? selectedPosition;
  bool _isSearchVisible = false;
  XFile? _image; // Use XFile to pick images
  String? _uploadedImageUrl;
  Uint8List? _imageBytes; // To hold image bytes for display

  @override
  void initState() {
    super.initState();
    _fetchCandidates();
    _searchController.addListener(_filterCandidates);
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = pickedFile;
        _readImageBytes(); // Read image bytes after picking the image
      });
    }
  }

  Future<void> _readImageBytes() async {
    if (_image == null) return;

    final reader = html.FileReader();
    final completer = Completer<Uint8List>();

    reader.onLoadEnd.listen((_) {
      completer.complete(reader.result as Uint8List);
    });

    reader.readAsArrayBuffer(html.File([await _image!.readAsBytes()], _image!.name));
    final fileBytes = await completer.future;

    setState(() {
      _imageBytes = fileBytes;
    });
  }

  Future<void> _uploadImage() async {
  if (_image == null) return;

  final url = Uri.parse('https://api.cloudinary.com/v1_1/dcmdta4rb/image/upload');
  final request = http.MultipartRequest('POST', url);

  // Add the upload preset (if you have one)
  request.fields['upload_preset'] = 'sjon389q';

  // Add image file to the request
  // request.files.add(await http.MultipartFile.fromPath('file', _image!.path));
  request.files.add(http.MultipartFile.fromBytes('file', _imageBytes!, filename: _image!.name));

  // Send request
  final response = await request.send();

  if (response.statusCode == 200) {
    final responseData = await response.stream.bytesToString();
    final responseJson = json.decode(responseData);

    if (responseJson['url'] != null) {
      setState(() {
        _uploadedImageUrl = responseJson['url'];
      });
    } else {
      // Handle error from Cloudinary
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image upload failed'), backgroundColor: Colors.red),
      );
    }
  } else {
    // Handle the HTTP error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to upload image'), backgroundColor: Colors.red),
    );
  }
}


  Future<void> _fetchCandidates() async {
    final url = Uri.parse('http://192.168.1.6/for_testing/fetch_all_candidates.php');
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
    });
  }


  Future<void> _deleteCandidate(String studentNo) async {
    final url = Uri.parse('http://192.168.1.6/for_testing/delete_candidate.php');
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

  Future<void> _addCandidate(Map<String, String> candidateData) async {
    final url = Uri.parse('http://192.168.1.6/for_testing/add_candidate.php');
    final response = await http.post(url, body: candidateData);

    // Upload the image only if not already uploaded
    if (_uploadedImageUrl == null) {
      await _uploadImage();
    }

    final responseData = json.decode(response.body);

    if (response.statusCode == 200) {
      if (responseData['status'] == 'success') {
        print('url: $_uploadedImageUrl');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message']), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
        _fetchCandidates();
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

  void _showAddCandidateForm() async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
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
                          selectedPosition = newValue ?? '';
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a position';
                        }
                        return null;
                      },
                    ),
                    ElevatedButton(
                      onPressed: _pickImage,
                      child: Text('Pick Image'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A), // Background color
              ),
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  await _uploadImage();

                  final candidateData = {
                    'studentno': studentnoController.text,
                    'lastname': lastnameController.text,
                    'firstname': firstnameController.text,
                    'middlename': middlenameController.text,
                    'course': courseController.text,
                    'section': sectionController.text,
                    'slogan': sloganController.text,
                    'position': selectedPosition ?? '',
                    'image_url': _uploadedImageUrl ?? '',
                  };

                  _addCandidate(candidateData);
                }
              },
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
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
                          selectedPosition = newValue ?? '';
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
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A), // Background color
              ),
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
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

                  _updateCandidate(candidateData);
                }
              },
              child: const Text('Update', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateCandidate(Map<String, String> candidateData) async {
    final url = Uri.parse('http://192.168.1.6/for_testing/update_candidate.php');
    final response = await http.post(url, body: candidateData);

    final responseData = json.decode(response.body);

    if (response.statusCode == 200) {
      if (responseData['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message']), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
        _fetchCandidates();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawerAdmin(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        title: const Text('Candidates', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
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
        ],
      ),
      body: Column(
        children: [
          if (_isSearchVisible) ...[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  DropdownButton<String>(
                    hint: const Text('All'),
                    value: selectedPosition,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedPosition = newValue;
                        _filterCandidates();
                      });
                    },
                    items: positionsFilter.map((String position) {
                      return DropdownMenuItem<String>(
                        value: position,
                        child: Text(position),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
          Expanded(
            child: ListView.builder(
              itemCount: filteredCandidates.length,
              itemBuilder: (context, index) {
                final candidate = filteredCandidates[index];
                final isEvenRow = index % 2 == 0;
                return Column(
                  children: [
                    Divider(),
                    ListTile(
                      title: Text('${candidate['lastname']}, ${candidate['firstname']} ${candidate['middlename']}'),
                      subtitle: Text('Student No: ${candidate['studentno']} - Position: ${candidate['position']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showUpdateForm(candidate),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _showDeleteConfirmation(candidate['studentno']),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1E3A8A),
        onPressed: _showAddCandidateForm,
        child: const Icon(Icons.add, color: Colors.white,),
      ),
    );
  }
}
