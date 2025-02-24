import 'package:SSCVote/forum/list_forum.dart';
import 'package:flutter/material.dart';
import 'package:SSCVote/election_survey_pages/election_survey_candidates.dart';
import 'package:SSCVote/main.dart';
import 'package:SSCVote/results_pages/results.dart';
import 'package:SSCVote/voter_pages/announcement.dart';
import 'package:SSCVote/voter_pages/evaluation.dart';
import 'package:SSCVote/voter_pages/profile.dart';
import 'package:SSCVote/voter_pages/vote.dart';
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

  void _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Optionally call your server to end the session
    // await http.post(Uri.parse('http://192.168.1.6/SSCVote/logout.php'));
    // await http.post(Uri.parse('https://studentcouncil.bcp-sms1.com/php/logout.php'));

    if (!context.mounted) return; // Ensure the widget is still mounted

    // Use pushAndRemoveUntil to clear the navigation stack
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoadingScreen()), // Replace with your login page
      (Route<dynamic> route) => false, // Remove all previous routes
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white, // Hex color #1E3A8A,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.white, // Hex color #1E3A8A
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Image.asset('assets/bcp_logo.png', width: 90),
                const SizedBox(height: 10),
                Text(studentNo ?? 'Student No', style: const TextStyle(color: Colors.black, fontSize: 18)),
              ],
            ),
          ),
          const SizedBox(height: 10,),
          ListTile(
            leading: const Icon(Icons.announcement, color: Colors.black,),
            title: const Text('Announcement', style: TextStyle(color: Colors.black)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => AnnouncementPage()));
            },
          ),
          // const SizedBox(height: 10,),
          // ListTile(
          //   leading: const Icon(Icons.person, color: Colors.black,),
          //   title: const Text('Profile', style: TextStyle(color: Colors.black)),
          //   onTap: () {
          //     Navigator.pop(context);
          //     Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileInfo()));
          //   },
          // ),
          const SizedBox(height: 10,),
          ListTile(
            leading: const Icon(Icons.how_to_vote, color: Colors.black,),
            title: const Text('Votes', style: TextStyle(color: Colors.black)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => VotePage()));
            },
          ),
          const SizedBox(height: 10,),
          ListTile(
            leading: const Icon(Icons.people, color: Colors.black,),
            title: const Text('Election Results', style: TextStyle(color: Colors.black)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => ResultsPage()));
            },
          ),
          const SizedBox(height: 10,),
          ListTile(
            leading: const Icon(Icons.question_answer, color: Colors.black,),
            title: const Text('Evaluation', style: TextStyle(color: Colors.black)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => EvaluationPage()));
            },
          ),
          const SizedBox(height: 10,),
          ListTile(
            leading: const Icon(Icons.announcement, color: Colors.black,),
            title: const Text('Election Survey', style: TextStyle(color: Colors.black)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => ElectionSurveyCandidates()));
            },
          ),
          const SizedBox(height: 10,),
          ListTile(
            leading: const Icon(Icons.format_quote, color: Colors.black,),
            title: const Text('Forums', style: TextStyle(color: Colors.black)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context, 
                MaterialPageRoute(
                  builder: (context) => ForumsListScreen(
                    studentNo: studentNo ?? '', // Pass the student number
                  )
                )
              );
            },
          ),
          // const SizedBox(height: 10,),
          // ListTile(
          //   leading: const Icon(Icons.logout, color: Colors.black,),
          //   title: const Text('Logout', style: TextStyle(color: Colors.black)),
          //   onTap: () {
          //     _logout(context);
          //   },
          // ),
        ],
      ),
    );
  }
}
