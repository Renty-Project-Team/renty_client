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
  bool _rememberMe = true; // "로그인 상태 유지" 기본값
  bool _isLoading = false;
  String _statusMessage = '';

  Future<void> _login() async {
    print(_formKey.currentState?.validate());
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _statusMessage = '로그인 시도 중...';
      });

      try {
        // ApiClient를 통해 Dio 인스턴스 접근
        // !!! 중요: 실제 로그인 API 엔드포인트로 변경하세요 !!!
        // 예: /auth/login, /account/login 등
        final response = await apiClient.client.post(
          '/Auth/login', // 예시 엔드포인트
          data: {
            // !!! 중요: 서버가 요구하는 필드명으로 정확히 변경하세요 !!!
            'email': _emailController.text,
            'password': _passwordController.text,
          },
        );
        print("test");
        // 성공 (예: 상태 코드 200)
        if (response.statusCode == 200) {
          Map<String, dynamic> jsonData = response.data;
          final String accessToken = jsonData['token'];
          await TokenManager.saveToken(accessToken);
          setState(() {
            _statusMessage = '로그인 성공!';
            // 로그인 성공 후 다음 화면으로 이동하거나 상태 업데이트
            // 예: Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage()));
            Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MainPage())
            );
            print('로그인 성공 데이터: ${response.data}'); // 서버 응답 데이터 확인
          });
          // 로그인 성공 후 쿠키가 잘 저장되었는지 확인 (디버깅용)
          // _checkCookies();
        } else {
          // 서버에서 예상치 못한 성공 상태 코드 반환
          setState(() {
            _statusMessage = '로그인 실패: 서버 응답 코드 ${response.statusCode}';
          });
        }
      } on DioException catch (e) {
        // Dio 관련 오류 처리
        String errorMessage = '로그인 오류 발생';
        if (e.response != null) {
          // 서버가 오류 응답을 반환한 경우
          print('서버 오류 응답: ${e.response?.data}');
          print('서버 오류 상태 코드: ${e.response?.statusCode}');
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
        }
        else {
          // 기타 Dio 오류 (요청 설정 오류 등)
          errorMessage = '네트워크 요청 중 오류 발생: ${e.message}';
        }
        setState(() {
          _statusMessage = errorMessage;
        });
      } catch (e) {
        // Dio 외의 예기치 않은 오류
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
                  Text(
                    'ㅂㄹㅂ',
                    style: TextStyle(
                      fontSize: 120,
                      fontFamily: 'Hakgyoansim',
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                      letterSpacing: -5,
                    ),
                  ),
                  SizedBox(height: 20),

                  /// 이메일
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

                  /// 비밀번호
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
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // 로그인 로직 실행
                          print('이메일: ${_emailController.text}');
                          print('비밀번호: ${_passwordController.text}');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: TextButton(
                        onPressed: () async{
                          await _login();
                        },
                        child: Text('빌려봄 로그인', style: TextStyle(color: Colors.white)),
                      )
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

                  /// 카카오 로그인
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

                  /// 구글 로그인
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

                  /// 네이버 로그인
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
