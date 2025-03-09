import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:SSCVote/admin_pages/candidates.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UpdateCandidatePage extends StatefulWidget {
  final Map candidate;
  final List<String> positions;
  final List<String> partylists;

  const UpdateCandidatePage({
    Key? key,
    required this.candidate,
    required this.positions,
    required this.partylists,
  }) : super(key: key);

  @override
  _UpdateCandidatePageState createState() => _UpdateCandidatePageState();
}

class _UpdateCandidatePageState extends State<UpdateCandidatePage> {
  late TextEditingController studentnoController;
  late TextEditingController lastnameController;
  late TextEditingController firstnameController;
  late TextEditingController middlenameController;
  late TextEditingController courseController;
  late TextEditingController sectionController;
  late TextEditingController sloganController;

  String? selectedPosition;
  String? selectedPartylist;
  XFile? _pickedImage;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageFile;
  bool _isUploadingImage = false;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing candidate data
    studentnoController = TextEditingController(text: widget.candidate['studentno']);
    lastnameController = TextEditingController(text: widget.candidate['lastname']);
    firstnameController = TextEditingController(text: widget.candidate['firstname']);
    middlenameController = TextEditingController(text: widget.candidate['middlename'] ?? '');
    courseController = TextEditingController(text: widget.candidate['course']);
    sectionController = TextEditingController(text: widget.candidate['section']);
    sloganController = TextEditingController(text: widget.candidate['slogan']);

    // Ensure selectedPosition and selectedPartylist are valid
    selectedPosition = widget.candidate['position'] ?? widget.positions.first;
    selectedPartylist = widget.candidate['partylist'] ?? widget.partylists.first;
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _imageFile = bytes;
          _pickedImage = image;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _uploadImageToDatabase() async {
    if (_imageFile == null) return null;

    try {
      String base64Image = base64Encode(_imageFile!);
      return base64Image;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Image conversion failed: $e'),
        ),
      );
      return null;
    }
  }

  Future<void> _updateCandidate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://studentcouncil.bcp-sms1.com/php/update_candidate.php'),
      );

      String? base64Image;
      if (_imageFile != null) {
        base64Image = await _uploadImageToDatabase();
        if (base64Image == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.red,
              content: Text('Image upload failed.'),
            ),
          );
          setState(() {
            _isUpdating = false;
          });
          return;
        }
      }

      request.fields['original_studentno'] = widget.candidate['studentno'];
      request.fields['studentno'] = studentnoController.text;
      request.fields['lastname'] = lastnameController.text;
      request.fields['firstname'] = firstnameController.text;
      request.fields['middlename'] = middlenameController.text;
      request.fields['course'] = courseController.text;
      request.fields['section'] = sectionController.text;
      request.fields['slogan'] = sloganController.text;
      request.fields['position'] = selectedPosition ?? '';
      request.fields['partylist'] = selectedPartylist ?? '';

      if (base64Image != null) {
        request.fields['img'] = base64Image;
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Candidate updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Update failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update candidate'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Candidate'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 5,
                blurRadius: 7,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 150,
                      height: 150,
                      child: _buildImageWidget(),
                    ),
                  ),
                  const Text("Tap image to change"),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: TextFormField(
                      readOnly: true,
                      controller: studentnoController,
                      decoration: const InputDecoration(labelText: 'Student Number'),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter student number'
                          : null,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: TextFormField(
                      readOnly: true,
                      controller: lastnameController,
                      decoration: const InputDecoration(labelText: 'Last Name'),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter last name'
                          : null,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: TextFormField(
                      readOnly: true,
                      controller: firstnameController,
                      decoration: const InputDecoration(labelText: 'First Name'),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter first name'
                          : null,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: TextFormField(
                      readOnly: true,
                      controller: middlenameController,
                      decoration: const InputDecoration(labelText: 'Middle Name'),
                      // Middle name is optional, so no validator
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: TextFormField(
                      controller: courseController,
                      decoration: const InputDecoration(labelText: 'Course'),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter course'
                          : null,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: TextFormField(
                      controller: sectionController,
                      decoration: const InputDecoration(labelText: 'Section'),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter section'
                          : null,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: TextFormField(
                      controller: sloganController,
                      decoration: const InputDecoration(labelText: 'Slogan'),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter slogan'
                          : null,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: DropdownButtonFormField<String>(
                      value: selectedPosition,
                      decoration: const InputDecoration(labelText: 'Position'),
                      items: widget.positions.map((String position) {
                        return DropdownMenuItem<String>(
                          value: position,
                          child: Text(position),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedPosition = newValue;
                        });
                      },
                      validator: (value) => value == null
                          ? 'Please select a position'
                          : null,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: DropdownButtonFormField<String>(
                      value: selectedPartylist,
                      decoration: const InputDecoration(labelText: 'Partylist'),
                      items: [
                        const DropdownMenuItem<String>(
                          value: '',
                          child: Text('None'),
                        ),
                        ...widget.partylists.map((String partylist) {
                          return DropdownMenuItem<String>(
                            value: partylist,
                            child: Text(partylist),
                          );
                        }).toList(),
                      ],
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedPartylist = newValue;
                        });
                      },
                      validator: (value) => value == null
                          ? 'Please select a partylist'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isUpdating ? null : _updateCandidate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                    ),
                    child: _isUpdating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Update Candidate', style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CandidatesPage()),
                      );
                    },
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageWidget() {
    return ClipOval(
      child: Container(
        width: 150,
        height: 150,
        color: Colors.grey[200],
        child: _getImageOrPlaceholder(),
      ),
    );
  }

  Widget _getImageOrPlaceholder() {
    if (_imageFile != null) {
      // If a new image is picked, display it
      return Image.memory(
        _imageFile!,
        fit: BoxFit.cover,
        width: 150,
        height: 150,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.error, color: Colors.red);
        },
      );
    } else if (widget.candidate['img'] != null && widget.candidate['img'].isNotEmpty) {
      // If there's an existing image, try to display it
      try {
        // Debug: Print the image data
        // print('Image data: ${widget.candidate['img']}');

        // Remove the Base64 prefix if it exists
        String base64Image = widget.candidate['img'];
        if (base64Image.startsWith('data:image')) {
          base64Image = base64Image.split(',').last;
        }

        // Decode the Base64 string and display the image
        return Image.memory(
          base64Decode(base64Image),
          fit: BoxFit.cover,
          width: 150,
          height: 150,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.broken_image, color: Colors.grey);
          },
        );
      } catch (e) {
        // If decoding fails, log the error and show a placeholder
        print('Error decoding image: $e');
        return const Icon(Icons.camera_alt, color: Colors.grey);
      }
    } else {
      // If no image is available, show a placeholder
      return const Icon(Icons.camera_alt, color: Colors.grey, size: 50);
    }
  }

  @override
  void dispose() {
    studentnoController.dispose();
    lastnameController.dispose();
    firstnameController.dispose();
    middlenameController.dispose();
    courseController.dispose();
    sectionController.dispose();
    sloganController.dispose();
    super.dispose();
  }
}