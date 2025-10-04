import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:xyz/screens/drawer/pannel_member.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Which page is currently visible
  Widget currentPage = UserManagementScreen();

  void openPage(Widget page) {
    Navigator.of(context).pop(); // close drawer
    setState(() => currentPage = page);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: Colors.blue[800],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
          const SizedBox(width: 6),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                color: Colors.blue[800],
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white,
                      child: Text(
                        'A',
                        style: TextStyle(
                            color: Colors.blue[800],
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Admin Panel',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          SizedBox(height: 4),
                          Text('admin@company.com',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Drawer items
              _DrawerItem(
                icon: Icons.people,
                title: 'User Management',
                onTap: () => openPage(UserManagementScreen()),
              ),
              _DrawerItem(
                icon: Icons.group,
                title: 'Panel Members',
                onTap: () => openPage(TeamLeadScreen()),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(child: currentPage),
    );
  }
}

/// Drawer item widget
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DrawerItem(
      {required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue[800]),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }
}

/// ------------------- User Management Screen -------------------
class UserManagementScreen extends StatefulWidget {
  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  String searchQuery = "";
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Color getRoleColor(String? role) {
    switch (role) {
      case 'Manager':
        return Colors.green.shade100;
      case 'CFO':
        return Colors.red.shade100;
      case 'Employees':
        return Colors.blue.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  Color getRoleTextColor(String? role) {
    switch (role) {
      case 'Manager':
        return Colors.green.shade800;
      case 'CFO':
        return Colors.red.shade800;
      case 'Employees':
        return Colors.blue.shade800;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Column(
        children: [
          // Centered header
          Column(
            children: [
              Text(
                "Users Management",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Manage users and assign roles easily.",
                style: TextStyle(fontSize: 15, color: Colors.grey[700]),
              ),
              const SizedBox(height: 14),
              // Search
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: "Search by name or email...",
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),

          // User list card
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading users'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final users = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return {
                    'id': doc.id,
                    'name': data['name'] as String? ?? 'Unknown',
                    'email': data['email'] as String? ?? 'unknown@email.com',
                    'designation': data['designation'] as String?,
                  };
                }).toList();

                final filteredUsers = users.where((user) {
                  final name = (user['name'] as String).toLowerCase();
                  final email = (user['email'] as String).toLowerCase();
                  return name.contains(searchQuery.toLowerCase()) ||
                      email.contains(searchQuery.toLowerCase());
                }).toList();

                if (filteredUsers.isEmpty) {
                  return const Center(
                    child: Text(
                      "No users found",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredUsers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      return Container(
                        height: 100,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade100),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Avatar
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.blue.shade100,
                              child: Text(
                                (user['name'] as String)[0],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[900],
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    user['name'] as String,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    user['email'] as String,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Role dropdown (badge)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: getRoleColor(user['designation']),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: DropdownButton<String>(
                                value: user['designation'],
                                hint: const Text(
                                  "Please select",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey,
                                  ),
                                ),
                                items: ['Employees', 'Manager', 'CFO']
                                    .map((role) => DropdownMenuItem(
                                          value: role,
                                          child: Text(
                                            role,
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: getRoleTextColor(role)),
                                          ),
                                        ))
                                    .toList(),
                                onChanged: (newRole) {
                                  if (newRole != null) {
                                    _firestore
                                        .collection('users')
                                        .doc(user['id'] as String)
                                        .update({'designation': newRole});
                                  }
                                },
                                underline: const SizedBox(),
                                isDense: true,
                                icon: Icon(
                                  Icons.arrow_drop_down,
                                  size: 18,
                                  color: getRoleTextColor(user['designation']),
                                ),
                                dropdownColor: Colors.white,
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Arrow button - only show after role selected
                            if (user['designation'] != null &&
                                user['designation'] == 'Employees')
                              IconButton(
                                icon: const Icon(Icons.arrow_forward_ios,
                                    size: 18, color: Colors.blue),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          AssignManagerScreen(user: user),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// ------------------- Assign Manager Screen -------------------
class AssignManagerScreen extends StatelessWidget {
  final Map<String, dynamic> user;
  const AssignManagerScreen({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Manager'),
        backgroundColor: Colors.blue[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          children: [
            Card(
              elevation: 2,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Text((user['name'] as String)[0],
                      style: TextStyle(color: Colors.blue[900])),
                ),
                title: Text(user['name'] as String),
                subtitle: Text(user['email'] as String),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Select a manager to assign:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            // List of managers from DB
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('designation', isEqualTo: 'Manager')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading managers'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final managers = snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return {
                      'id': doc.id,
                      'name': data['name'] as String? ?? 'Unknown',
                      'role': 'Manager',
                    };
                  }).toList();

                  if (managers.isEmpty) {
                    return const Center(child: Text('No managers available'));
                  }

                  return ListView.builder(
                    itemCount: managers.length,
                    itemBuilder: (context, index) {
                      final manager = managers[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green.shade100,
                            child: Text((manager['name'] as String)[0], style: TextStyle(color: Colors.green.shade800)),
                          ),
                          title: Text(manager['name'] as String),
                          subtitle: Text(manager['role'] as String),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(user['id'] as String)
                                .update({'managerId': manager['id']});
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text('${manager['name']} assigned')));
                            Navigator.of(context).pop();
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}