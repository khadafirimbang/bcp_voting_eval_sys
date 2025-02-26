import 'dart:async';

import 'package:SSCVote/voter_pages/profile.dart';
import 'package:flutter/material.dart';
import 'package:SSCVote/main.dart';
import 'package:SSCVote/voter_pages/announcement.dart';
import 'package:SSCVote/voter_pages/drawerbar.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ElectionSurveyCandidates extends StatefulWidget {
  @override
  _ElectionSurveyCandidatesState createState() => _ElectionSurveyCandidatesState();
}

class _ElectionSurveyCandidatesState extends State<ElectionSurveyCandidates> {
  List<dynamic> candidates = [];
  Map<String, List<String>> selectedCandidates = {};
  Map<String, int> votesQty = {};
  bool isLoading = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    checkParticipation();
  }

  Future<void> checkParticipation() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? studentno = prefs.getString('studentno');

  try {
    final response = await http.get(
      Uri.parse('https://studentcouncil.bcp-sms1.com/php/check_participation.php?studentno=$studentno')
    );
    
    if (response.statusCode == 200) {
      final Map<String, dynamic> participationData = json.decode(response.body);
      
      if (participationData['participated'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ParticipationDetailsPage(
              selectedCandidates: participationData['selected_candidates'],
              selectedPartylist: participationData['selected_partylist'],
              participationDate: participationData['participation_date'],
            ),
          ),
        );
      } else {
        // Proceed with survey
        fetchCandidates();
        fetchVotesQty();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking participation status')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Network error: ${e.toString()}')),
    );
  }
}


  Future<void> fetchCandidates() async {
    final response = await http.get(Uri.parse('https://studentcouncil.bcp-sms1.com/php/fetch_candidates.php'));
    if (response.statusCode == 200) {
      setState(() {
        candidates = json.decode(response.body);
        isLoading = false;
      });
    }
  }

  Future<void> fetchVotesQty() async {
    final response = await http.get(Uri.parse('https://studentcouncil.bcp-sms1.com/php/fetch_votes_qty.php'));
    if (response.statusCode == 200) {
      setState(() {
        votesQty = Map.from(json.decode(response.body));
      });
    }
  }

  void onCandidateSelected(String position, String candidateId, bool isSelected) {
    setState(() {
      selectedCandidates.putIfAbsent(position, () => []);
      if (isSelected) {
        if (!selectedCandidates[position]!.contains(candidateId)) {
          selectedCandidates[position]!.add(candidateId);
        }
      } else {
        selectedCandidates[position]!.remove(candidateId);
      }
    });
  }

  void onNext() {
    for (var position in votesQty.keys) {
      if (selectedCandidates[position]?.length != votesQty[position]) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Warning'),
            content: Text('You must select ${votesQty[position]} candidates for $position.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
        );
        return;
      }
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ElectionSurveyPartylist(selectedCandidates)),
    );
  }

  @override
  Widget build(BuildContext context) {
    Map<String, List<dynamic>> candidatesByPosition = {};

    for (var candidate in candidates) {
      String position = candidate['position'] ?? 'Unknown';
      if (!candidatesByPosition.containsKey(position)) {
        candidatesByPosition[position] = [];
      }
      candidatesByPosition[position]!.add(candidate);
    }

    return SafeArea(
      child: Scaffold(
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
                'Election Survey',
                style: TextStyle(fontSize: 18, color: Colors.black54),
              ),
                ],
              ),
              Row(
                children: [
                  _buildProfileMenu(context)
                ],
              )
            ],
          )
          ),
        ),
        drawer: const AppDrawer(),
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text("This is only a survey, please select the Candidates and Partylist you preferred.", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
                  Expanded(
                    child: ListView(
                        children: candidatesByPosition.entries.map((entry) {
                          String position = entry.key;
                          List<dynamic> positionCandidates = entry.value;
                    
                          return ExpansionTile(
                            title: Text(position),
                            children: positionCandidates.map((candidate) {
                              String candidateId = candidate['studentno'].toString();
                              return ListTile(
                                // leading: CircleAvatar(
                                  
                                //   child: Icon(Icons.person),
                                // ),
                                title: Text('${candidate['firstname']} ${candidate['lastname']}'),
                                subtitle: Text('Party: ${candidate['partylist']}'),
                                trailing: Checkbox(
                                  value: selectedCandidates[position]?.contains(candidateId) ?? false,
                                  onChanged: (bool? isSelected) {
                                    onCandidateSelected(position, candidateId, isSelected ?? false);
                                  },
                                ),
                              );
                            }).toList(),
                          );
                        }).toList(),
                      ),
                  ),
                ],
              ),
            ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.black,
          onPressed: onNext,
          child: Icon(Icons.arrow_forward, color: Colors.white),
        ),
      ),
    );
  }
}

class ElectionSurveyPartylist extends StatefulWidget {
  final Map<String, List<String>> selectedCandidates;

  ElectionSurveyPartylist(this.selectedCandidates);

  @override
  _ElectionSurveyPartylistState createState() => _ElectionSurveyPartylistState();
}

class _ElectionSurveyPartylistState extends State<ElectionSurveyPartylist> {
  List<dynamic> partyLists = [];
  String? selectedPartylist;

  @override
  void initState() {
    super.initState();
    fetchPartyLists();
  }

  Future<void> fetchPartyLists() async {
    final response = await http.get(Uri.parse('https://studentcouncil.bcp-sms1.com/php/fetch_partylist.php'));
    if (response.statusCode == 200) {
      setState(() {
        partyLists = json.decode(response.body);
      });
    }
  }

  void onSubmit() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? studentno = prefs.getString('studentno');

  // Ensure a partylist is selected
  if (selectedPartylist == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Please select a Partylist before submitting'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            title: Text('Confirm Submission'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Are you sure you want to submit your selections?'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  // Dismiss the confirmation dialog
                  Navigator.of(context).pop();

                  // Show loading dialog
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => WillPopScope(
                      onWillPop: () async => false,
                      child: AlertDialog(
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Submitting your selections...'),
                          ],
                        ),
                      ),
                    ),
                  );

                  try {
                    // Perform submissions
                    await submitSurveyData(studentno!);
                    await updatePopularity();

                    // Ensure we're not in the loading dialog before navigating
                    Navigator.of(context, rootNavigator: true).pop();

                    // Fetch survey details and navigate
                    final surveyDetails = await fetchSurveyDetails(studentno);
                    
                    if (surveyDetails['participated'] == true) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ParticipationDetailsPage(
                            selectedCandidates: surveyDetails['selectedCandidates'],
                            selectedPartylist: surveyDetails['selectedPartylist'],
                            participationDate: surveyDetails['participationDate'],
                          ),
                        ),
                      );
                    } else {
                      throw Exception('Survey submission failed');
                    }
                  } catch (e) {
                    // Close any open dialogs
                    Navigator.of(context, rootNavigator: true).pop();

                    // Show error snackbar
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error submitting survey: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: Text('Yes'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('No'),
              ),
            ],
          ),
        );
      },
    ),
  );
}



Future<Map<String, dynamic>> fetchSurveyDetails(String studentno) async {
  try {
    final response = await http.get(
      Uri.parse('https://studentcouncil.bcp-sms1.com/php/check_participation.php?studentno=$studentno'),
    ).timeout(
      Duration(seconds: 10), // Add a timeout
      onTimeout: () {
        throw TimeoutException('Network request timed out');
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> surveyData = json.decode(response.body);

      if (surveyData['participated'] == true) {
        return {
          'participated': true,
          'participationDate': surveyData['participation_date'] ?? DateTime.now().toIso8601String(),
          'selectedCandidates': surveyData['selected_candidates'] ?? [],
          'selectedPartylist': surveyData['selected_partylist'] ?? {},
        };
      } else {
        throw Exception('Survey submission not found');
      }
    } else {
      throw Exception('Failed to fetch survey details: ${response.body}');
    }
  } catch (e) {
    print('Error fetching survey details: $e');
    throw e; // Rethrow to be handled by caller
  }
}



  Future<void> submitSurveyData(String studentno) async {
  List<String> selectedCandidateIds = widget.selectedCandidates.values.expand((x) => x).toList();
  String? selectedPartylistId = selectedPartylist;

  Map<String, dynamic> body = {
    'studentno': studentno,
    'candidates': selectedCandidateIds,
    'partylist': selectedPartylistId,
  };

  try {
    final response = await http.post(
      Uri.parse('https://studentcouncil.bcp-sms1.com/php/submit_survey.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      // Fetch and navigate to details page
      final surveyDetails = await fetchSurveyDetails(studentno);
    
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ParticipationDetailsPage(
            selectedCandidates: surveyDetails['selectedCandidates'],
            selectedPartylist: surveyDetails['selectedPartylist'],
            participationDate: surveyDetails['participationDate'],
          ),
        ),
      );
    } else {
      // Throw an error to be caught in the calling method
      throw Exception('Failed to submit survey: ${response.body}');
    }
  } catch (e) {
    // Rethrow to be handled by the caller
    rethrow;
  }
}

  Future<void> updatePopularity() async {
  List<String> selectedCandidateIds = widget.selectedCandidates.values.expand((x) => x).toList();
  String? selectedPartylistId = selectedPartylist;

  Map<String, dynamic> body = {
    'candidates': selectedCandidateIds,
    'partylist': selectedPartylistId,
  };

  try {
    final response = await http.post(
      Uri.parse('https://studentcouncil.bcp-sms1.com/php/update_popularity.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update popularity: ${response.body}');
    }
  } catch (e) {
    // Rethrow to be handled by the caller
    rethrow;
  }
}

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: Text('Select Partylist')),
        body: partyLists.isEmpty
            ? Center(child: CircularProgressIndicator())
            : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text("This is only a survey, please select the Candidates and Partyist you prefer", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
                  Expanded(
                    child: ListView(
                        children: partyLists.map((party) {
                          return ListTile(
                            title: Text(party['name']),
                            leading: Radio<String>(
                              value: party['id'].toString(),
                              groupValue: selectedPartylist,
                              onChanged: (String? value) {
                                setState(() {
                                  selectedPartylist = value;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                  ),
                ],
              ),
            ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.black,
          onPressed: onSubmit,
          child: Icon(Icons.check, color: Colors.white),
        ),
      ),
    );
  }
}

class ParticipationMessage extends StatelessWidget {
  final String message;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  ParticipationMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
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
                  'Election Survey',
                  style: TextStyle(fontSize: 18, color: Colors.black54),
                ),
                  ],
                ),
              ],
            )
          ),
        ),
        drawer: const AppDrawer(),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Text(message, style: TextStyle(fontSize: 20), textAlign: TextAlign.center,),
          ),
        ),
      ),
    );
  }
}

class ParticipationDetailsPage extends StatelessWidget {
  final List<dynamic> selectedCandidates;
  final dynamic selectedPartylist;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final String participationDate;

  ParticipationDetailsPage({
    required this.selectedCandidates, 
    required this.selectedPartylist,
    required this.participationDate
  });

  @override
  Widget build(BuildContext context) {
    // Group candidates by position
    Map<String, List<dynamic>> candidatesByPosition = {};
    for (var candidate in selectedCandidates) {
      String position = candidate['position'] ?? 'Unknown';
      if (!candidatesByPosition.containsKey(position)) {
        candidatesByPosition[position] = [];
      }
      candidatesByPosition[position]!.add(candidate);
    }

    return SafeArea(
      child: Scaffold(
        key: _scaffoldKey,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            height: 56,
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
                      'Participation Details',
                      style: TextStyle(fontSize: 18, color: Colors.black54),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildProfileMenu(context)
                  ],
                )
              ],
            ),
          ),
        ),
        drawer: const AppDrawer(),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Selected Partylist Section
              Column(
                children: [
                  Text(
                      'Your Election Survey Selections',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'Selected Partylist:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              ListTile(
                title: Text(selectedPartylist['name'] ?? 'No Partylist Selected'),
                leading: Icon(Icons.flag),
              ),
                ],
              ),
              Expanded(
                child: Column(
                  // mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // SizedBox(height: 16),
                    
                    // Selected Candidates Section
                    Text(
                      'Selected Candidates:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    Expanded(
                      child: ListView(
                        children: candidatesByPosition.entries.map((entry) {
                          String position = entry.key;
                          List<dynamic> positionCandidates = entry.value;
                
                          return ExpansionTile(
                            title: Text(
                              position, 
                              style: TextStyle(
                                fontSize: 16, 
                                fontWeight: FontWeight.bold
                              )
                            ),
                            children: positionCandidates.map((candidate) {
                              return ListTile(
                                // leading: CircleAvatar(
                                  
                                //   child: Icon(Icons.person),
                                // ),
                                title: Text('${candidate['firstname']} ${candidate['lastname']}'),
                                subtitle: Text('Party: ${candidate['partylist']}'),
                              );
                            }).toList(),
                          );
                        }).toList(),
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
}


String _formatDate(String dateString) {
    try {
      DateTime dateTime = DateTime.parse(dateString);
      return DateFormat('MMMM d, yyyy at h:mm a').format(dateTime);
    } catch (e) {
      return dateString; // Return original string if parsing fails
    }
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
  
