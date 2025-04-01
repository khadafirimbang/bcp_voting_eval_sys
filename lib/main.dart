import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:SSCVote/admin_pages/dashboard2.dart';
import 'package:SSCVote/voter_pages/announcement.dart';
import 'package:SSCVote/signin.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const LoadingScreen());

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      color: Colors.red,
      title: 'SSCVote',
      home: LoadingScreenWidget(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Loading Page
class LoadingScreenWidget extends StatefulWidget {
  const LoadingScreenWidget({super.key});

  @override
  _LoadingScreenWidgetState createState() => _LoadingScreenWidgetState();
}

class _LoadingScreenWidgetState extends State<LoadingScreenWidget> {
  bool isConnectedToInternet = false;
  StreamSubscription? _internetConnectionStreamSubscription;
  static const Duration delayDuration = Duration(seconds: 1);

  @override
  void initState() {
    super.initState();
    _checkSession();

    _internetConnectionStreamSubscription = InternetConnection().onStatusChange.listen((event) {
      _handleInternetStatus(event);
    });

    _checkInternetConnectionAndNavigate();
    fetchAndSaveData();
  }

  @override
  void dispose() {
    _internetConnectionStreamSubscription?.cancel();
    super.dispose();
  }

  void _handleInternetStatus(InternetStatus status) {
    setState(() {
      isConnectedToInternet = status == InternetStatus.connected;
    });

    if (!isConnectedToInternet && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please check your internet connection'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _checkSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? studentNo = prefs.getString('studentno');

    if (studentNo != null && mounted) {
      String? role = await _fetchUserRole(studentNo);
      _navigateToRoleBasedPage(role);
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

  void _navigateToRoleBasedPage(String? role) {
    if (role == 'Voter') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AnnouncementPage()));
    } else if (role == 'Admin&69*-+' || role == 'Super&69*Admin-+') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DashboardPage2()));
    } else {
      // Redirect to LoginPage if role is not recognized
      _navigateToLoginPage();
    }
  }

  Future<void> _checkInternetConnectionAndNavigate() async {
    await Future.delayed(delayDuration);

    if (mounted) {
      if (!isConnectedToInternet) {
        // SnackBar will be shown in _handleInternetStatus
      }
    }

    await Future.delayed(delayDuration); // Delay before navigating to LoginPage
    _navigateToLoginPage();
  }

  void _navigateToLoginPage() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()), // Redirect to Login page
      );
    }
  }

  Future<void> fetchAndSaveData() async {
    final response = await http.get(Uri.parse('https://registrar.bcp-sms1.com/api/students.php'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final saveResponse = await http.post(
        Uri.parse('https://studentcouncil.bcp-sms1.com/php/registrar_students_info.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      // print('Data sent: ${jsonEncode(data)}');

      if (saveResponse.statusCode == 200) {
        print('Data saved successfully');
        // print('Save response: ${saveResponse.body}');
      } else {
        print('Failed to save data');
      }
    } else {
      print('Failed to fetch data');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // const SizedBox(height: 80),
              Image.asset('assets/bcp_logo.png', width: 100),
              const SizedBox(height: 50),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
