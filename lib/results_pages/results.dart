import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:SSCVote/voter_pages/profile.dart';
import 'package:SSCVote/voter_pages/profile_menu.dart';
import 'package:flutter/material.dart';
import 'package:SSCVote/admin_pages/drawerbar_admin.dart';
import 'package:SSCVote/main.dart';
import 'package:SSCVote/voter_pages/announcement.dart';
import 'package:SSCVote/voter_pages/drawerbar.dart';
import 'package:SSCVote/voter_pages/election_history.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ResultsPage extends StatefulWidget {
  @override
  _ResultsPageState createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  List<dynamic> candidates = [];
  Map<String, Uint8List> imageCache = {};
  int totalVoters = 0;
  int totalVoted = 0;
  int totalNotVoted = 0;
  String selectedPosition = 'All';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late Timer _timer;
  bool isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    _initialFetch();
    _setupPeriodicFetch();
  }

  Future<void> _initialFetch() async {
    await fetchResults();
    if (mounted) {
      setState(() {
        isInitialLoad = false;
      });
    }
  }

  void _setupPeriodicFetch() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _updateVoteCounts();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _updateVoteCounts() async {
    try {
      final response = await http.get(
        Uri.parse('https://studentcouncil.bcp-sms1.com/php/results.php')
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            // Only update the vote counts and totals, not the images
            for (var newCandidate in data['candidates']) {
              final index = candidates.indexWhere((c) => 
                c['studentno'].toString() == newCandidate['studentno'].toString());
              if (index != -1) {
                candidates[index]['total_votes'] = newCandidate['total_votes'];
              }
            }
            totalVoters = data['total_voters'];
            totalVoted = data['total_voted'];
            totalNotVoted = totalVoters - totalVoted;
          });
        }
      }
    } catch (e) {
      print('Error updating vote counts: $e');
    }
  }

  Future<void> fetchResults() async {
    try {
      final response = await http.get(
        Uri.parse('https://studentcouncil.bcp-sms1.com/php/results.php')
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            candidates = data['candidates'];
            totalVoters = data['total_voters'];
            totalVoted = data['total_voted'];
            totalNotVoted = totalVoters - totalVoted;
          });
        }

        // Cache images only during initial load
        if (isInitialLoad) {
          for (var candidate in data['candidates']) {
            final studentNo = candidate['studentno'].toString(); // Convert to string
            if (candidate['img'] != null && 
                candidate['img'].isNotEmpty && 
                !imageCache.containsKey(studentNo)) {
              try {
                String cleanBase64 = candidate['img']
                    .replaceAll(RegExp(r'data:image/[^;]+;base64,'), '')
                    .replaceAll('\n', '')
                    .replaceAll('\r', '')
                    .replaceAll(' ', '+');
                imageCache[studentNo] = base64Decode(cleanBase64);
              } catch (e) {
                print('Error caching image for $studentNo: $e');
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error fetching results: $e');
    }
  }

  Widget _buildCandidateImage(dynamic candidate) {
    final studentNo = candidate['studentno'].toString(); // Convert to string
    if (candidate['img'] != null && 
        candidate['img'].isNotEmpty && 
        imageCache.containsKey(studentNo)) {
      return CircleAvatar(
        backgroundImage: MemoryImage(imageCache[studentNo]!),
        radius: 70,
      );
    } else {
      return const CircleAvatar(
        backgroundImage: AssetImage('assets/bcp_logo.png'),
        radius: 70,
      );
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
  Widget build(BuildContext context) {
    List<dynamic> filteredCandidates = selectedPosition == 'All'
        ? candidates
        : candidates.where((candidate) => 
            candidate['position'] == selectedPosition).toList();

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
        backgroundColor: Colors.grey[200],
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
                      'Results',
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
                    ProfileMenuVoter()
                  ],
                )
              ],
            ),
          ),
        ),
        drawer: const AppDrawer(),
        body: isInitialLoad 
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      children: groupedCandidates.entries.map((entry) {
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
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _buildCandidateImage(candidate),
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
