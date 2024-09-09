import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:for_testing/drawerbar.dart';
import 'package:for_testing/main.dart';
import 'package:for_testing/vote.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomePage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Exit the app when the back button is pressed
        return exit(0);
      },
      child: Scaffold(
        body: ProfileInfo()
      ),
    );
  }
}

class WarningBox extends StatefulWidget {
  const WarningBox({super.key});

  @override
  _WarningBoxState createState() => _WarningBoxState();
}

class _WarningBoxState extends State<WarningBox> {
  bool _isVisible = true; // Control visibility of the warning box

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: _isVisible,
      child: Container(
        margin: const EdgeInsets.all(8), // Optional margin around the box
        padding: const EdgeInsets.all(12), // Padding inside the box
        decoration: BoxDecoration(
          color: Colors.redAccent, // Red background color for the warning
          borderRadius: BorderRadius.circular(8), // Rounded corners
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between text and X button
          children: [
            const Text(
              'Note: You need to fill out the form and wait\nuntil your account is verified to vote.', // Warning text
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isVisible = false; // Close the warning box when X is clicked
                });
              },
              child: const Icon(
                Icons.close, // X (close) icon
                color: Colors.white, // White color for the X button
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// Profile 
class ProfileInfo extends StatefulWidget {
  @override
  _ProfileInfoState createState() => _ProfileInfoState();
}

class _ProfileInfoState extends State<ProfileInfo> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController studentNoController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController lastnameController = TextEditingController();
  final TextEditingController firstnameController = TextEditingController();
  final TextEditingController middlenameController = TextEditingController();
  final TextEditingController courseController = TextEditingController();
  final TextEditingController sectionController = TextEditingController();
  final TextEditingController statusController = TextEditingController();
  String? errorMessage;
  String? accountStatus;

  bool _obscureText = true;
  bool _obscureText2 = true;

    @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }
  void _togglePasswordVisibility2() {
    setState(() {
      _obscureText2 = !_obscureText2;
    });
  }

  // Fetch Profile Info
  Future<void> _fetchUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? studentno = prefs.getString('studentno');

    if (studentno != null) {
      var url = Uri.parse('http://192.168.1.2/for_testing/fetch_user_info.php');
      var response = await http.post(url, body: {'studentno': studentno});

      var data = json.decode(response.body);

      if (data['status'] == 'success') {
        // Populate the form fields with the fetched data

        setState(() {
          firstnameController.text = data['data']['firstname'];
          middlenameController.text = data['data']['middlename'];
          lastnameController.text = data['data']['lastname'];
          courseController.text = data['data']['course'];
          sectionController.text = data['data']['section'];
          statusController.text = data['data']['account_status'];
        });
      } else {
        print('Error fetching user data: ${data['message']}');
        setState(() {
        });
      }
    } else {
      print('Error: studentno not found in SharedPreferences');
      setState(() {
      });
    }
  }

  Future<void> updateInfo(
    String firstname, String middlename, String lastname, String course, String section) async {
  
  // Retrieve studentno from SharedPreferences
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? studentno = prefs.getString('studentno');

  if (studentno == null) {
    print('Error: studentno not found in SharedPreferences');
    return;
  }

  // The URL of your PHP script
  var url = Uri.parse('http://192.168.1.2/for_testing/update_profile.php');

  // Make the POST request to the server with the updated data
  var response = await http.post(
    url,
    body: {
      'studentno': studentno,  // Use studentno from SharedPreferences
      'firstname': firstname,
      'middlename': middlename,
      'lastname': lastname,
      'course': course,
      'section': section,
    },
  );

  // Decode the JSON response
  var data = json.decode(response.body);

  if (data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Update Successfully!'), backgroundColor: Colors.green, duration: Duration(seconds: 2),),
        );
  } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Update Failed!'), backgroundColor: Colors.red, duration: Duration(seconds: 2),),
        );
  }
}

void _submitForm() {
  if (_formKey.currentState!.validate()) {
    // If the form is valid, proceed with submitting the data
    String firstname = firstnameController.text;
    String middlename = middlenameController.text;
    String lastname = lastnameController.text;
    String course = courseController.text;
    String section = sectionController.text;

    // Call the update function
    updateInfo(firstname, middlename, lastname, course, section);
  } else {
    // If the form is invalid, show a validation message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please fill out all fields correctly'), backgroundColor: Colors.red, duration: Duration(seconds: 2)),
    );
  }
}

    // Function to show confirmation dialog
  Future<void> _showConfirmationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Profile Confirmation'),
          content: const Text('Are you sure you want to save?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _submitForm(); // Call the logout function
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text('Sign Up')),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('Profile Information',  style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(
            color: Colors.white, // Change the color of the Drawer icon here
          ),
        ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                  const SizedBox(height: 80),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const Text('Please enter your Information',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w600,
                      ),
                      ),
                      const SizedBox(height: 20,),
                      SizedBox(
                        width: 340,
                        child: TextFormField(
                          keyboardType: TextInputType.text,
                          controller: firstnameController,
                          decoration: const InputDecoration(labelText: 'First Name'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your first name';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 5),
                      SizedBox(
                        width: 340,
                        child: TextFormField(
                          keyboardType: TextInputType.text,
                          controller: middlenameController,
                          decoration: const InputDecoration(labelText: 'Middle Name'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your middle name';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 5),
                      SizedBox(
                        width: 340,
                        child: TextFormField(
                          keyboardType: TextInputType.text,
                          controller: lastnameController,
                          decoration: const InputDecoration(labelText: 'Last Name'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your last name';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 5),
                      SizedBox(
                        width: 340,
                        child: TextFormField(
                          keyboardType: TextInputType.text,
                          controller: courseController,
                          decoration: const InputDecoration(labelText: 'Course', hintText: 'Ex: BSIT'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your course';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 5),
                      SizedBox(
                        width: 340,
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          controller: sectionController,
                          decoration: const InputDecoration(labelText: 'Section', hintText: 'Ex: 41014'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your section';
                            }
                            return null;
                          },
                        ),
                      ),
                      
                      if (errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      const SizedBox(height: 5),
                      SizedBox(
                        width: 340,
                        child: TextFormField(
                          readOnly: true,
                          keyboardType: TextInputType.text,
                          controller: statusController,
                          decoration: const InputDecoration(labelText: 'Account Status',),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: 340,
                        child: TextButton(
                              style: TextButton.styleFrom(
                                shape: const RoundedRectangleBorder(),
                                padding: const EdgeInsets.all(14.0),
                                backgroundColor: Colors.green,
                                
                              ),
                              onPressed: () {_showConfirmationDialog(context);},
                              child: const Text('Save', 
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                ),),
                            ),
                      ),
                      const SizedBox(height: 10),
                      const WarningBox(),

                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

