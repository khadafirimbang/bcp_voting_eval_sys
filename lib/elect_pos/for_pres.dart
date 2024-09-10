import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:for_testing/drawerbar.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // For getting logged-in student's number

class ForPres extends StatefulWidget {
  const ForPres({super.key});

  @override
  State<ForPres> createState() => _ForPresState();
}

class _ForPresState extends State<ForPres> {
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
    var url = Uri.parse('http://192.168.1.2/for_testing/fetch_candidates_pres.php');
    var response = await http.get(url);

    if (response.statusCode == 200) {
      setState(() {
        candidates = json.decode(response.body);
      });
    } else {
      print('Failed to fetch candidates');
    }
  }

  Future<void> _voteForCandidate(String studentno) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? loggedInStudentno = prefs.getString('studentno');

    var url = Uri.parse('http://192.168.1.2/for_testing/vote_candidate.php');
    var response = await http.post(url, body: {
      'studentno': studentno,
      'loggedInStudentno': loggedInStudentno ?? '',
    });

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

  void _showConfirmationDialog(String studentno) {
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
                await _voteForCandidate(studentno); // Perform the voting
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        title: const Text('For President', style: TextStyle(color: Colors.white)),
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
                          : 1;

                  return Align(
                    alignment: Alignment.topCenter,
                    child: GridView.builder(
                      shrinkWrap: true,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        mainAxisExtent: null,
                      ),
                      itemCount: candidates.length,
                      itemBuilder: (context, index) {
                        var candidate = candidates[index];

                        // Decode base64 image data
                        String base64Image = candidate['pic'] ?? '';
                        Uint8List imageBytes = base64Decode(base64Image);

                        String firstName = candidate['firstname'] ?? '';
                        String middleName = candidate['middlename'] ?? '';
                        String lastName = candidate['lastname'] ?? '';
                        String slogan = candidate['slogan'] ?? 'No slogan available';

                        return Card(
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Candidate's picture
                                Container(
                                  width: 155,
                                  height: 155,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    image: DecorationImage(
                                      image: MemoryImage(imageBytes),
                                      fit: BoxFit.cover,
                                    ),
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
                                // const SizedBox(height: 8),
                                // Wrap slogan with Flexible to handle overflow
                                SizedBox(
                                  height: 90,
                                  child: Text(
                                    slogan,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    overflow: TextOverflow.ellipsis, // Handles text overflow
                                    maxLines: 4, // Limits the number of lines
                                  ),
                                ),
                                // const Spacer(),
                                // const SizedBox(height: 10,),
                                SizedBox(
                                  width: 100,
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      padding: const EdgeInsets.all(12.0),
                                      backgroundColor: const Color(0xFF1E3A8A),
                                    ),
                                    onPressed: () => _showConfirmationDialog(candidate['studentno']),
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
                                // const SizedBox(height: 10,)
                              ],
                            ),
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
