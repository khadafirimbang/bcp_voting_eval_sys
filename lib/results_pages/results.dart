import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:for_testing/voter_pages/drawerbar.dart';
import 'package:for_testing/voter_pages/election_history.dart';
import 'package:http/http.dart' as http;

class ResultsPage extends StatefulWidget {
  @override
  _ResultsPageState createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  List<dynamic> candidates = [];
  int totalVoters = 0;
  int totalVoted = 0;
  int totalNotVoted = 0;
  String selectedPosition = 'All'; // Default position filter
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Fetch data from the PHP backend
  Future<void> fetchResults() async {
    final response = await http.get(Uri.parse('https://studentcouncil.bcp-sms1.com/php/results.php'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        candidates = data['candidates'];
        totalVoters = data['total_voters'];
        totalVoted = data['total_voted'];
        totalNotVoted = totalVoters - totalVoted;
      });
    } else {
      throw Exception('Failed to load results');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchResults();
  }

  @override
  Widget build(BuildContext context) {
    // Filter candidates by selected position
    List<dynamic> filteredCandidates = selectedPosition == 'All'
        ? candidates
        : candidates.where((candidate) => candidate['position'] == selectedPosition).toList();

    // Get unique positions for the dropdown filter
    Set<String> positions = {'All'};
    for (var candidate in candidates) {
      positions.add(candidate['position']);
    }

    // Calculate the number of cards per row based on screen size
    int crossAxisCount;
    double screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth >= 1200) {
      crossAxisCount = 5; // Laptop/PC
    } else if (screenWidth >= 800) {
      crossAxisCount = 3; // Tablet/iPad
    } else {
      crossAxisCount = 1; // Mobile phone
    }

    // Group candidates by position
    Map<String, List<dynamic>> groupedCandidates = {};
    for (var candidate in filteredCandidates) {
      if (!groupedCandidates.containsKey(candidate['position'])) {
        groupedCandidates[candidate['position']] = [];
      }
      groupedCandidates[candidate['position']]!.add(candidate);
    }

    // Calculate percentages for overall stats
    double votedPercentage = totalVoters > 0 ? (totalVoted / totalVoters) * 100 : 0;
    double notVotedPercentage = totalVoters > 0 ? (totalNotVoted / totalVoters) * 100 : 0;

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
                  'Election Results',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                  ],
                ),
                Row(
                  children: [
                    DropdownButton<String>(
                      value: selectedPosition,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedPosition = newValue!;
                        });
                      },
                      items: positions.map<DropdownMenuItem<String>>((String position) {
                        return DropdownMenuItem<String>(
                          value: position,
                          child: Text(position),
                        );
                      }).toList(),
                    ),
                  ],
                )
              ],
            )
          ),
        ),
        drawer: const AppDrawer(),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              
              Card(
                elevation: 2,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 60),
                  child: Column(
                    children: [
                      SizedBox(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.all(10.0),
                            backgroundColor: Colors.black,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ElectionHistory()),
                            );
                          },
                          child: const Text(
                            'Election History',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Voters: $totalVoters - 100%',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Voted: $totalVoted - ${votedPercentage.toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Not Voted Yet: $totalNotVoted - ${notVotedPercentage.toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: groupedCandidates.entries.map((entry) {
                    // Calculate total votes for this position
                    int totalPositionVotes = entry.value.fold<int>(0, (sum, candidate) {
                      return sum + (candidate['total_votes'] as int);
                    });
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 10),
                        ExpansionTile(
                          collapsedShape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.zero,
                                  ),
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.zero,
                                  ),
                                  title: Text(entry.key),
                          children: [
                            GridView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 8.0,
                              mainAxisSpacing: 8.0,
                            ),
                            itemCount: entry.value.length,
                            itemBuilder: (context, index) {
                              var candidate = entry.value[index];
                          
                              // Calculate the percentage of votes for this candidate based on total voters
                              double percentage = totalVoters > 0
                                  ? (candidate['total_votes'] / totalVoters) * 100
                                  : 0;
                          
                              return Card(
                                elevation: 5,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min, // Ensure the Column height fits the content
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
                                    SizedBox(height: 8),
                                    Text(
                                      '${candidate['lastname']}, ${candidate['firstname']}',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text('Position: ${candidate['position']}'),
                                    Text('${candidate['total_votes']} votes'),
                                    SizedBox(
                                      width: double.infinity,
                                      child: LinearProgressIndicator(
                                        value: percentage / 100,
                                        backgroundColor: Colors.grey[300],
                                        color: Colors.blue,
                                      ),
                                    ),
                                    Text('${percentage.toStringAsFixed(2)}%'), // Display the percentage with two decimal places
                                  ],
                                ),
                              );
                            },
                          ),
                          ],
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
