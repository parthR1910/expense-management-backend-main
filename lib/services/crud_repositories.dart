import 'package:cloud_firestore/cloud_firestore.dart';

import '../screens/model/model.dart';

/// Generic base repository for Firestore CRUD.
class FirestoreRepository<T> {
  final String collectionPath;
  final T Function(Map<String, dynamic> data) fromMap;
  final Map<String, dynamic> Function(T value) toMap;

  const FirestoreRepository({
    required this.collectionPath,
    required this.fromMap,
    required this.toMap,
  });

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection(collectionPath);

  /// Create a new document. Returns the created document id.
  Future<String> create(T value) async {
    final doc = await _col.add(toMap(value));
    return doc.id;
  }

  /// Upsert with custom doc id (useful when you want a stable key)
  Future<void> setWithId(String docId, T value, {bool merge = true}) async {
    await _col.doc(docId).set(toMap(value), SetOptions(merge: merge));
  }

  /// Read document by document id.
  Future<T?> getByDocId(String docId) async {
    final snap = await _col.doc(docId).get();
    if (!snap.exists) return null;
    final data = snap.data();
    if (data == null) return null;
    return fromMap(data);
  }

  /// Query by a field equals value. Returns a list.
  Future<List<T>> getByField(String field, dynamic value, {int limit = 100}) async {
    final qs = await _col.where(field, isEqualTo: value).limit(limit).get();
    return qs.docs.map((d) => fromMap(d.data())).toList();
  }

  /// Get all documents (limited).
  Future<List<T>> getAll({int limit = 100}) async {
    final qs = await _col.limit(limit).get();
    return qs.docs.map((d) => fromMap(d.data())).toList();
  }

  /// Update an existing document by doc id.
  Future<void> update(String docId, T value, {bool merge = false}) async {
    if (merge) {
      await _col.doc(docId).set(toMap(value), SetOptions(merge: true));
    } else {
      await _col.doc(docId).update(toMap(value));
    }
  }

  /// Patch (partial update) with a map
  Future<void> patch(String docId, Map<String, dynamic> patch) async {
    await _col.doc(docId).update(patch);
  }

  /// Delete by doc id.
  Future<void> delete(String docId) async {
    await _col.doc(docId).delete();
  }
}

// ---------------- Specific repositories ----------------

class UsersRepository extends FirestoreRepository<UserModel> {
  UsersRepository()
      : super(
          collectionPath: 'users',
          fromMap: (m) => UserModel.fromMap(m),
          toMap: (u) => u.toMap(),
        );
}

class DevicesRepository extends FirestoreRepository<DeviceModel> {
  DevicesRepository()
      : super(
          collectionPath: 'devices',
          fromMap: (m) => DeviceModel.fromMap(m),
          toMap: (d) => d.toMap(),
        );
}

class CompaniesRepository extends FirestoreRepository<CompanyModel> {
  CompaniesRepository()
      : super(
          collectionPath: 'companies',
          fromMap: (m) => CompanyModel.fromMap(m),
          toMap: (c) => c.toMap(),
        );
}

class ExpensesRepository extends FirestoreRepository<ExpenseModel> {
  ExpensesRepository()
      : super(
          collectionPath: 'expenses',
          fromMap: (m) => ExpenseModel.fromMap(m),
          toMap: (e) => e.toMap(),
        );

  /// Convenience: query by status
  Future<List<ExpenseModel>> getByStatus(ExpenseStatus status, {int limit = 100}) {
    return getByField('status', expenseStatusToString(status), limit: limit);
  }

  /// Convenience: query by employee id
  Future<List<ExpenseModel>> getByEmployee(int employeeId, {int limit = 100}) {
    return getByField('employee_id', employeeId, limit: limit);
  }
}

class ApprovalWorkflowsRepository extends FirestoreRepository<ApprovalWorkflowModel> {
  ApprovalWorkflowsRepository()
      : super(
          collectionPath: 'approval_workflows',
          fromMap: (m) => ApprovalWorkflowModel.fromMap(m),
          toMap: (w) => w.toMap(),
        );
}

class ExpenseApprovalsRepository extends FirestoreRepository<ExpenseApprovalModel> {
  ExpenseApprovalsRepository()
      : super(
          collectionPath: 'expense_approvals',
          fromMap: (m) => ExpenseApprovalModel.fromMap(m),
          toMap: (a) => a.toMap(),
        );

  Future<List<ExpenseApprovalModel>> getForExpense(int expenseId, {int limit = 100}) {
    return getByField('expense_id', expenseId, limit: limit);
  }
}

class ApprovalRulesRepository extends FirestoreRepository<ApprovalRuleModel> {
  ApprovalRulesRepository()
      : super(
          collectionPath: 'approval_rules',
          fromMap: (m) => ApprovalRuleModel.fromMap(m),
          toMap: (r) => r.toMap(),
        );
}
