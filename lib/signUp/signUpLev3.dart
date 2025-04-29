import 'package:flutter/material.dart';
import 'signUpLev4.dart';
import 'package:renty_client/signUp/signUpData.dart';

class SignupPassword extends StatelessWidget {
  final SignupData signupData;
  SignupPassword({Key? key, required this.signupData}) : super(key: key);
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 60),
              Text('${signupData.name}님이 로그인할때 사용할 비밀번호를 입력해주세요', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              TextField(
                controller: passwordController,
                obscureText: true,
                autofocus: true,
                style: TextStyle(fontSize: 20),
                decoration: InputDecoration(
                  hintText: '비밀번호',
                  border: UnderlineInputBorder(),
                ),
              ),
              Text('실수록 입력해서 넘겨도 마지막 단계에서 한번에 수정이 가능해요!', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) =>
                          SignupPhone(
                            signupData: signupData.copyWith(pw: passwordController.text),
                          ),
                      ),
                    );
                  },
                  child: Text('다음'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}