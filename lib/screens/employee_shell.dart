import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmployeeShell extends StatefulWidget {
  static const routeName = '/employee';
  const EmployeeShell({super.key});

  @override
  State<EmployeeShell> createState() => _EmployeeShellState();
}

class _EmployeeShellState extends State<EmployeeShell> {
  int _index = 0;
  String _search = '';
  DateTimeRange? _range;

  String get _titleForIndex {
    switch (_index) {
      case 0:
        return 'Submitted';
      case 1:
        return 'Pending';
      case 2:
        return 'Approved';
      default:
        return 'Expenses';
    }
  }

  (Color bg, Color fg) _appBarColors(ColorScheme cs) {
    switch (_index) {
      case 0:
        return (cs.primary, Colors.white);
      case 1:
        return (cs.secondary, Colors.white);
      case 2:
        return (const Color(0xFF2E7D32), Colors.white);
      default:
        return (cs.primary, Colors.white);
    }
  }

  Future<void> _exportApprovedCsv() async {
    // Dummy export using local sample data to avoid Firestore.
    final df = (DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
    final now = DateTime.now();
    final data = List.generate(
      10,
      (i) => {
        'title': 'Expense #${i + 1} - Lunch with client',
        'project': 'Project ${(i % 3) + 1}',
        'date': now.subtract(Duration(days: i)),
        'category': 'Food',
        'amount': 500 + i * 10,
        'currency': 'INR',
        'owner': 'me@example.com',
        'status': 'Approved',
      },
    );
    final rows = <List<String>>[];
    rows.add([
      'Sr No',
      'Title',
      'Project',
      'Date',
      'Category',
      'Amount',
      'Currency',
      'Amount (INR)',
      'Owner',
      'Status',
    ]);
    for (var i = 0; i < data.length; i++) {
      final m = data[i];
      rows.add([
        '${i + 1}',
        m['title'].toString(),
        m['project'].toString(),
        df(m['date'] as DateTime),
        m['category'].toString(),
        m['amount'].toString(),
        m['currency'].toString(),
        m['amount'].toString(),
        m['owner'].toString(),
        m['status'].toString(),
      ]);
    }
    final csv = rows.map((r) => r.map(_escapeCsv).join(',')).join('\n');
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/approved_expenses.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'Approved expenses export');
  }

  String _escapeCsv(String v) {
    final needsQuotes = v.contains(',') || v.contains('"') || v.contains('\n');
    var out = v.replaceAll('"', '""');
    return needsQuotes ? '"$out"' : out;
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _StatusListPage(status: 'submitted', search: _search, range: _range),
      _StatusListPage(status: 'pending', search: _search, range: _range),
      _StatusListPage(status: 'approved', search: _search, range: _range),
    ];

    final cs = Theme.of(context).colorScheme;
    final (bg, fg) = _appBarColors(cs);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: fg,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        centerTitle: true,
        title: Text(_titleForIndex),
        actions: [
          if (_index == 2)
            IconButton(
              tooltip: 'Export to Excel (CSV)',
              onPressed: _exportApprovedCsv,
              icon: const Icon(Icons.ios_share),
            ),
          IconButton(
            tooltip: 'Filter by date range',
            icon: const Icon(Icons.filter_list),
            onPressed: () async {
              final now = DateTime.now();
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(now.year - 1),
                lastDate: DateTime(now.year + 1),
                initialDateRange:
                    _range ??
                    DateTimeRange(
                      start: now.subtract(const Duration(days: 30)),
                      end: now,
                    ),
              );
              if (picked != null) setState(() => _range = picked);
            },
          ),
          IconButton(
            tooltip: 'Manager Approvals',
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: () => Navigator.pushNamed(context, '/approvals/nav'),
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Optional confirm
              final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Do you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  ) ??
                  false;
              if (!ok) return;
              try {
                await FirebaseAuth.instance.signOut();
              } finally {
                if (!mounted) return;
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search description, category, amount...',
                ),
                onChanged: (v) => setState(() => _search = v.trim()),
              ),
            ),
            Expanded(child: pages[_index]),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/employee/form'),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.outbox_outlined),
            selectedIcon: Icon(Icons.outbox),
            label: 'Submitted',
          ),
          NavigationDestination(
            icon: Icon(Icons.pending_outlined),
            selectedIcon: Icon(Icons.pending),
            label: 'Pending',
          ),
          NavigationDestination(
            icon: Icon(Icons.verified_outlined),
            selectedIcon: Icon(Icons.verified),
            label: 'Approved',
          ),
        ],
      ),
    );
  }
}

class _StatusListPage extends StatelessWidget {
  final String status; // submitted | pending | approved
  final String search;
  final DateTimeRange? range;
  const _StatusListPage({
    required this.status,
    required this.search,
    required this.range,
  });

  String _label() => status[0].toUpperCase() + status.substring(1);

  Color _chipColor(ColorScheme cs) {
    switch (status) {
      case 'submitted':
        return cs.primary;
      case 'pending':
        return cs.secondary;
      case 'approved':
        return const Color(0xFF2E7D32); // green
      default:
        return cs.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Local dummy items (no Firestore)
    final now = DateTime.now();
    List<Map<String, dynamic>> items = List.generate(
      12,
      (i) => {
        'description': 'Expense #${i + 1} • Lunch with client',
        'date': now.subtract(Duration(days: i)),
        'category': ['Food', 'Travel', 'Stay'][i % 3],
        'amount': 500 + i * 20,
        'status': status,
      },
    );

    // Apply optional filters on local list
    if (range != null) {
      items = items.where((m) {
        final d = m['date'] as DateTime;
        return !d.isBefore(range!.start) && !d.isAfter(range!.end);
      }).toList();
    }
    if (search.isNotEmpty) {
      final s = search.toLowerCase();
      items = items.where((m) {
        final desc = m['description'].toString().toLowerCase();
        final cat = m['category'].toString().toLowerCase();
        final amt = m['amount'].toString();
        return desc.contains(s) || cat.contains(s) || amt.contains(s);
      }).toList();
    }
    items.sort(
      (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
    );

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: cs.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No ${_label()} expenses',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Create a new expense to get started.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/employee/form'),
              icon: const Icon(Icons.add),
              label: const Text('New Expense'),
            ),
          ],
        ),
      );
    }

    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')} ${_month(d.month)} ${d.year}';
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemBuilder: (_, i) {
        final m = items[i];
        final desc = m['description'].toString();
        final date = m['date'] as DateTime;
        final category = m['category'].toString();
        final amount = m['amount'].toString();
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: _chipColor(cs).withOpacity(0.12),
              child: Icon(Icons.receipt_long, color: _chipColor(cs)),
            ),
            title: Text(desc, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _chipColor(cs).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _label(),
                    style: TextStyle(
                      color: _chipColor(cs),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${fmt(date)} · $category',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                ),
              ],
            ),
            trailing: Text(
              '₹ $amount',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            onTap: () {},
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: items.length,
    );
  }
}

String _month(int m) => const [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
][m - 1];
