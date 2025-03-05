import 'dart:convert';
import 'package:http/http.dart' as http;

class SentimentAnalysis {
  static Future<String> analyzeFeedback(String feedback) async {
    final url = Uri.parse('https://api-inference.huggingface.co/models/distilbert-base-uncased-finetuned-sst-2-english');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer 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',
    };
    final body = jsonEncode({'inputs': feedback});

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        return response.body;
      } else {
        final errorMessage = 'Failed to analyze feedback: ${response.statusCode} - ${response.body}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      rethrow;
    }
  }
}
