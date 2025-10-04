import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:country_picker/country_picker.dart';
import 'package:xyz/customs/custom_buton.dart';
import 'package:xyz/customs/custom_textfield.dart';
import 'package:xyz/routes/app_routes.dart';
import 'package:xyz/screens/sign_up/sign_up_controller.dart';
import 'package:xyz/screens/sign_up/sign_up_notifier.dart';

class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  late SignUpController signUpController;

  @override
  void initState() {
    signUpController = SignUpController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signUpProvider);
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: width > 600 ? 500 : width * 0.9,
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
                  "Create Account",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Fill your details to sign up",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 32),
                CustomTextField(
                  controller: signUpController.nameController,
                  label: "Company Name",
                  hintText: "Enter your full company name",
                  prefixIcon: const Icon(Icons.person),
                  onChanged: (value) => ref.read(signUpProvider.notifier).updateName(value),
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: signUpController.emailController,
                  label: "Email",
                  hintText: "Enter your email address",
                  prefixIcon: const Icon(Icons.email),
                  onChanged: (value) => ref.read(signUpProvider.notifier).updateEmail(value),
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: signUpController.passwordController,
                  label: "Password",
                  hintText: "Enter your password",
                  obscureText: true,
                  prefixIcon: const Icon(Icons.lock),
                  onChanged: (value) => ref.read(signUpProvider.notifier).updatePassword(value),
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: signUpController.confirmPasswordController,
                  label: "Confirm Password",
                  hintText: "Re-enter your password",
                  obscureText: true,
                  prefixIcon: const Icon(Icons.lock_outline),
                  onChanged: (value) => ref.read(signUpProvider.notifier).updateConfirmPassword(value),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    showCountryPicker(
                      context: context,
                      showPhoneCode: false,
                      onSelect: (Country country) {
                        ref.read(signUpProvider.notifier).updateCountry(country.name);
                      },
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(state.country.isEmpty ? "Select Country" : state.country),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                CustomButton(
                  text: "Sign Up",
                  onPressed: () => signUpController.handleSignUp(ref, context),
                  type: ButtonType.filled,
                  backgroundColor: Colors.indigo,
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: "Back to Login",
                  onPressed: () => Navigator.pop(context),
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
