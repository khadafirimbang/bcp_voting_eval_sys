import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:for_testing/admin_pages/dashboard.dart';
import 'package:for_testing/profile.dart';
import 'package:for_testing/signin.dart';
import 'package:for_testing/signup.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

void main() => runApp(const LoadingScreen());

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'BCP',
      home: LoadingScreenWidget(),
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

  @override
  void initState() {
    super.initState();
    _checkSession();

    _internetConnectionStreamSubscription = InternetConnection().onStatusChange.listen((event) {
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
    });

    _checkInternetConnectionAndNavigate();
  }

  @override
  void dispose() {
    _internetConnectionStreamSubscription?.cancel();
    super.dispose();
  }

  void _checkSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? studentNo = prefs.getString('studentno');
    String? role = prefs.getString('role');

    if (studentNo != null) {
      if (role == 'student') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()));
      } else if (role == 'admin') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardPage()));
      }
    }
  }

  Future<void> _checkInternetConnectionAndNavigate() async {
    // Wait for the initial status of internet connection
    await Future.delayed(const Duration(seconds: 1));

    if (!isConnectedToInternet) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please check your internet connection'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }

    // Navigate to the LoginPage after a short delay to allow the snackbar to show
    await Future.delayed(const Duration(seconds: 1));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()), // Redirect to Login page
    );
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
              Image.asset('assets/bcp_logo.png', width: 100),
              const SizedBox(height: 200),
              const CircularProgressIndicator(),
            ],
          ),
        ],
      ),
    );
  }
}
