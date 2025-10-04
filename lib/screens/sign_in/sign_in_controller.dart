import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xyz/customs/custom_toast.dart';
import 'package:xyz/routes/app_routes.dart';
import 'package:xyz/screens/sign_in/sign_in_notifier.dart';
import 'package:xyz/screens/sign_in/sign_in_repo.dart';

class SignInController {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  SignInController();

  /// Handles Firebase sign-in using email and password
  Future<void> handleSignIn(WidgetRef ref, BuildContext context) async {
    final state = ref.watch(signInProvider);
    final email = state.email;
    final password = state.password;

    emailController.text = email;
    passwordController.text = password;

    if (email.isEmpty || password.isEmpty) {
      ToastUtils.showToast("Email and password cannot be empty", backgroundColor: Colors.red);
      return;
    }

    try {
      final credential = await SignInRepo.firebaseSignIn(email, password);

      if (credential.user == null) {
        ToastUtils.showToast("User not found", backgroundColor: Colors.red);
        return;
      }

      // Login successful → navigate to Admin Dashboard
      // context.go(AppRoutesNames.home);
      ToastUtils.showToast("Login successful", backgroundColor: Colors.green);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        ToastUtils.showToast("User not found", backgroundColor: Colors.red);
      } else if (e.code == 'wrong-password') {
        ToastUtils.showToast("Incorrect password", backgroundColor: Colors.red);
      } else {
        ToastUtils.showToast(e.message ?? "Authentication error", backgroundColor: Colors.red);
      }
    } catch (e) {
      ToastUtils.showToast("An error occurred: ${e.toString()}", backgroundColor: Colors.red);
    }
  }
}
