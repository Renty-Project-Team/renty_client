class SignupData {
  String name;
  String userName;
  String pw;
  String email;
  String phone;

  SignupData({
    this.name = '',
    this.userName = '',
    this.pw = '',
    this.email = '',
    this.phone = '',
  });

  // 복사본 생성
  SignupData copyWith({
    String? name,
    String? userName,
    String? email,
    String? pw,
    String? phone,
  }) {
    return SignupData(
      name: name ?? this.name,
      userName: userName ?? this.userName,
      email: email ?? this.email,
      pw: pw ?? this.pw,
      phone: phone ?? this.phone,
    );
  }
}
