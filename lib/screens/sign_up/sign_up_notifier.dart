import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sign_up_state.dart';

final signUpProvider = StateNotifierProvider<SignUpNotifier, SignUpState>((ref) {
  return SignUpNotifier();
});

class SignUpNotifier extends StateNotifier<SignUpState> {
  SignUpNotifier() : super(SignUpState());

  void updateName(String value) {
    state = state.copyWith(name: value);
  }

  void updateEmail(String value) {
    state = state.copyWith(email: value);
  }

  void updatePassword(String value) {
    state = state.copyWith(password: value);
  }

  void updateConfirmPassword(String value) {
    state = state.copyWith(confirmPassword: value);
  }

  void updateCountry(String value) {
    state = state.copyWith(country: value);
  }
}
