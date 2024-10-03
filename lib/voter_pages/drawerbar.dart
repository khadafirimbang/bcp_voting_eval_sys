import 'package:flutter/material.dart';
import 'package:for_testing/elect_pos/for_audi.dart';
import 'package:for_testing/elect_pos/for_pres.dart';
import 'package:for_testing/elect_pos/for_sec.dart';
import 'package:for_testing/elect_pos/for_treasurer.dart';
import 'package:for_testing/elect_pos/for_vicepres.dart';
import 'package:for_testing/main.dart';
import 'package:for_testing/results_pages/result_auditor.dart';
import 'package:for_testing/results_pages/result_pres.dart';
import 'package:for_testing/results_pages/result_sec.dart';
import 'package:for_testing/results_pages/result_treasurer.dart';
import 'package:for_testing/results_pages/result_vicepres.dart';
import 'package:for_testing/voter_pages/announcement.dart';
import 'package:for_testing/voter_pages/evaluation.dart';
import 'package:for_testing/voter_pages/profile.dart';
import 'package:for_testing/signin.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
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
    // await http.post(Uri.parse('https://studentcouncil.bcp-sms1.com/php/logout.php'));

    // Use pushAndRemoveUntil to clear the navigation stack
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoadingScreen()),
      (route) => false, // Remove all other routes
    );
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
          SizedBox(height: 10,),
          ListTile(
            leading: const Icon(Icons.announcement, color: Colors.white,),
            title: const Text('Announcement', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => AnnouncementPage()));
            },
          ),
          SizedBox(height: 10,),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.white,),
            title: const Text('Profile', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileInfo()));
            },
          ),
          SizedBox(height: 10,),
          ExpansionTile(
            collapsedIconColor: Colors.white,
            leading: const Icon(Icons.contact_emergency_sharp, color: Colors.white,),
            title: const Text('Vote', style: TextStyle(color: Colors.white)),
            childrenPadding: const EdgeInsets.only(left: 37),
            children: [
              ListTile(
                title: const Text('President', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ForPres()));
                },
              ),
              ListTile(
                title: const Text('Vice President', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ForVicePres()));
                },
              ),
              ListTile(
                title: const Text('Secretary', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ForSecretary()));
                },
              ),
              ListTile(
                title: const Text('Treasurer', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ForTreasurer()));
                },
              ),
              ListTile(
                title: const Text('Auditor', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ForAuditor()));
                },
              ),
            ],
          ),
          SizedBox(height: 10,),
          ExpansionTile(
            collapsedIconColor: Colors.white,
            leading: const Icon(Icons.file_copy, color: Colors.white,),
            title: const Text('Results', style: TextStyle(color: Colors.white)),
            childrenPadding: const EdgeInsets.only(left: 37),
            children: [
              ListTile(
                title: const Text('President', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ResultPres()));
                },
              ),
              ListTile(
                title: const Text('Vice President', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ResultVicePres()));
                },
              ),
              ListTile(
                title: const Text('Secretary', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ResultSecretary()));
                },
              ),
              ListTile(
                title: const Text('Treasurer', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ResultTreasurer()));
                },
              ),
              ListTile(
                title: const Text('Auditor', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ResultAuditor()));
                },
              ),
            ],
          ),
          SizedBox(height: 10,),
          ListTile(
            leading: const Icon(Icons.question_answer, color: Colors.white,),
            title: const Text('Evaluation', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const EvaluationPage()));
            },
          ),
          SizedBox(height: 10,),
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
