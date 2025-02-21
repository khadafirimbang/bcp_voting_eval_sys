import 'dart:convert';
import 'package:http/http.dart' as http;
import 'post_model.dart';

class PostService {
static const String baseUrl = 'https://studentcouncil.bcp-sms1.com/php';

Future<List<Post>> getPosts(String order, int studentNo) async {
  final response = await http.get(
    Uri.parse('$baseUrl/get_posts.php?order=$order&studentno=$studentNo')
  );

  if (response.statusCode == 200) {
    List jsonResponse = json.decode(response.body);
    return jsonResponse.map((post) => Post.fromJson(post)).toList();
  } else {
    throw Exception('Failed to load posts');
  }
}

Future<void> createPost(int studentNo, String title, String description, String? image) async {
  await http.post(
    Uri.parse('$baseUrl/create_post.php'),
    body: json.encode({
      'studentno': studentNo,
      'title': title,
      'description': description,
      'image': image
    })
  );
}

Future<void> interactWithPost(int studentNo, int postId, String interactionType) async {
  await http.post(
    Uri.parse('$baseUrl/interact_post.php'),
    body: json.encode({
      'studentno': studentNo,
      'post_id': postId,
      'interaction_type': interactionType
    })
  );
}
}