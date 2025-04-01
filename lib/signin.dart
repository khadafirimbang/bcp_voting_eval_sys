import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:SSCVote/admin_pages/dashboard2.dart';
import 'package:SSCVote/voter_pages/announcement.dart';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return exit(0);
      },
      child: const Scaffold(
        body: LoginWidget(),
      ),
    );
  }
}

class LoginWidget extends StatefulWidget {
  const LoginWidget({super.key});

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SSCVote',
      home: LoginWidgetWidget(),
    );
  }
}

class LoginWidgetWidget extends StatefulWidget {
  const LoginWidgetWidget({super.key});

  @override
  _LoginWidgetWidgetState createState() => _LoginWidgetWidgetState();
}

class _LoginWidgetWidgetState extends State<LoginWidgetWidget> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _studentNoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;
  bool isConnectedToInternet = false;
  bool _isLoading = false; // Add this variable
  StreamSubscription? _internetConnectionStreamSubcription;
  FocusNode _focusNode = FocusNode();

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  void initState() {
    super.initState();
    _internetConnectionStreamSubcription = InternetConnection().onStatusChange.listen((event) {
      setState(() {
        isConnectedToInternet = event == InternetStatus.connected;
      });
    });
  }

  @override
  void dispose() {
    _internetConnectionStreamSubcription?.cancel();
    super.dispose();
  }

  Future<void> _login() async {
  if (_formKey.currentState!.validate()) {
    setState(() {
      _isLoading = true; // Start loading
    });

    String input = _studentNoController.text; // This can be either studentno or email
    String password = _passwordController.text;

    final response = await http.post(
      Uri.parse('https://studentcouncil.bcp-sms1.com/php/signin.php'),
      body: {
        'input': input, // Send the input (studentno or email)
        'password': password,
      },
    );

    final data = jsonDecode(response.body);

    setState(() {
      _isLoading = false; // Stop loading
    });

    if (data['status'] == 'success') {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Convert studentno to string if it's an integer
      String studentNo = data['studentno'].toString(); 
      await prefs.setString('studentno', studentNo); // Store the student number

      // Fetch the user role
      String? role = await _fetchUserRole(studentNo);
      await prefs.setString('role', role ?? ''); // Store the role

      // Navigate based on the role
      if (role == 'Voter') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AnnouncementPage()),
        );
      } else if (role == 'Admin' || role == 'SuperAdmin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardPage2()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message']),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

Future<String?> _fetchUserRole(String studentNo) async {
  try {
    final response = await http.get(
      Uri.parse('https://studentcouncil.bcp-sms1.com/php/get_user_role.php?studentNo=$studentNo'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['role']; // Adjust based on your API response structure
    } else {
      print('Failed to fetch role: ${response.statusCode}');
      return null; // Handle errors appropriately
    }
  } catch (e) {
    print('Error fetching role: $e');
    return null; // Handle exceptions
  }
}

  // String _sanitizeInput(String input) {
  //   return input.trim().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  // }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: KeyboardListener(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: (KeyEvent event) {
            if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
              _login();
            }
          },
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/bcp_logo.png',
                      width: 100,
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Login your Account',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _studentNoController,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                              labelText: 'Student Number', // Updated label
                              prefixIcon: const Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your student number or email';
                              }
                              // Check if the input is a valid email or student number
                              bool isEmail = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value);
                              bool isStudentNo = RegExp(r'^\d+$').hasMatch(value); // Assuming student numbers are numeric
                              if (!isEmail && !isStudentNo) {
                                return 'Please enter a valid email or student number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscureText,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
                                onPressed: _togglePasswordVisibility,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          // Show loading indicator if _isLoading is true
                          if (_isLoading)
                            const CircularProgressIndicator()
                          else
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 50),
                                backgroundColor: Color(0xFF313131),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                              onPressed: _login,
                              child: const Text(
                                'Login',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          // const SizedBox(height: 10),
                          // TextButton(
                          //   onPressed: () {
                          //     Navigator.push(
                          //       context,
                          //       MaterialPageRoute(builder: (context) => const SignUpPage()),
                          //     );
                          //   },
                          //   child: const Text('Create Account', style: TextStyle(color: Colors.black)),
                          // ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

