import 'package:SSCVote/admin_pages/accounts.dart';
import 'package:SSCVote/sentiment_analysis/sentiment_analysis_result.dart';
import 'package:SSCVote/voter_pages/profile.dart';
import 'package:flutter/material.dart';
import 'package:SSCVote/admin_pages/announcement_admin.dart';
import 'package:SSCVote/admin_pages/candidates.dart';
import 'package:SSCVote/admin_pages/chatbot_admin.dart';
import 'package:SSCVote/admin_pages/dashboard2.dart';
import 'package:SSCVote/admin_pages/election_sched.dart';
import 'package:SSCVote/admin_pages/evaluation_admin.dart';
import 'package:SSCVote/admin_pages/feedback_results.dart';
import 'package:SSCVote/admin_pages/prediction.dart';
import 'package:SSCVote/admin_pages/survey_results.dart';
import 'package:SSCVote/admin_pages/resultAdmin.dart';
import 'package:SSCVote/admin_pages/voters.dart';
import 'package:SSCVote/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
class AppDrawerAdmin extends StatefulWidget {
  const AppDrawerAdmin({super.key});

  @override
  State<AppDrawerAdmin> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawerAdmin> {
  String? studentNo = "Unknown"; // Default value
  String? userRole;

  @override
  void initState() {
    super.initState();
    _loadStudentNo(); // Load the user's name when the drawer is initialized
    _loadUserRole();
  }


  Future<void> _loadStudentNo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      studentNo = prefs.getString('studentno') ?? 'Student No'; // Fetch student no
    });
  }

  Future<void> _loadUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userRole = prefs.getString('role'); // Assuming 'role' is the key used
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

  Widget _buildProfileMenu(BuildContext context) {
    return PopupMenuButton<int>(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onSelected: (item) {
        switch (item) {
          case 0:
            // Navigate to Profile page
            Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileInfoPage()));
            break;
          case 1:
            // Handle sign out
            _logout(context); // Example action for Sign Out
            break;
        }
      },
      offset: Offset(0, 50), // Adjust dropdown position
      itemBuilder: (context) => [
        PopupMenuItem<int>(
          value: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Signed in as', style: TextStyle(color: Colors.black54)),
              Text('Student num here', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem<int>(
          value: 0,
          child: Row(
            children: [
              Icon(Icons.person, color: Colors.black54),
              SizedBox(width: 10),
              Text('Profile'),
            ],
          ),
        ),
        PopupMenuItem<int>(
          value: 1,
          child: Row(
            children: [
              Icon(Icons.logout, color: Colors.black54),
              SizedBox(width: 10),
              Text('Sign out'),
            ],
          ),
        ),
      ],
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: Colors.black54),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
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
            leading: const Icon(Icons.dashboard, color: Colors.black,),
            title: const Text('Dashboard', style: TextStyle(color: Colors.black)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => DashboardPage2()));
            },
          ),
          const SizedBox(height: 10,),
          ListTile(
            leading: const Icon(Icons.people, color: Colors.black,),
            title: const Text('Candidates', style: TextStyle(color: Colors.black)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CandidatesPage()));
            },
          ),        
          const SizedBox(height: 10,),
          ListTile(
            leading: const Icon(Icons.people, color: Colors.black,),
            title: const Text('Voters', style: TextStyle(color: Colors.black)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const VotersPage()));
            },
          ),        
          const SizedBox(height: 10,),
          ListTile(
            leading: const Icon(Icons.chat, color: Colors.black,),
            title: const Text("FAQs Management", style: TextStyle(color: Colors.black)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => ChatbotAdminPage()));
            },
          ),        
          const SizedBox(height: 10,),
          ListTile(
            leading: const Icon(Icons.date_range, color: Colors.black,),
            title: const Text('Election Schedule', style: TextStyle(color: Colors.black)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ElectionScheduler()));
            },
          ),
          const SizedBox(height: 10,),
          ListTile(
            leading: const Icon(Icons.file_copy, color: Colors.black,),
            title: const Text('Election Results', style: TextStyle(color: Colors.black)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => ResultAdminPage()));
            },
          ),
          const SizedBox(height: 10,),
          ListTile(
            leading: const Icon(Icons.announcement, color: Colors.black,),
            title: const Text('Announcement', style: TextStyle(color: Colors.black)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AnnouncementAdminPage()));
            },
          ),
          const SizedBox(height: 10,),
          ExpansionTile(
            collapsedIconColor: Colors.black,
            leading: const Icon(Icons.question_answer_outlined, color: Colors.black,),
            title: const Text('Evaluation', style: TextStyle(color: Colors.black)),
            childrenPadding: const EdgeInsets.only(left: 37),
            children: [
              ListTile(
              leading: const Icon(Icons.question_answer_outlined, color: Colors.black,),
              title: const Text('Evaluation List', style: TextStyle(color: Colors.black)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const EvaluationPage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.question_answer, color: Colors.black,),
              title: const Text('Survey Results', style: TextStyle(color: Colors.black)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => SurveyResultsPage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.question_answer, color: Colors.black,),
              title: const Text('Feedback Results', style: TextStyle(color: Colors.black)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => QuestionsListPage()));
              },
            ),
            // ListTile(
            //   leading: const Icon(Icons.question_answer, color: Colors.black,),
            //   title: const Text('Feedback Sentiment Analysis', style: TextStyle(color: Colors.black)),
            //   onTap: () {
            //     Navigator.pop(context);
            //     Navigator.push(context, MaterialPageRoute(builder: (context) => SentimentAnalysisResultsPage()));
            //   },
            // ),
            ],
          ),
          const SizedBox(height: 10,),
          ListTile(
            leading: const Icon(Icons.online_prediction_outlined, color: Colors.black,),
            title: const Text('Election Prediction', style: TextStyle(color: Colors.black)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => ElectionPredictionPage()));
            },
          ),
          // Conditionally display AccountsPage based on user role
          if (userRole == 'SuperAdmin') ...[
            const SizedBox(height: 10,),
            ListTile(
              leading: const Icon(Icons.account_circle, color: Colors.black,),
              title: const Text('Admins', style: TextStyle(color: Colors.black)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => AccountsPage()));
              },
            ),
          ],
        ],
      ),
    );
  }
}


