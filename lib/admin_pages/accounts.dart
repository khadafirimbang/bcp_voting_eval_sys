import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:SSCVote/admin_pages/add_account.dart';
import 'package:SSCVote/admin_pages/drawerbar_admin.dart';
import 'package:http/http.dart' as http;

class AccountsPage extends StatefulWidget {
  @override
  _AccountsPageState createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  List<Map<String, dynamic>> accounts = [];
  List<Map<String, dynamic>> currentAccounts = [];
  int currentPage = 1;
  int accountsPerPage = 10;
  String selectedRole = 'All';
  String searchQuery = '';
  bool isSearchVisible = false; // State variable for search field visibility
  final TextEditingController searchController = TextEditingController(); // Controller for the search input

  @override
  void initState() {
    super.initState();
    fetchAccounts();
  }

  Future<void> fetchAccounts() async {
    try {
      final response = await http.get(
        Uri.parse('https://studentcouncil.bcp-sms1.com/php/fetch_accounts.php'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          accounts = List<Map<String, dynamic>>.from(data);
          _updateCurrentAccounts();
        });
      } else {
        throw Exception('Failed to load accounts');
      }
    } catch (e) {
      print('Error fetching accounts: $e');
    }
  }

  void _updateCurrentAccounts() {
    final filteredAccounts = accounts.where((account) {
      final fullName = '${account['lastname']}, ${account['firstname']} ${account['middlename']}';
      final studnetNo = '${account['studentno']}';
      final isRoleMatched = selectedRole == 'All' || account['role'] == selectedRole;
      return (fullName.toLowerCase().contains(searchQuery.toLowerCase()) && isRoleMatched) || (studnetNo.contains(searchQuery) && isRoleMatched);
    }).toList();

    int startIndex = (currentPage - 1) * accountsPerPage;
    int endIndex = startIndex + accountsPerPage;

    if (startIndex < filteredAccounts.length) {
      currentAccounts = filteredAccounts.sublist(startIndex, endIndex > filteredAccounts.length ? filteredAccounts.length : endIndex);
    } else {
      currentAccounts = [];
    }
  }

  void changePage(int page) {
    setState(() {
      currentPage = page;
      _updateCurrentAccounts();
    });
  }

  Future<void> editAccount(Map<String, String> updatedAccount) async {
    final response = await http.post(
      Uri.parse('https://studentcouncil.bcp-sms1.com/php/edit_account.php'),
      body: updatedAccount,
    );
    if (response.statusCode == 200) {
      fetchAccounts();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: Colors.green,
        content: Text('Updated successfully!'),
      ));
    } else {
      throw Exception('Failed to update account');
    }
  }

  Future<void> deleteAccount(int studentno) async {
    final response = await http.post(
      Uri.parse('https://studentcouncil.bcp-sms1.com/php/delete_account.php'),
      body: {'studentno': studentno.toString()}, // Convert to String
    );
    if (response.statusCode == 200) {
      fetchAccounts();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: Colors.green,
        content: Text('Deleted successfully!'),
      ));
    } else {
      throw Exception('Failed to delete account');
    }
  }

  void confirmDeleteAccount(int studentno) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Account'),
          content: Text('Are you sure you want to delete this account?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await deleteAccount(studentno); // Ensure studentno is passed as an int
                Navigator.of(context).pop();
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void showAccountForm({Map<String, dynamic>? account}) {
    final _formKey = GlobalKey<FormState>();
    TextEditingController studentnoController = TextEditingController(
      text: account != null ? account['studentno'].toString() : '',
    );
    TextEditingController firstnameController = TextEditingController(
      text: account != null ? account['firstname'] : '',
    );
    TextEditingController middlenameController = TextEditingController(
      text: account != null ? account['middlename'] : '',
    );
    TextEditingController lastnameController = TextEditingController(
      text: account != null ? account['lastname'] : '',
    );
    String role = account != null ? account['role'] : 'Voter';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Account'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: studentnoController,
                  decoration: const InputDecoration(labelText: 'Student Number'),
                  enabled: false,
                ),
                TextFormField(
                  controller: firstnameController,
                  decoration: const InputDecoration(labelText: 'First Name'),
                  validator: (value) => value!.isEmpty ? 'Enter first name' : null,
                ),
                TextFormField(
                  controller: middlenameController,
                  decoration: const InputDecoration(labelText: 'Middle Name'),
                ),
                TextFormField(
                  controller: lastnameController,
                  decoration: const InputDecoration(labelText: 'Last Name'),
                  validator: (value) => value!.isEmpty ? 'Enter last name' : null,
                ),
                DropdownButtonFormField<String>(
                  value: role,
                  items: ['Voter', 'Admin'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      role = newValue!;
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Role'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                Map<String, String> accountData = {
                  'studentno': studentnoController.text,
                  'firstname': firstnameController.text,
                  'middlename': middlenameController.text,
                  'lastname': lastnameController.text,
                  'role': role,
                };
                editAccount(accountData);
                Navigator.of(context).pop();
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        title: const Text('Accounts', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() {
                isSearchVisible = !isSearchVisible; // Toggle search field visibility
                searchController.clear(); // Clear the search field when opening
                searchQuery = ''; // Clear the search query
                _updateCurrentAccounts(); // Update accounts based on new search query
              });
            },
          ),
          const SizedBox(width: 10),
          DropdownButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            hint: const Text('All', style: TextStyle(color: Colors.white)),
            value: selectedRole,
            items: ['All', 'Voter', 'Admin'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                selectedRole = newValue!;
                _updateCurrentAccounts(); // Update accounts based on filter
              });
            },
            dropdownColor: const Color(0xFF1E3A8A),
            style: const TextStyle(color: Colors.white),
          ),
          IconButton(onPressed: (){
            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => AccountsPage()),
                            );
          }, icon: const Icon(Icons.refresh))
        ],
      ),
      drawer: const AppDrawerAdmin(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (isSearchVisible) // Show search field if visible
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search accounts...',
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      searchController.clear();
                      setState(() {
                        searchQuery = '';
                        isSearchVisible = false; // Hide search field
                        _updateCurrentAccounts(); // Update accounts without search
                      });
                    },
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value; // Update search query
                    _updateCurrentAccounts(); // Update accounts based on search input
                  });
                },
              ),
            const SizedBox(height: 16.0),
            Expanded(
              child: ListView.builder(
                itemCount: currentAccounts.length,
                itemBuilder: (context, index) {
                  final account = currentAccounts[index];
                  return Card(
                    color: Colors.white,
                    elevation: 2,
                    child: ListTile(
                      title: Text('${account['lastname']}, ${account['firstname']} ${account['middlename']}'),
                      subtitle: Text('Student No: ${account['studentno']} - Role: ${account['role']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => showAccountForm(account: account),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => confirmDeleteAccount(account['studentno']),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Pagination controls (previous/next buttons)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: currentPage > 1
                      ? () => changePage(currentPage - 1)
                      : null,
                ),
                Text('Page $currentPage'),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: currentPage < (accounts.length / accountsPerPage).ceil()
                      ? () => changePage(currentPage + 1)
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) =>  AddAccountPage()),
          ).then((_) => fetchAccounts()); // Refresh accounts when returning
        },
        backgroundColor: const Color(0xFF1E3A8A),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
