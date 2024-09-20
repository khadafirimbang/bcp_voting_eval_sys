import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:for_testing/voter_pages/drawerbar.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // For getting logged-in student's number

class ForSecretary extends StatefulWidget {
  const ForSecretary({super.key});

  @override
  State<ForSecretary> createState() => _ForSecretaryState();
}

class _ForSecretaryState extends State<ForSecretary> {
  List candidates = [];
  String? studentnoLoggedIn;

  @override
  void initState() {
    super.initState();
    _getLoggedInStudentNo();
    _fetchCandidates();
  }

  Future<void> _getLoggedInStudentNo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      studentnoLoggedIn = prefs.getString('studentno');
    });
  }

  Future<void> _fetchCandidates() async {
    var url = Uri.parse('http://192.168.1.6/for_testing/fetch_all_candidates.php');
    var response = await http.get(url);

    if (response.statusCode == 200) {
      setState(() {
        // Filter candidates where position is "President"
        candidates = (json.decode(response.body) as List)
            .where((candidate) => candidate['position'] == 'Secretary')
            .toList();
      });
    } else {
      print('Failed to fetch candidates');
    }
  }

  Future<void> _voteForCandidate(String studentno, String position) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? loggedInStudentno = prefs.getString('studentno');

    var url = Uri.parse('http://192.168.1.6/for_testing/vote_candidate.php');
    var response = await http.post(url, body: {
      'studentno': studentno,
      'loggedInStudentno': loggedInStudentno ?? '',
      'position': position,
    });

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      var result = json.decode(response.body);
      String message;
      Color color;

      if (result['status'] == 'success') {
        message = 'Vote successful';
        color = Colors.green;
        _fetchCandidates(); // Refresh candidate list after voting
      } else {
        message = result['message'];
        color = Colors.red;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      print('Failed to vote');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to vote'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showConfirmationDialog(String studentno, String position) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Vote'),
          content: const Text('Are you sure you want to vote for this candidate?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
            ),
            TextButton(
              child: const Text('Vote'),
              onPressed: () async {
                Navigator.of(context).pop(); // Dismiss the dialog
                await _voteForCandidate(studentno, position); // Perform the voting with position
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double cardHeight = MediaQuery.of(context).size.width > 1200
        ? 350 // Desktop, larger screens
        : MediaQuery.of(context).size.width > 800
            ? 380 // Tablet size
            : 360; // Mobile screens

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        title: const Text('For Secretary', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: candidates.isNotEmpty
            ? LayoutBuilder(
                builder: (context, constraints) {
                  int columns = constraints.maxWidth > 1200
                      ? 5
                      : constraints.maxWidth > 800
                          ? 3
                          : constraints.maxWidth > 700
                              ? 2
                              : 1;

                  return Align(
                    alignment: Alignment.topCenter,
                    child: GridView.builder(
                      shrinkWrap: true,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        mainAxisExtent: cardHeight, // Setting the fixed height for the card
                      ),
                      itemCount: candidates.length,
                      itemBuilder: (context, index) {
                        var candidate = candidates[index];

                        // Decode base64 image data if available, else display icon
                        String base64Image = candidate['pic'] ?? '';
                        Uint8List? imageBytes;
                        if (base64Image.isNotEmpty) {
                          imageBytes = base64Decode(base64Image);
                        }

                        String firstName = candidate['firstname'] ?? '';
                        String middleName = candidate['middlename'] ?? '';
                        String lastName = candidate['lastname'] ?? '';
                        String slogan = candidate['slogan'] ?? 'No slogan available';

                        return Card(
                          elevation: 3,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Candidate's picture or default icon
                                    Container(
                                      width: 155,
                                      height: 155,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.grey.shade200,
                                      ),
                                      child: imageBytes != null
                                          ? ClipOval(
                                              child: Image.memory(
                                                imageBytes,
                                                fit: BoxFit.cover,
                                                width: 155,
                                                height: 155,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.person,
                                              size: 100,
                                              color: Colors.grey,
                                            ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      '$firstName $middleName $lastName',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // Slogan text
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                                      child: SizedBox(
                                        height: 60, // Adjusted for fixed height
                                        child: Text(
                                          slogan,
                                          textAlign: TextAlign.justify,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontStyle: FontStyle.italic,
                                          ),
                                          overflow: TextOverflow.visible,
                                          maxLines: 4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Vote button
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                                child: SizedBox(
                                  width: 100,
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      padding: const EdgeInsets.all(10.0),
                                      backgroundColor: const Color(0xFF1E3A8A),
                                    ),
                                    onPressed: () => _showConfirmationDialog(candidate['studentno'], 'president'),
                                    child: const Text(
                                      'Vote',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
