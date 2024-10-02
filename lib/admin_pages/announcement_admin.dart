import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart'; // For date formatting

class AnnouncementPage extends StatefulWidget {
  @override
  _AnnouncementPageState createState() => _AnnouncementPageState();
}

class _AnnouncementPageState extends State<AnnouncementPage> {
  final _formKey = GlobalKey<FormState>();
  String? _title;
  String? _description;
  Uint8List? _imageData; // Image data as Uint8List
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false; // Loading state
  List<dynamic> _announcements = []; // List to store announcements

  @override
  void initState() {
    super.initState();
    _fetchAnnouncements(); // Fetch announcements when the page loads
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _imageData = await pickedFile.readAsBytes();
      setState(() {});
    }
  }

  Future<void> _uploadAnnouncement() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isLoading = true; // Start loading
      });

      try {
        final imageUrl = await uploadImageToCloudinary(_imageData!, _title!);
        if (imageUrl != null) {
          await saveAnnouncement(_title!, _description!, imageUrl);
          _formKey.currentState!.reset();
          _imageData = null;
          _fetchAnnouncements(); // Refresh the list after adding an announcement
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit announcement: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false; // End loading
        });
      }
    }
  }

  Future<String?> uploadImageToCloudinary(Uint8List imageData, String title) async {
    final url = Uri.parse('https://api.cloudinary.com/v1_1/dcmdta4rb/image/upload');
    String formattedDate = DateFormat('yyyyMMdd').format(DateTime.now());
    String filename = 'announcement_${title}_$formattedDate.jpg';

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = 'sjon389q'
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        imageData,
        filename: filename,
      ));

    final response = await request.send();
    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final Map<String, dynamic> jsonResponse = jsonDecode(respStr);
      return jsonResponse['secure_url'];
    } else {
      throw Exception('Failed to upload image');
    }
  }

  Future<void> saveAnnouncement(String title, String description, String imageUrl) async {
    final response = await http.post(
      Uri.parse('http://192.168.1.6/for_testing/announcement.php'),
      body: {
        'title': title,
        'description': description,
        'image_url': imageUrl,
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Announcement added successfully!')),
      );
    } else {
      throw Exception('Failed to save announcement');
    }
  }

  // Fetch announcements from the server
  Future<void> _fetchAnnouncements() async {
    final response = await http.get(
      Uri.parse('http://192.168.1.6/for_testing/get_announcements.php'),
    );

    if (response.statusCode == 200) {
      setState(() {
        _announcements = jsonDecode(response.body); // Update the announcement list
      });
    } else {
      throw Exception('Failed to load announcements');
    }
  }

  // Delete announcement
  Future<void> _deleteAnnouncement(int id) async {
    final response = await http.post(
      Uri.parse('http://192.168.1.6/for_testing/delete_announcement.php'),
      body: {'id': id.toString()},
    );

    if (response.statusCode == 200) {
      _fetchAnnouncements(); // Refresh the list after deletion
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Announcement deleted successfully!')),
      );
    } else {
      throw Exception('Failed to delete announcement');
    }
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Announcement'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Title'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _title = value;
                      },
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 4,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _description = value;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(_imageData != null ? 'Image selected' : 'No image selected'),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _pickImage,
                          child: const Text('Upload Image'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _isLoading
                        ? CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: _uploadAnnouncement,
                            child: const Text('Submit Announcement'),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Display the list of announcements
              ListView.builder(
                shrinkWrap: true,
                itemCount: _announcements.length,
                itemBuilder: (context, index) {
                  final announcement = _announcements[index];
                  return Card(
                    child: ListTile(
                      title: Text(announcement['title']),
                      subtitle: Text(announcement['description']),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              // Show confirmation dialog before deletion
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('Confirm Deletion'),
                                    content: Text('Are you sure you want to delete this announcement?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop(); // Dismiss the dialog
                                        },
                                        child: Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop(); // Dismiss the dialog
                                          _deleteAnnouncement(announcement['id']); // Proceed with deletion
                                        },
                                        child: Text('Delete'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
