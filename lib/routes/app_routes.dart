import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xyz/screens/home/home.dart';
import 'package:xyz/screens/sign_in/sign_in.dart';
import 'package:xyz/screens/sign_up/sign_up.dart';
import 'package:xyz/screens/drawer/pannel_member.dart';

class AppRoutesNames {
  static const String signIn = '/signin';
  static const String signUp = '/signup';
  static const String home = '/home';
  static const String pannelMember = '/pannel_member'; // new route
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutesNames.signIn,
    routes: [
      GoRoute(
        path: AppRoutesNames.signIn,
        builder: (context, state) => const SignInPage(),
      ),
      GoRoute(
        path: AppRoutesNames.signUp,
        builder: (context, state) => const SignUpPage(),
      ),
      GoRoute(
        path: AppRoutesNames.home,
        builder: (context, state) => HomeScreen(),
      ),
      GoRoute(
        path: AppRoutesNames.pannelMember,
        builder: (context, state) =>  TeamLeadScreen(), // new screen
      ),
    ],
  );
});
