import 'package:flutter/material.dart';
import 'loginPage.dart';
import 'signUp/signUpData.dart';


class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: CustomLoginScreen()
      ),
    );
  }
}