import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'state/app_state.dart';
import 'services/services.dart';
import 'screens/model/model.dart';

// Screens
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/employee_expense_list_screen.dart';
import 'screens/employee_expense_form_screen.dart';
import 'screens/manager_approvals_screen.dart';
import 'screens/employee_shell.dart';
import 'screens/splash_screen.dart';
import 'screens/extract_page.dart';
import 'screens/approvals_dashboard.dart';
import 'screens/manager/approvals_nav.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final appState = AppState();
  runApp(AppScope(notifier: appState, child: const MyApp()));
}

// Seed 5 sample companies into Firestore (call this manually when needed)
Future<void> seedCompaniesDemo() async {
  final repo = CompaniesRepository();
  final samples = <CompanyModel>[
    const CompanyModel(name: 'Acme Corp', country: 'USA', currencyCode: 'USD'),
    const CompanyModel(name: 'Globex Ltd', country: 'UK', currencyCode: 'GBP'),
    const CompanyModel(name: 'Innotech', country: 'India', currencyCode: 'INR'),
    const CompanyModel(name: 'Soylent', country: 'Germany', currencyCode: 'EUR'),
    const CompanyModel(name: 'Umbrella', country: 'Japan', currencyCode: 'JPY'),
  ];
  for (final c in samples) {
    await repo.create(c);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Expense Management',
      theme: ThemeData(
        useMaterial3: true,
        // 🎨 Modern color palette with cohesive contrast
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5B5BD6), // Indigo-violet base
          primary: const Color(0xFF5B5BD6),
          secondary: const Color(0xFF00BFA6), // Teal accent
          surface: const Color(0xFFF8F9FB),
          surfaceContainerHighest: const Color(0xFFEDEFF3),
          error: const Color(0xFFD32F2F),
          brightness: Brightness.light,
        ),

        // 🧱 App backgrounds & text
        scaffoldBackgroundColor: const Color(0xFFF8F9FB),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontWeight: FontWeight.w600, fontSize: 22),
          titleMedium: TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
          bodyMedium: TextStyle(fontSize: 15),
          bodySmall: TextStyle(fontSize: 13),
        ),

        // 🪟 Input fields
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF0F1F4),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          labelStyle: const TextStyle(fontWeight: FontWeight.w500),
          hintStyle: TextStyle(color: Colors.grey.shade500),
        ),

        // 🔘 Filled Buttons
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF5B5BD6),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),

        // 🧷 Text Buttons
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF5B5BD6),
            textStyle: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),

        // 🔄 Page Transitions
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),

      // 🧭 App Routing
      initialRoute: SplashScreen.routeName,
      routes: {
        SplashScreen.routeName: (_) => const SplashScreen(),
        LoginScreen.routeName: (_) => const LoginScreen(),
        SignupScreen.routeName: (_) => const SignupScreen(),
        EmployeeShell.routeName: (_) => const EmployeeShell(),
        ManagerApprovalsNav.routeName: (_) => const ManagerApprovalsNav(),
        ApprovalsDashboard.routeName: (_) => const ApprovalsDashboard(),
        // Direct routes to Approved/Rejected lists
        '/approvals/approved': (_) => const AcceptedRequestsScreen(),
        '/approvals/rejected': (_) => const RejectedRequestsScreen(),
        EmployeeExpenseListScreen.routeName: (_) =>
            const EmployeeExpenseListScreen(),
        EmployeeExpenseFormScreen.routeName: (_) =>
            const EmployeeExpenseFormScreen(),
        ExtractPage.routeName: (_) => const ExtractPage(),
        ManagerApprovalsScreen.routeName: (_) => const ManagerApprovalsScreen(),
      },
    );
  }
}
