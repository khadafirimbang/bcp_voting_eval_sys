import 'package:flutter/material.dart';
import 'package:for_testing/admin_pages/drawerbar_admin.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EvaluationPage extends StatefulWidget {
  const EvaluationPage({super.key});

  @override
  State<EvaluationPage> createState() => _EvaluationPageState();
}

class _EvaluationPageState extends State<EvaluationPage> {
  List<Map<String, dynamic>> evaluations = [];
  final List<String> types = ['Survey', 'Feedback']; // Removed 'All' option
  List<Map<String, dynamic>> newEvaluations = [
    {'question': '', 'type': 'Survey'}
  ];
  List<Map<String, dynamic>> filteredEvaluations = [];
  final TextEditingController searchController = TextEditingController();
  bool isSearching = false;
  String selectedType = 'All'; // Default to 'All' for search
  int _currentPage = 1;
  final int _rowsPerPage = 10;

  @override
  void initState() {
    super.initState();
    fetchEvaluations();
    searchController.addListener(() {
      filterEvaluations(searchController.text);
    });
  }

  Future<void> fetchEvaluations() async {
    final response = await http.get(Uri.parse('http://192.168.1.6/for_testing/get_evaluations.php'));
    if (response.statusCode == 200) {
      setState(() {
        evaluations = List<Map<String, dynamic>>.from(
          json.decode(response.body).map((eval) => {
            'id': int.parse(eval['id']),
            'question': eval['question'],
            'type': eval['type'],
          })
        );
        filteredEvaluations = evaluations; // Initialize filtered evaluations
      });
    }
  }

  void filterEvaluations(String query) {
    setState(() {
      filteredEvaluations = evaluations.where((eval) {
        final questionLower = eval['question'].toLowerCase();
        final queryLower = query.toLowerCase();
        final typeMatches = selectedType == 'All' || eval['type'] == selectedType;

        return (questionLower.contains(queryLower) || query.isEmpty) && typeMatches;
      }).toList();
    });
  }

  Future<void> addEvaluations() async {
    for (var eval in newEvaluations) {
      final response = await http.post(
        Uri.parse('http://192.168.1.6/for_testing/add_evaluation.php'),
        body: {
          'question': eval['question'],
          'type': eval['type'],
        },
      );

      if (response.statusCode == 200) {
        print('Evaluation added successfully');
      } else {
        print('Failed to add evaluation: ${response.statusCode}');
      }
    }
    fetchEvaluations(); 
  }

  Future<void> updateEvaluation(int id, String question, String type) async {
    final response = await http.post(
      Uri.parse('http://192.168.1.6/for_testing/update_evaluation.php'),
      body: {
        'id': id.toString(),
        'question': question,
        'type': type,
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['success']) {
        fetchEvaluations();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Updated Successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        print('Failed to update evaluation: ${responseData['error']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update evaluation: ${responseData['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      print('Failed to update evaluation: ${response.statusCode}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update evaluation.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> deleteEvaluation(int id) async {
    final response = await http.post(
      Uri.parse('http://192.168.1.6/for_testing/delete_evaluation.php'),
      body: {
        'id': id.toString(),
      },
    );

    if (response.statusCode == 200) {
      fetchEvaluations();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deleted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      print('Failed to delete evaluation: ${response.statusCode}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete evaluation.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void showAddEvaluationForm() {
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            final screenWidth = MediaQuery.of(context).size.width;

            double dialogWidth;
            if (screenWidth <= 600) {
              dialogWidth = screenWidth * 0.9;
            } else if (screenWidth <= 900) {
              dialogWidth = screenWidth * 0.7;
            } else {
              dialogWidth = screenWidth * 0.5;
            }

            return AlertDialog(
              title: const Text('Add New Evaluations'),
              contentPadding: const EdgeInsets.all(16.0),
              content: SizedBox(
                width: dialogWidth,
                height: MediaQuery.of(context).size.height * 0.5,
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        for (int index = 0; index < newEvaluations.length; index++)
                          Column(
                            children: [
                              TextFormField(
                                onChanged: (value) {
                                  newEvaluations[index]['question'] = value;
                                },
                                decoration: InputDecoration(
                                  labelText: 'Question ${index + 1}',
                                  border: const OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a question';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 10),
                              DropdownButtonFormField<String>(
                                value: newEvaluations[index]['type'],
                                decoration: const InputDecoration(
                                  labelText: 'Type',
                                  border: OutlineInputBorder(),
                                ),
                                items: types.map((String type) {
                                  return DropdownMenuItem<String>(
                                    value: type,
                                    child: Text(type),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  setState(() {
                                    newEvaluations[index]['type'] = newValue!;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select a type';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () {
                                      setState(() {
                                        newEvaluations.add({'question': '', 'type': 'Survey'});
                                      });
                                    },
                                  ),
                                  if (newEvaluations.length > 1)
                                    IconButton(
                                      icon: const Icon(Icons.remove),
                                      onPressed: () {
                                        setState(() {
                                          newEvaluations.removeAt(index);
                                        });
                                      },
                                    ),
                                ],
                              ),
                              const Divider(),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A), // Background color
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Confirmation'),
                            content: const Text('Are you sure you want to add all evaluations?'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  try {
                                    await addEvaluations();
                                    Navigator.of(context).pop();
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Added Successfully!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } catch (e) {
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Failed to add.'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    print('Error adding evaluations: $e');
                                  }
                                },
                                child: const Text('Confirm'),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  },
                  child: const Text('Add All', style: TextStyle(color: Colors.white)),
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
      },
    );
  }

  void showUpdateEvaluationForm(int id, String question, String type) {
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            final screenWidth = MediaQuery.of(context).size.width;

            double dialogWidth;
            if (screenWidth <= 600) {
              dialogWidth = screenWidth * 0.9;
            } else if (screenWidth <= 900) {
              dialogWidth = screenWidth * 0.7;
            } else {
              dialogWidth = screenWidth * 0.5;
            }

            return AlertDialog(
              title: const Text('Update Evaluation'),
              contentPadding: const EdgeInsets.all(16.0),
              content: SizedBox(
                width: dialogWidth,
                height: MediaQuery.of(context).size.height * 0.4,
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          initialValue: question,
                          onChanged: (value) {
                            question = value;
                          },
                          decoration: const InputDecoration(
                            labelText: 'Question',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a question';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: type,
                          decoration: const InputDecoration(
                            labelText: 'Type',
                            border: OutlineInputBorder(),
                          ),
                          items: types.map((String type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              type = newValue!;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a type';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A), // Background color
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Confirmation'),
                            content: const Text('Are you sure you want to update this evaluation?'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  Navigator.of(context).pop(); // Close the confirmation dialog
                                  await updateEvaluation(id, question, type);
                                  Navigator.of(context).pop(); // Close the update form dialog
                                },
                                child: const Text('Confirm'),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  },
                  child: const Text('Update', style: TextStyle(color: Colors.white)),
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
      },
    );
  }

  void showDeleteConfirmation(int id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Confirmation'),
          content: const Text('Are you sure you want to delete this evaluation?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                deleteEvaluation(id);
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  List get _paginatedEvaluations {
    int startIndex = (_currentPage - 1) * _rowsPerPage;
    int endIndex = startIndex + _rowsPerPage;
    return filteredEvaluations.sublist(
      startIndex,
      endIndex.clamp(0, filteredEvaluations.length), // Ensure it doesn't go out of bounds
    );
  }

  void _nextPage() {
    setState(() {
      if (_currentPage < (filteredEvaluations.length / _rowsPerPage).ceil()) {
        _currentPage++;
      }
    });
  }

  void _previousPage() {
    setState(() {
      if (_currentPage > 1) {
        _currentPage--;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        title: const Text('Evaluation', style: TextStyle(color: Colors.white)),
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
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() {
                isSearching = !isSearching;
              });
            },
          ),
        ],
      ),
      drawer: const AppDrawerAdmin(),
      body: Column(
        children: [
          if (isSearching)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search evaluations',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => filterEvaluations(value),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    hint: const Text('Select Type'),
                    value: selectedType,
                    onChanged: (value) {
                      setState(() {
                        selectedType = value!;
                        filterEvaluations(searchController.text); // Filter based on both search query and selected type
                      });
                    },
                    items: ['All', ...types].map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _paginatedEvaluations.length,
              itemBuilder: (context, index) {
                final eval = _paginatedEvaluations[index];
                // Determine the background color based on the row index
                // final backgroundColor = index.isEven ? Colors.grey[300] : Colors.grey[100];

                return Container(
                  // color: backgroundColor,
                  child: Column(
                    children: [
                      Divider(),
                      ListTile(
                        contentPadding: const EdgeInsets.all(8.0),
                        title: Text(eval['question']),
                        subtitle: Text(eval['type']),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                showUpdateEvaluationForm(eval['id'], eval['question'], eval['type']);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                showDeleteConfirmation(eval['id']);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Pagination Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: _previousPage,
                ),
              Text('Page $_currentPage of ${(filteredEvaluations.length / _rowsPerPage).ceil()}', style: TextStyle(fontWeight: FontWeight.bold)),
              IconButton(
                  icon: Icon(Icons.arrow_forward, color: Colors.black),
                  onPressed: _nextPage,
                ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1E3A8A),
        onPressed: showAddEvaluationForm,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
