import 'package:flutter/material.dart';

class ManagerApprovalsScreen extends StatelessWidget {
  static const routeName = '/manager/approvals';
  const ManagerApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manager's Approvals")),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (_, i) => Card(
          child: ListTile(
            title: const Text('Restaurant bill'),
            subtitle: const Text('Owner: Sarah • Food'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(onPressed: () {}, child: const Text('Reject', style: TextStyle(color: Colors.red))),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: () {}, child: const Text('Approve')),
              ],
            ),
          ),
        ),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemCount: 6,
      ),
    );
  }
}
