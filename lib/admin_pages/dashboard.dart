import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:for_testing/admin_pages/drawerbar_admin.dart';
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
    fetchVoteCounts(); // Fetch vote counts first
  }

  Future<void> fetchVoteCounts() async {
    try {
      final response = await http.get(Uri.parse('https://studentcouncil.bcp-sms1.com/php/fetch_vote_count.php'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          votedCount = data['voted_count'];
          notVotedCount = data['not_voted_count'];
        });
        await fetchTotalEvalAns(); // Call this after voted counts are set
        await fetchTotalCandidates(); // Fetch total candidates
        await fetchTotalEval(); // Fetch total evaluations
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
      final response = await http.get(Uri.parse('https://studentcouncil.bcp-sms1.com/php/fetch_total_candidates.php'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          totalCandidates = data['total_candidates'];
        });
      } else {
        throw Exception('Failed to load total candidates');
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> fetchTotalEvalAns() async {
    try {
      final response = await http.get(Uri.parse('https://studentcouncil.bcp-sms1.com/php/fetch_total_eval_answered.php'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          totalEvalAns = data['total_eval_answered'];
          // Calculate totalEvalNotAns after fetching totalEvalAns
          totalEvalNotAns = (votedCount + notVotedCount) - totalEvalAns;
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
        setState(() {
          totalEval = data['total_eval'];
        });
      } else {
        throw Exception('Failed to load total eval');
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        isLoading = false; // Set loading to false after all data is fetched
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
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
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          // Total Voters Container
                          buildInfoContainer(
                            title: 'Total of Voters: ${votedCount + notVotedCount}',
                            color: Colors.green,
                            icon: Icons.people,
                          ),
                          // Total Candidates Container
                          buildInfoContainer(
                            title: 'Total of Candidates: $totalCandidates',
                            color: Colors.blue,
                            icon: Icons.people,
                          ),
                          // Total Evaluation Container
                          buildInfoContainer(
                            title: 'Total of Evaluation: $totalEval',
                            color: Colors.red,
                            icon: Icons.question_answer,
                          ),
                          // First PieChart
                          buildPieChart(
                            title: "Voted vs Not Voted",
                            dataMap: {
                              "Voted - $votedCount": votedCount.toDouble(),
                              "Not Voted - $notVotedCount": notVotedCount.toDouble(),
                            },
                            colorList: const [Colors.blue, Colors.red],
                          ),
                          // Second PieChart
                          buildPieChart(
                            title: "Evaluation Answered vs Not Answered",
                            dataMap: {
                              "Evaluation Answered - $totalEvalAns": totalEvalAns.toDouble(),
                              "Evaluation Not Answered - $totalEvalNotAns": totalEvalNotAns.toDouble(),
                            },
                            colorList: const [Colors.green, Colors.red],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget buildInfoContainer({required String title, required Color color, required IconData icon}) {
    return Container(
      width: MediaQuery.of(context).size.width > 600
          ? (MediaQuery.of(context).size.width / 3) - 20
          : MediaQuery.of(context).size.width - 20,
      height: 300,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            offset: const Offset(6, 6),
            blurRadius: 5,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
              child: Text(
                title,
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
            Icon(icon, size: 50, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget buildPieChart({required String title, required Map<String, double> dataMap, required List<Color> colorList}) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        height: 340,
        child: PieChart(
          dataMap: dataMap,
          chartType: ChartType.disc,
          animationDuration: const Duration(milliseconds: 1000),
          colorList: colorList,
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
            showChartValueBackground: false,
            showChartValues: true,
            chartValueStyle: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
