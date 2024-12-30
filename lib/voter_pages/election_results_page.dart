import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ElectionResultsPage extends StatelessWidget {
  final String electionId;
  final String electionName;

  ElectionResultsPage({required this.electionId, required this.electionName});

  Future<Map<String, dynamic>> fetchElectionResults() async {
    final response = await http.get(Uri.parse(
        'https://studentcouncil.bcp-sms1.com/php/fetch_election_results.php?election_id=$electionId'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load election results');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Results: $electionName')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchElectionResults(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No results found.'));
          }

          final results = snapshot.data!;
          return ListView(
            children: results.entries.map((entry) {
              final position = entry.key;
              final candidates = entry.value as List<dynamic>;

              // Calculate the total votes for this position
              final totalVotes = candidates.fold<int>(
                0,
                (sum, candidate) => sum + (candidate['total_votes'] as int),
              );

              return ExpansionTile(
                title: Text(position),
                children: candidates.map((candidate) {
                  final votes = candidate['total_votes'] as int;
                  final percentage = totalVotes > 0
                      ? (votes / totalVotes)
                      : 0.0;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text(
                          '${candidate['firstname']} ${candidate['lastname']}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Rank: ${candidate['rank']} | Votes: $votes (${(percentage * 100).toStringAsFixed(1)}%)'),
                          SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: percentage,
                            minHeight: 10,
                            backgroundColor: Colors.grey[300],
                            color: Colors.blue,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
