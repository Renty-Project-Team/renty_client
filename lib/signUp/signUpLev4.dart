import 'package:flutter/material.dart';
import 'package:renty_client/signUp/signUpData.dart';

class SignupPhone extends StatelessWidget {
  final SignupData signupData;
  SignupPhone({Key? key, required this.signupData}) : super(key: key);
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
              Text('${signupData.name} 사용중인 전화번호를 입력해주세요', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              TextField(
                autofocus: true,
                style: TextStyle(fontSize: 20),
                decoration: InputDecoration(
                  hintText: '전화번호',
                  border: UnderlineInputBorder(),
                ),
              ),
              Text('실수록 입력해서 넘겨도 마지막 단계에서 한번에 수정이 가능해요!', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {// 다음 단계로 이동
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