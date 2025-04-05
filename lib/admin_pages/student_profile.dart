import 'package:flutter/material.dart';

class StudentProfilePage extends StatelessWidget {
  final Map<String, dynamic> studentData;

  const StudentProfilePage({Key? key, required this.studentData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Voter Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Container(
            width: 400,
            height:550,
            child: Card(
              elevation: 2,
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Student No:', style: TextStyle(fontSize: 16)),
                  Text(studentData['studentno'], style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Text('Last Name:', style: TextStyle(fontSize: 16)),
                  Text(studentData['lastname'], style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Text('First Name:', style: TextStyle(fontSize: 16)),
                  Text(studentData['firstname'], style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Text('Middle Name:', style: TextStyle(fontSize: 16)),
                  Text(studentData['middlename'], style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Text('Course:', style: TextStyle(fontSize: 16)),
                  Text(studentData['course'], style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Text('Section:', style: TextStyle(fontSize: 16)),
                  Text(studentData['section'], style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Text('Status:', style: TextStyle(fontSize: 16)),
                  Text('${studentData['status']}', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: studentData['status'] == 'Voted' ? Colors.green : Colors.red)),
                  // Add more fields as necessary
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
