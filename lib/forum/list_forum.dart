import 'package:SSCVote/forum/comment_screen.dart';
import 'package:SSCVote/forum/create_forum_page.dart';
import 'package:SSCVote/forum/model_forum.dart';
import 'package:SSCVote/forum/service_forum.dart';
import 'package:SSCVote/main.dart';
import 'package:SSCVote/voter_pages/announcement.dart';
import 'package:SSCVote/voter_pages/drawerbar.dart';
import 'package:SSCVote/voter_pages/profile.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ForumsListScreen extends StatefulWidget {
  final String studentNo;

  const ForumsListScreen({Key? key, required this.studentNo}) : super(key: key);

  @override
  _ForumsListScreenState createState() => _ForumsListScreenState();
}

class _ForumsListScreenState extends State<ForumsListScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _forumService = ForumService();
  List<Forum> _forums = [];
  Map<int, int> _commentCountCache = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadForums();
  }

  void _loadForums() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final forums = await _forumService.fetchForums();
      setState(() {
        _forums = forums;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading forums: $e')),
      );
    }
  }

  void _handleLike(Forum forum, bool isLike) async {
  try {
    final result = await _forumService.likeForum(
      widget.studentNo, 
      forum.id, 
      isLike
    );

    print('Like/Dislike Result: $result'); // Debug print

    if (result['success'] == true) {
      setState(() {
        // Update the forum's like/dislike counts
        final index = _forums.indexWhere((f) => f.id == forum.id);
        if (index != -1) {
          _forums[index] = Forum(
            id: forum.id,
            title: forum.title,
            content: forum.content,
            authorName: forum.authorName,
            createdAt: forum.createdAt,
            totalLikes: result['total_likes'] ?? 0,
            totalDislikes: result['total_dislikes'] ?? 0,
            authorStudentNo: forum.authorStudentNo,
          );
        }
      });
    } else {
      // Show error message if the like/dislike was not successful
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Failed to like/dislike forum'),
        ),
      );
    }
  } catch (e) {
    print('Error in _handleLike: $e'); // Debug print
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error liking/disliking forum: $e')),
    );
  }
}

// Method to get comment count
  Future<int> _getCommentCount(Forum forum) async {
    // Check if count is already in cache
    if (_commentCountCache.containsKey(forum.id)) {
      return _commentCountCache[forum.id]!;
    }

    try {
      // Fetch comment count
      final count = await _forumService.getCommentCount(forum.id);
      
      // Cache the count
      setState(() {
        _commentCountCache[forum.id] = count;
      });

      return count;
    } catch (e) {
      print('Error fetching comment count: $e');
      return 0;
    }
  }

  bool _isAuthorOfForum(Forum forum) {
    return forum.authorStudentNo == widget.studentNo;
  }


  void _deleteForum(Forum forum) async {
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
        final result = await _forumService.deleteForum(widget.studentNo, forum.id);

        if (result['success'] == true) {
          // Remove the forum from the list
          setState(() {
            _forums.removeWhere((f) => f.id == forum.id);
          });

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


Widget _buildCommentCountWidget(Forum forum) {
    return FutureBuilder<int>(
      future: _getCommentCount(forum),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('0'); // Show 0 while loading
        }
        return Text('${snapshot.data ?? 0}');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.grey[200],
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            height: 56,
            alignment: Alignment.center,
            margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                onPressed: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
                icon: const Icon(Icons.menu, color: Colors.black45),
              ),
              const Text(
                'Forums',
                style: TextStyle(fontSize: 18, color: Colors.black54),
              ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    _loadForums();
                  },
                ),
                  _buildProfileMenu(context)
                ],
              )
            ],
          )
          ),
        ),
        drawer: const AppDrawer(),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
          itemCount: _forums.length,
          itemBuilder: (context, index) {
            final forum = _forums[index];
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: ListTile(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('By ${forum.authorName}', style: TextStyle(fontWeight: FontWeight.w900)),
                        // Delete Forum
                        if (_isAuthorOfForum(forum))
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_horiz), // Three dots icon
                            onSelected: (String choice) {
                              switch (choice) {
                                case 'delete':
                                  _deleteForum(forum);
                                  break;
                                // case 'edit':
                                //   _deleteForum(forum);
                                //   break;
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
                              // PopupMenuItem<String>(
                              //   value: 'edit',
                              //   child: Row(
                              //     children: [
                              //       Icon(Icons.edit, color: Colors.black),
                              //       SizedBox(width: 8),
                              //       Text('Edit', style: TextStyle(color: Colors.black)),
                              //     ],
                              //   ),
                              // ),
                            ],
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(forum.title, style: TextStyle(fontWeight: FontWeight.w800)),
                    SizedBox(height: 15),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        // Create a TextPainter to calculate if text exceeds 10 lines
                        final textPainter = TextPainter(
                          text: TextSpan(
                            text: forum.content,
                            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                          ),
                          maxLines: 10,
                          textDirection: TextDirection.ltr,
                        )..layout(maxWidth: constraints.maxWidth);

                        // Check if text is truncated
                        final bool isTextTruncated = textPainter.didExceedMaxLines;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              forum.content, 
                              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14), 
                              maxLines: 10,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (isTextTruncated)
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CommentScreen(
                                        forum: forum,
                                        studentNo: widget.studentNo,
                                      ),
                                    ),
                                  ).then((result) {
                                    // If the forum was deleted from the CommentScreen
                                    if (result == true) {
                                      _loadForums(); // Refresh the forums list
                                    }
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: Text(
                                      'See more...',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.thumb_up),
                              onPressed: () => _handleLike(forum, true),
                            ),
                            Text('${forum.totalLikes}'),
                            IconButton(
                              icon: const Icon(Icons.comment),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CommentScreen(
                                      forum: forum,
                                      studentNo: widget.studentNo,
                                    ),
                                  ),
                                ).then((result) {
                                  // If the forum was deleted from the CommentScreen
                                  if (result == true) {
                                    _loadForums(); // Refresh the forums list
                                  }
                                });
                              },
                            ),
                            _buildCommentCountWidget(forum),
                            IconButton(
                              icon: const Icon(Icons.thumb_down),
                              onPressed: () => _handleLike(forum, false),
                            ),
                            Text('${forum.totalDislikes}'),
                          ],
                        ),
                      ],
                    ),
                  ),

                ),
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.black,
          onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateForumScreen(
                      studentNo: widget.studentNo
                    ),
                  ),
                ).then((result) {
                  if (result == true) {
                    _loadForums(); // Refresh forums if a new one was created
                  }
                });
              },
          child: const Icon(Icons.add, color: Colors.white,),
        ),
      ),
    );
  }
}

Widget _buildProfileMenu(BuildContext context) {
    return PopupMenuButton<int>(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onSelected: (item) {
        switch (item) {
          case 0:
            // Navigate to Profile page
            Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileInfoPage()));
            break;
          case 1:
            // Handle sign out
            _logout(context); // Example action for Sign Out
            break;
        }
      },
      offset: Offset(0, 50), // Adjust dropdown position
      itemBuilder: (context) => [
        PopupMenuItem<int>(
          padding: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
          value: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Signed in as', style: TextStyle(color: Colors.black54)),
              Text(studentNo ?? 'Unknown'),
            ],
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem<int>(
          value: 0,
          child: Row(
            children: [
              Icon(Icons.person, color: Colors.black54),
              SizedBox(width: 10),
              Text('Profile'),
            ],
          ),
        ),
        PopupMenuItem<int>(
          value: 1,
          child: Row(
            children: [
              Icon(Icons.logout, color: Colors.black54),
              SizedBox(width: 10),
              Text('Sign out'),
            ],
          ),
        ),
      ],
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: Colors.black54),
          ),
        ],
      ),
    );
  }
  
  void _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!context.mounted) return; // Ensure the widget is still mounted

    // Use pushAndRemoveUntil to clear the navigation stack
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoadingScreen()), // Replace with your login page
      (Route<dynamic> route) => false, // Remove all previous routes
    );
  }