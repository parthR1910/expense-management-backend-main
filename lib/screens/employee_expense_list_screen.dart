import 'package:flutter/material.dart';

class EmployeeExpenseListScreen extends StatelessWidget {
  static const routeName = '/employee/list';
  const EmployeeExpenseListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Expenses')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/employee/form'),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 96),
          itemCount: 10,
          itemBuilder: (_, i) => Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              title: Text('Restaurant bill #${i + 1}'),
              subtitle: const Text('Draft • 04 Oct 2025 • Food'),
              trailing: const Text('₹ 500'),
            ),
          ),
        ),
      ),
    );
  }
}
