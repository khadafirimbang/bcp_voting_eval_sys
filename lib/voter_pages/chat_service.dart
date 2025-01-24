import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  final String apiKey = 'AIzaSyA5os-SP8kMymDWGfKE4enPbj3gjWnUROM';  // Replace with your actual API key
  final String apiUrl = 'https://api.google.com/gemini'; // Update with actual URL

  Future<String> sendMessage(String message) async {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({'message': message}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['response']; // Adjust based on actual response structure
    } else {
      throw Exception('Failed to communicate with the API');
    }
  }
}
