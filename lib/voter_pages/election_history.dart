import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:for_testing/voter_pages/election_results_page.dart';
import 'package:http/http.dart' as http;

class ElectionHistory extends StatefulWidget {
  @override
  _ElectionHistoryState createState() => _ElectionHistoryState();
}

class _ElectionHistoryState extends State<ElectionHistory> {
  late Future<List<dynamic>> _electionList;

  Future<List<dynamic>> fetchEndedElections() async {
    final response = await http.get(Uri.parse('https://studentcouncil.bcp-sms1.com/php/fetch_ended_elections.php'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load elections');
    }
  }

  @override
  void initState() {
    super.initState();
    _electionList = fetchEndedElections();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: Text('Election History')),
        body: FutureBuilder<List<dynamic>>(
          future: _electionList,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('No ended elections found.'));
            }
      
            final elections = snapshot.data!;
            return ListView.builder(
              itemCount: elections.length,
              itemBuilder: (context, index) {
                final election = elections[index];
                return ListTile(
                  title: Text(election['election_name']),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ElectionResultsPage(
                          electionId: election['id'].toString(),
                          electionName: election['election_name'],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
