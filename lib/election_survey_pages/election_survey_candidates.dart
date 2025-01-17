import 'package:flutter/material.dart';
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

    return Scaffold(
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
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
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
      floatingActionButton: FloatingActionButton(
        onPressed: onNext,
        child: Icon(Icons.arrow_forward),
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
    return Scaffold(
      appBar: AppBar(title: Text('Select Partylist')),
      body: partyLists.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView(
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
      floatingActionButton: FloatingActionButton(
        onPressed: onSubmit,
        child: Icon(Icons.check),
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
    return Scaffold(
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
      body: Center(
        child: Text(message, style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
