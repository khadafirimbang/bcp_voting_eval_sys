import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:SSCVote/admin_pages/accounts.dart';
import 'package:http/http.dart' as http;

class AddAccountPage extends StatefulWidget {
  @override
  _AddAccountPageState createState() => _AddAccountPageState();
}

class _AddAccountPageState extends State<AddAccountPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController studentnoController;
  late TextEditingController firstnameController;
  late TextEditingController middlenameController;
  late TextEditingController lastnameController;
  late TextEditingController passwordController;
  late TextEditingController confirmPasswordController;
  late TextEditingController emailController;
  String role = 'Admin&69*-+';
  String? studentNoError; // Variable to hold error message for student number

  @override
  void initState() {
    super.initState();
    studentnoController = TextEditingController();
    firstnameController = TextEditingController();
    middlenameController = TextEditingController();
    lastnameController = TextEditingController();
    passwordController = TextEditingController();
    confirmPasswordController = TextEditingController();
    emailController = TextEditingController();
  }

  @override
  void dispose() {
    studentnoController.dispose();
    firstnameController.dispose();
    middlenameController.dispose();
    lastnameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
     emailController.dispose();
    super.dispose();
  }

  // Function to check if student number already exists
  Future<bool> checkStudentNo() async {
    final response = await http.post(
      Uri.parse('https://studentcouncil.bcp-sms1.com/php/check_accounts.php'),
      body: {'studentno': studentnoController.text},
    );

    if (response.statusCode == 200) {
      var jsonResponse = json.decode(response.body);
      // Ensure 'exists' is a boolean or default to false if null
      return jsonResponse['exists'] == true; // Explicitly check for true
    } else {
      // Handle server error
      throw Exception('Failed to check student number');
    }
  }

  Future<void> saveAccount() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Check if student number already exists
        bool exists = await checkStudentNo();
        if (exists) {
          setState(() {
            studentNoError = 'Student number already exists.';
          });
          return; // Stop further execution
        } else {
          setState(() {
            studentNoError = null; // Clear error if student number is valid
          });
        }

        final response = await http.post(
          Uri.parse('https://studentcouncil.bcp-sms1.com/php/add_account.php'),
          body: {
            'studentno': studentnoController.text,
            'firstname': firstnameController.text,
            'middlename': middlenameController.text,
            'lastname': lastnameController.text,
            'password': passwordController.text,
            'email': emailController.text,
            'role': role,
          },
        );

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          if (responseData['success'] == true) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AccountsPage()),
            );
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              backgroundColor: Colors.green,
              content: Text('Account added successfully!'),
            ));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(responseData['error'] ?? 'Failed to add account.')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save account. Please try again.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add Admin Account'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white, // Background color of the container
              borderRadius: BorderRadius.circular(10.0), // Rounded corners
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2), // Shadow color
                  spreadRadius: 3, // Spread radius of shadow
                  blurRadius: 5, // Blur radius of shadow
                  offset: const Offset(0, 3), // Offset for shadow
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(30.0), // Inner padding for the container
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: studentnoController,
                        decoration: const InputDecoration(labelText: 'Student Number'),
                        validator: (value) {
                          if (value!.isEmpty) return 'Enter student number';
                          return null;
                        },
                      ),
                      if (studentNoError != null) // Display error message if exists
                        Text(
                          studentNoError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      TextFormField(
                        controller: firstnameController,
                        decoration: const InputDecoration(labelText: 'First Name'),
                        validator: (value) {
                          if (value!.isEmpty) return 'Enter first name';
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: middlenameController,
                        decoration: const InputDecoration(labelText: 'Middle Name'),
                        
                      ),
                      TextFormField(
                        controller: lastnameController,
                        decoration: const InputDecoration(labelText: 'Last Name'),
                        validator: (value) {
                          if (value!.isEmpty) return 'Enter last name';
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: emailController, // New email field
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (value) {
                          if (value!.isEmpty) return 'Enter email';
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Password'),
                        validator: (value) {
                          if (value!.isEmpty) return 'Enter password';
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Confirm Password'),
                        validator: (value) {
                          if (value!.isEmpty) return 'Confirm your password';
                          if (value != passwordController.text) return 'Passwords do not match';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      Column(
                        children: [
                          SizedBox(
                            width: 100,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                              ),
                              onPressed: saveAccount,
                              child: const Text('Save', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: 100,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                              ),
                              onPressed: () {
                                Navigator.of(context).pop(); // Go back to AccountsPage
                              },
                              child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                            ),
                          ),
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
}
