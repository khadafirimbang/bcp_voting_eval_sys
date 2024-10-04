import 'package:flutter/material.dart';
import 'package:for_testing/admin_pages/drawerbar_admin.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class AnnouncementAdminPage extends StatefulWidget {
  @override
  _AnnouncementAdminPageState createState() => _AnnouncementAdminPageState();
}

class _AnnouncementAdminPageState extends State<AnnouncementAdminPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  Uint8List? _imageData;
  String? _existingImageUrl; // Store the existing image URL
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  List<dynamic> _announcements = [];
  int? _editingId;

  @override
  void initState() {
    super.initState();
    _fetchAnnouncements();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final imageBytes = await pickedFile.readAsBytes();
      setState(() {
        _imageData = imageBytes;
      });
    }
  }

  Future<void> _uploadAnnouncement() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isLoading = true;
      });

      try {
        String? imageUrl;

        // Check if a new image is selected; if not, use the existing image URL
        if (_imageData != null) {
          imageUrl = await uploadImageToCloudinary(_imageData!, _titleController.text);
        } else {
          imageUrl = _existingImageUrl; // Retain the existing image URL if no new image
        }

        if (_editingId != null) {
          // Editing existing announcement
          await updateAnnouncement(_editingId!, _titleController.text, _descriptionController.text, imageUrl);
        } else {
          // New announcement
          await saveAnnouncement(_titleController.text, _descriptionController.text, imageUrl);
        }

        // Reset the form and variables after saving
        _formKey.currentState!.reset();
        setState(() {
          _titleController.clear(); // Clear the title
          _descriptionController.clear(); // Clear the description
          _imageData = null; // Reset the image data
          _existingImageUrl = null; // Reset the existing image URL
          _editingId = null; // Reset the editing ID
        });

        // Fetch the updated announcements list
        _fetchAnnouncements();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit announcement: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false; // Stop loading indicator
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

  Future<void> saveAnnouncement(String title, String description, String? imageUrl) async {
    final response = await http.post(
      Uri.parse('http://192.168.1.6/for_testing/announcement.php'),
      body: {
        'title': title,
        'description': description,
        'image_url': imageUrl ?? '',
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement added successfully!')),
      );
    } else {
      throw Exception('Failed to save announcement');
    }
  }

  Future<void> updateAnnouncement(int id, String title, String description, String? imageUrl) async {
    final response = await http.post(
      Uri.parse('http://192.168.1.6/for_testing/update_announcement.php'),
      body: {
        'id': id.toString(),
        'title': title,
        'description': description,
        'image_url': imageUrl ?? '',
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement updated successfully!')),
      );
    } else {
      throw Exception('Failed to update announcement');
    }
  }

  Future<void> _fetchAnnouncements() async {
    final response = await http.get(
      Uri.parse('http://192.168.1.6/for_testing/get_announcements.php'),
    );

    if (response.statusCode == 200) {
      setState(() {
        _announcements = jsonDecode(response.body);
      });
    } else {
      throw Exception('Failed to load announcements');
    }
  }

  Future<void> _deleteAnnouncement(int id) async {
    final response = await http.post(
      Uri.parse('http://192.168.1.6/for_testing/delete_announcement.php'),
      body: {'id': id.toString()},
    );

    if (response.statusCode == 200) {
      _fetchAnnouncements();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement deleted successfully!')),
      );
    } else {
      throw Exception('Failed to delete announcement');
    }
  }

  void _editAnnouncement(Map<String, dynamic> announcement) {
    setState(() {
      _editingId = announcement['id'];
      _titleController.text = announcement['title']; // Set the title
      _descriptionController.text = announcement['description']; // Set the description
      _existingImageUrl = announcement['image_url'];
      _imageData = null; // Reset image field for editing
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        title: const Text('Announcement', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer(); // Use this context
            },
                  );
          }
        ),
        actions: [
          IconButton(onPressed: (){
            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => AnnouncementAdminPage()),
                            );
          }, icon: const Icon(Icons.refresh))
        ],
      ),
      drawer: const AppDrawerAdmin(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text('Create Announcement', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 4,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(_imageData != null
                            ? 'Image selected'
                            : _existingImageUrl != null
                                ? 'Image exists'
                                : 'No image selected'),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _pickImage,
                          child: const Text('Upload Image'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : TextButton(
                              style: TextButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)
                                ),
                                padding: const EdgeInsets.all(14.0),
                                backgroundColor: const Color(0xFF1E3A8A),
                                
                              ),
                              onPressed: _uploadAnnouncement,
                              child: Text(_editingId != null
                                ? 'Update Announcement'
                                : 'Add Announcement', 
                                style: TextStyle(
                                  color: Colors.white,
                                  ),),
                            ),
                        // ElevatedButton(
                        //     onPressed: _uploadAnnouncement,
                        //     child: Text(_editingId != null
                        //         ? 'Update Announcement'
                        //         : 'Submit Announcement'),
                        //   ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Make the ListView scrollable
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.7, // Adjust height as needed
                child: ListView.builder(
                  itemCount: _announcements.length,
                  itemBuilder: (context, index) {
                    final announcement = _announcements[index];
                    return Card(
                      child: ListTile(
                        title: Text('Title: ${announcement['title']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Description: ${announcement['description']}'),
                            const SizedBox(height: 8),
                            // Check if the image URL exists and display the image or "No image"
                            if (announcement['image_url'] != null && announcement['image_url'].isNotEmpty)
                              Image.network(
                                announcement['image_url'],
                                height: 100,
                                width: 100,
                                fit: BoxFit.cover,
                              )
                            else
                              const Text('No image'),
                          ],
                        ),
                        trailing: Wrap(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editAnnouncement(announcement),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteAnnouncement(announcement['id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
