// lib/models/models.dart
import 'dart:convert';

enum RoleEnum { Admin, Manager, Employee }

enum ExpenseStatus { Pending, Approved, Rejected }

RoleEnum roleEnumFromString(String? v) {
  switch ((v ?? '').toLowerCase()) {
    case 'admin':
      return RoleEnum.Admin;
    case 'manager':
      return RoleEnum.Manager;
    case 'employee':
      return RoleEnum.Employee;
    default:
      return RoleEnum.Employee;
  }
}

String roleEnumToString(RoleEnum v) {
  switch (v) {
    case RoleEnum.Admin:
      return 'Admin';
    case RoleEnum.Manager:
      return 'Manager';
    case RoleEnum.Employee:
      return 'Employee';
  }
}

ExpenseStatus expenseStatusFromString(String? v) {
  switch ((v ?? '').toLowerCase()) {
    case 'pending':
      return ExpenseStatus.Pending;
    case 'approved':
      return ExpenseStatus.Approved;
    case 'rejected':
      return ExpenseStatus.Rejected;
    default:
      return ExpenseStatus.Pending;
  }
}

String expenseStatusToString(ExpenseStatus v) {
  switch (v) {
    case ExpenseStatus.Pending:
      return 'Pending';
    case ExpenseStatus.Approved:
      return 'Approved';
    case ExpenseStatus.Rejected:
      return 'Rejected';
  }
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is int) {
    // if backend returns epoch ms
    return DateTime.fromMillisecondsSinceEpoch(v);
  }
  if (v is String && v.trim().isNotEmpty) {
    // try ISO or common formats
    try {
      return DateTime.parse(v);
    } catch (_) {}
  }
  return null;
}

String? _toIsoString(DateTime? d) => d?.toIso8601String();

T? _as<T>(Map<String, dynamic> m, String k) => m[k] is T ? m[k] as T : null;

// ----------------------------- User -----------------------------
class UserModel {
  final int? id;
  final int? companyId;
  final String? email;
  final String? hashedPassword;
  final String? firstName;
  final String? lastName;
  final RoleEnum role;
  final int? managerId;
  final bool? isActive;
  final DateTime? createdAt;

  const UserModel({
    this.id,
    this.companyId,
    this.email,
    this.hashedPassword,
    this.firstName,
    this.lastName,
    this.role = RoleEnum.Employee,
    this.managerId,
    this.isActive,
    this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: _as<int>(map, 'id'),
      companyId: _as<int>(map, 'company_id'),
      email: _as<String>(map, 'email'),
      hashedPassword: _as<String>(map, 'hashed_password'),
      firstName: _as<String>(map, 'first_name'),
      lastName: _as<String>(map, 'last_name'),
      role: roleEnumFromString(map['role'] as String?),
      managerId: _as<int>(map, 'manager_id'),
      isActive: _as<bool>(map, 'is_active'),
      createdAt: _parseDate(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'company_id': companyId,
    'email': email,
    'hashed_password': hashedPassword,
    'first_name': firstName,
    'last_name': lastName,
    'role': roleEnumToString(role),
    'manager_id': managerId,
    'is_active': isActive,
    'created_at': _toIsoString(createdAt),
  };

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source) as Map<String, dynamic>);
  String toJson() => json.encode(toMap());
}

// ----------------------------- Device -----------------------------
class DeviceModel {
  final int? id;
  final String? deviceId;
  final int? deviceType; // 0 = iOS, 1 = Android
  final String? osVersion;
  final String? deviceName;
  final String? appVersion;
  final String? fcmToken;
  final String? latitude;
  final String? longitude;
  final String? authToken;
  final int? userId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DeviceModel({
    this.id,
    this.deviceId,
    this.deviceType,
    this.osVersion,
    this.deviceName,
    this.appVersion,
    this.fcmToken,
    this.latitude,
    this.longitude,
    this.authToken,
    this.userId,
    this.createdAt,
    this.updatedAt,
  });

  factory DeviceModel.fromMap(Map<String, dynamic> map) {
    return DeviceModel(
      id: _as<int>(map, 'id'),
      deviceId: _as<String>(map, 'device_id'),
      deviceType: _as<int>(map, 'device_type'),
      osVersion: _as<String>(map, 'os_version'),
      deviceName: _as<String>(map, 'device_name'),
      appVersion: map['app_version']?.toString(),
      fcmToken: map['fcm_token']?.toString(),
      latitude: map['latitude']?.toString(),
      longitude: map['longitude']?.toString(),
      authToken: map['auth_token']?.toString(),
      userId: _as<int>(map, 'user_id'),
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'device_id': deviceId,
    'device_type': deviceType,
    'os_version': osVersion,
    'device_name': deviceName,
    'app_version': appVersion,
    'fcm_token': fcmToken,
    'latitude': latitude,
    'longitude': longitude,
    'auth_token': authToken,
    'user_id': userId,
    'created_at': _toIsoString(createdAt),
    'updated_at': _toIsoString(updatedAt),
  };

  factory DeviceModel.fromJson(String source) =>
      DeviceModel.fromMap(json.decode(source) as Map<String, dynamic>);
  String toJson() => json.encode(toMap());
}

// ----------------------------- Company -----------------------------
class CompanyModel {
  final int? id;
  final String? name;
  final String? country;
  final String? currencyCode;
  final DateTime? createdAt;

  const CompanyModel({
    this.id,
    this.name,
    this.country,
    this.currencyCode,
    this.createdAt,
  });

  factory CompanyModel.fromMap(Map<String, dynamic> map) {
    return CompanyModel(
      id: _as<int>(map, 'id'),
      name: _as<String>(map, 'name'),
      country: _as<String>(map, 'country'),
      currencyCode: _as<String>(map, 'currency_code'),
      createdAt: _parseDate(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'country': country,
    'currency_code': currencyCode,
    'created_at': _toIsoString(createdAt),
  };

  factory CompanyModel.fromJson(String source) =>
      CompanyModel.fromMap(json.decode(source) as Map<String, dynamic>);
  String toJson() => json.encode(toMap());
}

// ----------------------------- Expense -----------------------------
class ExpenseModel {
  final int? id;
  final int? employeeId;
  final int? companyId;
  final double? amountOriginal;
  final String? currencyOriginal;
  final double? amountInCompanyCurrency;
  final String? category;
  final String? description;
  final DateTime? date;
  final String? receiptUrl;
  final ExpenseStatus status;
  final int? currentStep;
  final DateTime? createdAt;

  const ExpenseModel({
    this.id,
    this.employeeId,
    this.companyId,
    this.amountOriginal,
    this.currencyOriginal,
    this.amountInCompanyCurrency,
    this.category,
    this.description,
    this.date,
    this.receiptUrl,
    this.status = ExpenseStatus.Pending,
    this.currentStep,
    this.createdAt,
  });

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    double? _toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    return ExpenseModel(
      id: _as<int>(map, 'id'),
      employeeId: _as<int>(map, 'employee_id'),
      companyId: _as<int>(map, 'company_id'),
      amountOriginal: _toDouble(map['amount_original']),
      currencyOriginal: _as<String>(map, 'currency_original'),
      amountInCompanyCurrency: _toDouble(map['amount_in_company_currency']),
      category: _as<String>(map, 'category'),
      description: _as<String>(map, 'description'),
      date: _parseDate(map['date']),
      receiptUrl: _as<String>(map, 'receipt_url'),
      status: expenseStatusFromString(map['status'] as String?),
      currentStep: _as<int>(map, 'current_step'),
      createdAt: _parseDate(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'employee_id': employeeId,
    'company_id': companyId,
    'amount_original': amountOriginal,
    'currency_original': currencyOriginal,
    'amount_in_company_currency': amountInCompanyCurrency,
    'category': category,
    'description': description,
    'date': _toIsoString(date),
    'receipt_url': receiptUrl,
    'status': expenseStatusToString(status),
    'current_step': currentStep,
    'created_at': _toIsoString(createdAt),
  };

  factory ExpenseModel.fromJson(String source) =>
      ExpenseModel.fromMap(json.decode(source) as Map<String, dynamic>);
  String toJson() => json.encode(toMap());
}

// ----------------------------- ApprovalWorkflow -----------------------------
class ApprovalWorkflowModel {
  final int? id;
  final int? companyId;
  final int? stepNumber;
  final String? roleRequired; // Manager, Finance, Director, CFO
  final int? sequenceOrder;
  final DateTime? createdAt;

  const ApprovalWorkflowModel({
    this.id,
    this.companyId,
    this.stepNumber,
    this.roleRequired,
    this.sequenceOrder,
    this.createdAt,
  });

  factory ApprovalWorkflowModel.fromMap(Map<String, dynamic> map) {
    return ApprovalWorkflowModel(
      id: _as<int>(map, 'id'),
      companyId: _as<int>(map, 'company_id'),
      stepNumber: _as<int>(map, 'step_number'),
      roleRequired: _as<String>(map, 'role_required'),
      sequenceOrder: _as<int>(map, 'sequence_order'),
      createdAt: _parseDate(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'company_id': companyId,
    'step_number': stepNumber,
    'role_required': roleRequired,
    'sequence_order': sequenceOrder,
    'created_at': _toIsoString(createdAt),
  };

  factory ApprovalWorkflowModel.fromJson(String source) =>
      ApprovalWorkflowModel.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );
  String toJson() => json.encode(toMap());
}

// ----------------------------- ExpenseApproval -----------------------------
class ExpenseApprovalModel {
  final int? id;
  final int? expenseId;
  final int? approverId;
  final int? stepNumber;
  final ExpenseStatus status;
  final String? comments;
  final DateTime? approvedAt;

  const ExpenseApprovalModel({
    this.id,
    this.expenseId,
    this.approverId,
    this.stepNumber,
    this.status = ExpenseStatus.Pending,
    this.comments,
    this.approvedAt,
  });

  factory ExpenseApprovalModel.fromMap(Map<String, dynamic> map) {
    return ExpenseApprovalModel(
      id: _as<int>(map, 'id'),
      expenseId: _as<int>(map, 'expense_id'),
      approverId: _as<int>(map, 'approver_id'),
      stepNumber: _as<int>(map, 'step_number'),
      status: expenseStatusFromString(map['status'] as String?),
      comments: _as<String>(map, 'comments'),
      approvedAt: _parseDate(map['approved_at']),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'expense_id': expenseId,
    'approver_id': approverId,
    'step_number': stepNumber,
    'status': expenseStatusToString(status),
    'comments': comments,
    'approved_at': _toIsoString(approvedAt),
  };

  factory ExpenseApprovalModel.fromJson(String source) =>
      ExpenseApprovalModel.fromMap(json.decode(source) as Map<String, dynamic>);
  String toJson() => json.encode(toMap());
}

// ----------------------------- ApprovalRule -----------------------------
class ApprovalRuleModel {
  final int? id;
  final int? companyId;
  final String? ruleType; // percentage / special / hybrid
  final int? percentageRequired;
  final String? specialApproverRole; // e.g., CFO
  final DateTime? createdAt;

  const ApprovalRuleModel({
    this.id,
    this.companyId,
    this.ruleType,
    this.percentageRequired,
    this.specialApproverRole,
    this.createdAt,
  });

  factory ApprovalRuleModel.fromMap(Map<String, dynamic> map) {
    return ApprovalRuleModel(
      id: _as<int>(map, 'id'),
      companyId: _as<int>(map, 'company_id'),
      ruleType: _as<String>(map, 'rule_type'),
      percentageRequired: _as<int>(map, 'percentage_required'),
      specialApproverRole: _as<String>(map, 'special_approver_role'),
      createdAt: _parseDate(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'company_id': companyId,
    'rule_type': ruleType,
    'percentage_required': percentageRequired,
    'special_approver_role': specialApproverRole,
    'created_at': _toIsoString(createdAt),
  };

  factory ApprovalRuleModel.fromJson(String source) =>
      ApprovalRuleModel.fromMap(json.decode(source) as Map<String, dynamic>);
  String toJson() => json.encode(toMap());
}
