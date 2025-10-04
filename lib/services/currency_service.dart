import 'dart:convert';
import 'package:http/http.dart' as http;

class CountryCurrency {
  final String country;
  final String code; // e.g., INR
  final String name; // e.g., Indian Rupee

  CountryCurrency({required this.country, required this.code, required this.name});

  @override
  String toString() => '$country ($code) — $name';
}

class CurrencyService {
  static const countriesUrl = 'https://restcountries.com/v3.1/all?fields=name,currencies';
  // Reliable, keyless endpoint. Docs: https://exchangerate.host/#/#docs
  static const rateUrl = 'https://api.exchangerate.host/latest?base=';

  static Future<List<CountryCurrency>> fetchCountries() async {
    final res = await http.get(Uri.parse(countriesUrl)).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) throw Exception('Failed to load countries');
    final List data = json.decode(res.body) as List;
    final list = <CountryCurrency>[];
    for (final item in data) {
      final name = (item['name']?['common'] ?? '').toString();
      final currencies = item['currencies'] as Map<String, dynamic>?;
      if (name.isEmpty || currencies == null || currencies.isEmpty) continue;
      final firstCode = currencies.keys.first;
      final currName = currencies[firstCode]?['name']?.toString() ?? firstCode;
      list.add(CountryCurrency(country: name, code: firstCode, name: currName));
    }
    list.sort((a, b) => a.country.compareTo(b.country));
    return list;
  }

  static Future<Map<String, double>> fetchRates(String base) async {
    final normalizedBase = base.toUpperCase();
    final uri = Uri.parse('$rateUrl$normalizedBase');
    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw Exception('Failed to load rates (${res.statusCode})');
    }
    final data = json.decode(res.body) as Map<String, dynamic>;
    if (data['rates'] is! Map) throw Exception('Malformed rates response');
    final rates = (data['rates'] as Map).map((k, v) => MapEntry(k.toString(), (v as num).toDouble()));
    return rates;
  }
}
