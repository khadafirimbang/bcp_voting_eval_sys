import 'package:SSCVote/admin_pages/profile_menu_admin.dart';
import 'package:SSCVote/voter_pages/profile.dart';
import 'package:flutter/material.dart';
import 'package:SSCVote/admin_pages/dashboard2.dart';
import 'package:SSCVote/admin_pages/drawerbar_admin.dart';
import 'package:SSCVote/main.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnnouncementAdminPage extends StatefulWidget {
  const AnnouncementAdminPage({super.key});

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
      Uri.parse('https://studentcouncil.bcp-sms1.com/php/announcement.php'),
      body: {
        'title': title,
        'description': description,
        'image_url': imageUrl ?? '',
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.green, content: Text('Announcement added successfully!')),
      );
    } else {
      throw Exception('Failed to save announcement');
    }
  }

  Future<void> updateAnnouncement(int id, String title, String description, String? imageUrl) async {
    final response = await http.post(
      Uri.parse('https://studentcouncil.bcp-sms1.com/php/update_announcement.php'),
      body: {
        'id': id.toString(),
        'title': title,
        'description': description,
        'image_url': imageUrl ?? '',
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.green, content: Text('Announcement updated successfully!')),
      );
    } else {
      throw Exception('Failed to update announcement');
    }
  }

  Future<void> _fetchAnnouncements() async {
    final response = await http.get(
      Uri.parse('https://studentcouncil.bcp-sms1.com/php/get_announcements.php'),
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
    // Show a confirmation dialog before deleting
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Announcement'),
          content: const Text('Are you sure you want to delete this announcement? This action cannot be undone.'),
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
        );
      },
    );

    // Only proceed with deletion if user confirms
    if (confirmDelete == true) {
      try {
        final response = await http.post(
          Uri.parse('https://studentcouncil.bcp-sms1.com/php/delete_announcement.php'),
          body: {'id': id.toString()},
        );

        if (response.statusCode == 200) {
          await _fetchAnnouncements();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Colors.green, 
                content: Text('Announcement deleted successfully!')
              ),
            );
          }
        } else {
          throw Exception('Failed to delete announcement');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red, 
              content: Text('Error deleting announcement: ${e.toString()}')
            ),
          );
        }
      }
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
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[200],
        key: _scaffoldKey,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(56), // Set height of the AppBar
          child: Container(
            height: 56,
            alignment: Alignment.center, // Align the AppBar in the center
            margin: const EdgeInsets.fromLTRB(16, 10, 16, 0), // Add margin to control width
            decoration: BoxDecoration(
              color: Colors.white, 
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3), // Shadow color
                  blurRadius: 8, // Blur intensity
                  spreadRadius: 1, // Spread radius
                  offset: const Offset(0, 4), // Vertical shadow position
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
                  'Announcement',
                  style: TextStyle(fontSize: 18, color: Colors.black54),
                ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(onPressed: (){
                      _fetchAnnouncements();
                    }, icon: const Icon(Icons.refresh)),
                    ProfileMenu()
                  ],
                )
              ],
            )
          ),
        ),
        drawer: const AppDrawerAdmin(),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Card(
                  color: Colors.white,
                  elevation: 2,
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
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black
                                    ),
                                    onPressed: _pickImage,
                                    child: const Text('Upload Image', style: TextStyle(color: Colors.white),),
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
                                          padding: const EdgeInsets.all(10.0),
                                          backgroundColor: Colors.black,
                                          
                                        ),
                                        onPressed: _uploadAnnouncement,
                                        child: Text(_editingId != null
                                          ? 'Update Announcement'
                                          : 'Add Announcement', 
                                          style: const TextStyle(
                                            color: Colors.white,
                                            ),),
                                      ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Make the ListView scrollable
                SingleChildScrollView(
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7, // Adjust height as needed
                    child: ListView.builder(
                      itemCount: _announcements.length,
                      itemBuilder: (context, index) {
                        final announcement = _announcements[index];
                        return Card(
                          color: Colors.white,
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: ListTile(
                              title: Text('Title: ${announcement['title']}'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Description: ${announcement['description']}', maxLines: 3,),
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
                          ),
                        );
                      },
                    ),
                  ),
                ),
      
              ],
            ),
          ),
        ),
      ),
    );
  }
}
