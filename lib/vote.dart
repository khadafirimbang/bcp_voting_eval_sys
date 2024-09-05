import 'package:flutter/material.dart';
import 'dart:io';

import 'package:for_testing/drawerbar.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: VotePage(),
    );
  }
}

class VotePage extends StatelessWidget {
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
          title: Text('Vote Page', style: TextStyle(color: Colors.white),),
          iconTheme: IconThemeData(
            color: Colors.white, // Change the color of the Drawer icon here
          ),
        ),
        drawer: AppDrawer(),
        body: Center(
          child: Text('Vote Page.'),
        ),
      ),
    );
  }
}
