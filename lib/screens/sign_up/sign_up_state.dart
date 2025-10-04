class SignUpState {
  final String name;
  final String email;
  final String password;
  final String confirmPassword;
  final String country;
  final bool isAdmin; // added field

  SignUpState({
    this.name = '',
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.country = '',
    this.isAdmin = true, // default true
  });

  SignUpState copyWith({
    String? name,
    String? email,
    String? password,
    String? confirmPassword,
    String? country,
    bool? isAdmin,
  }) {
    return SignUpState(
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      country: country ?? this.country,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}
