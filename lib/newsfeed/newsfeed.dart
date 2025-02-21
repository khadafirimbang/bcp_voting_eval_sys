// main.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Newsfeed',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
      home: const NewsfeedPage(),
    );
  }
}

// Constants
const String apiBaseUrl = 'https://studentcouncil.bcp-sms1.com/php/newsfeed.php'; // Use 10.0.2.2 for Android emulator
const String currentUser = '2023-12345'; // Replace with actual user authentication

class NewsfeedPage extends StatefulWidget {
  const NewsfeedPage({Key? key}) : super(key: key);

  @override
  _NewsfeedPageState createState() => _NewsfeedPageState();
}

class _NewsfeedPageState extends State<NewsfeedPage> {
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;
  String _sortBy = 'newest';
  
  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/getPosts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sort': _sortBy,
          'studentno': currentUser,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          setState(() {
            _posts = List<Map<String, dynamic>>.from(data['posts']);
            _isLoading = false;
          });
        } else {
          throw Exception('Failed to load posts: ${data['message']}');
        }
      } else {
        throw Exception('Failed to load posts');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _changeSortOrder(String sortBy) {
    setState(() {
      _sortBy = sortBy;
    });
    _fetchPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Newsfeed'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: _changeSortOrder,
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'newest',
                child: Text('Newest First'),
              ),
              const PopupMenuItem(
                value: 'oldest',
                child: Text('Oldest First'),
              ),
              const PopupMenuItem(
                value: 'popular',
                child: Text('Most Popular'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchPosts,
              child: _posts.isEmpty
                  ? Center(
                      child: Text(
                        'No posts yet. Be the first to post!',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _posts.length,
                      itemBuilder: (context, index) {
                        return PostCard(
                          post: _posts[index],
                          onDelete: () {
                            _deletePost(_posts[index]['post_id']);
                          },
                          onRefresh: _fetchPosts,
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePostPage()),
          );
          
          if (result == true) {
            _fetchPosts();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _deletePost(int postId) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/deletePost'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'post_id': postId,
          'studentno': currentUser,
        }),
      );

      final data = jsonDecode(response.body);
      if (data['success']) {
        _fetchPosts();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'])),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}

class PostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final VoidCallback onDelete;
  final VoidCallback onRefresh;

  const PostCard({
    Key? key,
    required this.post,
    required this.onDelete,
    required this.onRefresh,
  }) : super(key: key);

  @override
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _isExpanded = false;
  List<Map<String, dynamic>> _comments = [];
  bool _loadingComments = false;
  int _likes = 0;
  int _dislikes = 0;
  String? _userReaction;
  
  @override
  void initState() {
    super.initState();
    _likes = widget.post['likes'] ?? 0;
    _dislikes = widget.post['dislikes'] ?? 0;
    _userReaction = widget.post['user_reaction'];
  }

  Future<void> _fetchComments() async {
    if (_loadingComments) return;
    
    setState(() {
      _loadingComments = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/getComments'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'post_id': widget.post['post_id'],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          setState(() {
            _comments = List<Map<String, dynamic>>.from(data['comments']);
            _loadingComments = false;
          });
        } else {
          throw Exception('Failed to load comments');
        }
      } else {
        throw Exception('Failed to load comments');
      }
    } catch (e) {
      setState(() {
        _loadingComments = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _toggleReaction(String type) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/toggleReaction'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'post_id': widget.post['post_id'],
          'studentno': currentUser,
          'reaction_type': type,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          setState(() {
            _likes = data['likes'] ?? 0;
            _dislikes = data['dislikes'] ?? 0;
            _userReaction = data['userReaction'];
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'])),
          );
        }
      } else {
        throw Exception('Failed to toggle reaction');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateTime postDate = DateTime.parse(widget.post['created_at']);
    final String formattedDate = DateFormat('MMM d, yyyy • h:mm a').format(postDate);
    final bool isCurrentUserPost = widget.post['studentno'] == currentUser;
    
    Widget? postImage;
    if (widget.post['image'] != null && widget.post['image'].toString().isNotEmpty) {
      if (kIsWeb) {
        // Use Image.network or base64 for web
        postImage = Image.memory(
          base64Decode(widget.post['image']),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Center(child: Text('Failed to load image'));
          },
        );
      } else {
        // Use Image.file for mobile platforms
        postImage = Image.file(
          File.fromRawPath(base64Decode(widget.post['image'])),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Center(child: Text('Failed to load image'));
          },
        );
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(
              widget.post['name'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(formattedDate),
            trailing: isCurrentUserPost
                ? IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: widget.onDelete,
                  )
                : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              widget.post['title'],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(widget.post['description']),
          ),
          if (postImage != null)
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              width: double.infinity,
              child: postImage,
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text('$_likes likes • $_dislikes dislikes'),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                      if (_isExpanded && _comments.isEmpty) {
                        _fetchComments();
                      }
                    });
                  },
                  child: Text(_isExpanded ? 'Hide Comments' : 'Show Comments'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.thumb_up,
                    color: _userReaction == 'like' ? Colors.blue : Colors.grey,
                  ),
                  onPressed: () => _toggleReaction('like'),
                ),
                IconButton(
                  icon: Icon(
                    Icons.thumb_down,
                    color: _userReaction == 'dislike' ? Colors.red : Colors.grey,
                  ),
                  onPressed: () => _toggleReaction('dislike'),
                ),
                Expanded(
                  child: TextButton.icon(
                    icon: const Icon(Icons.comment),
                    label: const Text('Comment'),
                    onPressed: () {
                      _showCommentDialog(context);
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_isExpanded)
            _loadingComments
                ? const Center(child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      ..._comments.map((comment) => CommentTile(comment: comment)),
                      if (_comments.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'No comments yet. Be the first to comment!',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                    ],
                  ),
        ],
      ),
    );
  }

  void _showCommentDialog(BuildContext context) {
    final TextEditingController commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Comment'),
          content: TextField(
            controller: commentController,
            decoration: const InputDecoration(
              hintText: 'Write your comment...',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (commentController.text.trim().isEmpty) {
                  return;
                }

                try {
                  final response = await http.post(
                    Uri.parse('$apiBaseUrl/addComment'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      'post_id': widget.post['post_id'],
                      'studentno': currentUser,
                      'comment_text': commentController.text.trim(),
                    }),
                  );

                  Navigator.pop(context);

                  final data = jsonDecode(response.body);
                  if (data['success']) {
                    if (_isExpanded) {
                      _fetchComments();
                    } else {
                      setState(() {
                        _isExpanded = true;
                        _fetchComments();
                      });
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(data['message'])),
                    );
                  }
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: const Text('Post'),
            ),
          ],
        );
      },
    );
  }
}

class CommentTile extends StatelessWidget {
  final Map<String, dynamic> comment;

  const CommentTile({Key? key, required this.comment}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final DateTime commentDate = DateTime.parse(comment['created_at']);
    final String timeAgo = _getTimeAgo(commentDate);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                comment['name'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Text(
                timeAgo,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(comment['comment_text']),
          const Divider(),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final Duration difference = DateTime.now().difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({Key? key}) : super(key: key);

  @override
  _CreatePostPageState createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _base64Image;
  bool _isLoading = false;
  File? _imageFile;

  Future<void> _pickImage() async {
  try {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (image != null) {
      // Null check before processing
      final bytes = await image.readAsBytes();
      setState(() {
        _base64Image = base64Encode(bytes);
        _imageFile = kIsWeb ? null : File(image.path);
      });
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error picking image: $e')),
    );
  }
}

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) {
    return;
  }

  setState(() {
    _isLoading = true;
  });

  try {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/createPost'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'studentno': currentUser,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        // Use null-aware operator to handle optional image
        'image': _base64Image ?? '',  // Empty string instead of null
      }),
    );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post created successfully')),
          );
        } else {
          throw Exception(data['message']);
        }
      } else {
        throw Exception('Failed to create post');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
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
        title: const Text('Create New Post'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo),
                      label: const Text('Add Image (Optional)'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    if (_imageFile != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Image.file(
                                _imageFile!,
                                fit: BoxFit.cover,
                                height: 200,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.black54,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _imageFile = null;
                                    _base64Image = null;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submitPost,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Create Post', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}