import 'package:SSCVote/forum/model_forum.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ForumService {
  static const String baseUrl = 'https://studentcouncil.bcp-sms1.com/php/forum/';

  Future<List<Forum>> fetchForums() async {
    final response = await http.get(Uri.parse('${baseUrl}get_forums.php'));
    
    if (response.statusCode == 200) {
      List<dynamic> body = json.decode(response.body);
      return body.map((dynamic item) => Forum.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load forums');
    }
  }

  Future<bool> createForum(String studentNo, String title, String content) async {
    final response = await http.post(
      Uri.parse('${baseUrl}create_forum.php'),
      body: json.encode({
        'studentno': studentNo,
        'title': title,
        'content': content,
      }),
    );

    return json.decode(response.body)['success'];
  }

  Future<Map<String, dynamic>> likeForum(
    String studentNo, 
    int forumId, 
    bool isLike
  ) async {
    final response = await http.post(
      Uri.parse('${baseUrl}like_forum.php'),
      headers: {
        'Content-Type': 'application/json', // Add this header
      },
      body: json.encode({
        'studentno': studentNo,
        'forum_id': forumId,
        'is_like': isLike,
      }),
    );

    // Add some debug print to check the response
    // print('Like/Dislike Response: ${response.body}');

    return json.decode(response.body);
  }

  // Delete a forum
  Future<Map<String, dynamic>> deleteForum(String studentNo, int forumId) async {
  final response = await http.post(
    Uri.parse('${baseUrl}delete_forum.php'),
    headers: {
      'Content-Type': 'application/json',
    },
    body: json.encode({
      'studentno': studentNo,
      'forum_id': forumId,
    }),
  );

  return json.decode(response.body);
}

  // Fetch comments for a specific forum
  Future<List<Comment>> fetchComments(int forumId) async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}get_comments.php?forum_id=$forumId')
      );
      
      // Debug print to understand the raw response
      // print('Raw Response: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic body = json.decode(response.body);
        
        // Explicitly handle the expected JSON structure
        if (body is Map<String, dynamic>) {
          // Check for success flag
          if (body['success'] == false) {
            throw Exception(body['error'] ?? 'Failed to load comments');
          }

          // Ensure comments is a list
          final comments = body['comments'];
          if (comments is List) {
            return comments
                .map<Comment>((item) => Comment.fromJson(item))
                .toList();
          } else {
            throw Exception('Comments is not a list');
          }
        }
        
        throw Exception('Unexpected response format');
      } else {
        throw Exception('Failed to load comments. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Detailed error in fetchComments: $e');
      rethrow;
    }
  }

  // Add a new comment
  Future<Map<String, dynamic>> addComment(
    String studentNo, 
    int forumId, 
    String content
  ) async {
    final response = await http.post(
      Uri.parse('${baseUrl}add_comment.php'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'studentno': studentNo,
        'forum_id': forumId,
        'content': content,
      }),
    );

    return json.decode(response.body);
  }

  Future<int> getCommentCount(int forumId) async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}get_comment_count.php?forum_id=$forumId')
      );
      
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        return int.parse(body['comment_count'].toString());
      } else {
        return 0;
      }
    } catch (e) {
      print('Error getting comment count: $e');
      return 0;
    }
  }

}


