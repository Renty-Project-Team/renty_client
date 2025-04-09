import 'package:flutter/material.dart';
import 'signUp/signUpData.dart';
import 'signUp/signUpLev1.dart';

class CustomLoginScreen extends StatelessWidget {
  const CustomLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                SizedBox(height: 40),
                // 로고
                Text(
                  'ㅂㄹㅂ', // 실제 앱 로고 대체
                  style: TextStyle(
                    fontSize:120,
                    fontFamily: 'Hakgyoansim',
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary, // 파란색
                    letterSpacing: -5,
                  ),
                ),
                SizedBox(height: 20),

                // 이메일 입력
                TextField(
                  decoration: InputDecoration(
                    labelText: '이메일',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),

                // 비밀번호 입력
                TextField(
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: '비밀번호',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),

                // 링크
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {},
                      child: Text('비밀번호 찾기', style: TextStyle(color: Colors.grey)),
                    ),
                    Text('|', style: TextStyle(color: Colors.grey)),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SignupNamePage(signupData: SignupData())),
                        );
                      },
                      child: Text('회원가입', style: TextStyle(color: Colors.grey)),
                    ),
                  ],
                ),
                SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('빌려봄 로그인',style: TextStyle(color: Colors.white)),
                  ),
                ),
                SizedBox(height: 24),

                // "또는" 구분선
                Row(
                  children: [
                    Expanded(child: Divider(thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text('또는', style: TextStyle(color: Colors.grey)),
                    ),
                    Expanded(child: Divider(thickness: 1)),
                  ],
                ),
                SizedBox(height: 24),

                // 노란색 버튼
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow[600],
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('카카오 로그인'),
                  ),
                ),
                SizedBox(height: 12),

                // 흰색 버튼 (디스코드 같은 외부 로그인?)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('구글 로그인'),
                  ),
                ),
                SizedBox(height: 12),

                // 초록색 버튼
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('네이버 로그인'),
                  ),
                ),
                SizedBox(height: 40),

                // 하단 텍스트
                Text(
                  'made by\nSilla University',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
