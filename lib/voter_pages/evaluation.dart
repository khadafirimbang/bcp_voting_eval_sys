import 'dart:convert';
import 'package:SSCVote/voter_pages/profile.dart';
import 'package:flutter/material.dart';
import 'package:SSCVote/main.dart';
import 'package:SSCVote/voter_pages/announcement.dart';
import 'package:SSCVote/voter_pages/chatbot.dart';
import 'package:SSCVote/voter_pages/drawerbar.dart';
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = true; // Add loading state
  bool _isSubmittingEvaluation = false;

  @override
  void initState() {
    super.initState();
    _getStudentNo();
    _initializeData();
  }

  // Consolidated initialization method
  Future<void> _initializeData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get student number first
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        studentno = prefs.getString('studentno');
      });

      // Fetch data concurrently
      await Future.wait([
        _fetchSurveyQuestions(),
        _fetchFeedbackQuestions(),
        _checkSubmissionStatus()
      ]);
    } catch (e) {
      print('Initialization error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load data: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fetch Survey questions
  Future<void> _fetchSurveyQuestions() async {
    try {
      var url = Uri.parse('https://studentcouncil.bcp-sms1.com/php/fetch_evaluation.php?type=Survey');
      var response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          surveyQuestions = json.decode(response.body);
        });
      } else {
        throw Exception('Failed to fetch survey questions');
      }
    } catch (e) {
      print('Survey Questions Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading survey questions: $e')),
      );
    }
  }

  // Fetch Feedback questions
  Future<void> _fetchFeedbackQuestions() async {
    try {
      var url = Uri.parse('https://studentcouncil.bcp-sms1.com/php/fetch_evaluation.php?type=Feedback');
      var response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          feedbackQuestions = json.decode(response.body);
        });
      } else {
        throw Exception('Failed to fetch feedback questions');
      }
    } catch (e) {
      print('Feedback Questions Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading feedback questions: $e')),
      );
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

    try {
      var url = Uri.parse('https://studentcouncil.bcp-sms1.com/php/check_submission_status.php?studentno=$studentno');
      var response = await http.get(url);

      if (response.statusCode == 200) {
        var result = json.decode(response.body);
        setState(() {
          _isSubmitted = result['submitted'] == 1;
        });
      } else {
        throw Exception('Failed to check submission status');
      }
    } catch (e) {
      print('Submission Status Error: $e');
      setState(() {
        _isSubmitted = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator if data is being fetched
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Loading Evaluation...'),
            ],
          ),
        ),
      );
    }
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
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
                'Evaluation',
                style: TextStyle(fontSize: 18, color: Colors.black54),
              ),
                ],
              ),
              Row(
                children: [
                  _buildProfileMenu(context)
                ],
              )
            ],
          )
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
                    elevation: 2,
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
      backgroundColor: _isSubmittingEvaluation ? Colors.grey : Colors.black,
    ),
    onPressed: _isSubmitted || _isSubmittingEvaluation ? null : _submitEvaluation,
    child: _isSubmittingEvaluation
        ? SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : const Text(
            'Submit', 
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => ChatbotScreen()),
            );
          },
          child: Icon(Icons.chat_outlined),
        ),
      ),
    );
  }

  // Function to handle form submission
  Future<void> _submitEvaluation() async {
    // Prevent multiple submissions
    if (_isSubmittingEvaluation) return;

    if (studentno == null) {
      print('Student number not found.');
      return;
    }

    // Validate Survey Responses
    bool isSurveyComplete = surveyQuestions.every((question) {
      return surveyResponses.containsKey(question['id']) && 
            surveyResponses[question['id']] != null && 
            surveyResponses[question['id']]!.isNotEmpty;
    });

    // Validate Feedback Responses
    bool isFeedbackComplete = feedbackQuestions.every((question) {
      return feedbackResponses.containsKey(question['id']) && 
            feedbackResponses[question['id']] != null && 
            feedbackResponses[question['id']]!.trim().isNotEmpty;
    });

    // Check if all questions are answered
    if (!isSurveyComplete || !isFeedbackComplete) {
      // Show an error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Incomplete Evaluation'),
          content: Text('Please answer all survey and feedback questions before submitting.'),
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

    // Set submission state
    setState(() {
      _isSubmittingEvaluation = true;
    });

    try {
      // Convert responses to JSON
      String feedbackResponsesJson = json.encode(feedbackResponses.map((key, value) => MapEntry(key.toString(), value)));
      String surveyResponsesJson = json.encode(surveyResponses.map((key, value) => MapEntry(key.toString(), value)));

      // Send data to the backend
      var url = Uri.parse('https://studentcouncil.bcp-sms1.com/php/submit_evaluation.php');
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully submitted!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Show failure Snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Handle any network or unexpected errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Always reset submission state
      setState(() {
        _isSubmittingEvaluation = false;
      });
    }
  }
}

Widget _buildProfileMenu(BuildContext context) {
    return PopupMenuButton<int>(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onSelected: (item) {
        switch (item) {
          case 0:
            // Navigate to Profile page
            Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileInfoPage()));
            break;
          case 1:
            // Handle sign out
            _logout(context); // Example action for Sign Out
            break;
        }
      },
      offset: Offset(0, 50), // Adjust dropdown position
      itemBuilder: (context) => [
        PopupMenuItem<int>(
          padding: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
          value: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Signed in as', style: TextStyle(color: Colors.black54)),
              Text(studentNo ?? 'Unknown'),
            ],
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem<int>(
          value: 0,
          child: Row(
            children: [
              Icon(Icons.person, color: Colors.black54),
              SizedBox(width: 10),
              Text('Profile'),
            ],
          ),
        ),
        PopupMenuItem<int>(
          value: 1,
          child: Row(
            children: [
              Icon(Icons.logout, color: Colors.black54),
              SizedBox(width: 10),
              Text('Sign out'),
            ],
          ),
        ),
      ],
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: Colors.black54),
          ),
        ],
      ),
    );
  }
  
  void _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!context.mounted) return; // Ensure the widget is still mounted

    // Use pushAndRemoveUntil to clear the navigation stack
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoadingScreen()), // Replace with your login page
      (Route<dynamic> route) => false, // Remove all previous routes
    );
  }
