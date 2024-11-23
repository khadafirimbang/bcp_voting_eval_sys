import 'package:flutter/material.dart';

class CandidateDetailPage extends StatelessWidget {
  final Map<String, dynamic> candidate;

  CandidateDetailPage({required this.candidate});

  @override
  Widget build(BuildContext context) {

    double cardWidth = MediaQuery.of(context).size.width > 800 ? 500 : 350;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        title: const Text('Candidate Information', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: SingleChildScrollView(
            child: Container(
              width: cardWidth,
              child: Card(
                elevation: 10,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 30),
                  child: Column(
                    children: [
                      ClipOval(
                        child: Image.network(
                          candidate['image_url'],
                          width: 180,
                          height: 180,
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        '${candidate['lastname']}, ${candidate['firstname']} ${candidate['middlename']}',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Section:',
                        style: TextStyle(fontSize: 14)
                      ),
                      Text(
                        '${candidate['section']}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Course:',
                        style: TextStyle(fontSize: 14)
                      ),
                      Text(
                        '${candidate['course']}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Running for:',
                        style: TextStyle(fontSize: 14)
                      ),
                      Text(
                        '${candidate['position']}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Partylist:',
                        style: TextStyle(fontSize: 14)
                      ),
                      Text(
                        '${candidate['partylist']}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Slogan:',
                        style: TextStyle(fontSize: 14)
                      ),
                      Text(
                        '${candidate['slogan']}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Go back to previous screen
                        },
                        child: Text('Back'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
