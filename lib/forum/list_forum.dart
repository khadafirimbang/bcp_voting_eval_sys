import 'package:SSCVote/forum/comment_screen.dart';
import 'package:SSCVote/forum/create_forum_page.dart';
import 'package:SSCVote/forum/edit_forum_page.dart';
import 'package:SSCVote/forum/model_forum.dart';
import 'package:SSCVote/forum/service_forum.dart';
import 'package:SSCVote/main.dart';
import 'package:SSCVote/voter_pages/announcement.dart';
import 'package:SSCVote/voter_pages/drawerbar.dart';
import 'package:SSCVote/voter_pages/profile.dart';
import 'package:SSCVote/voter_pages/profile_menu.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ForumsListScreen extends StatefulWidget {
  final String studentNo;

  const ForumsListScreen({Key? key, required this.studentNo}) : super(key: key);

  @override
  _ForumsListScreenState createState() => _ForumsListScreenState();
}

// Enum for sorting options
  enum ForumSortOption {
    newest,
    oldest,
    popular,
    myForums
  }

class _ForumsListScreenState extends State<ForumsListScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _forumService = ForumService();
  List<Forum> _forums = [];
  bool _isLoading = false;
  // Current selected sort option
  ForumSortOption _currentSortOption = ForumSortOption.newest;
  List<Forum> _originalForums = []; // To store the original list of forums
  Map<int, int> _commentCountCache = {};
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

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
      await _preloadCommentCounts(forums);
      setState(() {
        _originalForums = forums;
        _forums = List.from(_originalForums);
        _sortForums(ForumSortOption.newest); // Default sorting
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading forums: $e')),
      );
    }
  }

  void _sortForums(ForumSortOption option) {
    setState(() {
      _currentSortOption = option;
      
      switch (option) {
        case ForumSortOption.newest:
          _forums = List.from(_originalForums)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case ForumSortOption.oldest:
          _forums = List.from(_originalForums)
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
          break;
        case ForumSortOption.popular:
          _forums = List.from(_originalForums)
            ..sort((a, b) {
              // Sort by total interactions (likes + comments)
              return _calculatePopularity(b).compareTo(_calculatePopularity(a));
            });
          break;
        case ForumSortOption.myForums:
          _forums = _originalForums
              .where((forum) => _isAuthorOfForum(forum))
              .toList();
          break;
      }
    });
  }

  // Preload comment counts for all forums
  Future<void> _preloadCommentCounts(List<Forum> forums) async {
    _commentCountCache.clear();
    for (var forum in forums) {
      try {
        int commentCount = await _forumService.getCommentCount(forum.id);
        _commentCountCache[forum.id] = commentCount;
      } catch (e) {
        print('Error loading comment count for forum ${forum.id}: $e');
        _commentCountCache[forum.id] = 0;
      }
    }
  }

  // Helper method to calculate forum popularity
  int _calculatePopularity(Forum forum) {
    // Get cached comment count, default to 0 if not found
    int commentCount = _commentCountCache[forum.id] ?? 0;
    // print('comments: $commentCount');
    
    // Calculate popularity as total likes plus total comments
    return forum.totalLikes + commentCount;
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


  bool _isAuthorOfForum(Forum forum) {
    print('Current Student No: ${widget.studentNo}');
  print('Forum Author Student No: ${forum.authorStudentNo}');
  bool isAuthor = forum.authorStudentNo == widget.studentNo;
  print('Is Author: $isAuthor');
  return isAuthor;
  }


  void _deleteForum(Forum forum) async {
    // Show confirmation dialog
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Forum'),
        content: const Text('Are you sure you want to delete this forum? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
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
            const SnackBar(
              content: Text('Forum deleted successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Optional: Navigate back if this was the last forum or in a detail view
          if (_forums.isEmpty) {
            Navigator.of(context).pop();
          }
        } else {
          // Show specific error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Failed to delete forum'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        // Handle any network or unexpected errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting forum: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }


  void _editForum(Forum forum) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditForumScreen(
          forum: forum,
          studentNo: widget.studentNo,
        ),
      ),
    );

    // If forum was successfully updated, refresh the list
    if (result == true) {
      _loadForums();
    }
  }


  Widget _buildCommentCountWidget(Forum forum) {
    return StatefulBuilder(
      builder: (context, setState) {
        return FutureBuilder<int>(
          future: _forumService.getCommentCount(forum.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('0'); // Show 0 while loading
            }
            return Text('${snapshot.data ?? 0}');
          },
        );
      },
    );
  }

  // New method for filtering forums
  void _filterForums(String query) {
    setState(() {
      if (query.isEmpty) {
        // If query is empty, reset to original list
        _forums = List.from(_originalForums);
      } else {
        // Filter forums by author name or forum title (case-insensitive)
        _forums = _originalForums.where((forum) {
          final lowercaseQuery = query.toLowerCase();
          return forum.authorName.toLowerCase().contains(lowercaseQuery) ||
                 forum.title.toLowerCase().contains(lowercaseQuery) ||
                 forum.content.toLowerCase().contains(lowercaseQuery);
        }).toList();
      }
    });
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
                          icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.black54),
                          onPressed: () {
                            setState(() {
                              _isSearching = !_isSearching;
                              if (!_isSearching) {
                                // Reset search when closing
                                _searchController.clear();
                                _filterForums('');
                              }
                            });
                          },
                        ),
                  PopupMenuButton<ForumSortOption>(
                      icon: Icon(Icons.filter_list, color: Colors.black54),
                      onSelected: _sortForums,
                      itemBuilder: (BuildContext context) => [
                        PopupMenuItem<ForumSortOption>(
                          value: ForumSortOption.newest,
                          child: Row(
                            children: [
                              Icon(Icons.new_releases_outlined, 
                                color: _currentSortOption == ForumSortOption.newest 
                                  ? Colors.black
                                  : Colors.black45
                              ),
                              SizedBox(width: 10),
                              Text('Newest', 
                                style: TextStyle(
                                  color: _currentSortOption == ForumSortOption.newest 
                                    ? Colors.black
                                    : Colors.black45                               )
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem<ForumSortOption>(
                          value: ForumSortOption.oldest,
                          child: Row(
                            children: [
                              Icon(Icons.history, 
                                color: _currentSortOption == ForumSortOption.oldest 
                                  ? Colors.black
                                  : Colors.black45
                              ),
                              SizedBox(width: 10),
                              Text('Oldest', 
                                style: TextStyle(
                                  color: _currentSortOption == ForumSortOption.oldest 
                                    ? Colors.black
                                    : Colors.black45                               )
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem<ForumSortOption>(
                          value: ForumSortOption.popular,
                          child: Row(
                            children: [
                              Icon(Icons.trending_up, 
                                color: _currentSortOption == ForumSortOption.popular 
                                  ? Colors.black
                                  : Colors.black45
                              ),
                              SizedBox(width: 10),
                              Text('Popular', 
                                style: TextStyle(
                                  color: _currentSortOption == ForumSortOption.popular 
                                    ? Colors.black
                                    : Colors.black45                               )
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem<ForumSortOption>(
                          value: ForumSortOption.myForums,
                          child: Row(
                            children: [
                              Icon(Icons.person_outline, 
                                color: _currentSortOption == ForumSortOption.myForums 
                                  ? Colors.black
                                  : Colors.black45
                              ),
                              SizedBox(width: 10),
                              Text('My Forums', 
                                style: TextStyle(
                                  color: _currentSortOption == ForumSortOption.myForums 
                                    ? Colors.black
                                    : Colors.black45                               )
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        _loadForums(); // This will reset to newest by default
                      },
                    ),
                    ProfileMenuVoter()
                ],
              )
            ],
          )
          ),
        ),
        drawer: const AppDrawer(),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Search field conditionally appears
              if (_isSearching)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by forum title or author...',
                      prefixIcon: Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterForums('');
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: _filterForums,
                  ),
                ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                              itemCount: _forums.length,
                              itemBuilder: (context, index) {
                    final forum = _forums[index];
                    return Column(
                      children: [
                        Card(
                          elevation: 4,
                          color: Colors.white,
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
                                        case 'edit':
                                          _editForum(forum);
                                          break;
                                      }
                                    },
                                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                      PopupMenuItem<String>(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            SizedBox(width: 8),
                                            Text('Edit', style: TextStyle(color: Colors.black)),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem<String>(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            SizedBox(width: 10),
                                            Text('Delete', style: TextStyle(color: Colors.black)),
                                          ],
                                        ),
                                      ),
                                      
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
                        
                      ],
                    );
                              },
                            ),
              ),
            ],
          ),
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

  @override
  void dispose() {
    // Don't forget to dispose of the search controller
    _searchController.dispose();
    super.dispose();
  }

}
