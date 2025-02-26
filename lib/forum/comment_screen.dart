import 'package:SSCVote/forum/edit_forum_page.dart';
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
  bool _isSubmittingComment = false;
  int? _editingCommentId;
  bool _showAllComments = false;
  late Forum _currentForum;

  @override
  void initState() {
    super.initState();
    _currentForum = widget.forum;
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
    String commentText = _commentController.text.trim();

    if (commentText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment cannot be empty')),
      );
      return;
    }

    // Set loading state
    setState(() {
      _isSubmittingComment = true;
    });

    try {
      // Check if we're editing an existing comment
      if (_editingCommentId != null) {
        // Edit existing comment
        final result = await _forumService.editComment(
          widget.studentNo, 
          _editingCommentId!, 
          commentText
        );

        if (result['success'] == true) {
          // Update the comment in the list
          setState(() {
            int index = _comments.indexWhere((c) => c.id == _editingCommentId);
            if (index != -1) {
              _comments[index] = Comment(
                id: _comments[index].id,
                forumId: _comments[index].forumId,
                studentNo: _comments[index].studentNo,
                content: commentText,
                authorName: _comments[index].authorName,
                createdAt: _comments[index].createdAt,
              );
            }
            
            // Reset editing state
            _editingCommentId = null;
          });

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Comment updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['error'] ?? 'Failed to edit comment')),
          );
        }
      } else {
        // Add new comment
        final result = await _forumService.addComment(
          widget.studentNo, 
          widget.forum.id, 
          commentText
        );

        if (result['success'] == true) {
          // Reload comments
          _loadComments();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['error'] ?? 'Failed to add comment')),
          );
        }
      }

      // Clear the text field
      _commentController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting comment: $e')),
      );
    } finally {
      // Always reset loading state
      setState(() {
        _isSubmittingComment = false;
      });
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

  void _editForum() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditForumScreen(
          forum: widget.forum,
          studentNo: widget.studentNo,
        ),
      ),
    );

    // If forum was successfully updated, refresh the screen or go back
    if (result == true) {
      // Option 1: Pop back to previous screen with updated status
      Navigator.of(context).pop(true);
    }
  }


  // Method to get displayed comments based on _showAllComments
  List<Comment> _getDisplayedComments() {
    if (_showAllComments) {
      return _comments;
    }
    return _comments.take(5).toList();
  }
  
  void _updateForum(Forum updatedForum) {
    setState(() {
      _currentForum = updatedForum;
    });
  }

  void _handleLike(bool isLike) async {
    try {
      final result = await _forumService.likeForum(
        widget.studentNo, 
        _currentForum.id, 
        isLike
      );

      if (result['success'] == true) {
        _updateForum(Forum(
          id: _currentForum.id,
          title: _currentForum.title,
          content: _currentForum.content,
          authorName: _currentForum.authorName,
          createdAt: _currentForum.createdAt,
          totalLikes: result['total_likes'] ?? 0,
          totalDislikes: result['total_dislikes'] ?? 0,
          authorStudentNo: _currentForum.authorStudentNo,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to like/dislike forum'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error liking/disliking forum: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
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
                            'By ${_currentForum.authorName}',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                          // Delete Forum Option
                          if (_isAuthorOfForum(_currentForum))
                            PopupMenuButton<String>(
                              icon: Icon(Icons.more_horiz, size: 20), // Three dots icon
                              onSelected: (String choice) {
                                switch (choice) {
                                  case 'delete':
                                    _deleteForum();
                                    break;
                                  case 'edit':
                                  _editForum();
                                  break;
                                }
                              },
                              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                PopupMenuItem<String>(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      SizedBox(width: 10),
                                      Text('Edit Forum', style: TextStyle(color: Colors.black)),
                                    ],
                                  ),
                                ),
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
                        _currentForum.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: 15),
                      Text(
                        _currentForum.content,
                        style: TextStyle(fontSize: 16),
                      ),
                      // Like and Dislike Row
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Like Button
                            IconButton(
                              icon: const Icon(Icons.thumb_up),
                              onPressed: () => _handleLike(true),
                            ),
                            Text('${_currentForum.totalLikes}'),

                            // Dislike Button
                            IconButton(
                              icon: const Icon(Icons.thumb_down),
                              onPressed: () => _handleLike(false),
                            ),
                            Text('${_currentForum.totalDislikes}'),
                          ],
                        ),
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
                      : Column(
                          children: [
                            ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: _getDisplayedComments().length,
                              itemBuilder: (context, index) {
                                final comment = _getDisplayedComments()[index];
                                return Column(
                                  children: [
                                    SizedBox(height: 5),
                                    Card(
                                      color: Colors.grey[300],
                                      child: ListTile(
                                        title: Text(
                                          '${comment.authorName}',
                                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              comment.content, 
                                              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)
                                            ),
                                            Text(
                                              '${_formatDateTime(comment.createdAt)}',
                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w200),
                                            )
                                          ],
                                        ),
                                        trailing: _buildCommentOptions(comment),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            // "See all comments" button
                            if (!_showAllComments && _comments.length > 10)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _showAllComments = true;
                                    });
                                  },
                                  child: Text('See all ${_comments.length} comments'),
                                ),
                              ),
                            // "Collapse comments" button when all comments are shown
                            if (_showAllComments && _comments.length > 5)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _showAllComments = false;
                                    });
                                  },
                                  child: Text('Collapse to 5 comments'),
                                ),
                              ),
                          ],
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
                            hintText: _editingCommentId != null 
                              ? 'Edit your comment...' 
                              : 'Add a comment...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            suffixIcon: _editingCommentId != null
                              ? IconButton(
                                  icon: Icon(Icons.close),
                                  onPressed: () {
                                    setState(() {
                                      _editingCommentId = null;
                                      _commentController.clear();
                                    });
                                  },
                                )
                              : null,
                          ),
                          // Disable text field while submitting
                          enabled: !_isSubmittingComment,
                        ),
                      ),
                      // Conditionally render send button or loading indicator
                      _isSubmittingComment
                        ? SizedBox(
                            width: 48, // Match the IconButton size
                            height: 48,
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                ),
                              ),
                            ),
                          )
                        : IconButton(
                            icon: Icon(Icons.send, color: Colors.black),
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

  // Method to build comment options
Widget _buildCommentOptions(Comment comment) {
  // Check if the current user is the author of the comment
  bool isCommentAuthor = comment.studentNo == widget.studentNo;

  if (!isCommentAuthor) return SizedBox.shrink();

  return PopupMenuButton<String>(
    icon: Icon(Icons.more_vert),
    onSelected: (String choice) {
      switch (choice) {
        case 'delete':
          _deleteComment(comment);
          break;
        case 'edit':
          _editComment(comment);
          break;
      }
    },
    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
      PopupMenuItem<String>(
        value: 'edit',
        child: Row(
          children: [
            SizedBox(width: 10),
            Text('Edit Comment', style: TextStyle(color: Colors.black)),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'delete',
        child: Row(
          children: [
            SizedBox(width: 10),
            Text('Delete Comment', style: TextStyle(color: Colors.black)),
          ],
        ),
      ),
    ],
  );
}

  // Method to handle comment deletion
  void _deleteComment(Comment comment) async {
    // Show confirmation dialog
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Comment'),
        content: Text('Are you sure you want to delete this comment? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete',),
          ),
        ],
      ),
    );

    // If user confirms deletion
    if (confirmDelete == true) {
      try {
        final result = await _forumService.deleteComment(widget.studentNo, comment.id);

        if (result['success'] == true) {
          // Remove the comment from the list
          setState(() {
            _comments.removeWhere((c) => c.id == comment.id);
          });

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Comment deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Failed to delete comment'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        // Handle any network or unexpected errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting comment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Method to handle comment editing
  void _editComment(Comment comment) {
  // Set the comment controller to the current comment content
  _commentController.text = comment.content;

  // Scroll to the bottom of the screen to show the comment input
  // This assumes you're using a SingleChildScrollView
  // If not, you might need to adjust this approach
  Future.delayed(Duration.zero, () {
    // Focus on the comment input field
    FocusScope.of(context).requestFocus();
  });

  // Temporarily store the comment being edited
  setState(() {
    _editingCommentId = comment.id;
  });
}

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
