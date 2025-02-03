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
  Map<int, bool> selectedItems = {};
  bool selectAll = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    fetchEvaluations();
    searchController.addListener(() {
      filterEvaluations(searchController.text);
    });
  }

  void toggleSelectAll() {
    setState(() {
      selectAll = !selectAll;
      for (var eval in evaluations) {
        selectedItems[eval['id']] = selectAll;
      }
    });
  }

  Future<void> deleteSelectedEvaluations() async {
    List<int> selectedIds = selectedItems.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No items selected'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final response = await http.post(
      Uri.parse('https://studentcouncil.bcp-sms1.com/php/delete_selected_evaluations.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'ids': selectedIds}),
    );

    if (response.statusCode == 200) {
      setState(() {
        selectedItems.clear();
        selectAll = false;
      });
      fetchEvaluations();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selected items deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete selected items'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> resetEvaluationStatus() async {
    final response = await http.post(
      Uri.parse('https://studentcouncil.bcp-sms1.com/php/reset_evaluation_status.php'),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Evaluation reset successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to reset evaluation'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void showDeleteSelectedConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Confirmation'),
          content: const Text('Are you sure you want to delete all selected evaluations?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                deleteSelectedEvaluations();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void showResetConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Confirmation'),
          content: const Text('Are you sure you want to reset the evaluation? All of the evaluation records will be deleted!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                resetEvaluationStatus();
              },
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
  }

  Future<void> fetchEvaluations() async {
    final response = await http.get(Uri.parse('https://studentcouncil.bcp-sms1.com/php/get_evaluations.php'));
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
        Uri.parse('https://studentcouncil.bcp-sms1.com/php/add_evaluation.php'),
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
      Uri.parse('https://studentcouncil.bcp-sms1.com/php/update_evaluation.php'),
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
      Uri.parse('https://studentcouncil.bcp-sms1.com/php/delete_evaluation.php'),
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
    final formKey = GlobalKey<FormState>();

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
                    key: formKey,
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
                    backgroundColor: Colors.black, // Background color
                  ),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
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
    final formKey = GlobalKey<FormState>();

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
                    key: formKey,
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
                    backgroundColor: Colors.black, // Background color
                  ),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
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
                'Evaluation',
                style: TextStyle(fontSize: 18, color: Colors.black54),
              ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  setState(() {
                    isSearching = !isSearching;
                  });
                },
              ),
                    IconButton(onPressed: (){
                      fetchEvaluations();
                    }, icon: const Icon(Icons.refresh))
                ],
              )
            ],
          )
        ),
      ),
      drawer: const AppDrawerAdmin(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (isSearching)
              Padding(
                padding: const EdgeInsets.all(16.0),
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
                    const SizedBox(width: 10,),
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
              const SizedBox(height: 16.0),

            Column(                                                                      
              children: [
                Row(
                  children: [
                    
                    SizedBox(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.all(10.0),
                          backgroundColor: Colors.black,
                        ),
                        onPressed: showDeleteSelectedConfirmation,
                        child: const Text(
                          'Delete Selected',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.all(10.0),
                          backgroundColor: Colors.black,
                        ),
                        onPressed: showResetConfirmation,
                        child: const Text(
                          'Reset Evaluation',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 5,),
                Row(
                  children: [
                    Checkbox(
                      value: selectAll,
                      onChanged: (bool? value) => toggleSelectAll(),
                    ),
                    const Text('Select All'),
                  ],
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _paginatedEvaluations.length,
                itemBuilder: (context, index) {
                  final eval = _paginatedEvaluations[index];
                  return Column(
                    children: [
                      Card(
                        color: Colors.white,
                        elevation: 2,
                        child: ListTile(
                          leading: Checkbox(
                            value: selectedItems[eval['id']] ?? false,
                            onChanged: (bool? value) {
                              setState(() {
                                selectedItems[eval['id']] = value ?? false;
                                if (!(value ?? false)) {
                                  selectAll = false;
                                }
                              });
                            },
                          ),
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
                      ),
                    ],
                  );
                },
              ),
            ),
            // Pagination Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: _previousPage,
                  ),
                Text('Page $_currentPage of ${(filteredEvaluations.length / _rowsPerPage).ceil()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                    icon: const Icon(Icons.arrow_forward, color: Colors.black),
                    onPressed: _nextPage,
                  ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: showAddEvaluationForm,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
