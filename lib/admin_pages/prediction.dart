import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Election Prediction',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ElectionPredictionPage(),
    );
  }
}

class Candidate {
  final String studentno;
  final String name;
  final double predictedVotes;

  Candidate({
    required this.studentno,
    required this.name,
    required this.predictedVotes,
  });

  factory Candidate.fromJson(Map<String, dynamic> json) {
    return Candidate(
      studentno: json['studentno'].toString(),
      name: json['name'].toString(),
      predictedVotes: json['predicted_votes']?.toDouble() ?? 0.0, // Ensure default value for null
    );
  }
}

class ElectionPredictionPage extends StatefulWidget {
  @override
  _ElectionPredictionPageState createState() => _ElectionPredictionPageState();
}

class _ElectionPredictionPageState extends State<ElectionPredictionPage> {
  late Future<Map<String, List<Candidate>>> candidatesByPosition;

  Future<Map<String, List<Candidate>>> fetchCandidates() async {
    final response = await http.get(
      Uri.parse('https://studentcouncil.bcp-sms1.com/php/fetch_election_data.php'),
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = json.decode(response.body);
      Map<String, List<Candidate>> candidatesByPosition = {};

      jsonResponse.forEach((position, candidatesData) {
        candidatesByPosition[position] = (candidatesData as List)
            .map((candidate) => Candidate.fromJson(candidate))
            .toList();

        // Sort candidates by predicted votes in descending order
        candidatesByPosition[position]!.sort((a, b) => b.predictedVotes.compareTo(a.predictedVotes));
      });

      return candidatesByPosition;
    } else {
      throw Exception('Failed to load candidates');
    }
  }

  @override
  void initState() {
    super.initState();
    candidatesByPosition = fetchCandidates();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Election Prediction'),
      ),
      body: FutureBuilder<Map<String, List<Candidate>>>(  // Fetch candidates data
        future: candidatesByPosition,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No candidates available.'));
          } else {
            final candidatesByPosition = snapshot.data!;

            return ListView.builder(
              itemCount: candidatesByPosition.keys.length,
              itemBuilder: (context, index) {
                String position = candidatesByPosition.keys.elementAt(index);
                List<Candidate> candidates = candidatesByPosition[position]!;

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ExpansionTile(
                    title: Text('$position'),
                    children: candidates.map((candidate) {
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            candidate.name.isNotEmpty ? candidate.name[0] : '?',
                          ),
                        ),
                        title: Text(candidate.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Predicted Votes: ${candidate.predictedVotes.toStringAsFixed(2)}%'),
                            SizedBox(height: 8),
                            // Horizontal bar graph
                            LinearProgressIndicator(
                              value: candidate.predictedVotes / 100, // Normalize to 0-1 range
                              minHeight: 8, // Height of the bar
                              color: Colors.blue, // Bar color
                              backgroundColor: Colors.grey[300], // Background color
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
