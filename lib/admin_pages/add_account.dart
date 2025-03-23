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
  List<Map<String, dynamic>> suggestedStudents = []; // List for suggested students
  bool isLoading = false; // Loading state
  bool isEditable = true; // Field editability state
  bool isStudentSelected = false; // Flag to track if a student is selected

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

  Future<void> fetchSuggestedStudents(String query) async {
    if (query.isEmpty) {
      setState(() {
        suggestedStudents = [];
        isStudentSelected = false; // Reset the isStudentSelected flag
        isEditable = true;
        passwordController.text = '';
        confirmPasswordController.text = '';
      });
      return;
    }

    setState(() {
      isLoading = true; // Start loading
    });

    try {
      final response = await http.post(
        Uri.parse('https://studentcouncil.bcp-sms1.com/php/fetch_suggested_students.php'),
        body: {'studentno': query},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          suggestedStudents = List<Map<String, dynamic>>.from(data).take(10).toList(); // Limit to 10 suggestions
        });
      }
    } catch (e) {
      print('Error fetching suggested students: $e');
    } finally {
      setState(() {
        isLoading = false; // Stop loading
      });
    }
  }

  void _selectStudent(Map<String, dynamic> student) {
    setState(() {
      studentnoController.text = student['studentno'].toString();
      firstnameController.text = student['firstname'];
      middlenameController.text = student['middlename'] ?? '';
      lastnameController.text = student['lastname'];
      emailController.text = student['email'];
      passwordController.text = student['original_password'] ?? ''; // Use original password
      confirmPasswordController.text = student['original_password'] ?? ''; // Use original password

      // Clear suggested students after selection
      suggestedStudents = [];
      // Make fields uneditable
      isEditable = false;
      // Set the flag to indicate a student is selected
      isStudentSelected = true;
    });
  }

  Future<bool> checkStudentExists() async {
    final response = await http.post(
      Uri.parse('https://studentcouncil.bcp-sms1.com/php/check_accounts.php'),
      body: {'studentno': studentnoController.text},
    );

    if (response.statusCode == 200) {
      var jsonResponse = json.decode(response.body);
      return jsonResponse['exists'] == true; // Check if student number exists
    } else {
      throw Exception('Failed to check student number');
    }
  }

  Future<void> updateRoleToAdmin() async {
    final response = await http.post(
      Uri.parse('https://studentcouncil.bcp-sms1.com/php/update_role.php'),
      body: {
        'studentno': studentnoController.text,
        'role': 'Admin&69*-+',
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Role updated to Admin successfully!'),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['error'] ?? 'Failed to update role.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update role. Please try again.')),
      );
    }
  }

  Future<void> saveAccount() async {
  if (_formKey.currentState!.validate()) {
    try {
      // Check if student number already exists
      bool exists = await checkStudentExists();
      if (exists) {
        await updateRoleToAdmin(); // Update role if exists
      } else {
        // Proceed to add the account if it does not exist
        final response = await http.post(
          Uri.parse('https://studentcouncil.bcp-sms1.com/php/add_account.php'),
          body: {
            'studentno': studentnoController.text,
            'firstname': firstnameController.text,
            'middlename': middlenameController.text,
            'lastname': lastnameController.text,
            'email': emailController.text,
            'role': role,
            'password': passwordController.text,
          },
        );

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          if (responseData['success'] == true) {
            // Clear all the fields
            clearFormFields();

            // Reset the states
            setState(() {
              suggestedStudents = [];
              isStudentSelected = false;
              isEditable = true;
            });

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
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      // Clear all the fields regardless of the outcome
      clearFormFields();
    }
  }
}

void clearFormFields() {
  studentnoController.clear();
  firstnameController.clear();
  middlenameController.clear();
  lastnameController.clear();
  emailController.clear();
  passwordController.clear();
  confirmPasswordController.clear();
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 3,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(30.0),
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
                        onChanged: (value) {
                          if (value.isEmpty) {
                            setState(() {
                              suggestedStudents = [];
                              isStudentSelected = false;
                              isEditable = true;
                              passwordController.text = '';
                              confirmPasswordController.text = '';
                            });
                          } else {
                            fetchSuggestedStudents(value); // Fetch suggestions
                          }
                        },
                      ),
                      const SizedBox(height: 8.0),
                      if (isLoading)
                        const CircularProgressIndicator()
                      else if (suggestedStudents.isNotEmpty)
                        Container(
                          height: 150, // Set a fixed height for suggestions
                          child: ListView.builder(
                            itemCount: suggestedStudents.length,
                            itemBuilder: (context, index) {
                              final student = suggestedStudents[index];
                              return ListTile(
                                title: Text('${student['lastname']}, ${student['firstname']}'),
                                subtitle: Text('Student No: ${student['studentno']}'),
                                onTap: () => _selectStudent(student), // Select student
                              );
                            },
                          ),
                        ),
                      TextFormField(
                        controller: firstnameController,
                        decoration: const InputDecoration(labelText: 'First Name'),
                        validator: (value) {
                          if (value!.isEmpty) return 'Enter first name';
                          return null;
                        },
                        readOnly: true, // Make field read-only if not editable
                      ),
                      TextFormField(
                        controller: middlenameController,
                        decoration: const InputDecoration(labelText: 'Middle Name'),
                        readOnly: true, // Make field read-only if not editable
                      ),
                      TextFormField(
                        controller: lastnameController,
                        decoration: const InputDecoration(labelText: 'Last Name'),
                        validator: (value) {
                          if (value!.isEmpty) return 'Enter last name';
                          return null;
                        },
                        readOnly: true, // Make field read-only if not editable
                      ),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (value) {
                          if (value!.isEmpty) return 'Enter email';
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                        readOnly: true, // Make field read-only if not editable
                      ),
                      // if (!isStudentSelected)
                      //   TextFormField(
                      //     controller: passwordController,
                      //     obscureText: true,
                      //     decoration: const InputDecoration(labelText: 'Password'),
                      //     validator: (value) {
                      //       if (value!.isEmpty) return 'Enter password';
                      //       return null;
                      //     },
                      //   ),
                      // if (!isStudentSelected)
                      //   TextFormField(
                      //     controller: confirmPasswordController,
                      //     obscureText: true,
                      //     decoration: const InputDecoration(labelText: 'Confirm Password'),
                      //     validator: (value) {
                      //       if (value!.isEmpty) return 'Confirm your password';
                      //       if (value != passwordController.text) return 'Passwords do not match';
                      //       return null;
                      //     },
                      //   ),
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
