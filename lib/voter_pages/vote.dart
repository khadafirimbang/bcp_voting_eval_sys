import 'dart:typed_data';

import 'package:SSCVote/voter_pages/election_audit.dart';
import 'package:SSCVote/voter_pages/profile.dart';
import 'package:SSCVote/voter_pages/selected_candidates.dart';
import 'package:flutter/material.dart';
import 'package:SSCVote/main.dart';
import 'package:SSCVote/results_pages/results.dart';
import 'package:SSCVote/voter_pages/announcement.dart';
import 'package:SSCVote/voter_pages/candidate_info.dart';
import 'package:SSCVote/voter_pages/chatbot.dart';
import 'package:SSCVote/voter_pages/drawerbar.dart';
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Map<String, ImageProvider> _imageCache = {};
  List<dynamic> _selectedCandidates = [];
  Map<String, int> positionVotesCounts = {};
  Map<String, bool> _positionsVotedStatus = {};

  @override
  void initState() {
    super.initState();
    fetchElectionSchedule();

    // Check election status every minute
    _scheduleCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) {
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

  ImageProvider _getImageProvider(dynamic candidate) {
    if (candidate['img'] == null || candidate['img'].isEmpty) {
      return const AssetImage('assets/bcp_logo.png');
    }

    final String imageKey = candidate['studentno'].toString();
    if (_imageCache.containsKey(imageKey)) {
      return _imageCache[imageKey]!;
    }

    try {
      final String cleanBase64 = candidate['img']
          .replaceAll(RegExp(r'data:image/[^;]+;base64,'), '')
          .replaceAll('\n', '')
          .replaceAll('\r', '')
          .trim();

      final ImageProvider provider = MemoryImage(base64Decode(cleanBase64));
      _imageCache[imageKey] = provider;
      return provider;
    } catch (e) {
      print('Error loading image for candidate ${candidate['studentno']}: $e');
      return const AssetImage('assets/bcp_logo.png');
    }
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
            // Parse end date in UTC and adjust for Philippines timezone
            final endDate = DateTime.parse(schedule['end_date']).toUtc();
            
            // Log the end date for debugging
            print('End Date: $endDate');
            
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
  // Get current date in UTC and adjust for Philippines timezone
  final now = DateTime.now().toUtc();
  
  // Log current time for debugging
  print('Current Time: $now');
  
  return now.isAfter(endDate);
}


  Future<void> fetchCandidatesAndPositions() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? studentNo = prefs.getString('studentno');

    final candidatesFuture = http.get(
      Uri.parse('https://studentcouncil.bcp-sms1.com/php/1fetch_candidates.php')
    );
    final positionsFuture = http.get(
      Uri.parse('https://studentcouncil.bcp-sms1.com/php/1fetch_positions.php')
    );

    // Fetch votes count and voted positions
    final votedPositionsFuture = http.get(
      Uri.parse('https://studentcouncil.bcp-sms1.com/php/fetch_voted_positions.php?studentno=$studentNo')
    );

    final responses = await Future.wait([
      candidatesFuture, 
      positionsFuture, 
      votedPositionsFuture
    ]);

    // Detailed logging
    print('Candidates Response Body: ${responses[0].body}');
    print('Positions Response Body: ${responses[1].body}');
    print('Voted Positions Response Body: ${responses[2].body}');

    if (responses[0].statusCode == 200 && 
        responses[1].statusCode == 200 && 
        responses[2].statusCode == 200) {
      
      final candidatesData = json.decode(responses[0].body);
      final positionsData = json.decode(responses[1].body);
      final votedPositionsData = json.decode(responses[2].body);

      setState(() {
        candidates = _sanitizeList(candidatesData);
        positions = _sanitizePositions(positionsData);
        
        // Robust handling of voted positions
        _positionsVotedStatus = _sanitizeVotedPositions(votedPositionsData);

        // Remove the filtering logic for positions
        // positions = positions.where((position) {
        //   String positionName = position['name']?.toString() ?? '';
        //   int maxVotes = _safeParseInt(position['votes_qty']) ?? 0;
        //   int currentVotes = _countCurrentVotes(positionName);
          
        //   return currentVotes < maxVotes;
        // }).toList();

        isLoading = false;
      });
    } else {
      // More detailed error logging
      print('Failed to load data');
      print('Candidates Status: ${responses[0].statusCode}');
      print('Positions Status: ${responses[1].statusCode}');
      print('Voted Positions Status: ${responses[2].statusCode}');
      
      throw Exception('Failed to load data');
    }
  } catch (e, stackTrace) {
    print('Comprehensive Error in fetchCandidatesAndPositions: $e');
    print('Stacktrace: $stackTrace');
    
    setState(() {
      isLoading = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error loading data: $e'),
        duration: Duration(seconds: 5),
      ),
    );
  }
}

  // Sanitize list to ensure it's a list and contains only valid items
  List<dynamic> _sanitizeList(dynamic data) {
    if (data is List) {
      return data.where((item) => item is Map).toList();
    }
    print('Invalid data type for list: ${data.runtimeType}');
    return [];
  }

  // Sanitize positions with robust type handling
  List<dynamic> _sanitizePositions(dynamic data) {
    if (data is! List) {
      print('Invalid positions data type: ${data.runtimeType}');
      return [];
    }

    return data.map((position) {
      // Ensure position is a map
      if (position is! Map) {
        print('Invalid position item type: ${position.runtimeType}');
        return null;
      }

      // Create a new map with sanitized values
      return {
        'name': position['name']?.toString() ?? '',
        'votes_qty': _safeParseInt(position['votes_qty']) ?? 0,
        // Add other necessary fields, sanitizing as needed
        ...position
      };
    }).whereType<Map>().toList();
  }

  // Sanitize voted positions with robust handling
  Map<String, bool> _sanitizeVotedPositions(dynamic data) {
    Map<String, bool> votedPositions = {};

    // Handle different possible data structures
    if (data is Map) {
      // If it's a map with 'voted_positions' key
      if (data.containsKey('voted_positions')) {
        data = data['voted_positions'];
      }
    }

    // Convert to map of position names to voted status
    if (data is Map) {
      data.forEach((key, value) {
        votedPositions[key.toString()] = _isTruthy(value);
      });
    } else if (data is List) {
      for (var item in data) {
        if (item is Map) {
          votedPositions[item['position']?.toString() ?? ''] = 
            _isTruthy(item['voted']);
        }
      }
    }

    return votedPositions;
  }

  // Safe integer parsing
  int? _safeParseInt(dynamic value) {
    if (value == null) return null;
    
    // If it's already an int, return it
    if (value is int) return value;
    
    // Try parsing string to int
    return int.tryParse(value.toString());
  }

  // Check if a value is considered "truthy"
  bool _isTruthy(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      return ['true', '1', 'yes'].contains(value.toLowerCase());
    }
    return false;
  }


  int _countCurrentVotes(String positionName) {
  return candidates.where((candidate) => 
    candidate['position'] == positionName && 
    _selectedCandidates.any((selected) => 
      selected['studentno'].toString() == candidate['studentno'].toString())
  ).length;
}

  void startCountdown(DateTime endDate) {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
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
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        searchQuery = value.toLowerCase();
      });
    });
  }

  void _voteForCandidate(dynamic candidate) async {
    if (electionSchedule?['status'] != 'ongoing') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voting is not currently available.')),
      );
      return;
    }

    final confirmVote = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Vote"),
          content: Text("Are you sure you want to vote for ${candidate['firstname']} ${candidate['lastname']}?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Confirm"),
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

          // Update local votes count
          setState(() {
            positionVotesCounts[candidate['position']] = 
              (positionVotesCounts[candidate['position']] ?? 0) + 1;
            
            // Remove position if max votes reached
            positions = positions.where((position) {
              String positionName = position['name'];
              int maxVotes = position['votes_qty'] ?? 0;
              int currentVotes = positionVotesCounts[positionName] ?? 0;
              return currentVotes < maxVotes;
            }).toList();
          });
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (electionSchedule == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Elections')),
        body: const Center(child: Text('No active election scheduled.')),
      );
    }

    if (electionSchedule!['status'] == 'ended') {
      return Scaffold(
        appBar: AppBar(title: const Text('Election Ended')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Election Ended',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 20),
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

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[200],
        key: _scaffoldKey,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(56), // Set height of the AppBar
          child: Container(
            height: 56,
            alignment: Alignment.center, // Align the AppBar in the center
            margin: const EdgeInsets.fromLTRB(16, 10, 16, 0), // Add margin to control width
            decoration: BoxDecoration(
              color: Colors.white, 
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3), // Shadow color
                  blurRadius: 8, // Blur intensity
                  spreadRadius: 1, // Spread radius
                  offset: const Offset(0, 4), // Vertical shadow position
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                  onPressed: () {
                    _scaffoldKey.currentState?.openDrawer();
                  },
                  icon: const Icon(Icons.menu, color: Colors.black45),
                ),
                const Text(
                  'Vote',
                  style: TextStyle(fontSize: 18, color: Colors.black54),
                ),
                  ],
                ),
                Row(
                  children: [
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
                        const DropdownMenuItem<String>(value: 'All', child: Text('All')),
                        ...positions.map<DropdownMenuItem<String>>((position) {
                          return DropdownMenuItem<String>(
                            value: position['name'] as String,
                            child: Text(position['name'] as String),
                          );
                        }).toList(),
                      ],
                    ),
                    _buildProfileMenu(context)
                  ],
                )
              ],
            )
          ),
        ),
        drawer: const AppDrawer(),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 6),
              child: Column(
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ElectionAuditPage()),
                      );
                    },
                    child: const Text('Election Audit', style: TextStyle(color: Colors.black)),
                  ),
                  Text(electionSchedule!['election_name'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 21)
                  ),
                ],
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
                                  const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                            ),
                            onChanged: debounceSearch,
                          ),
                        ),
                      selectedPosition == 'All'
                          ? Column(
                              children: positions.map((position) {
                                var filteredCandidates =
                                    _filterCandidates(position['name']);
                                return ExpansionTile(
                                  collapsedShape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.zero,
                                  ),
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.zero,
                                  ),
                                  title: Text(
                                    position['name'],
                                    style: const TextStyle(fontSize: 16.0,),
                                  ),
                                  children: [
                                    _buildCandidateGrid(
                                    position,
                                    filteredCandidates,
                                    candidatesPerRow,
                                    cardHeight
                                  ),
                                  ],
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
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          onPressed: _selectedCandidates.isNotEmpty 
              ? () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SelectedCandidatesPage(
                        selectedCandidates: _selectedCandidates,
                        onCandidatesUpdated: (updatedCandidates) {
                          // Update the _selectedCandidates list in VotePage
                          setState(() {
                            _selectedCandidates = updatedCandidates;
                          });
                        },
                      ),
                    ),
                  );
                  
                  if (result == true) {
                    // Reset selected candidates after voting
                    setState(() {
                      _selectedCandidates.clear();
                    });
                  }
                }
              : null,
          child: Icon(Icons.check),
        ),
      ),
    );
  }

  Widget _buildCandidateGrid(
  dynamic position, 
  List<dynamic> filteredCandidates,
  int candidatesPerRow, 
  double cardHeight
) {
  // Check if position is fully voted
  bool isPositionVoted = _positionsVotedStatus[position['name'] as String] ?? false;

  // If no candidates and position is voted, return nothing
  if (filteredCandidates.isEmpty && isPositionVoted) {
    return const SizedBox.shrink();
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Position Title with voting status
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Text(
            //   position['name'],
            //   style: TextStyle(
            //     fontSize: 18, 
            //     fontWeight: FontWeight.bold,
            //     color: isPositionVoted ? Colors.grey : Colors.black,
            //   ),
            // ),
            if (isPositionVoted)
              Text(
                'Already voted for this position',
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),

      // Candidates Grid or No Candidates Message
      filteredCandidates.isEmpty
        ? Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                'No candidates available for this position',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          )
        : GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: candidatesPerRow,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
              mainAxisExtent: cardHeight,
            ),
            itemCount: filteredCandidates.length,
            itemBuilder: (context, index) {
              var candidate = filteredCandidates[index];
              return _buildCandidateCard(candidate, isPositionVoted);
            },
          ),
    ],
  );
}

Widget _buildCandidateCard(dynamic candidate, bool isPositionVoted) {
  // Get the position of the candidate
  String position = candidate['position'];

  // Get the maximum number of votes allowed for this position
  int maxVotes = positions.firstWhere((pos) => pos['name'] == position, orElse: () => {'votes_qty': 0})['votes_qty'];

  // Count the number of currently selected candidates for this position
  int currentVotes = _selectedCandidates.where((c) => c['position'] == position).length;

  // Check if the maximum number of votes has been reached
  bool isMaxVotesReached = currentVotes >= maxVotes;

  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CandidateDetailPage(candidate: candidate),
        ),
      );
    },
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
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
                  CircleAvatar(
                    radius: 80,
                    backgroundImage: _getImageProvider(candidate),
                    onBackgroundImageError: (exception, stackTrace) {
                      print('Error loading image: $exception');
                      setState(() {
                        _imageCache.remove(candidate['studentno'].toString());
                      });
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      '${candidate['firstname'] ?? ''} ${candidate['lastname'] ?? ''} | ${candidate['position'] ?? ''}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    candidate['slogan'] ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: isPositionVoted
                      ? Text(
                          '',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedCandidates.any((c) => c['studentno'] == candidate['studentno']) 
                              ? Colors.green 
                              : Colors.black
                          ),
                          onPressed: _selectedCandidates.any((c) => c['studentno'] == candidate['studentno']) || !isMaxVotesReached
                            ? () {
                                setState(() {
                                  if (_selectedCandidates.any((c) => c['studentno'] == candidate['studentno'])) {
                                    _selectedCandidates.removeWhere((c) => c['studentno'] == candidate['studentno']);
                                  } else {
                                    _selectedCandidates.add(candidate);
                                  }
                                });
                              }
                            : null, // Disable the button if max votes reached and candidate is not selected
                          child: Text(
                            _selectedCandidates.any((c) => c['studentno'] == candidate['studentno']) 
                              ? 'Selected' 
                              : 'Select', 
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildProfileMenu(BuildContext context) {
    return PopupMenuButton<int>(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onSelected: (item) {
        switch (item) {
          case 0:
            // Navigate to Profile page
            Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileInfoPage()));
            break;
          case 1:
            // Handle sign out
            _logout(context); // Example action for Sign Out
            break;
        }
      },
      offset: Offset(0, 50), // Adjust dropdown position
      itemBuilder: (context) => [
        PopupMenuItem<int>(
          padding: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
          value: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Signed in as', style: TextStyle(color: Colors.black54)),
              Text(studentNo ?? 'Unknown'),
            ],
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem<int>(
          value: 0,
          child: Row(
            children: [
              Icon(Icons.person, color: Colors.black54),
              SizedBox(width: 10),
              Text('Profile'),
            ],
          ),
        ),
        PopupMenuItem<int>(
          value: 1,
          child: Row(
            children: [
              Icon(Icons.logout, color: Colors.black54),
              SizedBox(width: 10),
              Text('Sign out'),
            ],
          ),
        ),
      ],
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: Colors.black54),
          ),
        ],
      ),
    );
  }
  
  void _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!context.mounted) return; // Ensure the widget is still mounted

    // Use pushAndRemoveUntil to clear the navigation stack
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoadingScreen()), // Replace with your login page
      (Route<dynamic> route) => false, // Remove all previous routes
    );
  }
}