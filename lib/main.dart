import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:for_testing/profile.dart';
import 'package:for_testing/signup.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'BCP',
      home: LoadingScreen(),
    );
  }
}

// Loading Page
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  bool isConnectedToInternet = false;
  StreamSubscription? _internetConnectionStreamSubcription;

  @override
  void initState() {
    super.initState();

        _internetConnectionStreamSubcription = InternetConnection().onStatusChange.listen((event){
      switch (event) {
        case InternetStatus.connected:
          setState(() {
            isConnectedToInternet = true;
          });
          break;
        case InternetStatus.disconnected:
            setState(() {
              isConnectedToInternet = false;
          });
          break;
        default:
          setState(() {
            isConnectedToInternet = false;
          });
          break;
      }
    },);

    // Simulate a loading process and then navigate to the Login page
    Future.delayed(const Duration(seconds: 3), () {
      // Checking if there's an Internet Connection
      if(isConnectedToInternet == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please check your internet connection'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3)),
        );
    }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()), // Redirect to Login page
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            children: [
              const SizedBox(height: 80),
              Image.asset('assets/bcp_logo.png', width: 100,),
              const SizedBox(height: 200),
              const CircularProgressIndicator(),
            ],
          ),
        ],
      ),
    );
  }
}

// Login Page
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _studentNoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;
  bool isConnectedToInternet = false;

  StreamSubscription? _internetConnectionStreamSubcription;

    void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  void initState() {
    super.initState();
    _checkSession();
    _internetConnectionStreamSubcription = InternetConnection().onStatusChange.listen((event){
      switch (event) {
        case InternetStatus.connected:
          setState(() {
            isConnectedToInternet = true;
          });
          break;
        case InternetStatus.disconnected:
            setState(() {
              isConnectedToInternet = false;
          });
          break;
        default:
          setState(() {
            isConnectedToInternet = false;
          });
          break;
      }
    },);
  }

  @override
  void dispose() {
    _internetConnectionStreamSubcription?.cancel();
    super.dispose();
  }

  void _checkSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? studentNo = prefs.getString('studentno');

    if (studentNo != null) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => HomePage()));
    }
  }

Future<void> _login() async {
  if (_formKey.currentState!.validate()) {
    final response = await http.post(
      Uri.parse('http://192.168.1.2/for_testing/signin.php'),
      body: {
        'studentno': _studentNoController.text,
        'password': _passwordController.text, // Sending plain text password to be verified
      },
    );

    final data = jsonDecode(response.body);

    if (data['status'] == 'success') {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('studentno', _studentNoController.text);

      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => HomePage())
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text('Login')),
      body: SingleChildScrollView(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                //Logo
                const SizedBox(height: 80),
                Image.asset(
                  'assets/bcp_logo.png',
                  width: 100,
                  ),
                const SizedBox(height: 80),
                Form(
                  key: _formKey,
                  child: Column(
                    children: <Widget>[
                      const Text('Login your Account',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w600,
                      ),
                      ),
                      const SizedBox(height: 20,),
                      SizedBox(
                        width: 340,
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          controller: _studentNoController,
                          decoration: const InputDecoration(
                            labelText: 'Student Number',
                            prefixIcon: Icon(Icons.person),
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your student number';
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
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureText ? Icons.visibility : Icons.visibility_off,
                              ),
                              onPressed: _togglePasswordVisibility,
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          obscureText: _obscureText,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: 340,
                        child: TextButton(
                              style: TextButton.styleFrom(
                                shape: const RoundedRectangleBorder(),
                                padding: const EdgeInsets.all(14.0),
                                backgroundColor: const Color(0xFF1E3A8A),
                                
                              ),
                              onPressed: () {_login();},
                              child: const Text('Sign in', 
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                ),),
                            ),
                      ),
                      const SizedBox(height: 20),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => SignUpPage()),
                            );
                          },
                          child: const Text('Click here to Sign up',
                          style: TextStyle(
                            color: Color(0xFF1E3A8A)
                          ),),
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

