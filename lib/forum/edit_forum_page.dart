import 'package:SSCVote/forum/model_forum.dart';
import 'package:SSCVote/forum/service_forum.dart';
import 'package:flutter/material.dart';

class EditForumScreen extends StatefulWidget {
  final Forum forum;
  final String studentNo;

  const EditForumScreen({
    Key? key, 
    required this.forum, 
    required this.studentNo
  }) : super(key: key);

  @override
  _EditForumScreenState createState() => _EditForumScreenState();
}

class _EditForumScreenState extends State<EditForumScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  final _forumService = ForumService();
  bool _isSubmittingForum = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing forum data
    _titleController = TextEditingController(text: widget.forum.title);
    _contentController = TextEditingController(text: widget.forum.content);
  }

  void _updateForum() async {
    if (_contentController.text.trim().isEmpty || _titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title or Content cannot be empty')),
      );
      return;
    }
    // Set loading state
    setState(() {
      _isSubmittingForum = true;
    });

    try {
      final result = await _forumService.editForum(
        widget.studentNo, 
        widget.forum.id, 
        _titleController.text, 
        _contentController.text
      );

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Forum updated successfully!'), 
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return to previous screen with success
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to update forum'), 
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating forum: $e'), 
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmittingForum = false;
      });
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Forum'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Forum Title',
                border: OutlineInputBorder(),
              ),
              maxLines: null,
              maxLength: null,
              enabled: !_isSubmittingForum,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Forum Content',
                border: OutlineInputBorder(),
              ),
              maxLines: 6,
              enabled: !_isSubmittingForum,
            ),
            const SizedBox(height: 16),
            _isSubmittingForum
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _updateForum,
                    child: const Text('Update Forum'),
                  ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}
