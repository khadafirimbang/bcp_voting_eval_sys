import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:SSCVote/admin_pages/candidates.dart';
import 'package:SSCVote/admin_pages/drawerbar_admin.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NewCandidatePage extends StatefulWidget {
  @override
  _NewCandidatePageState createState() => _NewCandidatePageState();
}

class _NewCandidatePageState extends State<NewCandidatePage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _studentNoController = TextEditingController();
  TextEditingController _firstNameController = TextEditingController();
  TextEditingController _middleNameController = TextEditingController();
  TextEditingController _lastNameController = TextEditingController();
  TextEditingController _sectionController = TextEditingController();
  TextEditingController _courseController = TextEditingController();
  TextEditingController _sloganController = TextEditingController();

  String? _selectedPosition;
  String? _selectedPartylist;
  Uint8List? _imageFile;
  bool _isUploadingImage = false;
  bool _isSaving = false;

  final List<String> _positions = [];
  final List<String> _partylist = [];
  Timer? _debounceTimer;
  List<Map<String, dynamic>> _filteredStudents = [];

  @override
  void initState() {
    super.initState();
    _loadPositions();
    _loadPartylist();
    fetchAndSaveData();
  }

  Future<List<Map<String, dynamic>>> _fetchEligibleStudents({String searchTerm = ''}) async {
    final url = Uri.parse('https://studentcouncil.bcp-sms1.com/php/get_eligible_students.php?search=$searchTerm');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return List<Map<String, dynamic>>.from(data['students']);
        } else {
          throw Exception(data['message']);
        }
      } else {
        throw Exception('Failed to load eligible students');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching eligible students: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return [];
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
            _partylist.clear();
            _partylist.addAll(List<String>.from(data['partylist']));
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
            _positions.clear();
            _positions.addAll(List<String>.from(data['positions']));
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


  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageFile = bytes;
      });
    }
  }

  Future<String?> _uploadImageToDatabase(Uint8List image) async {
  setState(() {
    _isUploadingImage = true;
  });

  try {
    // Convert image to base64 string
    String base64Image = base64Encode(image);
    
    setState(() {
      _isUploadingImage = false;
    });
    
    return base64Image;
  } catch (e) {
    setState(() {
      _isUploadingImage = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: Colors.red,
      content: Text('Image conversion failed: $e'),
    ));
    
    return null;
  }
}


  Future<void> _saveCandidate(String img) async {
    setState(() {
      _isSaving = true;
    });

    final url = Uri.parse('https://studentcouncil.bcp-sms1.com/php/add_candidate.php');
    final response = await http.post(
      url,
      body: {
        'studentno': _studentNoController.text,
        'firstname': _firstNameController.text,
        'middlename': _middleNameController.text.isEmpty ? '' : _middleNameController.text,
        'lastname': _lastNameController.text,
        'section': _sectionController.text,
        'course': _courseController.text,
        'slogan': _sloganController.text,
        'position': _selectedPosition,
        'partylist': _selectedPartylist ?? '',
        'img': img,
      },
    );

    final responseBody = json.decode(response.body);

    if (responseBody['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: Colors.green,
        content: Text('Candidate added successfully!'),
      ));

      _resetFormFields();
    } else {
      print(responseBody['message']);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red,
        content: Text(responseBody['message']),
      ));
    }

    setState(() {
      _isSaving = false;
    });
  }

  Future<bool> _checkStudentNoExists(String studentNo) async {
    final url = Uri.parse('https://studentcouncil.bcp-sms1.com/php/check_studentno.php');
    final response = await http.post(url, body: {
      'studentno': studentNo,
    });

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return jsonResponse['exists'] == true;
    } else {
      return false;
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final studentNo = _studentNoController.text;
      bool exists = await _checkStudentNoExists(studentNo);

      if (exists) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Student number already exists!'),
        ));
        return;
      }

      if (_imageFile != null) {
        final base64Image = await _uploadImageToDatabase(_imageFile!);
        if (base64Image != null) {
          await _saveCandidate(base64Image);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Image upload failed.'),
          ));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Please upload an image.'),
        ));
      }
    }
  }

  void _resetFormFields() {
    _studentNoController.clear();
    _firstNameController.clear();
    _middleNameController.clear();
    _lastNameController.clear();
    _sectionController.clear();
    _courseController.clear();
    _sloganController.clear();
    _selectedPosition = null;
    _selectedPartylist = null;
    _imageFile = null;
    setState(() {});
  }

  void _onSearchChanged(String value) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (value.isNotEmpty) {
        final students = await _fetchEligibleStudents(searchTerm: value);
        setState(() {
          _filteredStudents = students;
        });
      } else {
        setState(() {
          _filteredStudents = [];
        });
      }
    });
  }

  Future<void> fetchAndSaveData() async {
    final response = await http.get(Uri.parse('https://registrar.bcp-sms1.com/api/students.php'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final saveResponse = await http.post(
        Uri.parse('https://studentcouncil.bcp-sms1.com/php/registrar_students_info.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      // print('Data sent: ${jsonEncode(data)}');

      if (saveResponse.statusCode == 200) {
        print('Data saved successfully');
        // print('Save response: ${saveResponse.body}');
      } else {
        print('Failed to save data');
      }
    } else {
      print('Failed to fetch data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add New Candidate'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildStudentNoField(), // Use the new method here
                      _buildTextField(_firstNameController, 'First Name', 255, true, true),
                      _buildTextField(_middleNameController, 'Middle Name', 255, false, true),
                      _buildTextField(_lastNameController, 'Last Name', 255, true, true),
                      _buildTextField(_sectionController, 'Section', 255, true, true),
                      _buildTextField(_courseController, 'Course', 255, true, true),
                      _buildTextField(_sloganController, 'Slogan', 255, true, false),
                      _buildDropdownFieldPosition(),
                      _buildDropdownFieldPartylist(),
                      const SizedBox(height: 10),
                      _buildImageUploadSection(),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const CandidatesPage()),
                              );
                            },
                            child: const Text('Cancel', style: TextStyle(color: Colors.white),
                          ),
                          ),
                          const SizedBox(width: 10),
                          _buildSubmitButton(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentNoField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _studentNoController,
          maxLength: 8,
          decoration: InputDecoration(
            labelText: 'Student No',
            counterText: '',
            suffixIcon: IconButton(
              icon: Icon(Icons.search), // Add search icon
              onPressed: () async {
                // Fetch all eligible students when the search icon is clicked
                final students = await _fetchEligibleStudents();
                setState(() {
                  _filteredStudents = students;
                });
              },
            ),
          ),
          onChanged: _onSearchChanged, // Use the debounced method
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter Student No';
            }
            return null;
          },
        ),
        if (_filteredStudents.isNotEmpty)
          Container(
            margin: EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(5),
            ),
            height: 250, // Adjust height as needed
            child: ListView.builder(
              itemCount: _filteredStudents.length,
              itemBuilder: (context, index) {
                final student = _filteredStudents[index];
                return ListTile(
                  title: Text('${student['firstname'] ?? ''} ${student['lastname'] ?? ''}'),
                  subtitle: Text('Student No: ${student['studentno'] ?? ''}'),
                  onTap: () {
                    _studentNoController.text = student['studentno']?.toString() ?? '';
                    _firstNameController.text = student['firstname'] ?? '';
                    _lastNameController.text = student['lastname'] ?? '';
                    _sectionController.text = student['section'] ?? '';
                    _courseController.text = student['course'] ?? '';
                    setState(() {
                      _filteredStudents = []; // Clear the list after selection
                    });
                  },
                );
              },
            ),
          ),
      ],
    );
}

  void _showStudentSelectionDialog(List<Map<String, dynamic>> students) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select Student'),
          content: SingleChildScrollView(
            child: Column(
              children: students.map((student) {
                return ListTile(
                  title: Text('${student['firstname'] ?? ''} ${student['lastname'] ?? ''}'),
                  subtitle: Text('Student No: ${student['studentno'] ?? ''}'),
                  onTap: () {
                    _studentNoController.text = student['studentno']?.toString() ?? '';
                    _firstNameController.text = student['firstname'] ?? '';
                    _lastNameController.text = student['lastname'] ?? '';
                    _sectionController.text = student['section'] ?? '';
                    _courseController.text = student['course'] ?? '';
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, [int? maxLength, bool isRequired = false, bool readOnly = false]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: controller,
        maxLength: maxLength,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          counterText: maxLength != null ? '' : null,
        ),
        validator: isRequired
            ? (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter $label';
                }
                return null;
              }
            : null, // No validation for optional fields
      ),
    );
  }

  Widget _buildDropdownFieldPosition() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(labelText: 'Position'),
        value: _selectedPosition,
        items: _positions.map((position) {
          return DropdownMenuItem(
            value: position,
            child: Text(position),
          );
        }).toList(),
        onChanged: (newValue) {
          setState(() {
            _selectedPosition = newValue;
          });
        },
        validator: (value) {
          if (value == null) {
            return 'Please select a position';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdownFieldPartylist() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(labelText: 'Partylist'),
        value: _selectedPartylist,
        items: _partylist.map((partylist) {
          return DropdownMenuItem(
            value: partylist,
            child: Text(partylist),
          );
        }).toList(),
        onChanged: (newValue) {
          setState(() {
            _selectedPartylist = newValue;
          });
        },
        validator: null, // No validation for optional fields
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (_imageFile != null) 
          Image.memory(
            _imageFile!,
            height: 150,
            width: 150,
            fit: BoxFit.cover,
          ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _pickImage,
          style: ElevatedButton.styleFrom(
            // backgroundColor: Colors.blue,
          ),
          child: const Text('Upload Image'),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      // width: 150,
      child: ElevatedButton(
        onPressed: _isSaving || _isUploadingImage ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          // padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        child: _isSaving
            ? const CircularProgressIndicator(
                color: Colors.white,
              )
            : const Text('Save', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}