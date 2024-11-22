import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class VotePage extends StatefulWidget {
  @override
  _VotePageState createState() => _VotePageState();
}

class _VotePageState extends State<VotePage> {
  List<dynamic> candidates = [];
  List<dynamic> positions = [];
  String selectedPosition = 'All';
  Map<String, List<String>> userVotes = {}; // Tracks user votes per position
  bool isLoading = true; // Flag to show loading screen

  @override
  void initState() {
    super.initState();
    fetchCandidates();
    fetchPositions();
  }

  Future<void> fetchCandidates() async {
    final response = await http.get(Uri.parse('https://studentcouncil.bcp-sms1.com/php/1fetch_candidates.php'));
    if (response.statusCode == 200) {
      setState(() {
        candidates = json.decode(response.body);
        isLoading = false; // Hide loading indicator after data is fetched
      });
    } else {
      setState(() {
        isLoading = false; // Hide loading indicator in case of failure
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load candidates.')),
      );
    }
  }

  Future<void> fetchPositions() async {
    final response = await http.get(Uri.parse('https://studentcouncil.bcp-sms1.com/php/1fetch_positions.php'));
    if (response.statusCode == 200) {
      setState(() {
        positions = json.decode(response.body);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load positions.')),
      );
    }
  }

  Future<void> voteCandidate(String studentNo, String position, int votesQty) async {
    userVotes[position] ??= [];
    if ((userVotes[position]?.length ?? 0) >= votesQty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You have reached the voting limit for $position.')),
      );
      return;
    }
    if (userVotes[position]!.contains(studentNo)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You have already voted for this candidate.')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://studentcouncil.bcp-sms1.com/php/1vote_candidate.php'),
        body: {'studentno': studentNo},
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success'] == true) {
          setState(() {
            userVotes[position]!.add(studentNo);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Vote cast successfully!')),
          );
          fetchCandidates(); // Refresh candidates list
        } else {
          throw Exception(result['error'] ?? 'Failed to vote');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double cardHeight = MediaQuery.of(context).size.width > 1200
        ? 350 // Desktop, larger screens
        : MediaQuery.of(context).size.width > 800
            ? 380 // Tablet size
            : 360; // Mobile screens

    // Determine the number of candidates per row based on device size
    int candidatesPerRow = 5; // Default for large screens (computers)
    if (MediaQuery.of(context).size.width <= 1024) {
      candidatesPerRow = 3; // For iPads and Tablets
    }
    if (MediaQuery.of(context).size.width <= 540) {
      candidatesPerRow = 1; // For Mobile devices
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Vote'),
        actions: [
          DropdownButton<String>(
            value: selectedPosition,
            onChanged: (value) {
              setState(() {
                selectedPosition = value!;
              });
            },
            items: [
              DropdownMenuItem<String>(value: 'All', child: Text('All')),
              ...positions.map<DropdownMenuItem<String>>((position) {
                return DropdownMenuItem<String>(
                  value: position['name'] as String,
                  child: Text(position['name'] as String),
                );
              }).toList(),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator()) // Show loading indicator while fetching
            : SingleChildScrollView( // Wrap content in a scrollable container
                child: Column(
                  children: positions
                      .map((position) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Show position name if it matches the selected filter
                              if (selectedPosition == 'All' || selectedPosition == position['name'])
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    position['name'],
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              // Display candidates for this position if the filter matches
                              Align(
                                alignment: Alignment.topCenter,
                                child: GridView.builder(
                                  shrinkWrap: true, // Allows the GridView to fit inside a ListView
                                  physics: NeverScrollableScrollPhysics(), // Disable scrolling within GridView
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: candidatesPerRow,
                                    crossAxisSpacing: 8.0,
                                    mainAxisSpacing: 8.0,
                                    mainAxisExtent: cardHeight,
                                  ),
                                  itemCount: candidates
                                      .where((candidate) => selectedPosition == 'All' || candidate['position'] == position['name'])
                                      .toList()
                                      .length,
                                  itemBuilder: (context, index) {
                                    var candidate = candidates
                                        .where((candidate) => selectedPosition == 'All' || candidate['position'] == position['name'])
                                        .toList()[index];
                                    return Card(
                                      elevation: 2.0,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                ClipOval(
                                                  child: Image.network(
                                                    candidate['image_url'],
                                                    width: 155, // Adjust size based on device
                                                    height: 155, // Adjust size based on device
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.all(8.0),
                                                  child: Text(
                                                    '${candidate['firstname']} ${candidate['lastname']}',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                                Text(
                                                  candidate['slogan'] ?? '',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(fontStyle: FontStyle.italic),
                                                ),
                                              ],
                                            ),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              voteCandidate(
                                                candidate['studentno'] as String,
                                                position['name'] as String,
                                                position['votes_qty'] as int,
                                              );
                                            },
                                            child: Text('Vote'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ))
                      .toList(),
                ),
              ),
      ),
    );
  }
}
