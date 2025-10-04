import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xyz/screens/sign_in/sign_in_state.dart';

final signInProvider = StateNotifierProvider<SignInNotifier,SignInState>((ref){
  return SignInNotifier();
});

class SignInNotifier extends StateNotifier<SignInState>{
  SignInNotifier() : super(SignInState());


  void updateEmail(String value){
    state = state.copyWith(email: value);
  }

  void updatePassword(String value){
    state = state.copyWith(password: value);
  }

}