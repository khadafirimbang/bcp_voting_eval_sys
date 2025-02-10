import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:for_testing/admin_pages/drawerbar_admin.dart';
import 'package:for_testing/main.dart';
import 'package:for_testing/voter_pages/announcement.dart';
import 'package:for_testing/voter_pages/drawerbar.dart';
import 'package:for_testing/voter_pages/election_history.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ResultsPage extends StatefulWidget {
  @override
  _ResultsPageState createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  List<dynamic> candidates = [];
  int totalVoters = 0;
  int totalVoted = 0;
  int totalNotVoted = 0;
  String selectedPosition = 'All';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> fetchResults() async {
    final response = await http.get(Uri.parse('https://studentcouncil.bcp-sms1.com/php/results.php'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        candidates = data['candidates'];
        totalVoters = data['total_voters'];
        totalVoted = data['total_voted'];
        totalNotVoted = totalVoters - totalVoted;
      });
    } else {
      throw Exception('Failed to load results');
    }
  }

  Widget _buildVotingStatsChart() {
    return Container(
      height: 200,
      width: 500,
      padding: const EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceEvenly,
          maxY: totalVoters.toDouble(),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: Colors.black87,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                String label;
                double percentage;
                switch (groupIndex) {
                  case 0:
                    percentage = 100.0;
                    label = 'Total Voters: ${totalVoters.toString()} (100%)';
                    break;
                  case 1:
                    percentage = (totalVoted / totalVoters) * 100;
                    label = 'Voted: ${totalVoted.toString()} (${percentage.toStringAsFixed(1)}%)';
                    break;
                  case 2:
                    percentage = (totalNotVoted / totalVoters) * 100;
                    label = 'Not Voted: ${totalNotVoted.toString()} (${percentage.toStringAsFixed(1)}%)';
                    break;
                  default:
                    label = '';
                    percentage = 0;
                }
                return BarTooltipItem(
                  label,
                  const TextStyle(color: Colors.white),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  String text;
                  switch (value.toInt()) {
                    case 0:
                      text = 'Total';
                      break;
                    case 1:
                      text = 'Voted';
                      break;
                    case 2:
                      text = 'Not Voted';
                      break;
                    default:
                      text = '';
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      text,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: false),
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: totalVoters.toDouble(),
                  color: Colors.blue,
                  width: 20,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: totalVoted.toDouble(),
                  color: Colors.green,
                  width: 20,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
            BarChartGroupData(
              x: 2,
              barRods: [
                BarChartRodData(
                  toY: totalNotVoted.toDouble(),
                  color: Colors.red,
                  width: 20,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchResults();
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> filteredCandidates = selectedPosition == 'All'
        ? candidates
        : candidates.where((candidate) => candidate['position'] == selectedPosition).toList();

    Set<String> positions = {'All'};
    for (var candidate in candidates) {
      positions.add(candidate['position']);
    }

    int crossAxisCount;
    double screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth >= 1200) {
      crossAxisCount = 5;
    } else if (screenWidth >= 800) {
      crossAxisCount = 3;
    } else {
      crossAxisCount = 1;
    }

    Map<String, List<dynamic>> groupedCandidates = {};
    for (var candidate in filteredCandidates) {
      if (!groupedCandidates.containsKey(candidate['position'])) {
        groupedCandidates[candidate['position']] = [];
      }
      groupedCandidates[candidate['position']]!.add(candidate);
    }

    return SafeArea(
      child: Scaffold(
        key: _scaffoldKey,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            height: 56,
            alignment: Alignment.center,
            margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
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
                      'Election Results',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ],
                ),
                Row(
                  children: [
                    DropdownButton<String>(
                      value: selectedPosition,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedPosition = newValue!;
                        });
                      },
                      items: positions.map<DropdownMenuItem<String>>((String position) {
                        return DropdownMenuItem<String>(
                          value: position,
                          child: Text(position),
                        );
                      }).toList(),
                    ),
                    _buildProfileMenu(context)
                  ],
                )
              ],
            ),
          ),
        ),
        drawer: const AppDrawer(),
        body: SingleChildScrollView( // Make the body scrollable
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Card(
                  elevation: 2,
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                    child: Column(
                      children: [
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
                                MaterialPageRoute(builder: (context) => ElectionHistory()),
                              );
                            },
                            child: const Text(
                              'Election History',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        _buildVotingStatsChart(),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                ListView(
                  physics: NeverScrollableScrollPhysics(), // Prevent scrolling of ListView
                  shrinkWrap: true, // Allow ListView to take only the necessary space
                  children: groupedCandidates.entries.map((entry) {
                    int totalPositionVotes = entry.value.fold<int>(0, (sum, candidate) {
                      return sum + (candidate['total_votes'] as int);
                    });
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 10),
                        ExpansionTile(
                          collapsedShape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                          title: Text(entry.key),
                          children: [
                            GridView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 8.0,
                                mainAxisSpacing: 8.0,
                              ),
                              itemCount: entry.value.length,
                              itemBuilder: (context, index) {
                                var candidate = entry.value[index];
                                double percentage = totalVoters > 0
                                    ? (candidate['total_votes'] / totalVoters) * 100
                                    : 0;
                                return Card(
                                  elevation: 5,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ClipOval(
                                        child: candidate['image_url'] != null &&
                                                candidate['image_url'].isNotEmpty
                                            ? Image.network(
                                                candidate['image_url'],
                                                height: 155,
                                                width: 155,
                                                fit: BoxFit.cover,
                                              )
                                            : Image.asset(
                                                'assets/images/bcp_logo.png',
                                                height: 155,
                                                width: 155,
                                                fit: BoxFit.cover,
                                              ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        '${candidate['lastname']}, ${candidate['firstname']}',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text('Position: ${candidate['position']}'),
                                      Text('${candidate['total_votes']} votes'),
                                      SizedBox(
                                        width: double.infinity,
                                        child: LinearProgressIndicator(
                                          value: percentage / 100,
                                          backgroundColor: Colors.grey[300],
                                          color: Colors.blue,
                                        ),
                                      ),
                                      Text('${percentage.toStringAsFixed(2)}%'),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
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
            // Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage()));
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