import 'package:flutter/material.dart';
import 'loginPage.dart';
import '../signUp/signUpData.dart';


class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            Navigator.of(context).pop(); // 이전 화면으로 돌아가기
          },
        ),
      ),
      body: CustomLoginScreen(),
    );
  }
}