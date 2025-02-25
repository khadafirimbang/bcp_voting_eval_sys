import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:SSCVote/forum/model_forum.dart';
import 'package:SSCVote/forum/service_forum.dart';

class CommentScreen extends StatefulWidget {
  final Forum forum;
  final String studentNo;

  const CommentScreen({
    Key? key, 
    required this.forum, 
    required this.studentNo
  }) : super(key: key);

  @override
  _CommentScreenState createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final _forumService = ForumService();
  final _commentController = TextEditingController();
  List<Comment> _comments = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  void _loadComments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final comments = await _forumService.fetchComments(widget.forum.id);
      setState(() {
        // Sort comments by most recent first
        _comments = comments..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading comments: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _submitComment() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment cannot be empty')),
      );
      return;
    }

    try {
      final result = await _forumService.addComment(
        widget.studentNo, 
        widget.forum.id, 
        _commentController.text.trim()
      );

      if (result['success'] == true) {
        // Clear the text field
        _commentController.clear();
        
        // Reload comments
        _loadComments();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Failed to add comment')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting comment: $e')),
      );
    }
  }

  bool _isAuthorOfForum(Forum forum) {
    return forum.authorStudentNo == widget.studentNo;
  }

  void _deleteForum() async {
    // Show confirmation dialog
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Forum'),
        content: Text('Are you sure you want to delete this forum? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    // If user confirms deletion
    if (confirmDelete == true) {
      try {
        final result = await _forumService.deleteForum(widget.studentNo, widget.forum.id);

        if (result['success'] == true) {
          // Navigate back to previous screen
          Navigator.of(context).pop(true);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Forum deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Failed to delete forum'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        // Handle any network or unexpected errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting forum: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.forum.authorName}'),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadComments,
            ),
            
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 8,
            child: Column(
              children: [
                // Forum details
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'By ${widget.forum.authorName}',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                          // Delete Forum Option
                          if (_isAuthorOfForum(widget.forum))
                            PopupMenuButton<String>(
                              icon: Icon(Icons.more_horiz, size: 20), // Three dots icon
                              onSelected: (String choice) {
                                switch (choice) {
                                  case 'delete':
                                    _deleteForum();
                                    break;
                                }
                              },
                              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      SizedBox(width: 10),
                                      Text('Delete Forum', style: TextStyle(color: Colors.black)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text(
                        widget.forum.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: 15),
                      Text(
                        widget.forum.content,
                        style: TextStyle(fontSize: 16),
                      ),
                      
                    ],
                  ),
                ),

                Divider(thickness: 2.0,),
                
                // Comments List
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _comments.isEmpty
                          ? const Center(child: Text('No comments yet'))
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: _comments.length,
                              itemBuilder: (context, index) {
                                final comment = _comments[index];
                                return Column(
                                  children: [
                                    SizedBox(height: 5),
                                    Card(
                                      elevation: 5,
                                      child: ListTile(
                                        title: Text(
                                          '${comment.authorName} • ${_formatDateTime(comment.createdAt)}',
                                          style: TextStyle(fontWeight: FontWeight.w900),
                                        ),
                                        subtitle: Text(comment.content, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                ),
            
                // Comment Input
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          keyboardType: TextInputType.multiline,
                          maxLines: null,
                          decoration: InputDecoration(
                            hintText: 'Add a comment...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: Colors.black),
                        onPressed: _submitComment,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final commentDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    // Format time in 12-hour format
    final timeString = DateFormat('h:mm a').format(dateTime);

    // Contextual date formatting
    if (commentDate == today) {
      return 'Today, $timeString';
    } else if (commentDate == yesterday) {
      return 'Yesterday, $timeString';
    } else if (dateTime.year == now.year) {
      // If in the same year, show month, day, and time
      return '${DateFormat('MMM d').format(dateTime)}, $timeString';
    } else {
      // If in a different year, show full date with time
      return '${DateFormat('MMM d, yyyy').format(dateTime)}, $timeString';
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
