import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

class ExtractPage extends StatefulWidget {
  static const String routeName = '/extract';

  const ExtractPage({super.key});

  @override
  ExtractPageState createState() => ExtractPageState();
}

class ExtractPageState extends State<ExtractPage> {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;

  String _extractedText = '';
  String _language = '';
  String _merchantName = '';
  String _receiptDate = '';
  String _currency = '';
  String _totalPrice = '';
  String _category = '';

  final TextStyle infoTextStyle = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  // Pick from Gallery
  Future<void> _pickFromGallery() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (pickedFile == null) return;
      setState(() => _imageFile = File(pickedFile.path));
      final base64Image = await _processImage(_imageFile!);
      if (base64Image != null) await recognizeText(base64Image);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to open gallery: $e')));
    }
  }

  // Capture from Camera
  Future<void> _captureFromCamera() async {
    final cameraStatus = await Permission.camera.request();
    if (cameraStatus.isGranted) {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (pickedFile == null) return;
      setState(() => _imageFile = File(pickedFile.path));
      final base64Image = await _processImage(_imageFile!);
      if (base64Image != null) await recognizeText(base64Image);
    } else if (cameraStatus.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  // Resize + Convert to Base64
  Future<String?> _processImage(File imageFile) async {
    final imageBytes = await imageFile.readAsBytes();
    img.Image? image = img.decodeImage(imageBytes);
    if (image == null) return null;
    image = img.copyResize(image, width: 640);
    final resizedBytes = img.encodeJpg(image, quality: 85);
    return base64Encode(resizedBytes);
  }

  // Call OCR Cloud Function
  Future<void> recognizeText(String base64Image) async {
    try {
      final url = Uri.parse(
        'https://annotateimagehttp-uh7mqi6ahq-uc.a.run.app',
      );
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({"image": base64Image}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final text = (data['text'] ?? '').toString();
        setState(() {
          _extractedText = text;
          _merchantName = _extractMerchantName(text);
          _language = detectLanguage(text);
          _currency = _extractCurrency(text);
          _totalPrice = _extractAmount(text);
          _receiptDate = _extractDate(text);
          _category = _inferCategory(text);
        });
        // Auto-return extracted data to the caller
        _useThisData();
      } else {
        setState(() {
          _extractedText =
              'HTTP failed: ${response.statusCode}\n${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _extractedText = 'Error calling OCR: $e';
      });
    }
  }

  // --- Helper Extractors ---
  String _extractMerchantName(String text) {
    final lines = text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    for (final line in lines) {
      if (line.toLowerCase().contains('invoice') ||
          line.toLowerCase().contains('bill')) {
        final idx = lines.indexOf(line);
        if (idx > 0) return lines[idx - 1];
      }
    }
    return lines.isNotEmpty ? lines.first : 'Not Found';
  }

  String _extractAmount(String text) {
    final lines = text.split('\n');
    final keyIdx = lines.indexWhere((l) {
      final s = l.toLowerCase();
      return s.contains('grand total') ||
          s.contains('total') ||
          s.contains('amount payable') ||
          s.contains('balance due');
    });
    final searchText = keyIdx >= 0
        ? lines.sublist(keyIdx.clamp(0, lines.length)).take(3).join(' ')
        : text;
    final regex = RegExp(
      r'(\d{1,3}(?:[,\s]\d{3})*(?:[\.,]\d{2})|\d+[\.,]\d{2})',
    );
    RegExpMatch? last(Iterable<RegExpMatch> it) {
      RegExpMatch? m;
      for (final e in it) m = e;
      return m;
    }

    final value =
        (last(regex.allMatches(searchText)) ?? last(regex.allMatches(text)))
            ?.group(0);
    return value?.replaceAll(',', '').trim() ?? 'Not Found';
  }

  String detectLanguage(String text) {
    final t = text.toLowerCase();
    if (t.contains('total') || t.contains('amount')) return 'English';
    if (t.contains('कुल') || t.contains('राशि') || t.contains('कुल राशि'))
      return 'Hindi';
    return 'Unknown';
  }

  String _extractCurrency(String text) {
    final t = text.toLowerCase();
    if (text.contains('₹') ||
        RegExp(r'\brs\.?\b').hasMatch(t) ||
        RegExp(r'\binr\b').hasMatch(t))
      return 'INR';
    if (text.contains('€') || t.contains('eur')) return 'EUR';
    if (text.contains('£') || t.contains('gbp')) return 'GBP';
    if (text.contains('¥') || t.contains('jpy')) return 'JPY';
    if (t.contains('chf')) return 'CHF';
    if (t.contains('cny')) return 'CNY';
    if (t.contains('sgd')) return 'SGD';
    if (t.contains('aud')) return 'AUD';
    if (t.contains('cad')) return 'CAD';
    if (t.contains('nzd')) return 'NZD';
    if (text.contains('\$') || t.contains('usd')) return 'USD';
    return 'Unknown';
  }

  String _extractDate(String text) {
    final regex = RegExp(
      r'(\d{1,2}[\/\-\.\s]\d{1,2}[\/\-\.\s]\d{2,4}|\d{4}[\/\-\.\s]\d{1,2}[\/\-\.\s]\d{1,2})',
    );
    final match = regex.firstMatch(text);
    if (match == null) return 'Not Found';
    final raw = match.group(0)!;
    final candidates = <String>[
      'dd/MM/yyyy',
      'dd-MM-yyyy',
      'dd.MM.yyyy',
      'dd MM yyyy',
      'MM/dd/yyyy',
      'MM-dd-yyyy',
      'MM.dd.yyyy',
      'yyyy-MM-dd',
      'yyyy/MM/dd',
      'yyyy.MM.dd',
      'd/M/yyyy',
      'd-M-yyyy',
      'd.M.yyyy',
      'yyyy-M-d',
      'yyyy/M/d',
      'yyyy.M.d',
    ];
    for (final f in candidates) {
      try {
        final parsed = DateFormat(f).parseLoose(raw);
        return DateFormat('yyyy-MM-dd').format(parsed);
      } catch (_) {}
    }
    return raw;
  }

  String _inferCategory(String text) {
    final t = text.toLowerCase();
    const food = [
      'restaurant',
      'cafe',
      'food',
      'meal',
      'pizza',
      'burger',
      'curry',
      'coffee',
      'tea',
      'grocery',
      'mart',
      'store',
      'supermarket',
      'dairy',
      'bakery',
    ];
    const travel = [
      'uber',
      'ola',
      'taxi',
      'cab',
      'airline',
      'flight',
      'train',
      'bus',
      'fuel',
      'petrol',
      'diesel',
      'gas',
      'toll',
      'parking',
      'auto',
      'rickshaw',
      'rental',
    ];
    const stay = [
      'hotel',
      'motel',
      'lodge',
      'resort',
      'airbnb',
      'inn',
      'guest house',
      'hostel',
    ];
    if (food.any(t.contains)) return 'Food';
    if (travel.any(t.contains)) return 'Travel';
    if (stay.any(t.contains)) return 'Stay';
    return 'Other';
  }

  void _useThisData() {
    // Return extracted data to caller for auto-fill
    if (!mounted) return;
    Navigator.pop(context, {
      'imagePath': _imageFile?.path,
      'text': _extractedText,
      'merchant': _merchantName,
      'date': _receiptDate,
      'currency': _currency,
      'amount': _totalPrice,
      'category': _category,
      'language': _language,
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Extract Receipt'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_imageFile != null)
              Image.file(_imageFile!, height: 220, fit: BoxFit.contain),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
                ElevatedButton.icon(
                  onPressed: _captureFromCamera,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                ),
              ],
            ),
            const Divider(height: 32),
            Text('Merchant: $_merchantName', style: infoTextStyle),
            Text('Date: $_receiptDate', style: infoTextStyle),
            Text('Currency: $_currency', style: infoTextStyle),
            Text('Total: $_totalPrice', style: infoTextStyle),
            Text('Language: $_language', style: infoTextStyle),
            Text('Category: $_category', style: infoTextStyle),
            const SizedBox(height: 16),
            Text('Raw OCR:', style: infoTextStyle),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_extractedText, style: const TextStyle(fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}
