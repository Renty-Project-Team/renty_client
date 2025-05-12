import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:renty_client/core/token_manager.dart';
import '../signUp/signUpData.dart';
import '../signUp/signUpLev1.dart';
import '../main.dart';

class CustomLoginScreen extends StatefulWidget {
  const CustomLoginScreen({super.key});

  @override
  State<CustomLoginScreen> createState() => _CustomLoginScreenState();
}

class _CustomLoginScreenState extends State<CustomLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = true;
  bool _isLoading = false;
  String _statusMessage = '';

  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _statusMessage = '로그인 시도 중...';
      });

      try {
        final response = await apiClient.client.post(
          '/Auth/login',
          data: {
            'email': _emailController.text,
            'password': _passwordController.text,
          },
        );

        if (response.statusCode == 200) {
          Map<String, dynamic> jsonData = response.data;
          final String accessToken = jsonData['token'];
          await TokenManager.saveToken(accessToken);
          setState(() {
            _statusMessage = '로그인 성공!';
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => MainPage()),
                  (route) => false,
            );
          });
        } else {
          setState(() {
            _statusMessage = '로그인 실패: 서버 응답 코드 ${response.statusCode}';
          });
        }
      } on DioException catch (e) {
        String errorMessage = '로그인 오류 발생';
        if (e.response != null) {
          if (e.response?.statusCode == 401) {
            errorMessage = '이메일 또는 비밀번호가 잘못되었습니다.';
          } else {
            errorMessage = '서버 오류 (${e.response?.statusCode})';
          }
        } else if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          errorMessage = '네트워크 타임아웃 발생';
        } else if (e.type == DioExceptionType.connectionError) {
          errorMessage = '네트워크 연결 오류 발생';
        } else {
          errorMessage = '네트워크 요청 중 오류 발생: ${e.message}';
        }
        setState(() {
          _statusMessage = errorMessage;
        });
      } catch (e) {
        setState(() {
          _statusMessage = '알 수 없는 오류 발생: $e';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(height: 40),
                LayoutBuilder(
                  builder: (context, constraints) {
                    double screenWidth = constraints.maxWidth;
                    double dynamicFontSize = screenWidth * 0.25;

                    return Text(
                      'ㅂㄹㅂ',
                      style: TextStyle(
                        fontSize: dynamicFontSize.clamp(40, 120),
                        fontFamily: 'Hakgyoansim',
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                        letterSpacing: -5,
                      ),
                    );
                  },
                ),
                SizedBox(height: 20),

                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: '이메일',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty || !value.contains('@')) {
                      return '유효한 이메일을 입력해주세요.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: '비밀번호',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty || value.length < 6) {
                      return '6자 이상 비밀번호를 입력해주세요.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12),

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
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        await _login();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('빌려봄 로그인', style: TextStyle(color: Colors.white)),
                  ),
                ),
                SizedBox(height: 24),
                if (_statusMessage.isNotEmpty)
                  Text(
                    _statusMessage,
                    style: TextStyle(
                      color: _statusMessage.contains('성공') ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                SizedBox(height: 24),
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