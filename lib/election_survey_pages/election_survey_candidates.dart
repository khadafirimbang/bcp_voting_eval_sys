import 'package:flutter/material.dart';
import 'package:for_testing/main.dart';
import 'package:for_testing/voter_pages/announcement.dart';
import 'package:for_testing/voter_pages/drawerbar.dart';
import 'package:http/http.dart' as http;
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

    final response = await http.get(Uri.parse('https://studentcouncil.bcp-sms1.com/php/check_participation.php?studentno=$studentno'));
    if (response.statusCode == 200 && json.decode(response.body)['participated']) {
      // User has already participated
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ParticipationMessage(message: 'You already participated in the election survey.')),
      );
    } else {
      // User has not participated, fetch candidates and votes quantity
      fetchCandidates();
      fetchVotesQty();
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
                  Text("This is only a survey, please select the Candidates and Partyist you prefer", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
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
                                leading: CircleAvatar(
                                  backgroundImage: NetworkImage(candidate['image_url'] ?? ''),
                                  child: candidate['image_url'] == null ? Icon(Icons.person) : null,
                                ),
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
          onPressed: onNext,
          child: Icon(Icons.arrow_forward),
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

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Confirm Submission'),
      content: Text('Are you sure you want to submit your selections?'),
      actions: [
        TextButton(
          onPressed: () async {
            await submitSurveyData(studentno!);
            await updatePopularity();
            Navigator.of(context).pop();
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
}

  Future<void> submitSurveyData(String studentno) async {
    List<String> selectedCandidateIds = widget.selectedCandidates.values.expand((x) => x).toList();
    String? selectedPartylistId = selectedPartylist;

    Map<String, dynamic> body = {
      'studentno': studentno,
      'candidates': selectedCandidateIds,
      'partylist': selectedPartylistId,
    };

    final response = await http.post(
      Uri.parse('https://studentcouncil.bcp-sms1.com/php/submit_survey.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ParticipationMessage(message: 'Thank you for participating in our survey.')),
      );
    } else {
      print('Failed to submit survey: ${response.body}');
    }
  }

  Future<void> updatePopularity() async {
    List<String> selectedCandidateIds = widget.selectedCandidates.values.expand((x) => x).toList();
    String? selectedPartylistId = selectedPartylist;

    Map<String, dynamic> body = {
      'candidates': selectedCandidateIds,
      'partylist': selectedPartylistId,
    };

    final response = await http.post(
      Uri.parse('https://studentcouncil.bcp-sms1.com/php/update_popularity.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      print('Popularity updated successfully');
    } else {
      print('Failed to update popularity: ${response.body}');
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
          onPressed: onSubmit,
          child: Icon(Icons.check),
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

Widget _buildProfileMenu(BuildContext context) {
    return PopupMenuButton<int>(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onSelected: (item) {
        switch (item) {
          case 0:
            // Navigate to Profile page
            // Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage()));
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
