import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:for_testing/admin_pages/drawerbar_admin.dart';
import 'package:for_testing/admin_pages/resultAdmin.dart';
import 'package:http/http.dart' as http;
import 'package:pie_chart/pie_chart.dart';

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int votedCount = 0;
  int notVotedCount = 0;
  bool isLoading = true;
  int totalCandidates = 0;
  int totalEvalAns = 0;
  int totalEvalNotAns = 0;
  int totalEval = 0;

  @override
  void initState() {
    super.initState();
    fetchVoteCounts();
    fetchTotalCandidates();
    fetchTotalEvalAns();
    fetchTotalEval();
  }

  Future<void> fetchVoteCounts() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.1.6/for_testing/fetch_vote_count.php'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          votedCount = data['voted_count'];
          notVotedCount = data['not_voted_count'];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load vote counts');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print(e);
    }
  }

  Future<void> fetchTotalCandidates() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.1.6/for_testing/fetch_total_candidates.php'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        totalCandidates = data['total_candidates'];
      } else {
        throw Exception('Failed to load total candidates');
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> fetchTotalEvalAns() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.1.6/for_testing/fetch_total_eval_answered.php'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        totalEvalAns = data['total_eval_answered'];
        setState(() {
          // Calculate totalEvalNotAns after fetching totalEvalAns
          totalEvalNotAns = (votedCount + notVotedCount) - totalEvalAns;
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
      final response = await http.get(Uri.parse('http://192.168.1.6/for_testing/fetch_total_eval.php'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        totalEval = data['total_eval'];
      } else {
        throw Exception('Failed to load total eval');
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine the number of columns based on the screen width
    int crossAxisCount;
    double screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth > 1200) {
      crossAxisCount = 4; // For computers
    } else if (screenWidth > 600) {
      crossAxisCount = 3; // For iPads and tablets
    } else {
      crossAxisCount = 1; // For mobile devices
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const AppDrawerAdmin(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Center(
                  child: Column(
                    children: [
                      // Grid layout for containers
                      GridView.count(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          // Total Voters Container
                          Container(
                            color: Colors.green,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
                                    child: Text(
                                      'Total of Voters: ${votedCount + notVotedCount}',
                                      style: const TextStyle(
                                        fontSize: 23,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          Shadow(
                                            offset: Offset(0.3, 0.3),
                                            blurRadius: 3.0,
                                            color: Colors.black54,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.people, size: 50, color: Colors.white),
                                ],
                              ),
                            ),
                          ),
                          // Total Candidates Container
                          Container(
                            color: Colors.blue,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
                                    child: Text(
                                      'Total of Candidates: $totalCandidates',
                                      style: const TextStyle(
                                        fontSize: 23,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          Shadow(
                                            offset: Offset(0.3, 0.3),
                                            blurRadius: 3.0,
                                            color: Colors.black54,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.people, size: 50, color: Colors.white),
                                ],
                              ),
                            ),
                          ),
                          // Total Evaluation Container
                          Container(
                            color: Colors.red,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
                                    child: Text(
                                      'Total of Evaluation: $totalEval',
                                      style: const TextStyle(
                                        fontSize: 23,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          Shadow(
                                            offset: Offset(0.3, 0.3),
                                            blurRadius: 3.0,
                                            color: Colors.black54,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.question_answer, size: 50, color: Colors.white),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      // PieChart
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 10),
                              height: 340, // Set a fixed height for the PieChart
                              child: PieChart(
                                dataMap: {
                                  "Voted - $votedCount": votedCount.toDouble(),
                                  "Not Voted - $notVotedCount": notVotedCount.toDouble(),
                                },
                                chartType: ChartType.disc,
                                animationDuration: const Duration(milliseconds: 1000),
                                colorList: const [Colors.blue, Colors.red],
                                legendOptions: const LegendOptions(
                                  showLegendsInRow: false,
                                  legendPosition: LegendPosition.right,
                                  showLegends: true,
                                  legendTextStyle: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 23,
                                  ),
                                ),
                                chartValuesOptions: const ChartValuesOptions(
                                  showChartValueBackground: true,
                                  showChartValues: true,
                                  showChartValuesInPercentage: true,
                                  showChartValuesOutside: false,
                                ),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 10),
                              height: 340, // Set a fixed height for the PieChart
                              child: PieChart(
                                dataMap: {
                                  "Total Answered Evaluation - $totalEvalAns": totalEvalAns.toDouble(),
                                  "Not Answered - $totalEvalNotAns": totalEvalNotAns.toDouble(),
                                },
                                chartType: ChartType.disc,
                                animationDuration: const Duration(milliseconds: 1000),
                                colorList: const [Colors.green, Colors.purple],
                                legendOptions: const LegendOptions(
                                  showLegendsInRow: false,
                                  legendPosition: LegendPosition.right,
                                  showLegends: true,
                                  legendTextStyle: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 23,
                                  ),
                                ),
                                chartValuesOptions: const ChartValuesOptions(
                                  showChartValueBackground: true,
                                  showChartValues: true,
                                  showChartValuesInPercentage: true,
                                  showChartValuesOutside: false,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

