import 'package:flutter/material.dart';
import 'package:SSCVote/signin.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
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

  // Function to sanitize input
  String sanitizeInput(String input) {
    return input.trim().replaceAll(RegExp(r'[^a-zA-Z0-9@._-]'), '');
  }

  // Validate student number
  String? validateStudentNo(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your student number';
    } else if (value.length < 7 || value.length > 9) {
      return 'Student number must be 8 characters';
    }
    return null;
  }

  // Validate password
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    } else if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    return null;
  }

  Future<void> _signUp() async {
  if (_formKey.currentState!.validate()) {
    // Sanitize inputs
    String sanitizedStudentNo = sanitizeInput(studentNoController.text);
    String sanitizedPassword = sanitizeInput(passwordController.text);
    String sanitizedConfirmPassword = sanitizeInput(confirmPasswordController.text);

    // Use the sanitized inputs in the request
    try {
      final response = await http.post(
        // Uri.parse('http://192.168.1.6/SSCVote/signup.php'),
        Uri.parse('https://studentcouncil.bcp-sms1.com/php/signup.php'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'studentno': sanitizedStudentNo,
          'password': sanitizedPassword,
          'cpassword': sanitizedConfirmPassword,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration Complete!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
          // Navigate to another page or clear the form
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SignUpPage()),
          );
        } else {
          setState(() {
            errorMessage = data['message'];
          });
        }
      } else {
        setState(() {
          errorMessage = 'Failed to connect to server. Status code: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred: $e';
      });
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                const SizedBox(height: 80),
                Image.asset(
                  'assets/bcp_logo.png',
                  width: 100,
                ),
                const SizedBox(height: 80),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const Text(
                        'Create an Account',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: 340,
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          controller: studentNoController,
                          decoration: const InputDecoration(labelText: 'Student Number'),
                          validator: validateStudentNo,
                        ),
                      ),
                      const SizedBox(height: 5),
                      SizedBox(
                        width: 340,
                        child: TextFormField(
                          keyboardType: TextInputType.text,
                          controller: passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureText ? Icons.visibility : Icons.visibility_off,
                              ),
                              onPressed: _togglePasswordVisibility,
                            ),
                          ),
                          obscureText: _obscureText,
                          validator: validatePassword,
                        ),
                      ),
                      const SizedBox(height: 5),
                      SizedBox(
                        width: 340,
                        child: TextFormField(
                          keyboardType: TextInputType.text,
                          controller: confirmPasswordController,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureText2 ? Icons.visibility : Icons.visibility_off,
                              ),
                              onPressed: _togglePasswordVisibility2,
                            ),
                          ),
                          obscureText: _obscureText2,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            } else if (value != passwordController.text) {
                              return 'Passwords do not match';
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
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.all(14.0),
                            backgroundColor: const Color(0xFF1E3A8A),
                          ),
                          onPressed: () {
                            _signUp();
                          },
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginPage()),
                          );
                        },
                        child: const Text(
                          'Click here to Sign in',
                          style: TextStyle(color: Color(0xFF1E3A8A)),
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
