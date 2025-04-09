class SignupData {
  String name;
  String pw;
  String email;
  String phone;

  SignupData({
    this.name = '',
    this.pw = '',
    this.email = '',
    this.phone = '',
  });

  // 복사본 생성
  SignupData copyWith({
    String? name,
    String? email,
    String? pw,
    String? phone,
  }) {
    return SignupData(
      name: name ?? this.name,
      email: email ?? this.email,
      pw: pw ?? this.pw,
      phone: phone ?? this.phone,
    );
  }
}
