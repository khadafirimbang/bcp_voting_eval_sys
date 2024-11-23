import 'package:flutter/material.dart';
import 'package:for_testing/voter_pages/candidate_info.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

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
    fetchCandidatesAndPositions();
  }

  // Fetch candidates and positions in one function to reduce network calls
  Future<void> fetchCandidatesAndPositions() async {
    try {
      final candidatesResponse = await http.get(Uri.parse('https://studentcouncil.bcp-sms1.com/php/1fetch_candidates.php'));
      final positionsResponse = await http.get(Uri.parse('https://studentcouncil.bcp-sms1.com/php/1fetch_positions.php'));

      if (candidatesResponse.statusCode == 200 && positionsResponse.statusCode == 200) {
        setState(() {
          candidates = json.decode(candidatesResponse.body);
          positions = json.decode(positionsResponse.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  // Voting function optimized to only update necessary state
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

    int candidatesPerRow = MediaQuery.of(context).size.width > 1024
        ? 5 // Desktop
        : MediaQuery.of(context).size.width > 540
            ? 3 // Tablets
            : 1; // Mobile devices

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
            ? Center(child: CircularProgressIndicator()) // Loading indicator
            : SingleChildScrollView(
                child: Column(
                  children: selectedPosition == 'All'
                      ? positions.map((position) {
                          var filteredCandidates = candidates
                              .where((candidate) => candidate['position'] == position['name'])
                              .toList();

                          return _buildCandidateGrid(position, filteredCandidates, candidatesPerRow, cardHeight);
                        }).toList()
                      : positions.where((position) => position['name'] == selectedPosition).map((position) {
                          var filteredCandidates = candidates
                              .where((candidate) => candidate['position'] == position['name'])
                              .toList();

                          return _buildCandidateGrid(position, filteredCandidates, candidatesPerRow, cardHeight);
                        }).toList(),
                ),
              ),
    ));
  }

  // Helper function to create the candidate grid
  Widget _buildCandidateGrid(dynamic position, List<dynamic> filteredCandidates, int candidatesPerRow, double cardHeight) {
    if (filteredCandidates.isEmpty) return SizedBox.shrink(); // Skip if no candidates

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            position['name'],
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: candidatesPerRow,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
            mainAxisExtent: cardHeight,
          ),
          itemCount: filteredCandidates.length,
          itemBuilder: (context, index) {
            var candidate = filteredCandidates[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CandidateDetailPage(candidate: candidate),
                  ),
                );
              },
              child: Card(
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
                            child: CachedNetworkImage(
                              imageUrl: candidate['image_url'],
                              width: 155,
                              height: 155,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => CircularProgressIndicator(),
                              errorWidget: (context, url, error) => Icon(Icons.error),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              '${candidate['firstname']} ${candidate['lastname']} | ${candidate['position']}',
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
              ),
            );
          },
        ),
      ],
    );
  }
}
