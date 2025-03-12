import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ProfileInfoAdminPage extends StatefulWidget {
  const ProfileInfoAdminPage({Key? key}) : super(key: key);

  @override
  _ProfileInfoAdminPageState createState() => _ProfileInfoAdminPageState();
}

class _ProfileInfoAdminPageState extends State<ProfileInfoAdminPage> {
  // Text editing controllers
  final TextEditingController _studentNoController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();

  // State to manage edit mode
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // Fetch user data when the screen initializes
  Future<void> _fetchUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final studentNo = prefs.getString('studentno');

      if (studentNo != null && studentNo.isNotEmpty) {
        _studentNoController.text = studentNo;
        await _fetchUserDataFromServer(studentNo);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No student number found')),
        );
      }
    } catch (e) {
      print('Error fetching student number: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error retrieving student information')),
      );
    }
  }

  // Fetch user data from server
  Future<void> _fetchUserDataFromServer(String studentNo) async {
    try {
      final response = await http.post(
        Uri.parse('https://studentcouncil.bcp-sms1.com/php/fetch_user_info.php'),
        body: {'student_no': studentNo},
      );

      if (response.statusCode == 200) {
        final dynamic responseBody = json.decode(response.body);
        if (responseBody is Map<String, dynamic>) {
          setState(() {
            _studentNoController.text = (responseBody['studentno'] ?? '').toString();
            _firstNameController.text = (responseBody['firstname'] ?? '').toString();
            _middleNameController.text = (responseBody['middlename'] ?? '').toString();
            _lastNameController.text = (responseBody['lastname'] ?? '').toString();
            _emailController.text = (responseBody['email'] ?? '').toString();
          });
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch user data: ${response.body}')),
        );
      }
    } catch (e) {
      print('Error fetching user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  // Toggle edit mode
  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        _fetchUserData();
      }
    });
  }

  // Save changes to the server
  Future<void> _saveChanges() async {
    // Validate required fields
    if (_studentNoController.text.isEmpty ||
        _firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    if (_currentPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your current password')),
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final studentNo = prefs.getString('studentno');

      final response = await http.post(
        Uri.parse('https://studentcouncil.bcp-sms1.com/php/update_user_info.php'),
        body: {
          'student_no': studentNo,
          'new_student_no': _studentNoController.text,
          'firstname': _firstNameController.text,
          'middlename': _middleNameController.text,
          'lastname': _lastNameController.text,
          'email': _emailController.text,
          'current_password': _currentPasswordController.text,
        },
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        if (responseBody['success'] != null) {
          if (_studentNoController.text != studentNo) {
            await prefs.setString('studentno', _studentNoController.text);
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseBody['success']), backgroundColor: Colors.green),
          );
          _toggleEditMode();
        } else if (responseBody['error'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseBody['error']), backgroundColor: Colors.red),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: ${response.body}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    Orientation orientation = MediaQuery.of(context).orientation;

    int crossAxisCount = _calculateCrossAxisCount(screenWidth, orientation);

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          actions: [
            IconButton(
              icon: Icon(_isEditing ? Icons.cancel : Icons.edit),
              onPressed: _toggleEditMode,
            ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Employee Information',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildResponsiveGrid(crossAxisCount),

                        if (_isEditing) ...[
                          const SizedBox(height: 10),
                          _buildTextField('Current Password', _currentPasswordController, isPassword: true),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton(
                                onPressed: _saveChanges,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                ),
                                child: Text('Save', style: TextStyle(color: Colors.white)),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: _toggleEditMode,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey,
                                ),
                                child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Calculate cross axis count based on screen width and orientation
  int _calculateCrossAxisCount(double width, Orientation orientation) {
    if (width > 600) return 2; // Large screens
    return 1; // Mobile phones
  }

  // Build a responsive grid of text fields
  Widget _buildResponsiveGrid(int crossAxisCount) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      childAspectRatio: crossAxisCount == 1 ? 5 : 8,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: [
        _buildTextField('Employee No', _studentNoController),
        _buildTextField('First Name', _firstNameController),
        _buildTextField('Middle Name', _middleNameController),
        _buildTextField('Last Name', _lastNameController),
        _buildTextField('Email', _emailController),
      ],
    );
  }

  // Build a text field
  Widget _buildTextField(String label, TextEditingController controller, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.black54,
          fontSize: 14,
        ),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      obscureText: isPassword,
      enabled: _isEditing,
      style: TextStyle(
        color: _isEditing ? Colors.black : Colors.black54,
        fontSize: 15,
      ),
    );
  }
}
