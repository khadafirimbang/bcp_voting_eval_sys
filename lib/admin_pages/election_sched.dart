import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:for_testing/admin_pages/drawerbar_admin.dart';
import 'package:for_testing/voter_pages/election_history.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ElectionScheduler(),
    );
  }
}

class ElectionScheduler extends StatefulWidget {
  const ElectionScheduler({super.key});

  @override
  _ElectionSchedulerState createState() => _ElectionSchedulerState();
}

class _ElectionSchedulerState extends State<ElectionScheduler> {
  final ApiService _apiService = ApiService('https://studentcouncil.bcp-sms1.com/php');
  List<ElectionSchedule> _schedules = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();            

  @override
  void initState() {
    super.initState();
    _fetchSchedules();
  }

  Future<void> _fetchSchedules() async {
    try {
      final schedules = await _apiService.getSchedules();
      setState(() {
        _schedules = schedules;
      });
    } catch (e) {
      print('Failed to fetch schedules: $e');
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _addSchedule() async {
    if (_schedules.isNotEmpty) {
      final ongoingElection = _schedules.any((schedule) =>
          schedule.startDate.isBefore(DateTime.now()) &&
          schedule.endDate.isAfter(DateTime.now()));

      if (ongoingElection) {
        _showSnackbar('You can only add an election schedule if there is no ongoing election.');
        return;
      }

      _showSnackbar('You can only add 1 election schedule. Delete or edit the current election schedule if you want to add.');
      return;
    }

    final schedule = await _showScheduleDialog();

    if (schedule != null) {
      try {
        await _apiService.createSchedule(schedule);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Added successfully!'),
        ));
        _fetchSchedules();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Failed to add schedule!'),
        ));
        print('Failed to add schedule: $e');
      }
    }
  }

  Future<void> _editSchedule(ElectionSchedule schedule) async {
    final updatedSchedule = await _showScheduleDialog(schedule: schedule);

    if (updatedSchedule != null) {
      bool confirmed = await _showConfirmationDialog();
      if (confirmed) {
        try {
          await _apiService.updateSchedule(updatedSchedule);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Updated successfully!'),
          ));
          _fetchSchedules();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Failed to update schedule!'),
          ));
          print('Failed to update schedule: $e');
        }
      }
    }
  }

  Future<void> _deleteSchedule(int id) async {
    bool confirmed = await _showConfirmationDialog();
    if (confirmed) {
      try {
        await _apiService.deleteSchedule(id);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Deleted successfully!'),
        ));
        _fetchSchedules();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Failed to delete schedule!'),
        ));
        print('Failed to delete schedule: $e');
      }
    }
  }

  Future<bool> _showConfirmationDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm'),
        content: const Text('Are you sure you want to end the Election?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ).then((result) => result ?? false);
  }

  Future<ElectionSchedule?> _showScheduleDialog({ElectionSchedule? schedule}) {
    final TextEditingController nameController = TextEditingController(text: schedule?.electionName ?? '');
    DateTime? startDate = schedule?.startDate;
    DateTime? endDate = schedule?.endDate;

    return showDialog<ElectionSchedule>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(schedule == null ? 'Add Schedule' : 'Edit Schedule'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Election Name'),
              ),
              DateTimeField(
                label: 'Start Date',
                selectedDate: startDate,
                onDateSelected: (date) {
                  startDate = date; // Update local state
                },
              ),
              DateTimeField(
                label: 'End Date',
                selectedDate: endDate,
                onDateSelected: (date) {
                  endDate = date; // Update local state
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && startDate != null && endDate != null) {
                  final updatedSchedule = ElectionSchedule(
                    id: schedule?.id ?? 0,
                    electionName: nameController.text,
                    startDate: startDate!,
                    endDate: endDate!,
                  );
                  Navigator.of(context).pop(updatedSchedule);
                } else {
                  _showSnackbar('Please fill all fields correctly.');
                }
              },
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: const Text('Election Schedule'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchSchedules,
            ),
          ],
        ),
        drawer: const AppDrawerAdmin(),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 16.0),
              SizedBox(
                child: TextButton(
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(10.0),
                    backgroundColor: Colors.black,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ElectionHistory()),
                    );
                  },
                  child: const Text(
                    'Election History',
                    style: TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ),
              ),
              Expanded(
                child: _schedules.isEmpty
                  ? const Center(child: Text("No schedules available."))
                  : ListView.builder(
                  itemCount: _schedules.length,
                  itemBuilder: (context, index) {
                    final schedule = _schedules[index];
                    final formatter = DateFormat('MMM dd, yyyy h:mm a');
                    final startDateFormatted = formatter.format(schedule.startDate);
                    final endDateFormatted = formatter.format(schedule.endDate);
                
                    return Column(
                      children: [
                        const SizedBox(height: 16.0),
                        Card(
                          color: Colors.white,
                          elevation: 2,
                          child: ListTile(
                            title: Text(schedule.electionName),
                            subtitle: Text('From $startDateFormatted to $endDateFormatted'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _editSchedule(schedule),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _deleteSchedule(schedule.id),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addSchedule,
          backgroundColor: Colors.black,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}

class ElectionSchedule {
  final int id;
  final String electionName;
  DateTime startDate;
  DateTime endDate;

  ElectionSchedule({
    required this.id,
    required this.electionName,
    required this.startDate,
    required this.endDate,
  });

  factory ElectionSchedule.fromJson(Map<String, dynamic> json) {
    return ElectionSchedule(
      id: int.parse(json['id'].toString()),
      electionName: json['election_name'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'election_name': electionName,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
    };
  }
}

class ApiService {
  final String baseUrl;

  ApiService(this.baseUrl);

  Future<List<ElectionSchedule>> getSchedules() async {
    final response = await http.get(Uri.parse('$baseUrl/get_schedules.php'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => ElectionSchedule.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load schedules');
    }
  }

  Future<void> createSchedule(ElectionSchedule schedule) async {
    final response = await http.post(
      Uri.parse('$baseUrl/create_schedule.php'),
      body: json.encode(schedule.toJson()),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create schedule');
    }
  }

  Future<void> updateSchedule(ElectionSchedule schedule) async {
    final response = await http.post(
      Uri.parse('$baseUrl/update_schedule.php'),
      body: json.encode(schedule.toJson()),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update schedule');
    }
  }

  Future<void> deleteSchedule(int id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/delete_schedule.php'),
      body: json.encode({'id': id}),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete schedule');
    }
  }
}

class DateTimeField extends StatefulWidget {
  final String label;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const DateTimeField({super.key, 
    required this.label,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  _DateTimeFieldState createState() => _DateTimeFieldState();
}

class _DateTimeFieldState extends State<DateTimeField> {
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(widget.label),
        ),
        TextButton(
          onPressed: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: _selectedDate ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (pickedDate != null) {
              final pickedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(_selectedDate ?? DateTime.now()),
              );
              if (pickedTime != null) {
                final dateTime = DateTime(
                  pickedDate.year,
                  pickedDate.month,
                  pickedDate.day,
                  pickedTime.hour,
                  pickedTime.minute,
                );
                setState(() {
                  _selectedDate = dateTime;
                });
                widget.onDateSelected(dateTime);
              }
            }
          },
          child: Text(
            _selectedDate != null
                ? DateFormat('MMM dd, yyyy h:mm a').format(_selectedDate!)
                : 'Select date and time',
          ),
        ),
      ],
    );
  }
}
