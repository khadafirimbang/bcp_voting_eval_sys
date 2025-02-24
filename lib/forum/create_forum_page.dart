import 'package:SSCVote/forum/service_forum.dart';
import 'package:flutter/material.dart';

class CreateForumScreen extends StatefulWidget {
  final String studentNo;

  const CreateForumScreen({Key? key, required this.studentNo}) : super(key: key);

  @override
  _CreateForumScreenState createState() => _CreateForumScreenState();
}

class _CreateForumScreenState extends State<CreateForumScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _forumService = ForumService();

  void _submitForum() async {
    try {
      bool success = await _forumService.createForum(
        widget.studentNo,
        _titleController.text,
        _contentController.text,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Forum created successfully!')),
        );
        Navigator.pop(context, true); // Return to previous screen
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating forum: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Forum')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              keyboardType: TextInputType.multiline,
              maxLength: null,
              decoration: const InputDecoration(labelText: 'Forum Title'),
            ),
            TextField(
              controller: _contentController,
              keyboardType: TextInputType.multiline,
              maxLength: null,
              decoration: const InputDecoration(labelText: 'Forum Content'),
              maxLines: 4,
            ),
            ElevatedButton(
              onPressed: _submitForum,
              child: const Text('Create Forum'),
            ),
          ],
        ),
      ),
    );
  }
}