import 'package:flutter/material.dart';
import 'package:for_testing/voter_pages/drawerbar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AnnouncementPage extends StatefulWidget {
  @override
  _AnnouncementPageState createState() => _AnnouncementPageState();
}

class _AnnouncementPageState extends State<AnnouncementPage> {
  List<dynamic> _announcements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAnnouncements();
  }

  Future<void> _fetchAnnouncements() async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.6/for_testing/get_announcements.php'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _announcements = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load announcements');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print(e);
    }
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
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Container(
              margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 20), // Margin around the container
              padding: const EdgeInsets.all(10.0), // Padding inside the container
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3), // Changes position of shadow
                  ),
                ],
              ),
              child: ListView.builder(
                itemCount: _announcements.length,
                itemBuilder: (context, index) {
                  final announcement = _announcements[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0), // Padding for individual announcements
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center, // Center alignment for content
                      children: [
                        Text(
                          announcement['title'],
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                        const SizedBox(height: 10), // Space between title and description
                        Text(
                          announcement['description'],
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 10,),
                        Text(
                          announcement['created_at'],
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8.0), // Space between description and image
                        if (announcement['image_url'] != null && announcement['image_url'].isNotEmpty)
                          Image.network(
                            announcement['image_url'],
                            width: 1500,
                            fit: BoxFit.cover,
                          )
                        else
                          const Text('', textAlign: TextAlign.center),
                        SizedBox(height: 30,),
                        Divider()
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
