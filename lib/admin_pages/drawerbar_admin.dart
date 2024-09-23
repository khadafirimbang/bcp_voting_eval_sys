import 'package:flutter/material.dart';
import 'package:for_testing/admin_pages/candidates.dart';
import 'package:for_testing/admin_pages/dashboard.dart';
import 'package:for_testing/admin_pages/election_sched.dart';
import 'package:for_testing/admin_pages/evaluation_admin.dart';
import 'package:for_testing/elect_pos/for_audi.dart';
import 'package:for_testing/elect_pos/for_pres.dart';
import 'package:for_testing/elect_pos/for_sec.dart';
import 'package:for_testing/elect_pos/for_treasurer.dart';
import 'package:for_testing/elect_pos/for_vicepres.dart';
import 'package:for_testing/voter_pages/profile.dart';
import 'package:for_testing/main.dart';
import 'package:for_testing/signin.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class AppDrawerAdmin extends StatefulWidget {
  const AppDrawerAdmin({super.key});

  @override
  State<AppDrawerAdmin> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawerAdmin> {
  String? studentNo = "Name here"; // Default value

  @override
  void initState() {
    super.initState();
    _loadStudentNo(); // Load the user's name when the drawer is initialized
  }


  Future<void> _loadStudentNo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      studentNo = prefs.getString('studentno') ?? 'Student No'; // Fetch student no
    });
  }

  Future<void> _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('studentno');

    // Optionally call your server to end the session
    await http.post(Uri.parse('http://192.168.1.6/for_testing/logout.php'));

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
    return Drawer(
      backgroundColor: const Color(0xFF1E3A8A), // Hex color #1E3A8A,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF1E3A8A), // Hex color #1E3A8A
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const Icon(Icons.account_circle, size: 90, color: Colors.white),
                const SizedBox(height: 10),
                Text(studentNo ?? 'Student No', style: const TextStyle(color: Colors.white, fontSize: 18)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.white,),
            title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const DashboardPage()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.question_answer, color: Colors.white,),
            title: const Text('Candidates', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CandidatesPage()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.question_answer, color: Colors.white,),
            title: const Text('Evaluation', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const EvaluationPage()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.date_range, color: Colors.white,),
            title: const Text('Election Schedules', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => ElectionScheduler()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white,),
            title: const Text('Logout', style: TextStyle(color: Colors.white)),
            onTap: () {
              _showLogoutDialog(context);
            },
          ),
        ],
      ),
    );
  }
}
