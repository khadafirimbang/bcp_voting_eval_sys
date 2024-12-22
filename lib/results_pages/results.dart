import 'dart:convert';
import 'package:flutter/material.dart';
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
  String selectedPosition = 'All';  // Default position filter

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

    return Scaffold(
      appBar: AppBar(
        title: Text('Election Results'),
        actions: [
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Voters: $totalVoters',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Total Voted: $totalVoted',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Total Not Voted Yet: $totalNotVoted',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      Text(
                        entry.key, // Position name (e.g., President, Vice President)
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 8.0,
                          mainAxisSpacing: 8.0,
                          // Removed childAspectRatio to let height fit content
                        ),
                        itemCount: entry.value.length,
                        itemBuilder: (context, index) {
                          var candidate = entry.value[index];

                          // Calculate the percentage of votes for this candidate
                          int percentage = totalPositionVotes > 0
                              ? ((candidate['total_votes'] / totalPositionVotes) * 100).toInt()
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
                                Text('$percentage%'),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
