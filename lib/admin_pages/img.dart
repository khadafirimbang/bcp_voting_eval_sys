// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';

// class ImagePage extends StatefulWidget {
//   const ImagePage({super.key});

//   @override
//   State<ImagePage> createState() => _ImagePageState();
// }

// class _ImagePageState extends State<ImagePage> {
//   File? _imageFile;
//   String? _imageUrl;

//   Future<void> _pickImage(ImageSource source) async {
//     final ImagePicker picker = ImagePicker();
//     final XFile? pickedFile = await picker.pickImage(source: source);
//     setState(() {
//       if(pickedFile != null) _imageFile = File(pickedFile.path);
//     });
//   }

//   Future<void> _uploadImage() async {

//   }


  
//   @override
//   Widget build(BuildContext context) {
//     return const Placeholder();
//   }
// }

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data'; // Import for Uint8List
import 'dart:html' as html; // Import for web file handling

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Upload Image to Cloudinary')),
        body: ImageUploader(),
      ),
    );
  }
}

class ImageUploader extends StatefulWidget {
  @override
  _ImageUploaderState createState() => _ImageUploaderState();
}

class _ImageUploaderState extends State<ImageUploader> {
  XFile? _image; // Use XFile to pick images
  String? _uploadedImageUrl;
  Uint8List? _imageBytes; // To hold image bytes for display

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = pickedFile;
        _readImageBytes(); // Read image bytes after picking the image
      });
    }
  }

  Future<void> _readImageBytes() async {
    if (_image == null) return;

    final reader = html.FileReader();
    final completer = Completer<Uint8List>();

    reader.onLoadEnd.listen((_) {
      completer.complete(reader.result as Uint8List);
    });

    reader.readAsArrayBuffer(html.File([await _image!.readAsBytes()], _image!.name));
    final fileBytes = await completer.future;

    setState(() {
      _imageBytes = fileBytes;
    });
  }

  Future<void> _uploadImage() async {
    if (_imageBytes == null) return;

    final url = Uri.parse('https://api.cloudinary.com/v1_1/dcmdta4rb/image/upload');
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = 'sjon389q'
      ..files.add(http.MultipartFile.fromBytes('file', _imageBytes!, filename: _image!.name));

    final response = await request.send();
    if (response.statusCode == 200) {
      final responseData = await http.Response.fromStream(response);
      final data = json.decode(responseData.body);
      setState(() {
        _uploadedImageUrl = data['secure_url'];
      });
    } else {
      print('Failed to upload image');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _imageBytes == null
              ? Text('No image selected.')
              : Image.memory(_imageBytes!), // Use Image.memory for Web
          ElevatedButton(
            onPressed: _pickImage,
            child: Text('Pick Image'),
          ),
          ElevatedButton(
            onPressed: _uploadImage,
            child: Text('Upload Image'),
          ),
          _uploadedImageUrl == null
              ? Container()
              : Image.network(_uploadedImageUrl!),
        ],
      ),
    );
  }
}
