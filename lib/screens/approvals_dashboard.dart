import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ExpenseRequest {
  final int id;
  final String approvalSubject;
  final String requestOwner;
  final String category;
  String requestStatus;
  final double totalAmount;
  final String currencyCode;
  final String originalAmountDetails;
  final String expenseDocId; // Firestore doc id

  ExpenseRequest({
    required this.id,
    required this.approvalSubject,
    required this.requestOwner,
    required this.category,
    required this.requestStatus,
    required this.totalAmount,
    required this.currencyCode,
    required this.originalAmountDetails,
    required this.expenseDocId,
  });
}

class ApprovalsDashboard extends StatefulWidget {
  static const routeName = '/approvals';
  const ApprovalsDashboard({super.key});

  @override
  State<ApprovalsDashboard> createState() => _ApprovalsDashboardState();
}

class _ApprovalsDashboardState extends State<ApprovalsDashboard> {
  late List<ExpenseRequest> _allRequests;
  late List<ExpenseRequest> _filteredRequests;
  final TextEditingController _searchController = TextEditingController();

  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _pendingStream;

  @override
  void initState() {
    super.initState();
    _allRequests = [];
    _filteredRequests = [];
    _searchController.addListener(_filterRequests);
    _pendingStream = FirebaseFirestore.instance
        .collection('expenses')
        .where('status', isEqualTo: 'Pending')
        .orderBy('created_at', descending: true)
        .limit(200)
        .snapshots();
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterRequests);
    _searchController.dispose();
    super.dispose();
  }

  void _filterRequests() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredRequests = List.from(_allRequests);
      } else {
        _filteredRequests = _allRequests.where((request) {
          return request.requestOwner.toLowerCase().contains(query) ||
              request.approvalSubject.toLowerCase().contains(query) ||
              request.category.toLowerCase().contains(query);
        }).toList();
      }
      _sortRequests(_sortColumnIndex, _sortAscending, skipSetState: true);
    });
  }

  void _sortRequests(
    int columnIndex,
    bool ascending, {
    bool skipSetState = false,
  }) {
    final comparator = (ExpenseRequest a, ExpenseRequest b) {
      Comparable<dynamic> aValue;
      Comparable<dynamic> bValue;
      switch (columnIndex) {
        case 0:
          aValue = a.approvalSubject;
          bValue = b.approvalSubject;
          break;
        case 1:
          aValue = a.requestOwner;
          bValue = b.requestOwner;
          break;
        case 2:
          aValue = a.category;
          bValue = b.category;
          break;
        case 4:
          aValue = a.totalAmount;
          bValue = b.totalAmount;
          break;
        default:
          aValue = a.id;
          bValue = b.id;
      }
      final comparison = aValue.compareTo(bValue);
      return ascending ? comparison : -comparison;
    };

    if (!skipSetState) {
      setState(() {
        _sortColumnIndex = columnIndex;
        _sortAscending = ascending;
        _filteredRequests.sort(comparator);
      });
    } else {
      _filteredRequests.sort(comparator);
    }
  }

  Future<void> _handleAction(ExpenseRequest req, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('expenses')
          .doc(req.expenseDocId)
          .update({'status': newStatus});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request ${req.id} $newStatus')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: $e')),
      );
    }
  }

  ExpenseRequest _mapDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    final desc = (m['description'] ?? 'N/A').toString();
    final owner = (m['owner'] ?? m['employee_email'] ?? 'Unknown').toString();
    final cat = (m['category'] ?? 'Other').toString();
    final status = (m['status'] ?? 'Pending').toString();
    final amount = (m['amount_original'] is num)
        ? (m['amount_original'] as num).toDouble()
        : double.tryParse(m['amount_original']?.toString() ?? '0') ?? 0.0;
    final currency = (m['currency_original'] ?? 'USD').toString();
    final originalDetails =
        '${m['currency_original'] ?? currency} ${(m['amount_original'] ?? amount).toString()}';
    return ExpenseRequest(
      id: d.id.hashCode,
      approvalSubject: desc,
      requestOwner: owner,
      category: cat,
      requestStatus: status,
      totalAmount: amount,
      currencyCode: currency,
      originalAmountDetails: originalDetails,
      expenseDocId: d.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Approvals Dashboard',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        padding: const EdgeInsets.all(12.0),
        color: const Color(0xFFF0F2F5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 15.0),
              child: SizedBox(
                width: 400,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search (Owner, Subject, Category)...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(12),
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _pendingStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    final docs = snapshot.data?.docs ?? [];
                    _allRequests = docs.map(_mapDoc).toList();
                    _filterRequests();

                    double minTableWidth = 900;
                    return ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width > minTableWidth
                              ? MediaQuery.of(context).size.width
                              : minTableWidth,
                          child: _filteredRequests.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(30.0),
                                  child: Center(
                                    child: Text(
                                      docs.isEmpty
                                          ? '🎉 All caught up! No approvals pending.'
                                          : 'No results found for "${_searchController.text}".',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                )
                              : DataTable(
                                  dataRowColor: MaterialStateProperty.resolveWith<Color?>(
                                    (Set<MaterialState> states) {
                                      if (states.contains(MaterialState.hovered)) {
                                        return Colors.blue.shade50;
                                      }
                                      return Colors.white;
                                    },
                                  ),
                                  headingRowColor: MaterialStateProperty.all(
                                    const Color(0xFFE5F0FF),
                                  ),
                                  sortColumnIndex: _sortColumnIndex,
                                  sortAscending: _sortAscending,
                                  border: const TableBorder(
                                    horizontalInside: BorderSide(
                                      color: Color(0xFFE5E7EB),
                                      width: 3,
                                    ),
                                    bottom: BorderSide(
                                      color: Color(0xFFE5E7EB),
                                      width: 3,
                                    ),
                                  ),
                                  columnSpacing: 10,
                                  dataRowHeight: 55,
                                  columns: <DataColumn>[
                                    _buildSortableColumn('Approval Subject', 0, width: 250),
                                    _buildSortableColumn('Request Owner', 1, width: 150),
                                    _buildSortableColumn('Category', 2, width: 100),
                                    const DataColumn(
                                      label: Text(
                                        'Status',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    _buildSortableColumn('Amount', 4, width: 120),
                                    const DataColumn(
                                      label: Text(
                                        'Actions',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                  rows: _filteredRequests.map((request) {
                                    return DataRow(
                                      cells: <DataCell>[
                                        DataCell(
                                          Text(
                                            request.approvalSubject,
                                            style: const TextStyle(fontWeight: FontWeight.w500),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        DataCell(Text(request.requestOwner)),
                                        DataCell(Text(request.category)),
                                        DataCell(_buildStatusChip(request.requestStatus)),
                                        DataCell(_buildAmountCell(request)),
                                        DataCell(_buildActionButtons(request)),
                                      ],
                                    );
                                  }).toList(),
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataColumn _buildSortableColumn(String label, int index, {double? width}) {
    Widget columnLabel = Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        Icon(Icons.unfold_more, size: 16, color: Colors.grey.shade600),
      ],
    );

    if (width != null) {
      columnLabel = SizedBox(
        width: width,
        child: Align(alignment: Alignment.centerLeft, child: columnLabel),
      );
    }

    return DataColumn(
      label: columnLabel,
      onSort: (columnIndex, ascending) {
        _sortRequests(columnIndex, ascending);
      },
      numeric: index == 4,
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    if (status == 'Approved') {
      color = const Color(0xFF10B981);
    } else if (status == 'Rejected') {
      color = const Color(0xFFEF4444);
    } else {
      color = const Color(0xFFF59E0B);
    }

    return Chip(
      label: Text(
        status,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
      backgroundColor: color,
      labelPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildAmountCell(ExpenseRequest request) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${request.currencyCode} ${request.totalAmount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color(0xFF1F2937),
          ),
        ),
        Text(
          request.originalAmountDetails,
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ExpenseRequest request) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 30,
          child: ElevatedButton.icon(
            onPressed: () => _handleAction(request, 'Approved'),
            icon: const Icon(Icons.check, size: 14),
            label: const Text(
              'Approve',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          height: 30,
          child: OutlinedButton.icon(
            onPressed: () => _handleAction(request, 'Rejected'),
            icon: const Icon(Icons.close, size: 14),
            label: const Text(
              'Reject',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
              side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ),
      ],
    );
  }
}
