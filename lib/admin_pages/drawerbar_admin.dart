import 'package:flutter/material.dart';
import 'package:for_testing/admin_pages/accounts.dart';
import 'package:for_testing/admin_pages/announcement_admin.dart';
import 'package:for_testing/admin_pages/candidates.dart';
import 'package:for_testing/admin_pages/dashboard.dart';
import 'package:for_testing/admin_pages/election_sched.dart';
import 'package:for_testing/admin_pages/evaluation_admin.dart';
import 'package:for_testing/admin_pages/pending_voters.dart';
import 'package:for_testing/admin_pages/positions.dart';
import 'package:for_testing/admin_pages/responses.dart';
import 'package:for_testing/admin_pages/resultAdmin.dart';
import 'package:for_testing/admin_pages/voters.dart';
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
    await http.post(Uri.parse('https://studentcouncil.bcp-sms1.com/php/logout.php'));

    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => const LoginPage()));
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
          const SizedBox(height: 10,),
          ListTile(
            leading: const Icon(Icons.dashboard, color: Colors.white,),
            title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const DashboardPage()));
            },
          ),
          const SizedBox(height: 10,),
          ListTile(
            leading: const Icon(Icons.people, color: Colors.white,),
            title: const Text('Candidates', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CandidatesPage()));
            },
          ),        
          const SizedBox(height: 10,),
          ExpansionTile(
            collapsedIconColor: Colors.white,
            leading: const Icon(Icons.contact_emergency_sharp, color: Colors.white,),
            title: const Text('Voters', style: TextStyle(color: Colors.white)),
            childrenPadding: const EdgeInsets.only(left: 37),
            children: [
              ListTile(
              leading: const Icon(Icons.people, color: Colors.white,),
              title: const Text('Verified Voters', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const VotersPage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_outline, color: Colors.white,),
              title: const Text('Unverified Voters', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PendingVotersPage()));
              },
            ),
            ],
          ),
          
          const SizedBox(height: 10,),
          ListTile(
            leading: const Icon(Icons.date_range, color: Colors.white,),
            title: const Text('Election Schedules', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ElectionScheduler()));
            },
          ),
          const SizedBox(height: 10,),
          ListTile(
            leading: const Icon(Icons.file_copy, color: Colors.white,),
            title: const Text('Result', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ResultAdminPage()));
            },
          ),
          const SizedBox(height: 10,),
          ListTile(
            leading: const Icon(Icons.announcement, color: Colors.white,),
            title: const Text('Announcement', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AnnouncementAdminPage()));
            },
          ),
          const SizedBox(height: 10,),
          ExpansionTile(
            collapsedIconColor: Colors.white,
            leading: const Icon(Icons.question_answer_outlined, color: Colors.white,),
            title: const Text('Evaluation', style: TextStyle(color: Colors.white)),
            childrenPadding: const EdgeInsets.only(left: 37),
            children: [
              ListTile(
              leading: const Icon(Icons.question_answer_outlined, color: Colors.white,),
              title: const Text('Evaluation List', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const EvaluationPage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.question_answer, color: Colors.white,),
              title: const Text('Evaluation Responses', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ResponsesPage()));
              },
            ),
            ],
          ),
          const SizedBox(height: 10,),
          ListTile(
            leading: const Icon(Icons.announcement, color: Colors.white,),
            title: const Text('Accounts', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => AccountsPage()));
            },
          ),
          const SizedBox(height: 10,),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white,),
            title: const Text('Logout', style: TextStyle(color: Colors.white)),
            onTap: () {
              _logout(context);
            },
          ),
        ],
      ),
    );
  }
}
