import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ElectionAuditPage extends StatefulWidget {
  @override
  _ElectionAuditPageState createState() => _ElectionAuditPageState();
}

class _ElectionAuditPageState extends State<ElectionAuditPage> {
  List<dynamic> votedCandidates = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchVotedCandidates();
  }

  Future<void> fetchVotedCandidates() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? studentNo = prefs.getString('studentno');

    if (studentNo == null) {
      setState(() {
        errorMessage = 'No student number found';
        isLoading = false;
      });
      return;
    }
    
    try {
      final response = await http.get(
        Uri.parse('https://studentcouncil.bcp-sms1.com/php/fetch_voted_candidates.php?studentno=$studentNo')
      );

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          setState(() {
            votedCandidates = data['voted_candidates'] ?? [];
            isLoading = false;
          });
        } catch (parseError) {
          setState(() {
            errorMessage = 'JSON Parsing Error: $parseError\n${response.body}';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'HTTP Error: ${response.statusCode}\n${response.body}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Network Error: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text('Election Audit'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: isLoading 
          ? Center(child: CircularProgressIndicator())
          : errorMessage != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 60),
                    SizedBox(height: 16),
                    Text(
                      errorMessage!,
                      style: TextStyle(fontSize: 18, color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : votedCandidates.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.how_to_vote_outlined, color: Colors.grey, size: 60),
                      SizedBox(height: 16),
                      Text(
                        'No votes cast yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                ],
              ),
            )
            : CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          var candidate = votedCandidates[index];
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 5),
                            child: Card(
                              elevation: 4,
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, 
                                  vertical: 8
                                ),
                                leading: CircleAvatar(
                                  radius: 30,
                                  backgroundImage: candidate['img'] != null && candidate['img'].isNotEmpty
                                    ? MemoryImage(base64Decode(
                                        candidate['img']
                                          .replaceAll(RegExp(r'data:image/[^;]+;base64,'), '')
                                          .replaceAll('\n', '')
                                          .replaceAll('\r', '')
                                          .trim()
                                      ))
                                    : AssetImage('assets/bcp_logo.png') as ImageProvider,
                                ),
                                title: Text(
                                  '${candidate['firstname']} ${candidate['lastname']}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Position: ${candidate['position']}',
                                      style: TextStyle(color: Colors.grey[700]),
                                    ),
                                    if (candidate['partylist'] != null)
                                      Text(
                                        'Party: ${candidate['partylist']}',
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                  ],
                                ),
                                trailing: Icon(
                                  Icons.check_circle, 
                                  color: Colors.green,
                                  size: 30,
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: votedCandidates.length,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
