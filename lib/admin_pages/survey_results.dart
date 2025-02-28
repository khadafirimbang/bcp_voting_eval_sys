import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:SSCVote/admin_pages/dashboard2.dart';
import 'package:SSCVote/admin_pages/drawerbar_admin.dart';
import 'package:SSCVote/admin_pages/feedback_results.dart';
import 'package:SSCVote/main.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SurveyResponseGraph extends StatelessWidget {
  final String question;
  final List<Map<String, dynamic>> responses;

  const SurveyResponseGraph({
    Key? key,
    required this.question,
    required this.responses,
  }) : super(key: key);

  Map<int, int> _calculateResponseFrequency() {
    Map<int, int> frequency = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (var response in responses) {
      int rating = int.parse(response['response'].toString());
      frequency[rating] = (frequency[rating] ?? 0) + 1;
    }
    return frequency;
  }

  @override
  Widget build(BuildContext context) {
    final responseFrequency = _calculateResponseFrequency();
    final maxCount = responseFrequency.values.reduce((a, b) => a > b ? a : b).toDouble();

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxCount + 1,
                  minY: 0,
                  barGroups: responseFrequency.entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.toDouble(),
                          color: Colors.black,
                          width: 25,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,  // Set interval to 1 to show whole numbers
                        getTitlesWidget: (value, meta) {
                          if (value == value.roundToDouble()) {  // Only show whole numbers
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(fontSize: 12),
                            );
                          }
                          return const Text('');  // Return empty text for non-whole numbers
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: 1,  // Add horizontal grid lines at interval of 1
                    drawHorizontalLine: true,
                    drawVerticalLine: false,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Total Responses: ${responses.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


class SurveyResultsPage extends StatefulWidget {
  const SurveyResultsPage({Key? key}) : super(key: key);

  @override
  State<SurveyResultsPage> createState() => _SurveyResultsPageState();
}

class _SurveyResultsPageState extends State<SurveyResultsPage> {
  List<Map<String, dynamic>> surveyData = [];
  bool isLoading = true;
  String? error;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    fetchSurveyData();
  }

  Future<void> fetchSurveyData() async {
    try {
      final response = await http.get(
        Uri.parse('https://studentcouncil.bcp-sms1.com/php/fetch_survey_results.php'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success']) {
          setState(() {
            surveyData = List<Map<String, dynamic>>.from(jsonData['data']);
            isLoading = false;
          });
        } else {
          setState(() {
            error = 'Failed to load data';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          error = 'Server error: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[200],
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
                  'Survey Results',
                  style: TextStyle(fontSize: 18, color: Colors.black54),
                ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(onPressed: (){
                      fetchSurveyData();
                    }, icon: const Icon(Icons.refresh)),
                    _buildProfileMenu(context)
                  ],
                )
              ],
            )
          ),
        ),
        drawer: const AppDrawerAdmin(),
        body: Column(
          children: [
            const SizedBox(height: 16),
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
                                    MaterialPageRoute(builder: (context) => QuestionsListPage()),
                                  );
                                },
                                child: const Text('Feedback Results', 
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
            Expanded(
              child: isLoading 
                ? const Center(child: CircularProgressIndicator())
                : error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            error!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: fetchSurveyData,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth > 600 ? 2 : 1;
                        
                        // Group responses by question
                        Map<String, List<Map<String, dynamic>>> groupedResponses = {};
                        for (var response in surveyData) {
                          String question = response['question'];
                          if (!groupedResponses.containsKey(question)) {
                            groupedResponses[question] = [];
                          }
                          groupedResponses[question]!.add(response);
                        }
                    
                        if (groupedResponses.isEmpty) {
                          return const Center(
                            child: Text('No survey responses available'),
                          );
                        }
                    
                        return RefreshIndicator(
                          onRefresh: fetchSurveyData,
                          child: GridView.builder(
                            padding: const EdgeInsets.all(8),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              childAspectRatio: 1.2,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: groupedResponses.length,
                            itemBuilder: (context, index) {
                              String question = groupedResponses.keys.elementAt(index);
                              return SurveyResponseGraph(
                                question: question,
                                responses: groupedResponses[question]!,
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
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
            // Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePagsse()));
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