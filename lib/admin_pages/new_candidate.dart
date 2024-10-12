import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:for_testing/admin_pages/candidates.dart';
import 'package:for_testing/admin_pages/drawerbar_admin.dart';
import 'package:image_picker_web/image_picker_web.dart'; // For Web Image Picker
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_spinkit/flutter_spinkit.dart';

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
  TextEditingController _sloganController = TextEditingController(); // New slogan field

  String? _selectedPosition;
  Uint8List? _imageFile;
  bool _isUploadingImage = false;
  bool _isSaving = false; // To handle loading state

  final List<String> _positions = [
    'President',
    'Vice President',
    'Secretary',
    'Treasurer',
    'Auditor'
  ];

  Future<void> _pickImage() async {
    var pickedFile = await ImagePickerWeb.getImageAsBytes();
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }

  Future<String?> _uploadImageToCloudinary(Uint8List image) async {
    setState(() {
      _isUploadingImage = true;
    });

    String cloudinaryUrl = 'https://api.cloudinary.com/v1_1/dcmdta4rb/image/upload';
    String apiKey = '187942544922379';
    String uploadPreset = 'sjon389q';

    // Generate the filename using student number
    String studentNo = _studentNoController.text;
    String filename = 'candidate_$studentNo.png'; // Set the filename

    var request = http.MultipartRequest('POST', Uri.parse(cloudinaryUrl));
    request.fields['upload_preset'] = uploadPreset;
    request.fields['api_key'] = apiKey;
    request.files.add(http.MultipartFile.fromBytes('file', image, filename: filename)); // Use generated filename

    var response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final jsonData = json.decode(responseData);
      setState(() {
        _isUploadingImage = false;
      });
      return jsonData['secure_url'];
    } else {
      setState(() {
        _isUploadingImage = false;
      });
      return null;
    }
  }

  Future<void> _saveCandidate(String imageUrl) async {
    setState(() {
      _isSaving = true; // Start saving state
    });

    final url = Uri.parse('https://studentcouncil.bcp-sms1.com/php/add_candidate.php');
    final response = await http.post(
      url,
      body: {
        'studentno': _studentNoController.text,
        'firstname': _firstNameController.text,
        'middlename': _middleNameController.text,
        'lastname': _lastNameController.text,
        'section': _sectionController.text,
        'course': _courseController.text,
        'slogan': _sloganController.text, // Slogan field data
        'position': _selectedPosition,
        'image_url': imageUrl,
      },
    );

    final responseBody = json.decode(response.body);

    if (responseBody['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: Colors.green,
        content: Text('Candidate added successfully!'),
      ));

      // Reset form fields after success
      _resetFormFields();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red,
        content: Text(responseBody['message']),
      ));
    }

    setState(() {
      _isSaving = false; // Stop saving state
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
    return false; // In case of error, consider it does not exist
  }
}

void _submitForm() async {
  if (_formKey.currentState!.validate()) {
    // Check if the student number already exists
    final studentNo = _studentNoController.text;
    bool exists = await _checkStudentNoExists(studentNo);

    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: Colors.red,
        content: Text('Student number already exists!'),
      ));
      return; // Exit the method without proceeding
    }

    if (_imageFile != null) {
      final imageUrl = await _uploadImageToCloudinary(_imageFile!);
      if (imageUrl != null) {
        _saveCandidate(imageUrl);
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
    _sloganController.clear(); // Reset slogan field
    _selectedPosition = null;
    _imageFile = null;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        title: const Text('Add New Candidate', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        ),
      drawer: AppDrawerAdmin(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12), // Rounded corners
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 5,
                blurRadius: 7,
                offset: const Offset(0, 3), // Changes position of shadow
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
                    _buildTextField(_studentNoController, 'Student No', 8),
                    _buildTextField(_firstNameController, 'First Name'),
                    _buildTextField(_middleNameController, 'Middle Name'),
                    _buildTextField(_lastNameController, 'Last Name'),
                    _buildTextField(_sectionController, 'Section'),
                    _buildTextField(_courseController, 'Course'),
                    _buildTextField(_sloganController, 'Slogan'), // Slogan field
                    _buildDropdownField(),
                    const SizedBox(height: 10),
                    _buildImageUploadSection(),
                    const SizedBox(height: 20),
                    _buildSubmitButton(),
                    const SizedBox(height: 10,),
                    ElevatedButton(
                      
                      onPressed: () {
                      Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const CandidatesPage()),
                            );
                    }, 
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red, // Set the background color
                    ),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white),))
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, [int? maxLength]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: controller,
        maxLength: maxLength, // Set maximum length for student number
        decoration: InputDecoration(
          labelText: label,
          counterText: maxLength != null ? '' : null, // Hide counter if not needed
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          if (label == 'Student No' && value.length != 8) { // Validate student number length
            return 'Student number must be 8 characters';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdownField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(labelText: 'Position'),
        value: _selectedPosition,
        items: _positions.map((String position) {
          return DropdownMenuItem<String>(
            value: position,
            child: Text(position),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedPosition = value;
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

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center, // Align image section center
      children: [
        ElevatedButton(
          onPressed: _pickImage,
          child: const Text('Upload Image'),
        ),
        const SizedBox(height: 10),
        _imageFile != null
            ? Image.memory(
                _imageFile!,
                width: 200,
                fit: BoxFit.cover,
              )
            : const Text('No image selected', style: TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A), // Set the background color
                    ),
      onPressed: _isSaving || _isUploadingImage ? null : _submitForm, // Disable button while saving or uploading
      child: _isSaving || _isUploadingImage
          ? const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 10),
                // Text('Saving...'), // Optionally include text
              ],
            )
          : const Text('Submit', style: TextStyle(color: Colors.white)),
    );
  }
}
