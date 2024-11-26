import 'package:flutter/material.dart';
import 'package:for_testing/voter_pages/candidate_info.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';

class VotePage extends StatefulWidget {
  @override
  _VotePageState createState() => _VotePageState();
}

class _VotePageState extends State<VotePage> {
  List<dynamic> candidates = [];
  List<dynamic> positions = [];
  String selectedPosition = 'All';
  String searchQuery = '';
  Map<String, List<String>> userVotes = {};
  bool isLoading = true;
  bool showSearchField = false; // State to toggle search field
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    fetchCandidatesAndPositions();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> fetchCandidatesAndPositions() async {
    try {
      final candidatesFuture = http.get(Uri.parse('https://studentcouncil.bcp-sms1.com/php/1fetch_candidates.php'));
      final positionsFuture = http.get(Uri.parse('https://studentcouncil.bcp-sms1.com/php/1fetch_positions.php'));

      final responses = await Future.wait([candidatesFuture, positionsFuture]);

      if (responses[0].statusCode == 200 && responses[1].statusCode == 200) {
        setState(() {
          candidates = json.decode(responses[0].body);
          positions = json.decode(responses[1].body);
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

  void debounceSearch(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(Duration(milliseconds: 300), () {
      setState(() {
        searchQuery = value.toLowerCase();
      });
    });
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
        ? 350
        : MediaQuery.of(context).size.width > 800
            ? 380
            : 360;

    int candidatesPerRow = MediaQuery.of(context).size.width > 1024
        ? 5
        : MediaQuery.of(context).size.width > 540
            ? 3
            : 1;

    return Scaffold(
      appBar: AppBar(
        title: Text('Vote'),
        actions: [
          IconButton(
            icon: Icon(showSearchField ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                showSearchField = !showSearchField;
                if (!showSearchField) {
                  searchQuery = '';
                }
              });
            },
          ),
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
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    // Search TextField at the top of the list
                    if (showSearchField)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          ),
                          onChanged: debounceSearch,
                        ),
                      ),
                    selectedPosition == 'All'
                        ? Column(
                            children: positions.map((position) {
                              var filteredCandidates =
                                  _filterCandidates(position['name']);
                              return _buildCandidateGrid(
                                  position,
                                  filteredCandidates,
                                  candidatesPerRow,
                                  cardHeight);
                            }).toList(),
                          )
                        : Column(
                            children: positions
                                .where((position) =>
                                    position['name'] == selectedPosition)
                                .map((position) {
                              var filteredCandidates =
                                  _filterCandidates(position['name']);
                              return _buildCandidateGrid(
                                  position,
                                  filteredCandidates,
                                  candidatesPerRow,
                                  cardHeight);
                            }).toList(),
                          ),
                  ],
                ),
              ),
      ),
    );
  }

  List<dynamic> _filterCandidates(String positionName) {
  return candidates
      .where((candidate) =>
          candidate['position'] == positionName &&
          (
            (candidate['firstname']?.toLowerCase() ?? '').contains(searchQuery) ||
            (candidate['lastname']?.toLowerCase() ?? '').contains(searchQuery) ||
            (candidate['studentno']?.toString().toLowerCase() ?? '').contains(searchQuery) ||
            (candidate['section']?.toString().toLowerCase() ?? '').contains(searchQuery) ||
            (candidate['course']?.toString().toLowerCase() ?? '').contains(searchQuery) ||
            (candidate['partylist']?.toString().toLowerCase() ?? '').contains(searchQuery)
          ))
      .toList();
}

  Widget _buildCandidateGrid(dynamic position, List<dynamic> filteredCandidates,
      int candidatesPerRow, double cardHeight) {
    if (filteredCandidates.isEmpty) return SizedBox.shrink();

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
                    builder: (context) =>
                        CandidateDetailPage(candidate: candidate),
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
                              placeholder: (context, url) =>
                                  CircularProgressIndicator(),
                              errorWidget: (context, url, error) =>
                                  Icon(Icons.error),
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
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ElevatedButton(
                              onPressed: () {
                                voteCandidate(
                                    candidate['studentno'],
                                    position['name'],
                                    1);
                              },
                              child: Text('Vote'),
                            ),
                          ),
                        ],
                      ),
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
