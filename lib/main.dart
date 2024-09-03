import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:for_testing/home.dart';
import 'package:for_testing/signup.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Demo',
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _studentNoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;

    void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  void initState() {
    super.initState();
    _checkSession();
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
        Uri.parse('http://192.168.1.11/for_testing/signin.php'),
        body: {
          'studentno': _studentNoController.text,
          'password': _passwordController.text,
        },
      );

      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('studentno', _studentNoController.text);
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => HomePage()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid Credentials')),
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
                      // ElevatedButton(
                      //   onPressed: _login,
                      //   child: const Text('Login'),
                      // ),
                      SizedBox(
                        width: 340,
                        child: TextButton(
                              style: TextButton.styleFrom(
                                shape: const RoundedRectangleBorder(),
                                padding: const EdgeInsets.all(14.0),
                                backgroundColor: Colors.blue,
                                
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
                            color: Colors.blue
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

// class HomePage extends StatelessWidget {
//   Future<void> _logout(BuildContext context) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.remove('studentno');

//     // Optionally call your server to end the session
//     await http.post(Uri.parse('http://192.168.1.11/for_testing/logout.php'));

//     Navigator.pushReplacement(
//         context, MaterialPageRoute(builder: (context) => LoginPage()));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Home Page'),
//         actions: <Widget>[
//           IconButton(
//             icon: const Icon(Icons.logout),
//             onPressed: () => _logout(context),
//           ),
//         ],
//       ),
//       body: const Center(child: const Text('Welcome!')),
//     );
//   }
// }
