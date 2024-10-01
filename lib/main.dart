import 'dart:async';
import 'package:flutter/material.dart';
import 'package:for_testing/admin_pages/dashboard.dart';
import 'package:for_testing/voter_pages/profile.dart';
import 'package:for_testing/signin.dart';
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
    String? role = prefs.getString('role');

    if (studentNo != null && mounted) {
      _navigateToRoleBasedPage(role);
    }
  }

  void _navigateToRoleBasedPage(String? role) {
    if (role == 'student') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()));
    } else if (role == 'admin') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DashboardPage()));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    );
  }
}
