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
  bool _isSubmittingForum = false;

  void _submitForum() async {
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
      bool success = await _forumService.createForum(
        widget.studentNo,
        _titleController.text,
        _contentController.text,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Forum created successfully!'), backgroundColor: Colors.green,),
        );
        Navigator.pop(context, true); // Return to previous screen
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating forum: $e'), backgroundColor: Colors.red,),
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
      appBar: AppBar(title: const Text('Create Forum')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              keyboardType: TextInputType.multiline,
              maxLines: 3,
              minLines: 3,
              maxLength: null,
              decoration: const InputDecoration(
                labelText: 'Forum Title',
                border: OutlineInputBorder(),
              ),
              enabled: !_isSubmittingForum,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              keyboardType: TextInputType.multiline,
              maxLength: null,
              decoration: const InputDecoration(
                labelText: 'Forum Content',
                border: OutlineInputBorder(),
              ),
              maxLines: 6,
              minLines: 6,
              enabled: !_isSubmittingForum,
            ),
            const SizedBox(height: 16),
            _isSubmittingForum
                ? const CircularProgressIndicator()
                : ElevatedButton(
                  style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.black),
                ),
                  onPressed: _submitForum,
                  child: const Text('Create Forum', style: TextStyle(color: Colors.white),),
                ),
          ],
        ),
      ),
    );
  }
}