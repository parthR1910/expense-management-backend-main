import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/extract_page.dart';

class EmployeeExpenseFormScreen extends StatefulWidget {
  static const routeName = '/employee/form';
  const EmployeeExpenseFormScreen({super.key});

  @override
  State<EmployeeExpenseFormScreen> createState() =>
      _EmployeeExpenseFormScreenState();
}

class _EmployeeExpenseFormScreenState extends State<EmployeeExpenseFormScreen> {
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  String? _category;
  String? _paidBy;
  String? _currency = 'USD';

  File? _receiptFile;
  String? _receiptName;
  int? _receiptSize;
  bool _isReceiptImage = false;

  final _categories = const ['Food', 'Travel', 'Stay', 'Other'];
  final _people = const ['Self', 'Company Card'];
  List<String> _currencies = ['USD', 'INR', 'EUR', 'GBP', 'JPY', 'AUD', 'CAD'];
  String? _language;
  bool _submitting = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _launchExtract() async {
    final res = await Navigator.pushNamed(context, ExtractPage.routeName);
    if (res is Map) {
      // Attach image file if provided
      final imagePath = res['imagePath'] as String?;
      if (imagePath != null && imagePath.isNotEmpty) {
        try {
          final appDir = await getApplicationDocumentsDirectory();
          final receiptsDir = Directory(p.join(appDir.path, 'receipts'));
          if (!await receiptsDir.exists()) {
            await receiptsDir.create(recursive: true);
          }
          final baseName = p.basename(imagePath);
          final newPath = p.join(
              receiptsDir.path, '${DateTime.now().millisecondsSinceEpoch}_$baseName');
          final saved = await File(imagePath).copy(newPath);
          final ext = p.extension(saved.path).toLowerCase();
          setState(() {
            _receiptFile = saved;
            _receiptName = baseName;
            _receiptSize = saved.lengthSync();
            _isReceiptImage = ['.jpg', '.jpeg', '.png'].contains(ext);
          });
        } catch (_) {}
      }
      // Autofill fields
      final merchant = (res['merchant'] ?? '').toString();
      final currency = (res['currency'] ?? '').toString();
      final amount = (res['amount'] ?? '').toString();
      final category = (res['category'] ?? '').toString();
      final language = (res['language'] ?? '').toString();
      setState(() {
        if (merchant.isNotEmpty) _descCtrl.text = merchant;
        if (currency.isNotEmpty) {
          if (!_currencies.contains(currency)) {
            _currencies = [..._currencies, currency];
          }
          _currency = currency;
        }
        if (amount.isNotEmpty && _amountCtrl.text.isEmpty) {
          _amountCtrl.text = amount;
        }
        if (category.isNotEmpty && _categories.contains(category)) {
          _category = category;
        }
        if (language.isNotEmpty) {
          _language = language;
        }
      });
    }
  }

  Future<void> _submitExpense() async {
    if (_descCtrl.text.trim().isEmpty || _amountCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Description and amount are required')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid;
      final email = user?.email ?? '';
      String ownerName = user?.displayName ?? '';
      String? companyId;
      String? companyName;

      if (uid != null) {
        final userSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        final u = userSnap.data() ?? {};
        ownerName = (u['name'] ?? ownerName) as String? ?? ownerName;
        companyId = (u['company_id'] ?? '') as String?;
        companyName = (u['company_name'] ?? '') as String?;
      }

      final amount = double.tryParse(_amountCtrl.text.replaceAll(',', ''));

      await FirebaseFirestore.instance.collection('expenses').add({
        // Linking
        'user_id': uid,
        'owner': ownerName.isNotEmpty ? ownerName : (email.isNotEmpty ? email : 'Unknown'),
        'employee_email': email,
        'company_id': companyId,
        'company_name': companyName,

        // Expense details (aligned with dashboards/queries)
        'description': _descCtrl.text.trim(),
        'category': _category,
        'amount_original': amount,
        'currency_original': _currency,
        'paid_by': _paidBy,
        'status': 'Pending',
        'created_at': FieldValue.serverTimestamp(),

        // Attachment (local path placeholder)
        'receipt_path': _receiptFile?.path,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense submitted')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _pickReceipt() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: false,
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
      );
      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.single.path;
      if (filePath == null) return;

      final appDir = await getApplicationDocumentsDirectory();
      final receiptsDir = Directory(p.join(appDir.path, 'receipts'));
      if (!await receiptsDir.exists()) {
        await receiptsDir.create(recursive: true);
      }

      final baseName = p.basename(filePath);
      final newPath = p.join(
        receiptsDir.path,
        '${DateTime.now().millisecondsSinceEpoch}_$baseName',
      );
      final saved = await File(filePath).copy(newPath);

      final ext = p.extension(saved.path).toLowerCase();
      setState(() {
        _receiptFile = saved;
        _receiptName = baseName;
        _receiptSize = saved.lengthSync();
        _isReceiptImage = ['.jpg', '.jpeg', '.png'].contains(ext);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Attached: $baseName')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick file: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Expense')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 380;
                if (narrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _pickReceipt,
                        icon: const Icon(Icons.attachment),
                        label: const Text('Attach Receipt'),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _launchExtract,
                        icon: const Icon(Icons.document_scanner_outlined),
                        label: const Text('Scan & Autofill'),
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickReceipt,
                        icon: const Icon(Icons.attachment),
                        label: const Text('Attach Receipt'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _launchExtract,
                        icon: const Icon(Icons.document_scanner_outlined),
                        label: const Text('Scan & Autofill'),
                      ),
                    ),
                  ],
                );
              },
            ),
            if (_receiptFile != null) ...[
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    if (_isReceiptImage)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _receiptFile!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      const Icon(Icons.picture_as_pdf, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _receiptName ?? 'Receipt',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (_receiptSize != null)
                            Text('${(_receiptSize! / 1024).toStringAsFixed(1)} KB',
                                style: Theme.of(context).textTheme.bodySmall),
                          Text(
                            _isReceiptImage ? 'Image' : 'PDF',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove',
                      onPressed: () {
                        setState(() {
                          _receiptFile = null;
                          _receiptName = null;
                          _receiptSize = null;
                          _isReceiptImage = false;
                        });
                      },
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(labelText: 'Description'),
              controller: _descCtrl,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Category'),
              value: _category,
              items: _categories
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v),
              isExpanded: true,
            ),
            const SizedBox(height: 12),
            // Removed Expense Date field as requested
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Paid by'),
              value: _paidBy,
              items: _people
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _paidBy = v),
              isExpanded: true,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Total amount',
                    ),
                    keyboardType: TextInputType.number,
                    controller: _amountCtrl,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Currency'),
                    value: _currency,
                    items: _currencies
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => _currency = v),
                  ),
                ),
              ],
            ),
            // Removed Remarks field as requested
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submitting ? null : _submitExpense,
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Submit'),
            ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
