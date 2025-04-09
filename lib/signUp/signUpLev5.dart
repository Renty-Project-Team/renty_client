import 'package:flutter/material.dart';
import 'package:renty_client/signUp/signUpData.dart';
import 'signUpLev1.dart';
import 'signUpLev2.dart';
import 'signUpLev3.dart';
import 'signUpLev4.dart';
import 'InfoRaw.dart';

class SignupConfirmPage extends StatelessWidget {
  final SignupData signupData;

  const SignupConfirmPage({super.key, required this.signupData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('가입 정보 확인')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InfoRow(
              label: '이름',
              value: signupData.name,
              onEdit: () {
                // 이름 수정 페이지로 이동
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SignupNamePage(signupData: signupData)),
                );
              },
            ),
            InfoRow(
              label: '이메일',
              value: signupData.email,
              onEdit: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SignupEmailPage(signupData: signupData)),
                );
              },
            ),
            InfoRow(
              label: '비밀번호',
              value: signupData.phone,
              onEdit: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SignupPassword(signupData: signupData)),
                );
              },
            ),
            InfoRow(
              label: '전화번호',
              value: signupData.phone,
              onEdit: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SignupPhone(signupData: signupData)),
                );
              },
            ),
            Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // 서버로 회원가입 정보 전송
                },
                child: Text('회원가입 완료'),
              ),
            )
          ],
        ),
      ),
    );
  }
}