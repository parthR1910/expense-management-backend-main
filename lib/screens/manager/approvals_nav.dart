import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../approvals_dashboard.dart';

class ManagerApprovalsNav extends StatefulWidget {
  static const routeName = '/approvals/nav';
  const ManagerApprovalsNav({super.key});

  @override
  State<ManagerApprovalsNav> createState() => _ManagerApprovalsNavState();
}

class _ManagerApprovalsNavState extends State<ManagerApprovalsNav> {
  int pageIndex = 0;

  final List<Widget> pages = const [
    AcceptedRequestsScreen(),
    RejectedRequestsScreen(),
    ApprovalsDashboard(),
  ];

  void _onItemTapped(int index) {
    setState(() => pageIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: pages[pageIndex]),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: 'Approved',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cancel),
            label: 'Rejected',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
        ],
        currentIndex: pageIndex,
        selectedItemColor: Colors.blue[800],
        onTap: _onItemTapped,
      ),
    );
  }
}

class AcceptedRequestsScreen extends StatelessWidget {
  const AcceptedRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final q = FirebaseFirestore.instance
        .collection('expenses')
        .where('status', isEqualTo: 'Approved')
        .orderBy('created_at', descending: true)
        .limit(100)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Approved Requests'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: q,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No approved requests'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemBuilder: (_, i) {
              final m = docs[i].data();
              final desc = (m['description'] ?? 'N/A').toString();
              final owner = (m['owner'] ?? m['employee_email'] ?? 'Unknown').toString();
              final amount = (m['amount_original'] ?? '').toString();
              final currency = (m['currency_original'] ?? 'USD').toString();
              return ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text(desc, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(owner),
                trailing: Text('$currency $amount'),
              );
            },
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemCount: docs.length,
          );
        },
      ),
    );
  }
}

class RejectedRequestsScreen extends StatelessWidget {
  const RejectedRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final q = FirebaseFirestore.instance
        .collection('expenses')
        .where('status', isEqualTo: 'Rejected')
        .orderBy('created_at', descending: true)
        .limit(100)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rejected Requests'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: q,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No rejected requests'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemBuilder: (_, i) {
              final m = docs[i].data();
              final desc = (m['description'] ?? 'N/A').toString();
              final owner = (m['owner'] ?? m['employee_email'] ?? 'Unknown').toString();
              final amount = (m['amount_original'] ?? '').toString();
              final currency = (m['currency_original'] ?? 'USD').toString();
              return ListTile(
                leading: const Icon(Icons.cancel, color: Colors.redAccent),
                title: Text(desc, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(owner),
                trailing: Text('$currency $amount'),
              );
            },
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemCount: docs.length,
          );
        },
      ),
    );
  }
}
