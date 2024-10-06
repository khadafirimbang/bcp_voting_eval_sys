import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:for_testing/admin_pages/drawerbar_admin.dart';
import 'package:for_testing/voter_pages/drawerbar.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // For getting logged-in student's number

class ResultAuditor extends StatefulWidget {
  const ResultAuditor({super.key});

  @override
  State<ResultAuditor> createState() => _ResultAuditorState();
}

class _ResultAuditorState extends State<ResultAuditor> {
  List candidates = [];
  String? studentnoLoggedIn;
  String statusMessage = 'Loading...';
  String? imageURL;

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
    var url = Uri.parse('https://studentcouncil.bcp-sms1.com/php/fetch_results.php');
    var response = await http.get(url);

    try {
      var data = json.decode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          if (data['status'] == 'ongoing') {
            if ((data['candidates'] as List).isNotEmpty) {
              candidates = (data['candidates'] as List)
                  .where((candidate) => candidate['position'] == 'Auditor')
                  .toList();
              statusMessage = ''; // Clear status message if candidates are available
            } else {
              candidates = [];
              statusMessage = 'No Candidates!';
            }
          } else if (data['status'] == 'ended') {
            candidates = [];
            statusMessage = 'Election Ended!';
          } else {
            candidates = [];
            statusMessage = 'Error fetching candidates.';
          }
        });
      } else {
        print('Failed to fetch candidates: ${response.statusCode}');
        setState(() {
          candidates = [];
          statusMessage = 'Error fetching candidates.';
        });
      }
    } catch (e) {
      print('Error decoding response: $e');
      setState(() {
        candidates = [];
        statusMessage = 'Error decoding response.';
      });
    }
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
        title: const Text('For Auditor', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer(); // Use this context
            },
                  );
          }
        ),
      ),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: candidates.isEmpty
            ? Center(
                child: Text(
                  statusMessage,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              )
            : LayoutBuilder(
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
                        String totalVotes = candidate['total_votes'] ?? '';
                        imageURL = candidate['image_url'] ?? '';

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
                                      child: imageURL != null && imageURL!.isNotEmpty
                                          ? ClipOval(
                                              child: Image.network(
                                                imageURL!,
                                                fit: BoxFit.cover,
                                                width: 155,
                                                height: 155,
                                                loadingBuilder: (context, child, loadingProgress) {
                                                  if (loadingProgress == null) {
                                                    return child;
                                                  } else {
                                                    return Center(
                                                      child: CircularProgressIndicator(
                                                        value: loadingProgress.expectedTotalBytes != null
                                                            ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                                                            : null,
                                                      ),
                                                    );
                                                  }
                                                },
                                                errorBuilder: (context, error, stackTrace) {
                                                  return const Icon(
                                                    Icons.error,
                                                    size: 100,
                                                    color: Colors.red,
                                                  );
                                                },
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
                                    const SizedBox(height: 50),
                                    // Slogan text
                                    Text(
                                      'Total Votes: $totalVotes',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }

  // Helper method to get the status message
  String _getStatusMessage() {
    return statusMessage.isEmpty ? 'No Candidates!' : statusMessage;
  }
}
