import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:for_testing/admin_pages/drawerbar_admin.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:http/http.dart' as http;

class ResultAdminPage extends StatefulWidget {
  const ResultAdminPage({super.key});

  @override
  _ResultAdminPageState createState() => _ResultAdminPageState();
}

class _ResultAdminPageState extends State<ResultAdminPage> {
  List<VotingData> _presidentVotes = [];
  List<VotingData> _vpVotes = [];
  List<VotingData> _secretaryVotes = [];
  List<VotingData> _treasurerVotes = [];
  List<VotingData> _auditorVotes = [];
  String _electionName = ''; // Variable to store the election name
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    fetchVotingData();
  }

  Future<void> fetchVotingData() async {
    final url = Uri.parse('https://studentcouncil.bcp-sms1.com/php/fetch_results_admin.php'); // Update with your actual PHP endpoint
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      setState(() {
        _electionName = responseData['election_name'] ?? 'Election Results'; // Set the election name
        final List<dynamic> data = responseData['data'];
        _presidentVotes = filterVotes(data, 'President');
        _vpVotes = filterVotes(data, 'Vice President');
        _secretaryVotes = filterVotes(data, 'Secretary');
        _treasurerVotes = filterVotes(data, 'Treasurer');
        _auditorVotes = filterVotes(data, 'Auditor');
      });
    } else {
      throw Exception('Failed to load voting data');
    }
  }

  List<VotingData> filterVotes(List<dynamic> data, String position) {
    return data.where((candidate) {
      return candidate['position'] == position; // Ensure your PHP returns this field
    }).map((candidate) {
      return VotingData(
        "${candidate['lastname']}, ${candidate['firstname']} ${candidate['middlename']}",
        int.tryParse(candidate['total_votes'].toString()) ?? 0, // Safely parse total_votes
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
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
                'Election Result',
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _electionName, // Display the election name
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0), // Add some spacing
            Card(color: Colors.white,
                  elevation: 2,child: buildChart('Voting Results for President', _presidentVotes)),
            Card(color: Colors.white,
                  elevation: 2,child: buildChart('Voting Results for Vice President', _vpVotes)),
            Card(color: Colors.white,
                  elevation: 2,child: buildChart('Voting Results for Secretary', _secretaryVotes)),
            Card(color: Colors.white,
                  elevation: 2,child: buildChart('Voting Results for Treasurer', _treasurerVotes)),
            Card(color: Colors.white,
                  elevation: 2,child: buildChart('Voting Results for Auditor', _auditorVotes)),
          ],
        ),
      ),
    );
  }

  Widget buildChart(String title, List<VotingData> votingData) {
    // Define a list of colors to use for the candidates
    final List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.amber,
      Colors.brown,
      Colors.cyan,
      Colors.indigo,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: SfCartesianChart(
        title: ChartTitle(text: title),
        primaryXAxis: const CategoryAxis(), // CategoryAxis for candidate names
        primaryYAxis: const NumericAxis(
          labelFormat: '{value}', // Ensure Y-axis labels are displayed as integers
          minimum: 0, // Set minimum value for Y-axis
        ),
        series: <CartesianSeries>[
          BarSeries<VotingData, String>(
            dataSource: votingData,
            xValueMapper: (VotingData data, _) => data.candidateName,
            yValueMapper: (VotingData data, _) => data.votes,
            // Use a color list based on index
            pointColorMapper: (VotingData data, int index) {
              return colors[index % colors.length]; // Cycle through colors
            },
            // Display total_votes inside the bars
            dataLabelMapper: (VotingData data, _) => data.votes.toString(),
            dataLabelSettings: const DataLabelSettings(isVisible: true),
          ),
        ],
      ),
    );
  }
}

class VotingData {
  final String candidateName;
  final int votes;

  VotingData(this.candidateName, this.votes);
}
