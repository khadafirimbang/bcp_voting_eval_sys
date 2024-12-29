import 'package:flutter/material.dart';
import 'package:for_testing/results_pages/results.dart';
import 'package:for_testing/voter_pages/candidate_info.dart';
import 'package:for_testing/voter_pages/chatbot.dart';
import 'package:for_testing/voter_pages/drawerbar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class VotePage extends StatefulWidget {
  @override
  _VotePageState createState() => _VotePageState();
}

class _VotePageState extends State<VotePage> {
  List<dynamic> candidates = [];
  List<dynamic> positions = [];
  Map<String, dynamic>? electionSchedule;
  Duration? timeRemaining;
  Timer? _countdownTimer;
  Timer? _debounce;
  bool isLoading = true;
  bool showSearchField = false;
  String selectedPosition = 'All';
  String searchQuery = '';
  Map<String, List<String>> userVotes = {};
  Timer? _scheduleCheckTimer;

  @override
  void initState() {
    super.initState();
    fetchElectionSchedule();

    // Check election status every minute
    _scheduleCheckTimer = Timer.periodic(Duration(minutes: 1), (_) {
      fetchElectionSchedule();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _debounce?.cancel();
    _scheduleCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchElectionSchedule() async {
    try {
      final response = await http.get(
        Uri.parse('https://studentcouncil.bcp-sms1.com/php/fetch_election_schedule.php')
      );

      if (response.statusCode == 200) {
        final schedule = json.decode(response.body);
        
        if (mounted) {
          setState(() {
            electionSchedule = schedule;
            
            if (schedule != null) {
              // Parse end date in Philippines timezone
              final endDate = DateTime.parse(schedule['end_date']).toLocal();
              
              if (schedule['status'] == 'ongoing') {
                // Check if the election has ended
                if (isCurrentDateMatchEndDate(endDate)) {
                  updateElectionStatus('ended');
                } else {
                  startCountdown(endDate);
                  fetchCandidatesAndPositions();
                }
              }
            }
            
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading election schedule: $e')),
        );
      }
    }
  }

  bool isCurrentDateMatchEndDate(DateTime endDate) {
    // Get current date in Philippines timezone
    final now = DateTime.now();
    
    // Compare year, month, and day
    return now.year == endDate.year &&
           now.month == endDate.month &&
           now.day == endDate.day;
  }

  Future<void> fetchCandidatesAndPositions() async {
    try {
      final candidatesFuture = http.get(
        Uri.parse('https://studentcouncil.bcp-sms1.com/php/1fetch_candidates.php')
      );
      final positionsFuture = http.get(
        Uri.parse('https://studentcouncil.bcp-sms1.com/php/1fetch_positions.php')
      );

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

  void startCountdown(DateTime endDate) {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      if (now.isAfter(endDate)) {
        timer.cancel();
        updateElectionStatus('ended');
        setState(() {});
      } else {
        setState(() {
          timeRemaining = endDate.difference(now);
        });
      }
    });
  }

  Future<void> updateElectionStatus(String status) async {
    try {
      final response = await http.post(
        Uri.parse('https://studentcouncil.bcp-sms1.com/php/update_election_status.php'),
        body: {
          'election_id': electionSchedule?['id'].toString(),
          'status': status
        }
      );

      if (response.statusCode == 200) {
        fetchElectionSchedule();
      }
    } catch (e) {
      print('Error updating election status: $e');
    }
  }

  String formatDuration(Duration? duration) {
    if (duration == null) return '';
    return '${duration.inDays}d ${duration.inHours.remainder(24)}h '
           '${duration.inMinutes.remainder(60)}m ${duration.inSeconds.remainder(60)}s';
  }

  void debounceSearch(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(Duration(milliseconds: 300), () {
      setState(() {
        searchQuery = value.toLowerCase();
      });
    });
  }

  void _voteForCandidate(dynamic candidate) async {
    if (electionSchedule?['status'] != 'ongoing') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Voting is not currently available.')),
      );
      return;
    }

    final confirmVote = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Vote"),
          content: Text("Are you sure you want to vote for ${candidate['firstname']} ${candidate['lastname']}?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text("Confirm"),
            ),
          ],
        );
      },
    );

    if (confirmVote == true) {
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? loggedInStudentno = prefs.getString('studentno');
        
        final response = await http.post(
          Uri.parse('https://studentcouncil.bcp-sms1.com/php/1vote_candidate.php'),
          body: {
            'studentno': loggedInStudentno,
            'candidate_id': candidate['studentno'].toString(),
            'position': candidate['position'],
          },
        );

        final result = json.decode(response.body);

        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'])),
          );
          fetchCandidatesAndPositions();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'])),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
      }
    }
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (electionSchedule == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Elections')),
        body: Center(child: Text('No active election scheduled.')),
      );
    }

    if (electionSchedule!['status'] == 'ended') {
      return Scaffold(
        appBar: AppBar(title: Text('Election Ended')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Election Ended',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
              ),
              SizedBox(height: 20),
              SizedBox(
                        width: 340,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.all(14.0),
                            backgroundColor: const Color(0xFF1E3A8A),
                          ),
                          onPressed: () {
                            Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ResultsPage()),
                          );
                          },
                          child: const Text('Election Result', 
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
              
            ],
          ),
        ),
      );
    }

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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          alignment: Alignment.center,
          margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: AppBar(
            titleSpacing: -5,
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'Vote',
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
            iconTheme: const IconThemeData(color: Colors.black45),
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
        ),
      ),
      drawer: AppDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 6),
            child: Text(electionSchedule!['election_name'],
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 21)
            ),
          ),
          if (electionSchedule!['status'] == 'ongoing')
            Container(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Time Remaining: ',
                    style: TextStyle(fontWeight: FontWeight.bold)
                  ),
                  Text(formatDuration(timeRemaining)),
                ],
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
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
                                cardHeight
                              );
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
                                cardHeight
                              );
                            }).toList(),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ChatbotScreen()),
          );
        },
        child: Icon(Icons.chat_outlined),
      ),
    );
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
                                  child: candidate['image_url'] != null && candidate['image_url'].isNotEmpty
                                      ? Image.network(
                                          candidate['image_url'],
                                          height: 155,
                                          width: 155,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.asset(
                                          'assets/images/bcp_logo.png',
                                          height: 155,
                                          width: 155,
                                          fit: BoxFit.cover,
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
                                _voteForCandidate(candidate);
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
