import 'package:SSCVote/admin_pages/profile_admin.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:SSCVote/admin_pages/change_pass.dart';
import 'package:SSCVote/main.dart'; // Import your main.dart or loading screen

class ProfileMenu extends StatefulWidget {
  @override
  _ProfileMenuState createState() => _ProfileMenuState();
}

class _ProfileMenuState extends State<ProfileMenu> {
  String? studentNo = "Unknown"; // Default value
  String? userRole = "Unknown"; // Default value

  @override
  void initState() {
    super.initState();
    _loadStudentNo();
    _loadUserRole();
  }

  Future<void> _loadStudentNo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      studentNo = prefs.getString('studentno') ?? 'Unknown'; // Fetch student no
    });
  }

  Future<void> _loadUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userRole = prefs.getString('role'); // Assuming 'role' is the key used
    });
  }

  @override
  Widget build(BuildContext context) {
    return buildProfileMenu(context, studentNo);
  }

  Widget buildProfileMenu(BuildContext context, String? studentNo) {
    return PopupMenuButton<int>(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onSelected: (item) {
        switch (item) {
          case 0:
            // Navigate to Profile page
            Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileInfoAdminPage()));
            break;
          case 1:
            // Handle change pass
            if (userRole == 'Super&69*Admin-+') {
              Navigator.push(context, MaterialPageRoute(builder: (context) => ChangePasswordPage()));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('You do not have permission to change the password.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            break; // Add break here to avoid fall-through
          case 2:
            // Handle sign out
            _logout(context); // Example action for Sign Out
            break;
        }
      },
      offset: Offset(0, 50), // Adjust dropdown position
      itemBuilder: (context) {
        List<PopupMenuEntry<int>> menuItems = [
          PopupMenuItem<int>(
            padding: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
            value: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Signed in as', style: TextStyle(color: Colors.black54)),
                Text(studentNo ?? 'Unknown'),
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
        ];

        // Conditionally add the Change Password option
        if (userRole == 'Super&69*Admin-+') {
          menuItems.add(
            PopupMenuItem<int>(
              value: 1,
              child: Row(
                children: [
                  Icon(Icons.lock, color: Colors.black54),
                  SizedBox(width: 10),
                  Text('Change password'),
                ],
              ),
            ),
          );
        }

        menuItems.add(
          PopupMenuItem<int>(
            value: 2,
            child: Row(
              children: [
                Icon(Icons.logout, color: Colors.black54),
                SizedBox(width: 10),
                Text('Sign out'),
              ],
            ),
          ),
        );

        return menuItems;
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!context.mounted) return; // Ensure the widget is still mounted

    // Use pushAndRemoveUntil to clear the navigation stack
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoadingScreen()), // Replace with your login page
      (Route<dynamic> route) => false, // Remove all previous routes
    );
  }
}
