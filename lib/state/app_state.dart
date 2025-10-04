import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  String? _baseCurrency; // Company's base currency code, e.g., INR, USD
  String? _countryName; // Optional, chosen during signup

  String? get baseCurrency => _baseCurrency;
  String? get countryName => _countryName;

  void setCompanyCurrency({required String code, String? country}) {
    _baseCurrency = code;
    _countryName = country ?? _countryName;
    notifyListeners();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState notifier, required Widget child})
      : super(notifier: notifier, child: child);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in context');
    return scope!.notifier!;
  }
}
