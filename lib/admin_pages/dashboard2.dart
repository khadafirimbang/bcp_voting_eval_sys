import 'dart:async';

import 'package:SSCVote/admin_pages/change_pass.dart';
import 'package:SSCVote/admin_pages/profile_menu_admin.dart';
import 'package:SSCVote/voter_pages/profile.dart';
import 'package:flutter/material.dart';
import 'package:SSCVote/admin_pages/announcement_admin.dart';
import 'package:SSCVote/admin_pages/candidates.dart';
import 'package:SSCVote/admin_pages/drawerbar_admin.dart';
import 'package:SSCVote/admin_pages/evaluation_admin.dart';
import 'package:SSCVote/admin_pages/resultAdmin.dart';
import 'package:SSCVote/admin_pages/survey_results.dart';
import 'package:SSCVote/admin_pages/voters.dart';
import 'package:SSCVote/main.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardPage2 extends StatefulWidget {
  @override
  _DashboardPage2State createState() => _DashboardPage2State();
}

String? studentNo = "Unknown"; // Default value

class _DashboardPage2State extends State<DashboardPage2> {
  int totalVoters = 0;
  int totalCandidates = 0;
  int totalEvaluations = 0;
  int totalAnnouncements = 0;
  List<Map<String, dynamic>> presidentData = [];
  List<Map<String, dynamic>> vicePresidentData = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int totalVoted = 0;
  int totalNotVoted = 0;
  bool _isLoading = true;
  int totalEval = 0;
  int totalEvalAns = 0;
  int totalEvalNotAns = 0;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel(); // Cancel any timers here
    super.dispose();
  }

  Future<void> fetchTotalEvalAns() async {
    try {
      final response = await http.get(Uri.parse('https://studentcouncil.bcp-sms1.com/php/fetch_total_eval_answered.php'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (!mounted) return; // Check if mounted
        setState(() {
          totalEvalAns = data['total_eval_answered'];
          // Calculate totalEvalNotAns
          totalEvalNotAns = totalVoters - totalEvalAns;
          totalEvalNotAns = totalEvalNotAns < 0 ? 0 : totalEvalNotAns; // Ensure it's not negative
        });
      } else {
        throw Exception('Failed to load total eval answered');
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> fetchTotalEval() async {
    try {
      final response = await http.get(Uri.parse('https://studentcouncil.bcp-sms1.com/php/fetch_total_eval.php'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (!mounted) return; // Check if mounted
        setState(() {
          totalEval = data['total_eval'];
        });
      } else {
        throw Exception('Failed to load total eval');
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _fetchAllData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // First, fetch total voters and results
      await Future.wait([
        fetchResults(),
        fetchData(),
      ]);

      // Then fetch evaluation-related data
      await Future.wait([
        fetchTotalEval(),
        fetchTotalEvalAns(),
      ]);

      // Load student number last
      await _loadStudentNo();
      
      // Additional data fetching
      await fetchCandidatesData();

    } catch (e) {
      print('Error fetching data: $e');
      if (!mounted) return; // Check if mounted
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load dashboard data')),
      );
    } finally {
      if (!mounted) return; // Check if mounted
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStudentNo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      studentNo = prefs.getString('studentno') ?? 'Student No'; // Fetch student no
    });
  }

  Future<void> fetchResults() async {
  final response = await http.get(Uri.parse('https://studentcouncil.bcp-sms1.com/php/results.php'));

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    if (!mounted) return; // Check if mounted
    setState(() {
      totalVoters = data['total_voters'];
      totalVoted = data['total_voted'];
      totalNotVoted = totalVoters - totalVoted;
    });
  } else {
    throw Exception('Failed to load results');
  }
}

  Future<void> fetchData() async {
    final response = await http.get(
        Uri.parse('https://studentcouncil.bcp-sms1.com/php/dashboard.php'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (!mounted) return; // Check if mounted
      setState(() {
        totalCandidates = data['totalCandidates'];
        totalEvaluations = data['totalEvaluations'];
        totalAnnouncements = data['totalAnnouncements'];
      });
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<void> fetchCandidatesData() async {
    final response = await http.get(
        Uri.parse('https://studentcouncil.bcp-sms1.com/php/top_candidates.php'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (!mounted) return; // Check if mounted
      setState(() {
        presidentData = List<Map<String, dynamic>>.from(data['president']);
        vicePresidentData = List<Map<String, dynamic>>.from(data['vice_president']);
      });
    }
  }

  Widget buildBarGraph(String title, VoidCallback onTap) {
    // Create a list of evaluation data
    List<Map<String, dynamic>> evaluationData = [
      {
        'name': 'Total Evaluation',
        'value': totalEval,
      },
      {
        'name': 'Evaluated',
        'value': totalEvalAns,
      },
      {
        'name': 'Not Evaluated',
        'value': totalEvalNotAns,
      }
    ];

    // Find the maximum value in the dataset
    double maxValue = evaluationData.map((data) => data['value'].toDouble()).reduce((a, b) => a > b ? a : b);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          elevation: 2,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Evaluation Statistics',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Current Evaluation Overview',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      backgroundColor: Colors.white,
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxValue * 1.2, // Add some padding above the highest bar
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: Colors.blueGrey,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              '${evaluationData[groupIndex]['name']}\n',
                              const TextStyle(color: Colors.white),
                              children: <TextSpan>[
                                TextSpan(
                                  text: rod.toY.toInt().toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  evaluationData[value.toInt()]['name'],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                            reservedSize: 50,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.black,
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: evaluationData.asMap().entries.map((entry) {
                        int index = entry.key;
                        Map<String, dynamic> data = entry.value;
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: data['value'].toDouble(),
                              color: index == 0 
                                ? Colors.black 
                                : (index == 1 
                                    ? Colors.black 
                                    : Colors.black),
                              width: 20,
                              borderRadius: BorderRadius.circular(4),
                            )
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildCard(String title, String value, IconData icon, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          elevation: 2,
          color: Colors.white, // Set Card color to white
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      value,
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Icon(
                  icon,
                  size: 60,
                  color: Colors.black,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildVotingStatisticsChart(VoidCallback onTap) {
  // Ensure Not Voted is not negative
  int notVoted = totalVoters - totalVoted;
  notVoted = notVoted < 0 ? 0 : notVoted; // Clamp to 0 if negative

  // Create a list of voting data
  List<Map<String, dynamic>> votingData = [
    {
      'name': 'Total Voters',
      'value': totalVoters.toDouble(),
    },
    {
      'name': 'Total Voted',
      'value': totalVoted.toDouble(),
    },
    {
      'name': 'Total Not Voted',
      'value': notVoted.toDouble(), // Use the clamped value
    }
  ];

  // Find the maximum value in the dataset
  double maxValue = votingData.map((data) => data['value']).reduce((a, b) => a > b ? a : b);

  // Ensure maxY is at least 1 to avoid division by zero
  maxValue = maxValue < 1 ? 1 : maxValue;

  return MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Voting Statistics',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Current Voting Overview',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                height: 200,
                child: BarChart(
                  BarChartData(
                    backgroundColor: Colors.white,
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxValue * 1.2, // Add some padding above the highest bar
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: Colors.blueGrey,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          String label;
                          switch (groupIndex) {
                            case 0:
                              label = 'Total Voters';
                              break;
                            case 1:
                              label = 'Total Voted';
                              break;
                            case 2:
                              label = 'Total Not Voted';
                              break;
                            default:
                              label = '';
                          }
                          return BarTooltipItem(
                            '$label\n',
                            const TextStyle(color: Colors.white),
                            children: <TextSpan>[
                              TextSpan(
                                text: rod.toY.toInt().toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                value == 0
                                    ? 'Voters'
                                    : value == 1
                                        ? 'Voted'
                                        : 'Not Voted',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                          reservedSize: 42,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black,
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: votingData.asMap().entries.map((entry) {
                      int index = entry.key;
                      Map<String, dynamic> data = entry.value;
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: data['value'],
                            color: Colors.black,
                            width: 20,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    int cardsPerRow;
    if (screenWidth >= 1200) {
      cardsPerRow = 4;
    } else if (screenWidth >= 800) {
      cardsPerRow = 2;
    } else {
      cardsPerRow = 1;
    }

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
                      'Dashboard',
                      style: TextStyle(fontSize: 18, color: Colors.black54),
                    ),
                  ],
                ),
                ProfileMenu()
              ],
            )
          ),
        ),
        drawer: const AppDrawerAdmin(),
        body: _isLoading
          ? _buildLoadingView()
          : SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: cardsPerRow,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.5,
                children: [
                  buildCard(
                    "Total Voters",
                    totalVoters.toString(),
                    Icons.people,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const VotersPage()),
                      );
                    },
                  ),
                  buildCard(
                    "Total Candidates",
                    totalCandidates.toString(),
                    Icons.group,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CandidatesPage()),
                      );
                    },
                  ),
                  buildCard(
                    "Total Evaluation",
                    totalEvaluations.toString(),
                    Icons.assessment,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EvaluationPage()),
                      );
                    },
                  ),
                  buildCard(
                    "Total Announcement",
                    totalAnnouncements.toString(),
                    Icons.announcement,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AnnouncementAdminPage()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 800) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: buildBarGraph(
                          "Evaluation Statistics",
                          () { 
                            Navigator.push(
                              context, 
                              MaterialPageRoute(builder: (context) => SurveyResultsPage())
                            ); 
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: buildVotingStatisticsChart(
                          () { 
                            Navigator.push(
                              context, 
                              MaterialPageRoute(builder: (context) => ResultAdminPage())
                            ); 
                          },
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      buildBarGraph(
                        "Evaluation Statistics",
                        () { 
                          Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (context) => SurveyResultsPage())
                          ); 
                        },
                      ),
                      const SizedBox(height: 16),
                      buildVotingStatisticsChart(
                        () { 
                          Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (context) => ResultAdminPage())
                          ); 
                        },
                      ),
                    ],
                  );
                }
              },
            ),
            ],
          ),
        ),
      ),
    );
  }
  
Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
          ),
          SizedBox(height: 20),
          Text(
            'Loading Dashboard...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
