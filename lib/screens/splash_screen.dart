import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends StatefulWidget {
  static const routeName = '/splash';
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1200), () async {
      if (!mounted) return;
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        // If you later store roles, you can route to admin/employee here.
        Navigator.pushReplacementNamed(context, '/employee');
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 240),
              child: Lottie.asset(
                'android/assets/Meeting Analytics.json',
                repeat: true,
                frameRate: FrameRate.max,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Expense Management',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: cs.primary, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
