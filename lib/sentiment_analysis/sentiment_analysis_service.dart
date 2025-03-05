import 'dart:convert';
import 'package:http/http.dart' as http;

class SentimentAnalysisService {
  Future<Map<String, dynamic>> analyzeFeedback(String feedback) async {
    try {
      var url = Uri.parse('https://studentcouncil.bcp-sms1.com/php/sentiment_analysis.php');
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'feedback': feedback}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to analyze feedback: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> submitSentimentAnalysis(List<Map<String, dynamic>> sentimentAnalysisData) async {
    try {
      var url = Uri.parse('https://studentcouncil.bcp-sms1.com/php/submit_sentiment_analysis.php');
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'sentiment_analysis': sentimentAnalysisData}),
      );

      if (response.statusCode == 200) {
        var result = jsonDecode(response.body);
        if (result['success']) {
          print(result['message']);
        } else {
          print(result['message']);
        }
      } else {
        print('Failed to submit sentiment analysis: ${response.statusCode}');
      }
    } catch (e) {
      print('Error submitting sentiment analysis: $e');
    }
  }
}
