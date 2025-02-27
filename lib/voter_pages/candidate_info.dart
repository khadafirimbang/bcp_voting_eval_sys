import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class CandidateDetailPage extends StatelessWidget {
  final Map<String, dynamic> candidate;

  CandidateDetailPage({required this.candidate});

  @override
  Widget build(BuildContext context) {

    double cardWidth = MediaQuery.of(context).size.width > 800 ? 500 : 350;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[200],
        appBar: AppBar(
          title: Text('Candidate Information'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: SingleChildScrollView(
              child: Container(
                width: cardWidth,
                child: Card(
                  elevation: 10,
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 30),
                    child: Column(
                      children: [
                        CircleAvatar(
                          backgroundImage: candidate['img'] != null && candidate['img'].isNotEmpty
                            ? MemoryImage(
                                (() {
                                  try {
                                    // Print raw data for debugging
                                    // print('Raw image data: ${candidate['img'].substring(0, 50)}...'); // Show first 50 chars
                                    
                                    // Clean and decode the base64 string
                                    String cleanBase64 = candidate['img']
                                        .replaceAll(RegExp(r'data:image/[^;]+;base64,'), '')
                                        .replaceAll('\n', '')
                                        .replaceAll('\r', '')
                                        .replaceAll(' ', '+');
                                        
                                    // print('Cleaned base64: ${cleanBase64.substring(0, 50)}...'); // Show first 50 chars
                                    
                                    return base64Decode(cleanBase64);
                                  } catch (e) {
                                    print('Error decoding image: $e');
                                    return Uint8List(0); // Return empty image data
                                  }
                                })()
                              )
                            : const AssetImage('assets/bcp_logo.png') as ImageProvider,
                          radius: 100,
                        ),
                        SizedBox(height: 20),
                        Text(
                          '${candidate['lastname']}, ${candidate['firstname']} ${candidate['middlename']}',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'Section:',
                          style: TextStyle(fontSize: 14)
                        ),
                        Text(
                          '${candidate['section']}',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Course:',
                          style: TextStyle(fontSize: 14)
                        ),
                        Text(
                          '${candidate['course']}',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Running for:',
                          style: TextStyle(fontSize: 14)
                        ),
                        Text(
                          '${candidate['position']}',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Partylist:',
                          style: TextStyle(fontSize: 14)
                        ),
                        Text(
                          '${candidate['partylist']}',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Slogan:',
                          style: TextStyle(fontSize: 14),
                        ),
                        Text(
                          '${candidate['slogan']}',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
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
      ),
    );
  }
}
