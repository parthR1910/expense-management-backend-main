import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatelessWidget {
  static const routeName = '/admin';
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin - Users')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.person_add),
        label: const Text('Invite User'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (_, i) => ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text('User ${i + 1}'),
          subtitle: Text(i % 2 == 0 ? 'Employee' : 'Manager'),
          trailing: TextButton(
            onPressed: () {},
            child: const Text('Send pwd'),
          ),
        ),
        separatorBuilder: (_, __) => const Divider(),
        itemCount: 8,
      ),
    );
  }
}
