import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SentimentAnalysisResultsPage extends StatefulWidget {
  @override
  _SentimentAnalysisResultsPageState createState() =>
      _SentimentAnalysisResultsPageState();
}

class _SentimentAnalysisResultsPageState
    extends State<SentimentAnalysisResultsPage> {
  List<Map<String, dynamic>> feedbackResponses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchFeedbackResponses();
  }

  Future<void> fetchFeedbackResponses() async {
  try {
    final response = await http.get(
      Uri.parse('https://studentcouncil.bcp-sms1.com/php/sentiment_analysis_result.php'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      setState(() {
        feedbackResponses = data.map((item) {
          // Parse sentiment_analysis field
          final sentimentAnalysis = jsonDecode(item['sentiment_analysis'] as String) as List<dynamic>;

          // Initialize scores
          double positiveScore = 0.0;
          double negativeScore = 0.0;

          // Dynamically identify positive and negative scores based on the label
          for (var sentiment in sentimentAnalysis[0]) {
            if (sentiment['label'] == 'POSITIVE') {
              positiveScore = sentiment['score'] as double;
            } else if (sentiment['label'] == 'NEGATIVE') {
              negativeScore = sentiment['score'] as double;
            }
          }

          return {
            'question': item['question'],
            'response': item['response'],
            'positive': positiveScore * 100, // Convert to percentage
            'negative': negativeScore * 100, // Convert to percentage
          };
        }).toList();
        isLoading = false;
      });
    } else {
      throw Exception('Failed to load data');
    }
  } catch (e) {
    setState(() {
      isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sentiment Analysis Results'),
        backgroundColor: Colors.blueGrey[900],
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: feedbackResponses.length,
              itemBuilder: (context, index) {
                final feedback = feedbackResponses[index];
                final positivePercentage = feedback['positive'];
                final negativePercentage = feedback['negative'];

                return Card(
                  elevation: 4,
                  margin: EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feedback['question'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey[900],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          feedback['response'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 16),
                        _buildSentimentBarChart(
                          positivePercentage: positivePercentage,
                          negativePercentage: negativePercentage,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildSentimentBarChart({
    required double positivePercentage,
    required double negativePercentage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'Sentiment Analysis',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[900],
            ),
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildBar(
                label: 'Positive',
                percentage: positivePercentage,
                color: Colors.green,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _buildBar(
                label: 'Negative',
                percentage: negativePercentage,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBar({
    required String label,
    required double percentage,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label (${percentage.toStringAsFixed(1)}%)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 4),
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage / 100,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
