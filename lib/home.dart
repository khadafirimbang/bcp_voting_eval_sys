import 'package:flutter/material.dart';
import 'package:for_testing/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomePage extends StatelessWidget {
  Future<void> _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('studentno');

    // Optionally call your server to end the session
    await http.post(Uri.parse('http://192.168.1.11/for_testing/logout.php'));

    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Home Page'),
      //   actions: <Widget>[
      //     IconButton(
      //       icon: const Icon(Icons.logout),
      //       onPressed: () => _logout(context),
      //     ),
      //   ],
      // ),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Home Page!"),
                       IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
          ],
        ),
      ),
    );
  }
}
