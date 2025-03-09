import 'package:SSCVote/voter_pages/vote.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SelectedCandidatesPage extends StatefulWidget {
  final List<dynamic> selectedCandidates;
  final Function(List<dynamic>) onCandidatesUpdated;

  const SelectedCandidatesPage({
    Key? key,
    required this.selectedCandidates,
    required this.onCandidatesUpdated,
  }) : super(key: key);

  @override
  _SelectedCandidatesPageState createState() => _SelectedCandidatesPageState();
}

class _SelectedCandidatesPageState extends State<SelectedCandidatesPage> {
  late List<dynamic> selectedCandidates;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    selectedCandidates = List.from(widget.selectedCandidates);
  }

  void _removeCandidate(dynamic candidate) {
    setState(() {
      selectedCandidates.removeWhere(
        (c) => c['studentno'] == candidate['studentno']
      );
    });
    // Notify the parent about the updated list
    widget.onCandidatesUpdated(selectedCandidates);
  }

  Future<void> _voteSelectedCandidates() async {
    setState(() {
      _isLoading = true; // Start loading
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? studentNo = prefs.getString('studentno');

    bool allVotesSuccessful = true;
    List<String> errorMessages = [];

    for (var candidate in selectedCandidates) {
      try {
        final response = await http.post(
          Uri.parse('https://studentcouncil.bcp-sms1.com/php/1vote_candidate.php'),
          body: {
            'studentno': studentNo,
            'candidate_id': candidate['studentno'].toString(),
            'position': candidate['position'],
          },
        );

        final result = json.decode(response.body);

        if (!result['success']) {
          allVotesSuccessful = false;
          errorMessages.add(result['message']);
        }
      } catch (e) {
        allVotesSuccessful = false;
        errorMessages.add('Error voting for ${candidate['firstname']} ${candidate['lastname']}: $e');
      }
    }

    setState(() {
      _isLoading = false; // Stop loading
    });

    if (allVotesSuccessful) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All selected candidates voted successfully!')),
      );
      // Navigator.pop(context, true); // Return to previous page
      Navigator.push(context, MaterialPageRoute(builder: (context) => VotePage()), );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: errorMessages.map((msg) => Text(msg)).toList(),
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _showConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevent dialog from closing on outside tap
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Vote'),
          content: const Text('Are you sure you want to vote for the selected candidates?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _voteSelectedCandidates(); // Proceed with voting
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selected Candidates'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: selectedCandidates.length,
              itemBuilder: (context, index) {
                var candidate = selectedCandidates[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: candidate['img'] != null && candidate['img'].isNotEmpty
                      ? MemoryImage(base64Decode(
                          candidate['img']
                            .replaceAll(RegExp(r'data:image/[^;]+;base64,'), '')
                            .replaceAll('\n', '')
                            .replaceAll('\r', '')
                            .trim()
                        ))
                      : const AssetImage('assets/bcp_logo.png') as ImageProvider,
                  ),
                  title: Text('${candidate['firstname']} ${candidate['lastname']}'),
                  subtitle: Text('Position: ${candidate['position']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () => _removeCandidate(candidate),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
              ),
              onPressed: _isLoading || selectedCandidates.isEmpty
                  ? null // Disable button when loading or no candidates
                  : _showConfirmationDialog, // Show confirmation dialog
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Vote ${selectedCandidates.length} Selected Candidate(s)',
                          style: const TextStyle(color: Colors.white),),
            ),
          ),
        ],
      ),
    );
  }
}
