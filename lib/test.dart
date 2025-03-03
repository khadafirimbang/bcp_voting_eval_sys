import 'package:http/http.dart' as http;
import 'dart:convert';

class StudentSyncService {
  Future<void> syncStudentsAcrossDomains() async {
    try {
      // More robust error handling
      final fetchResponse = await http.get(
        Uri.parse('https://enrollment.bcp-sms1.com/fetch_students/cross-save.php'),
        // Add timeout to prevent hanging
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ewfSDSFAfa54'
        }
      ).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Fetch request timed out');
        }
      );

      if (fetchResponse.statusCode == 200) {
        // Parse the response body
        final studentsData = json.decode(fetchResponse.body);

        // Ensure we have students to sync
        if (studentsData['status'] == 'success' && studentsData['totalStudents'] > 0) {
          final syncResponse = await http.post(
            Uri.parse('https://studentcouncil.bcp-sms1.com/php/cross-save/receive_students.php'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ewfSDSFAfa54',
              'Accept': 'application/json'
            },
            body: json.encode(studentsData['externalResponse'] ?? [])
          ).timeout(
            Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Sync request timed out');
            }
          );

          if (syncResponse.statusCode == 200) {
            final result = json.decode(syncResponse.body);
            print('Sync Results: $result');
            
            // Handle sync results
            _handleSyncResults(result);
          } else {
            throw Exception('Failed to sync students across domains. Status: ${syncResponse.statusCode}');
          }
        } else {
          print('No students to sync or fetch failed');
        }
      } else {
        throw Exception('Failed to fetch students. Status: ${fetchResponse.statusCode}');
      }
    } catch (e) {
      print('Sync Error: $e');
      // More detailed error handling
      _handleSyncError(e);
    }
  }

  void _handleSyncResults(Map<String, dynamic> result) {
    // More comprehensive result handling
    if (result['status'] == 'success') {
      print('Successfully synced ${result['successfulInserts'] ?? 0} students');
    } else {
      print('Sync failed: ${result['message'] ?? 'Unknown error'}');
    }
  }

  void _handleSyncError(dynamic error) {
    // Implement more robust error handling
    print('Detailed Sync Error: $error');
    // You might want to show a dialog or log the error
  }

  
  Future<void> transferStudents() async {
  try {
    final response = await http.post(
      Uri.parse('transfer_students.php')
    );

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      if (result['success']) {
        print('Transferred ${result['transferred']} students');
      } else {
        print('Transfer failed: ${result['error']}');
      }
    }
  } catch (e) {
    print('Transfer error: $e');
  }
}

}
