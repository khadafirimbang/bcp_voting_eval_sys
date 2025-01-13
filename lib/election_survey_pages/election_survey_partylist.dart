import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ElectionSurveyPartylist extends StatefulWidget {
  final Map<String, List<Map<String, dynamic>>> selectedCandidates;

  ElectionSurveyPartylist({required this.selectedCandidates});

  @override
  _ElectionSurveyPartylistState createState() => _ElectionSurveyPartylistState();
}

class _ElectionSurveyPartylistState extends State<ElectionSurveyPartylist> {
  List<Map<String, dynamic>> partylists = [];
  Map<String, dynamic>? selectedPartylist;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPartylists();
  }

  Future<void> fetchPartylists() async {
    try {
      final response = await http.get(
        Uri.parse('http://your-domain.com/get_partylists.php'),
      );

      if (response.statusCode == 200) {
        setState(() {
          partylists = List<Map<String, dynamic>>.from(
            json.decode(response.body),
          );
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching partylists: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> submitSurvey() async {
    if (selectedPartylist == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Selection Required'),
          content: Text('Please select a partylist before submitting.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Submission'),
        content: Text('Are you sure you want to submit your selections?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Submit'),
          ),
        ],
      ),
    );

    if (confirm) {
      try {
        final response = await http.post(
          Uri.parse('http://your-domain.com/submit_survey.php'),
          body: json.encode({
            'candidates': widget.selectedCandidates,
            'partylist': selectedPartylist,
          }),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Success'),
              content: Text('Your survey has been submitted successfully.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Navigate back to home or previous screen
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  child: Text('OK'),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        print('Error submitting survey: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Select Partylist'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: partylists.length,
              itemBuilder: (context, index) {
                final partylist = partylists[index];
                return Card(
                  color: selectedPartylist == partylist
                      ? Colors.blue.shade100
                      : null,
                  child: ListTile(
                    title: Text(partylist['name']),
                    onTap: () {
                      setState(() {
                        selectedPartylist = partylist;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: submitSurvey,
              child: Text('Submit'),
            ),
          ),
        ],
      ),
    );
  }
}