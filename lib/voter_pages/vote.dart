import 'package:flutter/material.dart';
import 'dart:io';

import 'package:for_testing/voter_pages/drawerbar.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: VotePage(),
    );
  }
}

class VotePage extends StatelessWidget {
  const VotePage({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Exit the app when back button is pressed
        exit(0);
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          title: const Text('Vote Page', style: TextStyle(color: Colors.white),),
          iconTheme: const IconThemeData(
            color: Colors.white, // Change the color of the Drawer icon here
          ),
        ),
        drawer: const AppDrawer(),
        body: const Center(
          child: Text('Vote Page.'),
        ),
      ),
    );
  }
}
