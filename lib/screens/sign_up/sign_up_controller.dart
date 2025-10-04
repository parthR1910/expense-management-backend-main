import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xyz/customs/custom_toast.dart';
import 'package:xyz/screens/sign_up/sign_up_notifier.dart';
import 'package:xyz/screens/sign_up/sign_up_state.dart';

class SignUpController {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  SignUpController();

  /// Handles Firebase sign-up with full validation and Firestore storage
  Future<void> handleSignUp(WidgetRef ref, BuildContext context) async {
    final state = ref.watch(signUpProvider);

    // Assign controllers from state
    nameController.text = state.name;
    emailController.text = state.email;
    passwordController.text = state.password;
    confirmPasswordController.text = state.confirmPassword;

    final notifier = ref.read(signUpProvider.notifier);

    // --- Validation ---
    final name = state.name.trim();
    final email = state.email.trim();
    final password = state.password;
    final confirmPassword = state.confirmPassword;
    final country = state.country.trim();

    if (name.isEmpty || name.length < 3) {
      ToastUtils.showToast("Name must be at least 3 characters", backgroundColor: Colors.red);
      return;
    }

    if (email.isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      ToastUtils.showToast("Enter a valid email address", backgroundColor: Colors.red);
      return;
    }

    if (password.isEmpty || password.length < 6) {
      ToastUtils.showToast("Password must be at least 6 characters", backgroundColor: Colors.red);
      return;
    }

    if (confirmPassword.isEmpty || confirmPassword != password) {
      ToastUtils.showToast("Passwords do not match", backgroundColor: Colors.red);
      return;
    }

    if (country.isEmpty) {
      ToastUtils.showToast("Please select your country", backgroundColor: Colors.red);
      return;
    }

    // --- Firebase Sign Up ---
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        final uid = credential.user!.uid;

        // Update display name in FirebaseAuth
        await credential.user!.updateDisplayName(name);

        // --- Save user data to Firestore using model ---
        final userData = state.copyWith(isAdmin: true); // default isAdmin true
        await FirebaseFirestore.instance.collection('admin').doc(uid).set({
          'name': userData.name,
          'email': userData.email,
          'country': userData.country,
          'uid': uid,
          'createdAt': FieldValue.serverTimestamp(),
          'isAdmin': userData.isAdmin,
        });

        ToastUtils.showToast("Sign up successful!", backgroundColor: Colors.green);
        Navigator.pop(context); // Go back to SignIn page
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        ToastUtils.showToast("Email already in use", backgroundColor: Colors.red);
      } else if (e.code == 'weak-password') {
        ToastUtils.showToast("Password is too weak", backgroundColor: Colors.red);
      } else {
        ToastUtils.showToast(e.message ?? "Sign up failed", backgroundColor: Colors.red);
      }
    } catch (e) {
      ToastUtils.showToast("An error occurred: ${e.toString()}", backgroundColor: Colors.red);
    }
  }
}
