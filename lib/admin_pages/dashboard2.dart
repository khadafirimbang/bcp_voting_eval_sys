import 'package:flutter/material.dart';
import 'package:for_testing/admin_pages/announcement_admin.dart';
import 'package:for_testing/admin_pages/candidates.dart';
import 'package:for_testing/admin_pages/drawerbar_admin.dart';
import 'package:for_testing/admin_pages/evaluation_admin.dart';
import 'package:for_testing/admin_pages/resultAdmin.dart';
import 'package:for_testing/admin_pages/voters.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

class DashboardPage2 extends StatefulWidget {
  @override
  _DashboardPage2State createState() => _DashboardPage2State();
}

class _DashboardPage2State extends State<DashboardPage2> {
  int totalVoters = 0;
  int totalCandidates = 0;
  int totalEvaluations = 0;
  int totalAnnouncements = 0;
  List<Map<String, dynamic>> presidentData = [];
  List<Map<String, dynamic>> vicePresidentData = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    fetchData();
    fetchCandidatesData();
  }

  Future<void> fetchData() async {
    final response = await http.get(
        Uri.parse('https://studentcouncil.bcp-sms1.com/php/dashboard.php'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        totalVoters = data['totalVoters'];
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
      setState(() {
        presidentData = List<Map<String, dynamic>>.from(data['president']);
        vicePresidentData = List<Map<String, dynamic>>.from(data['vice_president']);
      });
    }
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

  Widget buildBarGraph(String title, List<Map<String, dynamic>> data, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        color: Colors.white, // Set Card color to white
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
              const SizedBox(height: 4),
              const Text(
                'Current Election Ranking',
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
                    backgroundColor: Colors.white, // Set background color to white
                    alignment: BarChartAlignment.spaceAround,
                    maxY: data.isEmpty
                        ? 100
                        : (data.map((e) => (e['total_votes'] as num).toDouble()).reduce(
                                (a, b) => a > b ? a : b) *
                            1.2),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: Colors.blueGrey,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${data[groupIndex]['lastname']}\n',
                            const TextStyle(color: Colors.white),
                            children: <TextSpan>[
                              TextSpan(
                                text: '${data[groupIndex]['total_votes']} votes',
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
                            int index = value.toInt();
                            if (index >= 0 && index < data.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Transform.rotate(
                                  angle: 45 * 3.1415927 / 180,
                                  child: Text(
                                    data[index]['lastname'].toString(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            }
                            return const Text('');
                          },
                          reservedSize: 42,
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
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
                    barGroups: List.generate(
                      data.length,
                      (index) => BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: (data[index]['total_votes'] as num).toDouble(),
                            color: Colors.black,
                            width: 20,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
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

    return Scaffold(
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
          )
        ),
      ),
      drawer: const AppDrawerAdmin(),
      body: SingleChildScrollView(
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
            screenWidth >= 800
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: buildBarGraph("President", presidentData,
                        () { Navigator.push(context, MaterialPageRoute(builder: (context) => const ResultAdminPage()),
                      ); 
                    },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: buildBarGraph("Vice President", vicePresidentData,
                        () { Navigator.push(context, MaterialPageRoute(builder: (context) => const ResultAdminPage()),
                      ); 
                    },
                    ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      buildBarGraph("President", presidentData,
                      () { Navigator.push(context, MaterialPageRoute(builder: (context) => const ResultAdminPage()),
                      ); 
                    },
                      ),
                      const SizedBox(height: 20),
                      buildBarGraph("Vice President", vicePresidentData,
                      () { Navigator.push(context, MaterialPageRoute(builder: (context) => const ResultAdminPage()),
                      ); 
                    },
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
