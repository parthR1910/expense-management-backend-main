import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xyz/customs/custom_buton.dart';
import 'package:xyz/customs/custom_textfield.dart';
import 'package:xyz/routes/app_routes.dart';
import 'package:xyz/screens/sign_in/sign_in_controller.dart';
import 'package:xyz/screens/sign_in/sign_in_notifier.dart';

class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  late SignInController signInController;

  @override
  void initState() {
    signInController = SignInController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signInProvider);
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: width > 600 ? 500 : width * 0.9, // responsive width
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Welcome Back",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Login to your account",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 32),
                // Email
                CustomTextField(
                  controller: signInController.emailController,
                  label: "Email",
                  hintText: "Enter your email address",
                  prefixIcon: const Icon(Icons.email),
                  onChanged: (value) =>
                      ref.read(signInProvider.notifier).updateEmail(value),
                ),
                const SizedBox(height: 20),
                // Password
                CustomTextField(
                  controller: signInController.passwordController,
                  label: "Password",
                  hintText: "Enter your password",
                  obscureText: true,
                  prefixIcon: const Icon(Icons.lock),
                  onChanged: (value) =>
                      ref.read(signInProvider.notifier).updatePassword(value),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // TODO: Forgot password
                    },
                    child: const Text("Forgot password?"),
                  ),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: "Login",
                  onPressed: () => signInController.handleSignIn(ref, context),
                  type: ButtonType.filled,
                  backgroundColor: Colors.indigo,
                ),

                const SizedBox(height: 16),

                CustomButton(
                  text: "Register",
                  onPressed: () {
                    context.push(AppRoutesNames.signUp);
                  },
                  type: ButtonType.outlined,
                  backgroundColor: Colors.indigo,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
