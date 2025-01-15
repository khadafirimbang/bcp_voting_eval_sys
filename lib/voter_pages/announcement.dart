import 'package:flutter/material.dart';
import 'package:for_testing/voter_pages/chatbot.dart';
import 'package:for_testing/voter_pages/drawerbar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AnnouncementPage extends StatefulWidget {
  const AnnouncementPage({super.key});

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
        Uri.parse('https://studentcouncil.bcp-sms1.com/php/get_announcements.php'),
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
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
          child: AppBar(
            titleSpacing: -5,
                        backgroundColor: Colors.transparent, // Make inner AppBar transparent
                        elevation: 0, // Remove shadow
                        title: const Text(
                          'Announcement',
                          style: TextStyle(fontSize: 18, color: Colors.black54),
                        ),
                        iconTheme: const IconThemeData(color: Colors.black45),
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
        ),
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                    offset: const Offset(0, 3), // Changes position of shadow
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
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                        const SizedBox(height: 10), // Space between title and description
                        Text(
                          announcement['description'],
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10,),
                        Text(
                          announcement['created_at'],
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8.0), // Space between description and image
                        if (announcement['image_url'] != null && announcement['image_url'].isNotEmpty)
                          Image.network(
                            announcement['image_url'],
                            width: 1000,
                            fit: BoxFit.cover,
                          )
                        else
                          const Text('', textAlign: TextAlign.center),
                        const SizedBox(height: 30,),
                        const Divider()
                      ],
                    ),
                  );
                },
              ),
            ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => ChatbotScreen()),
          );
        },
        child: Icon(Icons.chat_outlined),
      ),
    );
  }
}
