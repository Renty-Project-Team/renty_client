class SignupData {
  String name;
  String birth;
  String email;
  String phone;

  SignupData({
    this.name = '',
    this.birth = '',
    this.email = '',
    this.phone = '',
  });

  // 복사본 생성
  SignupData copyWith({
    String? name,
    String? birth,
    String? email,
    String? phone,
  }) {
    return SignupData(
      name: name ?? this.name,
      birth: birth ?? this.birth,
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }
}
