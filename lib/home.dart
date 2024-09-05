import 'dart:io';
import 'package:flutter/material.dart';
import 'package:for_testing/drawerbar.dart';
import 'package:for_testing/main.dart';
import 'package:for_testing/vote.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomePage extends StatelessWidget {
  Future<void> _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('studentno');

    // Optionally call your server to end the session
    await http.post(Uri.parse('http://192.168.1.29/for_testing/logout.php'));

    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => const LoginPage()));
  }

  // Function to show logout confirmation dialog
  Future<void> _showLogoutDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout Confirmation'),
          content: const Text('Are you sure you want to logout?'),
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
                _logout(context); // Call the logout function
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
  String? errorMessage;

  bool _obscureText = true;
  bool _obscureText2 = true;

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

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      final response = await http.post(
        Uri.parse('http://192.168.1.29/for_testing/signup.php'),
        body: {
          'studentno': studentNoController.text,
          'password': passwordController.text,
          'cpassword': confirmPasswordController.text,
        },
      );

      final data = json.decode(response.body);

      if (data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration Complete!'), backgroundColor: Colors.green, duration: Duration(seconds: 1),),
        );
        // Navigate to another page or clear the form
                  Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileInfo()),
              );
      } else {
        setState(() {
          errorMessage = data['message'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text('Sign Up')),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('Profile Information',  style: TextStyle(color: Colors.white)),
          iconTheme: IconThemeData(
            color: Colors.white, // Change the color of the Drawer icon here
          ),
        ),
      drawer: AppDrawer(),
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
                      const Text('Enter your information to Vote.',
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
                          // controller: studentNoController,
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
                          // controller: studentNoController,
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
                          // controller: studentNoController,
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
                          // controller: studentNoController,
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
                          // controller: studentNoController,
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
                      const SizedBox(height: 20),
                      SizedBox(
                        width: 340,
                        child: TextButton(
                              style: TextButton.styleFrom(
                                shape: const RoundedRectangleBorder(),
                                padding: const EdgeInsets.all(14.0),
                                backgroundColor: Colors.green,
                                
                              ),
                              onPressed: () {_signUp();},
                              child: const Text('Save', 
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                ),),
                            ),
                      ),

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

