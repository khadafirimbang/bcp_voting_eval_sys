import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:for_testing/voter_pages/drawerbar.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EvaluationPage extends StatefulWidget {
  const EvaluationPage({super.key});

  @override
  _EvaluationPageState createState() => _EvaluationPageState();
}

class _EvaluationPageState extends State<EvaluationPage> {
  List surveyQuestions = [];
  List feedbackQuestions = [];
  Map<int, String> feedbackResponses = {};
  Map<int, String> surveyResponses = {};
  String? studentno;
  bool _isSubmitted = false; // Track submission status

  @override
  void initState() {
    super.initState();
    _fetchSurveyQuestions();
    _fetchFeedbackQuestions();
    _getStudentNo();
  }

  // Fetch Survey questions
  Future<void> _fetchSurveyQuestions() async {
    var url = Uri.parse('http://192.168.1.6/for_testing/fetch_evaluation.php?type=Survey');
    var response = await http.get(url);

    if (response.statusCode == 200) {
      setState(() {
        surveyQuestions = json.decode(response.body);
      });
    } else {
      print('Failed to fetch survey questions');
    }
  }

  // Fetch Feedback questions
  Future<void> _fetchFeedbackQuestions() async {
    var url = Uri.parse('http://192.168.1.6/for_testing/fetch_evaluation.php?type=Feedback');
    var response = await http.get(url);

    if (response.statusCode == 200) {
      setState(() {
        feedbackQuestions = json.decode(response.body);
      });
    } else {
      print('Failed to fetch feedback questions');
    }
  }

  // Get student number from SharedPreferences
  Future<void> _getStudentNo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      studentno = prefs.getString('studentno');
    });
    _checkSubmissionStatus(); // Check if already submitted
  }

  // Check submission status from backend
  Future<void> _checkSubmissionStatus() async {
    if (studentno == null) return;

    var url = Uri.parse('http://192.168.1.6/for_testing/check_submission_status.php?studentno=$studentno');
    var response = await http.get(url);

    if (response.statusCode == 200) {
      var result = json.decode(response.body);
      setState(() {
        _isSubmitted = result['submitted'] == 1;
      });
    } else {
      print('Failed to check submission status');
      setState(() {
        _isSubmitted = false; // Default to not submitted if query fails
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        title: const Text('Evaluation', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(
          color: Colors.white, // Change the color of the Drawer icon here
        ),
      ),
      drawer: const AppDrawer(),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                double cardWidth;
                double screenWidth = MediaQuery.of(context).size.width;

                // Adjust card width based on screen width
                if (screenWidth > 1200) {
                  cardWidth = 1200; // Large screens (Desktop)
                } else if (screenWidth > 800) {
                  cardWidth = 600; // Medium screens (Tablet)
                } else {
                  cardWidth = screenWidth * 0.9; // Small screens (Mobile)
                }

                return Card(
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: cardWidth, // Set the width dynamically
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 20),
                              if (_isSubmitted)
                              Container(
                                decoration: BoxDecoration(
                                      border: Border.all(color: Colors.green, width: 1),
                                    ),
                                child: const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'You already answered the evaluation.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.green,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Rating scale with responsive design
                              Wrap(
                                alignment: WrapAlignment.center,
                                children: [
                                  Container(
                                    width: 200,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.black, width: 1),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                                      child: Text('5 - Outstanding', style: TextStyle(fontSize: screenWidth > 600 ? 16 : 14)),
                                    ),
                                  ),
                                  Container(
                                    width: 200,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.black, width: 1),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                                      child: Text('4 - Very Satisfactory', style: TextStyle(fontSize: screenWidth > 600 ? 16 : 14)),
                                    ),
                                  ),
                                  Container(
                                    width: 200,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.black, width: 1),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                                      child: Text('3 - Satisfactory', style: TextStyle(fontSize: screenWidth > 600 ? 16 : 14)),
                                    ),
                                  ),
                                  Container(
                                    width: 200,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.black, width: 1),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                                      child: Text('2 - Fairly Satisfactory', style: TextStyle(fontSize: screenWidth > 600 ? 16 : 14)),
                                    ),
                                  ),
                                  Container(
                                    width: 200,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.black, width: 1),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                                      child: Text('1 - Unsatisfactory', style: TextStyle(fontSize: screenWidth > 600 ? 16 : 14)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Survey Questions',
                                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 10),
                              // Survey Questions List
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight: constraints.maxHeight - 200, // Adjust height as needed
                                ),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  physics: const ClampingScrollPhysics(), // Avoid conflicts with ConstrainedBox
                                  itemCount: surveyQuestions.length,
                                  itemBuilder: (context, index) {
                                    var question = surveyQuestions[index];
                                    return Column(
                                      children: [
                                        ListTile(
                                          title: Text(question['question']),
                                          trailing: DropdownButton<String>(
                                            value: _isSubmitted ? null : surveyResponses[question['id']],
                                            items: ['1', '2', '3', '4', '5'].map((String value) {
                                              return DropdownMenuItem<String>(
                                                value: value,
                                                child: Text(value),
                                              );
                                            }).toList(),
                                            onChanged: _isSubmitted ? null : (value) {
                                              setState(() {
                                                surveyResponses[question['id']] = value ?? '';
                                              });
                                            },
                                            hint: const Text('Rate (1-5)'),
                                          ),
                                        ),
                                        const Divider(), // Divider added here
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                        
                      const SizedBox(height: 20),
                        
                      // Feedback Questions
                      SizedBox(
                        width: cardWidth, // Set the width dynamically
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'Feedback Questions',
                                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 10),
                              // Feedback Questions List
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight: constraints.maxHeight - 200, // Adjust height as needed
                                ),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  physics: const ClampingScrollPhysics(), // Avoid conflicts with ConstrainedBox
                                  itemCount: feedbackQuestions.length,
                                  itemBuilder: (context, index) {
                                    var question = feedbackQuestions[index];
                                    return ListTile(
                                      title: Text(question['question']),
                                      subtitle: TextField(
                                        maxLines: 3,
                                        onChanged: _isSubmitted ? null : (value) {
                                          feedbackResponses[question['id']] = value;
                                        },
                                        decoration: const InputDecoration(
                                          hintText: 'Enter your feedback (up to 3 sentences)',
                                          border: OutlineInputBorder(),
                                        ),
                                        enabled: !_isSubmitted, // Disable field if submitted
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                        
                      const SizedBox(height: 20),
                        
                      // Submit button
                      SizedBox(
                        width: 340,
                        child: TextButton(
                              style: TextButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.all(14.0),
                                backgroundColor: const Color(0xFF1E3A8A),
                              ),
                              onPressed: _isSubmitted ? null : _submitEvaluation,
                              child: const Text('Submit', 
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // Function to handle form submission
  Future<void> _submitEvaluation() async {
    if (studentno == null) {
      print('Student number not found.');
      return;
    }

    // Convert responses to JSON
    String feedbackResponsesJson = json.encode(feedbackResponses.map((key, value) => MapEntry(key.toString(), value)));
    String surveyResponsesJson = json.encode(surveyResponses.map((key, value) => MapEntry(key.toString(), value)));

    // Send data to the backend
    var url = Uri.parse('http://192.168.1.6/for_testing/submit_evaluation.php');
    var response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'studentno': studentno,
        'feedback_responses': feedbackResponsesJson,
        'survey_responses': surveyResponsesJson,
      }),
    );

    if (response.statusCode == 200) {
      // Set the submission status to true
      setState(() {
        _isSubmitted = true;
      });

      // Show success Snackbar
      final snackBar = const SnackBar(
        content: Text('Successfully submitted!'),
        backgroundColor: Colors.green,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } else {
      // Show failure Snackbar
      final snackBar = const SnackBar(
        content: Text('Failed to submit!'),
        backgroundColor: Colors.red,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }
}
