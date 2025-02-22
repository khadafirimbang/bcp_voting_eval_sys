import 'package:SSCVote/main.dart';
import 'package:SSCVote/signin.dart';
import 'package:SSCVote/voter_pages/announcement.dart';
import 'package:SSCVote/voter_pages/drawerbar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ProfileInfoPage extends StatefulWidget {
  const ProfileInfoPage({Key? key}) : super(key: key);

  @override
  _ProfileInfoPageState createState() => _ProfileInfoPageState();
  }

  class _ProfileInfoPageState extends State<ProfileInfoPage> {
  // Text editing controllers
  final TextEditingController _studentNoController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _sectionController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Fetch user data when the screen initializes
    _fetchUserData();
  }

  // Fetch student number from SharedPreferences and use it to get user data
  Future<void> _fetchUserData() async {
    try {
      // Get SharedPreferences instance
      final prefs = await SharedPreferences.getInstance();
      
      // Retrieve the stored student number
      final studentNo = prefs.getString('studentno');

      if (studentNo != null && studentNo.isNotEmpty) {
        // Set the student number in the controller
        _studentNoController.text = studentNo;
        
        // Fetch user data using the student number
        await _fetchUserDataFromServer(studentNo);
      } else {
        // Handle case where student number is not found
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
      // Replace with your actual PHP endpoint
      final response = await http.post(
        Uri.parse('https://studentcouncil.bcp-sms1.com/php/fetch_user_info.php'),
        body: {
          'student_no': studentNo,
        },
      );

      if (response.statusCode == 200) {
        // Parse the response body
        final dynamic responseBody = json.decode(response.body);
        
        // Check if the response is a map
        if (responseBody is Map<String, dynamic>) {
          setState(() {
            // Populate text controllers with user data
            _studentNoController.text = 
              (responseBody['studentno'] ?? '').toString();
            _firstNameController.text = 
              (responseBody['firstname'] ?? '').toString();
            _middleNameController.text = 
              (responseBody['middlename'] ?? '').toString();
            _lastNameController.text = 
              (responseBody['lastname'] ?? '').toString();
            _courseController.text = 
              (responseBody['course'] ?? '').toString();
            _sectionController.text = 
              (responseBody['section'] ?? '').toString();
          });
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        // Handle error
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

 @override
Widget build(BuildContext context) {
  // Get screen width and orientation to determine layout
  double screenWidth = MediaQuery.of(context).size.width;
  Orientation orientation = MediaQuery.of(context).orientation;

  // Determine number of columns based on screen width and orientation
  int crossAxisCount = _calculateCrossAxisCount(screenWidth, orientation);

  return SafeArea(
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16.0),
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
                        'Student Information', 
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildResponsiveGrid(crossAxisCount),
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
  return 1;  // Mobile phones
}

// Build a responsive grid of text fields
Widget _buildResponsiveGrid(int crossAxisCount) {
  return GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: crossAxisCount,
    childAspectRatio: crossAxisCount == 1 ? 5 : 8, // Adjust aspect ratio based on columns
    mainAxisSpacing: 10,
    crossAxisSpacing: 10,
    children: [
      _buildTextField('Student No', _studentNoController),
      _buildTextField('First Name', _firstNameController),
      _buildTextField('Middle Name', _middleNameController),
      _buildTextField('Last Name', _lastNameController),
      _buildTextField('Course', _courseController),
      _buildTextField('Section', _sectionController),
    ],
  );
}

// Modify the text field builder for better mobile responsiveness
Widget _buildTextField(String label, TextEditingController controller) {
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
    enabled: false,
    style: const TextStyle(
      color: Colors.black54,
      fontSize: 15,
    ),
  );
}
}
